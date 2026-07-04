# V1 Render Contract Freeze

Status: `Accepted for V1 Stabilization`

Date: `2026-07-03`

Scope:
- current V1 iOS editor preview
- current V1 production preview and export path
- text, token, and render-contract semantics only

Not in scope:
- renderer redesign
- export behavior rewrite
- bootstrap repair
- Draft test repair
- V2 layout-engine migration

## One-Sentence Decision

For V1 stabilization, Preview must stop acting as an independent rendering
authority, and template text, display text, renderer input, and export input
must each have one stable meaning.

## Problem

The current repository has drifted into a dual rendering shape:

```text
Preview/editor path
    Draft -> local compose -> Preview UI

Production path
    BatchConfigurationSnapshot -> RecordCardBuildService -> RecordCard
    -> CardVariableProvider -> CardTextBlockEngine -> Renderer -> Export
```

This makes the failing Draft orchestration test unsafe to treat as a local Draft
bug, because the failure sits on top of a contract mismatch.

## Contract Layers

### Layer 1: Template Source

Meaning:
the token-preserving source string that is intended to survive save, reload,
and later production rendering.

Examples:

```text
记录{{memory_summary}}
{{anchor_age_text}}
```

Owner:
template-facing editor state

Current concrete forms:
- `V1EditorDraft.singleLineTemplateText`
- `V1PreviewDraft.singleLineTemplateText`
- `TemplateArea.value`

### Layer 2: Display Text

Meaning:
the human-visible expanded text shown in preview UI.

Examples:

```text
记录乐乐今天1岁2个月18天啦！
还有86天
```

Owner:
preview-facing display state only

Rule:
display text must never replace template source semantics.

### Layer 3: Render Contract

Meaning:
the resolved production-facing input that is allowed to feed renderer output.

Current concrete path:

```text
BatchConfigurationSnapshot
    -> RecordCardBuildService
    -> RecordCard
    -> CardVariableProvider
    -> CardTextBlockEngine
```

Rule:
this is the only contract allowed to drive final rendered image content.

### Layer 4: Renderer Input

Meaning:
the final text/layout-ready content consumed by renderer code.

Current concrete form:
- `RecordCard` plus `CardTextBlockEngine` output

Rule:
renderer must not infer subject meaning, rebuild preview text, or reinterpret
Draft semantics.

### Layer 5: Export Input

Meaning:
the renderer-consumable production card that export turns into a file.

Current concrete form:
- `RecordCard` passed into `RecordCardExportService`

Rule:
export must not recompute semantic text independently.

## Freeze Decisions

### FC-001 `singleLineTemplateText` is template source only

Definition:

```text
singleLineTemplateText == token-preserving template source
```

It must always mean:

```text
记录{{memory_summary}}
```

It must never mean:

```text
记录乐乐今天1岁2个月18天啦！
```

Reason:
without this freeze, Draft, Preview, Save, and Export will continue to argue
over the same field name.

### FC-002 Expanded preview text must use a different name

Required direction:
if a caller needs expanded one-line preview text, it must use a separate field.

Allowed naming examples:
- `resolvedSingleLineText`
- `displayText`
- `resolvedDisplayText`

Forbidden direction:
reusing `singleLineTemplateText` for expanded preview output.

### FC-003 Preview is not a second rendering authority

Preview may:
- display expanded text
- show temporary/local composition state
- help the user edit template composition

Preview may not:
- redefine template-source meaning
- become the source of truth for production-rendered text
- silently diverge from the production contract

### FC-004 Renderer consumes production contract, not Draft

Renderer must only consume production-built render inputs.

Renderer must not consume:
- `V1EditorDraft`
- `V1PreviewDraft`
- editor-only display text

### FC-005 Export consumes renderer-ready production input

Export must render the `RecordCard` it receives.

Export must not:
- rebuild token display text
- recompute memory preview text independently
- reinterpret Draft-layer strings

### FC-006 `MemoryModule -> memory_summary` is a compatibility seam, not the end state

Current V1 fact:
`MemoryModule.renderedText` is projected into the legacy `memory_summary` slot.

Interpretation:
this is accepted as an interim V1 seam.

Constraint:
future work must not treat that projection as proof that preview and production
contracts are already unified.

### FC-007 Batch snapshot is a known limitation, not a true semantic snapshot

Current V1 fact:
`BatchConfigurationSnapshot` is still closer to a configuration reference than a
fully replayable semantic snapshot.

V1 rule:
this limitation must be treated as explicit repository knowledge, not as an
assumed snapshot guarantee.

### FC-008 Contract immutability

Definition:
once a production render contract has been built, all downstream consumers must
treat it as immutable display data.

Allowed:
- Preview displays contract data
- Renderer renders contract data
- Export exports renderer-ready contract data

Forbidden:
- reparsing template source after contract build
- re-expanding token values after contract build
- recomputing metadata-derived display strings after contract build
- mutating contract text inside Preview, Renderer, or Export

Interpretation:
all new parsing, token expansion, and semantic resolution logic must live in the
contract-building stage, not in contract consumers.

### FC-009 Renderer output specification is the V1 visual authority

Definition:
for V1 stabilization, the renderer defines the concrete output specification
that both preview and export must respect.

Renderer owns:
- final canvas interpretation
- typography application
- spacing and alignment as currently implemented
- image composition rules for the generated output
- the pixel-level expectation used to judge preview/export fidelity

Renderer does not own:
- Draft/editor semantics
- token expansion
- Memory Subject interpretation
- metadata-derived display calculations
- future V2 Layout Engine responsibilities

Preview rule:
Preview may present a lightweight or interactive view, but any visual
difference from renderer output must be treated as a fidelity gap or an
explicitly documented limitation. Preview must not become a second visual
specification.

Export rule:
Export must render the renderer-ready contract through the renderer. Export
must not apply a second visual policy after renderer output is produced.

Change rule:
Any intentional change to renderer visual output must update renderer-facing
tests, preview/export parity expectations, and this contract record when the
change affects V1 release behavior.

Consistency repair rule:
Any preview/export consistency repair should first modify RenderModel or the
Renderer Contract. It must not add Preview-specific special logic that creates
a second production interpretation path.

## Required Contract Flow

```text
Template Source
    │
    ├── editor state may preserve and mutate source tokens
    │
    ├── contract builder derives Display Data
    │
    ├── preview may display contract data
    │       but may not rewrite Template Source semantics
    │
    ▼
Saved Template / BatchConfigurationSnapshot
    │
    ▼
ContractBuilder / production build path
    │
    ▼
Immutable RenderContract
    │
    ├── Preview
    ├── Renderer
    └── Export
```

Current V1 approximation:

```text
BatchConfigurationSnapshot
    -> RecordCardBuildService
    -> RecordCard
    -> CardVariableProvider
    -> CardTextBlockEngine
```

## 2026-07-03 Contract Convergence Closure

Status:
Contract-class P0 is closed for V1 stabilization.

Closure basis:

- `singleLineTemplateText` is template source
- `resolvedSingleLineText` and `displayText` are display text
- PreviewSync consumes `V1PreviewRenderModel.displayText`
- public `composeText` has been removed
- external `moduleValue` production access has been removed
- `resolvedDisplayValue` remains only as private engine internals
- Contract tests, Preview migration tests, Draft tests, helper tests, iOS
  build, `git diff --check`, and global identifier searches passed

Remaining work is no longer classified as Contract P0. It is Runtime Review:
Bootstrap lifecycle, Export lifecycle, metadata fidelity, physical-device UI
behavior, temporary-file cleanup, notification lifecycle, and long-running
stability.

## Known Violations At Freeze Time

The following list records the conditions this document was created to close.
It is retained as historical context for the Contract Convergence milestone.

1. Preview still expands and composes text locally in multiple places.
2. `singleLineTemplateText` is currently expected as expanded text in at least
   one Draft orchestration test.
3. Production memory is only partially unified through a compatibility
   projection.
4. Saved batch configuration is not yet a true replayable semantic snapshot.

## Original Immediate Work Order

The contract-facing items in this order have been completed or reclassified by
the 2026-07-03 closure note above.

1. Unify model semantics around template source vs expanded display text.
2. Remove any remaining display-text use of `singleLineTemplateText`.
3. Introduce a contract-building seam for shared Preview and production consumption.
4. Reduce and then remove preview-local contract production logic.
5. Reclassify and repair the Draft test only after the contract is stable.
6. Continue Bootstrap and remaining stabilization work after contract convergence.

## Stabilization Implementation Direction

Recommended implementation order:

1. Model split
   - keep `singleLineTemplateText` as template source only
   - introduce a separately named expanded preview field where needed
2. Contract builder seam
   - create one build stage that produces shared display data
   - Preview and production consumers should converge on this stage
3. Preview authority reduction
   - shrink `composeText()`, `resolvedDisplayValue()`, `moduleValue()`, and
     similar helpers until Preview no longer produces its own rendering truth
4. Draft test repair
   - fix `V1DraftOrchestrationCoordinatorTests` against the frozen contract
     instead of against pre-freeze assumptions

## Verification Standard For Future Fixes

Any future fix in this area should answer these questions explicitly:

1. Is this value template source or display text?
2. Is this logic happening before contract build or after contract build?
3. Is Preview deriving text locally or consuming the shared contract?
4. Does this change make Preview, Renderer, and Export more singular or more split?
5. Would the same saved configuration still mean the same thing later?
