# PI-10 Location Configuration Adapter Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Adoption

## Mission

Identify the smallest adapter seam for translating provider-neutral
`ExpressionModuleConfiguration` into existing Location provider input without
changing platform contracts or connecting UI, preview, production, or renderer
behavior.

## Non-Goal

PI-10 does not add Inspector controls, persist configuration, change preview
output, connect production rendering, modify `LocationExpressionProvider`,
expand Location tokens, alter renderer/template lookup, modify export, change
share extension behavior, or change photo-library behavior.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-10 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| Location configuration adapter | `ExpressionModuleConfiguration` | Translate generic options into `LocationPresentationMode` and `LocationResolutionConfiguration` | Yes | Low | Keeps provider stateless and preserves explicit provider inputs. |
| `LocationExpressionProvider` | Explicit requested presentation and resolver configuration | Let provider parse `ExpressionModuleConfiguration` directly | No | Medium | Would make provider understand storage format instead of compiling domain output. |
| `LocationResolver` | `LocationContext` plus explicit configuration | Let resolver parse module options | No | High | Resolver must stay deterministic over context plus typed configuration. |
| `ExpressionModuleConfiguration` | Generic token and string options | Add Location-specific typed fields | No | High | Would break provider-neutral carrier semantics. |
| `IOSInsertedModule` | Optional generic configuration | Thread adapter into module insertion | No | Medium | Persistence and UI wiring are separate adoption steps. |
| `V1PreviewCompositionEngine` | Preview sample facts -> provider output | Consume adapter during preview | No | Medium | Preview adoption comes after configuration persistence semantics are stable. |
| Renderer / template path | `ExpressionLookup` / legacy tokens | Read module configuration during rendering | No | High | Renderer receives resolved text only. |

## Approved Seam

PI-10 may add a Location-specific adapter only:

```text
ExpressionModuleConfiguration
    -> LocationConfigurationAdapter
    -> LocationPresentationMode
    -> LocationResolutionConfiguration
```

The adapter must be a consumer of provider-neutral configuration. It must not
modify the provider-neutral carrier, `LocationExpressionProvider`, resolver,
formatter, preview, production, or renderer paths.

## Option Mapping

The approved option keys are:

```text
presentationMode
allowsCoordinateFallback
```

Unknown options are ignored. Missing or invalid values fall back to typed
defaults:

```text
presentationMode = provinceCity
allowsCoordinateFallback = false
```

## Out Of Scope

- New platform protocols
- Changes to `ExpressionToken`, `ExpressionValue`, `ExpressionContext`,
  `ExpressionLookup`, or `ExpressionModuleConfiguration`
- Changes to `Expression_System_Contract.md` or ADR-007
- Changes to `LocationExpressionProvider`, `LocationResolver`, or
  `LocationFormatter`
- Changes to `ConfigurationSession`
- Changes to `ConfigurationSnapshot`
- Changes to `MemoryBlock`, `MemoryTokenBlock`, or `MemoryExpression`
- Changes to `IOSInsertedModule`
- Changes to `MemoryBlockInspectorView` or Inspector drafts
- Changes to `V1PreviewCompositionEngine`
- Changes to `ConfigurationCenterPreviewCompositionHelper`
- Changes to `CardVariableProvider`, `RecordCard`, or
  `RecordCardBuildService`
- Renderer, layout, typography, drawing, color, or module behavior
- Export, Share Extension, batch, photo-library, or production behavior

## Selection Rule

Translate generic module configuration at the provider boundary, but outside
the provider.

For PI-10, a Location adapter is smaller and safer than teaching
`ExpressionModuleConfiguration`, `LocationExpressionProvider`, Resolver,
Preview, or Renderer to own strategy parsing.

## Review Checklist

- Adapter consumes `ExpressionModuleConfiguration`.
- Adapter outputs typed Location provider inputs.
- Adapter does not mutate or store configuration.
- Provider, Resolver, Formatter, Renderer, Preview, Production, and platform
  contracts remain unchanged.
- Unknown or invalid options are deterministic and use typed defaults.
- The architectural delta is:

```text
Location configuration adapter: ExpressionModuleConfiguration -> typed Location provider input
```
