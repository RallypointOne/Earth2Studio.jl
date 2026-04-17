# Models and Inference

## Model Protocols

### PrognosticModel (time-stepping forward model)

| Method | Signature | Description |
|--------|-----------|-------------|
| `__call__` | `(x: Tensor, coords: CoordSystem) -> (Tensor, CoordSystem)` | Single time-step |
| `create_iterator` | `(x, coords) -> Iterator[(Tensor, CoordSystem)]` | Autoregressive generator |
| `input_coords` | `() -> CoordSystem` | Required input dimensions |
| `output_coords` | `(input_coords) -> CoordSystem` | Transform input coords (advance lead_time) |
| `to` | `(device) -> PrognosticModel` | Move to device |

### DiagnosticModel (stateless variable transform)

Same as Prognostic minus `create_iterator`. Single-shot transforms (precipitation, super-resolution, derived quantities).

---

## Key Mixins and Decorators

- **`AutoModelMixin`**: Provides `from_pretrained(path)` — creates a `Package` from URI, downloads weights
- **`PrognosticMixin`**: Adds `front_hook` / `rear_hook` (identity callbacks injected before/after each step)
- **`@batch_func()`**: Compresses leading dims (ensemble, time) into single batch dim, decompresses after forward pass
- **`@batch_coords()`**: Same for `output_coords` methods

---

## Package System (Checkpoint Loading)

`Package` is an fsspec-based filesystem abstraction:

| Backend | URI Prefix | Notes |
|---------|-----------|-------|
| HuggingFace Hub | `hf://` | Most common |
| NGC Model Registry | `ngc://models/` | NVIDIA models |
| AWS S3 | `s3://` | |
| Google Cloud Storage | `gs://` | GraphCast |
| Local paths | `/path/to/...` | |

Cache: `~/.cache/earth2studio/` (override via `EARTH2STUDIO_CACHE`). Uses `WholeFileCacheFileSystem` with 1-year expiry.

---

## Complete Model Catalog

### Prognostic Models

#### ONNX Runtime Models (easiest to port)

| Model | Grid | Resolution | Variables | Step | Input Lead Times | Weights Source |
|-------|------|-----------|-----------|------|-----------------|---------------|
| **Pangu24** | 721x1440 | 0.25 deg | 69 | 24h | [0h] | HuggingFace |
| **Pangu6** | 721x1440 | 0.25 deg | 69 | 6h | [0h] | HuggingFace |
| **Pangu3** | 721x1440 | 0.25 deg | 69 | 3h | [0h] | HuggingFace |
| **FuXi** | 721x1440 | 0.25 deg | 70 | 6h | [-6h, 0h] | HuggingFace |
| **FengWu** | 721x1440 | 0.25 deg | 69 | 6h | [-6h, 0h] | HuggingFace |

Pangu6/3 interleave multiple resolution models (e.g., 3x6h + 1x24h cycle).
FuXi uses 3 cascaded ONNX models (short/medium/long), switching at steps 20 and 40.

#### PyTorch Models

| Model | Architecture | Grid | Variables | Step | Input | Notes |
|-------|-------------|------|-----------|------|-------|-------|
| **FCN** | PhysicsNeMo AFNO | 720x1440 | 26 | 6h | [0h] | `.mdlus` checkpoint |
| **FCN3** | Makani + torch_harmonics | 720x1440 | 72 | 6h | [0h] | Probabilistic, spherical harmonics |
| **SFNO** | Makani SFNO | 721x1440 | 73 | 6h | [0h] | NGC, requires `time` for zenith angle |
| **DLWP** | PhysicsNeMo | 721x1440 (I/O) | 7 | 6h | [-6h, 0h] | Cubed-sphere internally (6x64x64) |
| **Aurora** | Microsoft | 720x1440 | 69 | 6h | [-6h, 0h] | Static vars, tracks `rollout_step` |
| **ACE2ERA5** | Allen AI fme | 180x360 | Variable | 6h | [0h] | Requires forcing data during rollout |
| **AIFS/AIFSENS** | ECMWF anemoi + flash_attn | 721x1440 | ~90+ | 6h | [-6h, 0h] | Octahedral grid internal |
| **StormCast** | PhysicsNeMo diffusion | 512x640 HRRR | 99+26 | 1h | [0h] | Regional, regression + diffusion |
| **StormScope** | PhysicsNeMo diffusion | HRRR sub-region | Variant | 1h | Variant | "Ensemble of experts" denoising |
| **Atlas** | PhysicsNeMo + stochastic interpolant | 721x1440 | 75 | 6h | [-6h, 0h] | Autoencoder + latent diffusion |
| **DLESyM** | PhysicsNeMo | HEALPix nside=64 | 9 | 96h | Multi | Coupled atmos-ocean earth system |
| **CBottleVideo** | cbottle | HEALPix level 6 | Variable | Multi | [0h] | Climate diffusion, video (12 frames) |

#### JAX Models (hardest to port)

| Model | Grid | Variables | Step | Notes |
|-------|------|-----------|------|-------|
| **GraphCastSmall** | 181x360 | ~85 | 6h | 1.0 deg, mesh 1to6, forcing vars |
| **GraphCastOperational** | 721x1440 | ~85 | 6h | 0.25 deg, mesh 2to6 |
| **GenCastMini** | 181x360 | ~83 | 12h | Stochastic diffusion, 1.0 deg |

#### Utility Models

| Model | Notes |
|-------|-------|
| **Persistence** | Identity (returns input with shifted lead_time) |
| **DiagnosticWrapper** | Composes prognostic + diagnostic(s) |
| **InterpModAFNO** | Wraps another model, adds temporal interpolation |

### Diagnostic Models

| Model | Framework | Description |
|-------|-----------|-------------|
| **PrecipitationAFNO / v2** | PyTorch | 6h total precip from 20 atmos vars, 720x1440 |
| **SolarRadiationAFNO** | PyTorch | Solar radiation prediction |
| **WindgustAFNO** | PyTorch | Wind gust prediction |
| **ClimateNet** | PyTorch (CGNet) | TC + AR classification (3 labels) |
| **CorrDiff / CorrDiffTaiwan** | PyTorch (diffusion UNet) | Super-resolution |
| **CorrDiffCMIP6** | PyTorch | CMIP6 downscaling |
| **CBottle variants** | PyTorch | Infill, super-res, TC guidance |
| **DerivedRH, DerivedWS, DerivedTCWV, ...** | Pure computation | Physical formulas, no NN |
| **TCTracker variants** | Algorithm | Tropical cyclone tracking |
| **Identity** | None | Pass-through |

---

## Normalization Pattern

Every neural model follows this pattern:

```python
# Forward pass
x = (x - self.center) / self.scale      # normalize
x = self.model(x)                         # inference
x = self.scale * x + self.center          # denormalize
```

- `center` and `scale` loaded from `global_means.npy` / `global_stds.npy` in the package
- Registered as PyTorch buffers (`register_buffer`) for device transfer
- Shapes vary: `[n_vars]`, `[1, n_vars, 1, 1]`, `[n_vars, 1, 1]`
- ONNX models: normalization may be baked into the graph
- GraphCast/GenCast: xarray-based normalization from `diffs_stddev_by_level.nc` etc.

---

## Coordinate Conventions

| Dimension | Convention |
|-----------|-----------|
| **lat** | North-to-south: `linspace(90, -90, N)`. 721 pts (pole-including) or 720 pts (no south pole) |
| **lon** | `linspace(0, 360, M, endpoint=False)`. Typically 1440 pts |
| **variable** | `{var}{pressure_hPa}` for atmos (e.g., `z500`), plain for surface (`t2m`, `msl`) |
| **lead_time** | `np.timedelta64` values |
| **time** | `np.datetime64` (used for forcing like solar zenith) |

---

## ONNX Runtime Details

`create_ort_session`:
- CPU memory arena disabled for stability
- CUDA provider if GPU, else CPU
- Uses `io_binding` for zero-copy GPU inference (`bind_input`/`bind_output` with `data_ptr()`)

---

## Julia Porting Strategy

### By Difficulty

**Easiest (ONNX, self-contained):**
1. Pangu24 — single ONNX file
2. FengWu — single ONNX + normalization
3. FuXi — 3 ONNX files + time encoding

Use `ONNXRunTime.jl` with minimal wrapper code.

**Medium (PyTorch, standard architectures):**
4. FCN — AFNO architecture is relatively simple
5. PrecipitationAFNO — small diagnostic model
6. Derived diagnostics — pure computation, trivial in Julia

Options: (a) export to ONNX, run via `ONNXRunTime.jl`, or (b) reimplement in `Flux.jl` with weight loading.

**Hard (complex dependencies):**
7. GraphCast/GenCast — JAX, graph neural networks, full reimplementation needed
8. DLWP — cubed-sphere transforms
9. AIFS — octahedral grid + anemoi framework
10. StormCast — PhysicsNeMo diffusion

### Framework Mapping

| Python | Julia |
|--------|-------|
| ONNX Runtime | `ONNXRunTime.jl` |
| PyTorch | `Flux.jl` + manual weight loading |
| JAX (GraphCast) | Full reimplementation in Flux.jl |
| torch_harmonics | `FastSphericalHarmonics.jl` |
| HuggingFace Hub | `HTTP.jl` + HF API |

### Key Decisions
- ONNX models are the fastest path to Julia-native inference
- For PyTorch models, ONNX export -> `ONNXRunTime.jl` avoids reimplementation
- JAX models (GraphCast, GenCast) have no shortcut — need architecture reimplementation
- Derived diagnostics should be pure Julia from the start
