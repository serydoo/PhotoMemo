# PI-13B Production Provider Parity Gate

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Define the token-level parity gate required before any provider-produced
`ExpressionValue` can become production lookup authority.

## Non-Goal

PI-13B does not implement provider adoption, change production lookup source,
change `RecordCard`, change `RecordCardBuildService`, change
`CardVariableProvider`, change renderer output, alter export metadata, change
share extension behavior, or change platform contracts.

## Gate Rule

Provider-produced values may enter production authority only token by token.

For each token, one of these outcomes must be proven before implementation:

1. Provider output is identical to the current production value for the same
   semantic slot.
2. Provider output differs, and the product explicitly accepts that output
   change before implementation.

If neither outcome is true, production adoption for that token is blocked.

## Current Token Matrix

| Token | Provider Source | Legacy Production Source | Parity Status | Production Adoption |
| --- | --- | --- | --- | --- |
| `model` | `MetadataProvider -> MetadataContext.build(from:)[model]` | `MetadataContext.build(from:)[model]` through `RecordCard.context` and `CardVariableProvider` | Candidate for exact parity | Not approved until focused parity test exists. |
| `location` | `LocationContextBuilder -> LocationExpressionProvider[location]` | `PhotoMetadata.locationDisplay -> MetadataContext[location_display]` | Not proven; likely semantic mismatch in point-of-interest, hierarchy, and coordinate fallback cases | Blocked. |
| `memory` | `MemoryExpressionContext -> MemoryProvider[memory]` | Frozen production Memory payload plus `CardVariableProvider` legacy projection | Not proven; production Memory authority already runs through frozen `MemoryResult` and compatibility variables | Blocked. |

## Gate Conclusion

No provider token is approved for production authority in PI-13B.

The `model` token is the only current low-risk parity candidate because both
the provider and legacy production path read the same normalized metadata
projection:

```text
MetadataContext.build(from: metadata)[model]
```

Even for `model`, implementation remains deferred until a focused parity test
locks the equivalence and a separate implementation seam is approved.

`location` remains blocked because the legacy value and provider value are
different semantic authorities:

```text
Legacy:
PhotoMetadata.locationDisplay -> location_display

Provider:
LocationContext -> LocationExpressionProvider -> location
```

`memory` remains blocked because production Memory output is governed by the
frozen IA-003 production Memory path. Replacing that source with
`MemoryProvider` output would require a separate Memory production parity
review.

## Required Proof Before Implementation

Any future production provider adoption must include a focused parity test
before changing production source authority.

Minimum proof shape:

```text
Given the same production input
When legacy production lookup and provider lookup resolve the approved token
Then the resolved text is identical
```

If the resolved text is not identical, implementation must stop unless a
product review explicitly accepts the output delta.

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionLookup`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Provider token expansion
- Changes to `PhotoMetadata.locationDisplay`
- Changes to `MetadataContext.build(from:)`
- Changes to `CardVariableProvider`
- Changes to `RecordCard`
- Changes to `RecordCardBuildService`
- Renderer layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production output behavior

## Approved Follow-Up

The only approved follow-up from this scan is a narrow parity proof for the
`model` token:

```text
PI-13C Model Provider Parity Proof
```

PI-13C may add tests only. It must not change production source authority or
production code.

If that test passes, a later Boundary Scan may decide whether adopting
`MetadataProvider[model]` in production has enough product value to justify an
implementation seam.

## Review Checklist

- Provider adoption is gated token by token.
- No provider token becomes production authority in this scan.
- `model` is identified only as a parity-test candidate.
- `location` and `memory` remain blocked.
- Production renderer/export/share behavior remains unchanged.
- Platform contracts remain unchanged.
- The architectural delta is:

```text
Production provider adoption: ungated -> token-level parity gate required
```
