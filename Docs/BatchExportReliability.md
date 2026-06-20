# Batch Export Reliability

Last updated: 2026-06-20

## Scope

This document reviews reliability behavior in:

- `BatchProcessingCoordinator`
- `BatchQueueExecution`
- `PhotoLibraryExportService`
- related batch notification and task-state models

## Current Batch Flow

Per task, the execution path is:

1. import source photo
2. read metadata
3. build record card
4. render/export to a temporary file
5. save exported file into Photos
6. clean temporary file
7. mark final task result

## Reliability Findings

| Area | Current behavior | Reliability impact |
| --- | --- | --- |
| Task ordering | newest job is processed first; tasks inside a job keep source order | deterministic and easy to reason about |
| Execution model | processing loop is effectively serial | slower throughput, but lower concurrency risk |
| Progress phases | importing -> metadataReady -> previewReady -> exporting -> savingToPhotoLibrary -> completed | strong user-facing status granularity |
| Notification stages | queued, imported, rendering, saving, final | background status remains visible without main-UI coupling |
| Cancellation checks | checked after import, after export, and again before save | reduces risk of saving cancelled work into Photos |
| Temporary export cleanup | temp file removed on success, cancel-abort paths, and failures | strong local temp-file hygiene |
| Managed intake cleanup | only PhotoMemo-managed `ExternalIntake` files are cleaned | protects user originals |
| Retry semantics | retry allowed only when source still exists | avoids false retry promises |
| Per-job configuration | each job uses one captured `BatchConfigurationSnapshot` | stable output policy within a batch |

## Metadata Consistency In Batch

Batch export uses the same core services as single export:

- `PhotoImportService`
- `RecordCardBuildService`
- `RecordCardExportService`
- `PhotoLibraryExportService`

That is good for consistency because batch is not a second renderer/exporter implementation.

Current practical meaning:

- batch metadata preservation strengths and weaknesses are the same as single export
- batch does not introduce a separate metadata write policy

## Partial Failure Behavior

Current behavior is already thoughtful:

- failures are stored per task
- successful items still complete and save normally
- notifications use softer language when most items completed and only a few failed

This is a good product fit for large imports where one exception should not invalidate the full batch.

## Cleanup Behavior

Two cleanup layers are present:

1. exported temporary result cleanup
2. managed intake source cleanup

Important safety rule already preserved:

- PhotoMemo only cleans source files that it copied into its own `ExternalIntake` area
- it does not delete user original file paths

## Reliability Strengths

- deterministic ordering
- serial processing reduces race risk
- repeated cancellation guards
- clear failure capture
- safe temporary-file cleanup
- per-task Photos save result tracking through `savedAlbumName` and `savedAssetIdentifier`

## Reliability Limits

1. `BatchPipelinePolicy` exists in the model, but the current executor behaves serially.
2. No dedicated automated export-fixture tests exist yet.
3. Batch output is effectively JPEG-first because temporary export uses `.jpg`.

## Conclusion

The current batch system is conservative and reliability-oriented.

That is a reasonable tradeoff for PhotoMemo's present stage:

- correctness first
- deterministic behavior first
- background trust first

The main future opportunity is not more concurrency yet. It is stronger fixture-based verification of metadata preservation and Photos save-back behavior.
