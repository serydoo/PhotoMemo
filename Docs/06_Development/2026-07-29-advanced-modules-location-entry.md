# Advanced Modules Location Entry

Date: 2026-07-29
Status: Implemented; scoped automated verification complete
Primary loop: Product Loop
Risk: P2

## Observed Behavior

Before this pass, the `卡片布局与内容` section exposed `位置显示` as an inline row
with its location-format menu directly visible beside the other card settings.
This makes one advanced display choice look like a primary card-layout choice
and does not match the existing `卡片内容 -> 编辑 -> Sheet` interaction.

## Intended Outcome

1. Remove the inline location-display row from the main card-settings list.
2. Add `高级模块` directly below `卡片内容` and above configuration status.
3. Use the subtitle `部分高级模块的展示形式选择`.
4. Match the `卡片内容` trailing action with an `编辑` label and disclosure
   chevron.
5. Present an Apple-native Sheet titled `高级模块` with a trailing `完成`
   action.
6. Keep only `地理显示` in the Sheet for this pass. Its existing dropdown
   options and menu interaction remain unchanged.
7. Keep the Sheet within the current iOS Configuration Center visual system:
   inset-grouped system presentation, inline navigation title, existing
   `subheadline` / `caption` typography, compact line spacing, and the shared
   `ConfigurationUI` control background, corner radius, and hairline tokens.
8. Preserve the existing responsive row rule: use the compact horizontal form
   when it fits, and switch the setting to a readable vertical form for narrow
   widths or accessibility Dynamic Type sizes.

## Ownership And Boundaries

- The change is limited to the active iPhone Configuration Center surface.
- `LocationDisplayInspectorPresenter` remains the source of dropdown content.
- The existing location binding remains the source of selection, persistence,
  preview refresh, and downstream configuration behavior.
- No Memory Engine, Layout Engine, Renderer, Export, metadata, or Apple Photos
  lifecycle behavior changes.
- No new persisted state is introduced.

## Apple-Native Reuse

- Reuse SwiftUI `sheet`, `NavigationStack`, the existing custom `Menu`
  selection appearance, and the confirmation toolbar placement.
- Preserve the existing menu options, selected-item checkmark, value pill,
  and selection semantics instead of creating a parallel control.
- Reuse the same system Sheet and list treatment already present in the module
  library and local-backup surfaces. Do not introduce a separate card or form
  style for this single advanced setting.
- Use the existing `ViewThatFits` / accessibility-size pattern so the new row
  does not compress or overlap its title and menu value.

## Failure Modes

- Moving the control could accidentally create a second local selection state.
- The original inline location row could remain visible, duplicating the entry.
- The Sheet could use a different option list or fail to persist the selection.
- The new row could appear in the wrong order relative to `卡片内容` and status.

## Verification Plan

- Add a source contract for row order, copy, Sheet title, completion action,
  typography, shared visual tokens, and reuse of the existing location
  presentation and binding.
- Run the focused configuration-option, native-interaction, narrative-language,
  and location-display contracts.
- Run the required unsigned Debug build and `git diff --check`.
- Simulator visual verification remains omitted at the product owner's request.

## Verification Results

- The source contract covering row order, copy, Sheet controls, menu reuse, and
  visual-system tokens passed together with the focused configuration-option
  coverage.
- The unsigned `PhotoMemoiOS` Debug build and `git diff --check` passed for the
  scoped pass.
- The final integrated `PhotoMemoTests` run passed 1,185 tests with one skip and
  zero failures, and the final unsigned generic iOS build passed. The signed
  integrated build was overwrite-installed and launched on the paired physical
  `iPhone7` without uninstalling the app or clearing its container.
- Simulator and manual visual acceptance were not performed. The current
  evidence therefore does not certify narrow-width, accessibility Dynamic Type,
  or physical-device interaction appearance.
