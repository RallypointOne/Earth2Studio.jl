#--------------------------------------------------------------------------------# IO backends (earth2studio.io)

"""
    ZarrBackend(path::AbstractString; kwargs...)
    ZarrBackend(; kwargs...)

Zarr storage backend for writing forecast results to disk.
"""
ZarrBackend(path::AbstractString; kwargs...) = IOBackend(pymodule(:io).ZarrBackend(path; kwargs...))
ZarrBackend(; kwargs...) = IOBackend(pymodule(:io).ZarrBackend(; kwargs...))

"""
    AsyncZarrBackend(path::AbstractString; kwargs...)
    AsyncZarrBackend(; kwargs...)

Asynchronous Zarr storage backend.
"""
AsyncZarrBackend(path::AbstractString; kwargs...) = IOBackend(pymodule(:io).AsyncZarrBackend(path; kwargs...))
AsyncZarrBackend(; kwargs...) = IOBackend(pymodule(:io).AsyncZarrBackend(; kwargs...))

"""
    NetCDF4Backend(path::AbstractString; kwargs...)
    NetCDF4Backend(; kwargs...)

NetCDF4 file storage backend.
"""
NetCDF4Backend(path::AbstractString; kwargs...) = IOBackend(pymodule(:io).NetCDF4Backend(path; kwargs...))
NetCDF4Backend(; kwargs...) = IOBackend(pymodule(:io).NetCDF4Backend(; kwargs...))

"""
    XarrayBackend(; kwargs...)

In-memory xarray Dataset backend (results stay in Python memory).
"""
XarrayBackend(; kwargs...) = IOBackend(pymodule(:io).XarrayBackend(; kwargs...))

"""
    KVBackend(; kwargs...)

Key-value store backend.
"""
KVBackend(; kwargs...) = IOBackend(pymodule(:io).KVBackend(; kwargs...))

"""
    IOBackend(class_name::AbstractString, args...; kwargs...)

Construct an `IOBackend` from an arbitrary `earth2studio.io` class name.

### Examples
```julia
io = IOBackend("ZarrBackend", "/tmp/output.zarr")
```
"""
function IOBackend(class_name::AbstractString, args...; kwargs...)
    IOBackend(getproperty(pymodule(:io), Symbol(class_name))(args...; kwargs...))
end

#--------------------------------------------------------------------------------# Reading results back into Julia

"""
    to_xarray(io::IOBackend)

Return the xarray Dataset stored in an `IOBackend` after a workflow run completes.

### Examples
```julia
io = ZarrBackend("/tmp/forecast.zarr")
io = run_deterministic(time, 10, model, data, io)
ds = to_xarray(io)
```
"""
function to_xarray(io::IOBackend)
    py = io.py
    if pyhasattr(py, "root")
        return py.root
    elseif pyhasattr(py, "_root")
        return py._root
    else
        error("Earth2Studio: IOBackend $(typeof(py)) has no accessible xarray root")
    end
end
