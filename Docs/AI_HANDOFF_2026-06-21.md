# AI Handoff 2026-06-21

This file is a compact handoff packet for future AI sessions.

For full history, also read:

- `README.md`
- `AI_CONTEXT.md`
- `HANDOFF.md`
- `Docs/CURRENT_STATUS.md`
- `AGENTS.md`

## Product Direction Snapshot

MemoMark is now being refined as:

- a local-first memory card generator
- a share-first product built around Apple Photos
- a configuration center in the main app
- a rendering workflow that should feel quiet, automatic, and Apple-like

Current product language to preserve:

- MemoMark is not a photo editor
- configure once, share naturally, remember forever
- users should spend most of their time in Apple Photos, not in the main app

## What Landed In This Round

The current worktree includes several connected slices that are intentionally small in product scope but meaningful in product quality:

1. Share and workflow foundation

- external intake state now carries stronger provenance
- share intake diagnostics now expose deeper failure-stage information
- deep link groundwork was added for share-driven workflow coordination

2. Export naming hardening

- output file naming now prefers real original file names
- placeholder names such as `Photo Library` and `MemoMark Import` are filtered out
- deterministic fallback naming now uses `IMG_yyyyMMdd_HHmmss`
- copy suffix behavior follows:
  - `name.jpg`
  - `name (1).jpg`
  - `name (2).jpg`

3. First Run simplification

- first-run setup was reworked toward a cleaner system-style flow
- long-term profile concepts are moving toward:
  - relationship
  - baby nickname
  - birthday
  - default output destination
  - default style

4. Classic White render system hardening

- `RenderTheme.swift` introduced render tokens
- `ClassicWhiteCardRenderer.swift` extracted layout responsibility
- `ClassicWhiteRenderer.swift` now follows fixed-theme sizing rules
- `RecordCardRenderer.swift` now routes presets more explicitly

5. Snapshot-grade visual QA

- committed synthetic baselines live in:
  - `Tests/Fixtures/RendererSnapshots/ClassicWhite/full-card/`
- four reference scenarios now exist:
  - `landscape_standard`
  - `landscape_long_exif`
  - `portrait_standard`
  - `portrait_long_memory`
- `ClassicWhiteSnapshotTests.swift` and `ClassicWhiteSnapshotSupport.swift` now protect full-card visual stability

## Most Important Files

If a future AI needs to continue from the current state, inspect these first:

- `Source/PhotoMemo/PhotoMemo/Renderers/RenderTheme.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Models/PhotoFileNameResolver.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- `Source/PhotoMemo/PhotoMemo/Views/FirstRun/FirstRunWizardView.swift`

Related tests:

- `Tests/PhotoMemoTests/ExportTests/PhotoFileNameResolverTests.swift`
- `Tests/PhotoMemoTests/ExportTests/PhotoImportServiceTests.swift`
- `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
- `Tests/PhotoMemoTests/BatchTests/ExternalPhotoIntakeStoreDiagnosticsTests.swift`
- `Tests/PhotoMemoTests/RendererTests/ClassicWhiteRendererThemeTests.swift`
- `Tests/PhotoMemoTests/RendererTests/ClassicWhiteCardRendererLayoutTests.swift`
- `Tests/PhotoMemoTests/RendererTests/ClassicWhiteSnapshotTests.swift`
- `Tests/PhotoMemoTests/RendererTests/ImmersWhiteRendererLayoutTests.swift`
- `Tests/PhotoMemoTests/RendererTests/RecordCardRendererRoutingTests.swift`

## Verification Completed

The following verification has already been completed in this session:

- `PhotoMemoTests` full suite: passed
- `MemoMark` build: passed
- `PhotoMemoiOS` build: passed
- `PhotoMemoShareExtension` build: passed
- device install: passed
- device launch: passed

Installed device:

- user-visible name: `TestDeviceB`
- model: `iPhone 17 Pro Max`
- bundle id: `com.serydoo.PhotoMemo.iOS`

## Snapshot Workflow Note

Classic White snapshot refresh is now documented in:

- `Docs/ClassicWhiteVisualQA.md`

Important behavior:

- record mode is explicit via `.record-mode`
- reference PNG refresh uses exported Xcode test attachments
- normal comparison is strict, but allows only tiny color-managed drift:
  - `maxChannelDelta <= 1`
  - differing pixels below `0.05%`

This tolerance is only there to absorb attachment refresh color noise, not layout drift.

## Open Follow-Up Areas

These are the most natural next slices, without expanding product surface too early:

1. Real-device Share path verification

- confirm share confirmation page
- confirm actual render-save loop
- confirm user-facing error feedback if save fails

2. Main app simplification follow-through

- continue reducing workspace/developer language
- keep the app feeling closer to a settings/configuration center

3. Renderer polish against user-provided reference output

- especially Immers-style right-column spacing
- typography hierarchy
- divider/logo/text geometry

## Best Next Prompt For Another AI

If another AI needs to continue safely, a good starting prompt is:

`Read README.md, AI_CONTEXT.md, HANDOFF.md, AGENTS.md, Docs/CURRENT_STATUS.md, and Docs/AI_HANDOFF_2026-06-21.md. Then inspect git status. Continue from the current share-first MemoMark state without refactoring architecture.`
