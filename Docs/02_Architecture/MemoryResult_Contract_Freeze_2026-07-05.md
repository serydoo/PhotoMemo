# MemoryResult Contract Freeze

| Item | Value |
| --- | --- |
| **Status** | Accepted |
| **Scope** | IA-003 Domain Model Convergence |
| **Architecture Phase** | Contract Freeze |
| **Decision** | Memory Engine outputs structured semantic `MemoryResult` |
| **Next Review** | Before `MemoryResult` implementation begins |

## Objective

This document freezes the semantic contract for `MemoryResult` before
implementation.

IA-003 is not a UI refactor, Renderer evolution, or Memory feature expansion.
It is a production-pipeline convergence effort. The next required convergence
step is to move Memory Engine output from presentation-shaped strings toward a
structured domain result:

```text
MemoryEngine
    ↓
MemoryResult
    ↓
Presentation
```

`MemoryResult` answers:

```text
What does the Memory Engine know?
```

It does not answer:

```text
What final sentence should the UI display?
```

## Design Principles

### Pure Semantic

`MemoryResult` must contain Memory-domain facts and computed semantic values.
It must not contain final display copy, full prose, UI labels, slot placement,
typography, renderer state, or export state.

### Composable

Presentation must be able to combine `MemoryResult` with user-authored
expression, Preset fields, localization rules, and future block templates
without asking Memory Engine to recalculate.

### Extensible

The model must allow future Memory capabilities such as anniversaries,
festivals, growth stages, school stages, travel stages, and custom life events
without changing the meaning of existing fields.

### Serializable

`MemoryResult` should be stable enough for tests, caching, diagnostics, and
future export/debug payloads. The implementation should prefer `Codable` and
`Hashable` where practical.

### Deterministic

`MemoryResult` must be derived from frozen input and capture-time context. It
must not read live `UserDefaults`, current UI state, environment state, or
renderer/export state.

## Contract Shape

The final Swift API may vary, but the semantic shape is frozen as:

```text
MemoryResult
├── subjectID
├── captureDate
├── primaryAnchorResultID
├── anchorResults
└── metadata
```

### MemoryResult

| Field | Meaning |
| --- | --- |
| `subjectID` | Frozen `MemorySubject` identity used for the calculation. |
| `captureDate` | Photo capture time used by Memory Engine. |
| `primaryAnchorResultID` | Optional ID of the anchor result selected as primary output. |
| `anchorResults` | Structured results for resolved Life Anchor / Time Anchor calculations. |
| `metadata` | Deterministic diagnostics such as engine version, source kind, or missing-input status. |

### MemoryAnchorResult

Each anchor calculation should be represented as a structured result:

```text
MemoryAnchorResult
├── id
├── anchorID
├── anchorType
├── anchorTitle
├── anchorDate
├── direction
├── elapsed
├── precision
├── status
└── source
```

| Field | Meaning |
| --- | --- |
| `id` | Stable result identity for downstream reference. |
| `anchorID` | Source anchor identity. |
| `anchorType` | Birthday, relationship, marriage, exam, custom, or future types. |
| `anchorTitle` | Source anchor title, retained as data rather than final prose. |
| `anchorDate` | Anchor date used for calculation. |
| `direction` | Whether capture time is before, on, or after the anchor. |
| `elapsed` | Structured time distance such as years, months, days, total days, weeks, and total months. |
| `precision` | Granularity of the result, such as day-level or missing capture date. |
| `status` | Resolved, missing capture date, disabled anchor, unsupported anchor, or other deterministic states. |
| `source` | Whether the result came from frozen configuration, legacy adapter, or compatibility path. |

### Semantic Time Distance

Elapsed time must remain structured. The model should preserve values such as:

```text
years
months
days
totalDays
weeks
totalMonths
isFutureRelative
```

Formatted outputs such as `1岁2个月18天`, `还有86天`, or `婚后3年` are
Presentation outputs, not `MemoryResult` fields.

## Explicit Non-Contract

The following fields must not be added to `MemoryResult`:

```text
displayText
subtitle
badgeText
fullSentence
renderedText
slotText
templateText
localizedSentence
```

These names are intentionally excluded because they make Memory Engine own final
expression.

## Presentation Responsibility

Presentation consumes `MemoryResult` and owns:

- final sentence composition
- language and localization
- user-authored literal text
- expression style
- Preset / MemoryBlock field assembly
- compatibility projection to the current rendered text pipeline

The current `MemoryModule.renderedText` and `MemorySemanticResult.displayText`
may remain temporarily as compatibility outputs during migration, but they are
not the target Memory Engine contract.

## Migration Sequence

IA-003 must continue in this order:

1. **Freeze Contract**
   - This document defines the `MemoryResult` semantic boundary.
2. **Implement**
   - Add the structured `MemoryResult` model and make Memory Engine produce it.
3. **Migrate**
   - Add a Presentation compatibility formatter that projects `MemoryResult`
     into the current string-based output where existing callers still need it.
4. **Remove Legacy**
   - Remove direct string output from Memory Engine after callers consume
     `MemoryResult` or an explicit Presentation projection.

## Acceptance Criteria

`MemoryResult` implementation is complete only when:

- Memory Engine returns structured `MemoryResult` from frozen input.
- `MemoryResult` has no final display copy or full sentence fields.
- Presentation is responsible for converting `MemoryResult` into user-facing
  text.
- Existing output behavior can be preserved through a compatibility
  Presentation formatter.
- Tests can assert semantic fields without snapshotting prose.
- Production Memory code does not introduce new runtime-state reads.
- Renderer, Export, Share Extension, Photo Library behavior, and Layout Engine
  remain untouched by this contract slice.

## Architecture Impact Check

All IA-003 implementation PRs that touch Memory Engine output should answer:

| Item | Expected Answer |
| --- | --- |
| New Runtime State Introduced | No |
| New Truth Introduced | No |
| Bypasses Frozen Input | No |
| Production Pipeline Changed | Only through frozen-input consumption |
| Architecture Review Update Required | No, unless IA-003 Completion Criteria change |

## Review History

| Version | Date | Summary |
| --- | --- | --- |
| Contract-001 | 2026-07-05 | Frozen semantic contract for structured `MemoryResult` before implementation. |
