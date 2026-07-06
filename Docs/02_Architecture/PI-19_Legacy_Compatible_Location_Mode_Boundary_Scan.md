# PI-19 Legacy-Compatible Location Mode Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Approve the smallest Location provider change that can preserve the existing
production `location_display` text while moving authority toward
`LocationExpressionProvider`.

## Non-Goal

PI-19 does not adopt Location provider output in production, change
`PhotoMetadata.locationDisplay`, change renderer output, modify export/share
behavior, introduce new platform protocols, or change platform contracts.

## Product Decision

PI-18 proved that existing canonical Location presentation modes are not
output-identical to legacy `location_display`.

The accepted product direction is:

```text
User-visible location text should remain unchanged while internal authority
moves toward LocationProvider.
```

Therefore PI-19 approves a legacy-compatible Location presentation mode.

## Approved Seam

PI-19 may add one Location presentation mode:

```text
LocationPresentationMode.legacyDisplay
```

The mode must reproduce current legacy display semantics:

```text
1. location name / POI
2. country -> province -> city -> district, deduplicated
3. coordinate fallback
4. empty
```

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-19 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `LocationPresentationMode` | typed modes only | Add `legacyDisplay` | Yes | Low | Location-domain mode expansion only. |
| `LocationFormatter` | mode -> text | Format legacy display semantics | Yes | Low | Pure formatting; no production wiring. |
| `LocationResolver` | mode -> resolution | Treat legacy display as available when POI, hierarchy, or coordinate exists | Yes | Low | Keeps resolution deterministic. |
| `LocationExpressionProvider` | existing resolver + formatter | Consume the new mode through existing API | Yes | Low | No provider API change. |
| `PhotoMetadata.locationDisplay` | legacy display convenience | Modify legacy source | No | High | Legacy behavior remains the parity target. |
| `CardTextBlockEngine` | production text lookup | Adopt Location provider output | No | High | PI-19 only creates the compatible mode. |
| Renderer / Export / Share Extension | output consumers | Consume Location provider output | No | High | Production adoption is a later scan. |

## Output Rule

PI-19 must not change production renderer output.

The new mode should make this true in tests:

```text
LocationProvider[legacyDisplay] == PhotoMetadata.locationDisplay
```

for representative legacy cases.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `PhotoMetadata.locationDisplay`
- Changes to `MetadataContext.build(from:)`
- Changes to `ExpressionContextMetadataAdapter`
- Changes to `CardTextBlockEngine`
- Changes to `CardVariableProvider`
- Changes to `RecordCard` or `RecordCardBuildService`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Tests Before Implementation Freeze

Implementation must prove:

```text
LocationProvider[legacyDisplay] == MetadataContext[location_display]
```

for:

- POI / location name
- full hierarchy with country
- coordinate fallback

It must also preserve existing typed presentation behavior.

## Selection Rule

Add a compatibility mode inside the Location domain before production adoption.

This keeps visible behavior stable while allowing a later PI to move
`location_display` authority to the provider.

## Review Checklist

- Only Location-domain mode / resolver / formatter behavior changes.
- Production text lookup remains unchanged.
- Model and Memory adoption remain unchanged.
- Renderer/export/share output remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Location provider parity: unavailable -> legacy-compatible presentation mode available
```
