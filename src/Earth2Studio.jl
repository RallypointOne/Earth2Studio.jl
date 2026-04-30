module Earth2Studio

using PythonCall: PythonCall, Py, pyimport, pyconvert, pynew, pycopy!

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
    _ensure_ssl_cert_file()
    for (ref, name) in _SUBMODULES
        pycopy!(ref, pyimport(name))
    end
    return nothing
end

# Conda Python on macOS often ships an OpenSSL whose compiled-in CA path
# doesn't resolve when the env lives under .julia/dev/.../.CondaPkg/.pixi/...
# The cert bundle is at <sys.prefix>/ssl/cert.pem; point Python at it so
# remote data sources (ARCO, WB2ERA5, CDS, ...) can complete TLS handshakes.
# Updates both Julia's ENV and Python's os.environ — Python initialises its
# environ snapshot at interpreter startup and will not see vars Julia sets
# afterwards. This must run before importing earth2studio, because libraries in
# the data-source stack may cache SSL defaults at import time. Honors any
# pre-set SSL_CERT_FILE / REQUESTS_CA_BUNDLE.
function _ensure_ssl_cert_file()
    pyos = try
        pyimport("os")
    catch
        return
    end
    pyenv_has(k) = pyconvert(Bool, pyos.environ.__contains__(k))
    (haskey(ENV, "SSL_CERT_FILE") || haskey(ENV, "REQUESTS_CA_BUNDLE") ||
     pyenv_has("SSL_CERT_FILE") || pyenv_has("REQUESTS_CA_BUNDLE")) && return
    cert = try
        joinpath(pyconvert(String, pyimport("sys").prefix), "ssl", "cert.pem")
    catch
        return
    end
    if isfile(cert)
        ENV["SSL_CERT_FILE"] = cert
        pyos.environ["SSL_CERT_FILE"] = cert
    end
    return nothing
end

end # module
