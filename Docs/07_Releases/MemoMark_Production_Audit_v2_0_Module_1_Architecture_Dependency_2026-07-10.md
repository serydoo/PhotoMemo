# MemoMark Production Audit v2.0 Module 1

Module: Architecture & Dependency Audit

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Scope

This module reviews:

- app entry and composition root
- module dependency direction
- architecture debt
- API shape across App, Service, Repository, Coordinator, and Pipeline layers
- dependency review
- testability and future evolution pressure

It does not attempt to fix implementation issues. State consistency,
Configuration Repository behavior, Memory Engine semantics, Media Pipeline
correctness, SwiftUI behavior, and release performance will be reviewed in later
modules.

## Executive Assessment

Rating: **B+**

MemoMark's architecture is materially healthier than a typical late-MVP app.
The key boundaries still mostly hold:

- Renderer does not read Repository, UserDefaults, or Photo Library state.
- MemoryEngine does not import or depend on SwiftUI/UIKit.
- AppEnvironment provides a real composition root for the main app.
- MediaPipelineVNext has several protocol seams for Live Photo loading,
  writing, metadata revision, and readback verification.

The architecture debt is concentrated in glue and orchestration layers:

- runtime and App Group fallback behavior
- singleton intake paths beside environment-owned intake paths
- queue store/execution two-way coupling
- very large controller/view/service files
- concrete service/repository APIs that are only partially protocolized
- old and new iOS configuration surfaces coexisting

This is not a "rewrite" situation. It is a boundary hardening and progressive
extraction situation.

## Evidence

### Positive boundary evidence

Renderer dependency scan:

- `Source/PhotoMemo/PhotoMemo/Renderers/*` references SwiftUI rendering types,
  but no Repository, SettingsRepository, ConfigurationRepository,
  BatchQueueStore, PhotoLibraryExportService, PHPhotoLibrary, or UserDefaults
  references were found.

Memory Engine dependency scan:

- `Source/PhotoMemo/PhotoMemo/MemoryEngine/*` did not show SwiftUI/UIKit,
  UserDefaults, Repository, or Photo Library dependencies in this module scan.

Media pipeline seam evidence:

- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoAssetLoading.swift`
  defines Live Photo loading/resource provider/exporter protocols.
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/LivePhotoAssetWriting.swift`
  defines Live Photo writing protocols.
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/StillImageMetadataWriting.swift`
  defines still metadata writer abstractions.
- `Source/PhotoMemo/PhotoMemo/MediaPipelineVNext/MediaProcessingRoute.swift`
  defines routing protocol shape.

Composition root evidence:

- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:79` defines
  `AppEnvironment`.
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:126` builds the
  live environment.
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift:35` receives an
  `AppEnvironment`.

### Debt evidence

Large files:

- `PhotoMemoiOSV1View.swift`: 3405 lines
- `PhotoMemoShareExtensionViewController.swift`: 2624 lines
- `MemorySubjectEditorView.swift`: 1815 lines
- `PhotoMemoShareExtensionIntakeService.swift`: 1782 lines
- `RecordCardExportService.swift`: 1511 lines
- `ExternalPhotoIntakeStore.swift`: 1452 lines
- `PhotoMemoBackgroundStatusService.swift`: 1441 lines
- `ConfigurationCenteriOSView.swift`: 1413 lines
- `ConfigurationSession.swift`: 1316 lines
- `BatchQueueExecution.swift`: 1150 lines
- `SettingsService.swift`: 1035 lines

Singleton/fallback evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift:31`
  resolves App Group UserDefaults.
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift:46`
  resolves App Group container URL.
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:18`,
  `:33`, and `:55` use `ExternalPhotoIntakeCenter.shared`.
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift:68` uses the
  environment-owned intake center.
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:202` creates
  the live environment intake center.

Queue coupling evidence:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:6` is the queue
  observable store.
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:201` starts a
  processing task.
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:230` and
  nearby methods receive/mutate the store.

Runtime contract drift evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift:64` routes iOS
  to `PhotoMemoiOSV1View`.
- `Tests/PhotoMemoTests/ArchitectureTests/IOSRuntimeSurfaceContractTests.swift:17`
  expects `ConfigurationCenteriOSView(`.
- The test is gated with `#if os(iOS)`, so macOS test runs will not catch it.

## Ratings

| Dimension | Rating | Rationale |
|---|---|---|
| Product Architecture | A- | Product boundaries are clear and local-first principles remain intact. |
| Engineering Quality | B+ | Strong seams exist, but large orchestration files concentrate risk. |
| Maintainability | B+ | Maintainable with incremental extraction; risky if UI/queue/share keep growing. |
| Extensibility | B | Media and memory seams exist, but Video/HDR/RAW/Cloud Sync require stronger contracts. |
| Testability | B+ | Many modules are testable; App Group, runtime entry, and View mega-controllers are weaker. |
| Dependency Hygiene | A- | Core Renderer and Memory boundaries hold. Glue layers need cleanup. |
| Architecture Debt | B | Debt is real but localized and reducible without rewrite. |

## P0 Findings

No P0 architecture findings.

No evidence was found that:

- the app target cannot start
- renderer depends directly on repository/persistence
- memory engine depends directly on UI
- the current local-first product boundary is broken

## P1 Findings

### P1-01: App Group fallback hides Share Extension handoff failure

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift:31`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift:46`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:198`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:126`

Impact:

If App Group entitlement or provisioning fails in a distributed build, the Share
Extension can write into one fallback sandbox while the main app reads another.
The user may see a successful handoff while the main app never receives the
request.

Recommendation:

For Share Extension handoff paths, App Group resolution should be explicit and
diagnosable. Silent fallback can remain for tests or local development, but
production handoff should fail visibly or emit a readiness diagnostic.

Immediate fix?

Recommended before broad TestFlight distribution, or at minimum verified by a
real-device/TestFlight share handoff smoke test.

Long-term architecture?

Yes. Shared container readiness should become part of a platform capability
service rather than a static convenience fallback.

### P1-02: macOS AppDelegate bypasses runtime-owned intake

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:18`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:33`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift:55`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift:68`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:202`

Impact:

The app has two possible intake centers: singleton-owned and
environment-owned. If persistence succeeds, runtime can eventually drain from
the store. If persistence fails, the request can remain only in singleton
memory and never reach the runtime-observed intake center.

Recommendation:

Inject a runtime-owned intake router into AppDelegate or route AppDelegate URLs
through a single AppRuntime entry point.

Immediate fix?

Not an iOS TestFlight blocker. It is a P1 architecture debt for macOS and
long-term entry consistency.

Long-term architecture?

Yes. App entry events should enter the same intent/router boundary regardless
of platform.

### P1-03: iOS runtime contract test no longer matches root scene

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift:64`
- `Tests/PhotoMemoTests/ArchitectureTests/IOSRuntimeSurfaceContractTests.swift:17`

Impact:

The source of truth for the accepted iOS root surface has drifted. If iOS unit
tests begin running in CI, the contract will fail. If they do not run, the test
gives false confidence.

Recommendation:

Decide whether `PhotoMemoiOSV1View` is the accepted root for the current V1
line. If yes, update the contract test. If no, route root scene back to the
intended surface.

Immediate fix?

Recommended before relying on iOS architecture tests in CI. Not an archive-only
TestFlight blocker.

Long-term architecture?

No. This is a contract maintenance issue, not a deep architecture blocker.

## P2 Findings

### P2-01: Queue store and execution have two-way orchestration coupling

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:6`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:201`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:230`

Impact:

`BatchQueueStore` owns execution and UI-observable queue state, while execution
receives and mutates the store. This is not a circular import, but it is a
responsibility cycle.

Recommendation:

Move toward a reducer/event model:

- Execution returns `BatchQueueEvent` or task transitions.
- Store owns applying transitions.
- UI observes projections only.

Immediate fix?

No. Defer unless touching queue reliability.

Long-term architecture?

Yes. This is the biggest queue scalability and concurrency debt.

### P2-02: Composition root is useful but becoming a service registry

Evidence:

- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:5`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:39`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:61`
- `Source/PhotoMemo/PhotoMemo/Architecture/AppEnvironment.swift:126`

Impact:

`AppEnvironment.live()` constructs Settings, Photo Import, Render Export, Photo
Library, Batch Processing, External Intake, Snapshot Services, Repositories, and
Coordinators in one method. This is still understandable, but future Video/HDR
and sync services will make it harder to reason about dependency ownership.

Recommendation:

Keep `AppEnvironment` as the top-level composition root, but split construction
into capability builders:

- `StorageCapability`
- `MediaProcessingCapability`
- `ConfigurationCapability`
- `ShareIntakeCapability`
- `BackgroundProcessingCapability`

Immediate fix?

No.

Long-term architecture?

Yes. This should happen before adding major new media capabilities.

### P2-03: Large controller/view/service files concentrate release risk

Evidence:

- `PhotoMemoiOSV1View.swift`: 3405 lines
- `PhotoMemoShareExtensionViewController.swift`: 2624 lines
- `MemorySubjectEditorView.swift`: 1815 lines
- `PhotoMemoShareExtensionIntakeService.swift`: 1782 lines
- `RecordCardExportService.swift`: 1511 lines
- `ExternalPhotoIntakeStore.swift`: 1452 lines
- `ConfigurationSession.swift`: 1316 lines

Impact:

Large files are not automatically wrong, but these files sit on high-change
surfaces. Small fixes are likely to touch state, persistence, UI, and pipeline
logic at once.

Recommendation:

Extract by stable responsibilities, not by arbitrary size:

- V1 lifecycle and album loading coordinator
- Share Extension handoff monitor
- Share Extension preview loader
- Configuration draft model
- Export metadata writer facade

Immediate fix?

No, unless a P1 fix touches the same area.

Long-term architecture?

Yes. This is maintainability debt.

### P2-04: Service and repository APIs are only partially protocolized

Evidence:

- MediaPipelineVNext has explicit protocols for Live Photo loading, writing,
  metadata, and routing.
- Repository and coordinator containers primarily expose concrete classes such
  as `SettingsRepository`, `ConfigurationRepository`, `QueueRepository`, and
  `ShareCoordinator`.

Impact:

Current tests use injected concrete services and temporary UserDefaults suites
well, but future sync/cloud/offline replay will need stronger protocol seams
around repositories and persistence backends.

Recommendation:

Do not over-abstract everything now. Add protocols only at capability seams that
will soon need alternate implementations:

- Configuration persistence
- queue persistence
- external intake persistence
- photo-library writer
- media asset loader

Immediate fix?

No.

Long-term architecture?

Yes. Required before Cloud Sync or multi-store repository work.

### P2-05: Old and new iOS configuration surfaces coexist

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift:64` uses
  `PhotoMemoiOSV1View`.
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
  still exists as a parallel large configuration surface.
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift`
  can route to both surfaces.

Impact:

Two configuration surfaces can drift in state model, language, and behavior.
This is safe only if the old surface is explicitly marked internal/legacy and
kept out of production paths.

Recommendation:

Mark the non-production surface as legacy/internal, or create a single adapter
that feeds both from the same session/draft model.

Immediate fix?

No, if only `PhotoMemoiOSV1View` is exposed.

Long-term architecture?

Yes, before the next Configuration Center redesign or IA-003 integration step.

## Evolution Review

### Video

Readiness: **B**

The current MediaPipelineVNext concepts can grow toward video because routing,
planning, metadata writing, and Live Photo video composition seams already
exist. The blocker is that batch queue state and export result models are still
photo-output oriented. Video should enter through a new `MediaProcessingIntent`
variant, not by adding flags to existing photo task state.

### HDR / Wide Color

Readiness: **B-**

Export metadata preservation exists, but color policy is not a first-class
contract. HDR or P3 should not be bolted onto renderer constants. It needs a
media color policy layer shared by still export and Live Photo still
composition.

### RAW

Readiness: **C+**

The current pipeline can reject or down-convert unsupported input, but RAW
requires explicit decode, preview proxy, metadata retention, and output policy
decisions. This should be a separate media capability, not a small extension of
JPEG/HEIC import.

### Spatial Photo

Readiness: **C**

No current architecture evidence shows stereo/depth/multi-resource ownership
outside Live Photo pairing. Spatial Photo would need a generalized
multi-resource media asset model.

### AI Summary

Readiness: **B+**

Expression and Memory Engine layers provide a natural place for generated
memory summaries, but project rules require local-first behavior and user
control. AI Summary should be modeled as an optional provider feeding
Expression/Presentation, not as renderer text generation.

### Cloud Sync

Readiness: **C+**

The repository and persistence surfaces are local-first and UserDefaults-heavy.
That is appropriate for V1, but sync needs versioned records, conflict policy,
identity ownership, and explicit repository protocols. Do not add sync before
state and repository boundaries are hardened.

## API Design Review

Strengths:

- Many errors use `LocalizedError`.
- MediaPipelineVNext has clear protocol seams.
- AppEnvironment gives one obvious live construction entry.
- Coordinators already exist for share, queue, preview, export, and
  configuration.

Issues:

- Some APIs return `Void` while hiding persistence failure in lower layers.
- Some save APIs still accept defaults that can mutate production state
  incorrectly.
- Repository and service naming is mostly consistent, but ownership boundaries
  are mixed in `SettingsService`, `ConfigurationRepository`, and
  `ConfigurationSession`.
- Platform capability APIs are not yet explicit enough. App Group readiness,
  photo-library readiness, and external intake readiness are scattered.

Recommendation:

Introduce explicit API contracts only where errors and capabilities matter:

- `SharedContainerCapability`
- `ConfigurationPersistence`
- `QueuePersistence`
- `MediaProcessingCapability`
- `PhotoLibraryWriting`

Avoid broad protocolization of every service.

## Dependency Review

Boundary status:

- Renderer -> Repository: **clean**
- Renderer -> PhotoLibrary/UserDefaults: **clean**
- MemoryEngine -> UI: **clean**
- MemoryEngine -> Repository: **clean**
- MediaPipelineVNext -> Photos/FileManager: **expected platform boundary**
- Repository -> Service: **present and acceptable for current V1**
- View -> External Intake mutation: **present, P2**
- AppDelegate -> singleton intake: **present, P1**

Dependency direction is good in the core, weaker at entry/orchestration edges.

## Testability Review

Strengths:

- The project has a broad test surface across architecture, batch, export,
  metadata, memory, and media pipeline.
- Temporary UserDefaults suites are widely used in tests.
- MediaPipelineVNext protocols improve unit-test seams.

Weaknesses:

- iOS-only contract tests can be hidden by platform conditions.
- App Group fallback behavior is difficult to verify without real device or
  TestFlight smoke tests.
- Mega-views and mega-controllers are hard to isolate.
- Queue execution/store coupling makes deterministic concurrency tests harder.

Recommendation:

Add architecture contract tests for:

- accepted iOS root scene
- no renderer repository/persistence references
- MemoryEngine no UI references
- App Group readiness behavior
- queue persistence failure reporting

## Immediate Fixes

Recommended before broad TestFlight validation:

- Verify or harden App Group handoff readiness.
- Update the stale iOS root scene contract test.

Recommended when touching nearby code:

- Route macOS AppDelegate through runtime-owned intake.
- Remove `.shared` fallback from production V1 view construction paths.

## Long-Term Optimization

Recommended sequence:

1. Split AppEnvironment construction into capability builders.
2. Convert queue execution/store coupling to event application.
3. Extract Share Extension view model and handoff monitor.
4. Converge or explicitly retire duplicate iOS configuration surfaces.
5. Add protocol seams only where future capability variants are expected.

## Release Recommendation

For current iOS TestFlight:

**Conditional pass.**

This module does not reveal a new P0 blocker. The only architecture item that
can directly undermine iOS TestFlight validation is silent App Group fallback.
If Share Extension handoff is included in the validation story, verify it on the
signed distributed build or harden diagnostics first.

For long-term production:

**Do not add major new media or sync capabilities until queue, intake, and
configuration boundary hardening has begun.**
