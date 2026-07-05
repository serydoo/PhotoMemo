# PI-8 Expression Module Configuration Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Define where provider-neutral Expression Module Configuration should live
before Location module presentation configuration is implemented.

## Non-Goal

PI-8 does not implement storage, Inspector controls, preview wiring,
production wiring, renderer behavior, provider token expansion, export, share
extension behavior, photo-library behavior, or platform contract changes.

## Scan Table

| Consumer | Current Input | Candidate Boundary | PI-8 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| Inserted module instance | Module identity plus rendered preview value | Store provider-neutral configuration on the inserted module instance | Yes | Medium | Configuration is per module instance and must travel with the module that owns the presentation choice. |
| `MemoryBlock` / `MemoryTokenBlock` | Codable title/value token block | Store expression configuration directly on memory blocks | No | High | Would mix content-language blocks with provider strategy before a module-instance contract exists. |
| `ConfigurationSession` | Live UI/application state | Store expression configuration in session state | No | High | Session is not the durable owner of provider presentation choices. |
| `ConfigurationSnapshot` | Frozen production memory snapshot | Add expression configuration directly to snapshot first | No | High | Snapshot should receive already-modeled module configuration later, not invent the carrier. |
| `LocationExpressionProvider` | Explicit presentation mode and resolver configuration | Make provider remember or own configuration | No | High | Provider must remain a stateless compiler and must not own persisted configuration. |
| `ExpressionContext` | Token-addressed `ExpressionValue` map | Store configuration next to expression values | No | High | Context stores resolved values only; configuration belongs before resolution. |
| `ExpressionLookup` | Read-only `value(for:)` capability | Expose configuration lookup | No | High | Lookup is renderer dependency only and must not expose strategy or container semantics. |
| Renderer / template path | Resolved text lookup | Let renderer choose presentation mode | No | High | Renderer must receive resolved text only and must not own strategy. |

## Recommended Boundary

Expression Module Configuration should live on the inserted module instance.

Conceptual ownership:

```text
Inserted Module Instance
    -> Expression Module Configuration
    -> Provider input
    -> ExpressionValue
    -> ExpressionContext
```

The configuration must be provider-neutral at the carrier boundary. A module
instance may hold token-addressed configuration, but the carrier must not be a
Location-only field and must not require Renderer, Template, MetadataContext,
or ExpressionContext to understand Location strategy.

## Contract Requirements

The future implementation contract must satisfy:

- Configuration is attached to a concrete inserted module instance, not global
  session state.
- The carrier is provider-neutral and token-addressed.
- The stored shape is `Codable` and `Hashable`.
- Renderer, Template, `MetadataContext`, `ExpressionContext`, and
  `ExpressionLookup` never read or infer presentation strategy.
- Providers receive configuration as explicit input for a render cycle; they do
  not persist it.
- `LocationExpressionProvider` continues to support only the canonical
  `location` token until a separate token-expansion PI is approved.

## Location Configuration Mapping

For Location, the future module configuration may map to:

```text
ExpressionToken.location
    -> LocationPresentationMode
    -> LocationResolutionConfiguration
```

This mapping is a provider adapter concern. It must not leak into the generic
module carrier as Location-specific stored fields.

## Out Of Scope

- New platform protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider` token support
- Changes to `LocationResolver` or `LocationFormatter`
- Changes to `ConfigurationSession`
- Changes to `ConfigurationSnapshot`
- Changes to `MemoryBlockInspectorView`
- Changes to `V1PreviewCompositionEngine`
- Changes to `ConfigurationCenterPreviewCompositionHelper`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production behavior

## Selection Rule

Choose the durable ownership boundary, not the nearest call site.

For PI-8, the durable owner is the inserted module instance because the
presentation choice belongs to one module insertion. Session state, preview
helpers, snapshots, providers, and renderers are consumers or transport
surfaces, not the source of ownership.

## Review Checklist

- Configuration owner is the inserted module instance.
- Configuration carrier is provider-neutral.
- Configuration is stored before Provider resolution, not after
  `ExpressionValue` creation.
- Renderer receives resolved text only.
- `ExpressionLookup` remains value lookup only.
- No implementation is performed by this scan.
- The architectural delta is:

```text
Expression module configuration ownership: unowned -> inserted module instance
```
