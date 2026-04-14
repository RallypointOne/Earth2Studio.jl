#--------------------------------------------------------------------------------# Inference workflows (earth2studio.run)

"""
    run_deterministic(time, nsteps, prognostic, data, io; device=nothing, kwargs...)

Run a deterministic forecast for `nsteps` time steps. Returns the `IOBackend` containing results.

### Examples
```julia
io = run_deterministic(DateTime(2024, 1, 1), 10, model, data, ZarrBackend("/tmp/out.zarr"))
ds = to_xarray(io)
```
"""
function run_deterministic(
        time,
        nsteps::Integer,
        prognostic::PrognosticModel,
        data::DataSource,
        io::IOBackend;
        device = nothing,
        kwargs...,
    )
    pytime = _to_pytime(time)
    py_io = pymodule(:run).deterministic(
        pytime, nsteps, prognostic.py, data.py, io.py;
        _maybe_device(device)..., kwargs...,
    )
    IOBackend(py_io)
end

"""
    run_ensemble(time, nsteps, nensemble, prognostic, data, io, perturbation; batch_size=nothing, device=nothing, kwargs...)

Run an ensemble forecast with `nensemble` members. Returns the `IOBackend` containing results.

### Examples
```julia
io = run_ensemble(DateTime(2024,1,1), 10, 4, model, data, ZarrBackend("/tmp/out.zarr"), Zero())
ds = to_xarray(io)
```
"""
function run_ensemble(
        time,
        nsteps::Integer,
        nensemble::Integer,
        prognostic::PrognosticModel,
        data::DataSource,
        io::IOBackend,
        perturbation::Perturbation;
        batch_size::Union{Integer, Nothing} = nothing,
        device = nothing,
        kwargs...,
    )
    pytime = _to_pytime(time)
    bs = batch_size === nothing ? nensemble : batch_size
    py_io = pymodule(:run).ensemble(
        pytime, nsteps, nensemble,
        prognostic.py, data.py, io.py, perturbation.py;
        batch_size = bs,
        _maybe_device(device)..., kwargs...,
    )
    IOBackend(py_io)
end

"""
    run_diagnostic(time, nsteps, prognostic, diagnostic, data, io; device=nothing, kwargs...)

Run a forecast with a diagnostic model applied at each step. Returns the `IOBackend` containing results.

### Examples
```julia
io = run_diagnostic(DateTime(2024,1,1), 10, px_model, dx_model, data, ZarrBackend("/tmp/out.zarr"))
ds = to_xarray(io)
```
"""
function run_diagnostic(
        time,
        nsteps::Integer,
        prognostic::PrognosticModel,
        diagnostic::DiagnosticModel,
        data::DataSource,
        io::IOBackend;
        device = nothing,
        kwargs...,
    )
    pytime = _to_pytime(time)
    py_io = pymodule(:run).diagnostic(
        pytime, nsteps, prognostic.py, diagnostic.py, data.py, io.py;
        _maybe_device(device)..., kwargs...,
    )
    IOBackend(py_io)
end

_maybe_device(::Nothing) = NamedTuple()
_maybe_device(d::AbstractString) = (device = d,)
_maybe_device(d::Py) = (device = d,)
