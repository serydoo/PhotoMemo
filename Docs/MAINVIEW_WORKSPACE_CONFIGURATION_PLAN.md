# Implementation Plan: MainView Workspace Configurations And Operation Guide

## Overview
Implement the deferred "three configurations plus right-side help" redesign in one cohesive slice, while keeping `MainView` as the coordinator for slot selection and state application.

## Architecture Decisions
- Store the three configuration slots in `SettingsService` as local persisted snapshots
- Keep slot application and migration logic in `MainView`
- Keep the new right-side controls in a dedicated extracted view file
- Use dismissible helper cards for noisy left-side guidance, and a guide sheet for fuller explanations

## Task List

### Phase 1: Spec And Structure
- [x] Task 1: Document the multi-config and guide redesign
  - Acceptance: the repo contains a dedicated spec and plan for this slice
  - Verify: open both docs and confirm they match the current user request
  - Files: `Docs/MAINVIEW_WORKSPACE_CONFIGURATION_SPEC.md`, `Docs/MAINVIEW_WORKSPACE_CONFIGURATION_PLAN.md`

### Phase 2: Configuration Slots
- [x] Task 2: Add persisted workspace-configuration slots to `SettingsService`
  - Acceptance: three fixed slots exist, each can store a full configuration snapshot, and the active slot ID persists locally
  - Verify: build succeeds and code review confirms the slot model is wired into settings persistence
  - Files: `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`

- [x] Task 3: Wire slot selection, save, restore-default, and legacy migration into `MainView`
  - Acceptance: choosing a slot applies its snapshot or default skeleton; saving writes the current state into the active slot; restoring default clears the active slot snapshot
  - Verify: build succeeds and code review confirms `MainView` remains the coordinator
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`

### Phase 3: Right-Side Controls And Guidance
- [x] Task 4: Add the right-side configuration control panel and operation guide
  - Acceptance: the old top-right save button is replaced by a right-side panel with three slot buttons, save action, restore-default action, and a guide menu
  - Verify: build succeeds and the panel appears in the detail area
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceControls.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`

- [x] Task 5: Convert key noisy section hints into dismissible cards
  - Acceptance: anchor, smart-module, and supplemental-content guidance can be dismissed locally while remaining available in the operation guide
  - Verify: build succeeds and the section views compile with the new helper cards
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`

### Phase 4: Naming And Formal Help Center
- [x] Task 6: Add custom naming for configuration slots
  - Acceptance: each slot can persist an optional custom display name, and renaming a slot does not rename the underlying template
  - Verify: build succeeds and the active slot rename sheet updates the right-side cards and summaries
  - Files: `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`, `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceControls.swift`

- [x] Task 7: Upgrade the guide sheet into a grouped help-center navigation
  - Acceptance: help topics are grouped by category, the menu entry is categorized, and the sheet presents sidebar navigation plus a detail pane
  - Verify: build succeeds and code review confirms topic routing still opens the requested section
  - Files: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceControls.swift`

### Checkpoint: Feature Slice
- [x] Project builds cleanly
- [x] The main UI has a real three-slot configuration flow plus right-side guide entry point
- [x] Slot naming and grouped help-center navigation are wired into the same MainView coordinator flow

## Risks And Mitigations
| Risk | Impact | Mitigation |
|------|--------|------------|
| Slot switching could desynchronize preview state and editor state | High | Apply snapshots through one `MainView` path and immediately resync composer items plus batch defaults |
| Multi-slot persistence could overwrite today's existing calibration unexpectedly | Medium | Migrate the current saved state into the active slot before the user starts switching |
| The right-side guide could become noisy | Medium | Keep it behind a menu-triggered sheet and make left-side hints dismissible |

## Open Questions
- Should section-hint dismissal eventually gain a single "show all tips again" reset?
- Should the help center later support screenshots or inline preview thumbnails for first-time onboarding?
