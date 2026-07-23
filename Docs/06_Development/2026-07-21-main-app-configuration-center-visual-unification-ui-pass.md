# Main App Configuration Center Visual Unification UI Pass

Date: 2026-07-21

## Observed Current Behavior

- Configuration Center is the clearest current iOS visual reference.
- Memory Subject pages already use the shared `V1CardSurface` direction, but
  several cards have no semantic heading icon and some inner panels still use
  local radius and padding values.
- Home subject summaries still contain direct SF Symbol strings for concepts
  already represented by `MemoMarkSymbol`.
- Output, Task, Settings, and Welcome surfaces share the same general light
  system direction but retain local card, typography, spacing, and icon choices.

## Intended Outcome

- Use Configuration Center's existing visual language as the main-app baseline:
  bounded page content, `V1CardSurface`, `V1ConfigurationCardContainer`,
  compact semantic icon tiles, and clear outer-card/inner-panel hierarchy.
- Make Memory Subject and its Home summary read as the same product family as
  Configuration Center before extending the same primitives to adjacent pages.
- Keep all existing state ownership, navigation, persistence, actions,
  accessibility labels, Share Extension behavior, and renderer/export behavior.

## Scope

In scope:

- Main iOS visual primitives and semantic icon references.
- Memory Subject overview cards and Home subject summary.
- Later bounded migration of Output, Task, Settings, and Welcome surfaces.

Out of scope:

- IA-002 architecture changes.
- Share Extension's frozen `MemoMark Share Design v1` structure.
- Renderer, Layout Engine, Metadata, Export, Photo Library, and persistence.

## Verification Plan

- Add or update focused source contracts for shared visual metrics and semantic
  symbols.
- Run the focused PhotoMemoTests suites after each implementation slice.
- Run the full unsigned macOS Debug test suite and the required Debug build.
- Perform physical-device visual inspection for Configuration Center, Memory
  Subject, Home summary, Output, Task, Settings, and Welcome at default and
  accessibility text sizes. Manual visual acceptance remains required.

## Closure

Implemented:

- `ConfigurationUI` now owns the shared main-app card, inner-panel, content
  column, compact icon, and compact row metrics used by the migrated surfaces.
- `V1CardSurface`, `V1ConfigurationCardContainer`, and the subject overview
  hierarchy now share Configuration Center card chrome and semantic heading
  icons.
- Home, Output, Task, Settings, Welcome, and subject configuration surfaces now
  use the centralized `MemoMarkSymbol` catalog for domain concepts.
- Share Extension structure and its separate 24pt card contract remain frozen.

Evidence:

- Focused responsive-layout, Home quick-action, and symbol-catalog suites pass.
- The full unsigned `PhotoMemoTests` suite passes.
- Unsigned macOS `PhotoMemo` and generic iOS `PhotoMemoiOS` Debug builds pass.
- `git diff --check` passes.

Remaining acceptance:

- Default-size, Dynamic Type, dark-mode, and full navigation-sequence visual
  inspection on a physical iPhone remains required.
- Live Apple Photos Share-sheet visual acceptance remains pending and is
  tracked independently from this main-app pass.
