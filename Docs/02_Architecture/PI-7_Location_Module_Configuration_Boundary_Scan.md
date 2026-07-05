# PI-7 Location Module Configuration Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify whether Location module presentation configuration can be persisted
through an existing approved seam without changing Configuration Center,
Inspector, renderer, production, export, share, or platform contracts.

## Non-Goal

PI-7 does not implement Inspector controls, change Configuration Center
architecture, add new platform protocols, modify renderer behavior, alter
Export, change Share Extension behavior, modify Photo Library behavior, or
expand Location Provider token support.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-7 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `LocationExpressionProvider` | Explicit `LocationPresentationMode` and `LocationResolutionConfiguration` arguments | Persist these arguments as module configuration | No | Medium | Requires a configuration carrier that does not currently exist in the module model. |
| `LocationPresentationMode` | Codable enum | Store directly on an inserted module | No | Medium | Current inserted-module drafts store rendered preview values, not domain configuration. |
| `LocationResolutionConfiguration` | Codable resolver configuration | Store directly on an inserted module | No | Medium | This would expose resolver-level configuration without an approved module-configuration contract. |
| `ConfigurationSession` | Session state + presentation state | Add location module configuration to session state | No | High | Session is a live UI/application state owner; this would cross Configuration Center behavior. |
| `MemoryBlockInspectorView` | Local draft structs and inserted modules | Add UI controls for Location presentation options | No | High | Inspector behavior and UI configuration are outside an approved seam. |
| `ConfigurationSnapshot` | Frozen Memory Subject / expression snapshot | Add Location module configuration to production snapshot | No | High | Crosses production snapshot semantics and requires broader persistence review. |
| `V1PreviewCompositionEngine` | Preview sample facts -> ExpressionContext after PI-6 | Thread configuration into preview expression source | No | Medium | Preview source can consume configuration only after the configuration contract exists. |
| Renderer / template path | `ExpressionLookup` / legacy `MetadataContext` | Let renderer decide presentation mode | No | High | Renderer must receive resolved text only and must not own presentation strategy. |

## Scan Conclusion

PI-7 does not have an existing approved implementation seam.

The next safe architecture action is not implementation. It is a focused
configuration contract review that defines where expression module
configuration lives before any UI, preview, production, or renderer path
stores Location presentation choices.

## Required Follow-Up Boundary

Before implementation, a new scan or ADR must answer:

```text
Where does provider-neutral Expression Module Configuration live?
```

The answer must cover:

- whether configuration is provider-neutral or Location-specific
- whether it is stored on inserted modules, MemoryBlock fields, or snapshots
- how it remains Codable / Hashable
- how it avoids turning Renderer, Template, or `MetadataContext` into strategy
  owners
- how it keeps Location Provider token support unchanged

## Out Of Scope

- New platform abstractions or protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider` token support
- Changes to `LocationResolver` or `LocationFormatter`
- Changes to `ConfigurationSnapshot`
- Changes to `ConfigurationSession`
- Changes to `MemoryBlockInspectorView`
- Changes to `V1PreviewCompositionEngine`
- Changes to `ConfigurationCenterPreviewCompositionHelper`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production behavior

## Selection Rule

When no existing seam can preserve the current platform contracts, stop at the
Boundary Scan instead of forcing the migration through a live UI or production
model.

For PI-7, adding presentation configuration directly to `ConfigurationSession`,
`MemoryBlockInspectorView`, or `ConfigurationSnapshot` would optimize for code
proximity rather than architectural surface. The configuration contract must be
defined first.

## Review Checklist

- No implementation is approved by this scan.
- Renderer continues to receive resolved text only.
- Location Provider continues to support only the approved `location` token.
- Presentation mode remains an explicit input to provider calls until a
  configuration contract is approved.
- Platform contracts remain unchanged.
- The architectural delta for PI-7 is intentionally:

```text
No implementation seam approved: Expression module configuration requires a separate contract review
```
