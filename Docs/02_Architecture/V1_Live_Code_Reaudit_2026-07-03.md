MemoMark V1 Live Code Re-Audit

Date:
2026-07-03

Repository:
~/Desktop/PhotoMemo

Branch:
v1-checkpoint-20260702

Purpose:
Re-review the current live V1 codebase after the repository-line correction.
This document records current-state findings and optimization directions.

Method:
- Review current V1 source files and supporting tests
- Revalidate against the live repository only
- Keep Product Loop and Engineering Loop concerns separate

Verification:
- Focused V1 macOS test suite: one failing test remains
  - failing: `V1DraftOrchestrationCoordinatorTests.applyMutationUpdateBridgesStateAndReturnsDirtyPreviewDrafts()`
  - mismatch observed: `singleLineTemplateText` resolved to `记录{{memory_summary}}`, while the test expected the already-expanded display text
  - note: the same test passed when rerun in isolation, which suggests order-sensitive or flaky verification rather than a proven compile break
- `PhotoMemoiOSV1` generic iOS Simulator build: passed

Findings

1. High
V1 subject-library decode failure silently downgrades persistence to selected-subject-only mode.

Evidence:
- [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift:115) converts a subject-library decoding failure into `subjectLibraryReadFailure`.
- [V1BootstrapFlowSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1BootstrapFlowSupport.swift:130) turns that failure into `shouldSaveSubjectLibrary = false`.
- [V1SubjectFlowSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectFlowSupport.swift:16) then persists only the selected subject when that flag is false.

Risk:
- one bad payload can strand the user in a degraded single-subject mode
- the app keeps working, but there is no visible recovery path and no automatic library repair

Optimization direction:
- introduce an explicit degraded-bootstrap state for subject-library corruption
- surface recovery UI or auto-rebuild behavior instead of silently switching persistence mode
- add tests for corrupted subject-library payloads and the recovery path

2. High
Programmatic bootstrap and subject changes reuse the same dirty-state path as real user edits.

Evidence:
- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:630) marks the configuration dirty on every `birthdayDate` change.
- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:634) also reacts to `selectedSubject` changes by mutating `birthdayDate` and refreshing preview again.
- [V1BootstrapRuntimeCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1BootstrapRuntimeCoordinator.swift:73) applies bootstrap projection updates, including `birthdayDate`, through the same state pipeline.

Risk:
- bootstrap and subject switching can trigger duplicate preview refreshes
- non-user state restoration can be misclassified as unsaved user edits
- this behavior is fragile because correctness depends on event ordering inside SwiftUI

Optimization direction:
- separate user-edit dirtying from programmatic state restoration
- replace the current `onChange` fan-out with one explicit preview-effect policy coordinator
- add integration tests for bootstrap, subject switch, and active-anchor switch status outcomes

3. Medium
V1 preview is still a parallel presentation implementation, not the real renderer/export contract.

Evidence:
- [V1PreviewSection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSection.swift:4) renders a custom SwiftUI preview card.
- [V1IOSViewSupportComponents.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift:47) manually draws the compact information bar with renderer constants.
- [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift:391) builds a separate preview composition pipeline and local module-value resolver.

Risk:
- preview and export can drift because they do not share one rendering contract
- V1 keeps two semantic composition systems alive: preview-side and production-side

Optimization direction:
- move V1 preview toward a real render/export-backed surface, even if still cached or simplified
- reduce `V1PreviewCompositionEngine` to draft composition only, not a second presentation engine
- add one parity test that compares preview content assumptions with production card content

4. Medium
Product cleanup is incomplete: the home/overview summary still exposes `时间锚点数量`, and tests still enforce that legacy display.

Evidence:
- [V1IOSHomeProjection.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSHomeProjection.swift:4) still includes `anchorCountLabel`.
- [V1SubjectHomeSummarySupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectHomeSummarySupport.swift:9) still carries and displays that value.
- [V1IOSHomeProjectionTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1IOSHomeProjectionTests.swift:63) and [V1SubjectHomeSummaryPresenterTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/PhotoMemoTests/ArchitectureTests/V1SubjectHomeSummaryPresenterTests.swift:66) still lock the old behavior.

Risk:
- the live code no longer matches the product feedback artifact
- future UX cleanup will keep fighting stale test expectations

Optimization direction:
- remove `anchorCountLabel` from the V1 home/subject summary projection and view layer together
- update the tests and UX iteration document in the same slice

5. Medium
V1 quick-action photo intake creates a temporary picker file layer without a cleanup loop.

Evidence:
- [V1PhotoIntakeSupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PhotoIntakeSupport.swift:40) writes imported files into `temporaryDirectory/PhotoMemoV1Picker`.
- [ExternalPhotoIntakeCenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift:91) then forwards those URLs into the shared intake system.
- [ExternalPhotoIntakeStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift:136) only cleans managed intake URLs, not the V1 picker staging directory.

Risk:
- repeated in-app photo picking can accumulate temporary files outside the managed intake cleanup path
- this is low-visibility storage debt and easy to miss in manual testing

Optimization direction:
- either skip the extra V1 picker staging layer when the shared intake can safely manage the provider URL directly
- or add explicit cleanup for `MemoMarkV1Picker` after submission / failure
- add a regression test for temporary-file cleanup

6. Medium
V1 status semantics are still string-driven, which makes product state and engineering state easy to desynchronize.

Evidence:
- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:122) stores configuration status as free text.
- [V1DraftMutationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftMutationCoordinator.swift:223) hard-codes the dirty-state message.
- [V1ConfigurationApplySupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplySupport.swift:230) and [V1SubjectHomeSummarySupport.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SubjectHomeSummarySupport.swift:65) branch on message strings to derive UI meaning.

Risk:
- display tone, persistence state, and action readiness are coupled to text copy
- copy changes can accidentally change behavior

Optimization direction:
- replace status strings with a small typed V1 configuration status model
- derive display copy from that status model at the presentation layer only

Recommended Optimization Order

Phase 1: Correctness and state safety
- Fix the subject-library degraded-mode path
- Split bootstrap/programmatic refresh from user dirty-state transitions
- Add targeted regression tests for library corruption and bootstrap status behavior

Phase 2: Product cleanup consistency
- Remove `时间锚点数量` from the live V1 home/summary flow
- Align tests and `V1_UX_Feedback_Iteration_001.md`
- Convert string-based status branching into a typed status model

Phase 3: Preview and intake hardening
- Add cleanup for `MemoMarkV1Picker` temporary files
- Collapse duplicate preview semantics toward one renderer-backed contract
- Re-audit remaining large V1 files after the state-flow fixes land

Largest Remaining V1 Files

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:1) about 2022 lines
- [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift:391) about 662 lines
- [V1IOSViewSupportComponents.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift:1) about 615 lines

Conclusion

The current live V1 repository is buildable, but its focused V1 verification surface is not fully green and it still carries several real maintenance risks:
- silent subject-library degradation
- bootstrap/user-edit state conflation
- preview/export drift
- incomplete UX cleanup
- temporary-file leakage risk

The next V1 improvement round should prioritize correctness and state ownership first, then product cleanup, then preview/intake hardening.
