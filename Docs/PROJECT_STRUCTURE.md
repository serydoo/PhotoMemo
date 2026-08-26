# MemoMark Project Structure

Last updated: 2026-08-26

This is the practical lookup map for the current repository. Architecture and
product ownership remain defined by `PROJECT_CONSTITUTION.md`,
`Docs/MASTER_PLAN.md`, and the accepted PDR/ADR records.

## Repository root

- `Source/MemoMark/` — current Xcode project and production source.
- `Tests/MemoMarkTests/` — Swift Testing suites grouped by system.
- `Tests/MemoMarkUITests/` — signed-device QA harness tests.
- `Docs/` — product, architecture, development, release, and historical records.
- `Research/` — V4 research inputs, methods, and Expression Style foundation.
- `scripts/` — build, QA, evidence, and synchronization helpers.
- `QA/` — physical-device QA manifest and operating guidance.
- `App/`, `DesignSystem/`, `LayoutEngine/`, `Renderer/` — repository-level
  boundary notes; production implementation remains under `Source/MemoMark/`.
- `Examples/`, `Screenshots/` — public, non-private example boundaries.

## Xcode project

- Project: `Source/MemoMark/MemoMark.xcodeproj`
- macOS app: `MemoMark`
- iOS app: `MemoMarkiOS`
- Share Extension: `MemoMarkShareExtension`
- Widget Extension: `MemoMarkWidgetExtension`
- Unit tests: `MemoMarkTests`
- Physical-device QA: `MemoMarkDeviceQA`

Published bundle identifiers, App Group values, persistence keys, background
task identifiers, StoreKit identifiers, and legacy URL parsing intentionally
retain their historical compatibility values. Internal target and module names
use MemoMark.

## Production source

`Source/MemoMark/MemoMark/` is organized by ownership:

- `App/` — app lifecycle, external intake, shared-container state, root scenes,
  background status, and cross-target workflow summaries.
- `Architecture/` — small shared architectural primitives.
- `ConfigurationCenter/` — macOS Configuration Center, configuration session,
  object editors, inspectors, Memory Card, and configuration models.
- `Models/` — durable and runtime domain values.
- `Repositories/` — persistence and data-access boundaries.
- `Intent/` — explicit user/application intents.
- `Coordinators/` — orchestration across configuration, preview, queue, export,
  and share workflows.
- `Engines/`, `Expression/`, `MemoryEngine/`, `MetadataExpression/`,
  `LocationExpression/` — deterministic facts, memory calculation, and
  presentation-expression layers.
- `LayoutEngine/`, `MediaGeometry/` — measurable layout and media geometry.
- `Renderers/` — drawing implementations that consume resolved layout/content.
- `Services/`, `MediaPipelineVNext/` — PhotoKit, metadata, export, Live Photo,
  queue, notification, and media lifecycle services.
- `iOS/` — iOS app shell, ActivityKit bridge, Share Extension, and current views.
- `Views/` — current macOS/shared SwiftUI surfaces. The retired
  `Views/Main/MainView*` workspace/editor subtree must not be restored.
- `Assets.xcassets/` and `*.lproj/` — current assets and four-language resources.

## Current app entry points

- macOS: `ConfigurationCenter/ConfigurationCenterView.swift`
- iOS root scene: `App/MemoMarkRootSceneView.swift`
- iOS primary experience: `iOS/Views/MemoMarkiOSV1View.swift`
- Share Extension controller:
  `iOS/ShareExtension/MemoMarkShareExtensionViewController.swift`
- Widget bundle:
  `MemoMarkWidgetExtension/MemoMarkWidgetExtensionBundle.swift`

There is one accepted iOS production entry. The retired temporary dual-entry
switcher and legacy MainView workspace path are not part of the current tree.
Do not merge app, Share Extension, and Widget entry files: they belong to
different Apple target and lifecycle boundaries.

## iOS view map

`Source/MemoMark/MemoMark/iOS/Views/` remains physically flat because the
project uses filesystem-synchronized groups. Use the local `README.md` there
for the current logical grouping. New files should follow existing
`ConfigurationCenter*`, `V1*`, or `MemoMarkiOS*` responsibility prefixes.

## Tests

`Tests/MemoMarkTests/` contains:

- `ArchitectureTests/`
- `BatchTests/`
- `ExportTests/`
- `MemoryEngineTests/`
- `MetadataTests/`
- `RendererTests/`
- `VariableTests/`
- `Support/`

Source-contract tests must resolve files through `MemoMarkTestPaths`; they must
not embed a developer-specific absolute checkout path.

## Document navigation

- Start with `Docs/DOCUMENT_INDEX.md` to distinguish current facts from history.
- Use `Docs/CURRENT_STATUS.md` for the latest verified state.
- Use `HANDOFF.md` for chronological continuation.
- Use `Docs/07_Releases/README.md` for the current release package.
