# Default Memory Subject Privacy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace family-specific user-visible defaults with neutral baby nicknames and a recent default birthday.

**Architecture:** Keep the change limited to runtime seed data, preview fallbacks, and visible examples. Preserve all Memory Engine, Layout Engine, Renderer, Export, Metadata, Share Extension, Photo Library, camera, and device-model behavior.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Xcode

---

### Task 1: Runtime defaults and examples

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterMockSeed.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterMemoryTemplateCatalog.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPreviewCompositionHelper.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+UIPrimitives.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Views/Template/TemplateEditorView.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/Views/FirstRun/FirstRunWizardView.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1WelcomePresentation.swift`

- [ ] Replace runtime-visible `途途` fallbacks and examples with `小宝`.
- [ ] Change multi-name examples to `小宝、宝贝儿、安安`.
- [ ] Set hard-coded default birthday components to `2025-12-20`.
- [ ] Keep unrelated camera and device strings unchanged.

### Task 2: Focused tests

**Files:**
- Modify only tests whose assertions directly encode changed runtime defaults.

- [ ] Search tests for assertions affected by `小宝` and `2025-12-20`.
- [ ] Run focused Configuration Center, preview-composition, and first-run tests.
- [ ] Fix only assertions that represent the approved new defaults.

### Task 3: Documentation and verification

**Files:**
- Modify: `HANDOFF.md`

- [ ] Record the privacy-default cleanup and its verification in `HANDOFF.md`.
- [ ] Confirm runtime source contains no remaining user-visible `途途` occurrence.
- [ ] Run `git diff --check`.
- [ ] Run the unsigned iOS Debug build from `AGENTS.md`.
- [ ] Review the complete scoped diff for correctness, architecture, security, and performance.

### Task 4: GitHub synchronization

- [ ] Inspect mixed worktree scope before staging.
- [ ] Stage only approved privacy-default files and the related handoff/spec/plan documents.
- [ ] Commit with a scoped message.
- [ ] Push the current branch to `origin` using available Git credentials.
