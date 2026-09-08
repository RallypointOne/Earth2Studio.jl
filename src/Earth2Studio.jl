module Earth2Studio

using PythonCall: PythonCall, Py, pyimport, pyconvert, pynew, pycopy!, pycontains

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
    _ensure_ssl_cert_file()
    pycopy!(earth2studio, pyimport("earth2studio"))
    for (name, _) in SUBMODULES
        pycopy!(getfield(@__MODULE__, name), pyimport("earth2studio.$name"))
    end
    return nothing
end

#----------------------------------------------------------------------------# ensure_ssl_cert_file
# Make HTTPS work for Python inside the CondaPkg environment on macOS.
#
# Problem: The OpenSSL bundled with Conda Python on macOS looks for its trusted root certificates
# (the CA bundle) at a path fixed at build time. That path does not exist when the environment is
# installed under .CondaPkg/, so every TLS connection fails with a certificate verification error.
# This breaks remote data sources (ARCO, WB2ERA5, CDS, ...).
#
# Details:
# - Set it in Python's os.environ, not Julia's ENV. os.environ also calls
#   putenv, so OpenSSL sees it, while Julia's own HTTPS clients are unaffected.
# - Must run before importing earth2studio; some libraries in its data-source
#   stack read SSL settings at import time and cache them.
function _ensure_ssl_cert_file()
    environ = pyimport("os").environ
    pycontains(environ, "SSL_CERT_FILE") && return  # If user already set, ignore
    cert = try
        pyconvert(String, pyimport("certifi").where())  # Use certifi's SSL_CERT_FILE
    catch
        return
    end
    environ["SSL_CERT_FILE"] = cert
    return
end

end # module
