# MemoMark Evolution Review

## Historical Baseline

## Evolution Series Status

**Current phase:** Phase I Completed  
**Status:** Frozen  
**Frozen on:** 2026-07-14

Phase I established the product-origin, architecture-evolution,
implementation-baseline, outstanding-vision, and governance layers of the
Evolution series.

The series now enters a documentation freeze. New conversations, ideas, and
retrospective interpretations must not directly change Evolution.

Future modifications require at least one qualifying basis appropriate to the
volume:

- changed owning production code or executable contracts;
- an accepted ADR, RFC, PDR, freeze, or superseding architecture decision;
- new signed-device, production, or release-certification evidence;
- a demonstrable factual error in the frozen historical baseline.

Volume V remains deferred until the relevant production audits have produced
engineering principles proven through code, tests, and runtime evidence.

MemoMark Evolution Review is the project's permanent historical baseline.

It is not a changelog, backlog, or collection of retrospective essays. The
series preserves product origin, architectural reasoning, implementation
reality, outstanding vision, durable principles, production evidence, and the
verified project timeline.

The governing statement is:

> History is immutable. Reality is verifiable. Vision is intentional.

In Chinese:

> 历史不可改写；现实必须可验证；愿景必须有明确边界。

## Series Structure

| Volume | Title | Governing Rule | Status |
|---|---|---|---|
| [I](Volume_01_From_PhotoMemo_to_MemoMark.md) | From PhotoMemo to MemoMark | History is immutable | Frozen baseline; factual corrections only |
| [II](Volume_02_Architecture_Evolution.md) | Architecture Evolution | History is immutable | Frozen baseline; factual corrections only |
| [III](Volume_03_Implementation_Scorecard.md) | Implementation Scorecard | Reality is verifiable | V3 baseline frozen; evidence-backed minor updates allowed |
| [IV](Volume_04_Outstanding_Vision.md) | Outstanding Vision | Vision is intentional | Living document |
| V | Design Principles | Principles are stable | Planned |
| VI | Production Certification | Production is evidence-driven | Planned |
| VII | Project Timeline | Timeline records evolution, not opinion | Planned |

Planned volumes are listed to preserve the agreed seven-volume boundary. Their
files should be created only when source material and repository evidence are
ready; this index does not create empty placeholder documents.

## Evidence Governance

Evidence authority depends on the question:

| Question | Authority |
|---|---|
| What does the product implement? | Current code and executable contracts |
| What boundaries are accepted? | Constitution, source-of-truth documents, frozen decisions, ADRs, RFCs, and PDRs |
| What works in production? | Tests, runtime evidence, signed-device results, and release records |
| What was discussed historically? | Historical notes and retrospective drafts |

Conversation-derived material is source material, not repository truth. It may
identify events, motivations, and forgotten alternatives, but it must be
verified before becoming a current conclusion.

## Status Vocabulary

- **Current** — accepted and authoritative now.
- **Historical** — active in an earlier period and later replaced or narrowed.
- **Deprecated** — retained only for compatibility or record.
- **Active proof** — implemented but still accumulating V3 production evidence.
- **Rejected** — intentionally outside MemoMark unless a new decision reopens it.

Historical discussion must not be rewritten as if it were current architecture.
Likewise, current architecture must not be projected backward into historical
documents.

## Change Policy

### Volumes I–II

These volumes are historical baselines. Allowed changes are limited to:

- correcting a factual error;
- adding a missing primary reference;
- clarifying status without changing the historical conclusion;
- fixing terminology, links, or formatting.

New interpretations should be recorded in a later volume rather than silently
rewriting history.

### Volume III

The current V3 scorecard baseline is frozen. A status may change only when new
code, executable contracts, signed-device evidence, release evidence, or an
accepted superseding decision changes the conclusion.

### Volume IV

Outstanding Vision is intentionally living, but must shrink through completion
or explicit rejection rather than grow into a feature wishlist.

Every proposed entry must answer:

> If this vision is never realized, would MemoMark lose part of its product
> identity or accepted architectural direction?

If the answer is no, the item is probably ordinary product work and does not
belong in the Evolution series.

### Volumes V–VII

- Design Principles changes only when long-term repository rules change.
- Production Certification changes only through new evidence or certification
  criteria.
- Project Timeline records verifiable events and dates, not retrospective
  opinions.

## Scope Boundary

The Evolution series must not become:

- a feature backlog;
- a sprint plan;
- a release changelog;
- a duplicate ADR index;
- a daily engineering log;
- a place to revive rejected Workspace, Dashboard, Task Center, Processing
  Center, or import-first product concepts.

Its purpose is to preserve the small number of facts, decisions, unfinished
architectural ambitions, and principles that future MemoMark contributors
must understand.

## Project Knowledge Base Role

Evolution is the narrative and evidence-oriented entry to MemoMark's permanent
Project Knowledge Base. It explains the project across time without replacing
the documents that govern current work.

The recommended reading order for contributors is:

```text
Repository Constitution and Current Status
-> Evolution Review
-> ADR / RFC / PDR and frozen contracts
-> Owning code and tests
-> Runtime and release evidence
```

This order preserves two requirements at once: contributors understand why the
system exists before changing it, and current repository governance remains
authoritative over historical narrative.

## Evolution Maintenance Policy

The Evolution series is review-gated. Changes require a stated evidence basis
and must preserve the role of the volume being edited.

### Rule 1 — Historical Volumes

Volumes I and II may change only when:

- a historical fact is demonstrably wrong;
- a primary reference is missing or incorrect;
- wording confuses historical and current status;
- terminology, links, or formatting require correction without changing the
  historical conclusion.

New interpretations belong in later volumes. History must not be silently
rewritten to match present-day architecture.

### Rule 2 — Implementation Baseline

Volume III scores may change only when at least one of these changes the
evidence conclusion:

- owning production code;
- an accepted ADR, RFC, PDR, freeze, or superseding decision;
- executable contracts or regression tests;
- signed-device runtime evidence;
- release or production-certification evidence.

A new opinion, conversation, or document draft is not sufficient to change a
score.

### Rule 3 — Outstanding Vision

After the Volume IV baseline, a new outstanding vision may be added only when
both conditions are met:

1. the direction has remained relevant through more than one product or
   release version cycle;
2. leaving it permanently unrealized would materially weaken MemoMark's
   product identity or accepted long-term architecture.

The entry must also identify its current evidence, owning boundary, missing
closure, and reason it is not ordinary product work. Ideas that fail this test
belong in product planning, not Evolution.

### Rule 4 — Planned Volumes

Volumes V, VI, and VII remain planned until their evidence foundations are
ready. In particular, Design Principles should be derived from stable rules
that have survived implementation, testing, production audit, and real runtime
behavior. It must not be created early as a collection of unproven beliefs.

## Evolution Change Log

This log records changes to the Evolution baseline itself. It is not a project
Git log or release changelog.

| Date | Volume | Event | Resulting status |
|---|---|---|---|
| 2026-07-14 | Volume I — From PhotoMemo to MemoMark | Established the product-origin historical baseline | Frozen; factual corrections only |
| 2026-07-14 | Volume II — Architecture Evolution | Established the architecture-evolution and replacement baseline | Frozen; factual corrections only |
| 2026-07-14 | Volume III — Implementation Scorecard | Established the evidence-backed V3 implementation baseline | Frozen V3 baseline; evidence-backed minor updates only |
| 2026-07-14 | Volume IV — Outstanding Vision | Established the bounded set of unrealized architectural ambitions and rejected directions | Living; review-gated |
| 2026-07-14 | Volume V — Design Principles | Reserved in the seven-volume structure; intentionally deferred pending production audit maturity | Planned; file not created |
| 2026-07-14 | Volume VI — Production Certification | Reserved for a repeatable production-certification contract and evidence | Planned; file not created |
| 2026-07-14 | Volume VII — Project Timeline | Reserved for a verified event timeline without retrospective opinion | Planned; file not created |

Future entries should be added only when a volume is created, frozen,
superseded, or changes maintenance status. Ordinary factual corrections do not
need a separate change-log event unless they materially alter the historical
baseline.
