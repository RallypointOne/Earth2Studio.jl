# Workflow and Run Orchestration

## Overview

Earth2Studio uses **protocol-based composition**. Workflows are plain functions (not classes) in `earth2studio/run.py` that wire together pluggable components. The universal data type flowing through the system is `(torch.Tensor, CoordSystem)` pairs.

---

## Core Protocols (6 total)

| Protocol | Key Method | Purpose |
|----------|-----------|---------|
| `PrognosticModel` | `__call__`, `create_iterator`, `input_coords`, `output_coords` | Time-stepping forward model |
| `DiagnosticModel` | `__call__`, `input_coords`, `output_coords` | Stateless variable transform |
| `DataSource` | `__call__(time, variable) -> xr.DataArray` | Fetch gridded data |
| `IOBackend` | `add_array(coords, name)`, `write(x, coords, name)` | Store results |
| `Perturbation` | `__call__(x, coords) -> (x, coords)` | Perturb initial conditions |
| `Statistic` / `Metric` | `__call__` with `reduction_dimensions` | Post-processing |

Also: `ForecastSource`, `DataFrameSource`, `ForecastFrameSource`, `AssimilationModel`.

---

## Three Built-in Workflow Functions

### 1. `deterministic(time, nsteps, prognostic, data, io, output_coords={}, device=None)`

Simplest workflow:
1. Auto-detect device (CUDA/CPU), move model
2. `fetch_data(source, time, variable, lead_time, device)` -> `(Tensor, CoordSystem)`
3. Build `total_coords` from model's `output_coords`, set time/lead_time arrays
4. `io.add_array(total_coords, var_names)` to pre-allocate
5. `map_coords(x, coords, prognostic.input_coords())` to align data with model
6. `model.create_iterator(x, coords)` -> generator
7. Loop `nsteps+1` times (step 0 = initial condition):
   - `map_coords(x, coords, output_coords)` to subselect
   - `io.write(*split_coords(x, coords))` to store

### 2. `diagnostic(time, nsteps, prognostic, diagnostic, data, io, ...)`

Extends deterministic: chains a diagnostic model after each prognostic step.

Prognostic -> map_coords -> Diagnostic -> map_coords -> IO write

### 3. `ensemble(time, nsteps, nensemble, prognostic, data, io, perturbation, batch_size=None, ...)`

Most complex:
1. Fetch data as template `x0, coords0`
2. Add `"ensemble"` dimension to total_coords
3. Outer loop over batches (`batch_size` controls GPU memory):
   - Clone `x0`, add ensemble coords, expand tensor
   - `perturbation(x, coords)` — applied once before time-stepping
   - `create_iterator` for this batch
   - Inner loop: same as deterministic (map + split + write)

---

## Time-Stepping: The Iterator Pattern

Every `PrognosticModel.create_iterator` returns a Python generator:

```python
def _default_generator(self, x, coords):
    yield x, coords                              # Step 0: initial condition
    while True:
        x, coords = self.front_hook(x, coords)  # Hook (perturbation injection)
        x_out, coords_out = self._forward(x, coords)  # NN forward pass
        x_out, coords_out = self.rear_hook(x_out, coords_out)  # Hook
        # Slide window for multi-input models
        coords["lead_time"] = concat([coords["lead_time"][1:], coords_out["lead_time"]])
        x = cat([x[:, 1:], x_out], dim=1)
        yield x_out, coords_out
```

Key aspects:
- Step 0 always yields the initial condition unchanged
- `lead_time` advances by model `dt` each step
- Models with history (e.g., lead_time=[-6h, 0h]) maintain a sliding window
- `front_hook` and `rear_hook` are identity by default (override for custom behavior)
- Caller controls step count by iterating and breaking

### Lead Time Pre-computation

```python
total_coords["lead_time"] = np.array([dt * i for i in range(nsteps + 1)])
```

---

## The batch_func Decorator

Compresses leading dimensions into a single batch dim for model execution:

1. **Compress**: `[ensemble, time, lead_time, var, lat, lon]` -> `[batch, lead_time, var, lat, lon]`
2. **Forward**: Model sees single batch dim
3. **Decompress**: Reshape back to original leading dims

This means model implementations only need to handle one batch dimension.

---

## DiagnosticWrapper — Composition Pattern

Wraps a prognostic + one or more diagnostic models into a single `PrognosticModel`:

```python
for px_x, px_coords in self.px_model.create_iterator(x, coords):
    for dx_model in self.dx_model:
        dx_x, dx_coords = dx_model(prepare_input(px_x, px_coords))
    yield concat(prognostic_output, diagnostic_output)
```

Uses pluggable `Prepare*` protocols for input mapping and output concatenation.

---

## Data Flow: fetch_data

`fetch_data(source, time, variable, lead_time, device, interp_to, interp_method)`:
- Detects `ForecastSource` vs `DataSource`
- For `DataSource` with lead times: loops over lead times, shifts time, fetches, concatenates
- `prep_data_array` converts `xr.DataArray` -> `(torch.Tensor, CoordSystem)` with optional interpolation

---

## Coordinate Utilities

| Function | Purpose |
|----------|---------|
| `map_coords(x, in_coords, out_coords)` | Subselect, roll, slice, interpolate between coord systems |
| `split_coords(x, coords, "variable")` | Remove variable dim, split tensor -> list per variable |
| `cat_coords(tensors, coords, dim)` | Inverse of split |
| `tile_coords(x, coords, target)` | Add leading dims from target |

---

## AssimilationModel (Newer Protocol)

For data assimilation workflows:
- Uses `create_generator` (coroutine via `send()`) instead of `create_iterator`
- Accepts observations at each step
- Works with both `xr.DataArray` and `pd.DataFrame`
- Has separate `init_coords()` and `input_coords()`

---

## Julia Rewrite Considerations

### Iterator Pattern
- Python generators -> Julia `Channel` or custom iterator type
- The `yield` / `while True` pattern maps to `put!(channel, result)` in a `@async` task

### Protocol Composition
- Abstract types: `AbstractPrognosticModel`, `AbstractDiagnosticModel`, etc.
- Functor pattern: `(m::MyModel)(x, coords) = ...`
- `input_coords(m)` and `output_coords(m, input_coords)` as regular methods

### batch_func
- Could be a wrapper type or a `@generated` function
- Julia's multiple dispatch may reduce the need for this pattern

### Key Design Decisions
1. Workflows as functions (not types) — matches Julia idiom well
2. `(Array, CoordSystem)` as universal type — consider a custom struct or `DimArray`
3. Perturbation applied once before iteration, not at each step
4. `output_coords` parameter lets users subselect without changing computation
