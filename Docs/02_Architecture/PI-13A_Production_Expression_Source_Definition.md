# PI-13A Production Expression Source Definition

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Define the approved production source of `ExpressionLookup` values after
PI-13 stopped production lookup replacement due to value-authority risk.

## Non-Goal

PI-13A does not implement production adoption, add provider orchestration,
change `RecordCard`, change `RecordCardBuildService`, change
`CardVariableProvider`, change `MetadataContext`, alter renderer output,
modify export metadata, change share extension behavior, or change platform
contracts.

## Source Candidates

| Candidate Source | Output Authority | Approved | Risk | Notes |
| --- | --- | :--: | --- | --- |
| `CardVariableProvider.build(from:) -> MetadataContextExpressionLookup` | Existing production `MetadataContext` projection | Yes | Low | This is the only current source that preserves renderer/export output exactly. |
| `ExpressionContextMetadataAdapter` applied to provider output | Provider-produced `ExpressionContext` projected into legacy keys | No | Medium | Valid adapter, but production provider source and parity are not approved. |
| `LocationExpressionProvider` directly | Location provider canonical `location` value | No | High | May differ from `PhotoMetadata.locationDisplay`, especially for country, point-of-interest, and coordinate fallback behavior. |
| `MemoryProvider` directly | Memory provider canonical `memory` value | No | High | Production memory output already has frozen `MemoryResult` authority; changing template value source is a separate behavior decision. |
| `MetadataProvider` directly | Provider canonical `model` value | No | Medium | PI-4 validated one metadata token compiler, not production template replacement. |
| `RecordCard` stored `ExpressionContext` | New card-level expression carrier | No | High | Requires a production model ownership decision and may cross export/share boundaries. |
| `RecordCardBuildService` provider orchestration | Production build-time Expression source | No | High | Would modify production construction and needs parity proof before implementation. |

## Approved Source

For current production rendering, the approved `ExpressionLookup` source is:

```text
RecordCard
    -> CardVariableProvider.build(from:)
    -> MetadataContext
    -> MetadataContextExpressionLookup
    -> TemplateVariableEngine.render(..., lookup:)
```

This means production is already using the PI-2 lookup capability seam, but
its value authority remains the existing production `MetadataContext`
projection.

## Source Authority

Current production source authority remains:

```text
PhotoMetadata / frozen Memory production input / RecordCard fields
    -> CardVariableProvider
    -> MetadataContext
```

Provider-produced `ExpressionValue` instances are not yet approved as
production value authority.

This preserves the Platform Adoption rule:

```text
Renderer Output Change = No
```

## Why Provider Output Is Not Yet Approved

Provider compiler validation proved that domain semantics can enter Expression
Language. It did not prove that provider output is identical to the legacy
production template values.

The clearest unresolved case remains Location:

```text
Legacy production:
PhotoMetadata.locationDisplay

Provider production candidate:
LocationExpressionProvider.expressionValue(for: .location, ...)
```

These sources can legitimately disagree because they were designed at
different layers:

- `PhotoMetadata.locationDisplay` is a legacy display convenience that may use
  point-of-interest, hierarchy, or coordinate fallback behavior.
- `LocationExpressionProvider` emits the canonical provider token using typed
  presentation and resolution configuration.

Replacing one with the other would be a behavior change unless parity is
proven or the product explicitly accepts the output delta.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to provider token support
- Changes to `PhotoMetadata.locationDisplay`
- Changes to `MetadataContext.build(from:)`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Required Follow-Up Before Provider Adoption

Before any provider-produced value becomes production authority, the relevant
token needs a parity or acceptance gate:

```text
Production Provider Parity Gate
```

The gate must prove one of these outcomes for each approved token:

1. Provider output is identical to the existing production value.
2. Provider output differs, and the product explicitly accepts the output
   change.

Without that gate, provider adoption in production remains blocked.

## Review Checklist

- Production `ExpressionLookup` source is explicitly defined.
- Current renderer/export output remains unchanged.
- Provider-produced values are not treated as production authority.
- `RecordCard`, `RecordCardBuildService`, `CardVariableProvider`, and
  `MetadataContext` remain unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Production ExpressionLookup source authority: undefined -> legacy MetadataContext projection
```
