# Changelog

## Unreleased

Initial release.

### Added

- `Earth2Studio.earth2studio` and its submodules (`data`, `models`, `perturbation`, `io`, `run`, `statistics`, `utils`) as `PythonCall.Py` references. Nothing is exported, because `run` and `io` would clash with `Base`.
- CondaPkg environment with Python 3.11–3.13 and `earth2studio[data]` 0.18 or newer. Model extras are opt-in through your own `CondaPkg.toml`.
- Python verifies TLS certificates against the OS trust store (via `truststore`), so remote data sources work without changing Julia's own HTTPS settings.
- Docs: quickstart plus Basics, Forecasting, and Julia packages (DimensionalData and Makie) tutorials.

### Fixed

- Fresh installs: pinned `python-dateutil<3`, which `arraylake` requires, and made the eccodes bindings load the conda `libeccodes`, which fixes a crash when two `libeccodes` versions were loaded into one process.
