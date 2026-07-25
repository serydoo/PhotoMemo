# iOS Horizontal Divider Consistency Pass

## Decision Gate

- Primary loop: Product Loop
- Observed scenario: Configuration Center row separators begin after the icon column, while the accepted Memory Subject detail uses quiet, symmetric content-width separators.
- Objective: Use the Memory Subject detail as the visual baseline for horizontal separators inside iOS cards and grouped rows.
- Scope: iOS presentation components only; no configuration state, Memory Engine, Renderer, export, Share Extension, or Layout Engine behavior changes.
- Source of truth: Existing card content insets remain owned by each surface; one shared divider owns color and hairline thickness.
- Apple-native capability: SwiftUI semantic separator color is reused through `ConfigurationUI.faintHairline`; no custom drawing API or new dependency is needed.
- Risk: P2. Main failure modes are asymmetric insets, nested double insets, and accidental changes to vertical or system-list separators.

## Intended Outcome

- Horizontal dividers use one shared semantic hairline component.
- Card dividers end symmetrically within the containing content area.
- Icon-bearing rows no longer push only the leading edge of the divider past the icon column.
- Vertical dividers and native `List` row separators retain their existing semantics.

## Verification

- Add an architecture contract for the shared divider and absence of legacy one-sided divider implementations.
- Run the focused Apple-native product surface contract suite.
- Build the iOS scheme with code signing disabled.
- Inspect the resulting diff and run `git diff --check`.
- Manual simulator comparison remains required for final visual acceptance.

## Verification Result

- Apple-native product surface contracts passed, including the new shared-divider contract.
- Generic iOS Simulator Debug build for `PhotoMemoiOS` completed successfully.
- Legacy one-sided `0.5` point hairline implementations were no longer found in the iOS view layer.
- Simulator install and launch succeeded, but the system Photos authorization sheet obscured the Configuration Center even after a `simctl privacy` grant. Final visual acceptance therefore remains manual rather than claimed from the blocked screenshot.
