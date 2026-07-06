# PI-13 Production Lookup Integration Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest production lookup seam for adopting Expression Platform
without changing renderer output, export behavior, share extension behavior,
photo-library behavior, or platform contracts.

## Non-Goal

PI-13 does not add provider orchestration, change `RecordCard`, change
`RecordCardBuildService`, change `CardVariableProvider`, rewrite template
variables, alter export metadata, change share extension behavior, modify
renderer layout/drawing, or change platform contracts.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-13 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `CardTextBlockEngine.build(from:)` | `RecordCard -> CardVariableProvider.build(from:) -> MetadataContextExpressionLookup` | Replace the local lookup source with a production Expression lookup | No | High | No production `ExpressionContext` source exists on `RecordCard`; adding one would expand the production card model boundary. |
| `TemplateVariableEngine.render(..., lookup:)` | `ExpressionLookup` after PI-2 | Change template token resolution rules | No | High | The renderer text capability seam is already isolated; changing token semantics would be behavior migration. |
| `RecordCardBuildService.baseCard` | `PhotoMetadata + BatchConfigurationSnapshot -> RecordCard.context` | Produce provider values during production card construction | No | High | This would change the authority for production `location_display` and can change existing output. |
| `CardVariableProvider.build(from:)` | `RecordCard -> MetadataContext` | Merge Expression values into legacy variables | No | High | This would make legacy variable projection own Expression adoption policy. |
| `ExpressionContextMetadataAdapter` | `ExpressionContext -> MetadataContext[location_display]` | Reuse adapter in production | No | Medium | Adapter is valid, but production does not yet have an approved Expression source or no-output-change mapping. |
| `RecordCard` | Legacy card model with `MetadataContext` | Store `ExpressionContext` or `ExpressionLookup` on the card | No | High | This is a production model carrier decision and requires a separate approved seam. |
| `RecordCardRenderer` | `RecordCard` | Pass lookup directly to renderer | No | High | Would cross rendering boundary instead of the text resolution boundary. |
| `RecordCardExportService` | Rendered `RecordCard` + export metadata | Build or adapt Expression values during export | No | High | Export must remain a consumer of an already-built card. |
| Share Extension production path | `BatchConfigurationSnapshot -> RecordCard` | Adopt app-only providers | No | High | Share extension availability and output parity require a separate production adoption gate. |

## Scan Conclusion

PI-13 approves no implementation seam.

The current production lookup path is already capability-isolated at the text
resolution boundary after PI-2:

```text
CardTextBlockEngine
    -> TemplateVariableEngine.render(..., lookup: ExpressionLookup)
```

However, production still supplies that capability through a legacy adapter:

```text
RecordCard
    -> CardVariableProvider.build(from:)
    -> MetadataContextExpressionLookup
```

Replacing that source with provider-produced Expression values is not a pure
lookup dependency migration. It changes the production value authority.

The most visible example is `location_display`:

```text
Current production:
PhotoMetadata.locationDisplay -> MetadataContext[location_display]

Expression Platform:
LocationContext -> LocationExpressionProvider -> ExpressionContext[location]
```

These are not guaranteed to produce identical text. Existing
`PhotoMetadata.locationDisplay` may include country, point-of-interest, or
coordinate fallback behavior, while the canonical Location provider currently
freezes only the `location` token and the typed presentation modes validated in
the Location pipeline.

Because PI-13 requires no renderer output change, the production source
replacement is not approved in this scan.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `MemoryProvider`, or
  `MetadataProvider`
- Changes to `LocationResolver`, `LocationFormatter`, or Location token
  support
- Changes to `MetadataContext.build(from:)` or `PhotoMetadata.locationDisplay`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Follow-Up Before Implementation

Production adoption needs a separate approved boundary before code changes:

```text
Production Expression Source Definition
```

That follow-up must answer one question:

```text
What is the approved production source of ExpressionLookup values?
```

It must also prove one of the following before production implementation:

1. The provider-produced value is output-identical to the legacy
   `MetadataContext` value for the approved token.
2. The output change is explicitly accepted as a product behavior change under
   a separate review.

Without one of those proofs, production lookup integration would violate the
Platform Adoption regression rule.

## Selection Rule

Do not replace a production lookup source when the replacement changes value
authority.

For PI-13, the smallest safe architectural surface is to stop after the scan,
because every direct production adoption path either requires a new production
Expression source carrier or can change rendered/exported output.

## Review Checklist

- No implementation seam is approved by PI-13.
- Production renderer output remains unchanged.
- Production export behavior remains unchanged.
- Share Extension behavior remains unchanged.
- `RecordCard`, `RecordCardBuildService`, `CardVariableProvider`, and
  `MetadataContext` remain unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
No implementation seam approved: production lookup source requires separate source-authority review
```
