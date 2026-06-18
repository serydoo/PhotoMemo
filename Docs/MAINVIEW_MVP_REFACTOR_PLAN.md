# Implementation Plan: MainView MVP Refactor Round 2

## Overview
Continue reducing `MainView.swift` by extracting the remaining high-density template calibration panels into focused SwiftUI views, while preserving MainView as the state and action coordinator for PhotoMemo's current MVP.

## Architecture Decisions
- Keep bindings, persistence, and mutation logic in `MainView`
- Extract only display-oriented editor panels in this round
- Group related template-calibration panels into one new `MainView+TemplatePanels.swift` file

## Task List

### Phase 1: Spec And Structural Slice
- [x] Task 1: Write a focused refactor spec and plan for this round
  - Acceptance: refactor scope, commands, boundaries, and success criteria are documented in `Docs/`
  - Verify: open the docs and confirm the scope matches current MVP direction
  - Files: `Docs/MAINVIEW_MVP_REFACTOR_SPEC.md`, `Docs/MAINVIEW_MVP_REFACTOR_PLAN.md`

- [x] Task 2: Extract template calibration panels from `MainView`
  - Acceptance: template section, custom content section, badge section, and template rename sheet are moved to dedicated view structs
  - Verify: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`

### Checkpoint: After Phase 1
- [x] Project builds cleanly
- [x] `MainView.swift` line count continues downward

### Phase 2: Review And Next-Slice Readiness
- [x] Task 3: Review the extraction for correctness and scope discipline
  - Acceptance: no behavior drift, no accidental abstraction bloat, no unrelated cleanup
  - Verify: review changed files and build result
  - Files: same as Task 2

## Risks and Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Extracted view needs private MainView-only helpers | Medium | Pass concrete values and closures instead of moving logic |
| Bindings become harder to follow | Medium | Keep naming aligned with MainView computed bindings |
| Refactor drifts into feature changes | High | Limit this slice to structure only |

## Open Questions
- After this slice, should the next extraction prioritize the photo/anchor setup path or the preview/detail path?
