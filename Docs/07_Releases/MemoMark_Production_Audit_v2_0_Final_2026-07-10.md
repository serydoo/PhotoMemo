# MemoMark Production Audit v2.0 Final

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

Related reports:

- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Plan_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_1_Architecture_Dependency_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_2_State_Repository_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_3_Memory_Expression_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_4_Media_Pipeline_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_5_SwiftUI_2026-07-10.md`
- `Docs/07_Releases/MemoMark_Production_Audit_v2_0_Module_6_Release_2026-07-10.md`

## Executive Summary

MemoMark is no longer an MVP-level codebase. It has a real local-first
workflow, a meaningful Configuration Center, a production-shaped metadata and
export pipeline, a first Memory Engine integration path, and a main-app picker
Live Photo release candidate.

The main risk has shifted from feature absence to engineering consistency:

- configuration state must persist deterministically
- capture-time truth must not be synthesized from processing time
- media capability claims must match actual intake paths
- heavy processing must stop leaning on MainActor as the product scales
- SwiftUI root state must keep shrinking toward a coordinator shell

No confirmed P0 was found. The correct release decision is **Conditional Yes**
for a controlled TestFlight validation candidate, not broad production
readiness and not a claim that TestFlight distribution has already completed.

## Final Ratings

| Dimension | Rating | Notes |
|---|---|---|
| Product Architecture | A- | Local-first Apple Photos boundary is strong and coherent. |
| Engineering Quality | B+ | Core seams exist; orchestration files and persistence contracts need hardening. |
| Release Readiness | B- | Suitable for limited TestFlight, not broad media/performance claims. |
| Maintainability | B+ | Good direction, but root view, export, queue, and share intake are too large. |
| Extensibility | B | IA-003 path is good; media capabilities and provider APIs need stronger contracts. |
| Performance | C+ | Small flows are acceptable; 48MP and large batch need measured limits. |
| Concurrency | C | MainActor overuse is the clearest scaling risk. |
| Technical Debt | B- | Debt is visible and reducible; not a rewrite situation. |

Overall readiness score: **82 / 100**

TestFlight decision: **Conditional Yes for validation candidate**

## Critical Issues

Confirmed P0: **0**

Conditional P0: **1**

- Do not claim Share Extension Live Photo support. If release materials say
  Share Extension Live Photo is supported, that becomes release-blocking because
  the reviewed path does not preserve a usable PhotoKit identity or paired
  resources.

## Major Issues

P1 count: **17**

The highest-priority P1 items are:

1. Preset deletion is not durably persisted.
2. Anchor maintenance can auto-open an edit sheet on entry.
3. Capture-time fallbacks can use `Date()` and create false memory time.
4. MainActor overuse concentrates heavy processing and UI state on one actor.
5. 48MP memory risk is modeled but not enforced by runtime admission/scheduling.
6. Live Photo runtime gate naming does not match release governance.
7. Share Extension intake lacks an explicit count cap.
8. Settings/TestFlight Live Photo wording conflicts with actual scope.

## Release Conditions For Current Candidate

These should be fixed or explicitly accepted before external TestFlight:

- Fix or re-verify preset deletion persistence. Current source evidence still
  shows delete paths marking state dirty without guaranteed subject-library
  persistence.
- Fix or re-verify anchor maintenance auto-edit sheet behavior. Current source
  evidence still shows draft loading setting `editingTimeAnchorID`.
- Align Live Photo wording: main-app picker release candidate only; Share
  Extension Live Photo is a known limitation.
- Add or document Share Extension intake limits if Share Extension is part of
  the validation plan.
- Complete a real signed distribution chain before saying "TestFlight shipped":
  archive, export/upload, App Store Connect processing, TestFlight install, and
  launch smoke.
- Re-run focused build/test/archive verification after any code changes.

## Architecture Debt

### A1: Configuration state has two writable truths

`V1SubjectLibraryRecord` is close to the real V1 aggregate, but legacy selected
subject state remains writable. Long-term direction: make subject library the
aggregate source and emit legacy keys as compatibility output.

### A2: Root SwiftUI surface is too large

`PhotoMemoiOSV1View` remains production UI, runtime orchestrator, configuration
coordinator, sheet router, preview host, and photo picker owner. Long-term
direction: compress it into a coordinator shell.

### A3: Media policy is split between old export and VNext

Static export and Live Photo still composition do not fully share metadata
policy. Long-term direction: one metadata writer/policy path for still and Live
Photo still resources.

Current implementation note:

This should be treated as a future hardening item unless a small release patch
is explicitly scoped. It should not become an unplanned renderer/export rewrite
inside the current IA-003 boundary.

### A4: Memory Engine still has compatibility adapters in the hot path

`CardVariableProvider` merges old anchor results, new memory results, metadata,
and export descriptions. Long-term direction: provider registry and field-based
MemoryBlock resolver.

### A5: Processing pipeline lacks a bounded actor model

Batch queue, render/export, PhotoKit write, and Live Photo work still lean on
MainActor. Long-term direction: processing actor with bounded import/render/write
lanes and MainActor-only status publication.

## Evolution Review

MemoMark can evolve toward Video, HDR, RAW, Spatial Photo, AI Summary, and sync,
but not by adding those features directly to the current V1 glue.

Required evolution gates:

- Video/HDR/RAW/Spatial Photo require first-class `MediaAssetCapabilities`.
- AI Summary must be an optional local-first Expression Provider, not part of
  deterministic Memory Engine core.
- Sync requires repository write receipts, versioned records, and conflict
  semantics.
- Layout evolution must continue through Research -> Specification -> Layout
  Engine -> Renderer, not renderer-side constants.
- Renderer/Layout Engine changes are not immediate release work under the V2
  Reset rules. They remain post-specification architecture work unless a
  specific IA-003 boundary is reached.

## API Design Review

Strong APIs:

- `V1ConfigurationApplyRequest` as an aggregate apply request
- `ProductionMemoryResolver` as a clear production memory boundary
- Live Photo load/write protocols
- Photo Library export service protocol

Weak APIs:

- persistence save APIs return too little status
- `MediaProcessingRoute` lacks identity/capability semantics
- Expression Provider API lacks common value resolution
- root SwiftUI view still constructs too much application request state

## Dependency Review

Healthy:

- Renderer does not directly read Repository/UserDefaults/Photo Library state.
- Memory Engine does not import UI or Renderer.
- AppEnvironment provides a real composition root.

Needs hardening:

- App Group fallback can hide Share Extension handoff failure.
- macOS AppDelegate singleton intake bypasses runtime-owned intake.
- iOS root contract test does not match current root.
- Queue store and execution are tightly coupled.

## Testability Review

Strong coverage exists for:

- configuration lifecycle basics
- request building
- MemoryResult contracts
- metadata parsing
- Live Photo routing and pairing
- writer and metadata policy contracts

Missing high-value tests:

- preset delete -> reload -> preset remains deleted
- anchor maintenance entry does not open edit sheet
- missing capture date does not synthesize `Date()`
- static HEIC non-ASCII metadata parity
- stale Live Photo pairing metadata removal from static export
- 48MP end-to-end memory envelope
- Share Extension intake cap and large-provider behavior
- real-device/TestFlight Share Extension handoff smoke

## Technical Debt Backlog

### P0

- None confirmed.
- Conditional: remove/avoid any release claim that Share Extension Live Photo is
  supported.

### P1

- Persist preset deletion immediately and add reload regression coverage.
- Fix anchor maintenance auto-edit sheet.
- Remove `Date()` capture/reference fallbacks from production memory truth.
- Align Live Photo release wording and runtime gate naming.
- Add Share Extension intake admission limit.
- Start moving heavy render/export/Live Photo processing off MainActor or prove
  current behavior with Instruments.
- Align static export metadata policy with VNext.

### P2

- Return save receipts/errors from configuration persistence.
- Create provider value-resolution API.
- Add deterministic MemoryResult identity.
- Add shared thumbnail/avatar/logo cache.
- Replace eager task history rows with lazy/cached rendering if history grows.
- Add processing actor and bounded lanes.
- Make memory budget drive runtime scheduling.
- Add media capabilities for HDR/RAW/video/spatial.

## Recommended Fix Order

1. Configuration reliability: preset deletion persistence and reload test.
2. SwiftUI user-visible issue: anchor maintenance should not auto-open edit.
3. Release truth: Live Photo wording, Share Extension limitation, runtime gate
   naming.
4. Capture-time truth: remove `Date()` from memory semantics.
5. Distribution truth: real signed TestFlight upload/install smoke.
6. Intake safety: Share Extension count cap and App Group handoff diagnostic.
7. Media metadata parity: stale Live metadata removal and static HEIC non-ASCII
   handling, only as scoped hardening rather than broad export redesign.
8. Performance envelope: 48MP memory measurement and MainActor reduction plan.

## Final TestFlight Decision

**Conditional Yes for a controlled validation candidate.**

Recommended TestFlight scope:

- still-image flow
- small-batch processing
- main-app picker Live Photo release candidate
- configuration center smoke around subjects, presets, anchors, output, and
  album behavior

Required validation before claiming TestFlight shipped:

- signed archive/export/upload succeeds
- App Store Connect processing completes
- TestFlight install succeeds on device
- launch smoke passes
- main-app picker still and Live Photo RC smoke pass
- Share Extension handoff is either verified on the signed build or explicitly
  scoped out

Explicitly not ready to claim:

- TestFlight has already shipped or build processing has completed
- Share Extension Live Photo
- robust 48MP processing
- 100-batch reliability
- HDR/RAW preservation
- video or Spatial Photo support
- fully production-grade Memory Engine

## Closing Assessment

MemoMark is on the right architecture path. The project should not be rewritten.
The right next move is a short hardening sprint focused on persistence,
capture-time truth, release wording, and intake limits, followed by another
focused verification pass.

If those items close, MemoMark can reasonably move from limited TestFlight
candidate toward a stronger public beta baseline.
