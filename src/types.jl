#--------------------------------------------------------------------------------# Abstract base + shared behavior

abstract type Earth2StudioObject end

"""
    py_object(x::Earth2StudioObject)

Return the underlying Python object wrapped by `x`.
"""
py_object(x::Earth2StudioObject) = x.py

function Base.show(io::IO, x::Earth2StudioObject)
    py = x.py
    typename = split(last(split(string(typeof(x)), '.')), '{')[1]
    repr_str = try
        pyconvert(String, pymodule(:earth2studio).__builtins__.repr(py))
    catch
        try
            pyconvert(String, pystr(py))
        catch
            "<unrepresentable>"
        end
    end
    print(io, typename, "(", repr_str, ")")
end

Base.:(==)(a::T, b::T) where {T<:Earth2StudioObject} = pyconvert(Bool, a.py == b.py)

#--------------------------------------------------------------------------------# Concrete wrapper structs

"""
    DataSource

Wrapper around an `earth2studio.data.*` Python data source object.

Construct via named constructors like [`ARCO`](@ref), [`GFS`](@ref), etc.
"""
struct DataSource <: Earth2StudioObject
    py::Py
end

"""
    PrognosticModel

Wrapper around an `earth2studio.models.px.*` prognostic (forecast) model.

Construct via named constructors like [`FourCastNet`](@ref), [`Pangu24`](@ref), etc.
"""
struct PrognosticModel <: Earth2StudioObject
    py::Py
end

"""
    DiagnosticModel

Wrapper around an `earth2studio.models.dx.*` diagnostic model.

Construct via named constructors like [`CorrDiff`](@ref), [`ClimateNet`](@ref), etc.
"""
struct DiagnosticModel <: Earth2StudioObject
    py::Py
end

"""
    Perturbation

Wrapper around an `earth2studio.perturbation.*` perturbation method.

Construct via named constructors like [`Gaussian`](@ref), [`Zero`](@ref), etc.
"""
struct Perturbation <: Earth2StudioObject
    py::Py
end

"""
    IOBackend

Wrapper around an `earth2studio.io.*` IO backend for storing forecast results.

Construct via named constructors like [`ZarrBackend`](@ref), [`NetCDF4Backend`](@ref), etc.
"""
struct IOBackend <: Earth2StudioObject
    py::Py
end

"""
    Statistic

Wrapper around an `earth2studio.statistics.*` verification metric.

Construct via named constructors like [`RMSE`](@ref), [`ACC`](@ref), etc.
"""
struct Statistic <: Earth2StudioObject
    py::Py
end
