# PhotoMemo Current Status

Last updated: 2026-06-18

## Current Stage

PhotoMemo is currently in a combined refinement stage:

- Product-wise, it is still a **local-first template calibration center**
- Engineering-wise, it is moving from a large prototype-style `MainView` toward a more maintainable coordinator structure
- Capability-wise, the project has already crossed the MVP foundation line:
  - real EXIF import
  - anchor calculation
  - preview rendering
  - export to new image
  - save back to Photo Library
  - background queue and permission foundation

According to `Docs/DEVELOPMENT_PLAN.md`, the project is between:

- Phase 2: Template Calibration Center
- Phase 5: Render Fidelity And Metadata Hardening

## What Was Completed In This Round

### 1. Addy Osmani skills installed for future development workflow

The following skills are now installed in local Codex:

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

Recommended usage pattern for future work:

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

### 2. MainView refactor continued in controlled slices

`MainView.swift` is still large, but it has been meaningfully reduced and split into focused subviews.

Recent extracted files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerWidgets.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`

MainView line-count trend observed in this refactor stream:

- `5706`
- `5096`
- `4885`
- `4614`
- `4529`
- `4314`
- `4164`
- `3974`

Current result:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is now acting more like a coordinator
- template setup, logo setup, photo import summary, anchor setup, live preview shell, and multiple editor/panel regions have been extracted
- some dead UI helpers were removed after extraction to prevent stale code from remaining in `MainView`

### 3. Template-calibration UI structure is more stable

Completed structural extractions now cover:

- template section
- template rename sheet
- custom content section
- logo section
- photo section
- anchor section
- preview/detail display shell
- composer entry panel
- literal composer sheet
- variable library panels
- field editor wrappers
- memory / output / permission panels

This means future MainView work should prioritize:

- any lingering state-heavy editing helpers that still live inline
- any remaining preview-adjacent helper logic that is still coupled to coordinator code

### 4. Immers-style white border direction has already been integrated

Product/UI decisions already established in this workstream:

- only borrow the bottom white-bar design language from Immers
- keep PhotoMemo content centered on memory + smart modules, not generic EXIF-only filler
- unify the old badge semantics toward `Logo 标识`
- for `immersWhite`, when no custom logo is selected, use a classic Apple mini logo fallback
- horizontal layout was tuned to better match the reference direction while still staying consistent with PhotoMemo

Key related files:

- `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplatePreset.swift`
- `Source/PhotoMemo/PhotoMemo/Models/Template.swift`
- `Source/PhotoMemo/PhotoMemo/Models/TemplateItem.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Template/BadgePickerView.swift`

### 5. Permission and content wording refinement started

Latest refinement work now also covers:

- denied photo-library permission no longer pretends the system prompt can be re-shown; the UI now guides the user toward System Settings
- birthday-style smart text suppresses awkward under-one-year wording like `0岁8个月`
- the `补充信息` section now uses a single card and treats the checkbox as custom batch-description mode; when it is off, PhotoMemo falls back to the rendered right-bottom content

### 6. Multi-configuration workspace controls are now in progress

Latest MainView work now also adds a real right-side configuration workflow:

- three persisted local configuration slots
- one active slot at a time
- right-side save / restore-default actions instead of the old toolbar-only save entry
- a right-side operation-guide menu and sheet
- dismissible helper cards for anchor, smart-module, and supplemental-content guidance

Behavior expectations for this slice:

- switching slots should refresh the left-side configuration state and right-side preview together
- unsaved slots should fall back to `模板 1 / 2 / 3` default skeletons
- the active slot should remain aligned with the batch queue's default configuration snapshot

### 7. Workspace naming and help-center navigation were refined

The latest follow-up refinement now also adds:

- custom naming for each of the three configuration slots
- a dedicated rename sheet for the active slot
- a grouped right-side help-center menu instead of a flat operation-guide list
- a formal split-view help center with category navigation and topic detail panes

Important behavior choices:

- slot renaming changes only the workspace slot label, not the template name
- restoring a slot to its default skeleton clears the saved snapshot but keeps the custom slot name
- already-dismissed inline tips remain removable from the left side, while the full explanation stays available inside the help center

### 8. Left-side clutter and output controls were reduced further

The latest cleanup pass now also does the following:

- memory-progress guidance is dismissible like the other helper cards
- the personalized-region guidance is dismissible instead of being hard-coded inline text
- the supplemental-content area is truly reduced to a single card
- the permission block no longer occupies the sidebar after both permissions are granted
- the help center no longer keeps a separate permission topic after the permission flow is already understood
- the output area now focuses on album selection plus save-to-library, without the extra metadata-validation buttons

## Behavior Rules Preserved During Refactor

These behaviors were intentionally preserved and should not be reverted:

- variable insertion must target an explicitly selected custom region
- no implicit fallback that silently inserts into the right-bottom region
- template switching, restoring defaults, and template rename must refresh composer editing state
- preview-side template calibration must stay connected to the real render/export chain

## Verification Status

Recent verification command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Status:

- build passes
- only Xcode destination-selection warning observed
- no new compile error from the latest MainView extraction rounds
- there is still no separate automated test target in the current Xcode project, so refactor validation is currently build-first plus manual regression checks

## Current Technical Debt

### Still large

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` is improved but still too large for long-term comfort.

### Coordinator-adjacent editing helpers still need decomposition

The preview/detail display shell has now been extracted, but `MainView` still contains a large amount of editing, routing, and synchronization helper logic that should keep moving toward clearer coordinator-only responsibilities.

### Multi-config and in-app guidance still need a dedicated design slice

The newly requested three-slot configuration system and right-side operation guide are both product-shaping changes. They should be implemented as a dedicated state/persistence redesign instead of being mixed into small UI tweaks.

### Manual UI regression checks are still needed

Builds are passing, but some refactor rounds were verified mainly by compilation and structure review. Manual checks remain important for:

- template rename flow
- anchor selection flow
- photo import flow
- logo fallback behavior on `immersWhite`
- preview/export visual parity

## Recommended Next Steps

### Near-term

1. Continue extracting or simplifying the remaining inline editing/state helpers from `MainView`
2. Keep `MainView` focused on state, bindings, and action routing only
3. Run a deliberate manual check for:
   - template switching
   - template rename
   - anchor selection
   - photo import
   - live preview rendering after import
   - white-border logo fallback

### Product hardening

1. Continue preview/export parity work
2. Continue metadata-retention validation
3. Harden failed-task retry and library save feedback

### Architecture

1. Keep reducing macOS-only assumptions where practical
2. Preserve future iOS migration room
3. Avoid adding new feature surface faster than the real processing chain can support

## Best Entry Files For A New Session

Read in this order:

1. `README.md`
2. `AI_CONTEXT.md`
3. `HANDOFF.md`
4. `AGENTS.md`
5. `Docs/CURRENT_STATUS.md`
6. `Docs/DEVELOPMENT_PLAN.md`

Then inspect:

- `git status`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- the newest `MainView+*.swift` extraction files
