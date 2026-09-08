using Test
using Dates
using Earth2Studio
using PythonCall: Py, pyconvert, pyhasattr, pyis, pyimport, pybuiltins

const NAMES = (:earth2studio, :data, :models, :perturbation, :io, :run, :statistics, :utils)

@testset "Earth2Studio" begin

#-------------------------------------------------------------------------------# Module surface
@testset "nothing is exported (avoids clashing with Base.run)" begin
    @test names(Earth2Studio) == [:Earth2Studio]
end

@testset "module references are Py objects" begin
    for name in NAMES
        @test isdefined(Earth2Studio, name)
        @test getfield(Earth2Studio, name) isa Py
    end
end

@testset "every module reference has a Julia docstring" begin
    meta = Base.Docs.meta(Earth2Studio)
    for name in NAMES
        b = Base.Docs.Binding(Earth2Studio, name)
        @test haskey(meta, b)
        text = join(meta[b].docs[Union{}].text, "")
        @test !isempty(strip(text))
    end
end

#-------------------------------------------------------------------------------# Submodule wiring
@testset "submodules resolve to expected dotted names" begin
    @test pyconvert(String, Earth2Studio.earth2studio.__name__) == "earth2studio"
    @test pyconvert(String, Earth2Studio.data.__name__)         == "earth2studio.data"
    @test pyconvert(String, Earth2Studio.models.__name__)       == "earth2studio.models"
    @test pyconvert(String, Earth2Studio.perturbation.__name__) == "earth2studio.perturbation"
    @test pyconvert(String, Earth2Studio.io.__name__)           == "earth2studio.io"
    @test pyconvert(String, Earth2Studio.run.__name__)          == "earth2studio.run"
    @test pyconvert(String, Earth2Studio.statistics.__name__)   == "earth2studio.statistics"
    @test pyconvert(String, Earth2Studio.utils.__name__)        == "earth2studio.utils"
end

@testset "references are the same Py objects as direct pyimport" begin
    @test pyis(Earth2Studio.earth2studio, pyimport("earth2studio"))
    @test pyis(Earth2Studio.data,         pyimport("earth2studio.data"))
    @test pyis(Earth2Studio.models,       pyimport("earth2studio.models"))
    @test pyis(Earth2Studio.perturbation, pyimport("earth2studio.perturbation"))
    @test pyis(Earth2Studio.io,           pyimport("earth2studio.io"))
    @test pyis(Earth2Studio.run,          pyimport("earth2studio.run"))
    @test pyis(Earth2Studio.statistics,   pyimport("earth2studio.statistics"))
    @test pyis(Earth2Studio.utils,        pyimport("earth2studio.utils"))
end

#-------------------------------------------------------------------------------# SSL certificate bundle
@testset "SSL_CERT_FILE points Python at an existing bundle" begin
    environ = pyimport("os").environ
    @test pyconvert(Bool, environ.__contains__("SSL_CERT_FILE"))
    @test isfile(pyconvert(String, environ["SSL_CERT_FILE"]))
end

#-------------------------------------------------------------------------------# Reachable upstream API
@testset "data submodule" begin
    @testset "$cls" for cls in ("ARCO", "GFS", "GFS_FX", "IFS", "CDS", "WB2ERA5", "WB2Climatology", "HRRR", "HRRR_FX", "GOES", "MRMS", "NCAR_ERA5")
        @test pyhasattr(Earth2Studio.data, cls)
    end
end

@testset "models.px and models.dx" begin
    px = Earth2Studio.models.px
    dx = Earth2Studio.models.dx
    @test pyconvert(String, px.__name__) == "earth2studio.models.px"
    @test pyconvert(String, dx.__name__) == "earth2studio.models.dx"
    @testset "px.$cls" for cls in ("FCN", "FCN3", "Pangu24", "Pangu6", "Pangu3", "GraphCastSmall", "AIFS", "Aurora", "Persistence")
        @test pyhasattr(px, cls)
    end
    @testset "dx.$cls" for cls in ("CorrDiff", "PrecipitationAFNO", "ClimateNet", "DerivedRH", "DerivedVPD", "DerivedWS")
        @test pyhasattr(dx, cls)
    end
end

@testset "perturbation submodule" begin
    @testset "$cls" for cls in ("Gaussian", "SphericalGaussian", "CorrelatedSphericalGaussian",
                                "Brown", "BredVector", "LaggedEnsemble", "HemisphericCentredBredVector", "Zero")
        @test pyhasattr(Earth2Studio.perturbation, cls)
    end
end

@testset "io submodule" begin
    @testset "$cls" for cls in ("ZarrBackend", "AsyncZarrBackend", "NetCDF4Backend", "XarrayBackend", "KVBackend")
        @test pyhasattr(Earth2Studio.io, cls)
    end
end

@testset "run submodule" begin
    @testset "$fn" for fn in ("deterministic", "ensemble", "diagnostic")
        @test pyhasattr(Earth2Studio.run, fn)
    end
end

@testset "statistics submodule" begin
    @testset "$fn" for fn in ("rmse", "mae", "acc", "crps", "fss", "variance", "mean", "rank_histogram", "brier_score", "spread_skill_ratio", "log_spectral_distance")
        @test pyhasattr(Earth2Studio.statistics, fn)
    end
end

#-------------------------------------------------------------------------------# Auto-conversion of Julia types
@testset "DateTime / String auto-conversion" begin
    py_datetime = pyimport("datetime").datetime
    py_str = pybuiltins.str

    # Single DateTime -> datetime.datetime
    p = Py(DateTime(2023, 6, 15, 12, 30))
    @test pyconvert(Bool, pybuiltins.isinstance(p, py_datetime))

    # Vector{DateTime} -> iterable yielding datetime.datetime
    pv = Py([DateTime(2023, 6, 15), DateTime(2023, 6, 16)])
    @test pyconvert(Int, pybuiltins.len(pv)) == 2
    @test pyconvert(Bool, pybuiltins.isinstance(pv[0], py_datetime))
    @test pyconvert(Bool, pybuiltins.isinstance(pv[1], py_datetime))

    # String -> str
    @test pyconvert(Bool, pybuiltins.isinstance(Py("t2m"), py_str))

    # Vector{String} -> iterable yielding str
    pv = Py(["t2m", "u10m"])
    @test pyconvert(Int, pybuiltins.len(pv)) == 2
    @test pyconvert(Bool, pybuiltins.isinstance(pv[0], py_str))
end

end
