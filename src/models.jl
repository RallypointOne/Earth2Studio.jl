#--------------------------------------------------------------------------------# Prognostic models (earth2studio.models.px)

function _load_px(class_name::Symbol; package = nothing, kwargs...)
    cls = getproperty(pymodule(:models_px), class_name)
    pkg = package === nothing ? cls.load_default_package() : package
    PrognosticModel(cls.load_model(pkg; kwargs...))
end

"""
    FourCastNet(; kwargs...)

NVIDIA FourCastNet v1/v2 global weather model.
"""
FourCastNet(; kwargs...) = _load_px(:FCN; kwargs...)

"""
    FCN3(; kwargs...)

FourCastNet v3 global weather model.
"""
FCN3(; kwargs...) = _load_px(:FCN3; kwargs...)

"""
    Pangu24(; kwargs...)

Pangu-Weather 24-hour step model.
"""
Pangu24(; kwargs...) = _load_px(:Pangu24; kwargs...)

"""
    Pangu6(; kwargs...)

Pangu-Weather 6-hour step model.
"""
Pangu6(; kwargs...) = _load_px(:Pangu6; kwargs...)

"""
    Pangu3(; kwargs...)

Pangu-Weather 3-hour step model.
"""
Pangu3(; kwargs...) = _load_px(:Pangu3; kwargs...)

"""
    GraphCast(; kwargs...)

DeepMind GraphCast (small variant) weather model.
"""
GraphCast(; kwargs...) = _load_px(:GraphCastSmall; kwargs...)

"""
    GraphCastOper(; kwargs...)

DeepMind GraphCast operational variant.
"""
GraphCastOper(; kwargs...) = _load_px(:GraphCastOperational; kwargs...)

"""
    AIFS(; kwargs...)

ECMWF AIFS (Artificial Intelligence Forecasting System) model.
"""
AIFS(; kwargs...) = _load_px(:AIFS; kwargs...)

"""
    AIFSENS(; kwargs...)

ECMWF AIFS ensemble model variant.
"""
AIFSENS(; kwargs...) = _load_px(:AIFSENS; kwargs...)

"""
    Aurora(; kwargs...)

Microsoft Aurora foundation model for weather.
"""
Aurora(; kwargs...) = _load_px(:Aurora; kwargs...)

"""
    FengWu(; kwargs...)

Shanghai AI Lab FengWu weather model.
"""
FengWu(; kwargs...) = _load_px(:FengWu; kwargs...)

"""
    DLWP(; kwargs...)

Deep Learning Weather Prediction model.
"""
DLWP(; kwargs...) = _load_px(:DLWP; kwargs...)

"""
    StormCast(; kwargs...)

NVIDIA StormCast high-resolution convective model.
"""
StormCast(; kwargs...) = _load_px(:StormCast; kwargs...)

"""
    InterpModAFNO(; kwargs...)

Interpolation model using AFNO backbone.
"""
InterpModAFNO(; kwargs...) = _load_px(:InterpModAFNO; kwargs...)

"""
    Persistence(; kwargs...)

Persistence (no-skill baseline) forecast model.
"""
Persistence(; kwargs...) = _load_px(:Persistence; kwargs...)

"""
    PrognosticModel(class_name::AbstractString; kwargs...)

Construct a `PrognosticModel` from an arbitrary `earth2studio.models.px` class name.

### Examples
```julia
model = PrognosticModel("FCN")
```
"""
function PrognosticModel(class_name::AbstractString; kwargs...)
    _load_px(Symbol(class_name); kwargs...)
end

#--------------------------------------------------------------------------------# Diagnostic models (earth2studio.models.dx)

function _load_dx(class_name::Symbol; package = nothing, kwargs...)
    cls = getproperty(pymodule(:models_dx), class_name)
    pkg = package === nothing ? cls.load_default_package() : package
    DiagnosticModel(cls.load_model(pkg; kwargs...))
end

"""
    CorrDiff(; kwargs...)

NVIDIA CorrDiff generative downscaling model.
"""
CorrDiff(; kwargs...) = _load_dx(:CorrDiff; kwargs...)

"""
    CorrDiffTaiwan(; kwargs...)

CorrDiff model trained on Taiwan domain.
"""
CorrDiffTaiwan(; kwargs...) = _load_dx(:CorrDiffTaiwan; kwargs...)

"""
    CorrDiffCMIP6(; kwargs...)

CorrDiff model trained on CMIP6 data.
"""
CorrDiffCMIP6(; kwargs...) = _load_dx(:CorrDiffCMIP6; kwargs...)

"""
    PrecipitationAFNO(; kwargs...)

AFNO-based precipitation diagnostic model.
"""
PrecipitationAFNO(; kwargs...) = _load_dx(:PrecipitationAFNO; kwargs...)

"""
    PrecipitationAFNOv2(; kwargs...)

AFNO-based precipitation diagnostic model (v2).
"""
PrecipitationAFNOv2(; kwargs...) = _load_dx(:PrecipitationAFNOv2; kwargs...)

"""
    ClimateNet(; kwargs...)

ClimateNet extreme weather event detection model.
"""
ClimateNet(; kwargs...) = _load_dx(:ClimateNet; kwargs...)

"""
    SolarRadiationAFNO1H(; kwargs...)

AFNO-based solar radiation model (1-hour resolution).
"""
SolarRadiationAFNO1H(; kwargs...) = _load_dx(:SolarRadiationAFNO1H; kwargs...)

"""
    SolarRadiationAFNO6H(; kwargs...)

AFNO-based solar radiation model (6-hour resolution).
"""
SolarRadiationAFNO6H(; kwargs...) = _load_dx(:SolarRadiationAFNO6H; kwargs...)

"""
    TCTrackerVitart(; kwargs...)

Tropical cyclone tracker using Vitart algorithm.
"""
TCTrackerVitart(; kwargs...) = _load_dx(:TCTrackerVitart; kwargs...)

"""
    TCTrackerWuDuan(; kwargs...)

Tropical cyclone tracker using Wu-Duan algorithm.
"""
TCTrackerWuDuan(; kwargs...) = _load_dx(:TCTrackerWuDuan; kwargs...)

"""
    DerivedRH(; kwargs...)

Derived relative humidity diagnostic (analytic, no model weights).
"""
DerivedRH(; kwargs...) = DiagnosticModel(pymodule(:models_dx).DerivedRH(; kwargs...))

"""
    DerivedVPD(; kwargs...)

Derived vapor pressure deficit diagnostic (analytic, no model weights).
"""
DerivedVPD(; kwargs...) = DiagnosticModel(pymodule(:models_dx).DerivedVPD(; kwargs...))

"""
    DerivedWS(; kwargs...)

Derived wind speed diagnostic (analytic, no model weights).
"""
DerivedWS(; kwargs...) = DiagnosticModel(pymodule(:models_dx).DerivedWS(; kwargs...))

"""
    DiagnosticModel(class_name::AbstractString; kwargs...)

Construct a `DiagnosticModel` from an arbitrary `earth2studio.models.dx` class name.

### Examples
```julia
model = DiagnosticModel("CorrDiff")
```
"""
function DiagnosticModel(class_name::AbstractString; kwargs...)
    cls = getproperty(pymodule(:models_dx), Symbol(class_name))
    if pyhasattr(cls, "load_default_package")
        pkg = cls.load_default_package()
        DiagnosticModel(cls.load_model(pkg; kwargs...))
    else
        DiagnosticModel(cls(; kwargs...))
    end
end

#--------------------------------------------------------------------------------# Device placement

"""
    to_device!(model, device::AbstractString)

Move a prognostic or diagnostic model to the specified device (e.g. `"cuda"`, `"cpu"`).

### Examples
```julia
model = Pangu24()
to_device!(model, "cuda")
```
"""
to_device!(m::Union{PrognosticModel, DiagnosticModel}, device::AbstractString) = (m.py.to(device); m)
