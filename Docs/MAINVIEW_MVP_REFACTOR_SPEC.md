# Spec: MainView MVP Refactor Round 2

## Objective
Reduce `MainView.swift` complexity without changing MemoMark's current MVP behavior. This round focuses on the template calibration center surfaces that still live directly inside `MainView`: template selection, template rename, supplemental content, and logo configuration.

Success means `MainView` becomes more of a state coordinator, while these editor panels move into dedicated view types that are easier to iterate on during MemoMark's template-calibration MVP phase.

## Tech Stack
- Swift 5
- SwiftUI
- Xcode project: `Source/PhotoMemo/PhotoMemo.xcodeproj`

## Commands
- Build: `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- Git status: `git -C /Users/rui/Desktop/PhotoMemo status --short`
- MainView line count: `wc -l /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`

## Project Structure
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` → Main coordinator view and state/actions
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+*.swift` → extracted MainView subviews
- `Docs/` → project planning and refactor specs

## Code Style
Use lightweight SwiftUI wrapper views that receive bindings, display values, and action closures from `MainView`. Keep business logic and persistence in `MainView`; move display composition out.

```swift
MainTemplateSectionView(
    selectedPreset: selectedTemplatePreset,
    resolvedTemplateDisplayName: resolvedTemplateDisplayName,
    onPresentTemplateRename: {
        presentTemplateRenameSheet()
    }
)
```

## Testing Strategy
- Primary verification is project build success with `xcodebuild`
- Manual verification scope for this round:
  - template preset switching still works
  - template rename sheet still opens and saves
  - photo description settings still bind correctly
  - logo selection still updates preview semantics

## Boundaries
- Always:
  - preserve current UI behavior and copy unless simplification is structural only
  - keep `MainView` responsible for persistence and side effects
  - verify with a build after edits
- Ask first:
  - changing product flow
  - introducing new dependencies
  - renaming user-facing concepts beyond the already approved logo/标识 direction
- Never:
  - revert unrelated user changes
  - mix unrelated cleanup into this refactor slice
  - expand feature surface beyond current MVP

## Success Criteria
- `MainView.swift` loses the inline implementations for:
  - template section
  - custom content section
  - badge section
  - template rename sheet
- New extracted views live in a dedicated `Views/Main` file
- Build succeeds after the extraction
- Existing template-calibration behavior remains unchanged

## Open Questions
- Next round should likely target `photoSection` and `anchorSection`, or preview/detail helpers, depending on which side keeps growing faster.
