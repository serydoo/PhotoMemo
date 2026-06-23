# PhotoMemo Research

Last updated: 2026-06-22

Research is the highest-priority activity in PhotoMemo V2.

This folder stores extracted knowledge, not private datasets.

## Policy

- Private family photos must never be committed.
- Screenshots and private research images are temporary inputs only.
- Keep research reports, layout specifications, design tokens, adaptive rules, and validation notes.
- Destroy or exclude private datasets after extracting durable knowledge.

## Workflow

```text
Research
-> Specification
-> Layout Engine
-> Renderer
-> Validation
-> Release
```

Skipping research or specification before renderer changes is prohibited.

## Sections

- `ReverseEngineeringRoadmap.md`
- `ReverseEngineering.md`
- `LayoutSpecification.md`
- `CanvasSpecification.md`
- `PanelSpecification.md`
- `TypographySpecification.md`
- `ColorSpecification.md`
- `BrandAnchorSpecification.md`
- `MetadataSlotSpecification.md`
- `AdaptiveRules.md`
- `AdaptiveLayout.md`
- `OpticalLayout.md`
- `ResearchHistory.md`
- `MeasurementMethodology.md`

## Current Priority

1. `MeasurementMethodology.md`
2. `ReverseEngineeringRoadmap.md`
3. `CanvasSpecification.md`
4. `PanelSpecification.md`
5. `LayoutSpecification.md`

Do not implement Layout Engine or modify renderers until the measurement and layout specifications have enough evidence to define contracts.
