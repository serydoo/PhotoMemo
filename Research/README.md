# MemoMark Research

Last updated: 2026-07-30

Research is the active Product Loop in `V4 Expression Style System`. It supplies
evidence and measurable specifications without reopening frozen V2/V3
architecture or bypassing the V4 Entry Engineering Gate.

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

1. `ExpressionStyles/` -> `ES-001 User Expression Scenarios`
2. Expression Style dimension taxonomy
3. synthetic Classic and Minimal visual studies
4. measurable Classic and Minimal style specifications
5. V4 Product Design Review preparation

The V4 Expression Style direction is active in `ExpressionStyles/` as the V4
research foundation. It is not a frozen PDR or an active implementation track.
Expression Style production work and broader production-capability claims
remain blocked by the V4 Product Design Review and the `TX-001` / `BP-001` /
superseding-certification Engineering gate. This does not block separately
scoped refinement of existing product surfaces that preserves frozen ownership.

The general measurement, reverse-engineering, canvas, panel, and layout
specifications remain prerequisites and should be reused by V4 rather than
replaced with style-local constants.

The iOS semantic icon reserve is recorded in `Iconography/`. It derives from
the current Configuration Center language and provides stable SF Symbol,
semantic-color, sizing, and adoption guidance. It is a reusable UI reserve,
not authorization for a repository-wide visual rewrite.

The reusable window, bounded content column, card, inner-panel, and row
hierarchy is defined in `ConfigurationCenterWindowSpecification.md`. New
configuration windows and content surfaces should reuse this hierarchy before
introducing local width or chrome behavior.

Do not implement Layout Engine or modify renderers until the measurement and layout specifications have enough evidence to define contracts.
