# Data Sources

## Protocol Interfaces

Four protocols, each with sync `__call__` and async `fetch`:

| Protocol | Signature | Return Type |
|----------|-----------|-------------|
| `DataSource` | `(time, variable)` | `xr.DataArray` [time, variable, lat, lon] |
| `ForecastSource` | `(time, lead_time, variable)` | `xr.DataArray` [time, lead_time, variable, lat, lon] |
| `DataFrameSource` | `(time, variable, fields)` | `pd.DataFrame` |
| `ForecastFrameSource` | `(time, lead_time, variable, fields)` | `pd.DataFrame` |

---

## Complete Data Source Catalog

### A. GRIB-Based (Byte-Range Fetching)

| Class | Protocol | Remote | Storage | Notes |
|-------|----------|--------|---------|-------|
| **GFS** | DataSource | NOAA AWS S3 `noaa-gfs-bdp-pds` or NCEP FTP | GRIB2 byte-range | `s3fs`, `pygrib` |
| **GFS_FX** | ForecastSource | Same | Same | |
| **HRRR** | DataSource | AWS S3 / GCS / NOMADS HTTP | GRIB2 byte-range | `s3fs`/`gcsfs`, `pygrib`, `pyproj` |
| **HRRR_FX** | ForecastSource | Same | Same | |
| **GEFS_FX** | ForecastSource | AWS S3 `noaa-gefs-pds` | GRIB2 byte-range | 0.5 deg |
| **GEFS_FX_721x1440** | ForecastSource | Same | Same | 0.25 deg |
| **MRMS** | DataSource | AWS S3 `noaa-mrms-pds` | GRIB2 gzipped full file | `gzip`, `eccodes` |
| **IFS/IFS_FX/IFS_ENS/...** | ForecastSource | ECMWF Open Data | GRIB2 full download | `ecmwf.opendata`, `pygrib` |
| **AIFS_FX/AIFS_ENS_FX** | ForecastSource | Same | Same | |

### B. Zarr-Based (Async Chunk Fetching)

| Class | Protocol | Remote | Notes |
|-------|----------|--------|-------|
| **ARCO** | DataSource | GCS `gcp-public-data-arco-era5` | Zarr v3, `gcsfs`, `AsyncCachingFileSystem` |
| **WB2ERA5** | DataSource | GCS `weatherbench2/datasets/era5/` | Zarr v3 |
| **WB2ERA5_121x240** | DataSource | Same, 1.5 deg grid | |
| **WB2ERA5_32x64** | DataSource | Same, 5.625 deg grid | |
| **WB2Climatology** | DataSource | GCS WB2 climatology | |

### C. API-Based

| Class | Protocol | Service | Notes |
|-------|----------|---------|-------|
| **CDS** | DataSource | Copernicus CDS ERA5 | `cdsapi`, downloads GRIB, opens with `cfgrib`/`xarray` |
| **CAMS_FX** | ForecastSource | Copernicus CAMS Global | `cdsapi`, downloads NetCDF |
| **CMIP6** | DataSource | ESGF archive | `intake_esgf`, `xarray`, `scipy.interpolate.griddata` |

### D. AWS S3 NetCDF/HDF5

| Class | Protocol | Bucket | Format |
|-------|----------|--------|--------|
| **NCAR_ERA5** | DataSource | `ncar-era5` | NetCDF via `xarray` |
| **GOES** | DataSource | `noaa-goes16/17/18/19` | NetCDF via `xarray` |
| **JPSS** | DataSource | `noaa-nesdis-n20-pds` etc. | HDF5 via `h5py` |
| **JPSS_ATMS** | DataFrameSource | Same | HDF5 |
| **JPSS_CRIS** | DataFrameSource | Same | HDF5 |
| **UFSObsConv** | DataFrameSource | AWS S3 | NetCDF via `h5netcdf` |
| **UFSObsSat** | DataFrameSource | AWS S3 | NetCDF via `h5netcdf` |
| **ISD** | DataFrameSource | `noaa-isd-pds` | CSV via `pandas` |

### E. EUMETSAT (Binary)

| Class | Protocol | Notes |
|-------|----------|-------|
| **MetOpAMSUA** | DataFrameSource | `eumdac` API, EPS native binary with `struct` |
| **MetOpAVHRR** | DataFrameSource | Same |
| **MetOpMHS** | DataFrameSource | Same |

### F. Microsoft Planetary Computer (STAC)

| Class | Protocol | Format |
|-------|----------|--------|
| **PlanetaryComputerGOES** | DataSource | NetCDF |
| **PlanetaryComputerECMWFOpenDataIFS** | ForecastSource | GRIB2 |
| **PlanetaryComputerOISST** | DataSource | NetCDF |
| **PlanetaryComputerMODISFire** | DataSource | GeoTIFF |
| **PlanetaryComputerSentinel3AOD** | DataSource | NetCDF |

All use `pystac_client` + `planetary_computer` for STAC catalog + signed URL access.

### G. Special/Utility Sources

| Class | Protocol | Notes |
|-------|----------|-------|
| **ACE2ERA5Data** | DataSource | HuggingFace Hub, `scipy.special.roots_legendre` |
| **CBottle3D** | DataSource | Local model + ARCO |
| **Random / Random_FX** | DataSource / ForecastSource | In-memory random |
| **RandomDataFrame** | DataFrameSource | In-memory random |
| **Constant / Constant_FX** | DataSource / ForecastSource | In-memory constant |
| **LandSeaMask** | DataSource | ARCO ERA5 Zarr v2 (static) |
| **SurfaceGeoPotential** | DataSource | ARCO ERA5 Zarr v2 (static) |
| **CosineSolarZenith** | DataSource | Computed (solar geometry via `physicsnemo`) |
| **DataArrayFile** | DataSource | Local NetCDF/Zarr |
| **DataSetFile** | DataSource | Local NetCDF/Zarr dataset |
| **DataArrayDirectory** | DataSource | Local directory |
| **DataArrayPathList** | DataSource | Multi-file, uses Dask |
| **InferenceOutputSource** | DataSource | Existing inference output |
| **TimeWindow** | DataSource | Wrapper, fetches at multiple time offsets |

---

## Caching System

### Cache Root
`~/.cache/earth2studio/` (override via `EARTH2STUDIO_CACHE` or `EARTH2STUDIO_DATA_CACHE` env vars).

Each source has its own subdirectory (e.g., `gfs/`, `arco/`, `cds/`).

### Strategy 1: SHA-256 Hash Filenames (GRIB sources)

```
cache_key = sha256(uri + str(byte_offset))
cache_path = join(cache_dir, hex(cache_key))
```

No expiry — files persist until manually deleted. When `cache=False`, uses a temp directory cleaned up after the call.

### Strategy 2: AsyncCachingFileSystem (Zarr sources)

Wraps the remote filesystem (GCS/S3) with a local file cache:
- Uses fsspec's `HashCacheMapper` for filenames
- 1-year expiry (`expiry_time = 31622400`)
- Different byte-range slices cached as separate files (`path_{start}_{end}`)

---

## Byte-Range GRIB Fetching (Step by Step)

1. **Construct index file URI**: e.g., `noaa-gfs-bdp-pds/gfs.YYYYMMDD/HH/atmos/gfs.tHHz.pgrb2.0p25.fFFF.idx`
2. **Download and parse `.idx` file**: colon-delimited, one line per GRIB message:
   ```
   1:0:d=2024010100:UGRD:10 m above ground:anl:
   2:34556:d=2024010100:VGRD:10 m above ground:anl:
   ```
   Extract `(byte_offset, byte_length)` for each variable. Length = next_offset - current_offset. Max 5 MB per variable.
3. **Lexicon lookup**: `"u500"` -> `("UGRD::500 mb", modifier_fn)`, match against parsed index
4. **Create async tasks**: one `(time, lead_time, variable)` tuple per task
5. **Fetch bytes**: `fs._cat_file(path, start=offset, end=offset+length)` — HTTP range request to S3
6. **Cache**: write to `sha256(path + offset)` filename
7. **Decode**: `pygrib.open(cache_path)`, read `grbs[1].values`, apply modifier
8. **Pack into pre-allocated DataArray**

---

## Async Zarr Fetching (Step by Step)

1. **Init filesystem**: `gcsfs.GCSFileSystem(asynchronous=True, token="anon")`, wrap in `AsyncCachingFileSystem`
2. **Open Zarr store**: `zarr.storage.FsspecStore` -> `zarr.api.asynchronous.open(store, mode="r")` -> `AsyncGroup`
3. **Compute time index**: `hours_since_epoch = (time - datetime(1900,1,1)).total_seconds() / 3600` (Zarr has no datetime indexing)
4. **Lexicon lookup**: `"t500"` -> `("temperature::500", modifier)`
5. **Fetch slices**: `await zarr_array.getitem(time_index)` for surface, `(time_index, level_index)` for pressure levels — pulls only needed chunks
6. **Apply modifier, pack into DataArray**

All tasks run concurrently via `asyncio.gather`.

---

## Shared Utilities

| Function | Purpose |
|----------|---------|
| `prep_data_inputs(time, variable)` | Normalize to `list[datetime]`, `list[str]`; handle np.datetime64, pd.Timestamp; ensure UTC |
| `prep_forecast_inputs(...)` | Same + lead_time normalization |
| `async_retry(coro, retries=3)` | Retry with exponential backoff + jitter |
| `gather_with_concurrency(coros, max_workers=16)` | Semaphore-bounded concurrent execution with progress bar |
| `fetch_data(source, time, variable, ...)` | Top-level bridge: calls source, converts to `(Tensor, CoordSystem)`, optional interpolation |
| `datasource_to_file(...)` | Materialize data to local NetCDF or Zarr |

---

## Julia Library Equivalents

| Python | Purpose | Julia |
|--------|---------|-------|
| `xarray` | Labeled arrays | `DimensionalData.jl` or `YAXArrays.jl` |
| `pandas` | DataFrames | `DataFrames.jl` |
| `s3fs` | AWS S3 | `AWSS3.jl` or `CloudStore.jl` |
| `gcsfs` | Google Cloud Storage | `GoogleCloud.jl` or `HTTP.jl` |
| `zarr` v3 | Zarr arrays | `Zarr.jl` |
| `pygrib` | GRIB reading | `GRIB.jl` |
| `fsspec` | Filesystem abstraction | `CloudStore.jl` or custom |
| `cdsapi` | Copernicus CDS | `CDSAPI.jl` |
| `ecmwf.opendata` | ECMWF open data | `HTTP.jl` + REST API |
| `h5py` / `h5netcdf` | HDF5/NetCDF | `HDF5.jl` / `NCDatasets.jl` |
| `pystac_client` | STAC catalogs | `HTTP.jl` + STAC API |
| `pyproj` | Projections | `Proj.jl` |
| `asyncio` | Concurrency | Julia Tasks / `@async` / `Threads.@spawn` |
| `nest_asyncio` | Notebook compat | Not needed in Julia |

### Key Architecture Notes for Julia Port

1. Every source follows the same pattern: validate time -> lexicon lookup -> create async tasks -> fetch concurrently -> pack into output array. Highly amenable to trait/dispatch design.
2. The sync `__call__` just wraps async `fetch`. Julia's task system makes this distinction unnecessary.
3. All S3 sources use anonymous access (`anon=True`).
4. `nest_asyncio` exists only for Jupyter notebook compatibility — Julia doesn't need it.
