## Unreleased

### Breaking

- Rewritten as a minimal wrapper. The package now exports only the `earth2studio` Python module and its top-level submodules (`data`, `models`, `perturbation`, `io`, `run`, `statistics`, `utils`) as `PythonCall.Py` references. All hand-written Julia constructors, types (`DataSource`, `PrognosticModel`, `DiagnosticModel`, `Perturbation`, `IOBackend`, `Statistic`), workflow helpers (`run_deterministic`, `run_ensemble`, `run_diagnostic`, `fetch_data`, `to_device!`, `to_xarray`), and conversion utilities have been removed. Call into the upstream Python API directly via PythonCall.
