# Advanced Modules Sheet Polish

Date: 2026-07-29

## Decision Gate

- Primary loop: Product Loop
- Risk: P1, because this is a primary iOS configuration interaction and the
  sheet currently wastes space and repeats its heading in the supplied device
  evidence.
- Observed scenario: the Advanced Modules sheet opens at an oversized default
  detent, shows `高级模块` both as the navigation title and as the grouped
  section heading, and uses inconsistent text-pair spacing across the two
  module rows.
- Scope: `V1AdvancedModulesSheet` and its focused source contract test only.
  Memory Engine, renderer, export, persistence, and the rest of Configuration
  Center remain out of scope.
- Source of truth: the iOS sheet owns presentation-only layout; the existing
  location and time presentation models continue to own option values.
- Apple-native capabilities evaluated: SwiftUI `NavigationStack`, grouped
  `List`, system `Menu`, and sheet detents remain the correct native controls.
  No custom picker or UIKit replacement is needed.

## Accepted Pass

- Default sheet detent is `height(390)` with `large` available for expansion.
- The navigation title is the single visible sheet heading; the redundant
  section header is removed.
- Title-to-description spacing is `4pt` from
  `MemoMarkDesignTokens.Spacing.extraSmall`.
- The vertical gap between a module's label group and its secondary control is
  `8pt` from `MemoMarkDesignTokens.Spacing.small`.

## Verification Plan

- Run the focused `PhotoMemoTests` contract group.
- Build the generic iOS Debug target with signing disabled.
- Run `git diff --check`.
- Physical-device visual acceptance of the advanced sheet and its native menu
  remains a follow-up verification item.
