[![CI](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/Earth2Studio.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/Earth2Studio.jl/dev/)

# Earth2Studio.jl

A thin Julia wrapper around [NVIDIA's earth2studio](https://github.com/NVIDIA/earth2studio) Python package. The wrapper is intentionally minimal: it imports `earth2studio` and its top-level submodules and holds them as [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl) `Py` references. All functionality lives upstream — call into it from Julia using PythonCall idioms.

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/RallypointOne/Earth2Studio.jl")
```

On first load, [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl) creates a Conda environment with Python (3.11–3.13), `earth2studio[data]` (version 0.18 or newer), and the conda-forge packages the data sources need (`numpy`, `xarray`, `eccodes`, `pygrib`, `rasterio`). No manual pip step is required.

Model extras are opt-in. Add a `CondaPkg.toml` to your own project and CondaPkg merges it with the one shipped here:

```toml
[pip.deps.earth2studio]
extras = ["fcn", "pangu"]
```

## Usage

Nothing is exported, because upstream names such as `run` and `io` would clash with `Base`. Access every reference through the module:

```julia
using Earth2Studio

Earth2Studio.earth2studio  # the top-level Python module
Earth2Studio.data          # earth2studio.data
Earth2Studio.models        # earth2studio.models   (use models.px and models.dx)
Earth2Studio.perturbation  # earth2studio.perturbation
Earth2Studio.io            # earth2studio.io
Earth2Studio.run           # earth2studio.run
Earth2Studio.statistics    # earth2studio.statistics
Earth2Studio.utils         # earth2studio.utils
```

Example — fetch data from ARCO ERA5:

```julia
using Earth2Studio
using Dates

ds = Earth2Studio.data.ARCO()
da = ds(DateTime(2023, 6, 15), ["t2m", "u10m"])   # xarray.DataArray
```

`DateTime` and `String` convert to `datetime.datetime` and `str`. Julia vectors are passed as `juliacall.VectorValue` wrappers, which earth2studio accepts wherever it iterates over a list. For `Date`, convert with `DateTime(d)` first — earth2studio mixes `datetime.datetime` and `datetime.date` internally, which Python disallows.

Example — deterministic forecast:

```julia
using Earth2Studio
using Dates

ds      = Earth2Studio.data.ARCO()
pkg     = Earth2Studio.models.px.FCN.load_default_package()
model   = Earth2Studio.models.px.FCN.load_model(pkg)
backend = Earth2Studio.io.ZarrBackend("/tmp/forecast.zarr")

Earth2Studio.run.deterministic([DateTime(2023, 6, 15)], 10, model, ds, backend)
```

See the [docs](https://RallypointOne.github.io/Earth2Studio.jl/dev/) and the [earth2studio Python documentation](https://nvidia.github.io/earth2studio/) for details on the API surface.
