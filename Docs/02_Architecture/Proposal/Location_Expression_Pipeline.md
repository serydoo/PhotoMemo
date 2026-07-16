# Provider-Based Expression Architecture Proposal

Status: Proposed
Scope: Architecture
Target: Post IA-003
Branch: codex/地址模块
Date: 2026-07-05

## Mission

Establish a unified Provider-Based Expression Architecture so Metadata,
Location, Memory, and future capabilities produce tokens through independent
providers, are resolved by one Expression Engine, and are managed by the editor
as Expression Modules with presentation configuration.

Location is the first concrete case for this architecture. The long-term
decision is broader than a location module: Provider is the only producer of
Expression tokens.

## Context

MemoMark currently has real production token rendering through
`MetadataContext` and `TemplateVariableEngine`, while newer Memory work has
moved toward structured engine output. Location facts already exist in
`PhotoMetadata` and location tokens already exist in the variable catalog, but
location presentation is still partly metadata-derived and partly preview-local.

The next architecture step should avoid making Location a Metadata attachment.
Instead, Location should become a first-class expression provider beside
Metadata and Memory. `MetadataContext` remains useful as a V1 compatibility
adapter, but it should not be treated as the future expression core.

## Current Problem

The existing V1 shape can be simplified as:

```text
PhotoMetadata
        |
        v
MetadataContext
        |
        v
TemplateVariableEngine
        |
        v
Renderer
```

This shape makes every new expression source look like a metadata extension.
That is not a stable long-term model for Location, Weather, People, AI, or
future memory intelligence.

Preview also contains local demo values for location. A preview string such as
`示例省 · 示例市` can drift from the real production photo, which violates the
preview and production convergence principle.

## Configuration Center Boundary

The Configuration Center designs renderer behavior. It does not edit a
specific photo.

Configuration Center preview should be understood as:

```text
Configuration Snapshot
        |
        v
ExpressionContext built from sample preview values
        |
        v
Renderer Preview
```

It should not be understood as:

```text
Photo
        |
        v
Preview
```

The preview canvas is a renderer-backed memory card preview. It may use sample
values such as a sample camera, sample location, sample date, or sample memory
result, but those values are only inputs for previewing renderer output. They
must not become production data.

## Proposed Architecture

Future expression production should flow through independent providers:

```text
PhotoMetadata
        |
        +-------------------+
        |                   |
        v                   v
MetadataProvider     LocationProvider
        |                   |
        +---------+---------+
                  |
                  v
          ExpressionContext
                  |
                  v
          Expression Engine
                  |
                  v
              Renderer
```

The broader provider set should remain open:

```text
MetadataProvider
MemoryProvider
LocationProvider
WeatherProvider
PeopleProvider
AIProvider
        |
        v
ExpressionContext
        |
        v
Expression Engine
```

## Provider Independence

Each Provider:

- owns one semantic domain, such as Metadata, Location, or Memory
- independently produces its own tokens
- does not depend on Renderer
- does not depend on Template
- does not directly participate in UI
- may share lower-level input data, such as `PhotoMetadata`
- must not concatenate another provider's presentation strings
- must not take over another provider's display responsibility

Providers produce expression values. Presentation, layout, and rendering remain
separate responsibilities.

Provider input is limited to domain facts and approved services, such as:

- `PhotoMetadata`
- Configuration
- local services
- explicit enrichment services

Provider output is limited to semantic tokens and resolved expression values.
Provider code should continue to work if Renderer, Template, Inspector, or
editor presentation changes.

## Provider Ownership

Every Semantic Token has exactly one canonical Provider.

Examples:

```text
MetadataProvider
    camera_model
    lens_model
    iso
    shutter

LocationProvider
    location
    latitude
    longitude
    altitude

MemoryProvider
    age
    days
    memory_title
```

A Provider must not overwrite or regenerate another Provider's token. For
example, `LocationProvider` must not generate `camera_model`, and
`MemoryProvider` must not generate `location`.

If a future expression needs to combine values from multiple domains, that
combination should be modeled as a new semantic provider or presentation layer,
not as one Provider silently taking ownership of another Provider's token.

## Semantic Token And Presentation Rule

Tokens represent semantics. Presentation represents display.

This is the core rule for Provider-Based Expression Architecture:

- Raw Data becomes independent tokens.
- Different display forms of the same semantic value become Presentation modes,
  not new tokens.

For Location:

- `location` is the semantic token for a location expression.
- `latitude`, `longitude`, and `altitude` are independent raw-data tokens.
- Province + City, City + District, Province + City + District, and Coordinate
  are Presentation modes for a Location Expression Module.
- Altitude remains a raw semantic token because it is a separate fact, not a
  presentation of `location`.

This prevents the expression system from growing a new token for every display
variant, such as `location_short`, `location_full`, or
`location_coordinate`.

The same rule should apply to future Memory, Metadata, Weather, People, and AI
providers. For example, age, day count, and relative memory values may be
different semantic values, but compact, formal, or localized output styles are
Presentation modes.

## Review Invariants

These invariants are review checks for Provider-Based Expression Architecture.
They are not Location-specific implementation details.

### Invariant 1: Single Rendering Pipeline

The system has one renderer pipeline:

```text
ExpressionContext
        |
        v
Renderer
```

Preview and production must not fork into separate renderer or expression
pipelines. The only allowed difference is the source used to build
`ExpressionContext`.

Forbidden shapes:

```text
PreviewRenderer
ProductionRenderer
Preview Pipeline
Production Pipeline
```

### Invariant 2: Configuration Never Depends On Asset

Configuration records rules, not resolved asset values.

For example, a Location Module configuration may store:

```text
Presentation = Province + City
```

It must not store a resolved asset value such as:

```text
示例省 · 示例市
```

Changing the photo changes provider output. It must not change the saved
Configuration.

### Invariant 3: Providers Produce Meaning, Renderer Produces Pixels

Providers produce meaning. Renderer produces pixels.

Providers may resolve GPS, memory age, EXIF-derived facts, weather, people, or
future AI summaries into semantic expression values. Renderer receives resolved
text, icon choices, and layout instructions only. Renderer must not know how
GPS, Memory, Age, Location, Weather, or AI values were resolved.

### Invariant 4: Preview Must Never Invent Architecture

Preview must consume the normal `ExpressionContext`.

Preview may use sample values to build that context, but it must not introduce
a preview-only core context model, preview-only renderer, or preview-only
string composition path. Preview-specific shortcuts such as local demo strings
are architecture drift unless they are produced through the same expression
model that production can use.

## Location Pipeline

Location should be implemented as the first Provider-Based Expression case:

```text
PhotoMetadata
        |
        v
LocationContextBuilder
        |
        v
LocationContext
        |
        v
LocationResolver
        |
        +--> LocationFormatter
        |
        v
LocationExpressionProvider
        |
        v
ExpressionContext
        |
        v
Expression Engine
        |
        v
Renderer
```

### LocationContextBuilder

Builds a semantic `LocationContext` from available facts.

Initial inputs:

- raw GPS from EXIF
- altitude from EXIF
- friendly address fields when available
- future reverse-geocode output
- future POI or landmark facts

### LocationContext

`LocationContext` should not be a passive DTO. It should expose semantic
availability and preferred names so downstream providers do not repeat
field-by-field checks.

Candidate shape:

```swift
struct LocationContext {
    var coordinate: LocationCoordinate?
    var address: LocationAddress?
    var presentation: LocationPresentationFacts
    var availability: LocationAvailability

    var hasGPS: Bool
    var hasAddress: Bool
    var hasPOI: Bool
    var displayName: String
    var cityName: String
    var regionName: String
    var coordinateText: String
}
```

The exact Swift model is not frozen by this proposal. The architectural rule is
that location semantics live in `LocationContext`, not in Renderer, Template,
or ad hoc UI code.

### ReverseGeocoder

Reverse geocoding starts as a protocol boundary:

```swift
protocol ReverseGeocoder {
    func reverseGeocode(
        coordinate: LocationCoordinate
    ) async throws -> LocationContext
}
```

Possible adapters:

- `AppleReverseGeocoder`
- `GoogleReverseGeocoder`
- `OfflineReverseGeocoder`
- `CachedReverseGeocoder`

Core expression code should not change when the reverse-geocoding backend
changes.

### LocationResolver

Chooses what location expression should be exposed from the available context.

Responsibilities:

- choose POI, district, city, region, full address, or coordinate fallback
- decide whether GPS-only output is allowed
- apply missing-data behavior
- choose a formatter mode
- avoid direct renderer or UI dependency

### LocationFormatter

Formats selected location facts for a locale and presentation mode.

Examples:

- `上海 · 浦东`
- `Tokyo · Shibuya`
- `中国 · 上海`
- `31.230416, 121.473701`

The formatter owns string shape. The resolver owns which shape to request.

### LocationExpressionProvider

Projects resolved location expressions into `ExpressionContext` using the
module's selected Presentation mode.

Initial semantic token set:

```text
{{location}}
{{latitude}}
{{longitude}}
{{altitude}}
```

Token intent:

| Token | Meaning |
| --- | --- |
| `location` | semantic location expression resolved through Presentation mode |
| `latitude` | formatted latitude |
| `longitude` | formatted longitude |
| `altitude` | formatted altitude |

Candidate Location Presentation modes:

```swift
enum LocationPresentationMode {
    case provinceCity
    case cityDistrict
    case provinceCityDistrict
    case coordinate
}
```

The exact Swift naming is not frozen by this proposal. The architectural rule
is that Presentation mode changes the resolved value for `location`; it does
not create a new semantic token for each display variant.

## ExpressionContext

`ExpressionContext` is the future token store produced by providers.

It should eventually replace `MetadataContext` as the core expression model.
During V1 compatibility, `MetadataContext` may remain as an adapter for the
existing renderer and template pipeline.

Compatibility direction:

```text
Provider outputs
        |
        v
ExpressionContext
        |
        +--> V1 MetadataContext adapter
        |
        v
Expression Engine
```

New architecture work should prefer provider output and `ExpressionContext`
semantics over expanding `MetadataContext` as the central model.

### Preview Expression Source

Preview does not introduce a second context model.

The Configuration Center may use sample values to build an `ExpressionContext`
for renderer preview, but that source should be treated as a preview
expression source, not as a separate `PreviewExpressionContext` model.

The distinction is:

```text
Configuration Preview:
Sample Preview Values -> Providers or Preview Provider Fixtures -> ExpressionContext -> Renderer

Production:
PhotoMetadata -> Canonical Providers -> ExpressionContext -> Renderer
```

Preview and production differ by data source. They should converge on the same
`ExpressionContext -> Renderer` pipeline.

### MetadataContext Migration Note

`MetadataContext` is a V1 legacy adapter. It may project `ExpressionContext`
values into the existing renderer and template pipeline, but it must not carry
new token design semantics. New semantic tokens belong to canonical Providers
and should be modeled in `ExpressionContext` first.

## Expression Module Boundary

Editor modules should be modeled as Expression Modules, not as direct data
sources.

The editor should not need to know whether a module is EXIF, Location, Memory,
or AI. It should manage one abstraction:

```text
Expression Module
    Provider
    Presentation
```

Presentation is Configuration. It must be captured as part of the module
configuration that can be saved, restored, snapshotted, exported, and replayed
through production processing.

Presentation must not live only in transient UI state.

Conceptual shape:

```text
ExpressionModule
    provider = LocationProvider
    semantic = location
    configuration
        presentation = Display
        fallback = UseCoordinateIfAddressUnavailable
        decoration = ShowLocationMarker
```

```text
Module Library
        |
        v
Insert Expression Module
        |
        v
Select Provider
        |
        v
Configure Presentation
        |
        v
Expression Engine
        |
        v
Renderer
```

The editor inserts a `Location Module`, not separate modules such as
`Location Short`, `Location Full`, `Location City`, or `Location Coordinate`.

Those are presentation modes on one module instance:

```text
Location Module

Presentation:
    Province + City
    City + District
    Province + City + District
    Coordinate
```

This keeps the module surface stable when future output forms are added.

The Object Inspector owns Presentation configuration for the selected module
instance. For Location, example controls may include:

```text
Presentation
    Province + City
    City + District
    Province + City + District
    Coordinate

Fallback
    Empty
    Hide Module
    Placeholder

Decoration
    Show location marker

Region
    Hide country
    Hide province
```

These controls configure the module instance. They do not create new module
types and they do not ask Renderer to understand Location.

Fallback policy is not Location-specific. Empty, Hide Module, and Placeholder
should be modeled as reusable Expression Module fallback behavior so Memory,
Weather, People, and future providers can reuse the same configuration pattern.

Future Location presentation modes may include:

- POI
- Landmark
- Distance
- Visit Count
- First Visit

These should not require new editor module types unless their behavior becomes
semantically different from Location expression.

## V1 Boundary

V1 should keep renderer, export, photo-library, and share-extension behavior
stable.

Recommended V1 slices:

1. Add proposal and architecture tests for the intended provider boundary.
2. Introduce `ExpressionContext` as an additive model.
3. Introduce Location context, formatter, resolver, and provider as isolated
   files.
4. Add a V1 adapter from `ExpressionContext` to `MetadataContext`.
5. Replace preview-local location demo values with provider-resolved preview
   values.
6. Only after convergence, expose Location Module presentation configuration in
   the editor inspector.

V1 must not:

- make Renderer resolve location
- make Template split location strings
- add network-dependent reverse geocoding as a required core workflow
- add separate editor module types for every location presentation mode
- add new tokens only to represent display variants of the same semantic value
- create a second preview-only expression context model
- create a preview-only renderer or production-only renderer
- save resolved asset values as Configuration
- change export or photo-library behavior as part of this proposal

## V2 Direction

Post V1, Provider-Based Expression Architecture should become the standard
extension path for all expression-producing features.

Candidate future providers:

- Weather Provider
- People Provider
- AI Summary Provider
- Timeline Provider
- Visit History Provider

The architecture goal is that adding a provider does not require changing the
renderer or editor module architecture.

## Acceptance Criteria

This proposal is ready to move from Proposed to ADR when:

- `ExpressionContext` responsibilities are accepted
- provider independence is accepted as a repository architecture rule
- the semantic token and Presentation-mode rule is accepted
- Location semantic tokens and Presentation modes are accepted or revised
- V1 compatibility direction through `MetadataContext` adapter is accepted
- preview and production convergence requirements are agreed
- the Review Invariants are accepted as implementation review checks

This proposal is ready to move from ADR to Freeze when:

- tests prove Location provider output can feed preview and production through
  the same expression path
- V1 preview no longer contains hardcoded demo location values
- Renderer consumes resolved text only
- editor module insertion treats Location as one Expression Module with
  presentation configuration
- Configuration Center preview and production both feed Renderer through
  `ExpressionContext`, with different data sources only

## Open Questions

- Should `ExpressionContext` replace `MetadataContext` directly, or should it
  remain wrapped by a compatibility adapter until post V1?
- Should V1 keep `location_display` as a compatibility alias for a configured
  `location` presentation, or should compatibility projection hide the legacy
  name entirely?
- Should coordinate fallback be globally configurable or module-instance
  configurable?
- Should reverse geocoding be explicit user-triggered enrichment, automatic
  local-only enrichment, or deferred until V2?
- Should POI and Landmark be part of Location Provider or separate providers
  later?
