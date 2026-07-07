# MemoMark V2 Project Reset

Last updated: 2026-06-22

## Status

MemoMark feature development is paused.

The project has entered the MemoMark Research Phase.

`PROJECT_CONSTITUTION.md` is now the highest-level repository instruction. Read it before this file.

## Why Development Stopped

The previous implementation path was converging on renderer and UI refinement. That work improved output quality, but it also exposed a deeper architectural problem: layout decisions were still distributed across renderer code, UI assumptions, and manually tuned constants.

Continuing to polish renderer details would make MemoMark better as a photo watermark or card generator, but it would not make it a reusable Memory Presentation Engine.

## Why Reverse Engineering Begins

MemoMark now treats great photo presentation examples as research material, not as designs to copy.

The goal is to extract reusable, measurable principles:

- canvas relationships
- information panel structure
- brand-anchor placement
- metadata slot hierarchy
- typography ratios
- spacing systems
- color and contrast behavior
- optical alignment
- adaptive layout rules

Private research photos are temporary inputs. Specifications are the lasting project asset.

## Why Layout Engine Was Introduced

Renderer code should draw resolved presentation instructions. It should not invent layout.

MemoMark V2 introduces a Layout Engine as the only source of layout truth. The future chain is:

```text
Photo
-> Metadata Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

The renderer must become stateless from a layout perspective.

## Why Memory Presentation Engine Became The Better Definition

MemoMark does not only present photographs. It presents memories.

Objective photo metadata answers:

- When?
- Where?
- How?

Memory context answers:

- What does this moment mean?
- Where does this photo belong inside a person's life?

The Memory Engine calculates Life Position. Presentation Engine expresses it. Layout Engine presents it. Renderer draws it.

## Why Repository V2 Exists

The repository needs to become understandable as an open-source engine project, not only as the author's app history.

V2 priorities:

1. Research first
2. Specification first
3. Layout before renderer
4. Metadata as the single source of truth
5. No private datasets in the repository
6. No magic numbers without specification backing
7. Every layout decision must be measurable

## Forbidden Until Further Notice

- Do not polish Immers imitation.
- Do not add new visual styles by renderer-only tuning.
- Do not expand UI features.
- Do not immediately migrate old documents before research specifications stabilize.
- Do not add layout constants directly inside renderers.
- Do not commit private family photos or private reverse-engineering datasets.
- Do not treat screenshots as product assets. Treat extracted specifications as product assets.
