# Implementation Plan: MainView Permission And Content Refinement

## Overview
Land the highest-confidence usability fixes from the latest MemoMark feedback while keeping the larger multi-config redesign out of this slice.

## Architecture Decisions
- Keep permission-status resolution in `PermissionCenter`, but make the UI and alert flow honest about denied-state recovery
- Keep age-formatting rules in `AnchorEngine`
- Keep custom description persistence in `SettingsService`, but reinterpret the current toggle as a custom-input mode instead of a full on/off export-description switch
- Defer the three-config selector and operation-guide system to a later dedicated feature slice

## Task List

### Phase 1: Spec And Scope
- [x] Task 1: Document the request and separate immediate fixes from deferred redesign work
  - Acceptance: the repo contains a spec and plan for this slice
  - Verify: open both docs and confirm the scope matches the current user request
  - Files: `Docs/MAINVIEW_PERMISSION_AND_CONTENT_REFINEMENT_SPEC.md`, `Docs/MAINVIEW_PERMISSION_AND_CONTENT_REFINEMENT_PLAN.md`

### Phase 2: Immediate Fixes
- [x] Task 2: Fix the photo-library permission recovery UX
  - Acceptance: denied permission no longer behaves like a retryable prompt; the next action leads the user toward System Settings with clearer messaging
  - Verify: build succeeds and code review confirms the denied path is explicit
  - Files: `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`

- [x] Task 3: Improve under-one-year age wording
  - Acceptance: age-like smart output omits `0岁` while preserving the remaining month/day precision
  - Verify: build succeeds and logic review confirms the under-one branch
  - Files: `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`

- [x] Task 4: Simplify the `补充信息` section into one card with custom-description mode
  - Acceptance: the section uses one card, one checkbox, and default fallback-to-right-bottom behavior when custom input is not enabled
  - Verify: build succeeds and code review confirms the fallback logic
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`, `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`, `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`

### Checkpoint: Immediate Slice
- [x] Project builds cleanly
- [x] The three targeted behaviors are aligned with the latest feedback

### Phase 3: Defer And Handoff
- [x] Task 5: Record what remains for the future three-config/help redesign
  - Acceptance: the final status message clearly separates what was implemented from what still needs a broader redesign slice
  - Verify: summary/report calls out deferred work explicitly
  - Files: final response, optionally project status docs if needed

## Risks And Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Reinterpreting the description toggle could accidentally stop metadata description writing | High | Keep fallback generation in `RecordCardBuildService` explicit and review all call sites |
| Permission UX could still feel broken if denied-state messaging is vague | Medium | Make denied actions open settings directly and update alerts accordingly |
| Multi-config expectations bleed into this slice | High | Treat them as deferred architectural work, not opportunistic UI shuffling |

## Open Questions
- Should the future three-config UI store named user presets or fixed slot numbers first?
- Should the operation guide be dismissible per section, per session, or permanently via local settings?
