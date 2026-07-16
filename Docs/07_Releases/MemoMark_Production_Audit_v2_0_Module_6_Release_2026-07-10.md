# MemoMark Production Audit v2.0 Module 6

Module: Release Audit

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Scope

This module reviews:

- TestFlight readiness
- performance and memory risk
- concurrency and actor usage
- Live Photo release gating
- Share Extension intake scale
- error observability
- release hygiene and user-facing capability wording

No production code was modified during this module review.

## Executive Assessment

Rating: **Conditional TestFlight Validation Yes**

MemoMark is suitable to proceed as a controlled TestFlight validation candidate
focused on still-image and small-batch flows, with main-app picker Live Photo
described as a release candidate. This does not mean TestFlight distribution has
already completed. It is not ready to advertise broad 48MP reliability, robust
Live Photo support across Share Extension, 100-batch confidence, or a fully
production-grade media pipeline.

No confirmed P0 was found. The highest risks are P1 release-governance and
runtime-envelope issues: MainActor overuse, 48MP memory pressure, unclear Live
Photo runtime gate naming, no Share Extension count cap, and capability wording
drift.

## Evidence

- Current repository state before report generation:
  - `main...origin/main`
  - only audit docs untracked
- `xcodebuild -list` succeeds and lists:
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
  - `PhotoMemoWidgetExtension`
  - `PhotoMemoTests`
- iOS version/build:
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj:660`
  - `MARKETING_VERSION = 1.5`
  - `CURRENT_PROJECT_VERSION = 7`
  - bundle `com.serydoo.PhotoMemo.iOS`
- Prior release archive dry-run passed and is documented in:
  - `Docs/CURRENT_STATUS.md`
  - `HANDOFF.md`
- Unsigned IPA from earlier stabilization pass:
  - `<local-build-path>`
- Not yet proven by this audit:
  - signed upload to App Store Connect
  - App Store Connect processing completion
  - TestFlight installation
  - signed-build Share Extension App Group handoff

## Ratings

| Dimension | Rating | Rationale |
|---|---|---|
| Performance | C | Good enough for small smoke; large images remain risky. |
| Concurrency | C- | Processing is over-bound to MainActor. |
| Memory Usage | C- | 48MP policy exists without real peak enforcement. |
| Error Observability | C | Several important failures are swallowed or weakly surfaced. |
| Release Hygiene | C | Capability wording and gates need alignment. |
| TestFlight Readiness | Conditional | Suitable to enter validation only with narrow scope and known limitations. |

## P0 Findings

No confirmed P0 findings.

No evidence was found of:

- app startup blocker
- original photo mutation
- photo upload
- guaranteed unrecoverable data loss

Conditional P0:

If release notes claim robust Share Extension Live Photo or large-batch Live
Photo support, the claim is unsupported and should block that release wording.

If release notes claim TestFlight has already shipped, that also exceeds current
evidence. Current evidence supports local archive readiness and unsigned IPA
generation, not App Store Connect processing completion.

## P1 Findings

### P1-01: Processing chain is over-bound to `@MainActor`

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:6`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift:212`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:45`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift:74`
- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:51`

Impact:

Heavy rendering, PhotoKit, Live Photo orchestration, and queue execution share
MainActor pressure with UI state. This can produce UI stalls and makes
concurrency behavior hard to reason about.

Immediate fix?

Not required for a very small TestFlight smoke, but it blocks confidence in
large batch or long Live Photo processing.

### P1-02: 48MP memory risk is not bounded by runtime scheduling

Evidence:

- `Source/PhotoMemo/PhotoMemo/Models/PhotoProcessingInputPolicy.swift:39`
- `Tests/PhotoMemoTests/ExportTests/MediaMemoryBudgetTests.swift:104`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:143`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:254`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:1065`

Impact:

The policy allows approximately 48.8MP stills. Tests acknowledge roughly 195MB
decoded size. Export can allocate rendered output, source image, and full RGBA
buffers. The memory budget exists as model/test coverage but not as an
execution scheduler.

Immediate fix?

Required before claiming 48MP reliability. For narrow TestFlight, scope out
large-image confidence.

### P1-03: Live Photo default runtime gate uses `internalTesting` naming

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/LivePhotoBatchTaskProcessor.swift:77`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:82`

Impact:

The default production instantiation uses a gate named `internalTesting` with
Photo Library writes enabled. This is a release governance problem even if
runtime behavior is intentional.

Immediate fix?

Recommended before external TestFlight wording is finalized.

### P1-04: Share Extension intake has no explicit count cap

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:722`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:253`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift:382`

Impact:

Main app picker caps selection at 24. Share Extension appears to process all
supported providers sequentially. Large shares can stress memory, time, and
background execution limits without a user-facing admission policy.

Immediate fix?

Recommended before broad TestFlight if Share Extension is part of the
advertised workflow.

### P1-05: User-facing Live Photo wording conflicts with implementation state

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift:166`
- `Tests/PhotoMemoTests/BatchTests/LivePhotoBatchQueueExecutionTests.swift:11`

Impact:

Settings copy says Live Photo is outside V1.5 / entering V1.6, while tests and
runtime indicate main-app picker Live Photo can process through the internal
pipeline. Users and testers will not know what to validate.

Immediate fix?

Yes. Release notes and in-app wording must match the supported scope.

## P2 Findings

### P2-01: `try?` reduces observability

Evidence:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:659`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift:711`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:943`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift:795`

Classification: near-term maintenance.

### P2-02: Background expiration lacks cancellation/checkpoint strategy

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSBackgroundExecutionService.swift:70`

Classification: future capability blocker.

### P2-03: `BatchPipelinePolicy` concurrency settings are not active

Evidence:

- `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift:176`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueExecution.swift:240`

Classification: long-term architecture.

## Architecture Debt

The release pipeline is still shaped like:

```text
UI/MainActor store -> services -> PhotoKit/export side effects
```

The desired long-term shape is:

```text
bounded processing actor -> import/render/write lanes -> MainActor status publication
```

The memory budget is documented and tested, but not yet an admission-control or
scheduling boundary.

## Evolution Review

Do not expand advertised feature scope until:

- Live Photo release gates are named and scoped clearly
- Share Extension intake has admission limits
- 48MP and large-batch behavior have measured envelopes
- background expiration has a recovery strategy

## API Design Review

PhotoKit write APIs are wrapped, but services are still `@MainActor`. Future API
shape should separate PhotoKit execution from UI status publication.

## Dependency Review

The main external uncertainty remains Apple platform behavior:

- `PHPicker`
- `NSItemProvider`
- iCloud-backed Live Photo resource export
- PhotoKit background write timing
- Share Extension memory/time limits

## Testability Review

Strong:

- Live Photo routing tests
- oversized input tests
- 48MP memory budget tests
- metadata writer contract tests

Missing:

- 100-provider Share Extension intake test
- 48MP end-to-end memory envelope measurement
- background expiration recovery test
- real-device/TestFlight Live Photo smoke

## Immediate Fixes

- Align release and settings wording with actual Live Photo scope.
- Complete a signed distribution-chain smoke before marking TestFlight shipped:
  archive, export/upload, App Store Connect processing, TestFlight install, and
  launch.
- Add an explicit Share Extension intake cap or admission policy.
- Clarify Live Photo runtime gate naming for production.
- Add observability for metadata patch and cleanup failures.
- Run focused build/test/archive verification after any code fixes.

## Long-Term Optimization

- Introduce a processing actor with bounded lanes.
- Make `MediaMemoryBudget` drive scheduling and batch admission.
- Add release profiles: still-only, Live Photo RC, large-batch disabled/enabled.
- Move export/render/Live Photo heavy work off MainActor where possible.

## Release Recommendation

Conditional Yes for validation candidate.

Proceed only as a limited TestFlight candidate for still-image and small-batch
flows, with main-app picker Live Photo labeled release candidate and Share
Extension Live Photo explicitly scoped out. Do not state that TestFlight has
already shipped until signed upload, processing, install, and smoke verification
are complete.
