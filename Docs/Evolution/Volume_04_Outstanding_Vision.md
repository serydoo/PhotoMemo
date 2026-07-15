# MemoMark Evolution Review

## Volume IV — Outstanding Vision

**Document version:** 1.0  
**Status:** Living Document  
**Scope:** Architectural vision not fully realized as of V3  
**Evidence cutoff:** 2026-07-14  
**Author:** MemoMark Project  
**Last updated:** 2026-07-14

## Purpose

This document records the parts of MemoMark's accepted architectural vision
that have not yet been fully realized.

It is not a feature backlog, roadmap, sprint plan, or list of desirable ideas.
Vision is not TODO.

An item belongs here only when at least one of the following is true:

- it is part of MemoMark's accepted long-term product or architecture;
- its foundation exists but the intended ownership boundary is incomplete;
- implementation exists but production evidence is insufficient;
- leaving it permanently incomplete would weaken MemoMark's product identity,
  production integrity, or established architecture.

Every candidate must answer:

> If this vision is never realized, would MemoMark lose part of its product
> identity or accepted architectural direction?

If the answer is no, the item belongs in ordinary product planning rather than
the Evolution series.

## Evidence and Status Policy

Outstanding Vision does not override the implementation scorecard. Current
facts are owned by
[`Volume III`](Volume_03_Implementation_Scorecard.md), while accepted boundaries
remain owned by the constitution, frozen decisions, ADRs, RFCs, and PDRs.

Each item uses one of four classifications:

| Classification | Meaning |
|---|---|
| **A — Long-term Vision** | An accepted architectural goal is not yet fully implemented. |
| **B — Foundation Exists** | The owning foundation exists; the remaining gap is integration or workflow closure. |
| **C — Production Evidence** | The implementation exists; stronger runtime or release evidence is still required. |
| **D — Explicitly Rejected** | The direction is intentionally excluded and must not return without a new decision. |

An item may move from A to B to C as it matures. When production evidence
closes it, the result should be recorded in Volume III or Volume VI and removed
from the outstanding set. Rejected items remain as guardrails rather than work
requests.

## Outstanding Vision Summary

| Vision | Classification | Current reality | Missing closure |
|---|---|---|---|
| Layout Engine as sole layout truth | A — Long-term Vision | Renderer contracts are stable, but renderer-owned layout calculations remain | Specification-backed Layout Engine adoption and deletion of duplicate renderer layout ownership |
| First-class RAW workflow | B — Foundation Exists | RAW route, decode, output policy, and resource admission exist | True RAW/ProRAW/DNG provider intake, generated-output readback, metadata, memory, and device evidence |
| Adverse-lifecycle workflow reliability | B — Foundation Exists | Persistent queue, recovery, history, and Share handoff exist | Abnormal termination and repeated-session proof without unrecoverable jobs |
| Repeatable release certification | C — Production Evidence | Dual-device Share and mixed-media closures exist | A durable certification matrix repeatable for each release candidate |
| Performance and resource evidence | C — Production Evidence | Route, admission, duration, and stage diagnostics exist | Instruments, peak-memory, main-thread, long-duration, and heavy-media closure |

## Category A — Long-term Vision

### 1. Layout Engine as the Sole Layout Truth

**Current state:** Partially implemented architecture.  
**Volume III assessment:** Renderer and Layout are `PARTIAL`.

#### Vision

MemoMark's presentation pipeline should resolve meaning and layout before
Renderer draws:

```text
Metadata and Memory Results
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

Layout Engine should own:

- canvas and grid;
- semantic slot placement;
- spacing and padding;
- typography placement;
- adaptive rules;
- optical compensation.

Renderer should consume resolved layout output rather than choose layout
variants or introduce new constants locally.

#### Current Reality

- semantic content, expressions, and region models exist;
- renderer input and domain dependencies are controlled;
- Media Geometry has one independent owner;
- renderer and export output are well tested;
- `ClassicWhiteRenderer` and renderer constants still contain card layout,
  orientation, spacing, dimension, and adaptive presentation calculations.

#### Why This Remains Vision

Media Geometry and card layout are different domains. Completing Media
Geometry did not complete Layout Engine. If renderer-owned layout calculations
remain permanent, MemoMark does not fully realize its declared
specification-first architecture.

#### Closure Evidence

This vision closes only when:

- a measured Layout Specification exists for the adopted slice;
- Layout Engine produces the authoritative resolved layout;
- Renderer consumes that output read-only;
- duplicate layout calculations are removed from the migrated renderer path;
- renderer tests assert Layout Engine contracts;
- preview and export fidelity remain verified.

This is not authorization for an immediate renderer rewrite. Any adoption
requires a scoped V3 requirement and verification plan.

#### References

- [`PROJECT_CONSTITUTION.md`](../../PROJECT_CONSTITUTION.md)
- [`Docs/MASTER_PLAN.md`](../MASTER_PLAN.md)
- [`Docs/05_Renderer/README.md`](../05_Renderer/README.md)
- [`ClassicWhiteRenderer.swift`](../../Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift)

## Category B — Foundation Exists

### 2. First-Class RAW Workflow

**Current state:** Foundation and policies exist; provider-to-output proof is
incomplete.  
**Volume III assessment:** Media Platform is `PARTIAL`.

#### Vision

RAW/ProRAW/DNG should be treated as a first-class input workflow rather than a
filename extension that happens to decode.

The current product policy intentionally generates a normal still-image output
from RAW-family input. First-class does not mean modifying or re-exporting the
original RAW asset. It means that MemoMark can identify, decode, process,
describe, render, export, and save its generated result with reliability
equivalent to supported still and Live Photo workflows.

#### Current Reality

- RAW-family content types and filename fallbacks are recognized;
- `.rawStillImage` routing exists;
- RAW display-image generation exists;
- metadata and output policies describe generated still output;
- high-memory admission and single-lane resource policy exist;
- focused route, decode, policy, and admission tests exist;
- signed Apple Photos library runs supplied `8064×4536` JPEG proxies, not true
  RAW/DNG representations.

#### Missing Closure

- true RAW/ProRAW/DNG provider intake on signed devices;
- source identity and type evidence from the provider boundary;
- decode and generated-output readback evidence;
- capture time, orientation, location, and supported metadata behavior;
- multi-RAW memory pressure and resource release;
- save-back and user-visible output validation.

#### Closure Evidence

The workflow closes when at least one controlled true RAW-family input crosses
the complete production lifecycle with machine-readable route, admission,
duration, metadata, output, save, and resource evidence, followed by a
repeatable heavy-media validation appropriate to release claims.

#### References

- [`High-Resolution Media Intake Foundation`](../02_Architecture/High_Resolution_Media_Intake_Foundation_2026-07-05.md)
- [`MediaDecodeService.swift`](../../Source/PhotoMemo/PhotoMemo/Models/MediaDecodeService.swift)
- [`MediaProcessingRouter.swift`](../../Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaProcessingRouter.swift)
- [`MediaOutputPolicy.swift`](../../Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaOutputPolicy.swift)

### 3. Adverse-Lifecycle Workflow Reliability

**Current state:** Recovery architecture exists; normal and several restart
paths are verified.

#### Vision

No accepted Memory Workflow job should silently disappear or become
unrecoverable because the Share Extension, main app, or operating system
interrupts execution.

This is a reliability ambition, not a proposal for another queue architecture.

#### Current Reality

- external intake requests are persisted;
- queue jobs and tasks are persisted;
- restart recovery and terminal history exist;
- corrupted and missing persistence states are distinguished;
- failed writes surface typed errors;
- Share drain and exact configuration recovery have regression coverage;
- signed mixed Share jobs have completed on two devices.

Queue Recovery therefore exists. The outstanding vision is stronger evidence
under adverse lifecycle conditions, not implementation of recovery from zero.

#### Missing Closure

- extension termination during multi-item intake;
- main-app termination during queue execution;
- background interruption and later continuation;
- repeated or overlapping Share sessions without ownership ambiguity;
- persistence failure at intake-clear or queue-flush boundaries;
- proof that recovery does not duplicate, lose, or silently reconfigure tasks.

#### Closure Evidence

A repeatable interruption matrix should demonstrate, for each supported
boundary, whether the job resumes, fails explicitly, or requires a documented
user retry. No scenario may end in an unobservable or unrecoverable state.

#### References

- [`BatchQueueRecoveryTests.swift`](../../Tests/PhotoMemoTests/BatchTests/BatchQueueRecoveryTests.swift)
- [`ExternalPhotoIntakeStoreDiagnosticsTests.swift`](../../Tests/PhotoMemoTests/BatchTests/ExternalPhotoIntakeStoreDiagnosticsTests.swift)
- [`ShareDrainMigrationRegressionTests.swift`](../../Tests/PhotoMemoTests/ArchitectureTests/ShareDrainMigrationRegressionTests.swift)

## Category C — Production Evidence

### 4. Repeatable Production Certification

**Current state:** Strong V3 evidence exists, but certification remains a
release discipline rather than a single completed event.

#### Vision

MemoMark should be able to state production readiness through a repeatable,
versioned certification process instead of relying on a one-time successful
device session.

#### Current Reality

- Production Audit v1.0 and v2.0 exist;
- V3 evidence scenarios and machine-readable gates exist;
- signed builds have been installed and launched on multiple devices;
- JPEG, Live Photo, and 20-item mixed Share scenarios passed on two devices;
- configuration identity, semantic health, orientation, playback, save-back,
  duration, and crash evidence were inspected;
- current evidence still contains capability-specific gaps such as true RAW.

#### Missing Closure

- one canonical certification matrix tied to a release candidate;
- explicit required, conditional, and unsupported capability claims;
- repeatable signed-device evidence collection;
- traceable build, commit, configuration, device, scenario, and result identity;
- a clear rule for when prior evidence remains valid and when it must be rerun.

#### Closure Evidence

Volume VI should eventually own the certification contract. A release passes
only when every required scenario has current evidence or an explicit,
user-visible limitation accepted by the release decision.

#### References

- [`Production Audit v2.0 Final`](../07_Releases/MemoMark_Production_Audit_v2_0_Final_2026-07-10.md)
- [`V3 Device Installation Evidence`](../07_Releases/2026-07-13-V3-Device-Installation-Evidence.md)
- [`Docs/CURRENT_STATUS.md`](../CURRENT_STATUS.md)

### 5. Performance, Memory, and Resource Evidence

**Current state:** Diagnostics foundations exist; production envelope evidence
is incomplete.

#### Vision

MemoMark should know the operational limits of its supported workflow instead
of inferring safety from successful completion alone.

#### Current Reality

- route, media cost, memory tier, and admission evidence exist;
- high-memory inputs use conservative single-lane policy;
- per-task total and stage duration are recorded;
- 20-item heavy mixed scenarios completed on two devices;
- evidence retention supports full mixed-job analysis;
- current repository records still identify Instruments, main-thread, peak
  memory, multi-48MP, and true RAW evidence as incomplete.

#### Missing Closure

- Instruments traces for representative supported scenarios;
- peak-memory and resource-release evidence;
- main-thread work classification;
- long-duration and repeated-job behavior;
- multi-high-resolution and true RAW pressure testing;
- practical latency and throughput envelopes per supported device class.

#### Closure Evidence

Evidence should define an operational envelope and release gates, not merely
collect more logs. A metric belongs only when it can change admission policy,
implementation, capability claims, or release decisions.

#### References

- [`PhotoMemoShareDiagnostics.swift`](../../Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareDiagnostics.swift)
- [`LivePhotoBatchQueueExecutionTests.swift`](../../Tests/PhotoMemoTests/BatchTests/LivePhotoBatchQueueExecutionTests.swift)
- [`Production Audit Module 6`](../07_Releases/MemoMark_Production_Audit_v2_0_Module_6_Release_2026-07-10.md)

## Category D — Explicitly Rejected

Rejected directions are preserved here so that “unfinished vision” cannot be
used to reintroduce architecture MemoMark has intentionally excluded.

### Cloud Photo Processing

**Rejected because:** It violates Local First and user ownership of photos,
metadata, configurations, and memories.

### Original-Photo Mutation

**Rejected because:** MemoMark generates a new output image and preserves the
source photograph.

### Renderer-Owned Business Semantics

**Rejected because:** Renderer draws resolved presentation. It does not own
Memory calculations, provider resolution, fallback policy, or configuration
persistence.

### Renderer-Owned Media Geometry

**Rejected because:** Geometry belongs to media and is resolved into immutable
`CanonicalGeometry` before downstream consumption.

### Mutable Runtime Configuration as Production Truth

**Rejected because:** Production resolves one exact durable configuration
identity and revision, then freezes one complete snapshot.

### Share-Side Product Configuration

**Rejected because:** Share is an Apple Photos intake and handoff surface, not
a second Configuration Center.

### Parallel Share Production Architecture

**Rejected because:** Share persists and hands off work to the same production
contracts. It must not become a second renderer, queue, or media platform.

### Batch-First Dashboard Product

**Rejected because:** MemoMark is a local memory capability inside Apple
Photos. Workspace, Dashboard, Task Center, Processing Center, and photo-manager
concepts are not the product center.

### Feature-Driven Architecture Expansion

**Rejected because:** New capability must respect research, specification,
ownership, validation, and release boundaries. Feature quantity does not
justify duplicated truth or weakened foundations.

## Removal and Update Rules

Outstanding Vision should become smaller over time.

For each active item:

- **Completed:** record new implementation and evidence in Volume III or
  Volume VI, then remove it from the active summary.
- **Narrowed:** update the vision and explain what evidence changed its scope.
- **Abandoned:** move it to Explicitly Rejected and cite the superseding
  decision.
- **Unchanged:** do not rewrite it merely because a release occurred.

New entries require architectural evidence and the identity test defined in
this document. “Nice to have” is not sufficient.

## Conclusion

MemoMark's remaining vision is deliberately small:

- finish the ownership boundary between semantic presentation, Layout Engine,
  and Renderer;
- prove a true first-class RAW-family input workflow;
- demonstrate workflow recovery under adverse lifecycle conditions;
- turn current device evidence into repeatable production certification;
- define performance and resource limits through evidence.

These are not requests for continuous feature expansion. They are the
remaining conditions for MemoMark to fully realize the architecture and
production integrity it has already chosen.
