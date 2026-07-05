# PI-2 Renderer Dependency Isolation Boundary Scan

Date: 2026-07-06
Status: Frozen scan
Stage: Platform Integration

## Mission

Identify the smallest renderer dependency seam for `ExpressionLookup`
integration without changing renderer behavior.

## Non-Goal

PI-2 does not change layout, typography, drawing, color, modules, Export, Share
Extension behavior, Preview behavior, Provider integration, or production
output.

## Scan Table

| Consumer | Current Input | Candidate Seam | PI-2 | Migration Risk | Notes |
| --- | --- | --- | :--: | --- | --- |
| `ClassicWhiteCardRenderer` text values | `RecordCard` -> `CardTextBlockEngine` -> `MetadataContext` | `CardTextBlockEngine` variable lookup seam | Yes | Low | First migration target. Text values are resolved before layout-specific text rendering. |
| `ImmersWhiteCardRenderer` text values | `RecordCard` -> `CardTextBlockEngine` -> `MetadataContext` | `CardTextBlockEngine` variable lookup seam | Yes | Low | Shares the same text-block construction path as Classic White. |
| `RecordCardRenderer` routing | `RecordCard` | `RecordCardRenderer(image:card:)` | No | Medium | Routing still needs template preset, metadata size, and badge data. Replacing this constructor would enlarge PI-2. |
| Main preview canvas | `RecordCardRenderer(image:card:)` | Preview call site in `MainView+PreviewPanels.swift` | No | Medium | Defer. Changing preview call site risks preview behavior drift. |
| Export renderer | `RecordCardExportService` -> `RecordCardRenderer(image:card:)` | Export render entry | No | High | Defer. Export path also writes image metadata and description. |
| Batch / Share processing | `RecordCardBuildService` -> `RecordCard` | Build-service output model | No | High | Defer. This crosses production, batch, and Share Extension boundaries. |
| `TemplateVariableEngine` | `MetadataContext` | Template variable rendering API | No | Medium | Defer. This is broader than renderer dependency isolation because it is also used by export description and editor support. |
| `CardVariableProvider` | `RecordCard` -> `MetadataContext` | Legacy context projection | No | Medium | Defer. This remains the legacy adapter source until provider migration is approved. |

## Recommended Seam

PI-2 will replace the renderer text dependency at:

```text
CardTextBlockEngine
    -> TemplateVariableEngine.render(...)
    -> MetadataContext lookup
```

with a lookup-capability seam:

```text
CardTextBlockEngine
    -> ExpressionLookup
```

This is the smallest architectural surface because both current renderer
implementations already consume the resulting `CardTextBlock` values. PI-2 can
therefore isolate renderer text lookup without changing renderer layout,
drawing, export behavior, or the `RecordCardRenderer` routing API.

## Out Of Scope

- `RecordCardRenderer(image:card:)` constructor replacement
- `RecordCard` model replacement
- Export renderer migration
- Share Extension migration
- Batch processing migration
- Preview behavior migration
- `TemplateVariableEngine` platform-wide API migration
- `CardVariableProvider` removal
- Provider integration
- Layout, typography, drawing, color, and module changes

## Selection Rule

Choose the seam with the smallest architectural surface, not the smallest line
count.

For PI-2, the text-block lookup seam is smaller than the render-entry seam
because it avoids changing render routing, export rendering, preview call
sites, or production card construction.

## Review Checklist

- Renderer text lookup depends on `ExpressionLookup` capability.
- Renderer code must not depend on concrete `ExpressionContext` storage.
- Renderer code must not assume dictionary-backed lookup.
- Renderer code must not enumerate tokens or values.
- Renderer code must not mutate lookup input.
- Renderer output must not change.
- PI-2 must approve only this one integration seam.
