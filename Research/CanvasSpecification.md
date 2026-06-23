# Canvas Specification

Last updated: 2026-06-22

## Purpose

Define how PhotoMemo measures the final presentation canvas before any renderer draws it.

## Definitions

- Source photo bounds: original image pixel width and height.
- Output canvas bounds: final generated image width and height.
- Presentation bounds: total area controlled by the Layout Engine.
- Photo region: area where the unmodified source photo is placed.
- Information panel region: area reserved for metadata, memory, brand anchor, and supporting text.

## Measurement Units

All rules must be expressible in:

- pixels
- normalized ratios from `0.0` to `1.0`
- token references
- min/max constraints

## Required Measurements

For every researched layout sample, record:

- source photo width
- source photo height
- source photo aspect ratio
- output canvas width
- output canvas height
- output canvas aspect ratio
- photo region bounds
- information panel bounds
- panel-to-photo height ratio
- panel-to-output height ratio

## Open Questions

- Should the default canvas preserve source photo width exactly?
- Should panel height be fixed, ratio-based, token-based, or a hybrid?
- What is the minimum panel height that can preserve readable metadata?
- What is the maximum panel height before the output becomes a poster instead of a photo presentation?

## Renderer Boundary

Renderer must receive resolved canvas and region bounds from Layout Engine. Renderer must not calculate output canvas size from style-specific magic numbers.
