# MemoMark Research

Last updated: 2026-07-20

Research remains a governed activity in MemoMark V3. It supplies evidence and
specifications for production-quality changes without reopening frozen V2
architecture.

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
- `ExpressionStyles/`
- `Iconography/`
- `ConfigurationCenterWindowSpecification.md`

## Current Priority

1. `MeasurementMethodology.md`
2. `ReverseEngineeringRoadmap.md`
3. `CanvasSpecification.md`
4. `PanelSpecification.md`
5. `LayoutSpecification.md`

The possible V4 Expression Style direction is archived in
`ExpressionStyles/` as a research seed. It is not a frozen PDR or an active
implementation track. MemoMark remains in V3, and production work continues
with reliability closure before any Expression Style source change.

The iOS semantic icon reserve is recorded in `Iconography/`. It derives from
the current Configuration Center language and provides stable SF Symbol,
semantic-color, sizing, and adoption guidance. It is a reusable UI reserve,
not authorization for a repository-wide visual rewrite.

The reusable window, bounded content column, card, inner-panel, and row
hierarchy is defined in `ConfigurationCenterWindowSpecification.md`. New
configuration windows and content surfaces should reuse this hierarchy before
introducing local width or chrome behavior.

Do not implement Layout Engine or modify renderers until the measurement and layout specifications have enough evidence to define contracts.
