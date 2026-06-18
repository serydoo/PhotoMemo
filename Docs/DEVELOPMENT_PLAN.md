# PhotoMemo Development Plan

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

In active refinement.

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

Current.

## Phase 5

### Render Fidelity And Metadata Hardening

- preview/export parity
- border metrics
- typography consistency
- metadata retention validation
- failed-task retry polish

Status:

Next.

## Phase 6

### iOS Readiness

- reduce macOS-only assumptions
- preserve architecture for future share-extension style intake
- prepare notification and background concepts for iOS equivalents

Status:

Future, but current code should not block it.

## Working Rule

Do not expand feature surface faster than the real processing chain can support.
