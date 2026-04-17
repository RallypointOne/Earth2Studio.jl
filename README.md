[![CI](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/CI.yml)
[![Docs Build](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/Docs.yml/badge.svg)](https://github.com/RallypointOne/Earth2Studio.jl/actions/workflows/Docs.yml)
[![Stable Docs](https://img.shields.io/badge/docs-stable-blue)](https://RallypointOne.github.io/Earth2Studio.jl/stable/)
[![Dev Docs](https://img.shields.io/badge/docs-dev-blue)](https://RallypointOne.github.io/Earth2Studio.jl/dev/)

# Earth2Studio.jl

A Julia wrapper around [NVIDIA's earth2studio](https://github.com/NVIDIA/earth2studio) for AI-powered weather and climate forecasting. Run models like Pangu-Weather, GraphCast, FourCastNet, and Aurora from Julia with automatic Python environment management via [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl).

## Installation

```julia
using Pkg
Pkg.add("Earth2Studio")
```

### Python Dependencies

Earth2Studio.jl ships with only lightweight Python dependencies (python, numpy, xarray). You must install the `earth2studio` Python package separately into the Conda environment managed by PythonCall/CondaPkg:

```julia
using CondaPkg
CondaPkg.add_pip("earth2studio")
```

To include model-specific extras (e.g., FourCastNet, Pangu-Weather), specify them as pip extras:

```julia
CondaPkg.add_pip("earth2studio[fcn,pangu]")
```

Alternatively, to install from source:

```julia
CondaPkg.add_pip("earth2studio"; version="@ git+https://github.com/NVIDIA/earth2studio.git")
```
