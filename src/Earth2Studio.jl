module Earth2Studio

using PythonCall: PythonCall, pyimport, pyconvert, Py, pystr, pylist, pytuple, pydict,
                  pyhasattr, pyis, PyArray
using Dates: Dates, DateTime, Date

# Types
export DataSource, PrognosticModel, DiagnosticModel, Perturbation, IOBackend, Statistic

# Data source constructors (earth2studio.data)
export ARCO, GFS, GFS_FS, IFS, CDS, NCAR_ERA5, WB2ERA5, WB2Climatology, GOES, MRMS, HRRR, HRRR_FX

# Prognostic model constructors (earth2studio.models.px)
export FourCastNet, FCN3, Pangu24, Pangu6, Pangu3, GraphCast, GraphCastOper,
       AIFS, AIFSENS, Aurora, FengWu, DLWP, StormCast, InterpModAFNO, Persistence

# Diagnostic model constructors (earth2studio.models.dx)
export CorrDiff, CorrDiffTaiwan, CorrDiffCMIP6, PrecipitationAFNO, PrecipitationAFNOv2,
       ClimateNet, DerivedRH, DerivedVPD, DerivedWS, SolarRadiationAFNO1H, SolarRadiationAFNO6H,
       TCTrackerVitart, TCTrackerWuDuan

# Perturbation methods (earth2studio.perturbation)
export Gaussian, SphericalGaussian, CorrelatedSphericalGaussian, Brown,
       BredVector, LaggedEnsemble, HemisphericCentredBredVector, Zero

# IO backends (earth2studio.io)
export ZarrBackend, NetCDF4Backend, AsyncZarrBackend, XarrayBackend, KVBackend

# Statistics (earth2studio.statistics)
export RMSE, ACC, CRPS, MAE, MSE, FSS, Variance, Mean, SpreadSkillRatio, RankHistogram,
       BrierScore, LogScore, ReliabilityDiagram

# Run workflows
export run_deterministic, run_ensemble, run_diagnostic

# Fetch helper
export fetch_data

# Device placement
export to_device!

# IO utilities
export to_xarray

# Conversion / interop helpers
export pymodule, py_object, xarray_to_dict, datetime_to_np64, np64_to_datetime
export is_pymodule_available, pymodule_error

#--------------------------------------------------------------------------------# Lazy Python module table
const PYMODULES = Dict{Symbol, Union{Py, Exception}}()

const _SUBMODULES = (
    :earth2studio => "earth2studio",
    :data         => "earth2studio.data",
    :models_px    => "earth2studio.models.px",
    :models_dx    => "earth2studio.models.dx",
    :perturbation => "earth2studio.perturbation",
    :io           => "earth2studio.io",
    :run          => "earth2studio.run",
    :statistics   => "earth2studio.statistics",
    :utils        => "earth2studio.utils",
    :xarray       => "xarray",
    :numpy        => "numpy",
    :torch        => "torch",
)

function _try_import!(key::Symbol, name::AbstractString)
    try
        PYMODULES[key] = pyimport(name)
    catch e
        PYMODULES[key] = e
    end
    return nothing
end

function __init__()
    for (key, name) in _SUBMODULES
        _try_import!(key, name)
    end
    return nothing
end

function pymodule(key::Symbol)
    v = get(PYMODULES, key) do
        error("Earth2Studio: unknown pymodule key :$key. Known: $(keys(PYMODULES))")
    end
    v isa Py && return v
    throw(v)
end

is_pymodule_available(key::Symbol) = haskey(PYMODULES, key) && PYMODULES[key] isa Py
pymodule_error(key::Symbol) = haskey(PYMODULES, key) && !(PYMODULES[key] isa Py) ? PYMODULES[key] : nothing

include("convert.jl")
include("types.jl")
include("data.jl")
include("models.jl")
include("perturbation.jl")
include("io.jl")
include("run.jl")
include("statistics.jl")

end # module
