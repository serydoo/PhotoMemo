# MemoMark Card Layout Row Order Pass

Date: 2026-07-29
Status: Implemented; automated verification complete
Primary loop: Product Loop
Risk: P2

## Observed Behavior

In the `卡片布局与内容` section, `Logo 标识` currently appears before
`边框样式`. The requested scan order is to show the border choice first and
the logo identity second.

## Intended Outcome

Swap the two sibling rows so the order is:

1. `边框样式`
2. `Logo 标识`

Each row keeps its current title, subtitle, value, control type, binding,
accessibility labels, and interaction behavior. The existing divider treatment
remains between rows and all following rows retain their current order.

## Scope And Boundaries

- In scope: sibling order inside `V1ConfigurationOptionList` and its source
  contract.
- Out of scope: border rendering, logo selection, custom logo loading,
  persistence, preview/export behavior, Renderer, Layout Engine, and
  localization content.

## Verification Plan

- Update the source contract to assert the requested relative order while
  preserving the existing row-content assertions.
- Run the focused `V1ConfigurationOptionListContractTests` suite.
- Run the unsigned `PhotoMemoiOS` Debug build and `git diff --check`.
- Rebuild the signed iOS target and overwrite-install it on `iPhone7` without
  uninstalling the app or clearing its container.
- Manual visual acceptance remains separate from source and build evidence.

## Verification Results

- The new order contract failed before the production edit while the other six
  tests in `V1ConfigurationOptionListContractTests` passed, confirming the
  expected RED state.
- After swapping only the two row calls, all seven focused contract tests
  passed. The contract also confirms that `边框样式` still uses
  `configurationTextRow` and `Logo 标识` still uses `configurationRow`.
- The unsigned generic `PhotoMemoiOS` Debug build, signed physical-device build,
  strict code-sign verification, and `git diff --check` passed.
- The signed build was overwrite-installed and launched on the paired physical
  `iPhone7` without uninstalling the app or clearing its container.
- Manual visual acceptance was not performed; installation and launch evidence
  does not certify the rendered row order by visual inspection.
