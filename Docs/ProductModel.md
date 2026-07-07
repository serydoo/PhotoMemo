# MemoMark Product Model

Last updated: 2026-06-20

## Design Mission

Configure once. Remember forever.

一次设定，永久记录。

This is now the clearest long-term definition of MemoMark:

- the Main App prepares the workflow
- the Share Extension executes the workflow
- the user should not need to reconfigure MemoMark during normal sharing

## Core Definition

MemoMark is not a photo editor.

MemoMark is a memory generation workflow built around Apple Photos.

Its long-term product shape is:

Personal Profile

-> Style

-> Workflow

This order matters.

Identity comes first.

Presentation comes second.

Execution comes last.

## The Three Layers

| Layer | Purpose | Owns | Must Not Own |
| --- | --- | --- | --- |
| Personal Profile | Represents the person, baby, and long-term family defaults | relationship, baby nickname, birthday, default album policy, default style, future family memory dates | renderer layout, template arrangement, share execution state |
| Style | Represents how a MemoMark card is generated | template structure, variable placement, layout, badge/logo choice, supplemental-description behavior, renderer-facing options | baby nickname, relationship, birthday, album destination |
| Workflow | Represents execution from Apple Photos to saved result | selected photos, share source context, generate/save progress, result status, temporary execution choices | identity setup, style authoring |

## Layer 1: Personal Profile

Personal Profile is the new long-term home for information that rarely changes.

Its job is to answer:

- Who is using MemoMark?
- Who is this family record about?
- Which album should results usually go to?
- Which style should be used by default?

Initial Personal Profile fields:

- `relationship`
- `customRelationshipLabel`
- `babyNickname`
- `babyBirthday`
- `defaultAlbumPolicy`
- `defaultAlbumIdentifier`
- `defaultAlbumTitle`
- `defaultStyleID`

Future-safe additions that still belong here:

- additional family memory dates
- multiple child profiles
- household naming preferences

Important rule:

Personal Profile owns identity.

Styles may reference identity-derived values, but they do not store them.

## Layer 2: Style

Style is the new product-facing name for how a memory card is composed.

A Style controls:

- layout preset
- visual arrangement
- displayed variables
- custom-region content
- bottom-card composition
- badge/logo behavior
- renderer-facing options
- supplemental description strategy

A Style does not control:

- who the baby is
- what the relationship is
- the birthday itself
- where the result is saved by default

Current repository mapping:

- `Template`
- `TemplatePreset`
- `Badge`
- custom region text
- right-bottom generated content
- style slot snapshots

These are already structurally close to Style data.

The main future change is mostly naming and responsibility cleanup, not a renderer rewrite.

## Layer 3: Workflow

Workflow is the execution path:

Apple Photos

-> Share

-> MemoMark

-> Generate

-> Save

Workflow should become increasingly automatic.

The Share Extension should read:

- Personal Profile
- default Style

Then execute generation and save-back with as few user decisions as possible.

Workflow must never ask for:

- relationship
- baby nickname
- birthday
- style authoring

Those belong to setup, not execution.

## First Run Experience

The first run should establish the workflow once and then disappear.

It should be shown only when MemoMark has no completed Personal Profile baseline.

Recommended one-time steps:

1. Welcome
   - Welcome to MemoMark
   - Let's spend one minute preparing your memory workflow.

2. Who are you?
   - Mother
   - Father
   - Family Member
   - Custom

3. Baby Information
   - Baby nickname
   - Birthday

4. Default Style
   - Recommend one style only
   - Example: Baby Growth (Recommended)

5. Output Album
   - Current Album
   - Create `MemoMark`
   - User Selected Album

First Run should not expose:

- template engine concepts
- anchor terminology
- multiple advanced style slots
- renderer detail
- background queue semantics

## Main App Structure

The Main App should gradually converge to four top-level sections:

1. Personal Profile
2. Styles
3. Settings
4. About

Meaning of each section:

- Personal Profile: identity, family defaults, birthday, default album, default style
- Styles: create, choose, rename, edit, preview, and save style variants
- Settings: permissions, notifications, import/export behavior, diagnostics, help
- About: version, roadmap, credits, support, product philosophy

What should leave the primary Main App surface over time:

- execution-heavy background status
- technical onboarding copy
- developer-facing terms
- repeated export explanations

## Share Extension Role

The Share Extension is not a setup surface.

It is not a profile editor.

It is not a style editor.

It should only:

- read Personal Profile
- read the default Style
- optionally show a light confirmation
- generate
- save

Any advanced control inside Share should be optional and secondary.

## Boundary Separation Report

| Current Repository Concept | Current Storage | Future Owner | Product Meaning | Notes |
| --- | --- | --- | --- | --- |
| `selectedTemplate` | `SettingsService` | Style | the current editable style content | already close to Style |
| `selectedBadge` | `SettingsService` | Style | logo/badge choice | already style-owned |
| `configurationSlots` | `SettingsService` | Style | saved style variants | rename from configuration slots to styles |
| `activeConfigurationSlotID` | `SettingsService` | Personal Profile | default style selection | style content stays in Style layer; the user's default choice belongs to profile |
| `anchors` | `SettingsService` | Split | birthday and future family dates -> Personal Profile; style reference choice -> Style/Workflow | current anchor model mixes identity and execution |
| `selectedAnchorID` | `SettingsService` | Personal Profile first, Workflow later | default memory date selection | user-facing terminology should become Birthday or Memory Date |
| `shouldWritePhotoDescription` | `SettingsService` / snapshot | Style | supplemental output behavior | affects generated result semantics |
| `photoDescriptionOverride` | `SettingsService` / snapshot | Style | style-authored supplemental text | belongs with generated card behavior, not profile |
| `selectedAlbumIdentifier` | `SettingsService` / snapshot | Personal Profile | default save destination policy | share flow should consume this automatically |
| `selectedAlbumTitle` | `SettingsService` | Personal Profile | user-facing default album label | presentation companion to album identity |
| `TemplatePreset` | template/style data | Style | recommended visual family | remains internal implementation detail if needed |
| `SelectedPhoto` | runtime only | Workflow | the photo being processed now | never persisted as profile/style |
| `BatchJob` / `BatchTask` | queue services | Workflow | background processing state | should stay out of Main App primary IA |
| permissions | `PermissionCenter` | Settings | app capability access | not profile, not style, not workflow content |

## Terminology Review

User-facing language should continue moving away from developer wording.

Recommended replacements:

| Current Term | New User Language | Keep As Internal? |
| --- | --- | --- |
| Workspace | Settings or Main App section name only if necessary | yes |
| Configuration | Style | yes |
| Configuration Slot | Saved Style | yes |
| Anchor | Birthday or Memory Date | yes |
| Batch Queue | Background Processing | yes |
| Snapshot | internal only | yes |
| Template Variable | Photo Info / Memory Module | yes |

Important rule:

If a term only exists because of implementation structure, users should not need to see it.

## Apple Product Review Lens

Each future design decision should be checked against these questions:

1. Would Apple expose this setting?
2. Would Apple ask the user to make this decision repeatedly?
3. Can this become automatic?
4. Does this belong in First Run instead?
5. Does this belong in Settings instead?
6. Can this disappear entirely?

High-confidence outcomes from this lens:

- share-time personal data entry should disappear
- default album choice belongs in setup, not daily flow
- style selection should usually happen once, then persist
- multiple choices should be hidden behind editing, not shown on first launch
- preview remains the trust surface, not the place for technical education

## Migration Plan

This product model should land in small compatibility-safe slices.

### Phase 1

Documentation and terminology alignment

- define Personal Profile
- redefine Style boundary
- freeze the Share-first workflow model

### Phase 2

Add Personal Profile storage without breaking existing settings

- create additive profile model
- derive initial values from current `SettingsService`
- keep existing UserDefaults readable

### Phase 3

Introduce First Run Experience

- gate on a one-time completion flag
- backfill existing users from current settings where possible
- do not force re-setup for existing users

### Phase 4

Retitle Main App structure

- Personal Profile
- Styles
- Settings
- About

### Phase 5

Teach Share to consume Personal Profile + default Style directly

- avoid share-time configuration edits by default
- keep any advanced actions optional

## Compatibility Assessment

This model can be introduced conservatively.

What can remain unchanged in the near term:

- renderer pipeline
- export pipeline
- batch queue model
- metadata pipeline
- share intake persistence
- style snapshot structure

What needs additive evolution:

- a new Personal Profile model
- first-run completion state
- migration from current anchor terminology to birthday/memory-date wording
- default style designation that points at an existing saved style

Recommended compatibility stance:

- preserve existing UserDefaults keys during transition
- backfill Personal Profile from existing values when possible
- keep `BatchConfigurationSnapshot` readable until the Profile + Style split is fully wired
- avoid one-shot destructive migration

## Recommended Implementation Order

1. Define `PersonalProfile` as additive domain data.
2. Add repository-level docs and user-facing terminology rules.
3. Backfill Personal Profile from current settings.
4. Introduce one-time First Run.
5. Rename visible Main App IA around Profile / Styles / Settings / About.
6. Make Share consume Profile + default Style automatically.
7. Only then reduce or remove old mixed settings paths.

## ADR Status

No ADR update is required in this round.

Reason:

- this document establishes the product model
- it does not yet implement a new runtime architecture boundary
- when code begins moving identity data out of the mixed settings layer, that implementation phase should decide whether an ADR is warranted
