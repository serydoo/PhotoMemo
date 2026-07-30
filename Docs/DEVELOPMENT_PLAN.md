# MemoMark Development Plan

Status: Historical implementation-phase plan

Current stage: `V4 Expression Style System`. Current sequencing is owned by
`Docs/MASTER_PLAN.md` and
`Docs/01_Product/V4_Product_Stage_Kickoff_2026-07-30.md`.

## Phase 1

### Real Single-Photo Pipeline

- EXIF import
- anchor calculation
- preview rendering
- export to new image
- save to photo library

Status:

Completed as the foundation.

## Phase 2

### Template Calibration Center

- one persistent preview surface
- four custom text regions
- smart module insertion
- badge and output preferences

Status:

Established during V2/V3; ongoing changes are scoped polish only.

## Phase 3

### Background Intake And Queue

- external file intake
- frozen configuration snapshots
- queue state model
- background processing coordinator
- system notifications

Status:

Implemented as the current processing backbone.

## Phase 4

### Permission And Reliability Layer

- clear first-run permission guidance
- explicit photo-library access state
- explicit notification access state
- stable album refresh and save flows

Status:

Established during V3; remaining certification work is carried by the V4 Entry
Engineering Gate.

## Phase 5

### Render Fidelity And Metadata Hardening

- preview/export parity
- border metrics
- typography consistency
- metadata retention validation
- failed-task retry polish

Status:

Established as a V3 baseline; `TX-001` and `BP-001` remain explicit carryover.

## Phase 6

### iOS Readiness

- reduce macOS-only assumptions
- preserve architecture for future share-extension style intake
- prepare notification and background concepts for iOS equivalents

Status:

Realized during V2/V3. This label is historical.

## Working Rule

Do not expand feature surface faster than the real processing chain can support.
