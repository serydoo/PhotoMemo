# Changeset Draft: MainView Refactor And Project-State Docs

Last updated: 2026-06-18

## Suggested Commit Title

```text
Refactor MainView into focused panels and add project state docs
```

## Suggested PR Title

```text
Refactor MainView panel structure and formalize project handoff rules
```

## Summary

This changeset does two things:

1. Continues the structural decomposition of `MainView.swift` into focused SwiftUI panel files without changing the current PhotoMemo MVP direction.
2. Formalizes long-term repository guidance and current project state in project-internal docs so future PhotoMemo sessions can restart with less context loss.

## Why This Change Exists

PhotoMemo is no longer at the “just make it work” stage.

The project now has:

- a real EXIF import path
- real anchor calculation
- real preview and export rendering
- photo-library writeback
- background queue foundations

At this stage, the main editor flow must become easier to maintain.

`MainView.swift` had grown into a large implementation bucket. This refactor keeps behavior in place while pushing display-heavy sections into dedicated panel files, moving `MainView` closer to a coordinator role.

At the same time, repository restart cost was too high. New sessions still depended too heavily on chat history, so this changeset adds durable status and rule documents.

## MainView Refactor Scope

### Newly extracted panel files

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+MemoryProgress.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerWidgets.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+SetupPanels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`

### Areas now extracted from `MainView`

- memory progress panel
- output panel
- permission panel
- composer entry panel
- literal composer sheet
- variable library panels
- field editor wrappers and widgets
- template panel
- template rename sheet
- supplemental content panel
- logo panel
- photo setup panel
- anchor setup panel
- preview/detail display shell

### Behavioral rules preserved

- variable insertion still requires an explicitly selected custom region
- no implicit fallback insertion into the right-bottom region
- template switch / reset / rename still refresh composer editor state
- setup and editor UI remain tied to the real render/export chain

### Structural result

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` was reduced to approximately:

```text
3974 lines
```

The file is still large, but now has substantially more panel delegation and less inline UI density.

## Documentation Scope

### New files

- `AGENTS.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/MAINVIEW_MVP_REFACTOR_SPEC.md`
- `Docs/MAINVIEW_MVP_REFACTOR_PLAN.md`

### Updated file

- `HANDOFF.md`

### What these docs now cover

- startup reading order for new sessions
- long-term product and engineering guardrails
- current status of MainView decomposition
- installed skills and preferred development workflow
- Immers white-border constraints
- verification expectations
- recommended next implementation targets

## Verification

Build command used:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Observed result:

- build passed
- only Xcode destination-selection warning observed
- no new compile errors introduced by the panel extraction rounds
- current validation remains build-first because the Xcode project still has no separate test target

## Known Remaining Risks

- `MainView.swift` is improved but still too large for long-term comfort
- manual UI regression checks are still needed for:
  - template rename
  - template switching
  - photo import flow
  - anchor selection flow
  - `immersWhite` default logo fallback
  - preview/export parity

## Recommended Next Slice

If work continues immediately after this changeset, the best next refactor target is:

- remaining inline editing-state and routing helpers in `MainView`

After that:

- continue render/export parity checks
- continue metadata retention hardening
- continue reducing macOS-only assumptions where practical
