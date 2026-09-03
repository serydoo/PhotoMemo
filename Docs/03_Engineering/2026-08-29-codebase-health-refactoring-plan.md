# Implementation Plan: MemoMark Codebase Health Refactoring

- Program spec:
  `Docs/03_Engineering/2026-08-29-codebase-health-refactoring-program.md`
- Baseline: `2.2.3 (100)`, `main @ 0954bea`
- Status: Current refactor slice closed; observation follow-ups deferred

## 2026-09-03 Refactor Closeout And Observation Mode

The behavior-preserving source reorganization for `2.2.4 (101)` is now closed
for continued real-world use. The user has confirmed that the relevant manual
checks are broadly passing, including the output-album visual/playback check.
No new feature work or broad structural decomposition is authorized by this
closeout.

The following remain deliberately deferred rather than falsely marked as
complete:

- reproducible full macOS test execution when the Xcode 27 test-host runner
  stalls or cancels;
- the TX-001 interruption/readback/receipt-failure matrix;
- BP-001 Instruments measurements for main-thread work and memory;
- formal superseding production certification;
- final compatibility-alias cleanup under Task 7.4.

These are observation-mode engineering follow-ups. If continued use reveals a
real regression, reopen only the smallest affected slice with a focused
reproduction and verification plan. Do not resume a repository-wide rename or
another large presentation split merely because a file remains long.

## Architecture Decisions

- Refactor by owner and lifecycle, not by line-count target.
- Keep the application behavior identical during structural slices.
- RFC-002 and ADR-011 permit `ConfigurationSession`, `PhotoLibraryExporting`,
  and `BatchQueueStore` to become migration facades and eventually be replaced;
  one configuration, queue, receipt, memory, and media truth must exist at
  every step.
- Preserve Memory Engine meaning, Layout Engine geometry, Renderer/artifact
  behavior, durable formats, and Apple Photos guarantees while concrete types
  and dependency boundaries migrate.
- Prefer focused application transactions and narrow platform ports over new
  generic abstractions or one-to-one forwarding coordinators.
- Change source-contract tests before deleting retired source, so every step
  remains buildable and reviewable.
- Run iOS Simulator neither as a build target nor as visual evidence.
- Replace active `V1` names with stable responsibility names. Reserve
  `SchemaV1`/`LegacyV1` for real compatibility formats and preserve stored
  strings and raw values.

## Phase 1 — Retired Surface And Support Components

### Task 1.1: Record the dependency and test classification

- [x] Classify every reference to `ConfigurationCenteriOSView.swift` as active
      product behavior, active shared contract, or retired implementation.
- [x] Identify active types inside `ConfigurationCenterViewSupportComponents.swift` and
      confirm the unused boundary of `V1SlotATextKitEditor`.
- Acceptance: every planned deletion or move has a caller/test map and an
  explicit replacement owner.
- Verify: repository-wide `rg`, Xcode project/target inspection, and diff review.
- Files: program spec, implementation plan, no production source.

Dependency classification recorded on 2026-08-29:

| Reference | Classification | Migration action |
| --- | --- | --- |
| `MemoMarkRootSceneView -> MemoMarkiOSV1View` | Active runtime root | Preserve; no runtime call to `ConfigurationCenteriOSView` was found |
| `ConfigurationCenteriOSView` self `#Preview` | Retired implementation-only construction | Removed with the retired file |
| `ActiveLocalizationUsageAuditTests` allowlist | Retired file-list entry | Remove; `MemoMarkiOSV1View` and current sub-surfaces already remain in the active allowlist |
| `MemoMarkSymbolCatalogContractTests` joined source set | Duplicated implementation source | Remove retired path; semantic symbols remain asserted across active option/accessory/subject surfaces |
| `IPhoneResponsiveLayoutContractTests` viewport list | Retired page contract | Remove retired path; active primary pages and editor keep the viewport contract |
| `V1SettingsDisclosureContractTests` settings-tail assertion | Retired parent implementation detail | Assert Settings-owned workflow presentation directly from `V1SettingsPageSurface` and `V1WelcomePresentation` only |
| `AppleNativeProductSurfaceContractTests` center-name assertion | Retired type-name implementation detail | Preserve active object hierarchy assertions in `V1ConfigurationOptionList` and preview surfaces; remove the retired type-name check |
| `ConfigurationCenterLocationDisplaySupportTests` saved-summary and picker assertions | Mixed: pure support behavior is active, retired parent wiring is not | Preserve pure `ConfigurationCenterLocationDisplaySupport` tests and move wiring assertions to the active `MemoMarkiOSV1View` path; remove duplicate retired wiring checks |
| `iOS/Views/README.md` map | Stale repository map | Update when the retired source is deleted |
| Xcode project membership | Filesystem-synchronized group; no explicit file reference | Deletion is picked up automatically, but generic iOS and macOS builds remain mandatory |

`ConfigurationCenterViewSupportComponents.swift` classification:

- Generic card chrome/surface types are active across current iOS views.
- `MemoryCardPreviewSurface` is active through `MemoryCardPreviewSection`.
- `V1RegionEditorCard` is active through `V1RegionEditorCluster`.
- `V1InlineTextField`, `V1TextKitModuleAttachment`, and related UIKit support
  are active through the current editor/session path.
- `V1SlotATextKitEditor` has no construction or symbol reference outside its
  declaration. Its exact declaration can be removed without removing the
  neighboring active attachment type.

### Task 1.2: Migrate the first retired-surface test group

- [x] Move localization, symbol, and location assertions from the retired file
      to the active owner or remove only implementation-only duplication.
- Acceptance: the same active product contract remains covered without reading
  `ConfigurationCenteriOSView.swift`.
- Verify: focused localization/symbol/location suites.
- Expected files: up to three test files and, only if needed, one active source
  contract file.
- Dependency: Task 1.1.

### Task 1.3: Migrate the second retired-surface test group

- [x] Move responsive, settings-disclosure, and Apple-native assertions from
      the retired file to active surfaces.
- Acceptance: no test reads `ConfigurationCenteriOSView.swift`; no legitimate
  runtime contract is lost.
- Verify: focused responsive/settings/Apple-native suites.
- Expected files: up to three test files.
- Dependency: Task 1.2.

### Task 1.4: Delete the retired iOS surface

- [x] Reconfirm no production or test call/reference.
- [x] Delete `ConfigurationCenteriOSView.swift`.
- Acceptance: active iOS root remains `MemoMarkiOSV1View`; no retired
  Configuration Center architecture returns.
- Verify: focused architecture tests, complete tests, generic iOS build,
  required macOS build, governance, and diff checks.
- Files: one production deletion plus status record.
- Dependency: Task 1.3.

### Task 1.5: Remove the unused legacy TextKit editor

- [x] Remove only `V1SlotATextKitEditor`.
- [x] Preserve `V1TextKitModuleAttachment`, inline text fields, and the current
      `V1TextKitEditorSession` path.
- Acceptance: no active editor, caret, attachment, IME, selection, or undo
  implementation changes.
- Verify: editor line-box, responsive editor, and TextKit lifecycle suites;
  generic iOS build.
- Files: `ConfigurationCenterViewSupportComponents.swift` and status record.

### Task 1.6: Split support components by established responsibility

- [x] Confirm the remaining generic page/card surface and chrome types form one
      cohesive primitive catalog; do not split them solely to reduce line count.
- [x] Extract preview-card types.
- [x] Extract region-editor/UIKit support types.
- Acceptance: no state owner, constant, accessibility behavior, or input
  geometry changes; the original support file is removed or becomes a narrow
  index only if it still has a cohesive purpose.
- Verify after each extraction: relevant focused tests and generic iOS build.
- Expected scope: one source move per increment, no more than five files.
- Dependency: Task 1.5.

### Phase 1 Checkpoint

- [ ] Complete `MemoMarkTests` passes. Runtime suites execute after rebuilding
      the host and test bundle in one DerivedData, but source-contract suites
      that read the repository through `#filePath` hang in the app-hosted Xcode
      27 beta runner. They compile and the affected assertions were checked
      statically; the hanging runs are not counted as passes or code failures.
- [x] Required macOS and generic iOS builds pass.
- [x] Governance and `git diff --check` pass.
- [x] Five-axis code review finds no unresolved correctness or architecture
      issue.
- [x] No physical-device pass is claimed for pure source movement; if any UI
      behavior changes unexpectedly, the slice is reclassified as P1 and must
      receive iPhone acceptance.

Phase 1 structural outcome on 2026-08-29:

- Removed the 1,778-line retired `ConfigurationCenteriOSView.swift`; the active
  runtime root remains `MemoMarkiOSV1View`.
- Removed the unreferenced `V1SlotATextKitEditor`, its private text-view class,
  and an unreferenced private `CardRegion` symbol helper while preserving the
  active `V1TextKitEditorSession` and `V1TextKitModuleAttachment` path.
- Moved `MemoryCardPreviewSurface` into `MemoryCardPreviewSurface.swift` and the region editor/UIKit
  support into `V1RegionEditorSupport.swift` without changing declarations,
  constants, state, geometry, or accessibility behavior.
- Reduced `ConfigurationCenterViewSupportComponents.swift` from 2,001 to 825 lines. Its
  remaining declarations share one role: reusable iOS page, card, panel, and
  compact-action presentation primitives.
- Updated source-contract tests to read active owners. No production or test
  reference to the retired surface or editor remains.

## Phase 2 — iOS Root Responsibility Convergence

### Task 2.1: Freeze a root responsibility map

- [x] Map every root state group, dependency, intent, asynchronous operation,
  completion identity, and existing test seam.
- [x] Identify business flow still implemented directly in the SwiftUI root.
- Acceptance: proposed moves name the existing destination owner and do not
  create a parallel state container.

### Task 2.2: Extract subject-persistence orchestration

- [x] Add behavior tests for delayed save, later edit, failure, retry, and stale
      completion before moving orchestration.
- [x] Replace `V1SubjectPersistenceRequestGate` with one runtime coordinator
      that owns latest-request-wins sequencing and removes the retired gate.
- Acceptance: the root dispatches an intent and applies an explicit patch;
  user-facing status behavior remains stable, while queued candidates inherit
  the preceding successful receipt revision required by repository stale-write
  protection.
- Risk: P1, elevated to P0 if durable aggregate semantics change.

Task 2.2 outcome on 2026-08-29:

- `V1SubjectPersistenceRuntimeCoordinator` now serializes subject aggregate
  writes and publishes only `.queued`, `.saving`, or an explicit completion.
  It does not own subjects, presets, the configuration aggregate, navigation,
  or preview state.
- The root still performs the established legacy subject-library projection,
  creates the current aggregate candidate, and applies the returned durable
  candidate/status to `ConfigurationSession` and UI lifecycle state.
- Review confirmed the repository rejects a candidate whose revision does not
  match the stored aggregate. The retired gate discarded the successful first
  receipt when a newer edit was queued, so the next candidate could retain a
  stale revision. The runtime coordinator now rebases only the queued latest
  candidate onto that successful receipt revision; stale validation remains
  enabled and the durable schema is unchanged.
- A queued edit that returns to the pre-save baseline is still written after an
  intermediate save, preventing the intermediate subject state from becoming
  durable by mistake.
- Seven coordinator tests cover no-op, durable receipt, delayed newer edits,
  revert-to-baseline, stale failure, compatibility warning, and retry. Together
  with subject library and selection suites, 26 focused tests pass.

### Task 2.3: Extract media-selection and photo-intake orchestration

- [x] Keep picker presentation in SwiftUI and move processing orchestration to
      the established intake/application boundary.
- [x] Cover cancellation, empty selection, stale completion, and failure.
- Acceptance: no Photos permission, original-media, output, or Share workflow
  change.
- Risk: P1.

Task 2.3 outcome on 2026-08-29:

- `V1PhotoIntakeRuntimeCoordinator` now owns only one active quick-action
  request identity and the save-snapshot -> import -> submit ordering. Picker
  presentation remains in SwiftUI, durable submission remains in
  `ExternalPhotoIntakeCenter`, and configuration truth remains in
  `ConfigurationSession`/the configuration coordinator.
- A newer or cancelled request cannot submit or publish an older delayed
  completion. Imported-but-unsubmitted temporary picker copies are discarded
  only when they are descendants of MemoMark's own `MemoMarkV1Picker`
  temporary directory; Apple Photos originals and unrelated URLs are never
  deleted.
- Fourteen photo-intake tests now cover snapshot freezing, save failure, empty
  import, explicit cancellation, task cancellation and reuse, newer-request
  supersession, supported input, temporary copy, and cleanup containment.

### Task 2.4: Extract logo lifecycle and pure projection helpers

- [x] Separate asynchronous logo identity/cancellation from pure preview/module
      projection in independent increments.
- Acceptance: one canonical logo asset state, stale results rejected, preview
  output unchanged.
- Risk: P1.

Task 2.4 outcome on 2026-08-29:

- `V1LogoAssetRuntimeCoordinator` owns active optimization identity,
  cancellation, subject/configuration context validation, and stale asset
  cleanup. The root remains the only applier of explicit `LogoAssetUpdate`
  patches and no longer stores a duplicate active request in presentation
  state.
- `PreviewDraftAdapter` now directly bridges every
  `IOSInsertableModule` through the canonical preview composition engine for
  both editor-item and display-text projection. The redundant raw-value
  conversion and unreachable root fallback were removed.
- Eleven Logo coordinator tests and one all-modules preview projection test
  pass, including delayed cancellation and newer-request supersession.

### Task 2.5: Extract output-album loading lifecycle

- [x] Move request identity and stale-completion suppression out of the output
      draft and SwiftUI root.
- [x] Preserve `ExportCoordinator` as the album-reading boundary and keep the
      output draft as the only live album presentation projection.
- Acceptance: loading, failure, selection retention, context changes, task
  cancellation, and newer-request behavior remain stable; no PhotoKit write or
  durable configuration behavior changes.
- Risk: P2, elevated to P1 if output selection semantics change.

Task 2.5 outcome on 2026-08-29:

- `V1OutputAlbumRuntimeCoordinator` now owns only the active request UUID and
  rejects Task-cancelled, superseded, or subject/configuration/output-context
  mismatched results. An older request cannot clear a newer request's loading
  state.
- `V1OutputDraftState` no longer mirrors generation or active request identity;
  it continues to own available albums, selected album, loading, and status
  presentation values.
- Four runtime lifecycle tests, one context identity test, and four existing
  album projection tests pass. Required macOS and generic iOS builds pass.

### Phase 2 Checkpoint

- [x] Root remains the active Configuration Center composition surface.
- [ ] Complete tests and required builds pass. Sixty-six focused runtime
      tests, the test-target build, required macOS build, and generic iOS build
      pass. Source-contract suites that read repository files remain affected
      by the recorded Xcode 27 app-hosted runner hang and are not counted as
      executed passes.
- [ ] Signed iPhone 17 Pro Max install/launch and Configuration Center manual
      acceptance pass. The user's preceding Task 2.2 object-editing check
      reported no issue, but the exact combined Slice 2-4/avatar build still
      requires installation and crop-screen acceptance. An Apple Development
      signed `2.2.3 (100)` package passed strict code-sign verification at
      `/tmp/MemoMarkSlice234Device/Build/Products/Debug-iphoneos/MemoMarkiOS.app`,
      but the paired device was unavailable at the current checkpoint.
- [x] State/persistence review finds no second source of truth.

## Phase 3 — Memory Subject Editor Responsibility Convergence

### Task 3.1: Freeze one draft/transaction contract

- [x] Add or strengthen behavior tests for load, edit, cancel, save, selection,
  and object switching.

### Task 3.2: Extract display-focused identity and anchor sections

- [ ] Pass bindings and explicit intents only; do not duplicate subject state.
- [ ] Preserve Dynamic Type, localization, accessibility, and keyboard behavior.

Progress checkpoint on 2026-08-31:

- The pure time-anchor policy portion is now draft-owned: default anchor
  construction, cardinality limits, add/remove mutation, and selection
  fallback no longer live in `MemorySubjectEditorView`.
- The remaining work is the display-section extraction itself. It must keep
  bindings, focus ownership, and existing source-contract coverage intact;
  this checkpoint does not claim the task complete.

### Task 3.3: Isolate avatar media lifecycle

- [ ] Cover request identity, cancellation, stale result rejection, optimization
  failure, crop completion, and asset removal.
- [ ] Keep avatar media local and preserve all existing resource outputs.

Progress checkpoint on 2026-08-31:

- `MemorySubjectEditorView` now depends on the narrow
  `SubjectAvatarAssetOptimizing` capability instead of constructing against a
  concrete optimizer type. `SubjectAvatarAssetOptimizationService` remains the
  production adapter and its atomic three-resource output is unchanged.
- Request identity, crop presentation, stale-result rejection and local asset
  cleanup remain behaviorally unchanged and are still the next extraction
  boundary; this checkpoint does not claim the task complete.

### Phase 3 Checkpoint

- [ ] Complete tests and required builds pass.
- [ ] Physical iPhone object editing, anchors, PhotosPicker, crop, keyboard,
  VoiceOver, and localization acceptance pass.

## Phase 4 — PhotoKit And Queue Boundary Decomposition

### Task 4.1: Separate pure save and receipt policy compilation units

- [ ] Move policies/store/gate without changing behavior or public contracts.
- [ ] Run existing receipt and queue regression suites after each move.

Progress checkpoint (2026-08-31): pure receipt and ambiguous-commit policies
were moved into `PhotoLibrarySavePolicies.swift`; the store now focuses on
persistence and recovery. The focused receipt/queue regression run after this
move is the next verification gate.

### Task 4.2: Close runtime collaborator boundaries under TX-001

- [ ] Specify album, static writer, exact-identifier read-back, cancellation,
  and recovery ownership before extraction.
- [ ] Use failure injection and signed-device interruption evidence.

Progress checkpoint (2026-08-31): static and Live Photo batch routes now share
the composition-root-owned `BuildRecordCardTransaction`; the Live Photo
processor and `BatchProcessingCoordinator` no longer create a direct card-build
service path. This closes a production dependency-direction gap, but TX-001
device interruption/read-back evidence and the remaining PhotoKit collaborator
extraction are still open.

### Task 4.3: Extract startup receipt reconciliation behind ADR-002 facade

- [ ] Keep `BatchQueueStore` as the single migration facade until the
      actor-backed queue runtime is authoritative; never run two queue owners.
- [ ] Preserve persist-before-cleanup ordering and idempotent recovery.

### Phase 4 Checkpoint

- [ ] TX-001 evidence matrix is complete or remaining gaps are explicit.
- [ ] Renderer/export read-back and Apple Photos lifecycle pass on the paired
  physical iPhone.
- [ ] No duplicate output or original-asset mutation is observed.
- [ ] No production-certification claim is made without a superseding audit.

## Phase 5 — Final Health Gate

### Task 5.1: Review remaining large files by responsibility

- [ ] Record why each remaining file over 1,000 lines is cohesive or create a
  bounded follow-up task.

Progress checkpoint (2026-08-31): the active Configuration Center root now
uses responsibility-based names for its four root-owned state containers;
legacy `V1...` spellings are compatibility aliases only. The root remains
structurally large and still requires bounded presentation-section extraction.

### Task 5.2: Reduce fragile source contracts

- [ ] Replace source layout assertions with behavior/state tests where an
  executable seam exists.

### Task 5.3: Run final cross-cutting quality and release-readiness review

- [ ] Accessibility, localization, performance, physical-device fit, Git state,
  and release evidence are classified separately.
- [ ] `Docs/CURRENT_STATUS.md` records the completed program and remaining
      maintenance gates.

## Phase 6 — RFC-002 Core Architecture Migration

### Task 6.1: Freeze behavioral and compatibility contracts

- [ ] Add configuration schema, queue transition, presentation artifact, save
      receipt, App Group key, and output parity fixtures.
- [ ] Record the feature-preservation matrix evidence and physical-device gaps.

### Task 6.2: Establish application transaction and composition boundaries

- [x] Introduce typed immutable command/result/event conventions.
- [ ] Remove blanket main-actor ownership from non-UI dependency construction.
- [x] Migrate one read-only transaction before moving durable authority.

### Task 6.3: Migrate configuration core

- [ ] One editing draft aggregate and explicit save/load/restore transactions.
- [ ] Preserve aggregate revision, compatibility projection and saved bytes.

Task 6.3 partial outcome on 2026-08-30:

- Active configuration projection, aggregate-save, candidate and candidate
  builder types now use stable responsibility names; the Production save,
  bootstrap, Settings, reconciliation and Configuration Center callers no
  longer carry the obsolete stage prefix.
- Existing candidate construction, revision checks and compatibility projection
  tests remain the behavior gate. The affected regression suites now use the
  stable type names directly; no test-target or Production compatibility
  spelling remains for this configuration-draft family.
- The broader explicit Configuration Center save/load/restore transaction
  convergence remains open. This naming slice does not claim that work closed.

Task 6.3 restore-transaction outcome on 2026-08-31:

- `RestoreConfigurationLibraryTransaction` now owns serialized configuration
  restore admission, signed-document and managed-asset validation, rollback of
  newly copied assets on failure, candidate assembly and durable receipt
  reconciliation. `ConfigurationBackupRestoreCoordinator` retains only
  presentation feedback and backup-list refresh behavior.
- The new direct transaction test and the existing restore/import regression
  suites preserve first-restore current selection, copy restoration, receipt
  revision authority, resource rollback and serialized concurrent restoration.
  The broader editing-draft and bootstrap load convergence remains open.

Task 6.3 bootstrap-load transaction outcome on 2026-08-31:

- `LoadConfigurationBootstrapTransaction` is now built by the composition
  root from the narrow Settings repository capability and injected into the
  active Configuration Center. Startup reads no longer travel through the
  Configuration Coordinator or former load Intent production path.
- The Bootstrap Adapter remains the sole owner of the established safe default
  presentation fallback. The transaction returns canonical bootstrap data or a
  typed read failure without choosing a fallback or writing durable state.
- Focused transaction/bootstrap/migration/subject-library tests and the
  generic iOS build pass. The broader editing-draft and explicit legacy
  bootstrap-adapter convergence remains open.

Task 6.3 composition-root save and production-snapshot outcome on 2026-08-31:

- `SaveConfigurationTransaction` is now composed in `AppEnvironment` and
  injected through the root scene into the Configuration Center. The View no
  longer constructs a save transaction; aggregate-first persistence and the
  explicit `applyLegacyCompatibility` adapter still share that one owner.
- `LoadProductionConfigurationSnapshotTransaction` now performs the canonical
  post-save snapshot read through `ConfigurationRepository`. The View no
  longer constructs `SettingsService`, while the existing durable-save ->
  snapshot-load -> Intake default-update ordering remains unchanged.
- The direct architecture contract, complete macOS test suite (`1678 / 0 / 1`)
  and macOS, generic iOS and Share Extension Debug builds pass. Physical iPhone
  acceptance remains deferred to the final unified device pass.

### Task 6.4: Migrate queue core

- [x] Pure transition policy plus actor-backed durable runtime/ledger.
- [x] Task executor emits events/outcomes and cannot mutate the queue facade.
- [x] Preserve persist-before-cleanup, recovery, commerce and notifications on
      the current single-authority path after actor-ledger cutover.

Task 6.4 outcome on 2026-08-30:

- `BatchQueueDurableLedger` now owns every runtime queue commit. The
  `BatchQueueStore` projection changes only after durable success and blocks
  processing on persistence failure.
- Admission, retry, cancellation, recovery, executor events, background
  expiration, notification markers and history retention share this path.
  Runtime delayed-persistence flags were removed.
- Startup receipt reconciliation remains a clearly named synchronous Bootstrap
  Adapter before first actor use. It is not a concurrent or mirrored runtime
  authority.
- The combined queue/recovery/architecture gate passed `84 / 84`; macOS,
  generic iOS and Share Extension builds passed. Physical-device lifecycle
  evidence remains a separate open gate.

### Task 6.5: Migrate Photo Library core

- [x] Actor-backed receipt ledger reads existing SchemaV1 keys/format.
- [ ] Separate album, commit, exact-identifier read-back and reconciliation.
- [ ] Close TX-001 device interruption and duplicate-output evidence.

Task 6.5 partial outcome on 2026-08-30:

- The shared `PhotoLibrarySaveReceiptLedger` now owns normal receipt commands
  for static-photo, Live Photo and queue-resume paths. Existing keys and
  encoded values remain unchanged.
- A bounded synchronous placeholder writer is retained only because PhotoKit
  supplies the identifier inside `performChanges`; it may attach that value to
  a pre-existing intent and has no other receipt authority.
- The visibility locator now receives receipt candidates from the Bootstrap
  Adapter or ledger and performs only exact PhotoKit identifier lookup.
- `82 / 82` focused receipt/Live Photo/queue/architecture tests and three
  unsigned build targets pass. TX-001 physical-device interruption/read-back
  evidence remains open.

PhotoKit gateway follow-up on 2026-08-30:

- `PhotoLibraryTransactionGateway` now centralizes Apple Photos authorization,
  exact asset/album lookup, album creation and `performChanges` bridging for
  both static-photo and Live Photo writers.
- The writers retain their own resource pairing, receipt ordering and
  product-specific error translation. `83 / 83` focused tests and all three
  unsigned build targets pass; physical-device TX-001 evidence remains open.

Ambiguous-commit semantic closure on 2026-08-31:

- `PhotoLibraryAmbiguousCommitRecoveryPolicy` is now the shared recovery gate
  for static-photo and Live Photo writers. An idempotent task may report a
  reconciled, visible asset as successful only when its durable receipt has
  reached `commitAcknowledged`.
- Live Photo now matches the already-stricter static-photo behavior and emits
  its existing recoverable read-back-pending error while acknowledgement is
  absent. The policy leaves cancellation and non-idempotent save behavior
  unchanged; it does not alter receipt schema, resources, PhotoKit gateway or
  Renderer/media contracts.
- After a successful external Live Photo transaction, a failed submitted
  receipt write now preserves the pending intent and placeholder identifier;
  it no longer deletes the only exact-identity evidence that prevents a retry
  from creating a duplicate. A dedicated source contract failed before this
  correction and passes afterwards.
- `PhotoLibrarySaveGate` now lives under `Infrastructure/Concurrency` as the
  explicit shared serialization owner for both writers. Its Actor behavior and
  cancellation contract are unchanged.
- The policy, receipt, static/Live Photo writer and queue tests pass, as do
  unsigned macOS, generic iOS and Share Extension Debug builds. Signed-device
  TX-001 interruption/read-back/duplicate-output evidence remains open.

### Task 6.6: Migrate media build/render core

- [ ] Explicit semantic build, layout, artifact, encoding and commit stages.
- [ ] Move heavy work off the UI actor without weakening cancellation.
- [ ] Preserve static/Live Photo and metadata fidelity evidence.

Task 6.6 production-card transaction outcome on 2026-08-31:

- `BuildRecordCardTransaction` now forms the explicit Application boundary
  between a frozen production input and `RecordCardBuildService`. The batch
  task executor injects this transaction directly; it no longer knows about
  `BuildPreviewIntent` or `PreviewCoordinator`.
- `PreviewCoordinator` delegates to the same transaction, preserving one card
  construction implementation for preview and production while retaining
  Preview as a UI-facing adapter only. No memory calculation, snapshot,
  layout, renderer, metadata, export or Live Photo behavior moved in this
  increment.
- The direct transaction parity test, source dependency contract, complete
  host suite (`1677` passed, `0` failed, `1` skipped), macOS, generic iOS and
  Share Extension Debug builds pass. Moving composition/encoding work off the
  UI actor remains a separate, explicitly bounded follow-up.

### Task 6.7: Converge presentation features and compile-time modules

- [ ] Root and Subject editor become focused feature composition.
- [ ] Enforce dependency direction in local targets only after cycles are gone.
- [ ] Remove compatibility facades only after feature parity passes.

## Phase 7 — Active-Code Naming Modernization

Follow
`Docs/03_Engineering/2026-08-29-active-code-naming-modernization.md`.

### Task 7.1: Active root and current diagnostics

- [x] Rename `MemoMarkiOSV1View` to `MemoMarkConfigurationCenterView` and the
      active entry section to `ConfigurationCenterSection`.
- [x] Update routing, tests, source-contract paths and active documentation.
- [x] Remove current “V1 configuration” diagnostic copy.

### Task 7.2: Cross-layer product vocabulary

- [x] Rename output target, media output mode, Logo mode and album selection to
      stable product terms while preserving raw values and CodingKeys.

### Task 7.3: Configuration Center feature families

- [ ] Rename root state, flow, bootstrap, apply, output, Home, Settings,
      Subject, preview and editor families in bounded compiling slices.

Configuration Center presentation-primitive outcome on 2026-09-02:

- The active 825-line generic iOS presentation catalog is now
  `ConfigurationCenterViewSupportComponents.swift`. Its 18 active, non-schema
  `V1` type names now identify page, section, panel, card, action, or heading
  responsibility instead of a retired product stage.
- All active call sites and source contracts moved with the catalog. The
  behavior-preserving slice deliberately did not move a view body, adjust an
  accessibility/geometry constant, or alter a configuration, media, Renderer,
  queue, or compatibility contract.
- `V1PreviewCard` moved in the same bounded presentation family to
  `MemoryCardPreviewSurface.swift`; it remains a preview-only SwiftUI surface.
  The production card transaction remains preview-independent and continues
  to supply the same static and Live Photo production routes.
- The companion preview composition types, Intent names, section, and sync
  coordinator now use `MemoryCardPreview...` / `PreviewSyncCoordinator` names.
  This is an in-memory presentation projection migration only; the editor-draft
  / TextKit family remains a separately bounded follow-up.
- macOS and generic-iOS application builds plus `MemoMarkTests build-for-testing`
  passed. The focused `#filePath` source-contract execution hung in the known
  Xcode 27 app-hosted runner state and is not counted as a test pass; physical
  iPhone presentation acceptance remains part of the final unified device pass.

Memory Card Editor responsibility-family outcome on 2026-09-02:

- The non-schema card-editor draft, TextKit, interaction, line-box, region
  editor, overlay, and UIKit attachment owners now use
  `MemoryCardEditor...`, `MemoryCardTextKit...`, and
  `MemoryCardRegionEditor...` names and correspondingly named source files.
- The clipboard schema version and pasteboard types were explicitly retained;
  this is not a data-format migration. No geometric value, TextKit attribute
  factory, IME path, command-bus routing, draft projection, configuration
  owner, or Renderer/Layout/media behavior was changed.
- `MemoMarkTests build-for-testing` and generic iOS Debug builds passed after
  the migration. Focused execution of the line-box, draft bridge, and iPhone
  responsive source contracts stalled in the known Xcode 27 app-hosted runner
  at zero CPU and is not a passing result. The physical iPhone input/crop
  acceptance matrix remains part of the final unified device validation.

Root transient-state responsibility-family outcome on 2026-09-02:

- The composition root retains the one `ConfigurationSession` and the existing
  root-local draft/presentation ownership; it does not introduce a new
  ViewModel, aggregate, or umbrella coordinator merely to reduce file size.
- Root presentation, lifecycle, projection, and observation types are now
  responsibility-named `Root...` owners. The root's existing Pages, Actions,
  Bindings, Editor, Lifecycle, and Runtime extensions remain separate; no
  callback order, dirty/save suppression, picker lifecycle, or durable/media
  behavior moved in this naming slice.
- `MemoMarkTests build-for-testing`, generic iOS Debug build, diff check, and
  governance checks passed. Physical device workflow acceptance remains open.

Entry and welcome responsibility-family outcome on 2026-09-02:

- Entry routing, tab/presentation state, compact navigation shells, welcome
  state transitions, and welcome/settings presentation owners now use stable
  `Entry...` / `Welcome...` names and matching source paths.
- The `hasSeenWelcome` preference behavior, first-configuration decision,
  workflow guide, compact/regular navigation transitions, and quick-action
  routing were preserved exactly. This slice does not own configuration,
  snapshots, PhotoKit, queueing, rendering, or persistence.
- `MemoMarkTests build-for-testing`, generic iOS Debug build, diff check, and
  governance checks passed. The focused EntryFlowCoordinator,
  WelcomeFlowCoordinator, and WelcomePresentation suites executed with 16
  passing tests. The physical iPhone navigation/onboarding matrix remains part
  of final unified validation.

Home presentation responsibility-family outcome on 2026-09-02:

- The Home page, presentation primitives, preset/subject/output projections,
  activity/recent-processing presenters, feedback surface, and quick actions
  now use responsibility-named `Home...` types and files.
- The slice preserves the existing Configuration Center/Commerce/task-summary
  inputs and all Apple Photos guide, preset action, entitlement, localization,
  compact-layout, and accessibility behavior. It does not write configuration,
  access PhotoKit, or alter StoreKit, queue, Renderer, or export ownership.
- `MemoMarkTests build-for-testing` and generic iOS Debug build passed; the
  focused HomeProjection, HomeQuickActions, and HomeRecentProcessingPresenter
  suites executed with 20 passing tests. Diff and governance checks passed;
  physical Home acceptance remains open.

Subject and time-anchor presentation responsibility-family outcome on 2026-09-02:

- Subject overview, subject configuration flow, anchor-maintenance presentation,
  anchor formula/today presenters, home subject entry/avatar presentation, and
  the deterministic subject-selection policy now use responsibility-named
  `Subject...` / `TimeAnchor...` types and source paths.
- `ConfigurationSession` remains the single editing-session authority and the
  draft-to-explicit-save sequence is unchanged. `V1SubjectLibraryRecord` and
  `StoredV1SubjectLibraryRecord`, including Codable/App Group/Settings
  compatibility and raw values, remain untouched as explicit compatibility
  boundaries rather than being mechanically renamed.
- `MemoMarkTests build-for-testing`, generic iOS Debug build, diff check, and
  governance checks passed. TimeAnchorEntry, TimeAnchorToday, and
  SubjectSelectionMutation behavior suites executed with 13 passing tests.
  The combined SubjectOverview source-contract runner stalled at zero CPU in
  the known Xcode 27 app-hosted runner state after 85 seconds and is not a
  passing result; physical subject/anchor acceptance remains open.
- The adjacent Home subject-summary projection also now uses
  `SubjectHomeSummary...` names. Its three focused behavior tests, test-host
  build, and generic iOS Debug build passed; it remains read-only over the
  existing subject and configuration-status projections.

Preset coordinator naming outcome on 2026-09-02:

- The unreferenced, behavior-covered preset selection and deletion helpers now
  use `PresetSelectionCoordinator` / `PresetDeletionCoordinator` names.
  They were not connected to a new production path or deleted as dead code.
- The all-zero fallback selection UUID, no-op policy, and existing deletion
  delegation to `SubjectLibraryResolver.persist` remain unchanged; no second
  configuration library, snapshot, or save transaction was introduced.
- Test-host and generic iOS Debug builds, diff check, and governance checks
  passed. PresetSelectionCoordinator executed with three passing behavior
  tests. SubjectLibrarySupport was not enumerated as an executable suite by
  the current macOS runner and is not counted as passing.

Configuration inspector and action-footer responsibility outcome on 2026-09-02:

- The active inspector now has stable `ConfigurationOptionList`,
  `ConfigurationOutputBindings`, and `ConfigurationPageSurface` names. The
  bottom save/menu/confirmation surface is independently owned by
  `ConfigurationActionFooter`, while `ConfigurationOptionRowLayout` owns the
  shared ordinary-text and accessibility-size row arrangement. Neither owner
  inflates the inspector with unrelated presentation responsibility.
- This split retains the same one-way bindings and callbacks from the existing
  configuration page. It deliberately adds neither a second session/state
  holder nor any persistence, snapshot, PhotoKit, renderer, export, or Share
  path; all visual values and confirmation behavior are preserved.
- Test-host and generic iOS Debug builds plus diff/governance checks passed.
  Focused source-contract execution remained blocked by the known Xcode 27
  zero-CPU app-hosted runner state after 81 seconds and is not counted as a
  test pass. Physical inspector/footer acceptance remains part of final device
  validation.

Task presentation naming outcome on 2026-09-02:

- The queue/background-task read-only surface and its private history/thumbnail
  helpers now use `TaskPageSurface`, `TaskHistoryGroup`, and
  `TaskLocalThumbnail` responsibility names and matching active source paths.
- Its former Settings-named presenter projection is now accurately represented
  by `TaskPagePresenter`, `TaskPagePresentation`, `TaskCurrentPresentation`,
  and `TaskHistoryRowPresentation`.
- This is a presentation naming boundary only. Existing task state, retry,
  Photo Library callback, queue snapshot/persistence, partial-failure, media,
  Renderer, Export, and Share semantics remain owned by their established
  services and the existing presenter projection.
- Test-host and generic iOS Debug builds plus diff/governance checks passed.
  The renamed TaskPagePresenter behavior suite executed with nine passing
  tests; physical task page acceptance remains part of final device validation.

Settings presentation naming outcome on 2026-09-02:

- The active Settings page, expression guide, emphasis enum, and disclosure
  shell now use `Settings...` responsibility names and matching active source
  paths. The historical V1-form source references remain only in historical
  documents, where they preserve audit evidence.
- This does not migrate UserDefaults keys, change appearance/interface-language
  behavior, or alter commerce, diagnostics, external-feedback, privacy, or
  release-note semantics. It introduces no second preference store.
- Test-host and generic iOS Debug builds plus diff/governance checks passed.
  The 1,812-line SettingsPageSurface remains a deliberately separate structural
  decomposition follow-up, with final device acceptance still pending.

Settings disclosure-shell extraction outcome on 2026-09-02:

- `SettingsDisclosureSection` now owns only disclosure layout, accessibility,
  dynamic-type routing, reduced-motion animation, and content transition. The
  Settings page keeps every expanded-state binding and all preference/commerce/
  diagnostics/help action ownership.
- `SettingsSectionEmphasis` is module-internal only because the new shell reads
  it across a source-file boundary. No durable key, preference value, feature
  behavior, or media/production ownership changed.
- Generic iOS Debug and test-host builds plus diff/governance checks passed.
  The focused source-contract runner stalled in the known Xcode 27 zero-CPU
  state after 73 seconds and is recorded as BLOCKED; physical device acceptance
  remains pending.

MemoMark+ Settings card responsibility outcome on 2026-09-02:

- `MemoMarkPlusSettingsCard` now owns the visual card, its Dynamic Type route,
  and accessibility presentation from an already-resolved commerce projection.
  `SettingsPageSurface` keeps entitlement/allowance/first-recorder/TestFlight
  decision policy and passes only `isPlus`, status strings, language, hint, and
  the existing open action. The page consequently reduced from 1,652 to 1,525
  lines without moving StoreKit or durable state into SwiftUI presentation.
- Generic iOS Debug and test-host builds passed. The focused
  `SettingsDisclosureContractTests` executed with 15 passing tests after its
  source-contract assertions were updated to recognize the settled disclosure
  and commerce-card ownership boundaries. Diff/governance checks passed;
  physical Settings acceptance remains pending.

Settings support-row responsibility outcome on 2026-09-02:

- The repeated Settings action, privacy, information, link, and installed
  version row family is now independently owned by `SettingsActionRow`,
  `SettingsPrivacyRow`, `SettingsInformationRow`, `SettingsLinkRow`, and
  `SettingsVersionRow`. Their private content/icon primitives stay internal to
  that presentation file. The root page reduced from 1,525 to 1,309 lines and
  remains the sole owner of every action, URL, sheet, alert, preference, and
  diagnostic decision.
- Generic iOS Debug and test-host builds passed, and the 15 focused Settings
  disclosure/source contracts executed successfully. The broad Apple-native
  source-contract suite was then reconciled with the settled action-footer,
  option-row-layout, disclosure, and support-row owners and executed with 33
  passing tests. Diff/governance checks passed; physical Settings acceptance
  remains pending.

Settings read-only assurance-content outcome on 2026-09-02:

- `PhotoProcessingSupportContent` and `DataSafetySupportContent` now own only
  their settled assurance copy and support-row composition. The page supplies
  the existing language and, for photo processing, the already-resolved batch
  limit. Neither component reads PhotoKit, StoreKit, queue/snapshot state,
  preferences, or durable storage.
- The Settings root reduced from 1,309 to 1,193 lines. Generic iOS Debug build
  and the 15 focused Settings contracts passed, alongside diff/governance
  checks. Device acceptance remains a final unified step.

Settings guidance and About content outcome on 2026-09-02:

- `GettingStartedSupportContent` owns only guidance composition and delegates
  every action to the state-owning Settings page. `AboutSettingsContent` and
  `AboutMemoMarkNarrativeContent` similarly own only the settled About display
  content. Sheet/navigation/release-note state remains in the root page.
- The root reduced from 1,193 to 1,005 lines. Generic iOS Debug build and all
  15 focused Settings contracts passed, as did diff/governance checks. The next
  audit must keep feedback diagnostics, URLs, and interface preferences in
  their established ownership boundaries.

Settings community-content outcome on 2026-09-02:

- `CommunitySupportContent` now owns the two static community contact rows and
  receives only interface language. The Settings page remains the owner of
  disclosure persistence and of all diagnostics, TestFlight, mail, GitHub,
  preference, commerce, sheet, and external-navigation behavior.
- The root reduced from 1,005 to 969 lines. The 15 focused Settings disclosure
  contracts and an unsigned generic-iOS Debug build passed. Physical Settings,
  Dynamic Type, VoiceOver, and localization acceptance remain in the final
  device-validation pass.

Settings feedback-content outcome on 2026-09-02:

- `FeedbackSupportContent` now receives only resolved language, TestFlight and
  preparing state, and the three existing action callbacks. The Settings page
  still owns diagnostic-export lifecycle/result/error state, URL construction,
  disclosure persistence, and all external navigation and policy decisions.
- The root reduced from 969 to 888 lines after the obsolete local background
  helper was removed. The 15 focused Settings disclosure contracts and an
  unsigned generic-iOS Debug build passed. The final physical Settings,
  Dynamic Type, VoiceOver, and localization acceptance remains pending.

### Task 7.4: Explicit compatibility naming

- [ ] Rename real compatibility types to `SchemaV1`/`LegacyV1` forms.
- [ ] Centralize but do not alter V1 storage keys and file names.
- [ ] Add an active-source naming rule with compatibility allowlist.

## Current Execution Pointer

`RFC-002 next P0 — complete the evidence-gated physical-device production and
TX-001 interruption/readback matrix for the now-automatically-validated core;
retain compatibility aliases until their final source-migration review, and do
not reopen presentation decomposition unless a concrete device observation
requires it. Then begin the next evidence-gated
architecture boundary. Preserve the frozen Configuration Center, commerce,
diagnostics, and all durable compatibility boundaries.`
