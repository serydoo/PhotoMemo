# MemoMark Configuration Module Identity And Compatibility Specification

**Status:** Accepted for bounded implementation
**Date:** 2026-08-04
**Primary loop:** Engineering Loop
**Risk:** P0 — user-content preservation and memory truth; P1 — production compatibility, localization, and the primary configuration workflow

## Objective

Prevent persisted internal module names and unresolved expression tokens from
appearing in the Configuration Center. Existing and default configurations
must recover into stable editor modules without changing authored text or final
rendering semantics. Module titles must follow the interface language, while
preview and output values continue to follow the frozen configuration language.

## Evidence

- Physical-device screenshots show `Relationship Device Line` and raw
  `{{relationship_label}}` / `{{capture_date_display}}` expressions in the
  Configuration Center.
- Default Classic White and several legacy preset items store multiple tokens
  and literal text inside one variable `TemplateItem`.
- The current draft projection recognizes only values exactly equal to one
  insertable-module token and falls back to persisted `TemplateItem.name`.
- The preview composition resolver also recognizes only one complete token and
  therefore preserves the raw composite expression as its display value.
- Insertable and preview modules duplicate user-facing titles and metadata;
  their titles are hard-coded Simplified Chinese strings rather than one
  interface-language-aware source of truth.
- Legacy normalization replaces an entire region when only its first item
  matches an old built-in default. A multi-item region can therefore lose all
  later user-authored items when legacy settings are read and written back.
- Eleven module paths currently persist their preview sample when `token` and
  `rendererToken` are equal. Dynamic facts such as file format, ISO, aperture,
  orientation, and altitude can consequently become fixed sample text.
- The macOS Configuration Center maintains a third overlapping module catalog,
  and temporary inserted modules identify location through localized title plus
  icon instead of stable identity.
- Preview composition does not carry the selected configuration language
  explicitly, so output-language formatting can briefly follow global state
  while configurations change.

## Ownership And Dependency Direction

- The durable configuration aggregate remains the only saved configuration
  source of truth.
- `TemplateItem.value` remains the lossless authored expression source.
- One iOS module catalog owns stable module identity, accepted token aliases,
  icon, category, and localized user-facing title.
- The macOS Configuration Center uses a thin projection of the same stable
  identity while retaining its existing preview samples and legacy token alias.
- The configuration draft projection owns compatibility parsing from persisted
  template expressions into editor text/token items.
- Preview composition resolves canonical editor tokens through the existing
  presentation inputs. Renderer and Layout Engine receive unchanged template
  semantics and gain no new responsibility.

## Apple-Native Evaluation

SwiftUI locale propagation and the existing `MemoMarkLanguage` interface
preference are sufficient. The implementation requires no new framework,
permission, entitlement, background mode, network service, or user-data access.
Dynamic module titles must be resolved explicitly from the current interface
language because a runtime `String` passed to `Text` is not a localization key.

## Compatibility Contract

- Known composite expressions are parsed into ordered literal and token items
  without dropping whitespace, separators, unknown tokens, or authored text.
- Child editor identities derived from one persisted item are deterministic so
  SwiftUI does not rename or reorder modules during repeated projection.
- Exact single-token items continue to preserve their persisted UUID.
- Unknown tokens remain lossless and editable, use a localized safe title, and
  never expose a persisted internal English name as user-facing copy.
- Projection does not rewrite durable data. A later explicit save may write the
  already-supported canonical text/token sequence.
- Legacy default migration may replace a region only when the complete region
  is exactly the recognized single legacy item. Multi-item regions are never
  collapsed or overwritten.
- Legacy token aliases retain their existing display and output meaning. In
  particular, full capture-date expressions must not silently become short-date
  expressions.
- Dynamic modules always persist their production token. Preview samples remain
  display-only. Existing literal custom content remains literal by explicit
  policy rather than by token equality.

## Localization Contract

- Interface titles, categories, unknown-content labels, text labels, separators,
  and accessibility copy use the interface language.
- Preview values and exported card values use the selected configuration/output
  language carried explicitly by preview context.
- Persisted module identity and matching never depend on a localized title.
- `TemplateItem.name` and `TemplateArea.name` are compatibility metadata only
  and cannot be rendered as a user-facing module title.

## Project Structure And Style

- Canonical iOS module metadata stays in the existing iOS module-catalog area.
- Compatibility parsing stays beside `V1ConfigurationDraftProjection`.
- Preview resolution delegates to the canonical module catalog instead of
  maintaining a second metadata catalog.
- Tests remain in `Tests/PhotoMemoTests/ArchitectureTests` and use Swift Testing.
- Keep the change additive and surgical; do not introduce a persistence schema,
  external dependency, generic expression framework, or renderer-side fallback.

## Testing Strategy

Write failing behavior tests before production changes for:

1. direct Classic White projection into literal and recognized token items;
2. all built-in composite `TemplateItem` expressions;
3. unknown-token losslessness and localized safe presentation;
4. deterministic child identities across repeated projection;
5. save/reload preservation of canonical text/token sequences;
6. Simplified Chinese and English module-title parity;
7. source contracts preventing internal names and duplicate title catalogs.
8. multi-item legacy regions surviving normalization without content loss;
9. every dynamic module preserving its production token through save/reload;
10. stable temporary module identity replacing localized title/icon matching.

Run focused architecture tests first, then the complete serialized test suite,
the required unsigned macOS build, generic iOS/Share/Widget builds, localization
lint, whitespace validation, and an in-place signed-device installation.

## Boundaries

Always:

- preserve existing configuration data and exact expression order;
- preserve local-first behavior and preview/export semantics;
- keep interface language separate from output language;
- provide deterministic recovery for every built-in composite expression.
- refuse destructive legacy normalization of any multi-item region.

Review before:

- changing a renderer token or its output meaning;
- changing durable configuration encoding or migration-on-read behavior;
- removing a legacy alias after field evidence proves it is unused.

Never:

- show `TemplateItem.name` as a fallback title;
- discard an unknown token or user-authored literal;
- translate user-authored text during interface-language changes;
- move expression parsing or compatibility policy into Renderer or Layout Engine.

## Success Criteria

- The reported Classic White configuration shows localized module names and
  resolved preview content after cold launch, preset switching, and reload.
- No built-in composite item can display raw braces or an internal English name
  in the Configuration Center.
- English interface mode contains no hard-coded Chinese module titles; Chinese
  interface mode contains no internal English module names.
- Existing saved configurations and unknown future tokens remain lossless.
- Dynamic modules never persist preview fixtures such as `HEIC`, `ISO80`, or
  `42m` as production configuration values.
- Focused and complete verification pass, and the signed build installs over
  the existing app without deleting its configuration container.

## Implementation Tasks

1. Add red tests for destructive migration and dynamic-token persistence.
2. Add red tests for composite projection and title-language behavior.
3. Make one module catalog the metadata and localization source of truth.
4. Add deterministic lossless expression-to-draft compatibility parsing.
5. Delegate preview matching and language to explicit canonical inputs.
6. Replace localized title/icon identity checks with stable module identity.
7. Audit and close every internal-name or duplicate-title fallback.
8. Run automated, build, localization, and signed-device verification.
