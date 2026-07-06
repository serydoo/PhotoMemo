# PI-18 Location Provider Production Parity Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Determine whether `LocationExpressionProvider[location]` can become production
authority for legacy `MetadataContext[location_display]` without changing
renderer output.

## Non-Goal

PI-18 does not adopt Location provider output in production, change
`PhotoMetadata.locationDisplay`, expand Location provider token support,
change renderer output, modify export/share/photo-library behavior, introduce
new platform protocols, or change platform contracts.

## Prerequisite

PI-13B blocked Location production adoption because parity was not proven:

```text
Legacy:
PhotoMetadata.locationDisplay -> MetadataContext[location_display]

Provider:
LocationContext -> LocationExpressionProvider[location]
```

PI-17 completed model and memory production adoption. Location is now the
remaining blocked canonical provider token.

## Scan Table

| Case | Legacy Production Source | Provider Candidate | Parity | Notes |
| --- | --- | --- | --- | --- |
| POI / location name | `PhotoMetadata.locationDisplay` returns `locationName` first | Provider has no POI presentation mode | No | Provider can carry POI facts but cannot render POI-first legacy display. |
| Full hierarchy | `country -> province -> city -> district` | `.provinceCityDistrict` renders `province -> city -> district` | No | Provider intentionally omits country in current canonical modes. |
| Province + city | Legacy includes country when available | `.provinceCity` renders `province -> city` | Partial only | Exact parity exists only for narrow inputs where country, district, and POI are absent. |
| Coordinate fallback | Legacy falls back to coordinates when no friendly location exists | Provider requires `.coordinate` mode or coordinate fallback configuration | Conditional | Existing production `location_display` has no approved module configuration source. |

## Scan Conclusion

PI-18 approves no production adoption seam.

`LocationExpressionProvider[location]` is not output-identical to
`PhotoMetadata.locationDisplay` for the current production semantic slot.
The mismatch is semantic, not mechanical:

```text
PhotoMetadata.locationDisplay
    = legacy display convenience

LocationExpressionProvider[location]
    = typed canonical presentation value
```

Adopting the provider value would change visible renderer text for common
location cases unless the product explicitly accepts a Location output
behavior change.

## Approved Evidence

PI-18 may add focused tests proving the mismatch for representative cases:

```text
legacy location_display != LocationProvider[location]
```

The tests must be evidence-only and must not change production source
authority.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `LocationResolver`,
  `LocationFormatter`, or Location token support
- Changes to `PhotoMetadata.locationDisplay`
- Changes to `MetadataContext.build(from:)`
- Changes to `ExpressionContextMetadataAdapter`
- Changes to `CardTextBlockEngine`
- Changes to `CardVariableProvider`
- Changes to `RecordCard` or `RecordCardBuildService`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Follow-Up Before Implementation

Location production adoption requires one of these decisions:

1. Product accepts the canonical Location provider output as a visible behavior
   change.
2. A new legacy-compatible Location provider mode is approved.
3. Production keeps `PhotoMetadata.locationDisplay` as the authority for the
   legacy `location_display` slot.

Without one of these decisions, Location production adoption remains blocked.

## Selection Rule

Do not adopt a provider value when its semantic slot is not output-identical to
the legacy production value.

For PI-18, the smallest safe surface is evidence-only parity testing and a
frozen blocking conclusion.

## Review Checklist

- No implementation seam is approved by PI-18.
- Location provider output does not become production authority.
- Model and Memory adoption remain unchanged.
- Renderer/export/share output remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Location provider production adoption: blocked -> mismatch proven, product decision required
```
