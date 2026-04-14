#--------------------------------------------------------------------------------# Statistics / verification metrics (earth2studio.statistics)

"""
    RMSE(; kwargs...)

Root Mean Square Error metric.
"""
RMSE(; kwargs...) = Statistic(pymodule(:statistics).rmse(; kwargs...))

"""
    MAE(; kwargs...)

Mean Absolute Error metric.
"""
MAE(; kwargs...) = Statistic(pymodule(:statistics).mae(; kwargs...))

"""
    MSE(; kwargs...)

Mean Squared Error metric.
"""
MSE(; kwargs...) = Statistic(pymodule(:statistics).mse(; kwargs...))

"""
    ACC(; kwargs...)

Anomaly Correlation Coefficient metric.
"""
ACC(; kwargs...) = Statistic(pymodule(:statistics).acc(; kwargs...))

"""
    CRPS(; kwargs...)

Continuous Ranked Probability Score metric.
"""
CRPS(; kwargs...) = Statistic(pymodule(:statistics).crps(; kwargs...))

"""
    FSS(; kwargs...)

Fractions Skill Score metric.
"""
FSS(; kwargs...) = Statistic(pymodule(:statistics).fss(; kwargs...))

"""
    Variance(; kwargs...)

Variance statistic.
"""
Variance(; kwargs...) = Statistic(pymodule(:statistics).variance(; kwargs...))

"""
    Mean(; kwargs...)

Mean statistic.
"""
Mean(; kwargs...) = Statistic(pymodule(:statistics).mean(; kwargs...))

"""
    SpreadSkillRatio(; kwargs...)

Spread-skill ratio metric for ensemble calibration.
"""
SpreadSkillRatio(; kwargs...) = Statistic(pymodule(:statistics).spread_skill_ratio(; kwargs...))

"""
    RankHistogram(; kwargs...)

Rank histogram for ensemble reliability.
"""
RankHistogram(; kwargs...) = Statistic(pymodule(:statistics).rank_histogram(; kwargs...))

"""
    BrierScore(; kwargs...)

Brier Score for probabilistic binary forecasts.
"""
BrierScore(; kwargs...) = Statistic(pymodule(:statistics).brier_score(; kwargs...))

"""
    LogScore(; kwargs...)

Logarithmic scoring rule for probabilistic forecasts.
"""
LogScore(; kwargs...) = Statistic(pymodule(:statistics).log_score(; kwargs...))

"""
    ReliabilityDiagram(; kwargs...)

Reliability diagram data for probabilistic forecast calibration.
"""
ReliabilityDiagram(; kwargs...) = Statistic(pymodule(:statistics).reliability_diagram(; kwargs...))

"""
    Statistic(name::AbstractString; kwargs...)

Construct a `Statistic` from an arbitrary `earth2studio.statistics` function name.

### Examples
```julia
s = Statistic("rmse"; reduction_dimensions=String[])
```
"""
function Statistic(name::AbstractString; kwargs...)
    fn = getproperty(pymodule(:statistics), Symbol(name))
    Statistic(fn(; kwargs...))
end

function (s::Statistic)(args...; kwargs...)
    pyargs = Any[arg isa Earth2StudioObject ? arg.py : arg for arg in args]
    s.py(pyargs...; kwargs...)
end
