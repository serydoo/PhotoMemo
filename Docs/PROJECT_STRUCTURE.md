# PhotoMemo Project Structure

Last updated: 2026-07-02

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

## Repository Line Management

Historical PhotoMemo phases should be preserved through Git lines, not duplicated source folders.

Current intended split:

- `main` - V2 reset, IA-003, and repository source-of-truth line
- `release/v1` - ongoing V1 iPhone product line
- tags / releases - macOS foundation, iOS foundation, MVP, and V1 checkpoints

Do not create parallel root trees such as `MacVersion/`, `MVP/`, or `V1/` to archive history.

See `Docs/07_Releases/REPOSITORY_LINE_STRATEGY.md` for the repository cleanup policy.

## Xcode Workspace

- `Source/PhotoMemo/PhotoMemo.xcodeproj`
- `Source/PhotoMemo/PhotoMemo/`
- `Source/PhotoMemo/PhotoMemoWidgetExtension/`
- `Source/PhotoMemo/ShareExtension-Info.plist`

## App Source

`Source/PhotoMemo/PhotoMemo/` currently contains:

- `App/` - app runtime, external intake, shared container, deep links, and share workflow summaries
- `Architecture/` - lightweight shared app primitives such as result/environment wrappers
- `Models/` - core data models such as templates, anchors, badges, metadata, record cards, selected photos, and batch state
- `Repositories/` - repository-facing access boundaries for configuration, settings, queue, diagnostics, and photo-library reads
- `Intent/` - explicit app-flow, preview, queue, export, and save intents
- `Coordinators/` - higher-level orchestration for configuration, preview, export, queue, and share flows
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

## iOS Configuration Center And V1 Surface

`Source/PhotoMemo/PhotoMemo/iOS/Views/` is still physically flat, but the current working structure is easiest to read as four logical groups:

- Configuration Center:
  - `ConfigurationCenteriOSView.swift`
  - `ConfigurationCenter*`
  - `IOSConfigurationPanel.swift`
  - `MemoryWriteOptionPresenter.swift`
- V1 shell and subject flow:
  - `PhotoMemoiOSV1View.swift`
  - `V1Configuration*`
  - `V1Draft*`
  - `V1Preview*`
  - `V1IOSSubject*`
  - `V1SubjectHomeSummarySupport.swift`
- Home surface:
  - `PhotoMemoiOSHomeView.swift`
  - `PhotoMemoiOSBackgroundStatusSheet.swift`
  - `V1IOSHome*`
- Diagnostics and support:
  - `PhotoMemoiOSProcessingDiagnosticsSnapshot.swift`
  - `PhotoMemoiOSQueueDiagnosticsProjectionEngine.swift`
  - `V1DiagnosticsRefreshCoordinator.swift`
  - `PhotoMemoiOSTemporaryEntryView.swift`
  - `PhotoMemoiOSModuleCatalog.swift`
  - `IOSCompactEntryRow.swift`

The folder remains physically flat for now because the Xcode project uses filesystem-synchronized groups and the repository keeps long handoff histories with direct file links. Treat the grouping above as the current lookup map until a dedicated filesystem migration slice is approved.

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
