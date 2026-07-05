# PI-4 Metadata Provider Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Integration

## Mission

Identify the smallest Metadata provider compilation seam for validating legacy
photo facts entering Expression Language without changing renderer, export, or
metadata acquisition behavior.

## Non-Goal

PI-4 does not migrate the production template system, remove
`MetadataContext`, change `PhotoMetadataReader`, add metadata formatting rules,
connect Renderer, modify Export, change Share Extension behavior, or add new
platform contracts.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-4 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| Metadata provider compiler | `PhotoMetadata -> MetadataContext.build(from:)` | Provider reads one approved fact token from `MetadataContext` and emits `ExpressionValue` | Yes | Low | Reuses existing fact projection without changing acquisition, renderer, or export. |
| `PhotoMetadataReader` | ImageIO / EXIF input | Reader emits `ExpressionValue` | No | High | Would couple fact acquisition to Expression Language and risk metadata behavior. |
| `MetadataContext.build(from:)` | `PhotoMetadata` | Builder emits `ExpressionContext` | No | High | Would turn legacy variable map into platform storage and expand scope. |
| `CardVariableProvider` | `RecordCard -> MetadataContext` | Compile `camera_summary` / presentation variables | No | High | This path mixes metadata facts with card, memory, badge, and legacy presentation compatibility. |
| `TemplateVariableLibrary` | Template variable definitions | Migrate variable library to `ExpressionToken` | No | Medium | Broader token catalog migration, not minimal provider validation. |
| Renderer text lookup | `ExpressionLookup` after PI-2 | Renderer consumes metadata tokens directly | No | Medium | Renderer consumption is outside PI-4. |
| Export / Share / batch | Production card build path | Production metadata provider integration | No | High | Crosses production behavior and remains deferred. |

## Recommended Seam

PI-4 will validate Metadata provider compilation at:

```text
PhotoMetadata
    -> MetadataContext.build(from:)
    -> MetadataContext[model]
```

and compile the completed metadata fact into:

```text
ExpressionValue(
    token: .model,
    resolvedText: MetadataContext[model]
)
```

This seam is the smallest architectural surface because `PhotoMetadata` remains
the fact source, `MetadataContext.build(from:)` remains the existing fact
projection, and the Provider only compiles one already-normalized fact into
Expression Language.

## Canonical Token

PI-4 approves one token only:

```text
model
```

Composite tokens such as `camera_summary`, `capture_date_display`, location
tokens, memory tokens, or the full metadata variable catalog remain future
provider expansion or migration work.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `PhotoMetadataReader` or EXIF acquisition
- Changes to `MetadataContext.build(from:)`
- `CardVariableProvider` migration or cleanup
- `TemplateVariableLibrary` migration
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or preview behavior
- Location, Memory, or multi-token provider expansion

## Selection Rule

Choose the seam with the smallest architectural surface, not the largest useful
token catalog.

For PI-4, compiling `model` from the existing metadata fact projection is
smaller than introducing a metadata formatter or migrating composite template
variables, because it proves Metadata can enter Expression Language without
changing production output.

## Review Checklist

- Provider consumes existing metadata fact projection.
- Provider does not read image files or EXIF directly.
- Provider does not implement renderer-facing formatting rules.
- Provider supports only the approved `model` token.
- Provider returns `nil` for unapproved metadata tokens.
- Platform contracts remain unchanged.
- Renderer and production output remain unchanged.
- The architectural delta remains exactly one line:

```text
Metadata fact compilation: MetadataContext[model] -> ExpressionValue
```
