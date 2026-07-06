# PI-20 Location Provider Production Adoption Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest production adoption seam for the parity-proven
`LocationExpressionProvider[location, legacyDisplay]` value.

## Non-Goal

PI-20 does not change Location provider behavior, expand Location provider
tokens, change legacy `PhotoMetadata.locationDisplay`, alter renderer layout or
drawing, change export metadata, change share extension behavior, change
photo-library behavior, introduce new platform protocols, or change platform
contracts.

## Prerequisite

PI-18 proved that the existing canonical Location provider modes were not
output-identical to legacy production `location_display`.

PI-19 added and froze the legacy-compatible Location presentation mode:

```text
LocationExpressionProvider[location, legacyDisplay]
    == MetadataContext[location_display]
```

for representative full hierarchy, POI / location name, and coordinate
fallback cases.

That proof allows a location-only production adoption seam to be considered. It
does not approve raw latitude, longitude, altitude, POI, or hierarchy subtokens.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-20 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ExpressionContextMetadataAdapter` | `ExpressionContext[location] -> MetadataContext[location_display]` | Reuse the existing approved projection | Yes | Low | PI-5 already added the legacy projection; PI-20 should not need adapter expansion. |
| `CardTextBlockEngine.build(from:)` | Legacy base context plus approved provider overlays | Overlay `LocationProvider[legacyDisplay]` before building `MetadataContextExpressionLookup` | Yes | Medium | This is the text-resolution surface approved in PI-2 and already used by PI-13D / PI-17. |
| `LocationContextBuilder` | `PhotoMetadata -> LocationContext` | Build Location provider input from `card.metadata` | Yes | Low | Uses the existing domain builder; no metadata mutation. |
| `LocationExpressionProvider` | `LocationContext + requestedPresentation -> ExpressionValue(location)` | Consume existing `.legacyDisplay` mode | Yes | Low | PI-19 proved parity; PI-20 consumes the existing provider behavior. |
| `PhotoMetadata.locationDisplay` | legacy display convenience | Modify legacy source | No | High | Legacy behavior remains the parity target and fallback comparison source. |
| `MetadataContext.build(from:)` | `PhotoMetadata -> legacy MetadataContext` | Replace location display at metadata construction | No | High | Would move provider policy into the metadata layer instead of the approved text seam. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Teach legacy projection to call Location provider | No | High | Would make legacy variable projection own provider adoption policy. |
| `RecordCardBuildService` | `SelectedPhoto + BatchConfigurationSnapshot -> RecordCard` | Produce or carry Location expression values during card construction | No | Medium | No production carrier expansion is needed because the provider can compile from `card.metadata` at the text seam. |
| `RecordCard` | optional `productionExpressionContext` carrier | Store Location-specific provider values | No | Medium | Existing carrier is not required for Location adoption. |
| Renderer / Export / Share Extension | Rendered `RecordCard` and output services | Consume Location provider output directly | No | High | Adoption belongs at text lookup, not rendering/export/share boundaries. |

## Approved Seam

PI-20 approves a location-only production adoption seam:

```text
CardTextBlockEngine.build(from:)
    -> CardVariableProvider.build(from:)                      // legacy base context
    -> MetadataProvider.expressionValue(.model)               // existing PI-13D overlay
    -> RecordCard.productionExpressionContext[memory]         // existing PI-17 overlay
    -> LocationContextBuilder.build(from: card.metadata)
    -> LocationExpressionProvider[location, legacyDisplay]    // PI-19 parity-proven value
    -> ExpressionContext[location]
    -> ExpressionContextMetadataAdapter
    -> MetadataContext[location_display]
    -> MetadataContextExpressionLookup
```

The renderer-facing dependency remains:

```text
TemplateVariableEngine.render(..., lookup: ExpressionLookup)
```

## Output Rule

Renderer output must remain unchanged.

PI-20 may replace only the legacy `location_display` value with the
parity-proven Location provider `.legacyDisplay` value.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider` API or token support
- Changes to `LocationResolver` or `LocationFormatter` behavior
- Changes to `PhotoMetadata.locationDisplay`
- Changes to `MetadataContext.build(from:)`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Raw Location subtokens such as latitude, longitude, altitude, POI, country,
  province, city, or district
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before Implementation Freeze

Implementation must add focused tests for:

1. Production text regression:

```text
RecordCard with {{location_display}}
    -> CardTextBlockEngine
    -> LocationProvider[legacyDisplay] text
```

2. Provider parity protection:

```text
CardTextBlockEngine output == MetadataContext[location_display]
```

for the PI-19 representative cases:

- POI / location name
- full hierarchy with country
- coordinate fallback

3. Boundary protection:

```text
No Location provider adoption in CardVariableProvider / RecordCardBuildService / Renderer
No platform contract changes
```

## Selection Rule

Adopt the parity-proven provider value at the existing text-resolution surface,
not at metadata construction, production card construction, renderer/export
boundaries, or share-extension boundaries.

For PI-20, this is smaller than expanding `RecordCard`, adding a Location
carrier, teaching `CardVariableProvider` about providers, or changing
`MetadataContext.build(from:)`.

## Review Checklist

- Only `location` is approved.
- Only `.legacyDisplay` is approved.
- Provider output is projected through the existing legacy adapter.
- Renderer still depends only on `ExpressionLookup`.
- Renderer/export/share output remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Production location authority: legacy MetadataContext[location_display] -> parity-proven LocationProvider[legacyDisplay] projected into legacy lookup
```
