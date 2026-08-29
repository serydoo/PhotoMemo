# MemoMark Engineering Optimization And Swift 6 Assessment

Date: 2026-08-28

Status: Evidence-backed assessment and migration baseline; implementation follow-up is recorded in `Docs/CURRENT_STATUS.md`

Baseline: `053abc96553b06572928a132fbeb91ed3acab613`, MemoMark `2.2.2 (95)`

## Scope And Decision Boundary

- Primary loop: Engineering Loop. The user requested an optimization inventory and an assessment of moving to Swift 6.4 after reviewing an external code-screening report.
- Evidence: same-commit local source/resource inspection, read-only GitHub API queries in this session, installed-toolchain inspection, and unsigned generic-iOS build probes.
- Owners: Xcode target configuration owns language mode; existing services own media execution; queue/receipt services own transaction recovery; Memory Engine and Layout Engine retain their frozen responsibilities.
- Source of truth: `PROJECT_CONSTITUTION.md`, `Docs/CURRENT_BRIEF.md`, the TX-001 contracts, current source, and the certification carryover recorded in `Docs/CURRENT_STATUS.md`.
- Apple capabilities evaluated: Swift compiler data-race checking, per-target language modes, PhotoKit resource/album resolution, native permission-string localization, and existing Xcode Cloud checks.
- Risk: P1 for migration/compatibility readiness. Subsequent changes to media truth, save receipts, durable data, or ownership require P0 review under the repository risk definitions. Compiler diagnostics are not proof of a reproduced user-data incident.
- Boundaries: no source-code, project-setting, dependency, deployment-target, signing, toolchain-installation, CI-configuration, or external release changes in this assessment. No simulator, Photos mutation, device installation, or memory-profiling campaign was run.

## Actual Toolchain And Language Mode

| Item | Observed value |
| --- | --- |
| Selected developer directory | `/Applications/Xcode-beta.app/Contents/Developer` |
| Xcode | `27.0`, build `27A5237l` — Xcode 27 Beta 5 |
| Compiler | Apple Swift `6.4`, `swiftlang-6.4.0.30.4` |
| Language mode | `SWIFT_VERSION = 5.0` |
| Default isolation | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| Approachable concurrency | `SWIFT_APPROACHABLE_CONCURRENCY = YES` |
| Strict checking | No explicit target-level `SWIFT_STRICT_CONCURRENCY` override in the project |
| iOS deployment target | `18.0` |
| macOS deployment target | `27.0` |

All six native targets have Swift 5 language mode, MainActor default isolation, and Approachable Concurrency in both Debug and Release: `MemoMark`, `MemoMarkiOS`, `MemoMarkShareExtension`, `MemoMarkWidgetExtension`, `MemoMarkTests`, and `MemoMarkDeviceQA`.

The compiler is already Swift 6.4. The migration under consideration is to **Swift 6 language mode**, using `SWIFT_VERSION = 6`/`6.0`, not a language-mode value of `6.4`. Language mode, compiler version, SDK version, and minimum deployment version are separate decisions.

As checked on 2026-08-28, Apple lists Xcode 27 Beta 6 (`27A5252f`, released August 24) with Swift 6.4; the latest non-beta row is Xcode 26.6 with Swift 6.3. The installed Beta 5 is not the latest beta. Updating beta versions must be verified separately from language-mode migration. Do not automatically switch this project to Xcode 26.6: existing macOS 27 and SDK/compiler dependencies require a compatibility assessment first.

Sources: [Apple Xcode requirements](https://developer.apple.com/xcode/system-requirements), [Apple releases](https://developer.apple.com/news/releases/), [Swift migration guide](https://www.swift.org/migration/), [enabling Swift 6 mode](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/enabledataracesafety/).

## Reproducible Build Probe

The same current source and selected toolchain were used throughout. All overrides were command-line-only. Outputs are local, temporary audit artifacts under `/tmp/MemoMarkSwiftAudit-20260828-au9c4c3c`; these paths are not durable repository dependencies.

```bash
xcodebuild \
  -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkiOS \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/MemoMarkSwiftAudit-20260828-au9c4c3c/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet build
```

Repeat with `SWIFT_VERSION=6.0 SWIFT_STRICT_CONCURRENCY=complete` for the Swift 6 probe, or `SWIFT_VERSION=5.0 SWIFT_STRICT_CONCURRENCY=complete` for the preparatory warning scan.

| Probe | Exit | Result |
| --- | --- | --- |
| Existing Swift 5 settings | `0` | PASS: unsigned generic-iOS Debug build; quiet log empty |
| Swift 6 mode + complete checking | `65` | FAIL: first located error in Share Extension module compilation |
| Swift 5 mode + complete checking | `0` | PASS WITH WARNINGS: 33 unique located warnings across 10 files |

The initial Swift 6 failure was `Models/PhotoProcessingInputPolicy.swift:30:28`:

```text
main actor-isolated default value in a nonisolated context
```

The nonisolated `standard` static initializer called `PhotoProcessingInputPolicy()` whose initializer inherited MainActor isolation. This repeats a boundary identified by the July 20 certification, but the present result was a fresh build, not reused historical evidence. A bounded follow-up changed that initializer to `nonisolated`; the next Swift 6 probe then reached the existing `PhotoKitLivePhotoAssetWriter` closure-sendability boundary. The project remains in Swift 5 language mode pending a complete, target-by-target migration.

Warnings are deduplicated by file, line, column, severity, and message. They are **not** 33 independently confirmed bugs or a complete count of Swift 6 migration errors. Eleven warning messages explicitly say they become errors in Swift 6 mode. The Swift 6 probe stops at a module error; the warning scan does not prove all remaining Swift 6 behavior or diagnostics.

| File | Unique warnings | Observed diagnostic family |
| --- | ---: | --- |
| `Models/PhotoProcessingInputPolicy.swift` | 1 | Nonisolated default value calls MainActor initializer |
| `iOS/ShareExtension/MemoMarkShareExtensionIntakeService.swift` | 5 | Nonisolated diagnostics access actor-isolated properties |
| `iOS/ShareExtension/ShareManagedFileImporter.swift` | 7 | Provider callbacks access actor-isolated cancellation, constructors, and diagnostics |
| `iOS/Views/V1IOSViewSupportComponents.swift` | 3 | UIKit override isolation and Sendable callback mismatch |
| `iOS/Activity/MemoMarkiOSLiveActivityDriverService.swift` | 5 | Sending Activity-related values risks data races |
| `MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift` | 1 | Sending a non-Sendable asynchronous save closure |
| `ConfigurationCenter/Editors/MemorySubjectEditorView.swift` | 8 | View/state isolation and Sendable callback mismatch |
| `Services/PhotoImportService.swift` | 1 | Global dispatch callback invokes actor-isolated synchronous import |
| `Services/PhotoLibraryExportService.swift` | 1 | Sending a non-Sendable asynchronous save closure |
| `MediaPipelineVNext/LivePhotoAssetLoading.swift` | 1 | Resource callback invokes actor-isolated diagnostic helper |

No macOS, Release, unit-test, or Device QA build was run for this probe. No tests were executed. No installed-device or performance acceptance is implied.

## Optimization Inventory

Priority indicates attention/risk, not authorization to change code. Each implementation needs a bounded specification and the evidence appropriate to its owner.

| Priority / disposition | Evidence-backed issue | Owning scope | Closure evidence |
| --- | --- | --- | --- |
| P0 carryover | TX-001 still has unresolved durable binding/recovery cases | Queue, PhotoKit receipts and reconciliation | Accepted failure-injection matrix plus scoped physical-device recovery evidence; superseding certification |
| P0 carryover, campaign stopped | BP-001 is not a memory-safety pass. Budget concurrency properties are currently referenced by diagnostics, not a budget-driven scheduler | Media execution and resource lifetime | Enforced single-task contract and accepted measurement evidence under a separately authorized scope; do not restart the stopped Instruments campaign automatically |
| P1 | Static full-resolution decode/composition/encoding is synchronous in MainActor `RecordCardExportPipeline` | Export execution, not layout or memory semantics | Explicit execution boundary, cancellation/ownership tests, unchanged output/readback, and physical responsiveness evidence |
| P1 | Swift 6 language mode does not build; complete checking exposes boundary warnings in 10 files | Shared source and six existing targets | Bounded fixes, complete-checking inventory, Swift 6 Debug/Release builds and tests, device lifecycle acceptance |
| P1 | Photos permission descriptions are Chinese-only; no InfoPlist localization resources found | Main App/macOS system-facing bundle resources | Four-language resource/build-bundle checks and physical first-authorization prompts; app-internal language preferences are not the system language authority |
| P1 media risk | Live Photo export re-fetches resource arrays and resolves the old descriptor via an index, without identity revalidation | PhotoKit resource adapter | Reordered/changed/ambiguous resource tests and edited/iCloud Live Photo device cases; preserve original assets |
| P1 engineering gate | Existing Xcode Cloud Archive check is not an enforced branch gate; test execution scope is not established | Existing CI and repository rules | Confirm cloud toolchain/Test actions; enforce approved required checks after authorization; retain physical acceptance separately |
| P1/P2 conditional | Automatic albums use title matching; missing explicit album ID falls back for static output but errors for Live Photo | Album selection and PhotoKit adapters | Agreed deletion/rename/duplicate-title/permission-loss semantics, tests, and physical acceptance |
| P2 | Localization usage audit has hand-maintained surface coverage and namespaced-only regex | Localization audit tests | Detect missing literal/dynamic keys without declaring existing Chinese keys invalid; preserve four-language parity |
| P2 integration assessment | Metadata policy scaffold is not a proven exhaustive production executor | Actual export writers and metadata contract | Map the real production paths first; define supported field/action/target semantics and file readback; do not fix an uncalled writer and claim production closure |
| P2, coupled to TX-001 | Single durable queue snapshot has no prior-generation disk recovery | Queue persistence and receipt lifecycle | Corruption plus external-commit reconciliation tests before any automatic fallback; retain safe startup blocking |
| P2 maintenance | Root view has 3,329 lines; device harness 2,177 lines; 9 tracked empty Swift files exist | Existing UI composition/tests/repository hygiene | Only bounded extraction/cleanup with dependency checks and existing regressions; no architecture rewrite |
| Deferred until product scope changes | Verified transactions for unknown product IDs are finished | Commerce ownership | Revisit before adding another product; no speculative marketplace/router expansion now |

### Evidence Pointers And Report Corrections

- MainActor work: `Services/RecordCardExportPipeline.swift:6,44,54`; current photo import already uses `Repositories/PhotoRepository.swift:34`, but its dispatch bridge has a fresh complete-checking warning. An off-main dispatch is not itself proof of a sound actor boundary.
- Budget descriptions: `Models/MediaAsset.swift:296`; consumption: `Services/BatchTaskDiagnosticsRecorder.swift:55`. Serial execution limits overlap but is not a measured per-task peak-memory ceiling.
- Permission strings: `MemoMarkiOS-Info.plist:39` and `MemoMark-Info.plist:33`.
- Live Photo identity: `MediaPipelineVNext/LivePhotoAssetLoading.swift:355,439`; kind/filename/UTI already exist in the descriptor. An added ordinal alone is not a stable identity contract.
- Album behavior: `Services/PhotoLibraryExportService.swift:1557` versus `MediaPipelineVNext/PhotoKitLivePhotoAssetWriter.swift:557`; automatic title is currently `时光记`.
- Metadata production route: `RecordCardExportPipeline -> MetadataPreservingImageWriter`. No production caller was found for `ImageIOStillImageMetadataWriter` or `StillImageMetadataWritePlanner`; tests do call them. Their incomplete operation handling does not establish a shipped GPS-removal failure.
- Queue atomic write/readback: `Services/BatchQueuePersistence.swift:87`; startup blocking: `Services/BatchQueueStore.swift:192`; reconciliation currently selects `.savingToPhotoLibrary` at `:755`. A readable old snapshot can still be stale relative to a committed Photos output.
- Localization: the report's three alleged missing translations exist in all four languages. Earlier in this session, 12/12 Foundation Bundle lookups succeeded; resource parsing found 1,437 keys per language with identical key sets. There are 406 non-namespaced keys per resource, not 406 confirmed bugs. This is not installed-iOS UI acceptance.
- GitHub read-only check: remote main matched the baseline; workflows/runs were zero, but Check Run `98775873693` from `xcode-cloud` succeeded for `PhotoMemoiOS | MemoMarkiOS | Archive - iOS` at `2026-08-28T06:42:03Z`. Branch protection was disabled, required checks empty, and effective rules empty. A summary of zero test failures does not prove a nonzero test run. [Commit checks](https://github.com/serydoo/PhotoMemo/commit/053abc96553b06572928a132fbeb91ed3acab613/checks).

## Proposed Migration Sequence

1. **Toolchain and CI baseline.** Record the actual local/cloud Xcode builds, SDKs, language modes and Test actions. Preserve the existing working archive route; build 94 already encountered a local/cloud Photos SDK mismatch, fixed in build 95. Evaluate Beta 6 as its own compatibility change, not together with migration or deployment-target changes.
2. **Complete checking while retaining Swift 5 mode.** Use this assessment's diagnostic inventory as the starting point. Triage shared value-model isolation, Share/PhotoKit callbacks, sendability, and UIKit overrides by their real owners. Each slice gets tests before behavior changes. Do not blanket-add `@MainActor`, `@unchecked Sendable`, `nonisolated(unsafe)`, or broad `@preconcurrency` just to silence diagnostics.
3. **Bounded media execution isolation.** Keep UI/queue state on its owner and pass frozen, explicitly safe inputs to off-main execution. `SelectedPhoto` includes a platform image and `[CFString: Any]`; do not blindly send the entire object across an actor boundary. No change to memory meaning, layout truth, original assets, or receipt identity. This can accompany relevant diagnostic fixes, but is a separately verified behavior change.
4. **Enable Swift 6 per existing target dependency.** Shared sources are compiled into multiple targets, so validate all affected consumers before toggling one target. This does not require extracting new Swift packages. Confirm Swift 6 builds for App, extensions, unit tests and device QA, in Debug and Release. Complete checking is mandatory in Swift 6, not an optional weaker setting.
5. **Runtime and release evidence.** Run unit/contract tests, signed iPhone 17 Pro Max Share/Photos/recovery/UI acceptance, and actual cloud archive/tests. Verify callbacks, cancellation, late completion and TextKit input behavior. The migration must not claim to close TX-001, BP-001, metadata fidelity or production certification merely because the compiler succeeds.

Permission localization and localization coverage are independent small work items; root cleanup and commerce expansion should not be mixed into the language migration. Prefer improving the existing Xcode Cloud workflow over adding a second CI platform without a demonstrated need.

## Recommendation

Adopt Swift 6 language mode as a dedicated, staged engineering objective. Do not replace every `5.0` with `6.4`, upgrade all APIs, raise deployment targets, change default isolation globally, or rewrite the architecture in one pass. The current compiler is already 6.4; the concrete remaining work is explicit isolation/sendability and verified runtime behavior.

The V4 stage and `FAIL (Conditional)` production certification remain unchanged. This assessment and its build probes do not authorize implementation, installation, commit, push, CI mutation, TestFlight upload, or App Store submission.
