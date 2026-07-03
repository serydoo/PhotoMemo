# V1 Preview Renderer Export Contract Review

Date: 2026-07-03
Scope: current V1 iOS configuration/editor preview flow, production preview flow,
and export/render flow in the current repository checkout.

## Executive Conclusion

The current V1 codebase is not on a single end-to-end text/render contract yet.

It is operating with three connected but still distinct tracks:

1. Preview/editor track
   `V1EditorDraft -> V1PreviewDraft -> V1PreviewCompositionEngine -> region preview text`
2. Production render/export track
   `BatchConfigurationSnapshot -> RecordCardBuildService -> RecordCard -> CardVariableProvider -> CardTextBlockEngine -> RecordCardRenderer -> RecordCardExportService`
3. New memory semantic track
   `ConfigurationSnapshot -> MemoryExpressionEngine -> MemoryModule`

The best news is that the renderer boundary is relatively clean and the
production path has already started to carry `MemoryModule`.

The main risk is earlier in the pipeline:

- preview still composes text locally
- multiple preview/token composition layers exist
- `singleLineTemplateText` no longer has one stable meaning in all call sites
- persisted production configuration is still not a self-contained semantic
  snapshot

This makes the current `V1DraftOrchestrationCoordinatorTests` failure look more
like a contract symptom than a safe local bug fix target.

## Contract Map

```text
V1 editor state
    │
    ▼
V1EditorDraft
    │
    ├── singleLineText ------------------------------► UI/editor composed text
    │
    └── singleLineTemplateText
            │
            ▼
        TemplateArea.value
            │
            ▼
BatchConfigurationSnapshot
    │
    ▼
RecordCardBuildService
    │
    ├── AnchorEngine -------------------------------► AnchorResult
    │
    ├── ProductionMemoryResolver
    │       │
    │       └── ConfigurationSnapshot
    │               │
    │               ▼
    │           MemoryExpressionEngine
    │               │
    │               ▼
    │           MemoryModule
    │
    ▼
RecordCard
    │
    ▼
CardVariableProvider
    │
    ├── legacy MetadataContext values
    ├── legacy anchor-derived values
    └── compatibility projection:
        MemoryModule.renderedText -> memory_summary
    │
    ▼
CardTextBlockEngine
    │
    ▼
RecordCardRenderer
    │
    ▼
RecordCardExportService
```

## Node Review

| Node | Input | Output | Recomputes? | Changes semantics? | Notes |
| --- | --- | --- | --- | --- | --- |
| `V1EditorDraft` | editable items | `singleLineText`, `singleLineTemplateText` | no | yes, because it exposes both display text and template text | this is the first semantic split |
| `V1PreviewCompositionEngine` | `V1PreviewDraft` + preview context | display string | yes | yes | resolves token display values locally |
| `ConfigurationSession` | selected subject + session state | `ConfigurationSnapshot`, `MemoryModule`, region preview texts | yes | yes | new semantic path exists here |
| `BatchConfigurationSnapshot` | saved template/badge/anchor/description | persisted production config | no | yes, by omission | does not carry subject or memory snapshot |
| `RecordCardBuildService` | photo + batch snapshot + defaults | `RecordCard` | yes | partially | now carries `MemoryModule`, but via production reconstruction |
| `CardVariableProvider` | `RecordCard` | `MetadataContext` | yes | partially | projects new memory into old `memory_summary` slot |
| `RecordCardRenderer` | `RecordCard` | rendered image content | no meaningful business recompute | no | renderer mostly consumes already-resolved text |
| `RecordCardExportService` | photo + `RecordCard` | exported file + metadata | no content recompute | no | export consumes the built card |

## Token Resolver Inventory

These are the current text/value resolution layers relevant to this review:

1. `V1PreviewCompositionEngine`
   - resolves editor preview token display text
   - also provides hardcoded sample metadata values for many modules
2. `ConfigurationCenterPreviewCompositionHelper`
   - separately composes Configuration Center preview text
   - also carries hardcoded/sample metadata values
3. `TemplateVariableEngine`
   - performs production template token replacement against `MetadataContext`
4. `MemoryExpressionEngine`
   - semantic generator, not a general template expander
   - produces `MemoryModule.renderedText`

Conclusion:
there is only one production template expander, but there are at least two
preview-local composition layers plus one separate semantic memory generator.
So the contract is not single-source in preview land yet.

## Model Inventory

These types are currently serving different contract layers:

- `V1EditorDraft`
  - editor interaction model
- `V1PreviewDraft`
  - preview composition model
- `ConfigurationSnapshot`
  - semantic memory configuration model
- `MemoryModule`
  - resolved memory output model
- `BatchConfigurationSnapshot`
  - persisted production configuration shell
- `RecordCard`
  - renderer/export input model

Conclusion:
the project does not currently have one unified render-ready view model shared
by preview and export.

## Contract Review Findings

### CR-001 Preview still composes text outside the production render contract

Location:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterPreviewCompositionHelper.swift`

Current state:

- preview display text is composed locally from draft items
- token values are resolved inside preview-only helpers
- many metadata-like values are hardcoded sample values rather than coming from
  the production `RecordCard -> MetadataContext -> CardTextBlockEngine` path

Risk:

- preview can say one thing while export renders another
- fixing Draft-only regressions can hide upstream contract drift

Recommendation:

- preview should ultimately consume the same render-ready contract as export, or
  a shared model generated immediately before both preview and export

### CR-002 `singleLineTemplateText` no longer has one stable cross-layer meaning

Location:

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1EditorDraft.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift`
- `Tests/PhotoMemoTests/ArchitectureTests/V1DraftOrchestrationCoordinatorTests.swift`

Current state:

- the draft models define `singleLineTemplateText` as token-preserving template
  text via `savedValue`
- the failing orchestration test expects expanded display text instead

Risk:

- any local fix can accidentally collapse template semantics into display
  semantics
- the Draft layer can become a hiding place for contract drift

Recommendation:

- freeze the contract explicitly:
  `singleLineTemplateText` should remain persisted template text
- add a separately named expanded-preview field if a display string is needed

### CR-003 Production memory is only partially unified through a compatibility slot

Location:

- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`

Current state:

- production now resolves a `MemoryModule` during card build
- the resolved text is then projected into the legacy `memory_summary` variable
  slot
- renderer consumption stays on the old `TemplateVariableEngine` route

Risk:

- this is a good bridge for `{{memory_summary}}`
- but it is still a compatibility bridge, not a full shared presentation
  contract
- future memory-related variables can drift if they bypass this seam

Recommendation:

- treat `RecordCard.memoryModule -> CardVariableProvider.memory_summary` as an
  interim convergence seam, not the finished contract

### CR-004 Saved/export configuration is not a self-contained semantic snapshot

Location:

- `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift`
- `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift`
- `Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift`

Current state:

- `BatchConfigurationSnapshot` stores template, badge, anchor, and description
  preferences
- it does not store selected subject, `ConfigurationSnapshot`, or `MemoryModule`
- production meaning is reconstructed from `UserDefaults`, anchor selection, and
  capture date at build time

Risk:

- the same saved snapshot can resolve differently if ambient defaults change
- V1 apply/save is not yet preserving a fully reviewable render contract

Recommendation:

- the next contract-hardening step should persist explicit memory-config inputs
  instead of relying on ambient defaults

## Validated Non-Findings

These concerns look healthier than expected:

1. Renderer business boundary
   - `RecordCardRenderer` mainly routes by preset
   - concrete renderers consume `CardTextBlockEngine` output
   - renderer is not the main source of subject/memory/anchor drift

2. Export recomputation
   - `RecordCardExportService` renders the provided `RecordCard`
   - it does not independently regenerate memory text for the final image

## Recommended Fix Order

1. Do not patch `V1DraftOrchestrationCoordinator` first.
2. Freeze the meaning of `singleLineTemplateText`.
3. Decide the canonical shared render contract for preview and export.
4. Remove preview-local semantic drift by reducing local token/value composition.
5. Make saved production configuration carry explicit memory inputs.
6. Revisit the failing Draft test only after the contract decision is explicit.

## Draft-Test Interpretation

Based on the current code, the failing Draft orchestration test is most likely
surfacing this exact mismatch:

- the draft model still treats token `savedValue` as template contract
- at least one caller or test now expects expanded display text instead

That means the failing test should be treated as a contract-classification
problem first, and only secondarily as an implementation defect.
