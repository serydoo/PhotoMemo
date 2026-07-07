# Spec: MainView Permission And Content Refinement

## Objective
Refine several high-friction parts of MemoMark's current template-calibration UI without breaking the real preview/render/export pipeline.

This slice focuses on three issues raised from current usage:

1. Photo Library permission should feel explicit and understandable, especially when macOS will not re-show the system prompt after denial.
2. Birthday-style smart anchor output should avoid awkward `0岁8个月` wording for children under one year old.
3. The `补充信息` area should become simpler and clearer: a single card, one explicit checkbox for whether to use custom batch-description input, and a default fallback that writes the full right-bottom rendered content when custom input is not enabled.

This slice does **not** fully implement the larger three-config switching system yet. That requires a broader state and persistence redesign across `MainView`, `SettingsService`, and background-queue defaults.

## Assumptions
1. On macOS, Photo Library permission will only show the system prompt once; after denial, the right fix is to lead the user to System Settings rather than pretending the prompt can reappear.
2. For birthday/age wording, under-one-year output should suppress the `0岁` prefix but keep month/day precision when available.
3. The user's requested custom-description checkbox should control whether a separate batch description is entered; when unchecked, MemoMark should still write the full rendered right-bottom content instead of writing nothing.
4. The three-config button system and operation-guide redesign should be planned now but deferred from this implementation slice.

## Tech Stack
- Swift 5
- SwiftUI
- Xcode project: `Source/PhotoMemo/PhotoMemo.xcodeproj`

## Commands
- Build: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- Git status: `git -C /Users/rui/Desktop/PhotoMemo status --short`
- Relevant files:
  - `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`
  - `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`

## Project Structure
- `Views/Main/` -> current template-calibration UI and refactored MainView panels
- `Services/PermissionCenter.swift` -> permission state and settings-routing logic
- `Engines/AnchorEngine.swift` -> smart anchor output semantics
- `Services/SettingsService.swift` -> persisted local configuration and editor-state storage
- `Docs/` -> repo-local specs and plans for refactor slices

## Code Style
Prefer small behavior-preserving refinements over broad rewrites. Keep business logic in service/engine layers or `MainView`, and keep extracted SwiftUI views display-focused.

```swift
if state == .denied {
    openSettingsAction()
} else {
    requestAction()
}
```

## Testing Strategy
- Primary verification: project build success with `xcodebuild`
- There is currently no separate automated test target in the Xcode project
- Manual verification focus for this slice:
  - denied photo-library state shows the right next action
  - first-time permission flow still works
  - under-one-year birthday smart text no longer shows `0岁`
  - custom description checkbox behavior matches the requested fallback rules

## Boundaries
- Always:
  - preserve local-first behavior
  - keep preview/render/export wired to the real card pipeline
  - preserve explicit slot-routing behavior for custom regions
  - run a build after edits
- Ask first:
  - replacing the single-configuration model with a fully multi-slot configuration system
  - changing background queue semantics beyond the current default-configuration sync
  - adding new dependencies
- Never:
  - revert unrelated user changes
  - pretend the macOS permission prompt can be shown again after denial
  - mix the full three-config redesign into this smaller refinement slice

## Success Criteria
- Photo Library permission UI clearly distinguishes between first-time request and post-denial recovery
- Birthday smart text suppresses `0岁` for under-one-year output
- `补充信息` becomes a single-card section with one clear custom-description checkbox
- When custom-description input is disabled, MemoMark falls back to the full rendered right-bottom content instead of writing nothing
- Build succeeds after the change

## Open Questions
- How should the future three-config system model saved slots: template presets only, or full `BatchConfigurationSnapshot` variants including anchor, badge, album, and text drafts?
- Should the future operation guide live as a right-side sheet, a popover menu, or a dedicated help panel?
