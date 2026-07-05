# PI-9 Expression Module Configuration Carrier Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest implementation seam for introducing a provider-neutral
Expression Module Configuration carrier after PI-8 established inserted module
instance ownership.

## Non-Goal

PI-9 does not add Inspector controls, change preview output, connect Location
configuration to provider calls, change production snapshots, migrate
renderer/template lookup, expand provider tokens, modify export, alter share
extension behavior, or change photo-library behavior.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-9 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ExpressionModuleConfiguration` | None | Add provider-neutral `Codable` / `Hashable` carrier keyed by `ExpressionToken` | Yes | Low | Establishes the value object without changing existing expression contracts. |
| `IOSInsertedModule` | `title`, `value`, `systemImage` | Add optional expression configuration field with nil default | Yes | Low | Smallest live inserted-module instance used by current V1 module insertion path. |
| `InsertedModuleDraft` | Inspector-local module draft | Add configuration to Inspector draft | No | Medium | Crosses MemoryBlock Inspector draft behavior; defer until UI controls are approved. |
| `MemoryBlock` / `MemoryTokenBlock` | Codable content blocks | Store carrier directly on content blocks | No | High | Would alter Memory Language content model before module-instance persistence is approved. |
| `ConfigurationSnapshot` | Frozen production memory snapshot | Add carrier to snapshot | No | High | Snapshot transport should follow module-instance modeling, not define it. |
| `LocationExpressionProvider` | Explicit presentation mode and configuration arguments | Consume carrier now | No | Medium | Provider call mapping belongs to a later implementation PI after storage exists. |
| `V1PreviewCompositionEngine` | Preview sample facts -> `ExpressionContext` | Thread carrier into preview source | No | Medium | Preview output must remain unchanged during carrier introduction. |
| Renderer / template path | `ExpressionLookup` / legacy tokens | Read carrier during rendering | No | High | Renderer must receive resolved text only. |

## Approved Seam

PI-9 may modify only:

```text
Expression/ExpressionModuleConfiguration.swift
IOSInsertedModule.expressionConfiguration
```

The carrier introduction must be additive:

```text
IOSInsertedModule
    -> optional ExpressionModuleConfiguration
```

Existing module title, rendered value, system image, renderer token, and
preview behavior must remain unchanged.

## Contract Requirements

- `ExpressionModuleConfiguration` is provider-neutral.
- `ExpressionModuleConfiguration` is keyed by `ExpressionToken`.
- The stored option payload is `Codable` and `Hashable`.
- `IOSInsertedModule` keeps existing call sites working through a nil default.
- No Location-specific fields appear in the generic carrier.
- No renderer, template, provider, snapshot, session, export, share, or
  photo-library behavior changes.

## Out Of Scope

- New platform protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`, or
  `ExpressionLookup`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `LocationResolver`, or
  `LocationFormatter`
- Changes to `ConfigurationSession`
- Changes to `ConfigurationSnapshot`
- Changes to `MemoryBlock`, `MemoryTokenBlock`, or `MemoryExpression`
- Changes to `MemoryBlockInspectorView` or Inspector drafts
- Changes to `V1PreviewCompositionEngine`
- Changes to `ConfigurationCenterPreviewCompositionHelper`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production behavior

## Selection Rule

Implement the carrier before wiring any behavior.

For PI-9, adding the value object and attaching it as optional data to the
smallest inserted-module instance is safer than immediately threading
configuration through preview, provider, snapshot, or Inspector flows.

## Review Checklist

- Only the approved carrier seam is modified.
- Existing inserted module construction still works with no configuration.
- Carrier can be encoded, decoded, and compared.
- Carrier source does not import or name Location-specific types.
- No behavior changes are introduced.
- The architectural delta is:

```text
Expression module configuration carrier: absent -> optional inserted-module data
```
