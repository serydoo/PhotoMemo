# V1 Release Readiness Review

Date: 2026-07-03

Repository: `/Users/rui/Desktop/PhotoMemo`

Branch: `v1-checkpoint-20260702`

Checkpoint: `2218878d Checkpoint usable V1 device baseline`

Review type: Release Readiness Review, not a general code review

## Release Decision

Closure update:

The High findings in this review were closed later on 2026-07-03. The current
maintenance-baseline decision is recorded in:

- `Docs/02_Architecture/V1_High_Finding_Closure_Checklist_2026-07-03.md`
- `Docs/02_Architecture/Maintenance_Baseline_Freeze_2026-07-03.md`
- `Docs/CURRENT_STATUS.md`

Current decision:

```text
V1 Functional Baseline: accepted
V1 long-term Maintenance Baseline: not yet accepted
```

Interpretation:

- The checkpoint is suitable for continued V1 development, validation, and bug-fix work.
- The checkpoint should remain preserved as the current usable device baseline.
- It should not yet become the long-term maintenance baseline until the High findings are resolved or explicitly accepted as release risks.

Summary:

| Category | Count | Release Meaning |
| --- | ---: | --- |
| Functional release blockers | 0 | Current app can continue as the usable V1 checkpoint. |
| High findings | 2 | Must be resolved before long-term maintenance baseline. |
| Medium findings | 4 | Should be scheduled before V1.1 hardening or release cleanup. |
| Low findings | 0 | No standalone low finding carried into this baseline record. |
| Pass areas | 5 | Contract and core boundaries are stable enough to trust for next work. |

Recommendation:

```text
Use this checkpoint for continued V1 work.
Do not yet treat it as the durable maintenance baseline.
Resolve the subject-library recovery risk first.
Normalize the documentation baseline before the next architecture/RFC slice.
```

## Review Scope

This review used Contract + Runtime as the unit of review:

- Bootstrap Runtime
- Subject Library persistence
- V1 iOS root view state flow
- Photo Intake
- Render Pipeline
- Service / Repository / Coordinator boundaries
- MemoryEngine purity
- Intent layer size and responsibility
- Active documentation consistency

This review did not perform new code edits, renderer redesign, UI redesign, or V2 implementation work.

## Findings

### High 1: Corrupted subject library can be overwritten after add-subject re-enables persistence

Evidence:

- [V1SubjectFlowSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift:154)
- [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift:445)

Risk:

Bootstrap correctly disables subject-library writes when the library payload cannot decode, but `addDefaultSubject` forces subject-library persistence back on and immediately persists `session.state.subjects`. In a corrupt-library scenario, that can replace the unreadable user library with the fallback selected subject plus the newly created default subject.

Release meaning:

This is the only confirmed user-data-risk finding in this review. It should be treated as the first hardening task before declaring a long-term maintenance baseline.

Fix direction:

Keep `addDefaultSubject` under the disabled persistence gate when bootstrap detected a corrupt library. If the app should recover, make that a named recovery/reset path and preserve or back up the corrupt raw payload before first replacement.

### High 2: RFC-001 current-state claim conflicts with live repository status

Evidence:

- [RFC-001-Memory-Enters-the-Production-Pipeline.md](/Users/rui/Desktop/PhotoMemo/Docs/02_Architecture/RFC-001-Memory-Enters-the-Production-Pipeline.md:44)
- [CURRENT_STATUS.md](/Users/rui/Desktop/PhotoMemo/Docs/CURRENT_STATUS.md:108)

Risk:

RFC-001 marks Memory-in-production as achieved/completed/verified, while current status says the archive-line conclusion cannot yet be treated as revalidated fact for this live HEAD. Future agents or maintainers may incorrectly assume the production/export pipeline has already moved fully onto the Memory Engine path.

Release meaning:

This is a release-documentation problem, not a runtime code problem. It still blocks a durable maintenance baseline because it can misdirect future work.

Fix direction:

Keep RFC-001 as historical architecture memory, but add a top-level historical/superseded note pointing readers to the current live-repo status and this review.

### Medium 1: Bootstrap restore can still mark restored state as dirty

Evidence:

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:630)
- [V1BootstrapRuntimeCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1BootstrapRuntimeCoordinator.swift:115)

Risk:

Bootstrap sets `isApplyingBootstrapState`, applies restored state, then clears the flag. Several `onChange` handlers mark `activeConfigurationMessage = "有未保存修改"` unconditionally. `selectedSubject` has a guard, but `birthdayDate`, `logoMode`, `outputTarget`, `selectedExistingAlbumIdentifier`, and `newAlbumName` do not.

Release meaning:

This does not lose data or crash, but it weakens user trust in saved/restored configuration state.

Fix direction:

Do not add one-off bootstrap guards to every `onChange`. Centralize dirty marking behind a helper such as `markConfigurationDirty()` and make that helper ignore bootstrap/apply transactions.

### Medium 2: PhotosPicker staging files do not have a production cleanup policy

Evidence:

- [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift:40)
- [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift:240)
- [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift:278)

Risk:

The current picker path now correctly prefers file representation over loading every image as `Data`, but both file-copy and fallback-data paths stage files under `MemoMarkV1Picker`. The production path does not show a dedicated cleanup loop for those staged picker files.

Release meaning:

This is not an immediate correctness blocker, but it will matter for repeated HEIC/RAW-heavy device use.

Fix direction:

Track staged picker URLs and clean them after submit/failure, or run an age-based cleanup for `MemoMarkV1Picker` during startup/intake refresh.

### Medium 3: iOS exposes V1 and Configuration Center as separate root entries with separate sessions

Evidence:

- [PhotoMemoiOSTemporaryEntryView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift:72)
- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:35)
- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:7)

Risk:

The temporary iOS entry can switch between V1 and Configuration Center. Each root owns its own `ConfigurationSession`, and both can reach overlapping configuration concepts. If this is visible in a release build, users can enter two editing surfaces backed by different session owners.

Release meaning:

This is conditional. If the Configuration Center entry is debug-only or otherwise hidden from release users, it is not a release risk. If it is visible in the release build, it is a Medium release-readiness risk.

Fix direction:

Confirm release exposure. If visible, hide/debug-gate the non-release root entry or introduce one shared session/save path.

### Medium 4: Active docs still contain contradictory V1 verification status

Evidence:

- [CURRENT_STATUS.md](/Users/rui/Desktop/PhotoMemo/Docs/CURRENT_STATUS.md:38)
- [CURRENT_STATUS.md](/Users/rui/Desktop/PhotoMemo/Docs/CURRENT_STATUS.md:72)
- [HANDOFF.md](/Users/rui/Desktop/PhotoMemo/HANDOFF.md:21)
- [HANDOFF.md](/Users/rui/Desktop/PhotoMemo/HANDOFF.md:47)

Risk:

The newer contract baseline says the stale `V1DraftOrchestrationCoordinatorTests` failure is resolved, while older re-audit sections still list it as an active verification gap. A future maintainer may treat a resolved stale expectation as an active release blocker.

Release meaning:

This belongs under documentation consistency with High 2. It does not block the current functional checkpoint, but it should be cleaned before the maintenance baseline is frozen.

Fix direction:

Preserve historical order, but mark the older re-audit failure entries as superseded by the later contract-baseline rebuild.

## Pass Areas

### Render Contract

Status: Pass.

The V1 Render Contract convergence remains intact:

- `singleLineTemplateText` means Template Source.
- `resolvedSingleLineText` / `displayText` mean Display Text.
- V1 bridge builds `V1PreviewRenderModel`.
- Old `composeText`, `ComposeV1PreviewTextIntent`, and external `moduleValue` entry points did not reappear.

### Render Pipeline Boundary

Status: Pass with known size debt.

Renderers did not show reverse dependencies on album, share, notification, queue, or external intake concerns. Export consumes `RecordCard` and does not independently recompute Draft-layer strings.

Known debt:

`RecordCardExportService` is large and owns several responsibilities, including SwiftUI rendering, image artifact repair, metadata writeout, and temporary export file creation. That is a V1.1 maintainability item, not a current release blocker.

### Repository Boundary

Status: Pass.

Repositories primarily wrap services/stores and return `PhotoMemoResult`. No confirmed UI toast/alert/refresh ownership was found in repository code.

### MemoryEngine Boundary

Status: Pass.

`Source/PhotoMemo/PhotoMemo/MemoryEngine/*.swift` imports `Foundation` only. No SwiftUI, AppKit, UIKit, View, `@State`, binding, repository, or service dependency was found in MemoryEngine.

### Intent Layer

Status: Pass.

Intent files are still small enough to read as action descriptions and thin execution wrappers. No confirmed pattern of large business logic moving into Intent objects was found.

## Verification

Evidence available at review time:

- Current branch: `v1-checkpoint-20260702`
- Current checkpoint: `2218878d Checkpoint usable V1 device baseline`
- Worktree at review start: clean
- iPhone7 device build/install/launch had already succeeded and was accepted by user inspection
- Contract baseline tests had already passed:
  - `PreviewCompositionMigrationTests`
  - `V1PreviewSyncCoordinatorTests`
  - `V1DraftOrchestrationCoordinatorTests`
  - `ConfigurationCenterPreviewCompositionHelperTests`
- `PhotoMemoiOSV1` generic iOS Simulator build had already passed
- `git diff --check` had already passed before this review

Additional review support:

- Used code-review and MemoMark release/UI/render review skills.
- Used two completed read-only subagent reviews:
  - Subject / Bootstrap / persistence runtime
  - Docs / Architecture / MemoryEngine consistency
- A Render / Service subagent timed out and was closed; the main review still covered renderer, export, repository, intent, and batch execution paths directly.

## Baseline Rule Going Forward

Use this review as the V1 checkpoint record:

```text
Functional Baseline: 2218878d
Maintenance Baseline: pending High finding closure
```

Next recommended order:

1. Fix subject-library corrupt-payload recovery behavior.
2. Add historical/superseded banners to conflicting architecture docs.
3. Centralize V1 dirty-state marking.
4. Add PhotosPicker staging cleanup.
5. Confirm whether the Configuration Center root entry is release-visible.
6. Clean active status/handoff contradictions.
