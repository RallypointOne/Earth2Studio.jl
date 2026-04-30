[![CI](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/Earth2Studio.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/Earth2Studio.jl/dev/)

# Earth2Studio.jl

A thin Julia wrapper around [NVIDIA's earth2studio](https://github.com/NVIDIA/earth2studio) Python package. The wrapper is intentionally minimal: it imports `earth2studio` and its top-level submodules and re-exports them as [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl) `Py` references. All functionality lives upstream — call into it from Julia using PythonCall idioms.

## Installation

```julia
using Pkg
Pkg.add("Earth2Studio")
```

The Conda environment managed by [CondaPkg.jl](https://github.com/JuliaPy/CondaPkg.jl) installs Python, NumPy, and xarray. The `earth2studio` Python package itself must be added separately, with whichever model extras you need:

```julia
using CondaPkg
CondaPkg.add_pip("earth2studio")
# or with extras:
CondaPkg.add_pip("earth2studio[fcn,pangu]")
```

## Usage

```julia
using Earth2Studio

earth2studio  # the top-level Python module
data          # earth2studio.data
models        # earth2studio.models   (use models.px and models.dx)
perturbation  # earth2studio.perturbation
io            # earth2studio.io
run           # earth2studio.run
statistics    # earth2studio.statistics
utils         # earth2studio.utils
```

Example — deterministic forecast:

```julia
using Earth2Studio
using PythonCall

ds      = data.ARCO()
pkg     = models.px.FCN.load_default_package()
model   = models.px.FCN.load_model(pkg)
backend = io.ZarrBackend("/tmp/forecast.zarr")

t = pyimport("numpy").array([pyimport("numpy").datetime64("2024-01-01")])
run.deterministic(t, 10, model, ds, backend)
```

See the [docs](https://RallypointOne.github.io/Earth2Studio.jl/dev/) and the [earth2studio Python documentation](https://nvidia.github.io/earth2studio/) for details on the API surface.
