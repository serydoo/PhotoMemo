# MemoMark Research

Last updated: 2026-09-26

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

- `VisualPrototypes/ConfigurationPreviewReview-2026-09-23.html` -> interactive review prototype for Classic White, Minimal, FilmMark, and FM calibration preview states
- `VisualPrototypes/NativeConfigurationPreviewReview-2026-09-23.md` -> scope and acceptance record for the DEBUG-only native SwiftUI preview review route
- `VisualPrototypes/MidAutumnSharedPreviewBackgrounds-2026-09-24.md` -> owner-provided shared landscape/portrait preview assets and three-style review scope
- `VisualPrototypes/ConfigurationPreviewProductionIntegration-2026-09-24.md` -> approved iOS production-preview integration, local preference boundaries, and Baguette verification plan
- `VisualPrototypes/MemoMark-Cross-Surface-Visual-Review-2026-09-26.md` -> unified review of recent Home, Configuration Center preview, Classic White portrait, and FilmMark overflow changes; records the current edge-button contract and open device acceptance
- `ExternalDesignStudies/2026-09-23-Apple-Featured-App-Design-Study-01.md` -> recent Apple-featured and design-award app patterns translated into MemoMark research hypotheses
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
- `ExpressionStyles/FilmMark-Renderer-Spec-2026-09-14.md` -> FM independent
  Renderer specification; Classic White and Minimal remain frozen
- `Iconography/`
- `ConfigurationCenterWindowSpecification.md`

## Current Priority

2026-10-07 combined competitor/content/form execution is routed through
`Docs/03_Engineering/2026-10-07-post-2.3.6-research-execution-plan.md`.
The 2.3.6/124 baseline already has source-frame-dependent GlassCard motion;
measure its SDR fidelity/resource boundaries before proposing new material
behavior. Adaptive SDK probes may proceed independently while ordinary iPhone
landscape physical acceptance remains the next product gate.

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
introducing local width or chrome behavior. The 2026-09-24 production-preview
integration note records the initial swipe implementation; the current
orientation-switching contract uses the edge buttons documented by the
2026-09-24 arrow-switching decision and the 2026-09-26 cross-surface review.

Do not implement Layout Engine or modify renderers until the measurement and layout specifications have enough evidence to define contracts.
