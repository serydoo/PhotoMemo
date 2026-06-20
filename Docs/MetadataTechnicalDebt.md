# Metadata Technical Debt

Last updated: 2026-06-20

## Summary

PhotoMemo already has a good canonical pipeline shape, but the metadata layer now has several quality and maintenance gaps:

- model coverage is ahead of actual population for location fields
- runtime context coverage is ahead of public variable exposure
- date, locale, and formatting rules are duplicated
- there is little automated regression coverage for metadata correctness

None of these require a rewrite. They do require deliberate hardening work before the metadata surface grows further.

## 1. Current Limitations

| Priority | Limitation | Impact |
| --- | --- | --- |
| P1 | Friendly location fields exist in `PhotoMetadata` but are not populated by the current import flow | location variables are structurally present but practically unavailable |
| P1 | `MetadataContext` is string-only | missing vs empty vs zero cannot be distinguished cleanly |
| P1 | Capture-time normalization has no timezone model | future time-aware variables risk inconsistency |
| P1 | Variable catalog is incomplete relative to runtime context | picker/help/docs can drift away from actual engine behavior |
| P2 | Renderer/export rely on image width/height from metadata with fallback to decoded image size | mostly safe today, but future orientation/aspect variables need clearer rules |
| P2 | Share extension delays metadata validation until main-app import | intake succeeds earlier than metadata quality can be checked |

## 2. Duplicated Logic

| Priority | Duplication | Where |
| --- | --- | --- |
| P1 | Variable definitions are spread across multiple sources | `TemplateVariable`, `TemplateItem`, `MetadataContext`, `CardVariableProvider`, `EditorProjectionEngine` |
| P1 | Date formatting logic is split by use case with no central policy | `MetadataContext`, `CardVariableProvider`, `AnchorEngine`, runtime/title helpers |
| P2 | Camera summary formatting is separate from raw camera metadata normalization | `CardVariableProvider.cameraSummary` |
| P2 | Output description generation is separate from template preview concerns | `CardVariableProvider.exportDescription`, `RecordCardBuildService` |
| P2 | Supported-image assumptions are repeated across intake/import paths | import service, intake center, share extension |

## 3. Performance And Quality Concerns

| Priority | Concern | Why it matters |
| --- | --- | --- |
| P2 | `PhotoMetadataReader` builds date formatters on demand | repeated imports pay avoidable formatter allocation cost |
| P2 | `TemplateVariableEngine` recompiles its regex for each render call | repeated preview/export rendering pays repeated parse cost |
| P2 | `CardVariableProvider` creates new `DateFormatter` instances for display strings | repeated card builds create unnecessary formatter churn |
| P2 | Double values are stringified with default `Double -> String` formatting | GPS precision and altitude display may look noisy or unstable |

## 4. Missing Metadata

| Priority | Missing metadata | Current symptom |
| --- | --- | --- |
| P1 | GPS direction references and altitude reference handling | coordinates may be wrong in west/south or below-sea-level cases |
| P1 | Human-readable place resolution | `location`, `city`, `province`, `country` stay empty |
| P1 | Timezone / offset / subsecond capture-time data | precise time semantics cannot be trusted for future variables |
| P2 | Orientation | no first-class orientation variable |
| P2 | Aspect ratio and megapixels | common photo-summary variables cannot be offered |
| P2 | Flash, white balance, exposure bias, metering mode | photography-oriented templates are limited |
| P3 | Format / codec / color profile | export-audit and pro-camera use cases remain weak |

## 5. Potential Bugs

| Priority | Risk | Why it is risky |
| --- | --- | --- |
| P1 | GPS sign handling appears incomplete | `PhotoMetadataReader` reads latitude/longitude values but not their N/S/E/W reference tags |
| P1 | `TemplateVariableLibrary.recognized` prioritizes `{{location}}` without a matching public variable entry | public picker ordering and actual catalog are inconsistent |
| P1 | Hidden context keys such as `anchor_hours` / `anchor_minutes` / `anchor_seconds` are not cataloged | internal capability can drift silently |
| P2 | Locale strategy is inconsistent | `weekday_name` is English, anchor date is `zh_CN`, capture display uses POSIX formatting |
| P2 | Export preserves original metadata broadly with targeted overrides, not a documented allowlist | some downstream metadata mismatches may be hard to reason about |
| P2 | Empty `GeocoderService.swift` file suggests an unfinished or abandoned boundary | future contributors may assume location enrichment already exists |

## 6. Future Risks

| Priority | Risk | Result if ignored |
| --- | --- | --- |
| P1 | Adding more variables before normalizing ownership | variable surface grows faster than metadata quality |
| P1 | Expanding iPhone/share workflows before metadata regression coverage | background failures become harder to diagnose |
| P1 | Introducing location-facing UI before location pipeline exists | users see blank or inconsistent location results |
| P2 | Relying on string-only context for advanced computed variables | future bugs become harder to test and explain |
| P2 | Continuing to document variables manually in multiple places | help center, picker, editor, docs drift apart |

## 7. Suggested Priority Order

### P1: must harden next

1. Define a canonical metadata field and variable inventory.
2. Fix GPS normalization correctness, especially directional references.
3. Decide and document capture-time normalization policy.
4. Align public variable catalog with runtime context keys.
5. Add metadata regression tests around import -> variable -> export.

### P2: high-value follow-up

1. Wire friendly location enrichment into the existing `PhotoMetadata` model.
2. Add photo-shape metadata such as orientation, aspect ratio, and megapixels.
3. Centralize formatter policy for display strings.
4. Cache frequently reused regex/formatters.

### P3: later expansion

1. Add pro-camera metadata such as flash and white balance.
2. Add derived solar/season variables.
3. Add metadata audit tooling for save-back verification.

## 8. Recommended Engineering Stance

Do not solve this debt by adding a new abstraction layer first.

Solve it by tightening the existing pipeline:

- keep `PhotoMetadata` as the canonical typed model
- keep `MetadataContext` as the string-resolution bridge
- keep `TemplateVariableEngine` simple
- improve correctness, completeness, and catalog discipline around them
