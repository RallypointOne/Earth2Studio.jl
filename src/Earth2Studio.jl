module Earth2Studio

using PythonCall: PythonCall, Py, pyimport, pynew, pycopy!

#-------------------------------------------------------------------------------# Python module references
"""
    Earth2Studio.earth2studio :: Py

Top-level [`earth2studio`](https://github.com/NVIDIA/earth2studio) Python module.
"""
const earth2studio = pynew()

# Top-level submodules of `earth2studio` exposed as `Earth2Studio.<name>`
const SUBMODULES = (
    :data         => "data sources (e.g. `data.ARCO`, `data.GFS`, `data.WB2ERA5`)",
    :models       => "prognostic (`models.px`) and diagnostic (`models.dx`) model classes",
    :perturbation => "ensemble perturbation methods (e.g. `perturbation.Gaussian`, `perturbation.BredVector`)",
    :io           => "output backends (e.g. `io.ZarrBackend`, `io.NetCDF4Backend`)",
    :run          => "inference workflows (`run.deterministic`, `run.ensemble`, `run.diagnostic`)",
    :statistics   => "verification metrics (e.g. `statistics.rmse`, `statistics.acc`, `statistics.crps`)",
    :utils        => "miscellaneous utilities from the upstream package",
)

for (name, desc) in SUBMODULES
    @eval @doc $("    Earth2Studio.$name :: Py\n\n`earth2studio.$name` — $desc.") const $name = pynew()
end

function __init__()
    pyimport("truststore").inject_into_ssl()  # Julia's OpenSSL has no CA bundle; use the OS trust store
    pyimport("os").environ.setdefault("FINDLIBS_DISABLE_PACKAGE", "yes")  # use conda's libeccodes, not eccodeslib's
    pycopy!(earth2studio, pyimport("earth2studio"))
    for (name, _) in SUBMODULES
        pycopy!(getfield(@__MODULE__, name), pyimport("earth2studio.$name"))
    end
    return nothing
end

end # module
