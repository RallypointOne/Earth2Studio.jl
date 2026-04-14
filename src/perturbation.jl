#--------------------------------------------------------------------------------# Perturbation methods (earth2studio.perturbation)

"""
    Gaussian(; kwargs...)

Gaussian noise perturbation.
"""
Gaussian(; kwargs...) = Perturbation(pymodule(:perturbation).Gaussian(; kwargs...))

"""
    SphericalGaussian(; kwargs...)

Spherical Gaussian noise perturbation (latitude-weighted).
"""
SphericalGaussian(; kwargs...) = Perturbation(pymodule(:perturbation).SphericalGaussian(; kwargs...))

"""
    CorrelatedSphericalGaussian(; kwargs...)

Correlated spherical Gaussian perturbation.
"""
CorrelatedSphericalGaussian(; kwargs...) = Perturbation(pymodule(:perturbation).CorrelatedSphericalGaussian(; kwargs...))

"""
    Brown(; kwargs...)

Brownian noise perturbation.
"""
Brown(; kwargs...) = Perturbation(pymodule(:perturbation).Brown(; kwargs...))

"""
    BredVector(; kwargs...)

Bred vector ensemble perturbation method.
"""
BredVector(; kwargs...) = Perturbation(pymodule(:perturbation).BredVector(; kwargs...))

"""
    LaggedEnsemble(; kwargs...)

Lagged average ensemble perturbation.
"""
LaggedEnsemble(; kwargs...) = Perturbation(pymodule(:perturbation).LaggedEnsemble(; kwargs...))

"""
    HemisphericCentredBredVector(; kwargs...)

Hemispheric-centred bred vector perturbation method.
"""
HemisphericCentredBredVector(; kwargs...) = Perturbation(pymodule(:perturbation).HemisphericCentredBredVector(; kwargs...))

"""
    Zero(; kwargs...)

Zero (no-op) perturbation. Useful for deterministic runs or testing.
"""
Zero(; kwargs...) = Perturbation(pymodule(:perturbation).Zero(; kwargs...))

"""
    Perturbation(class_name::AbstractString; kwargs...)

Construct a `Perturbation` from an arbitrary `earth2studio.perturbation` class name.

### Examples
```julia
p = Perturbation("Gaussian"; noise_amplitude=0.05)
```
"""
function Perturbation(class_name::AbstractString; kwargs...)
    Perturbation(getproperty(pymodule(:perturbation), Symbol(class_name))(; kwargs...))
end
