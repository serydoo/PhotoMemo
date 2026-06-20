# WorkspaceMigrationPlan

Last updated: 2026-06-20

## Purpose

This document is a migration blueprint for the `MainView` workspace architecture.

It is planning-only.

It does **not** authorize:

- business-logic migration
- UI redesign
- rendering changes
- export-flow changes
- permission-flow changes
- behavior changes

The goal is to define a safe path from the current `MainView` coordinator shell toward a real `WorkspaceSessionController` architecture.

## Current Snapshot

`MainView.swift` is now a thin shell again, but the workspace still behaves like a distributed coordinator:

- root state is still owned directly by `MainView`
- most workflow logic still lives in `MainView+*.swift`
- service dependencies are still owned directly by `MainView`
- `WorkspaceSessionController` currently exists as a Phase A preparation shell only

Current Phase A files:

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceSession.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceSessionController.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceAction.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/WorkspaceEnvironment.swift`

Current Phase A status:

- `MainView` bootstraps `WorkspaceSessionController`
- `WorkspaceState` mirrors a subset of `MainView` state
- `WorkspaceEnvironment` mirrors `MainView` dependencies
- `WorkspaceSessionController.send(action:)` currently handles only shell-level state mutation
- existing business logic remains in the original `MainView+*.swift` extensions

## MainView Responsibility Map

### What currently belongs to `MainView`

These responsibilities should remain in the `MainView` layer even after migration:

- root SwiftUI scene host
- view composition entry point
- environment wiring
- sheet and alert attachment points
- binding adaptation between view controls and workspace session state
- platform shell branching between macOS split view and iPhone compact flow

### What `MainView` currently owns directly

State currently declared in `MainView.swift`:

- `selectedPhoto`
- `selectedAnchorID`
- `presentationState`
- `alertState`
- `saveFeedbackState`
- `availableAlbums`
- `selectedAlbumIdentifier`
- `isSavingToAlbum`
- `editorSession`

Dependencies currently declared in `MainView.swift`:

- `settings: SettingsService`
- `permissionCenter: PermissionCenter`
- `workspaceSession: WorkspaceSessionController`
- `batchQueueStore: BatchQueueStore`
- `templatePresetEngine: TemplatePresetEngine`
- `anchorEngine: AnchorEngine`
- `cardBuildService: RecordCardBuildService`
- `exportService: RecordCardExportService`
- `photoLibraryExportService: PhotoLibraryExportService`

### Responsibility map by file

| File | Current responsibility | Long-term destination |
|---|---|---|
| `MainView.swift` | root shell, local state ownership, dependency ownership | keep as root shell, reduce to session wiring + view assembly |
| `MainView+LayoutSections.swift` | scene composition and section assembly | keep in view layer |
| `MainView+ModalAndLifecycle.swift` | sheet wiring, alert wiring, lifecycle event routing | split: sheet host stays in view, event routing gradually moves to session |
| `MainView+DerivedState.swift` | derived preview/export/display state | mixed: view-facing display derivation may stay, workflow derivation may move |
| `MainView+TemplateEditingActions.swift` | editing slot routing, token insertion, template writes | migrate coordination into session |
| `MainView+ComposerSession.swift` | editor display state, raw/display conversion, initial bootstrapping | migrate session-owned editor workflow into session |
| `MainView+WorkspaceConfigurationState.swift` | slot save/select/apply/default flow, batch snapshot sync | migrate coordination into session |
| `MainView+ExportActions.swift` | permission-aware album reload and save-to-library flow | migrate coordination into session later |
| `MainView+PermissionLifecycle.swift` | first-run permission prep and active-scene refresh | migrate coordination into session late |
| `MainView+PresentationState.swift` | local presentation mutations, rename flows | migrate state mutation into session, keep sheet views in UI layer |
| `MainView+CoordinatorSupport.swift` | imported photo assignment, anchor sync, preview sizing | split: assignment/sync may move, preview sizing stays near view |
| `MainView+Feedback.swift` | alert and save-feedback state mutation | migrate state mutation into session |
| `MainView+StateModels.swift` | local workspace state models | keep models, but `WorkspaceState` should become canonical owner |
| `MainView+ComposerEditor.swift` | editor widgets and platform text-view bridges | keep in view/editor utility layer |
| `MainView+ComposerDisplayEngine.swift` | editor display/token-span mapping | keep as specialized editor utility |
| `MainView+TemplatePanels.swift` | presentational template/custom-content/badge UI | keep in view layer |
| `MainView+SetupPanels.swift` | presentational photo/anchor UI | keep in view layer |
| `MainView+PreviewPanels.swift` | presentational preview/detail UI | keep in view layer |
| `MainView+Permissions.swift` | presentational permission UI | keep in view layer |
| `MainView+OutputSection.swift` | presentational output UI | keep in view layer |
| `MainView+WorkspaceControls.swift` | workspace slot UI and help-center UI | keep in view layer |

## Dependency Graph

### High-level graph

```text
MainView
  ├── owns local workspace state
  ├── owns services
  ├── assembles sections
  ├── wires sheets / alerts / lifecycle
  └── calls helper extensions
       ├── ComposerSession
       │    ├── MainTemplateEditorDisplayEngine
       │    ├── SettingsService
       │    └── MainEditorSessionState
       ├── TemplateEditingActions
       │    ├── ComposerSession helpers
       │    ├── TemplatePresetEngine
       │    └── SettingsService
       ├── WorkspaceConfigurationState
       │    ├── SettingsService
       │    ├── BatchQueueStore
       │    ├── ExternalPhotoIntakeCenter
       │    └── TemplatePresetEngine
       ├── DerivedState
       │    ├── SettingsService
       │    ├── AnchorEngine
       │    ├── RecordCardBuildService
       │    └── PermissionCenter
       ├── ExportActions
       │    ├── PermissionCenter
       │    ├── RecordCardExportService
       │    └── PhotoLibraryExportService
       ├── PermissionLifecycle
       │    ├── PermissionCenter
       │    └── ExportActions.reloadAlbums()
       └── ModalAndLifecycle
            ├── SettingsService change observation
            ├── workspace sync hooks
            └── permission / export / composer refresh triggers
```

### Existing Phase A session graph

```text
MainView
  ├── currentWorkspaceState -> WorkspaceState
  ├── currentWorkspaceEnvironment -> WorkspaceEnvironment
  └── bootstrapWorkspaceSessionPhaseA()
       ├── workspaceSession.updateEnvironment(...)
       └── workspaceSession.send(.replaceState(...))

WorkspaceSessionController
  ├── owns WorkspaceState
  └── currently mutates shell state only
```

### Key migration blocker in one sentence

The current architecture does not have a clean split between:

- pure workspace state mutation
- service side effects
- view-only presentation wiring

Those concerns are still mixed across the same helper extensions.

## What Belongs In `MainView`

These responsibilities should remain in `MainView` after migration:

- `View` conformance
- platform shell selection
- section composition
- binding adapters from session state into presentational views
- sheet attachment points
- alert attachment points
- preview/editor panel placement
- dependency injection into `WorkspaceSessionController`

`MainView` should not remain responsible for:

- deciding how workspace state changes
- coordinating workspace slot application
- coordinating editor session mutations
- coordinating permission/export/lifecycle workflow transitions

## What Should Move Into `WorkspaceSessionController`

The long-term target for `WorkspaceSessionController` is workflow coordination, not rendering or service implementation.

Recommended future ownership:

- canonical `WorkspaceState`
- `send(action:)` as the only mutation path for workspace session state
- presentation-state mutation
- alert/save-feedback mutation
- selected photo / anchor / album mutation
- editor focus / selection / module-span mutation
- workspace slot selection / restore / apply coordination
- lifecycle reaction coordination
- permission/export workflow coordination
- batch-default-configuration sync triggers

`WorkspaceSessionController` should coordinate services through `WorkspaceEnvironment`, but should not absorb those services' internal responsibilities.

## What Should Remain Where It Is

These parts should not move into `WorkspaceSessionController`:

- `SettingsService`
- `PermissionCenter`
- `BatchQueueStore`
- `RecordCardBuildService`
- `RecordCardExportService`
- `PhotoLibraryExportService`
- `AnchorEngine`
- `TemplatePresetEngine`
- `ExternalPhotoIntakeCenter`
- `MainTemplateEditorDisplayEngine`
- `MainTemplateFieldEditorView`
- `MainInlineTemplateTextEditor`
- presentational section views
- preview renderers

Reason:

- they are already cohesive services or specialized utilities
- forcing them into the session would create artificial abstraction
- the session should orchestrate them, not replace them

## Workspace Migration Slices

The safest path is to migrate by responsibility, not by file size.

### Slice 1: Canonical workspace state ownership

Goal:

- make `WorkspaceState` the canonical owner of the current root workspace state

Scope:

- `selectedPhoto`
- `selectedAnchorID`
- `presentationState`
- `alertState`
- `saveFeedbackState`
- `availableAlbums`
- `selectedAlbumIdentifier`
- `isSavingToAlbum`
- `editorSession`

Why first:

- every later migration depends on a single source of truth
- this is the minimum prerequisite for removing duplicate local state

Expected result:

- `MainView` reads state from `workspaceSession.state`
- `MainView` stops owning duplicate local copies

### Slice 2: Pure state actions

Goal:

- move state-only mutations into `WorkspaceSessionController.send(action:)`

Best candidates:

- sheet open/close actions
- compact tab changes
- alert presentation and dismissal
- save-feedback presentation and dismissal
- editor focus changes
- selection and module-span changes
- selected photo / anchor / album assignment

Why second:

- these actions have low service coupling
- they establish the mutation discipline for later slices

### Slice 3: Composer session coordination

Goal:

- migrate editor-session coordination without changing the editor widgets

Best candidates:

- `templateEditorDisplayText`
- `templateEditorModuleSpans`
- selection clamping
- sync from template into editor display state
- apply display change -> raw token mapping -> template update chain

Keep outside the session:

- `MainTemplateEditorDisplayEngine`
- AppKit/UIKit text view wrappers

Why third:

- composer editing has the highest risk of invisible behavior drift
- it should stabilize before workspace-slot migration builds on top of it

### Slice 4: Workspace configuration lifecycle

Goal:

- move workspace slot orchestration into the session

Best candidates:

- save current slot
- select slot
- restore slot default
- apply snapshot
- persist draft state
- sync batch queue default configuration

Why fourth:

- workspace slots affect multiple state domains at once
- this slice depends on canonical state ownership and composer synchronization

### Slice 5: Template editing coordination

Goal:

- move user-intent coordination around template editing into the session

Best candidates:

- active slot routing
- token insertion
- snippet insertion
- reset-to-default flow
- template rename coordination

Why fifth:

- these actions depend on composer state and template state already being session-backed

### Slice 6: Derived workspace model cleanup

Goal:

- separate truly view-only derived state from workflow-derived session state

Likely keep in the view layer:

- preview-only formatting strings
- hero summaries
- section subtitles
- preview sizing

Likely move or centralize:

- values needed by multiple workflow actions
- slot summary inputs
- export eligibility state
- batch snapshot-related derived values

Why sixth:

- derived state should be clarified only after state ownership settles

### Slice 7: Export and permission orchestration

Goal:

- move workflow coordination for permission-aware export into the session

Best candidates:

- initial permission requests
- active-scene permission refresh
- album reload orchestration
- save-current-card flow
- photo-library denied-state handling

Why late:

- this slice mixes async side effects, UI feedback, and state writes
- moving it too early would increase regression risk

### Slice 8: Lifecycle event routing

Goal:

- make `MainView` forward lifecycle events while the session decides reactions

Best candidates:

- `onAppear`
- `scenePhase` activation refresh
- `settings` change reactions
- anchor/template/album/badge/photo-description sync hooks

Why last:

- lifecycle routes touch nearly every other slice
- if moved first, they multiply debugging complexity

## Recommended Migration Order

Recommended execution order:

1. Canonical state ownership
2. Pure state actions
3. Composer session coordination
4. Workspace configuration lifecycle
5. Template editing coordination
6. Derived workspace model cleanup
7. Export and permission orchestration
8. Lifecycle event routing

This order is recommended because:

- it builds from low-risk state consolidation toward high-risk async orchestration
- it moves the caret-sensitive composer workflow before slot-wide state application
- it delays permission/export/lifecycle cross-cutting behavior until state boundaries are stable

## Dependencies That Block Migration

### 1. Duplicate state ownership

Current blocker:

- `MainView` owns state directly
- `WorkspaceSessionController` owns a mirrored `WorkspaceState`

Risk:

- drift between the two copies

Migration requirement:

- one canonical source of truth before meaningful migration starts

### 2. Direct view bindings into local `@State` and `SettingsService`

Current blocker:

- many section views bind directly to:
  - `selectedAnchorID`
  - `selectedAlbumIdentifier`
  - `presentationState`
  - `settings.shouldWritePhotoDescription`
  - `settings.photoDescriptionOverride`
  - `settings.anchors`

Risk:

- session migration can be bypassed by old bindings

Migration requirement:

- introduce session-backed bindings incrementally

### 3. Mixed side effects and state mutation in the same helper methods

Examples:

- `applyWorkspaceConfigurationSnapshot(...)`
- `saveCurrentCardToAlbum()`
- `preparePermissionsOnAppear()`
- `handleSelectedTemplateChange()`

Risk:

- hard to migrate one concern without accidentally moving another

Migration requirement:

- split "decide next state" from "call service" inside the same workflow slice

### 4. Composer editing depends on synchronized triple-state

Current blocker:

- display text
- raw token value
- module spans

Risk:

- a partial migration can break insertion, selection, or deletion while still compiling

Migration requirement:

- composer slice must move as one cohesive responsibility

### 5. Workspace slot switching affects multiple subsystems at once

Current blocker:

- template
- anchor
- badge
- album
- photo description settings
- composer session refresh
- batch default configuration sync

Risk:

- seemingly small migrations cause refresh drift

Migration requirement:

- slot application must be treated as one transaction-like coordination point

## Risk Analysis

### High risk

#### Composer caret and module-span synchronization

Files involved:

- `MainView+ComposerSession.swift`
- `MainView+TemplateEditingActions.swift`
- `MainView+ComposerDisplayEngine.swift`
- `MainView+ComposerEditor.swift`

Why risky:

- user-visible regressions appear as subtle editor behavior, not compile errors

Failure modes:

- insert goes to the wrong position
- module deletion stops removing the full chip/span
- raw token mapping drifts from display text

#### Workspace slot switching during active editing

Files involved:

- `MainView+WorkspaceConfigurationState.swift`
- `MainView+ComposerSession.swift`
- `MainView+PresentationState.swift`

Why risky:

- one action refreshes multiple independent state domains

Failure modes:

- stale caret state survives into the wrong slot
- displayed chips do not match stored raw template
- preview and editor stop agreeing after slot switch

#### Batch default configuration synchronization

Files involved:

- `MainView+WorkspaceConfigurationState.swift`
- `MainView+ModalAndLifecycle.swift`
- `SettingsService`
- `BatchQueueStore`
- `ExternalPhotoIntakeCenter`

Why risky:

- workspace edits also define future background behavior

Failure modes:

- preview shows one configuration
- background intake uses another

### Medium risk

#### Permission/export/feedback coordination

Why risky:

- async flows update UI state, permissions, albums, and feedback messages together

Failure modes:

- export button state drifts
- alerts present at the wrong time
- albums do not reload after grant

#### Lifecycle hook drift

Why risky:

- `onAppear` and `onChange` currently encode important sync behavior

Failure modes:

- slot state no longer seeds correctly
- template or badge changes stop updating batch defaults

### Low risk

#### Presentational section extraction boundaries

Why lower risk:

- most presentational section files are already cohesive and should stay that way

Failure mode:

- only binding rewiring mistakes, not architectural mismatch

## Future Target Shape

The target is not a giant new abstraction layer.

The target shape is:

```text
MainView
  ├── owns shell composition
  ├── binds to WorkspaceSessionController.state
  ├── forwards user intent as WorkspaceAction
  └── hosts sheets / alerts / platform layout

WorkspaceSessionController
  ├── owns canonical WorkspaceState
  ├── accepts WorkspaceAction
  ├── coordinates workflow side effects
  └── uses WorkspaceEnvironment dependencies

Services / Engines / Utilities
  ├── remain specialized
  ├── do not become view models
  └── are orchestrated, not absorbed
```

## Migration Guardrails

During every future slice, preserve these rules:

- no implicit insertion fallback into right-bottom
- slot switching must refresh editor session correctly
- preview must remain tied to the real render/export pipeline
- batch default configuration must stay aligned with saved workspace state
- no renderer/export behavior changes are allowed under session migration work

## Suggested Review Checklist Before Implementation

Before any future migration slice begins, confirm:

- `WorkspaceState` fields for that slice are complete
- there is only one canonical write path for that slice
- direct local `@State` writes are identified
- direct `settings.*` writes are identified
- batch-default sync expectations are listed
- manual regression scenarios are listed for that slice

## Summary

The architecture is ready for migration preparation, but not yet ready for broad logic movement.

The correct next step is not more file splitting.

The correct next step is to migrate one cohesive responsibility at a time, in this order:

1. state ownership
2. pure actions
3. composer session
4. workspace configuration
5. template editing
6. derived model cleanup
7. export/permission coordination
8. lifecycle routing

This keeps `MainView` as a real view shell while allowing `WorkspaceSessionController` to grow into a workflow coordinator without changing PhotoMemo behavior.
