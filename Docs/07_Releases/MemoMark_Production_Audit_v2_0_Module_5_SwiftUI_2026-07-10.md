# MemoMark Production Audit v2.0 Module 5

Module: SwiftUI Audit

Date: 2026-07-10

Baseline: `f74717f Add Production Audit v1.0 report`

## Scope

This module reviews:

- iOS SwiftUI root surface
- Home, Configuration, Task, Output, and Memory Subject editor surfaces
- view composition and file size
- lifecycle refresh
- navigation and sheet state
- preview/render consistency
- UI performance and testability

No files were modified during this module review.

## Executive Assessment

Rating: **B- with targeted fixes**

The SwiftUI layer is usable and has been pushed through real-device feedback,
but it is carrying too much runtime responsibility in the root view. The
largest risk is not visual polish. It is state behavior that is hard to test:
sheet state, selected anchor state, runtime/default snapshot refresh, and
preview/export parity.

There is one user-visible P1 that should be fixed before wider TestFlight:
the anchor maintenance editor can auto-open an edit sheet because draft loading
sets the editing anchor ID.

## Evidence

- iOS root currently renders `PhotoMemoiOSV1View`:
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift:63`
- `PhotoMemoiOSV1View` is a 3405-line root surface holding session, draft,
  logo, album, diagnostics, sheet, tab, and preview runtime state:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:35`
- `ConfigurationCenteriOSView` is 1413 lines and remains reachable as temporary
  entry, but it is not the current main runtime root:
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSTemporaryEntryView.swift:116`
- `MemorySubjectEditorView` is 1815 lines and owns local draft, autosync, avatar
  processing, and anchor sheets:
  - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:20`

## Ratings

| Dimension | Rating | Rationale |
|---|---|---|
| State Ownership | C | Root and editor views still own too much state. |
| Lifecycle Refresh | B- | Works in common flows, but refresh sources are distributed. |
| Sheet/Navigation | C+ | Sheet state is fragile and needs coordinator-level tests. |
| Preview/Render Consistency | C+ | Preview still reimplements renderer-like layout. |
| UI Performance | B- | Good enough for current data sizes; synchronous image reads remain. |
| Testability | B | Presenter/coordinator tests exist; SwiftUI lifecycle gaps remain. |
| Release Readiness | B- | Suitable with targeted fixes. |

## P0 Findings

No P0 findings.

No evidence was found of original-photo mutation, network upload, or a SwiftUI
issue that would categorically block app launch.

## P1 Findings

### P1-01: Anchor maintenance can auto-open edit sheet

Evidence:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:690`
- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:1168`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSSubjectOverviewSheetSurface.swift:216`

Impact:

`timeWindowEditor` presents a sheet when `editingTimeAnchorID != nil`.
`loadDrafts()` sets `editingTimeAnchorID` to the current anchor while loading.
Entering anchor maintenance can therefore look like the app creates or reopens
an anchor by itself.

Immediate fix?

Yes. This maps to the earlier user report about anchors reappearing or being
duplicated. It is small and should be fixed before wider TestFlight.

Recommendation:

On draft load, set selected anchor only. Set editing anchor only after an
explicit row tap or edit action.

### P1-02: iOS root and runtime contract are split

Evidence:

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift:65`
- `Tests/PhotoMemoTests/ArchitectureTests/IOSRuntimeSurfaceContractTests.swift:17`

Impact:

The current root is `PhotoMemoiOSV1View`, while the iOS contract test still
expects `ConfigurationCenteriOSView`. Since the test is iOS-gated, macOS test
runs may not catch the drift.

Immediate fix?

Recommended before relying on iOS architecture tests or CI for root contracts.

Recommendation:

Freeze the current release root decision in the test. If `PhotoMemoiOSV1View`
is accepted for V1, update the contract accordingly.

### P1-03: Root view state concentration makes lifecycle behavior hard to verify

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:38`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:420`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift:742`

Impact:

The root view owns too many unrelated state domains: session, drafts, logo,
album, diagnostics, sheets, tabs, photo picker, and preview runtime. This makes
configuration reset bugs harder to isolate.

Immediate fix?

Not a single-release blocker, but should be part of near-term hardening.

### P1-04: Preview is not the real renderer output

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift:220`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplySupport.swift:73`

Impact:

`V1PreviewCard` redraws a renderer-like card in SwiftUI, and configuration save
still builds an `.immersWhite` template directly. This conflicts with the long
term principle that Configuration Center previews the real Memory Card.

Immediate fix?

Do not redesign now. Add contract tests first, then move toward Presentation /
Layout output after IA-003 reaches that boundary.

## P2 Findings

### P2-01: Home and preview synchronously read local images in view body paths

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift:567`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1IOSViewSupportComponents.swift:452`

Classification: near-term maintenance.

### P2-02: Recent task sheet eagerly builds all rows

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift:436`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift:708`

Classification: near-term maintenance.

### P2-03: `AnyView` accessory weakens SwiftUI identity

Evidence:

- `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Editors/MemorySubjectEditorView.swift:25`

Classification: long-term architecture.

### P2-04: Temporary configuration entry lacks full refresh behavior

Evidence:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:96`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift:317`

Classification: future capability blocker if restored as root.

## Architecture Debt

- `PhotoMemoiOSV1View` is still a production UI, runtime orchestrator, and
  configuration coordinator in one file.
- `ConfigurationCenteriOSView` and `PhotoMemoiOSV1View` both conceptually carry
  Configuration Center language, but only one is the release root.
- Preview remains a SwiftUI reproduction of the final card rather than a shared
  Presentation/Layout/Renderer output.

## Evolution Review

The next UI evolution should not add new surfaces. It should first:

- freeze the iOS root contract
- extract lifecycle/sheet/runtime state from the root view
- connect preview to real presentation/layout contracts when IA-003 reaches
  that boundary

## API Design Review

`V1ConfigurationApplyBuildInput` is a good boundary, but it is still assembled
inside the root view. A future `V1RuntimeViewState` or
`V1ConfigurationDraftState` would let SwiftUI bind to state/actions without
constructing persistence requests directly.

## Dependency Review

SwiftUI views currently depend directly on `ConfigurationSession`, coordinator,
runtime services, UIKit, and PhotosUI. This is acceptable for V1 but should be
reduced as the app moves toward a long-term Configuration Center shell.

## Testability Review

Strengths:

- presenter and coordinator tests exist
- configuration lifecycle tests already catch some persistence issues

Gaps:

- sheet-state tests for anchor editor behavior
- root contract tests that actually run in the build matrix
- preview/export parity tests

## Immediate Fixes

- Fix `MemorySubjectEditorView.loadDrafts()` so it does not set
  `editingTimeAnchorID`.
- Align `IOSRuntimeSurfaceContractTests` with the accepted release root.
- Add coordinator-level tests for mutually exclusive sheet state.

## Long-Term Optimization

- Compress `PhotoMemoiOSV1View` into a coordinator shell.
- Move lifecycle, album, sheet, draft, and preview sync state into focused state
  owners.
- Create a shared async cache for avatar/logo/thumbnail image loading.
- Make Configuration Center preview consume the real Presentation/Layout
  contract rather than independently redrawing the card.

## Release Recommendation

Conditional Yes.

Proceed to release validation only after closing the anchor auto-edit sheet P1,
or explicitly re-verifying/fixing it as a known issue for a small internal
TestFlight.
