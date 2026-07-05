# Implementation Plan: Provider-Based Location Expression Pipeline

Status: Proposed
Scope: Implementation Plan
Target: Post IA-003
Branch: codex/地址模块
Date: 2026-07-05

## Overview

This plan turns `Location_Expression_Pipeline.md` into a staged implementation
path. The goal is not to replace the current V1 production pipeline in one
step. The goal is to introduce `ExpressionContext` and Location Provider
capabilities additively, keep `MetadataContext` as a legacy adapter, and remove
preview-local location demo data only after provider output can feed the same
expression path used by production.

Configuration Center preview and production must converge on the same
`ExpressionContext -> Renderer` contract. Preview may use sample data, but it
must not introduce a second context model.

## References

- `Docs/02_Architecture/Proposal/Location_Expression_Pipeline.md`
- `Docs/02_Architecture/Contract/Expression_System_Contract.md`
- `Docs/02_Architecture/V1_Preview_Renderer_Export_Contract_Review_2026-07-03.md`
- `Docs/02_Architecture/V1_Render_Contract_Freeze_2026-07-03.md`
- `Docs/CURRENT_STATUS.md`

## Migration Roadmap

Current:

```text
PhotoMetadata
        |
        v
MetadataContext
        |
        v
Renderer
```

Transition:

```text
PhotoMetadata
        |
        +----------------+
        |                |
        v                v
MetadataContext    ExpressionContext
        |                |
        +---- Adapter ---+
                |
                v
             Renderer
```

Future:

```text
PhotoMetadata
        |
        v
Providers
        |
        v
ExpressionContext
        |
        v
Renderer
```

`ExpressionContext` is introduced by gradual migration. It is not a request for
a high-risk replacement of the current production pipeline.

Preview and production migration:

```text
Configuration Center Preview
Sample Preview Values
        |
        v
ExpressionContext
        |
        v
Renderer Preview

Production
PhotoMetadata
        |
        v
Canonical Providers
        |
        v
ExpressionContext
        |
        v
Renderer
```

Preview differs from production by data source only.

## Implementation Guardrails

- Do not modify Renderer, Export, Photo Library behavior, Share Extension
  behavior, or Layout Engine behavior as part of the early phases.
- Follow the Review Invariants in `Location_Expression_Pipeline.md`:
  Single Rendering Pipeline, Configuration Never Depends On Asset, Providers
  Produce Meaning / Renderer Produces Pixels, and Preview Must Never Invent
  Architecture.
- Do not add new semantic token design to `MetadataContext`.
- Any new semantic token must enter through its canonical Provider first.
- If the V1 renderer or template path still needs the value, project it through
  an explicit legacy adapter.
- `MetadataContext` remains a compatibility layer, not the expression source of
  truth.
- Presentation configuration must be saved as module configuration, not
  transient UI state.
- Reverse geocoding must not become a required network dependency for the core
  local-first workflow.
- Preview must not introduce demo location values that production cannot
  produce.
- Do not create `PreviewExpressionContext` or another preview-only core context
  model. Build normal `ExpressionContext` from sample preview values instead.

## Phase Summary

| Phase | Content | Production Code |
| --- | --- | --- |
| Phase 0 | Establish folders, protocols, empty Provider, empty Context, empty Resolver | No |
| Phase 1 | `LocationContextBuilder` builds `LocationContext` from `PhotoMetadata` | Yes, isolated internals |
| Phase 2 | `LocationFormatter` formats presentation strings | Yes, isolated internals |
| Phase 3 | `LocationResolver` owns resolution strategy | Yes, isolated internals |
| Phase 4-A | Expression System platform contract | No |
| Phase 4-B | Provider-neutral `ExpressionValue` contract | Yes, isolated internals |
| Phase 4-C | `ExpressionContext` storage and ownership tests | Yes, isolated internals |
| Phase 4-D | `LocationExpressionProvider` compiles Location domain output into `ExpressionValue` for `location` only | Yes, isolated internals |
| Phase 5 | `MetadataContext` adapter projects `ExpressionContext` into the legacy pipeline | Yes |
| Phase 6 | Preview uses `ExpressionContext` built from sample values and removes demo values such as `河南 · 商丘` | Yes |
| Phase 7 | Object Inspector stores `LocationPresentationMode` configuration | Yes |
| Phase 8 | Add Reverse Geocoder Apple adapter | Deferred |
| Phase 9 | POI, Landmark, and Location Intelligence | V2 |

## Phase Definition Of Done

- Phase 0: skeleton types exist, compile, and remain disconnected from
  renderer, UI, export, metadata mutation, share extension, and photo-library
  behavior.
- Phase 1: `LocationContext` can be independently built from `PhotoMetadata`,
  missing GPS is not invented, focused tests pass, and production renderer
  behavior is unchanged.
- Phase 2: `LocationFormatter` is side-effect free, does not depend on
  Provider, Renderer, Template, Inspector, or UI, and formatting modes are
  covered by focused tests.
- Phase 3: `LocationResolver` owns resolution strategy, including fallback,
  presentation selection, downgrade decisions, and future policy decisions.
  It is deterministic for the same `LocationContext` and configuration,
  delegates string shape to `LocationFormatter`, keeps `LocationResolution`
  immutable, transient, and request-scoped, and remains renderer/UI
  independent.
- Phase 4-A: Expression System platform contract is frozen before code
  integration.
- Phase 4-B: provider-neutral `ExpressionValue` carries semantic token identity
  and resolved text before any Provider integration.
- Phase 4-C: `ExpressionContext` stores provider-neutral values by semantic
  token, remains renderer/UI independent, and token ownership is test-covered.
- Phase 4-D: `LocationExpressionProvider` proves the Canonical Provider
  compiler boundary by producing a provider-neutral `ExpressionValue` for
  `location` only. It must consume `LocationContext`, `LocationResolver`, and
  `LocationFormatter` output without reading `PhotoMetadata`, reimplementing
  strategy, returning a provider-specific model, or connecting Renderer, UI,
  Export, Share Extension, or production metadata paths.

## Task List

### Phase 0: Architecture Skeleton

- [x] Task 0.1: Add isolated Location expression skeleton
  - Description: Create empty or minimal types for the provider-based Location
    pipeline without connecting them to production.
  - Acceptance:
    - `LocationContext`, `LocationContextBuilder`,
      `LocationResolver`, `LocationFormatter`,
      `LocationExpressionProvider`, and `ReverseGeocoder` protocol exist as
      isolated types.
    - No renderer, export, share-extension, photo-library, or UI behavior
      changes.
    - Types compile behind existing target boundaries.
  - Verify:
    - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/Expression/`
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/`
    - `Tests/PhotoMemoTests/ArchitectureTests/`
  - Estimated scope: Medium

### Phase 1: Location Context

- [x] Task 1.1: Build semantic LocationContext from PhotoMetadata
  - Description: Convert raw location facts from `PhotoMetadata` into a
    semantic `LocationContext` with availability helpers.
  - Acceptance:
    - GPS, altitude, country, province, city, district, and location name map
      into `LocationContext`.
    - `hasGPS`, `hasAddress`, and `hasPOI` behavior is tested.
    - Missing location facts degrade to empty values.
  - Verify:
    - focused Location context tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Models/LocationContext.swift`
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Builders/LocationContextBuilder.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/LocationExpressionPhase1Tests.swift`
  - Estimated scope: Medium

### Phase 2: Location Formatter

- [x] Task 2.1: Add LocationFormatter
  - Description: Move string-shape decisions into `LocationFormatter`.
  - Acceptance:
    - Province + City, City + District, Province + City + District, and
      Coordinate formatting are covered.
    - Duplicate hierarchy values are removed.
    - Altitude remains a raw semantic output, not a Location presentation mode.
  - Verify:
    - focused formatter tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Presentation/LocationFormatter.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/LocationExpressionPhase2Tests.swift`
  - Estimated scope: Small

### Checkpoint: Context Foundation

- [x] LocationContext builder internals are test-covered.
- [x] No production template or renderer behavior has changed.
- [x] No new semantic token was added directly to `MetadataContext`.
- [x] No Configuration stores resolved asset values.

### Phase 3: Location Resolver

- [x] Task 3.1: Add LocationResolver
  - Description: Resolve the final `location` expression value from
    `LocationContext` and `LocationPresentationMode`.
  - Acceptance:
    - Resolver consumes only `LocationContext` and resolution configuration.
    - Resolver chooses province + city, city + district, province + city +
      district, coordinate behavior, downgrade behavior, or fallback behavior.
    - `LocationResolution` records requested presentation, resolved
      presentation, and resolution policy for the current request only.
    - `LocationResolution` does not hold `LocationContext` or formatted text.
    - Formatter produces the final string from `LocationContext` and
      `LocationResolution`.
    - Resolver is deterministic for the same `LocationContext` and
      configuration.
    - `LocationResolution` is never stored in Configuration, persisted state,
      Renderer, or provider-owned domain data.
    - Resolver has no renderer, template, or UI dependency.
  - Verify:
    - focused resolver tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Presentation/LocationResolver.swift`
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Presentation/LocationResolution.swift`
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Presentation/LocationPresentationMode.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/LocationExpressionPhase3Tests.swift`
  - Estimated scope: Medium

### Phase 4-A: Expression System Contract

- [x] Task 4.1: Establish platform Expression System Contract
  - Description: Define the shared platform-level expression pipeline and hard
    rules before Provider integration begins.
  - Acceptance:
    - Contract defines Builder, Context, Resolver, Resolution, Formatter,
      Expression Value, Provider, ExpressionContext, and Renderer boundaries.
    - Contract does not require Location Provider implementation.
    - Contract does not modify production code.
  - Verify:
    - `git diff --check`
  - Files likely touched:
    - `Docs/02_Architecture/Contract/Expression_System_Contract.md`
  - Estimated scope: Small

### Phase 4-B: Expression Value Contract

- [x] Task 4.2: Define provider-neutral Expression Value contract
  - Description: Define the intermediate expression output shape that
    Providers emit before values enter `ExpressionContext`.
  - Acceptance:
    - Expression Value carries semantic token identity and resolved display
      value without exposing provider-specific `Resolution` types.
    - Provider output is not modeled as a bare `String`.
    - Expression Value does not depend on Renderer, Template, Inspector, or UI.
  - Verify:
    - focused Expression Value contract tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/Expression/`
    - `Tests/PhotoMemoTests/ArchitectureTests/`
  - Estimated scope: Medium

### Phase 4-C: ExpressionContext

- [x] Task 4.3: Introduce additive ExpressionContext
  - Description: Add a provider-produced token store without replacing
    `MetadataContext`.
  - Acceptance:
    - `ExpressionContext` stores Expression Values by semantic token.
    - duplicate canonical token ownership is prevented or test-detected.
    - `ExpressionContext` does not import renderer or UI types.
  - Verify:
    - focused ExpressionContext tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/Expression/ExpressionContext.swift`
    - `Source/PhotoMemo/PhotoMemo/Expression/ExpressionProvider.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/ExpressionContextTests.swift`
  - Estimated scope: Medium

### Phase 4-D: Location Expression Provider

### Checkpoint: Expression System Smoke

- [x] Fake Providers can emit `ExpressionValue` into a shared
  `ExpressionContext`.
- [x] A mock renderer can consume only `ExpressionContext` without provider,
  resolver, formatter, or context knowledge.
- [x] Duplicate semantic tokens remain rejected at the `ExpressionContext`
  boundary.
- [x] This checkpoint does not implement or freeze production Provider output
  APIs.

- [x] Task 4.4: Add LocationExpressionProvider
  - Description: Compile resolved Location domain output into the provider-
    neutral Expression Language.
  - Acceptance:
    - Phase 4-D Provider supports only the `location` semantic token.
    - Raw `latitude`, `longitude`, and `altitude` tokens remain future
      Location Provider expansion work.
    - Provider consumes `LocationContext`, `LocationResolver`, and
      `LocationFormatter`; it does not read `PhotoMetadata` directly.
    - Provider does not reimplement presentation, fallback, downgrade, or
      string-shaping logic.
    - Provider does not output Metadata or Memory tokens.
    - Provider ownership is locked by tests.
    - Provider output uses the provider-neutral Expression Value contract.
    - `ExpressionContext` can store the first real Provider output.
  - Verify:
    - focused provider ownership tests pass
    - Location Phase 0-4D regression tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/Providers/LocationExpressionProvider.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/LocationExpressionPhase4DTests.swift`
  - Estimated scope: Medium

### Checkpoint: Provider Model

- [x] Location Provider can produce `location` into `ExpressionContext`.
- [x] Provider ownership is test-covered for the Phase 4-D `location` token.
- [x] `MetadataContext` remains unchanged except for future adapter work.
- [x] Provider output remains independent from Renderer, Template, Inspector,
      and UI.

### Phase 5: Legacy Adapter

- [ ] Task 5.1: Add ExpressionContext to MetadataContext adapter
  - Description: Bridge provider output into the V1 legacy pipeline without
    making `MetadataContext` the semantic source of truth.
  - Acceptance:
    - Adapter can project `location` into legacy `location_display` if needed.
    - Adapter can project raw `latitude`, `longitude`, and `altitude`.
    - Existing `TemplateVariableEngine` behavior remains unchanged.
  - Verify:
    - adapter tests pass
    - existing `MetadataContextTests` and `TemplateVariableEngineTests` pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/Expression/ExpressionContextMetadataAdapter.swift`
    - `Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift`
    - `Tests/PhotoMemoTests/VariableTests/MetadataContextTests.swift`
    - `Tests/PhotoMemoTests/VariableTests/TemplateVariableEngineTests.swift`
  - Estimated scope: Medium

### Phase 6: Preview Convergence

- [ ] Task 6.1: Replace preview-local location demo values
  - Description: Make V1 preview location text come from normal
    `ExpressionContext` built from sample preview values instead of hardcoded
    sample strings.
  - Acceptance:
    - `V1PreviewCompositionEngine` no longer contains demo location strings
      such as `河南 · 商丘`.
    - Preview and production both feed Renderer through `ExpressionContext`.
    - No `PreviewExpressionContext` model is introduced.
    - Missing location data renders empty or configured fallback text.
  - Verify:
    - focused V1 preview composition tests pass
    - preview/export consistency tests pass where applicable
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/PreviewCompositionMigrationTests.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/V1DraftMutationCoordinatorTests.swift`
  - Estimated scope: Medium

### Phase 7: Inspector Configuration

- [ ] Task 7.1: Persist Location module presentation configuration
  - Description: Store `LocationPresentationMode` and fallback options as
    module configuration, not transient UI state.
  - Acceptance:
    - Location module instances preserve presentation configuration through
      save, restore, and snapshot creation.
    - Configuration flows do not create separate module types for Province +
      City, City + District, Province + City + District, or Coordinate.
    - Fallback options support Empty, Hide Module, and Placeholder as reusable
      Expression Module configuration.
    - Renderer receives resolved text only.
  - Verify:
    - configuration persistence tests pass
    - focused iOS configuration tests pass
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/`
    - `Source/PhotoMemo/PhotoMemo/iOS/Views/`
    - `Tests/PhotoMemoTests/ArchitectureTests/`
  - Estimated scope: Medium

### Deferred Phase 8: Reverse Geocoder Adapter

- [ ] Task 8.1: Add AppleReverseGeocoder behind protocol
  - Description: Add an optional Apple adapter behind `ReverseGeocoder`.
  - Acceptance:
    - Core workflow remains local-first and does not require network access.
    - Provider code does not change when the adapter is absent.
    - Cache strategy is explicitly reviewed before default use.
  - Verify:
    - adapter tests use mocked geocoder behavior
  - Files likely touched:
    - `Source/PhotoMemo/PhotoMemo/LocationExpression/AppleReverseGeocoder.swift`
    - `Tests/PhotoMemoTests/ArchitectureTests/LocationExpressionTests.swift`
  - Estimated scope: Medium

### Deferred Phase 9: Location Intelligence

- [ ] Task 9.1: Define POI, Landmark, and Visit semantics
  - Description: Treat richer location intelligence as V2 work after provider
    architecture is stable.
  - Acceptance:
    - POI and Landmark ownership is explicitly decided.
    - Visit count and first-visit logic do not backdoor into Renderer or
      `MetadataContext`.
  - Verify:
    - new Proposal or ADR exists before code
  - Files likely touched:
    - `Docs/02_Architecture/Proposal/`
  - Estimated scope: Documentation first

## Verification Commands

Preferred build command:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Focused tests should be added per phase. After production-facing phases, run
the relevant architecture, variable, preview, and configuration test groups
before closing the task.

## Risks And Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| `MetadataContext` becomes the center again | High | enforce the guardrail that new semantic tokens enter through Providers first |
| Preview diverges from production | High | remove demo values only after provider output can feed preview |
| Presentation state is stored only in UI | High | require module configuration persistence tests |
| Reverse geocoding adds network dependency | Medium | keep geocoder behind protocol and defer default adapter |
| Token ownership collisions appear | Medium | add provider ownership tests |

## Approval Boundary

Do not begin code implementation from this plan until the plan is reviewed and
accepted. The first implementation slice should be Phase 0 only.
