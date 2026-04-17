# Lexicon (Variable Mapping) System

## Overview

The lexicon system maps Earth2Studio's **canonical variable names** (e.g., `"t2m"`, `"u500"`) to **source-specific identifiers** used by weather data providers and AI models. Each mapping also includes a **modifier function** for unit conversion.

## Canonical Variable Naming Scheme

~230 standardized variable names defined in `E2STUDIO_VOCAB` (purely documentary, not enforced at runtime).

### Surface Variables

| Name | Description | Unit |
|------|-------------|------|
| `t2m` | Temperature at 2m | K |
| `u10m`, `v10m` | Wind components at 10m | m/s |
| `d2m` | Dewpoint at 2m | K |
| `sp` | Surface pressure | Pa |
| `msl` | Mean sea level pressure | Pa |
| `tp` | Total precipitation | m |
| `sst` | Sea surface temperature | K |
| `sic` | Sea ice concentration | 0-1 |
| `tcwv` | Total column water vapor | kg/m^2 |
| `lsm` | Land-sea mask | - |
| `z` | Surface geopotential | m^2/s^2 |

### Pressure-Level Variables

Pattern: `{variable_prefix}{pressure_hPa}` (e.g., `u500`, `t850`, `z250`)

| Prefix | Meaning | Unit |
|--------|---------|------|
| `u` | u-wind | m/s |
| `v` | v-wind | m/s |
| `w` | vertical velocity | Pa/s |
| `z` | geopotential | m^2/s^2 |
| `t` | temperature | K |
| `r` | relative humidity | % |
| `q` | specific humidity | kg/kg |
| `ws` | wind speed | m/s |

Standard pressure levels in canonical vocab: 50, 100, 150, 200, 250, 300, 400, 500, 600, 700, 850, 925, 1000 hPa (13 levels).

### Specialized Families

- `abi01c`--`abi16c`: GOES ABI channels
- `viirs01i`--`viirs05i`: VIIRS I-bands (375m)
- `viirs01m`--`viirs16m`: VIIRS M-bands (750m)
- `s3sy*`: Sentinel-3 SYNERGY (AOD, surface reflectance)
- `atms`, `amsua`, `crisfsr`, `iasi`, etc.: Satellite sounder instruments
- `tp06`, `tp12`: Time-accumulated precipitation
- `aod550`, `duaod550`, etc.: Aerosol optical depth by species
- `tcco`, `tcno2`, `tco3`, `tcso2`: Total column trace gases
- `tc_lat`, `tc_lon`, `tc_msl`, `tc_w10m`: Tropical cyclone tracking

## Python Interface

Uses a metaclass (`LexiconType`) so lexicons are **class-level lookups** (not instances):

```python
GFSLexicon["t2m"]       # -> ("TMP::2 m above ground", <modifier_fn>)
"t2m" in GFSLexicon     # -> True
```

Each lexicon class provides:
1. `VOCAB` — dict mapping canonical names to source-specific identifiers
2. `get_item(cls, val)` — returns `(source_key, modifier_function)`

## VOCAB Value Formats (varies by source)

| Source | Format | Example |
|--------|--------|---------|
| GFS | `"PARAM::level"` | `"TMP::500 mb"` |
| GEFS | `"product::PARAM::level"` | `"pgrb2a::UGRD::500 mb"` |
| HRRR | `"product::PARAM::level::fcst_range"` | `"wrfsfc::TMP::2 m above ground::anl"` |
| CDS ERA5 | `"dataset::variable::pressure"` | `"reanalysis-era5-pressure-levels::temperature::500"` |
| ARCO, WB2 | `"variable::pressure"` | `"u_component_of_wind::500"` |
| IFS | `"param::level_type::level"` | `"u::pl::500"` |
| CMIP6 | `(var_name, level_int)` tuple | `("ua", 500)` |
| GOES/PC | `(nc_var, modifier_fn)` tuple | `("sst", x -> x + 273.15)` |
| JPSS | `(type, folder, dataset, fn)` 4-tuple | `("M", "VIIRS-M5-SDR", "Radiance", identity)` |

## Complete List of Lexicon Classes (32 total)

### Data Source Lexicons

| Class | Source | # Variables |
|-------|--------|------------|
| `GFSLexicon` | NOAA GFS (37 pressure levels) | Large |
| `GEFSLexicon` | NOAA GEFS 0.5deg | |
| `GEFSLexiconSel` | NOAA GEFS 0.25deg (select) | |
| `HRRRLexicon` | HRRR Analysis | 39 levels |
| `HRRRFXLexicon` | HRRR Forecast | |
| `CDSLexicon` | CDS ERA5 | 13 levels |
| `ARCOLexicon` | ARCO ERA5 | 37 levels |
| `WB2Lexicon` | WeatherBench2 | 13 levels |
| `WB2ClimatetologyLexicon` | WB2 Climatology | |
| `IFSLexicon` | ECMWF IFS Open Data | |
| `AIFSLexicon` | ECMWF AIFS | |
| `NCAR_ERA5Lexicon` | NCAR ERA5 on AWS | |
| `CAMSGlobalLexicon` | CAMS atmosphere | |
| `CMIP6Lexicon` | CMIP6 models | 10 levels |
| `GOESLexicon` | GOES ABI (AWS) | |
| `MRMSLexicon` | NOAA MRMS radar | |
| `ISDLexicon` | NOAA ISD stations | |
| `JPSSLexicon` | JPSS VIIRS SDR/EDR | |
| `JPSSATMSLexicon` | JPSS ATMS microwave | |
| `JPSSCrISLexicon` | JPSS CrIS infrared | |
| `MetOpAMSUALexicon` | MetOp AMSU-A | |
| `MetOpAVHRRLexicon` | MetOp AVHRR | |
| `MetOpMHSLexicon` | MetOp MHS | |
| `GSIConventionalLexicon` | UFS GSI conventional obs | |
| `GSISatelliteLexicon` | UFS GSI satellite obs | |
| `PlanetaryComputerOISSTLexicon` | PC OISST | |
| `PlanetaryComputerSentinel3AODLexicon` | PC Sentinel-3 | |
| `PlanetaryComputerMODISFireLexicon` | PC MODIS fire | |
| `PlanetaryComputerECMWFOpenDataIFSLexicon` | PC ECMWF IFS | |
| `PlanetaryComputerGOESLexicon` | PC GOES ABI | |

### Model Lexicons

| Class | Model | Notes |
|-------|-------|-------|
| `ACELexicon` | NVIDIA ACE/FME | Bidirectional (has `VOCAB_REVERSE`) |
| `CBottleLexicon` | NVIDIA CBottle | Values are `(name, level)` tuples |

## Modifier Functions (Unit Conversions)

| Conversion | Where Used | Formula |
|-----------|-----------|---------|
| Geopotential height -> geopotential | GFS, GEFS, HRRR, IFS, CMIP6 | `x * 9.81` |
| Precip kg/m^2 -> meters | GFS, HRRR, AIFS | `x / 1000` |
| Cloud cover % -> fraction | HRRR, AIFS | `x / 100` |
| Relative humidity 0-1 -> % | WB2 | `x * 100` |
| SST degC -> Kelvin | CMIP6, PC-OISST | `x + 273.15` |
| Sea ice % -> fraction | PC-OISST | `x / 100` |
| Heuristic C/K detection | CMIP6 | `x + 273.15 if mean < 100` |
| Identity (no-op) | Most variables | `x` |

## Julia Rewrite Considerations

### Mapping to Julia Constructs

- **Metaclass pattern** (class-level `[]`): Use a module or singleton struct with `Base.getindex` overloading
- **Return type** `(source_key, modifier_fn)`: Use `NamedTuple{(:key, :modifier), Tuple{String, Function}}` or a lightweight struct
- **VOCAB heterogeneity**: Normalize all VOCAB values into a common Julia type (e.g., a struct with fields for each component) rather than mixing strings, tuples, and lambdas

### Suggested Julia Design

```julia
struct VarMapping
    key::String           # source-specific identifier
    modifier::Function    # unit conversion (identity if none)
end

abstract type AbstractLexicon end

# Each source lexicon is a module or singleton
struct GFSLexicon <: AbstractLexicon end

Base.getindex(::Type{GFSLexicon}, var::String) -> VarMapping
Base.in(var::String, ::Type{GFSLexicon}) -> Bool
```

### Pressure Level Counts by Source

| Source | # Levels |
|--------|----------|
| GFS | 37 (1-1000 mb) |
| HRRR | 39 |
| ARCO ERA5 | 37 |
| CDS ERA5 | 13 |
| WB2 | 13 |
| CMIP6 | 10 |
| Canonical | 13 |
