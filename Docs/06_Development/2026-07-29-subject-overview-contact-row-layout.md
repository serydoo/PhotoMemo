# MemoMark Subject Overview Contact-Style Fact Rows

Date: 2026-07-29
Status: Implemented; scoped automated verification complete
Primary loop: Product Loop
Risk: P2

## Observed Scenario

Before this pass, the iOS `记忆对象` overview retained the intended identity
summary and grouped basic-information facts, but each optional fact presented
its label above its value. The resulting hierarchy reads as a compact form
rather than the familiar scan pattern of an iPhone contact detail.

## Intended Outcome

Within the existing `基础资料` section, present the existing optional facts as
one horizontal information row: label on the leading edge and value on the
trailing edge. Use the same `.body` text style for both, with secondary color
for labels and primary color for values. Preserve multiline values, the
identity summary, fact order, conditional visibility, dividers, edit action,
and time-anchor section unchanged.

On the `编辑记忆对象` surface, retain the existing vertical field structure:
field title above the entry area. Replace the visually plain entry line with a
direct bordered `TextField`, and expose a trailing clear action only when a
field contains text. Clearing changes the existing draft binding and keeps the
field focused; it does not bypass the existing draft and `完成` save flow.

## Boundaries And Ownership

- Affected presentation module:
  `V1IOSSubjectOverviewSheetSurface`, its private fact-row view, and the
  `identityOverview` field presentation inside `MemorySubjectEditorView`.
- Canonical data remains `MemorySubject`; no state, persistence, identity, or
  Memory Engine behavior changes.
- The existing `Library -> Interactive Memory Card -> Object Inspector`
  architecture remains unchanged.
- SwiftUI system typography, semantic foreground styles, and accessibility
  grouping are reused. Apple Contacts is a visual interaction reference only:
  this change does not read contacts, store contact identifiers, or request
  Contacts permission.

## Failure Modes And Mitigations

- Long values could become hard to scan: the value remains multiline and
  trailing-aligned within the flexible row width.
- Typography could look mismatched: labels and values use the same `.body`
  size and semantic colors distinguish their roles.
- A clear action could obscure the field or reset persisted data immediately:
  it appears only for non-empty draft bindings and uses the existing session
  synchronization and save boundary.
- A visual-only change could accidentally alter editing or memory behavior:
  the implementation is isolated to private presentation views and covered by
  a source contract.

## Verification Plan

1. Add a Swift Testing source contract asserting the horizontal hierarchy,
   unified body typography, semantic colors, multiline value behavior, and
   the edit field's direct input and clear action.
2. Run that focused test and the existing subject-overview contracts.
3. Build the iOS target with isolated DerivedData and run `git diff --check`.
4. Review the scoped diff. Simulator visual verification is intentionally out
   of scope under the product owner's earlier direction.

## Verification Results

- The new contract failed against the former vertical fact rows, then passed
  after implementation together with the existing
  `V1IOSSubjectOverviewPresenterTests` suite (11 tests).
- `AppleNativeProductSurfaceContractTests` passed after the change.
- An iOS Debug build for `PhotoMemoiOS` completed with isolated DerivedData.
- `git diff --check` passed.
- The combined Apple-native and responsive-layout run exposed one stale
  `IPhoneResponsiveLayoutContractTests` expectation for the retired
  configuration-page subtitle `调整记忆表达，并实时确认最终卡片。`. The later
  cross-pass review aligned that expectation with the approved narrative copy,
  and its focused rerun passed.
- The final integrated `PhotoMemoTests` run passed 1,185 tests with one skip and
  zero failures, and the final unsigned generic iOS build passed. The signed
  integrated build was overwrite-installed and launched on the paired physical
  `iPhone7` without uninstalling the app or clearing its container.
- Simulator and manual visual verification were not performed at the product
  owner's direction.
