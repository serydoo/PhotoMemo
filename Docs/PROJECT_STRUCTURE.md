# PhotoMemo Project Structure

Last updated: 2026-06-22

This document maps the current source tree at a practical level. It is meant to help new sessions find the right file quickly, not to replace architecture or workflow docs.

## Repository Root

- `README.md` - product identity and high-level status
- `AI_CONTEXT.md` - compact AI working context
- `AGENTS.md` - repository working rules
- `HANDOFF.md` - session handoff history
- `CHANGELOG.md` - release-facing change history
- `PROJECT_RESET.md` - permanent V2 reset memory
- `RepositoryAudit.md` - V2 repository audit
- `App/` - reserved V2 app-facing structure
- `Docs/` - product, architecture, QA, and session documents
- `Research/` - V2 research system
- `DesignSystem/` - reserved V2 design-system assets
- `LayoutEngine/` - reserved V2 layout-engine boundary
- `Renderer/` - reserved V2 renderer boundary
- `Examples/` - public non-private examples
- `Screenshots/` - public non-private screenshots
- `Source/PhotoMemo/` - app source and Xcode project
- `Tests/` - fixtures and Swift test sources
- `scripts/` - local automation helpers

## V2 Target Structure

The V2 target structure is now represented non-destructively at the repository root:

- `App/`
- `Docs/`
- `Research/`
- `DesignSystem/`
- `LayoutEngine/`
- `Renderer/`
- `Examples/`
- `Screenshots/`
- `scripts/`
- `Tests/`

Existing source files remain under `Source/PhotoMemo/` until a reviewed migration slice moves them safely.

## Xcode Workspace

- `Source/PhotoMemo/PhotoMemo.xcodeproj`
- `Source/PhotoMemo/PhotoMemo/`
- `Source/PhotoMemo/PhotoMemoWidgetExtension/`
- `Source/PhotoMemo/ShareExtension-Info.plist`

## App Source

`Source/PhotoMemo/PhotoMemo/` currently contains:

- `App/` - app runtime, external intake, shared container, deep links, and share workflow summaries
- `Models/` - core data models such as templates, anchors, badges, metadata, record cards, selected photos, and batch state
- `Engines/` - deterministic calculation and template engines
- `MemoryEngine/` - memory-context and memory-variable calculation support
- `Renderers/` - preview/export renderers and render theme support
- `Services/` - import, metadata, export, photo-library save, settings, permissions, queue, and notification services
- `Views/` - macOS SwiftUI views for main calibration, preview, template, anchor, first-run, and shared components
- `iOS/` - iOS app shell, share extension, activity/live-activity bridge, and iOS-specific views
- `Extensions/` - small Swift extensions
- `Assets.xcassets/` - app icons, accent color, and badge assets
- entitlement files for macOS, iOS, and share extension targets

## Main Editor Flow

The main editor has been decomposed into a coordinator shell plus focused extensions:

- `Views/Main/MainView.swift` - coordinator shell and service/state ownership
- `Views/Main/MainView+StateModels.swift` - grouped local state models
- `Views/Main/MainView+LayoutSections.swift` - main scene and section composition
- `Views/Main/MainView+WorkspaceSession.swift` - workspace session wiring
- `Views/Main/MainView+WorkspaceConfigurationState.swift` - workspace configuration lifecycle
- `Views/Main/MainView+WorkspaceControls.swift` - workspace controls
- `Views/Main/MainView+TemplateEditingActions.swift` - template editing actions
- `Views/Main/MainView+ComposerSession.swift` - composer session state and behavior
- `Views/Main/MainView+ComposerDisplayEngine.swift` - inline composer display model
- `Views/Main/EditorProjectionEngine.swift` - editor projection logic
- `Views/Main/MainView+ExportActions.swift` - save/export actions
- `Views/Main/MainView+PermissionLifecycle.swift` - permission lifecycle handling
- `Views/Main/MainView+ModalAndLifecycle.swift` - modal and lifecycle glue

When touching main editor behavior, inspect `MainView.swift` plus the newest relevant `MainView+*.swift` file instead of assuming all logic still lives in one large file.

## Tests

`Tests/PhotoMemoTests/` is organized by system:

- `BatchTests/`
- `ExportTests/`
- `MemoryEngineTests/`
- `MetadataTests/`
- `RendererTests/`
- `VariableTests/`
- `Support/`

`Tests/Fixtures/` holds synthetic image fixtures and renderer snapshot references.

## Document Map

Use `Docs/DOCUMENT_INDEX.md` as the first stop for deciding which docs are current working references, topic-specific references, or historical notes.
