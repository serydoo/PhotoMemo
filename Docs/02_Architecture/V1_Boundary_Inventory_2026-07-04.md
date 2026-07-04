# V1 Boundary Inventory

Date: 2026-07-04

Repository: `/Users/rui/Desktop/PhotoMemo`

Branch: `v1-checkpoint-20260702`

Latest source branch: `v1-checkpoint-20260702`

Boundary hardening code checkpoint: `5f583093`

## Purpose

This inventory records which V1 boundaries are frozen and which still need
review. It is not a new architecture design and does not reopen frozen
contracts.

Use it to avoid re-reviewing boundaries that have already been locked, and to
focus future release-readiness work on the remaining high-value paths.

## Inventory

| Boundary | Status | Current Contract |
| --- | --- | --- |
| SubjectFlow | Frozen | State and one-shot events are separated. `V1SubjectFlowPatch.events` carries commands such as `reopenSubjectLibraryPersistence`; ordinary false booleans must not encode event semantics. |
| SharedContainer | Frozen | Directory creation failures are surfaced through throwing `ensureDirectory(at:)` and normalized as `SharedContainerError`. Call sites must handle the throwing contract. |
| BatchQueue Persistence | Frozen | Encoding and persistence are separated through `BatchQueuePersistenceBackend`. Queue writes return `PhotoMemoResult<Void>` and report encode/save failures. |
| Subject Library Corrupt Protection | Frozen | Corrupt bootstrap disables implicit library persistence. Ordinary edits do not re-enable writes. Explicit recovery/reset is required. |
| Render Contract | Frozen | `singleLineTemplateText` is Template Source; `resolvedSingleLineText` / render-model display text is Display Text. |
| Metadata Pipeline | Review Pending | Confirm no duplicated EXIF parsing or metadata-source drift across intake, build, render, and export paths. |
| Photo Intake | Review Pending | Confirm Share / picker / managed-copy paths share one intake contract and cannot bypass diagnostics or queue rules. |
| Render Pipeline | Review Pending | Confirm `Metadata -> Variables -> Renderer -> Export` remains single-direction and renderer stays pure. |
| Export Pipeline | Review Pending | Confirm metadata preservation, HEIC/RAW/Live Photo handling, and error propagation have no silent-failure paths. |
| Preview State | Review Pending | Confirm preview state consumes render/display contracts without parallel business-string recomputation. |

## Next Review Focus

1. Photo Intake boundary.
2. Render Pipeline boundary.
3. Export Pipeline boundary.

These are the remaining V1 release-candidate gates. Frozen boundaries should
only be revisited if new evidence shows the contract is broken.
