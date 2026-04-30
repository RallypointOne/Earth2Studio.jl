module Earth2Studio

using PythonCall: PythonCall, Py, pyimport, pynew, pycopy!

export earth2studio, data, models, perturbation, io, run, statistics, utils

#-------------------------------------------------------------------------------# Python module references
"""
    earth2studio :: Py

Top-level [`earth2studio`](https://github.com/NVIDIA/earth2studio) Python module.
"""
const earth2studio = pynew()

"""
    data :: Py

`earth2studio.data` — data sources (e.g. `data.ARCO`, `data.GFS`, `data.WB2ERA5`).
"""
const data = pynew()

"""
    models :: Py

`earth2studio.models` — prognostic (`models.px`) and diagnostic (`models.dx`) model classes.
"""
const models = pynew()

"""
    perturbation :: Py

`earth2studio.perturbation` — ensemble perturbation methods (e.g. `perturbation.Gaussian`, `perturbation.BredVector`).
"""
const perturbation = pynew()

"""
    io :: Py

`earth2studio.io` — output backends (e.g. `io.ZarrBackend`, `io.NetCDF4Backend`).
"""
const io = pynew()

"""
    run :: Py

`earth2studio.run` — inference workflows (`run.deterministic`, `run.ensemble`, `run.diagnostic`).
"""
const run = pynew()

"""
    statistics :: Py

`earth2studio.statistics` — verification metrics (e.g. `statistics.rmse`, `statistics.acc`, `statistics.crps`).
"""
const statistics = pynew()

"""
    utils :: Py

`earth2studio.utils` — miscellaneous utilities from the upstream package.
"""
const utils = pynew()

const _SUBMODULES = (
    (earth2studio, "earth2studio"),
    (data,         "earth2studio.data"),
    (models,       "earth2studio.models"),
    (perturbation, "earth2studio.perturbation"),
    (io,           "earth2studio.io"),
    (run,          "earth2studio.run"),
    (statistics,   "earth2studio.statistics"),
    (utils,        "earth2studio.utils"),
)

function __init__()
    for (ref, name) in _SUBMODULES
        pycopy!(ref, pyimport(name))
    end
    return nothing
end

end # module
