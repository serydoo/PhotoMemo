# Reverse Engineering Roadmap

Last updated: 2026-06-22

## Purpose

Define the research order for extracting reusable PhotoMemo layout rules.

This roadmap does not aim for screenshot similarity. It aims to produce measurable specifications that can later drive the Layout Engine.

## Phase 1: Measurement Foundation

- Define canonical measurement vocabulary.
- Define image coordinate conventions.
- Define canvas, panel, slot, typography, and color measurement methods.
- Define what counts as evidence.
- Define what must remain an open question.

Output:

- `MeasurementMethodology.md`

## Phase 2: Canvas And Panel

- Measure canvas aspect behavior.
- Measure photo-to-panel relationships.
- Identify how panel height relates to photo size, output size, and orientation.
- Separate structural layout rules from style-specific visual treatment.

Output:

- `CanvasSpecification.md`
- `PanelSpecification.md`

## Phase 3: Slots And Anchors

- Identify brand-anchor rules.
- Identify metadata slot groups.
- Identify memory slot groups.
- Define slot hierarchy and fallback behavior.

Output:

- `BrandAnchorSpecification.md`
- `MetadataSlotSpecification.md`

## Phase 4: Typography And Color

- Measure text hierarchy.
- Define type scale candidates.
- Define line-height and baseline relationships.
- Extract color tokens and contrast rules.

Output:

- `TypographySpecification.md`
- `ColorSpecification.md`

## Phase 5: Adaptive And Optical Rules

- Identify portrait vs landscape adaptation rules.
- Identify dense vs sparse metadata behavior.
- Define optical compensation rules.
- Define acceptance thresholds.

Output:

- `AdaptiveRules.md`
- `OpticalLayout.md`

## Phase 6: Layout Engine Contract

- Convert research specifications into Layout Engine input/output contracts.
- Define what renderer receives.
- Define what renderer must not compute.

Output:

- first Layout Engine contract draft

## Current Rule

Do not modify renderer or UI while this roadmap is still in Phase 1.
