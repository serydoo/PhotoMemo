# RFC-002: Behavior-Preserving Core Architecture Modernization

## Status

Accepted / Migration In Progress

## Date

2026-08-29

## Authority

The product owner explicitly opened MemoMark's internal core architecture for
redesign after review, with one overriding condition: every current user-facing
feature and every accepted data, media, and recovery guarantee must survive the
migration.

This RFC is the scoped V4 amendment that authorizes that work. It replaces the
earlier assumption that the current type boundaries and facades are permanent.
It does not reopen MemoMark's product identity or authorize new product surface.

## References

- `PROJECT_CONSTITUTION.md`
- `APPLE_PLATFORM_EXPERT.md`
- `Docs/CURRENT_BRIEF.md`
- `Docs/ADR/ADR-001-BatchConfigurationSnapshotProvider.md`
- `Docs/ADR/ADR-006-MemoryEngineFoundation.md`
- `Docs/ADR/ADR-007-ProviderBasedExpressionArchitecture.md`
- `Docs/ADR/ADR-008-MediaGeometryFoundation.md`
- `Docs/ADR/ADR-009-Configuration-Aggregate-And-Local-Backup-Library.md`
- `Docs/ADR/ADR-010-PresentationArtifactMediaParity.md`
- `Docs/ADR/ADR-011-Application-Transactions-And-Dependency-Direction.md`
- `Docs/03_Engineering/2026-08-29-codebase-health-refactoring-program.md`
- `Docs/03_Engineering/2026-08-29-codebase-health-refactoring-plan.md`

## Decision Summary

MemoMark will migrate from a collection of concrete, mutually aware runtime
objects toward five explicit architecture areas:

```text
Product Features / Presentation
            |
            v
Application Transactions
            |
            v
Domain Kernel

Platform Adapters ------> Application Ports

Composition Root constructs the graph; it owns no product behavior.
```

The target is not a generic Clean Architecture template. It is a MemoMark-
specific architecture organized around the transactions whose failure would be
visible to users: configuration save, media intake, queue execution, rendering,
Photo Library commit, recovery, and explicit backup/restore.

## Problem Statement

MemoMark's product and lower-level media logic have matured, but its runtime
ownership developed incrementally. Several large types now combine concerns
that need different lifetimes and different verification strategies:

- `MemoMarkiOSV1View` owns SwiftUI composition, a live configuration session,
  multiple drafts, navigation, persistence requests, Photos picker lifecycles,
  Logo optimization, album loading, diagnostics, and application feedback.
- `ConfigurationSession` is both an observable UI model and a broad forwarding
  facade over a 1,300-line editing state with persistence reconciliation mixed
  into the same surface.
- `BatchQueueStore` is observable UI state, durable queue authority, scheduler,
  recovery owner, receipt reconciler, commerce accountant, notification owner,
  and a collaborator directly mutated by `BatchTaskProcessor`.
- `BatchTaskProcessor` executes media work while reaching back into the store
  for every transition, which couples external work, state-machine rules,
  persistence timing, cleanup, notifications, and UI actor isolation.
- `PhotoLibraryExportService` combines authorization, album queries and
  creation, save serialization, PhotoKit mutations, receipt persistence,
  idempotency recovery, read-back, metadata validation, and temporary files.
- app composition constructs many concrete services, repositories, and
  coordinators under `@MainActor`, even when their work is file, metadata,
  rendering, or media work that does not belong to the UI actor.
- a partial Intent/Coordinator/Repository structure exists, but its boundaries
  are inconsistent: some intents wrap a coordinator one-to-one, some return a
  universal result, and other important workflows bypass it entirely.

The result is not primarily a line-count problem. It is an ownership problem:
state truth, orchestration, platform side effects, and presentation feedback
are too often held by the same object.

## Architectural Invariant Ring

Internal types, names, folders, facades, and module boundaries may change. The
following behavior contracts may not change without a separate product or data
migration decision.

1. MemoMark remains fully local-first for core photo and memory processing.
2. Apple Photos owns originals; MemoMark never modifies an original asset.
3. Processing creates a new output image or a correctly paired supported media
   result.
4. The user workflow remains centered on Apple Photos and the Configuration
   Center, including `Library -> Interactive Memory Card -> Object Inspector`.
5. `ConfigurationLibraryRecord` schema compatibility, UUID identity, revision
   behavior, App Group storage, and explicit backup/restore behavior remain
   readable throughout migration.
6. One durable configuration authority and one durable queue authority exist at
   every migration step.
7. A queued task uses the immutable production configuration snapshot accepted
   when the task is submitted. Later UI edits do not mutate that task.
8. Capture time, calendar/time-zone semantics, orientation, color, location,
   Live Photo pairing, and supported metadata degradation remain explicit and
   evidence-backed.
9. Memory Engine owns memory meaning; Provider/Expression owns semantic
   expression values; Layout Engine owns geometry; Renderer consumes resolved
   meaning and geometry.
10. Preview, still export, Live Photo still, and paired motion consume the same
    accepted presentation-artifact contract.
11. Photo Library save remains idempotent across cancellation, ambiguous commit,
    delayed asset visibility, process termination, and recovery.
12. Persist-before-cleanup and durable-terminal-before-notification ordering is
    preserved for queued work.
13. Share Extension remains a bounded intake and durable handoff process. It
    does not become a long-running media processor.
14. A task accepted for production never reads a configuration selected after
    its handoff. Current-format intake carries a valid canonical snapshot;
    historical intake may use only its own transport fields through an
    explicit compatibility adapter, never a later global configuration.
15. Existing localization, accessibility, commerce, notification, background,
    Live Activity, widget, and backup behaviors are retained unless separately
    specified.

## Target Architecture

### 1. Domain Kernel

The Domain Kernel contains deterministic product meaning and state transition
rules. It does not import SwiftUI, UIKit, Photos, PhotosUI, UserNotifications,
ActivityKit, StoreKit, or concrete file/persistence implementations.

Its accepted domains are:

- Configuration: Memory Subject aggregate, configuration entities, immutable
  production snapshots, revision and validation rules;
- Memory: capture-context and anchor meaning;
- Expression: provider-neutral semantic values and token lookup;
- Layout and Presentation Contract: canonical geometry, style registration,
  and immutable presentation artifacts;
- Processing Policy: queue/task phases, admission, retry, cancellation,
  recovery, media route, memory budget, and transition validation;
- Media Facts: resource identity, pairing identity, capture facts, orientation,
  color and metadata values without PhotoKit object ownership.

Domain code returns values and typed decisions. It performs no PhotoKit commit,
file write, notification, or UI mutation.

### 2. Application Transactions

An application transaction represents one user-meaningful or recovery-
meaningful operation. It receives an immutable command, calls narrow ports,
applies domain policy, and returns a typed result, receipt, or event stream.

Initial transaction families are:

- `SaveConfiguration` and `RestoreConfiguration`;
- `SubmitMediaIntake` and `DrainExternalIntake`;
- `AdmitBatchJob`, `RunNextBatchTask`, `RetryBatchTasks`, and `CancelBatchJob`;
- `BuildMemoryCard`, `RenderPresentation`, and `EncodeOutput`;
- `CommitStaticPhoto`, `CommitLivePhotoPair`, and `ReconcilePhotoLibraryCommit`;
- `LoadAlbums` and `EnsureAlbum`;
- `BackupConfiguration` and `ImportConfigurationBackup`;
- `PublishProcessingStatus` after a durable queue transition.

Transactions do not directly mutate SwiftUI models. Presentation supplies a
command and applies the returned result to its current session only after
identity/relevance checks.

No universal `Manager`, `Service`, or `Repository` protocol is introduced.
Protocols exist only around external effects or independently replaceable
storage boundaries.

### 3. Application Ports And Platform Adapters

Application ports are small and capability-based. Target examples include:

- `ConfigurationLibraryStoring`;
- `BatchQueuePersisting`;
- `PhotoLibraryAlbumAccessing`;
- `PhotoLibraryStaticAssetCommitting`;
- `PhotoLibraryPairedAssetCommitting`;
- `PhotoLibraryAssetLocating`;
- `MediaResourceLoading`;
- `PresentationRendering`;
- `NotificationDelivering`;
- `ExternalIntakeStaging`;
- `FileAccessing` and `Clock` only where deterministic failure/time testing is
  needed.

Production adapters own Apple and filesystem mechanics:

- PhotoKit/PhotosUI;
- Image I/O, Core Image, AVFoundation, and Uniform Type Identifiers;
- App Group/UserDefaults and atomic files;
- Share Extension provider loading and managed-file handoff;
- notifications, background tasks, ActivityKit, StoreKit, and widgets.

Platform objects such as `PHAsset`, `PHAssetResource`, `NSItemProvider`, and
`AVAsset` must not become durable domain identities. They are resolved at the
adapter boundary into MemoMark values.

### 4. Product Features And Presentation

SwiftUI remains a projection of state and a dispatcher of intents. UIKit and
TextKit retain caret, selection, IME, undo, accessibility, and module-atomic
editing where the existing editor contract requires them.

The presentation target is feature-scoped rather than one umbrella ViewModel:

- Configuration Center composition;
- Library/Home feature;
- Interactive Memory Card and editor feature;
- Memory Subject editor feature;
- Output configuration feature;
- processing/status feature;
- Settings and backup/restore feature.

Each feature may own an `@MainActor @Observable` model only when it has a real
shared UI lifetime. Pure view composition stays in SwiftUI. Heavy media,
metadata, rendering, persistence, and queue execution do not move into a UI
model.

The root view eventually contains only environment dependencies, root
navigation/presentation state, feature composition, and top-level event
routing. It does not construct collaborator factories inside computed
properties.

### 5. Composition Root

The app and extension targets each have one explicit composition root.

The main app composition root constructs concrete adapters, actor-backed
durable stores, application transactions, and presentation-facing feature
dependencies. It does not inherit `@MainActor` for the entire dependency graph.
Only `MemoMarkAppRuntime` and UI-observed projections are main-actor isolated.

The Share Extension composition root constructs only intake validation,
managed resource staging, durable handoff, diagnostics, and its bounded UI.

## Compile-Time Dependency Direction

The intended dependency graph is:

```text
MemoMarkApp / MemoMarkiOSApp / Extension targets
        |
        +--> MemoMarkComposition
        +--> MemoMarkPresentation

MemoMarkPresentation --> MemoMarkApplication --> MemoMarkDomain
MemoMarkPlatform -----> MemoMarkApplication --> MemoMarkDomain
MemoMarkMedia --------> MemoMarkApplication --> MemoMarkDomain
```

The initial migration may enforce these as folders and source-contract tests.
After dependencies are clean, local Swift package or framework targets may
enforce them at compile time:

- `MemoMarkDomain`;
- `MemoMarkApplication`;
- `MemoMarkMedia`;
- `MemoMarkApplePlatform`;
- `MemoMarkPresentation`.

Creating packages before dependency cleanup is explicitly rejected because it
would turn existing cycles into build-system work instead of solving them.

## State Lifetime Model

Every mutable value must identify exactly one lifetime and owner.

| Lifetime | Canonical owner | Examples | Rule |
| --- | --- | --- | --- |
| Durable product truth | actor-backed repository/ledger | configuration aggregate, queue jobs, save receipts | atomic/revisioned writes and recovery |
| Editing transaction | Configuration Center session/draft | unsaved subject, preset, output, text and style edits | explicit rebase/commit/cancel; never queue truth |
| Production snapshot | immutable value | accepted task configuration, resolved media facts | frozen at admission; `Sendable` |
| Runtime operation | transaction/task identity | picker load, Logo optimization, album load, save attempt | cancellable and relevance-checked |
| Presentation projection | `@MainActor` observable/value state | loading, alert, selected tab, progress | rebuildable; never durable authority |
| Platform resource | bounded adapter/task | PhotoKit resource, temp file, decoder buffer | explicit owner, cleanup and cancellation |

No state may exist in two rows as peer truth. Conversion between rows is an
explicit command, snapshot, receipt, event, or projection.

## Core Transaction Designs

### Configuration Save

```text
Editing Draft
-> SaveConfigurationCommand(expectedRevision, aggregate candidate)
-> validate domain invariants
-> compare-and-save durable aggregate
-> persist compatibility projection
-> ConfigurationSaveReceipt(revision, warnings)
-> rebase current editing session if still relevant
```

The compatibility projection may warn, but it never becomes peer durable
truth. A stale completion cannot overwrite newer editing state.

### Queue And Task Execution

```text
BatchQueueRuntime actor
-> selects one immutable BatchTaskCommand
-> persists running transition
-> BatchTaskExecutor executes without store access
-> emits typed progress/outcome
-> runtime validates and persists each accepted transition
-> durable terminal state
-> cleanup / history cover / notification side effects
```

`BatchTaskExecutor` cannot call `BatchQueueStore`, publish UI state, or select a
new task. The queue runtime cannot decode/render media itself. This separates
state-machine proof from media execution proof.

The target remains one enforced heavy-media task at a time until BP-001 is
superseded by measured evidence and a new decision.

### Photo Library Commit

```text
PhotoLibraryCommitCommand(idempotencyKey, artifact, metadata, album)
-> persist intent
-> serialize commit transaction
-> PhotoKit adapter submits resources and returns placeholder identity
-> persist submitted receipt
-> PhotoKit commit acknowledgement
-> persist committed receipt
-> exact-identifier read-back / reconciliation
-> PhotoLibraryCommitReceipt
```

If the platform commit may have succeeded but local proof or visibility is
missing, the transaction returns a pending/reconciliation state. It never
blindly retries and creates a duplicate.

Receipt persistence moves behind an actor-backed ledger. Existing keys and
Codable formats remain readable until a separately verified migration changes
them.

### Memory Card Build And Render

```text
Selected Media Facts + Production Configuration Snapshot
-> Memory resolution
-> Provider/Expression compilation
-> resolved Memory Card content
-> Layout Engine geometry
-> PresentationArtifact
-> still or paired-media composition
-> encoded temporary output
```

`RecordCard` and current services may remain compatibility models during
migration. The target compiler is stateless and does not depend on SwiftUI or
PhotoKit. Renderer registration stays style-oriented; media composition does
not branch on concrete presentation styles.

### Share Extension Intake

```text
NSItemProvider resources
-> validate and stage managed resources
-> write durable ExternalIntakeEnvelope
-> request main-app handoff
-> extension completes

Main app
-> drain envelope idempotently
-> resolve current accepted production configuration
-> submit one queue admission transaction
```

The extension never performs full-resolution rendering or Photo Library
save-back.

## Current-To-Target Ownership Map

| Current owner | Target responsibility | Migration treatment |
| --- | --- | --- |
| `AppEnvironment` concrete containers | composition root | replace nested concrete exposure with feature/application dependencies after callers migrate |
| `MemoMarkAppRuntime` | app lifecycle and UI-observed runtime | retain, shrink, and keep `@MainActor` |
| `ConfigurationSession` | editing-session facade | evolve toward one draft aggregate plus explicit commands; no persistence implementation |
| `ConfigurationEditingState` | configuration domain/editor reducers and projections | split deterministic mutation from presentation formatting |
| `ConfigurationCoordinator` | configuration application transactions | replace one-to-one forwarding with typed save/load/restore use cases |
| `BatchQueueStore` | temporary presentation/compatibility facade | retain during migration; durable authority moves to queue ledger/runtime actor |
| `BatchQueueCoordinator` | queue domain policies plus runtime orchestration | split pure transition policy from actor runtime |
| `BatchTaskProcessor` | task executor | remove direct store mutation; return events/outcomes |
| `PhotoLibraryExportService` | compatibility facade | split album access, commit transaction, receipt ledger, PhotoKit gateway, and read-back |
| `RecordCardBuildService` | stateless Memory Card compiler facade | split resolved semantic input from compatibility card construction only where tests prove parity |
| `RecordCardExportService` | encoded-output transaction | keep renderer-neutral artifact path and remove unnecessary UI-actor isolation |
| Share Extension controller/service | intake feature plus platform adapter | controller presents state; service stages resources; main app owns processing |
| `MemoMarkiOSV1View` | root feature composition | migrate application workflows to feature/application owners and extract focused views |
| `MemorySubjectEditorView` | subject editing feature | one subject draft, child presentation sections, separate anchor/avatar runtimes |

## Feature Preservation Matrix

Every row must retain automated evidence and, where an Apple framework is the
authority, signed physical-device evidence before the old path is deleted.

| Existing behavior | Required invariant | Target verification |
| --- | --- | --- |
| Configuration create/select/rename/delete | UUID and revision authority; no cross-subject fallback | aggregate contract and transaction tests |
| Subject identity/relationship/avatar edit | one draft; latest edit wins; managed asset cleanup | reducer/runtime tests plus physical editor acceptance |
| Time anchors and life-position text | capture context and calendar semantics; no fabricated meaning | Memory Engine fixtures |
| Preset/text/module editing | canonical string/module projection and TextKit geometry | projection, line-box, IME/undo tests and device acceptance |
| Preview | same resolved configuration and presentation contract as output | artifact parity tests |
| Logo selection/custom asset | request relevance and portable asset ownership | stale/cancel/cleanup tests |
| Location/time display | permission-aware degradation and saved configuration parity | provider/configuration tests |
| Photos picker quick action | immutable snapshot before intake; stale results ignored | intake lifecycle tests |
| Share Extension | staged durable handoff; bounded extension lifetime | provider/file/handoff tests and device share acceptance |
| Static photo processing | metadata, orientation, color and output correctness | fixture tests plus Photos read-back |
| Live Photo processing | still/motion identity, audio, duration and fail-closed pairing | pairing tests plus device long-press playback |
| Album selection/creation | exact identifier, missing-album recovery, authorization behavior | gateway tests plus device Photos acceptance |
| Queue retry/cancel/resume | valid state transitions and persist-before-cleanup | queue state-machine/failure-injection tests |
| Ambiguous PhotoKit commit recovery | no duplicate output; exact receipt reconciliation | interruption harness and device read-back |
| Background processing/notification/Live Activity | durable state precedes presentation side effects | lifecycle tests plus device checks |
| Local backup/import/restore | version/checksum/assets and explicit restore | compatibility fixtures and round-trip tests |
| Commerce limits/history | durable completed work drives accounting | queue/commerce reconciliation tests |
| Localization/accessibility/device fit | no user-facing regression | quality gate and physical iPhone acceptance |

## Migration Strategy

The migration is a strangler migration. At every step, the app has one active
production path and one durable authority.

### Slice A — Baseline And Architecture Contracts

- freeze schema fixtures, output/artifact fixtures, queue transition contracts,
  and Photo Library receipt compatibility;
- add dependency-direction tests for forbidden imports and ownership;
- record complete feature parity and device evidence gaps;
- retain `2.2.3 (100)` as the user-visible baseline.

### Slice B — Composition And Application Transaction Foundation

- define typed command/result/event conventions without forcing every operation
  into one generic protocol;
- separate concrete dependency construction from `@MainActor` UI runtime;
- migrate one read-only transaction first to verify composition and testing;
- do not move durable ownership in this slice.

### Slice C — Configuration Core

- consolidate subject/preset/output edits into one editing draft aggregate;
- split deterministic reducers and projections from SwiftUI;
- make save/load/restore explicit application transactions;
- preserve aggregate bytes, revision rules, compatibility projection, and
  current feature behavior before removing old forwarding methods.

### Slice D — Queue Runtime Core

- introduce pure transition policy tests;
- introduce an actor-backed durable queue runtime behind the existing facade;
- make the executor consume immutable commands and emit events/outcomes;
- migrate retry, cancel, recovery, notifications, history, and commerce in
  separately verified steps;
- remove direct processor-to-store mutation only after parity is complete.

### Slice E — Photo Library Transaction Core

- split policies and receipt codec without behavior change;
- add an actor receipt ledger that reads existing keys and formats;
- define PhotoKit gateway seams and failure injection;
- move static save, album access, exact-identifier read-back, and reconciliation
  one at a time;
- run TX-001 signed-device interruption evidence before deleting the old path.

### Slice F — Media Build/Render Core

- make semantic compilation, layout resolution, artifact creation, encoding,
  and Photo Library commit explicit adjacent stages;
- remove unnecessary main-actor isolation from heavy work;
- retain preview/still/Live Photo artifact parity and media fidelity;
- measure memory and duration on the paired device before performance claims.

### Slice G — Presentation Features

- reduce the iOS root to composition and event routing;
- complete Memory Subject editor draft/avatar/anchor decomposition;
- split oversized feature surfaces by state owner and interaction contract;
- preserve HIG, accessibility, localization, keyboard, and TextKit behavior.

### Slice H — Compile-Time Modules And Legacy Removal

- enforce the dependency graph with local targets/packages only after source
  dependencies are acyclic;
- remove compatibility facades, old coordinators, obsolete intents, and source-
  string tests only after all callers and evidence have moved;
- publish a superseding production certification before calling the migration
  complete.

### Slice I — Active-Code Naming Modernization

- replace active stage-prefixed `V1` names with stable responsibility-based
  product and architecture names;
- do not replace them mechanically with `V4`;
- retain real historical formats as explicit `SchemaV1` or `LegacyV1`
  boundaries;
- preserve every stored key, CodingKey, raw value, file name, checksum, and
  migration fallback unless a separate storage migration is accepted;
- follow
  `Docs/03_Engineering/2026-08-29-active-code-naming-modernization.md` by
  cohesive feature family, with compiler and test evidence after each family.

## Verification Gates

Each slice uses RED -> GREEN -> REFACTOR when behavior or lifecycle changes.
Pure moves use existing tests as the oracle and add no source-layout contract
unless it protects a durable forbidden dependency.

Required evidence is cumulative:

1. focused unit/contract/failure-injection tests;
2. complete `MemoMarkTests` checkpoint;
3. required macOS build;
4. generic iOS compile;
5. governance and `git diff --check`;
6. multi-axis Swift/code architecture review;
7. signed physical iPhone 17 Pro Max validation for UI, Photos, Live Photo,
   background, performance, permission, and commit-interruption boundaries;
8. output/read-back comparison for supported media claims;
9. explicit record of anything not verified.

No simulator evidence substitutes for the required physical-device evidence.

## Rollback And Compatibility Rules

- additive path first, caller switch second, old path removal last;
- no migration writes a new durable format until old-format fixtures and a
  recovery plan exist;
- preserve App Group keys and decode behavior while adapters move;
- every caller switch has a feature flag or independently revertible diff when
  the boundary is P0/P1;
- an ambiguous PhotoKit or persistence outcome blocks/reconciles; it never
  guesses success or blindly retries;
- temporary resources are deleted only after their durable owner no longer
  needs them;
- unrelated dirty-worktree changes are preserved.

## Explicit Non-Goals

- no new product feature, cloud service, account system, or photo-management
  surface;
- no redesign of `Library -> Interactive Memory Card -> Object Inspector`;
- no change to visible renderer output merely to fit the new architecture;
- no replacement of TextKit's accepted editing responsibilities;
- no speculative generalized plugin/provider framework;
- no package explosion before actual dependency seams exist;
- no big-bang rewrite and no line-count-only refactor.

## Success Criteria

The modernization is complete only when:

1. every current feature in the preservation matrix has equivalent or stronger
   evidence on the target path;
2. presentation objects do not own durable persistence or media execution;
3. queue execution is driven by an actor-owned durable state machine and task
   executors cannot mutate its store directly;
4. configuration editing has one draft owner and one durable aggregate
   transaction boundary;
5. Photo Library commits have explicit intent, receipt, acknowledgement,
   read-back, cancellation, and recovery owners;
6. heavy media work is not isolated to the UI actor for convenience;
7. Memory, Expression, Layout, Renderer, media composition, and export have
   one-way dependencies and no duplicate semantic or geometry truth;
8. Share Extension remains a bounded intake adapter;
9. compile-time module boundaries enforce the accepted dependency direction;
10. obsolete compatibility facades and duplicate paths are removed;
11. complete automated, build, review, and physical-device gates pass;
12. a superseding production certification closes the migration.
13. active production source uses stable responsibility-based names, with
    version labels limited to explicit schema, legacy, storage, and migration
    boundaries.

## Closing Record

### 2026-08-30 Implementation Checkpoint

- Slice B read-only transaction foundation is active for Photo Library album
  loading through a narrow port and a composition-root-owned transaction.
- Slice D has pure retry/cancel/job-state and executor-event transition policy;
  the executor now consumes immutable context through an async runtime port and
  emits typed events without depending on `BatchQueueStore`.
- Slice D's production durable queue authority is now
  `BatchQueueDurableLedger`. Admission, retry, cancellation, recovery,
  executor events, background expiration, notification markers and history
  retention commit through the actor before `BatchQueueStore` projects the
  result. `BatchQueueStore` remains a main-actor compatibility/presentation
  facade and orchestration seam, not a second durable owner.
- A narrow synchronous Bootstrap Adapter remains for startup-only receipt
  reconciliation and resume normalization before the actor is first used. The
  ledger bootstraps from that finalized persisted state; the adapter and actor
  do not run as competing production writers. Runtime delayed-persistence
  flags and direct processor-to-store mutation have been removed.
- Photo Library receipt persistence is now actor-owned by the shared
  `PhotoLibrarySaveReceiptLedger`, with static-photo, Live Photo and runtime
  queue recovery callers migrated. Existing SchemaV1 keys/formats remain
  unchanged. The only synchronous escape hatch is a capability restricted to
  attaching PhotoKit's placeholder identifier to an existing pre-commit
  intent inside `performChanges`; it cannot operate as a general receipt
  store. When the external transaction returns without a locally visible
  placeholder, both writers now retain the submitted evidence and surface
  readback-pending instead of deleting recovery state. TX-001 signed-device
  interruption and read-back evidence remain pending.
- Static-photo and Live Photo writers now share
  `PhotoLibraryTransactionGateway` for Apple Photos authorization, exact
  asset/album lookup, album creation and transaction continuation mechanics.
  Product-specific resource construction, receipt ordering and error mapping
  remain at each transaction owner; this is a dependency-direction migration,
  not a change to PhotoKit behavior.
- `BuildRecordCardTransaction` is no longer UI-actor isolated. Card
  compilation remains synchronous and deterministic, while its application
  boundary is now eligible for future queue/media scheduling away from the
  main actor without changing the renderer or memory contracts.
- Output-album lookup and creation now also run through the shared
  `PhotoLibrarySaveGate`, so configuration saves and batch work cannot race
  into duplicate same-title albums.
- The first active-code naming families now use stable root, configuration-save,
  persistence-status, adaptive-layout, date-formatting and status-badge names.
  The configuration application transport now also uses stable request,
  receipt, and album-selection vocabulary; old V1 spellings remain only as
  source-compatible aliases for migration callers. Configuration bootstrap and
  Share Extension readiness reads now use stable responsibility names as well;
  the remaining V1 symbols in those paths are deprecated adapters or explicit
  historical persisted representations.
  Remaining `V1` families require the same bounded compiler-and-test migration;
  no mechanical `V1 -> V4` rename is authorized.

- Architectural proposal: `Accepted`
- Implementation: `In Progress — Slice E evidence closure; Slice F transaction and album boundary converged`
- Behavior baseline: `2.2.3 (100)`
- Product feature changes: `None authorized`
- Durable-format migration: `None authorized without a scoped contract`
- Physical-device acceptance: `Pending where identified`
- Production certification: `Not claimed`
