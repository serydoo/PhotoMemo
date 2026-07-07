# Spec: MainView Preview Detail Refactor

## Objective
Continue reducing `MainView.swift` without changing MemoMark's current MVP behavior. This round focuses on the preview/detail side helpers that still live inline in `MainView`: the live preview layout, preview header, preview canvas shell, live context summary, and small status pills.

Success means `MainView` keeps acting as the coordinator for state, bindings, and side effects, while preview/detail display composition moves into a dedicated `MainView+*.swift` file that is easier to iterate on and less likely to hide behavior inside layout code.

## Assumptions
1. This slice is structural only and should not change any preview/export behavior.
2. The preview width rule should stay exactly the same for landscape vs portrait photos.
3. There is no separate automated test target in the current Xcode project, so verification will rely on build success plus diff review and manual-check guidance.

## Tech Stack
- Swift 5
- SwiftUI
- Xcode project: `Source/PhotoMemo/PhotoMemo.xcodeproj`

## Commands
- Build: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- Project info: `xcodebuild -list -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj`
- Git status: `git -C /Users/rui/Desktop/PhotoMemo status --short`
- MainView line count: `wc -l /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`

## Project Structure
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` -> Main coordinator view and state/actions
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+*.swift` -> extracted MainView display panels and helper views
- `Docs/` -> refactor specs, plans, and status docs

## Code Style
Use focused SwiftUI display views that receive already-resolved values from `MainView`. Avoid moving business logic or side effects into extracted preview panels.

```swift
MainPreviewDetailView(
    selectedPhoto: selectedPhoto,
    card: card,
    previewWidth: previewCardMaxWidth(for: selectedPhoto)
)
```

## Testing Strategy
- Primary verification is project build success with `xcodebuild`
- No dedicated automated test target is currently available in the project
- Manual verification scope for this round:
  - preview still appears after importing a photo
  - live context summary still reflects the selected template and anchor result
  - hero status pills still show current template, anchor, and photo-library readiness
  - portrait and landscape photos still get the same preview width behavior as before

## Boundaries
- Always:
  - keep `MainView` responsible for state, bindings, and side effects
  - keep preview fidelity tied to the real renderer path
  - preserve current copy and UI behavior unless a structural rename is needed for extracted view types
  - verify with a build after edits
- Ask first:
  - changing preview behavior or width heuristics
  - introducing new dependencies
  - changing the render/export pipeline
- Never:
  - revert unrelated user changes
  - move business logic into decorative preview subviews
  - expand feature scope beyond this structural refactor slice

## Success Criteria
- `MainView.swift` loses inline implementations for:
  - preview detail composition
  - preview header
  - preview canvas shell
  - live context summary
  - status pill view
- New preview/detail display views live in a dedicated `Views/Main` file
- Build succeeds after the extraction
- Existing preview and coordinator behavior remains unchanged

## Open Questions
- After this slice, should the next extraction focus on remaining template-field editor wrappers or any lingering coordinator-adjacent helper logic still embedded in `MainView`?
