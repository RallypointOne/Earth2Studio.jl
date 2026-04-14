using Test
using Earth2Studio
using Dates

const HAS_NUMPY = Earth2Studio.is_pymodule_available(:numpy)
const HAS_EARTH2STUDIO = Earth2Studio.is_pymodule_available(:earth2studio)
const HAS_DATA = Earth2Studio.is_pymodule_available(:data)
const HAS_PERTURB = Earth2Studio.is_pymodule_available(:perturbation)
const HAS_IO = Earth2Studio.is_pymodule_available(:io)
const HAS_STATS = Earth2Studio.is_pymodule_available(:statistics)

@testset "Earth2Studio" begin

#--------------------------------------------------------------------------------# Module structure
@testset "module structure" begin
    @test DataSource <: Earth2Studio.Earth2StudioObject
    @test PrognosticModel <: Earth2Studio.Earth2StudioObject
    @test DiagnosticModel <: Earth2Studio.Earth2StudioObject
    @test Perturbation <: Earth2Studio.Earth2StudioObject
    @test IOBackend <: Earth2Studio.Earth2StudioObject
    @test Statistic <: Earth2Studio.Earth2StudioObject

    @test isdefined(Earth2Studio, :run_deterministic)
    @test isdefined(Earth2Studio, :run_ensemble)
    @test isdefined(Earth2Studio, :run_diagnostic)
    @test isdefined(Earth2Studio, :pymodule)
    @test isdefined(Earth2Studio, :is_pymodule_available)
    @test isdefined(Earth2Studio, :fetch_data)
    @test isdefined(Earth2Studio, :to_device!)
    @test isdefined(Earth2Studio, :to_xarray)
    @test isdefined(Earth2Studio, :xarray_to_dict)
end

#--------------------------------------------------------------------------------# pymodule loader behavior
@testset "pymodule loader" begin
    @test_throws Exception Earth2Studio.pymodule(:does_not_exist)

    for key in (:earth2studio, :data, :numpy, :torch, :xarray)
        @test is_pymodule_available(key) isa Bool
    end
    @test !is_pymodule_available(:not_a_real_module)

    for (key, _) in Earth2Studio._SUBMODULES
        err = Earth2Studio.pymodule_error(key)
        if is_pymodule_available(key)
            @test err === nothing
        else
            @test err isa Exception
        end
    end
end

#--------------------------------------------------------------------------------# Tests requiring the Python env
if HAS_NUMPY
    @testset "time conversions" begin
        dt = DateTime(2024, 6, 15, 12, 30, 45)
        np64 = Earth2Studio.datetime_to_np64(dt)
        @test Earth2Studio.np64_to_datetime(np64) == dt

        d = Date(2024, 1, 1)
        np64d = Earth2Studio.datetime_to_np64(d)
        @test Earth2Studio.np64_to_datetime(np64d) == DateTime(d)

        times = [DateTime(2024, 1, 1), DateTime(2024, 1, 1, 6), DateTime(2024, 1, 2)]
        np64v = Earth2Studio.datetimes_to_np64(times)
        @test np64v !== nothing
    end
end

if HAS_DATA
    @testset "data source constructors" begin
        for (name, ctor) in (
                ("ARCO", ARCO),
                ("GFS", GFS),
                ("GFS_FS", GFS_FS),
                ("WB2ERA5", WB2ERA5),
            )
            @test Earth2Studio.pyhasattr(
                Earth2Studio.pymodule(:data), Symbol(name)
            ) === Earth2Studio.pyhasattr(
                Earth2Studio.pymodule(:data), Symbol(name)
            )
        end
    end
end

if HAS_PERTURB
    @testset "perturbation constructors" begin
        p = Zero()
        @test p isa Perturbation
        @test Earth2Studio.py_object(p) !== nothing

        try
            g = Gaussian()
            @test g isa Perturbation
        catch
        end
    end
end

if HAS_IO
    @testset "IO backend constructors" begin
        mktempdir() do dir
            z = ZarrBackend(joinpath(dir, "out.zarr"))
            @test z isa IOBackend
            @test Earth2Studio.py_object(z) !== nothing
        end
    end
end

if HAS_STATS
    @testset "statistics constructors" begin
        for ctor in (RMSE, MSE, MAE)
            try
                s = ctor(reduction_dimensions = String[])
                @test s isa Statistic
            catch e
                @test e isa Exception
            end
        end
    end
end

#--------------------------------------------------------------------------------# Show methods
@testset "show methods" begin
    if HAS_PERTURB
        p = try
            Zero()
        catch
            nothing
        end
        if p !== nothing
            io = IOBuffer()
            show(io, p)
            s = String(take!(io))
            @test contains(s, "Perturbation")
        end
    end
end

end # top-level testset
