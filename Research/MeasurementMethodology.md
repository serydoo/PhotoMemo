# Measurement Methodology

Last updated: 2026-06-22

## Purpose

Define how MemoMark research turns visual references into measurable layout knowledge.

## Forbidden Language

Avoid:

- approximately
- looks similar
- seems
- close enough
- more premium
- nicer

If a description is not measurable yet, mark it as an open question.

## Preferred Measurement Language

Use:

- pixel dimensions
- normalized ratios
- percentages
- bounding boxes
- baselines
- cap height
- x-height
- optical center
- safe area
- grid unit
- token value
- min/max constraint
- acceptance threshold

## Coordinate System

Use top-left origin unless a specific tool reports a different coordinate system.

Record every rectangle as:

```text
x, y, width, height
```

Record ratios as:

```text
value / reference = ratio
```

Example:

```text
panelHeight / outputHeight = 260 / 1340 = 0.1940
```

## Evidence Levels

### Level 1: Observation

A visual pattern was noticed but not measured.

Use only as a research prompt.

### Level 2: Measurement

A pattern was measured in one or more samples.

Use for draft specifications with open thresholds.

### Level 3: Rule

A pattern has repeatable measurements and a stated threshold.

Use for Layout Engine candidates.

### Level 4: Contract

A rule has tests or validation criteria.

Use for implementation.

## Research Record Template

```text
Reference ID:
Source type:
Privacy status:
Canvas bounds:
Photo bounds:
Panel bounds:
Brand anchor bounds:
Primary text bounds:
Metadata slot bounds:
Typography measurements:
Color measurements:
Observed rule:
Measured evidence:
Open questions:
Implementation candidate:
```

## Dataset Policy

Private datasets must not enter the repository.

Only extracted measurements, rules, and anonymized research conclusions may be committed.
