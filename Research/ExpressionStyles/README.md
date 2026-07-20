# MemoMark V4 Candidate: Expression Style System

Last updated: 2026-07-20

## Status

```text
Research Seed
Deferred Until V3 Reliability Closure
Not Frozen
No Implementation Authorized
```

This document archives the initial product thesis for a possible MemoMark V4
direction. It is intentionally a research starting point rather than a Product
Design Review, architecture decision, implementation plan, or commitment to a
V4 product stage.

MemoMark remains in:

```text
V3 Production Quality And Delivery
```

No Swift model, persistence schema, Configuration Center interaction,
Presentation Engine, Layout Engine, Renderer, Export, or Share workflow may be
changed from this document alone.

## Product Thesis

The long-term MemoMark promise remains:

> Configure once, and let every future photo express the memory automatically.

The configured result should eventually describe more than a white border or
a fixed arrangement. It should represent the user's preferred way of expressing
a memory:

```text
Expression Style
```

The user is not choosing whether a footer is 120 pt or 160 pt. The user is
choosing how the photograph should tell its story.

## Assumptions For This Research Seed

1. `Preset` remains the user-owned saved configuration concept.
2. `Expression Style` is a candidate component inside a Preset, not a rename of
   Preset and not a replacement for Configuration Center.
3. `MemoryBehavior` continues to own memory meaning and expression priorities.
4. Renderer remains downstream implementation and must not become the owner of
   style or layout decisions.
5. The frozen IA-002 structure remains:

   ```text
   Library
   -> Interactive Memory Card
   -> Object Inspector
   ```

6. V4 research may continue as documentation, but production implementation is
   deferred until the V3 reliability gates are closed and a future PDR is
   explicitly reviewed.

These assumptions require validation before a specification is frozen.

## Proposed Concept Separation

The initial discussion contained two different dimensions. They must remain
separate to avoid turning every semantic scenario and visual treatment into a
new template.

### Expression Style

Expression Style describes visual and presentation grammar:

- geometry
- composition mode
- typography hierarchy
- color treatment
- information density
- default content placement
- relationship between the photo and the presentation surface

Initial candidates:

| Candidate | Presentation Character |
| --- | --- |
| Classic | Complete reserved information card |
| Minimal | One-line or two-line low-presence expression |
| Signature | Lightweight corner overlay without a full card |
| Film | Monospaced photographic border and EXIF hierarchy |
| Magazine | Editorial title-led composition |

### Memory Behavior

Memory Behavior describes what the memory prioritizes and how meaning is
assembled:

- Journal: narrative sentence and date first
- Story: event or milestone first
- Baby: age and growth milestone first
- Travel: location and time context first
- Timeline: life-position sequence first

`Timeline` remains an open classification question because it may contain both
semantic behavior and a distinct composition model.

### Style Variant

A Style Variant is a bounded variation within one Expression Style. Examples:

- Classic: White, Black, Gray
- Minimal: One Line, Two Line, Corner
- Film: Leica-like hierarchy, General EXIF, Year Border

Names used here are research labels only. They do not authorize imitation of a
brand, trademark use, or renderer-specific implementation.

## Candidate Composition Model

The long-term user-owned configuration may be understood conceptually as:

```text
Preset
├─ Memory Subject
├─ Memory Behavior
├─ Expression Style
├─ Style Variant
├─ Content Composition
├─ Decoration
└─ Output Policy
```

This is a product model for research. It is not the current persistence schema
and must not be used to justify an immediate schema migration.

The separation enables combinations such as:

```text
Baby Behavior + Minimal Style
Travel Behavior + Film Style
Journal Behavior + Classic Style
```

Without this separation, every combination would become another independent
template and the library would grow without a coherent system.

## Candidate Architecture Direction

Expression Style should become a versioned presentation specification, not a
large Renderer switch statement.

The intended ownership direction is:

```text
Configuration Snapshot
-> Memory Engine Results
-> Memory Behavior
-> Expression Style Specification
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

Ownership boundaries:

- Memory Engine calculates reusable time and life-position results.
- Memory Behavior selects semantic priorities and expression composition.
- Expression Style defines presentation grammar and supported variation.
- Layout Engine resolves measurable geometry.
- Renderer draws resolved output without inventing layout.
- Export preserves the generated output and supported metadata contracts.

## Style Library Interaction Hypothesis

A growing style system should not rely on a long text-only dropdown.

The preferred research direction is a horizontal visual library inspired by
Apple-native wallpaper and filter selection patterns:

- every card uses the real Memory Card preview
- horizontal movement compares styles directly
- selecting a card updates the current Configuration Preview
- detailed properties remain editable through Object Inspector
- adding a future style does not require a new workflow concept

This library must remain inside Configuration Center. It must not create a new
Dashboard, Workspace, template marketplace, or daily import workflow.

The repository-facing name `Preset` remains unchanged unless a future Product
Design Review explicitly amends the frozen vocabulary. `Expression Style` is a
candidate user-facing term that still requires language validation.

## Candidate Style Families

The initial idea set is preserved below without treating every item as an
approved implementation commitment.

| Research Family | Likely Dimension | Core Emphasis |
| --- | --- | --- |
| Classic | Expression Style | Complete information card |
| Minimal | Expression Style | Low-density everyday sharing |
| Signature | Expression Style | Lightweight corner signature |
| Film | Expression Style | Photographic and EXIF language |
| Magazine | Expression Style | Editorial visual hierarchy |
| Journal | Memory Behavior | Personal sentence and date |
| Story | Memory Behavior | Event or milestone narrative |
| Baby | Memory Behavior | Age and growth priority |
| Travel | Memory Behavior | Place and journey priority |
| Timeline | Open | Sequential life-position expression |

Future research should prefer `Style Family` or `风格系列` over `Style Pack`.
The latter risks implying a template marketplace, which is outside MemoMark's
product identity.

## V3 Release Gate

This research does not change the active engineering order.

No V4 feature implementation should precede V3 reliability closure. The next
engineering work remains:

```text
TX-001 Export Transaction Specification And Failure Tests
-> BP-001 Enforced Single-Task Memory Contract
-> V3 Reliability Evidence And Certification Closure
```

Research and product discussion may continue without touching production code.
Implementation may begin only after:

1. V3 release-blocking reliability gaps are resolved or explicitly waived.
2. The Expression Style product model is reviewed through a future PDR.
3. Vocabulary, persistence, migration, Layout Engine, preview, export, and
   compatibility boundaries have approved specifications.
4. A verification plan protects existing Classic White output and saved
   configuration.

## Proposed Research Sequence

```text
Research Seed
-> User Expression Scenarios
-> Style Dimension Taxonomy
-> Synthetic Visual Studies
-> Measurable Style Specifications
-> Product Design Review
-> Architecture Review
-> Implementation Plan
-> Code
```

The likely first implementation proof, when eventually authorized, should be:

1. Express existing Classic White through the new specification without visual
   or persistence change.
2. Add one structurally different Minimal style.
3. Verify preview/export fidelity, migration, and orientation behavior before
   expanding the library.

This sequence is deferred and is not an active implementation plan.

## Research Questions

The following questions must be answered before a PDR can freeze the system:

1. What is the exact user-facing distinction between Preset and Expression
   Style?
2. Which dimensions belong to Memory Behavior, Expression Style, Style Variant,
   and Content Composition?
3. Is Timeline primarily semantic, visual, or a composition mode shared by
   several styles?
4. How does switching styles preserve or transform user-edited Memory Blocks?
5. Which customization properties are portable between styles?
6. How are style identity, versioning, migration, fallback, and deletion
   represented durably?
7. What capabilities must every style declare for portrait, landscape, square,
   Live Photo, RAW-derived output, and accessibility text?
8. How does the style library remain understandable with 20 or 50 entries?
9. Which style properties belong to Presentation Engine and which measurable
   properties belong exclusively to Layout Engine?
10. What evidence proves that Configuration Preview and production export
    remain identical for every supported style?

## Research Completion Criteria

This research seed is ready to advance into a Product Design Review only when:

- the semantic and visual dimensions no longer overlap ambiguously
- at least two structurally different styles have measurable specifications
- switching and migration behavior is defined
- the real Configuration Center interaction is described without reopening
  IA-002
- preview/export parity requirements are explicit
- Layout Engine ownership is measurable
- V3 reliability work is no longer displaced by the proposal

Until then, this document remains an idea archive and discussion anchor.
