# MemoMark Production Audit v2.0 Module 2

Module: State & Repository Audit

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Scope

This module reviews:

- SwiftUI and Configuration Center state ownership
- Repository source-of-truth rules
- `ConfigurationSession`, `SettingsService`, `SettingsRepository`, and
  `ConfigurationCoordinator`
- V1 subject library persistence
- selected subject / selected preset identity
- persistence consistency and reload behavior

No files were modified during this module review.

## Executive Assessment

Rating: **B- / C+ boundary**

MemoMark has a workable V1 configuration model, and recent fixes correctly
started carrying `memoryPresets` and `selectedMemoryPresetID` through the apply
path. The remaining risk is not general architecture collapse. The risk is
persistence consistency: several write paths still depend on caller discipline,
and some user-visible edits can remain in memory without being durably saved.

The current shape is shippable for a narrow TestFlight candidate, but it should
not be described as fully production-grade configuration reliability until the
preset deletion persistence path is fixed and tested.

## Evidence

- `SettingsService` persists both legacy selected subject and the V1 subject
  library:
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:232`
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:413`
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:446`
- `V1SubjectLibraryRecord` aggregates `subjects`, `selectedSubjectID`,
  `memoryPresets`, and `selectedMemoryPresetID`:
  - `Source/PhotoMemo/PhotoMemo/Models/V1SubjectLibraryRecord.swift:8`
- `ConfigurationSession` owns in-memory subject and preset lifecycle:
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:253`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:533`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:615`
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:1063`
- Batch configuration snapshot resolution prefers subject library state over
  legacy selected subject fallback:
  - `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift:328`
- V1 apply path now carries subject library and presets:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplySupport.swift:57`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1926`
- `ConfigurationCoordinator.saveV1Configuration` performs multi-step writes:
  - `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:107`
  - `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:141`
  - `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:145`
  - `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:187`

## Ratings

| Dimension | Rating | Rationale |
|---|---|---|
| State Source Clarity | B- | Main sources are visible, but UI/session/repository still share responsibility. |
| Repository Source Of Truth | C+ | V1 subject library is close to the aggregate, but legacy selected subject remains writable. |
| Persistence Consistency | C | Some operations mutate memory first and rely on later saves. |
| IA-003 Alignment | B | Snapshot direction is correct and compatible with Memory Engine integration. |
| Testability | B- | Good lifecycle tests exist, but delete/reload persistence coverage is missing. |
| Release Risk | Medium | User-visible reset/reappearance behavior is still possible. |

## P0 Findings

No P0 findings.

No evidence was found of original-photo mutation, network upload, or an
unrecoverable configuration data-loss path.

## P1 Findings

### P1-01: Preset deletion is not durably persisted

Evidence:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift:615`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1028`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1312`

Impact:

`ConfigurationSession.deleteSelectedMemoryPreset()` removes the selected preset
from memory. The Home and Configuration Center delete handlers then mark state
dirty and rebuild drafts, but they do not guarantee a subject-library save.
After app restart, a deleted preset can reappear unless another save path runs.

Immediate fix?

Yes. This should be fixed before claiming configuration reliability in
TestFlight, because it maps directly to the earlier user report that deleted or
renamed configuration state can appear to reset.

Recommendation:

Persist the subject library immediately after preset deletion from both Home and
Configuration Center paths, then add a reload regression test.

### P1-02: Subject/library dual-write can leave stale production state

Evidence:

- `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:141`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:145`
- `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:461`
- `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift:332`

Impact:

The save path writes legacy selected subject state and subject library state in
separate steps. The batch snapshot provider later prefers subject-library state.
If one write silently fails or a caller bypasses the coordinator, UI and
processing can disagree about the active subject/preset.

Immediate fix?

Recommended for the next hardening slice. It does not block a narrow internal
smoke build if release notes avoid broad reliability claims.

Recommendation:

Treat `V1SubjectLibraryRecord` as the V1 aggregate source and make legacy
selected-subject keys compatibility outputs, not independent truth.

## P2 Findings

### P2-01: Repository save APIs do not expose persistence failure

Evidence:

- `Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift:71`
- `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:461`
- `Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift:192`

Impact:

`saveV1SubjectLibrary` returns `Void`, and encoding failure can disappear inside
the settings layer. The UI cannot distinguish a successful save from a best
effort save.

Classification: near-term maintenance.

Recommendation:

Return a result, receipt, or typed failure from V1 subject-library writes and
surface that status to coordinator-level tests.

## Architecture Debt

- `V1SubjectLibraryRecord` is the closest V1 configuration aggregate, but the
  legacy selected subject path remains a second writable source.
- `ConfigurationSession` owns selection, preset lifecycle, preview text,
  presentation state, and snapshot creation.
- Repositories clarify dependency direction but still expose thin pass-through
  APIs instead of domain-level save semantics.

## Evolution Review

The IA-003 direction is positive. `BatchConfigurationSnapshot` is explicitly a
transport/compatibility DTO, while production semantics move into
`ConfigurationSnapshot` and embedded `MemorySubject`.

This supports the long-term Memory Engine target, but only if configuration
identity becomes deterministic and durably persisted before deeper IA-003
integration.

## API Design Review

`V1ConfigurationApplyRequest` is well-shaped as an aggregate request and now
carries presets correctly. The weaker API is persistence: save calls need
observable success/failure semantics.

## Dependency Review

`AppEnvironment` correctly wires one shared `SettingsService` into repositories,
queue, and intake. The risk is bypass behavior: `BatchQueueStore` and
`ExternalPhotoIntakeCenter` cache live default snapshots, so any write path that
does not go through `ConfigurationCoordinator.saveV1Configuration` can leave
processing state stale.

## Testability Review

Good coverage exists for request building and preset preservation on subject
switch:

- `Tests/PhotoMemoTests/ArchitectureTests/V1ConfigurationApplyRequestBuilderTests.swift:27`
- `Tests/PhotoMemoTests/ArchitectureTests/V1SubjectLibrarySupportTests.swift:311`
- `Tests/PhotoMemoTests/ArchitectureTests/ConfigurationSessionConfigurationLifecycleTests.swift:394`

Missing coverage:

- deleting a preset through the V1 UI/action path
- reloading bootstrap state from `photomemo.v1.subjectLibrary`
- confirming the deleted preset does not reappear

## Immediate Fixes

- Persist subject library immediately after preset deletion.
- Add a delete/reload regression test for V1 presets.
- Make `saveV1SubjectLibrary` return an observable result.

## Long-Term Optimization

- Promote `V1SubjectLibraryRecord` into the single V1 configuration aggregate.
- Move preset mutations into a small domain coordinator or repository.
- Add versioned migration/recovery behavior for subject-library records.

## Release Recommendation

Conditional Yes for TestFlight smoke.

Do not block release for a P0, because none was found. Do block any
"configuration reliability complete" claim until P1-01 is fixed or re-verified
against current HEAD and covered by reload regression tests.
