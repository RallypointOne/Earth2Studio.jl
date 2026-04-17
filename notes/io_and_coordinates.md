# IO and Coordinate System

## CoordSystem — The Fundamental Type

```python
CoordSystem = OrderedDict[str, np.ndarray]
```

An ordered dict mapping dimension names to coordinate arrays. **Key ordering matches tensor axis ordering.**

### Standard Dimensions

| Dimension | Type | Description |
|-----------|------|-------------|
| `"batch"` | `np.empty(0)` | Free/unbounded dimension (filled at runtime) |
| `"ensemble"` | `np.arange(N)` | Ensemble member indices |
| `"time"` | `np.datetime64` | Initialization/valid times |
| `"lead_time"` | `np.timedelta64` | Forecast lead times |
| `"variable"` | `np.ndarray` of str | Variable names (e.g., `"t2m"`, `"u500"`) |
| `"lat"` | `np.float64` | Latitude (1D regular grid) |
| `"lon"` | `np.float64` | Longitude (1D regular grid) |
| `"_lat"` / `"_lon"` | 2D arrays | Curvilinear grids (underscore = metadata, not true dim) |

### Conventions
- `np.empty(0)` means "free dimension" — pipeline fills it in at runtime
- Underscore-prefixed keys are metadata coordinates, not tensor dimensions
- Variable dimension is typically split out before IO writes

---

## IO Protocol

```python
class IOBackend(Protocol):
    def add_array(self, coords: CoordSystem, array_name: str | list[str], **kwargs) -> None: ...
    def write(self, x: Tensor | list[Tensor], coords: CoordSystem, array_name: str | list[str]) -> None: ...
```

All backends also implement `read()`, `__contains__`, `__getitem__`, `__len__`, `__iter__`.

### The split_coords Pattern

Before writing, the pipeline calls:
```python
io.write(*split_coords(x, coords, dim="variable"))
```

`split_coords` removes the "variable" dimension, splits the tensor along that axis, and returns `(list[Tensor], reduced_coords, variable_names)`. Each physical variable becomes a separate array in the IO store.

### IO Backends (5 total)

| Backend | Storage | Key Features |
|---------|---------|-------------|
| **ZarrBackend** | `zarr.MemoryStore` or `LocalStore` | Configurable chunking, optional codecs/compression, dimension metadata |
| **NetCDF4Backend** | `netCDF4.Dataset` (file) | cftime encoding ("hours since 0001-01-01"), lead_time as int with units attr |
| **XarrayBackend** | `xr.Dataset` (in-memory) | Wraps xarray, index-based partial writes |
| **KVBackend** | Python `dict[str, torch.Tensor]` | Keeps tensors on GPU, `to_xarray()` conversion |
| **AsyncZarrBackend** | Zarr v3 (async) | Thread pool for non-blocking writes, fsspec remote support, lazy init |

### Write Mechanism (shared pattern)

All backends use `np.isin` + `np.where` to compute which indices to write into pre-allocated arrays. This enables incremental writes (e.g., one timestep at a time into a pre-shaped array).

---

## Coordinate Validation ("Handshake" Functions)

```python
handshake_dim(input_coords, required_dim, required_index=None)   # dim exists (optionally at position)
handshake_coords(input_coords, target_coords, required_dim)       # matching values for a dim
handshake_size(input_coords, required_dim, required_size)          # dim has specific size
```

Models use these in `output_coords()` to verify input compatibility.

---

## Coordinate Mapping and Transformation

### map_coords (tensor-based)

`map_coords(x, input_coords, output_coords, method="nearest")` maps a tensor between coordinate systems:

1. **Identity** — skip if coords match
2. **Roll** — detects cyclic shifts (e.g., longitude origin shift), uses `torch.roll`
3. **Slice** — contiguous subrange detection
4. **Generic indexing** — sorted `np.isin` + `torch.index_select`
5. **Nearest-neighbor interpolation** — for numeric coords where output values aren't in input
6. Skips `batch`, `time`, `lead_time` and empty coords
7. Rejects 2D lat/lon (curvilinear) — directs to `fetch_data`/`prep_data_array`

### map_coords_xr (xarray-based)

Same concept for `xr.DataArray`. Separates exact selection (`xr.sel`) from nearest-neighbor interpolation.

### Other Utilities

| Function | Purpose |
|----------|---------|
| `split_coords(x, coords, dim)` | Remove dim, split tensor -> list of tensors + reduced coords |
| `cat_coords(tensors, coords, dim)` | Inverse of split — concatenate along named dim |
| `tile_coords(x, coords, target)` | Add leading dims from target not in coords |
| `convert_multidim_to_singledim` | Convert 2D lat/lon to synthetic 1D index dims (`"ilat"`, `"ilon"`) |

---

## Curvilinear Grid Handling

`convert_multidim_to_singledim` handles grids where lat/lon are 2D arrays:

```python
# Input: 2D curvilinear
coords = OrderedDict({"lat": LAT_2D, "lon": LON_2D})  # both shape (180, 360)

# Output: synthetic 1D indices
adjusted = {"ilat": arange(180), "ilon": arange(360)}
mapping = {"lat": ["ilat", "ilon"], "lon": ["ilat", "ilon"]}
```

The original 2D arrays are stored alongside as metadata.

---

## Interpolation Utilities

| Utility | Method | GPU Support |
|---------|--------|-------------|
| `latlon_interpolation_regular` | Bilinear from regular grid to arbitrary meshgrid | Yes (`torch.searchsorted`) |
| `LatLonInterpolation` (nn.Module) | Bilinear between arbitrary grids | Pre-computed indices via scipy, GPU forward |
| `NearestNeighborInterpolator` (nn.Module) | KDTree in 3D unit-sphere space | `scipy.spatial.KDTree`, configurable `max_dist_km` |

---

## Time Handling

| Function | Conversion |
|----------|-----------|
| `timearray_to_datetime` | `np.datetime64` -> Python `datetime` list |
| `leadtimearray_to_timedelta` | `np.timedelta64` -> Python `timedelta` list |
| `to_time_array` | `list[str]`, `list[datetime]`, etc. -> `datetime64[ns]` array |
| `normalize_time_tolerance` | Single or tuple tolerance -> `(lower, upper)` timedelta pair |

---

## Data Flow Through Pipeline

1. **Fetch**: `fetch_data(source, time, variable, ...)` -> `(Tensor, CoordSystem)`
2. **Setup IO**: Build `total_coords` from model's `output_coords()`, call `io.add_array(total_coords, var_names)`
3. **Iterate**: Model's `create_iterator(x, coords)` yields `(Tensor, CoordSystem)` per timestep
4. **Map + Write**: `map_coords(x, coords, output_coords)` then `io.write(*split_coords(x, coords))`

---

## Julia Rewrite Considerations

### CoordSystem
- `OrderedDict{String, AbstractVector}` from OrderedCollections.jl
- Or a custom struct wrapping dimension names + arrays with guaranteed ordering
- Consider `DimensionalData.jl` — its `Dim` system maps naturally to named coordinate dimensions

### IO Backends
- **Zarr**: `Zarr.jl` (though less mature than Python zarr)
- **NetCDF**: `NCDatasets.jl` — mature and well-supported
- **In-memory**: `DimensionalData.DimArray` or plain `Dict{String, Array}`
- The split_coords pattern (variable dim -> separate arrays) is fundamental

### Time Types
- `np.datetime64` -> `Dates.DateTime`
- `np.timedelta64` -> `Dates.Period` subtypes (`Hour`, `Minute`, etc.)

### Interpolation
- Bilinear: `Interpolations.jl`
- KDTree nearest-neighbor: `NearestNeighbors.jl`
- Spherical: consider `earth2grid` equivalent or `GeoStats.jl`

### Key Pattern: Partial Writes
All IO backends support writing a subset of coordinates into pre-allocated arrays (e.g., writing one timestep at a time). Julia implementation needs efficient index lookup for this.
