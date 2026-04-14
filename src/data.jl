#--------------------------------------------------------------------------------# Data sources

"""
    ARCO(; kwargs...)

Google's Analysis-Ready, Cloud-Optimized ERA5 dataset.
"""
ARCO(; kwargs...) = DataSource(pymodule(:data).ARCO(; kwargs...))

"""
    GFS(; kwargs...)

NOAA Global Forecast System data source.
"""
GFS(; kwargs...) = DataSource(pymodule(:data).GFS(; kwargs...))

"""
    GFS_FS(; kwargs...)

GFS forecast data source (as opposed to analysis).
"""
GFS_FS(; kwargs...) = DataSource(pymodule(:data).GFS_FS(; kwargs...))

"""
    IFS(; kwargs...)

ECMWF Integrated Forecasting System data source.
"""
IFS(; kwargs...) = DataSource(pymodule(:data).IFS(; kwargs...))

"""
    CDS(; kwargs...)

Copernicus Climate Data Store data source.
"""
CDS(; kwargs...) = DataSource(pymodule(:data).CDS(; kwargs...))

"""
    NCAR_ERA5(; kwargs...)

NCAR Research Data Archive ERA5 data source.
"""
NCAR_ERA5(; kwargs...) = DataSource(pymodule(:data).NCAR_ERA5(; kwargs...))

"""
    WB2ERA5(; kwargs...)

WeatherBench2 ERA5 data source (cloud-hosted on GCS).
"""
WB2ERA5(; kwargs...) = DataSource(pymodule(:data).WB2ERA5(; kwargs...))

"""
    WB2Climatology(; kwargs...)

WeatherBench2 climatology data source.
"""
WB2Climatology(; kwargs...) = DataSource(pymodule(:data).WB2Climatology(; kwargs...))

"""
    GOES(; kwargs...)

GOES satellite imagery data source.
"""
GOES(; kwargs...) = DataSource(pymodule(:data).GOES(; kwargs...))

"""
    MRMS(; kwargs...)

Multi-Radar Multi-Sensor precipitation data source.
"""
MRMS(; kwargs...) = DataSource(pymodule(:data).MRMS(; kwargs...))

"""
    HRRR(; kwargs...)

NOAA High-Resolution Rapid Refresh analysis data source.
"""
HRRR(; kwargs...) = DataSource(pymodule(:data).HRRR(; kwargs...))

"""
    HRRR_FX(; kwargs...)

NOAA High-Resolution Rapid Refresh forecast data source.
"""
HRRR_FX(; kwargs...) = DataSource(pymodule(:data).HRRR_FX(; kwargs...))

"""
    DataSource(class_name::AbstractString; kwargs...)

Construct a `DataSource` from an arbitrary `earth2studio.data` class name.

### Examples
```julia
ds = DataSource("CDS")
```
"""
function DataSource(class_name::AbstractString; kwargs...)
    DataSource(getproperty(pymodule(:data), Symbol(class_name))(; kwargs...))
end

#--------------------------------------------------------------------------------# Fetching

function (ds::DataSource)(time, variable)
    pytime = _to_pytime(time)
    pyvar = _to_pyvars(_as_vector(variable))
    ds.py(pytime, pyvar)
end

_as_vector(x::AbstractVector) = x
_as_vector(x::AbstractString) = [x]
_as_vector(x::Symbol) = [x]

_to_pytime(t::DateTime) = pylist([datetime_to_np64(t)])
_to_pytime(t::Date) = pylist([datetime_to_np64(t)])
_to_pytime(ts::AbstractVector{<:DateTime}) = datetimes_to_np64(ts)
_to_pytime(ts::AbstractVector{<:Date}) = datetimes_to_np64(ts)
_to_pytime(t::Py) = t

#--------------------------------------------------------------------------------# Convenience fetch

"""
    fetch_data(ds::DataSource, time, variable)

Fetch data and return a Julia `NamedTuple` with fields `data`, `dims`, and `coords`.

### Examples
```julia
ds = WB2ERA5()
result = fetch_data(ds, DateTime(2024, 1, 1), ["t2m", "u10m"])
result.data   # Array{Float32}
result.dims   # (:time, :variable, :lat, :lon)
result.coords # NamedTuple of coordinate vectors
```
"""
function fetch_data(ds::DataSource, time, variable)
    xarray_to_dict(ds(time, variable))
end
