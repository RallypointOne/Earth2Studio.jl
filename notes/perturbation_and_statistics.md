# Perturbation and Statistics Systems

## Core Type

Both systems operate on `(torch.Tensor, CoordSystem)` pairs where `CoordSystem = OrderedDict[str, np.ndarray]`.

---

## Perturbation System

### Protocol

```python
class Perturbation(Protocol):
    def __call__(self, x: torch.Tensor, coords: CoordSystem) -> tuple[torch.Tensor, CoordSystem]: ...
```

### Available Methods (8 total)

#### Simple Noise

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| **Zero** | No-op (deterministic member) | none |
| **Gaussian** | `x + amplitude * randn_like(x)` | `noise_amplitude=0.05` |
| **Brown** | Spatially correlated (red) noise via FFT2 | `noise_amplitude=0.05`, `reddening=2` |

Brown noise algorithm: white noise -> FFT2 -> multiply by `1/(|freq|^reddening)` spectral filter -> IFFT2.

#### Spherical Methods

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| **SphericalGaussian** | Matern covariance via spherical harmonic transform | `alpha=2.0`, `tau=3.0` |
| **CorrelatedSphericalGaussian** | HENS/SPPT-style AR(1) process in spectral space | `length_scale=5e5m`, `time_scale=48h` |

SphericalGaussian uses `torch_harmonics.InverseRealSHT` for the Karhunen-Loeve expansion.

CorrelatedSphericalGaussian (from Mahesh et al. 2024 "Huge Ensembles Part I") uses an AR(1) process: `coeff_new = phi * coeff_old + sigma_n * noise` where `phi = exp(-dt/time_scale)`.

#### Model-Based Methods

| Method | Description | Key Parameters |
|--------|-------------|----------------|
| **BredVector** | Classical bred vectors | `model`, `integration_steps=20`, `seeding=Brown()` |
| **HemisphericCentredBredVector** | HENS-style bred vectors | `model`, `data`, `integration_steps=3` |
| **LaggedEnsemble** | Replace ICs with different initialization times | `source`, `lags` |

BredVector algorithm:
1. Seed perturbation `dx` using seeding method
2. For N steps: run `x + dx` through model, compute difference, rescale
3. Return `x + amplitude * normalized_dx`

HemisphericCentredBredVector adds:
- Separate NH/SH scaling (>70 deg) with tropical interpolation
- Centered perturbations: yields both `x + dx` and `x - dx`
- Clips non-negative variables to zero

LaggedEnsemble: no noise added — each ensemble member uses ICs from a different time.

---

## Statistics System

### Two Protocols

**Statistic** (single tensor):
```python
class Statistic(Protocol):
    reduction_dimensions: list[str]
    def output_coords(self, input_coords: CoordSystem) -> CoordSystem: ...
    def __call__(self, x: Tensor, coords: CoordSystem) -> tuple[Tensor, CoordSystem]: ...
```

**Metric** (two tensors — forecast vs. observation):
```python
class Metric(Protocol):
    reduction_dimensions: list[str]
    def output_coords(self, input_coords: CoordSystem) -> CoordSystem: ...
    def __call__(self, x: Tensor, x_coords: CoordSystem, y: Tensor, y_coords: CoordSystem) -> tuple[Tensor, CoordSystem]: ...
```

Key design: `reduction_dimensions` are declared upfront and removed from output coords.

### Moment Statistics (Statistic protocol)

| Statistic | Formula | Batch Update |
|-----------|---------|-------------|
| **mean** | `sum(w*x) / sum(w)` | Running sum + count |
| **variance** | Bessel-corrected weighted variance | Parallel/incremental algorithm |
| **std** | `sqrt(variance)` | Via variance |

### Error Metrics (Metric protocol)

| Metric | Formula | Notes |
|--------|---------|-------|
| **rmse** | `sqrt(mean((x-y)^2))` | Optional ensemble mean first |
| **mae** | `mean(abs(x-y))` | Subclasses rmse |
| **spread_skill_ratio** | `sqrt(mean(var(x, ens))) / rmse(mean(x, ens), y)` | Uses 4 internal stats |
| **skill_spread** | Returns MSE and variance separately | Stacked with "metric" dim |

### Probabilistic Metrics (Metric protocol)

| Metric | Description | Key Details |
|--------|-------------|-------------|
| **acc** | Anomaly Correlation Coefficient | Optional climatology subtraction; Pearson correlation of anomalies |
| **crps** | Continuous Ranked Probability Score | CDF integration method; `fair=True` uses unbiased estimator |
| **brier_score** | Exceedance probability skill | Multiple thresholds; adds "threshold" coord |
| **energy_score** | Multivariate CRPS (cross-variable correlations) | Uses `torch.cdist`; fair version available |
| **fss** | Fractions Skill Score | 2D convolution with circular window; multiple window sizes + thresholds |
| **log_spectral_distance** | Power spectrum comparison in dB | Requires `physicsnemo`; optional wavenumber cutoff |
| **rank_histogram** | Rank of observation in ensemble | Optional tie randomization; outputs bin centers + counts |

### Batch Update Pattern

Several statistics support `batch_update=True` for streaming/online computation:
- **mean**: running `sum` and `n`
- **variance**: parallel/incremental algorithm with second-order correction
- **rmse**: delegates to mean with batch_update, applies sqrt at query
- **brier_score, fss**: forward batch_update to internal mean instances

### Weight Utilities

- `_broadcast_weights(weights, reduction_dims, coords)`: broadcasts weight tensor to full shape
- `lat_weight(lat)`: cosine latitude weighting normalized to mean=1

---

## Julia Rewrite Considerations

### Perturbation
- Abstract type `AbstractPerturbation` with functor pattern `(p::MyPert)(x, coords)`
- `SphericalGaussian` needs `FastSphericalHarmonics.jl` or similar
- `BredVector` takes a model as parameter — needs the model interface defined first
- Brown noise is straightforward with FFTW.jl

### Statistics
- Abstract types `AbstractStatistic` and `AbstractMetric`
- `reduction_dimensions` as a type parameter or field
- Batch update via mutable struct fields
- `OnlineStats.jl` could handle mean/variance streaming
- CRPS CDF implementation is self-contained (no external deps)
- FSS uses 2D convolution — `NNlib.jl` or manual FFT-based
- Energy score uses pairwise distances — `Distances.jl`
- `physicsnemo` dependencies (LSD, rank histogram, fair CRPS) need Julia ports
