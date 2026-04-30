using Test
using Earth2Studio
using PythonCall: Py, pyconvert, pyhasattr, pyis, pyimport

const EXPORTS = (:earth2studio, :data, :models, :perturbation, :io, :run, :statistics, :utils)

@testset "Earth2Studio" begin

#-------------------------------------------------------------------------------# Module surface
@testset "exported names match expected set" begin
    exported = Set(filter(!=(:Earth2Studio), names(Earth2Studio)))
    @test exported == Set(EXPORTS)
end

@testset "exports are Py references" begin
    for name in EXPORTS
        @test isdefined(Earth2Studio, name)
        @test getfield(Earth2Studio, name) isa Py
    end
end

@testset "every export has a Julia docstring" begin
    meta = Base.Docs.meta(Earth2Studio)
    for name in EXPORTS
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

@testset "exports are the same Py objects as direct pyimport" begin
    @test pyis(Earth2Studio.earth2studio, pyimport("earth2studio"))
    @test pyis(Earth2Studio.data,         pyimport("earth2studio.data"))
    @test pyis(Earth2Studio.models,       pyimport("earth2studio.models"))
    @test pyis(Earth2Studio.perturbation, pyimport("earth2studio.perturbation"))
    @test pyis(Earth2Studio.io,           pyimport("earth2studio.io"))
    @test pyis(Earth2Studio.run,          pyimport("earth2studio.run"))
    @test pyis(Earth2Studio.statistics,   pyimport("earth2studio.statistics"))
    @test pyis(Earth2Studio.utils,        pyimport("earth2studio.utils"))
end

#-------------------------------------------------------------------------------# Reachable upstream API
@testset "data submodule" begin
    for cls in ("ARCO", "GFS", "GFS_FX", "IFS", "CDS", "WB2ERA5", "WB2Climatology", "HRRR", "HRRR_FX", "GOES", "MRMS", "NCAR_ERA5")
        @test pyhasattr(Earth2Studio.data, cls)
    end
end

@testset "models.px and models.dx" begin
    px = Earth2Studio.models.px
    dx = Earth2Studio.models.dx
    @test pyconvert(String, px.__name__) == "earth2studio.models.px"
    @test pyconvert(String, dx.__name__) == "earth2studio.models.dx"
    for cls in ("FCN", "FCN3", "Pangu24", "Pangu6", "Pangu3", "GraphCastSmall", "AIFS", "Aurora", "Persistence")
        @test pyhasattr(px, cls)
    end
    for cls in ("CorrDiff", "PrecipitationAFNO", "ClimateNet", "DerivedRH", "DerivedVPD", "DerivedWS")
        @test pyhasattr(dx, cls)
    end
end

@testset "perturbation submodule" begin
    for cls in ("Gaussian", "SphericalGaussian", "CorrelatedSphericalGaussian",
                "Brown", "BredVector", "LaggedEnsemble", "HemisphericCentredBredVector", "Zero")
        @test pyhasattr(Earth2Studio.perturbation, cls)
    end
end

@testset "io submodule" begin
    for cls in ("ZarrBackend", "AsyncZarrBackend", "NetCDF4Backend", "XarrayBackend", "KVBackend")
        @test pyhasattr(Earth2Studio.io, cls)
    end
end

@testset "run submodule" begin
    for fn in ("deterministic", "ensemble", "diagnostic")
        @test pyhasattr(Earth2Studio.run, fn)
    end
end

@testset "statistics submodule" begin
    for fn in ("rmse", "mae", "acc", "crps", "fss", "variance", "mean", "rank_histogram", "brier_score", "spread_skill_ratio", "log_spectral_distance")
        @test pyhasattr(Earth2Studio.statistics, fn)
    end
end

end
