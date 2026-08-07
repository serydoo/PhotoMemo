# UI-17PM-018 Surface Hierarchy Refinement

Date: 2026-08-08

Primary loop: Product Loop

Risk: P1 - the work changes the primary Home, Configuration, Settings, and
Memory Subject surfaces, but must preserve every existing state, action,
persistence path, and Memory Card rendering boundary.

## Observed State

Physical-device screenshots show repeated equal-weight containers:

`page -> section card -> content card -> row/control`

The repetition is strongest on Home, Configuration, and Settings. It makes
section wrappers compete visually with the actual Memory Subject, Preset,
Renderer, entitlement, and status objects.

## Accepted Outcome

MemoMark uses four surface levels:

1. page background owns page and section headings;
2. cards represent real objects, primary results, entitlements, or status;
3. one grouped content surface contains related rows and dividers;
4. controls remain controls and do not create another card level.

This pass removes only section wrappers without independent object meaning.

## Scope

- Home: flatten the Memory Subject and Preset section wrappers while retaining
  the subject object surface, individual Preset rows, header titles, subtitles,
  and trailing actions.
- Configuration: keep the Renderer as the primary card; flatten the Memory
  Source and Card Layout section wrappers while retaining their grouped row
  surfaces and disclosure behavior.
- Settings: keep the MemoMark+ entitlement card; flatten ordinary disclosure
  section wrappers while retaining headers, expanded grouped content, state,
  and accessibility behavior.
- Memory Subject: flatten the `基础资料` and `时间锚点` wrappers in both the
  reading and editing flows while retaining the identity summary, editable
  field group, anchor rows, edit action, destructive confirmation, and draft
  save transaction.
- Primary actions: use one restrained shadow treatment across shared and
  configuration-save buttons.

## Outside Scope

- Renderer, Layout Engine, Export, Apple Photos, StoreKit, persistence, and
  navigation behavior.
- TextKit content editing, module insertion, keyboard behavior, and editor
  dismissal.
- Save, Progress, and modal-sheet restructuring beyond the two existing Memory
  Subject reading/editing surfaces.
- Typography, semantic colors, bottom navigation, and product copy.

## Verification

- Source contracts prove Home, Configuration, and Memory Subject use a
  header-on-page section surface and Settings disclosure sections no longer
  apply outer card chrome.
- Existing object cards, Renderer, Preset rows, and MemoMark+ remain present.
- Focused UI contracts and `git diff --check` pass.
- Full `PhotoMemoTests` and generic iOS Debug build are reported separately.
- A signed build is overwritten on the connected iPhone without uninstalling
  or clearing app data.
- Manual acceptance compares visual hierarchy, scrolling, disclosure actions,
  Preset selection, configuration editing, and save actions.
