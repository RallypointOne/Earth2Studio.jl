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
    # Make HTTPS work for Python. Inside Julia, Python's `ssl` module binds to the OpenSSL that
    # Julia already loaded, whose default CA bundle path is a build-machine path that does not
    # exist, so remote data sources (ARCO, WB2ERA5, CDS, ...) fail certificate verification.
    # truststore makes Python verify against the OS trust store instead. Unlike setting
    # SSL_CERT_FILE, it changes nothing outside Python, so Julia's own HTTPS clients are unaffected.
    # It must run before importing earth2studio: aiohttp creates its SSL context at import time.
    pyimport("truststore").inject_into_ssl()
    # Make the eccodes bindings load the conda libeccodes that pygrib links. By default findlibs
    # prefers the eccodeslib wheel (required by earth2studio[data]), and two different libeccodes
    # versions in one process crash on import.
    pyimport("os").environ.setdefault("FINDLIBS_DISABLE_PACKAGE", "yes")
    pycopy!(earth2studio, pyimport("earth2studio"))
    for (name, _) in SUBMODULES
        pycopy!(getfield(@__MODULE__, name), pyimport("earth2studio.$name"))
    end
    return nothing
end

end # module
