#--------------------------------------------------------------------------------# Time conversions

"""
    datetime_to_np64(dt::DateTime)
    datetime_to_np64(d::Date)

Convert a Julia `DateTime` or `Date` to a `numpy.datetime64` object.
"""
datetime_to_np64(dt::DateTime) = pymodule(:numpy).datetime64(Dates.format(dt, "yyyy-mm-ddTHH:MM:SS"))
datetime_to_np64(d::Date) = pymodule(:numpy).datetime64(Dates.format(d, "yyyy-mm-dd"))

"""
    datetimes_to_np64(ts::AbstractVector)

Convert a vector of `DateTime`/`Date` values to a numpy array of `datetime64`.
"""
function datetimes_to_np64(ts::AbstractVector)
    pymodule(:numpy).array(pylist([datetime_to_np64(t) for t in ts]))
end

"""
    np64_to_datetime(x::Py) -> DateTime

Convert a `numpy.datetime64` Python object back to a Julia `DateTime`. Nanosecond precision is truncated to seconds.
"""
function np64_to_datetime(x::Py)
    s = pyconvert(String, pymodule(:numpy).datetime_as_string(x, unit = "s"))
    DateTime(s)
end

#--------------------------------------------------------------------------------# Array conversions

"""
    xarray_to_dict(da::Py) -> NamedTuple

Convert an xarray `DataArray` to a Julia `NamedTuple` with fields `data`, `dims`, and `coords`.

### Examples
```julia
result = fetch_data(ds, DateTime(2024,1,1), "t2m")
result.data   # Array of values
result.dims   # (:time, :variable, :lat, :lon)
result.coords # NamedTuple of coordinate vectors
```
"""
function xarray_to_dict(da::Py)
    xr = pymodule(:xarray)
    pyconvert(Bool, pymodule(:numpy).ndim(da) isa Py || true)
    dims = Tuple(Symbol(pyconvert(String, d)) for d in da.dims)
    data = pyconvert(Array, da.values)
    coords_dict = NamedTuple(
        Symbol(pyconvert(String, name)) => _coord_to_julia(da.coords[name].values)
        for name in da.coords
    )
    return (data = data, dims = dims, coords = coords_dict)
end

function _coord_to_julia(values::Py)
    dtype_kind = pyconvert(String, values.dtype.kind)
    if dtype_kind == "M"
        n = pyconvert(Int, pymodule(:numpy).size(values))
        arr = pymodule(:numpy).datetime_as_string(values, unit = "s")
        strs = pyconvert(Vector{String}, arr)
        return [DateTime(s) for s in strs]
    else
        return pyconvert(Array, values)
    end
end

"""
    xarray_dataset_to_dict(ds::Py) -> Dict{Symbol, NamedTuple}

Convert an xarray `Dataset` to a `Dict` mapping variable names to `NamedTuple`s (see [`xarray_to_dict`](@ref)).
"""
function xarray_dataset_to_dict(ds::Py)
    out = Dict{Symbol, NamedTuple}()
    for var_name in ds.data_vars
        key = Symbol(pyconvert(String, var_name))
        out[key] = xarray_to_dict(ds[var_name])
    end
    return out
end

#--------------------------------------------------------------------------------# Variables vector helpers

_to_pyvars(v::AbstractVector{<:AbstractString}) = pylist([pystr(s) for s in v])
_to_pyvars(v::AbstractVector{Symbol}) = pylist([pystr(String(s)) for s in v])
_to_pyvars(v::Py) = v

#--------------------------------------------------------------------------------# py_object

py_object(x) = x.py
py_object(x::Py) = x
