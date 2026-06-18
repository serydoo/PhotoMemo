# Implementation Plan: MainView Preview Detail Refactor

## Overview
Continue the MainView decomposition by extracting the preview/detail display helpers into one focused SwiftUI file, while preserving `MainView` as the coordinator for state, bindings, and action routing.

## Architecture Decisions
- Keep `currentCard`, `selectedPhoto`, and other coordinator-owned state in `MainView`
- Extract only display-oriented preview helpers in this round
- Group preview/detail display views into one new `MainView+PreviewPanels.swift` file
- Keep preview-width calculation available to `MainView`, but scoped to preview concerns only

## Task List

### Phase 1: Spec And Structure
- [x] Task 1: Write a focused preview/detail refactor spec and plan
  - Acceptance: scope, assumptions, commands, and boundaries are documented in `Docs/`
  - Verify: open the docs and confirm the slice matches the current MainView direction
  - Files: `Docs/MAINVIEW_PREVIEW_DETAIL_REFACTOR_SPEC.md`, `Docs/MAINVIEW_PREVIEW_DETAIL_REFACTOR_PLAN.md`

- [x] Task 2: Extract preview/detail display helpers from `MainView`
  - Acceptance: detail preview composition, header, canvas shell, summary card, and status pill UI are moved into dedicated view structs
  - Verify: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`

### Checkpoint: After Phase 1
- [x] Project builds cleanly
- [x] `MainView.swift` line count continues downward

### Phase 2: Review And Handoff
- [x] Task 3: Review the extraction for behavior drift and scope discipline
  - Acceptance: no coordinator logic moved out, no preview behavior changed, no unrelated cleanup mixed in
  - Verify: inspect the diff and build result
  - Files: same as Task 2

- [x] Task 4: Update project state docs for the next session
  - Acceptance: repository status reflects the new preview/detail extraction slice and next likely targets
  - Verify: open updated status/handoff docs and confirm they describe the latest state accurately
  - Files: `Docs/CURRENT_STATUS.md`, `HANDOFF.md`

## Risks And Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Extracted preview views accidentally capture coordinator logic | High | Pass resolved values only and keep mutations in `MainView` |
| Preview layout changes subtly during extraction | Medium | Preserve the same spacing, card shell, and width rule |
| Refactor diff grows into unrelated cleanup | Medium | Limit edits to the preview/detail slice plus required status docs |

## Open Questions
- Should the next slice after preview/detail prioritize the remaining field-editor helpers, or stop for a manual UI regression pass first?
