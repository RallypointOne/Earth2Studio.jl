## Unreleased

### Breaking

- Rewritten as a minimal wrapper. The package now exports only the `earth2studio` Python module and its top-level submodules (`data`, `models`, `perturbation`, `io`, `run`, `statistics`, `utils`) as `PythonCall.Py` references. All hand-written Julia constructors, types (`DataSource`, `PrognosticModel`, `DiagnosticModel`, `Perturbation`, `IOBackend`, `Statistic`), workflow helpers (`run_deterministic`, `run_ensemble`, `run_diagnostic`, `fetch_data`, `to_device!`, `to_xarray`), and conversion utilities have been removed. Call into the upstream Python API directly via PythonCall.

### Fixed

- `CondaPkg.toml`: pinned Python to `>=3.10,<3.14` and added `pygrib` and `eccodes` as conda-forge dependencies. This avoids pixi attempting to build `pygrib` from source against the free-threaded Python 3.14 ABI (which has no wheel) and missing system `eccodes.h`, which broke `using Earth2Studio` on fresh installs.
