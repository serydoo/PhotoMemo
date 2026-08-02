# First Recorder Projection Correction

Date: 2026-08-03

## Decision Gate

- Primary loop: Engineering Loop
- Risk: P1 - the current Settings presentation can claim an unavailable paid
  capability after refund or revocation, and the same incorrect meaning is
  exposed to VoiceOver.
- Observed scenario: `V1SettingsPageSurface` evaluates a persisted
  `firstRecorderDate` before current Plus Access. A person whose current Access
  is free but whose historical First Recorder date remains therefore sees
  `First Recorder / Unlimited Records` even though unlimited recording is no
  longer available.
- Intended outcome: project historical First Recorder identity independently
  from current capability. Only current Access may produce unlimited-record
  language.

## Scope And Ownership

In scope:

- Settings MemoMark+ card status and accessibility projection.
- Simplified Chinese and English commemorative copy.
- Locale-aware presentation of the existing original First Recorder date.
- Focused Commerce UI source-contract tests.

Explicitly out of scope:

- StoreKit and transaction verification.
- Entitlement resolution, purchase, restore, refund, revocation, Offer Code,
  and Family Sharing behavior.
- `firstRecorderDate` persistence or derivation.
- Allowance counters, Growth Record counting, and admission behavior.
- MemoMark+ purchase-page behavior or any product-model change.

The existing Commerce snapshot remains the only input. Current Access remains
the capability authority; the persisted First Recorder date remains historical
identity. This pass changes only how those accepted facts are combined for
presentation.

## Projection Contract

The Settings MemoMark+ card evaluates states in this order:

1. Temporary TestFlight Access.
2. Verified Plus Access with a First Recorder date.
3. Verified Plus Access without a First Recorder date.
4. Free Access with a historical First Recorder date.
5. Ordinary free Access.

The historical free state shows a restrained commemorative label and the
localized original date. It must never include `无限记录` or `Unlimited
Records`. VoiceOver label, value, and hint must preserve the same distinction.

## Apple-Native Evaluation

The existing SwiftUI `Button` remains the interaction owner. Explicit
accessibility label, value, and state-specific hint are sufficient; no custom
accessibility element or UIKit bridge is required. Foundation
`Date.FormatStyle`, configured with the current MemoMark interface locale,
formats the already-stored date without changing date ownership or persistence.

No StoreKit API is needed for this correction because the view already receives
resolved Access and identity facts through its Commerce snapshot.

## Risks And Verification

Risks:

1. Identity-first branch ordering could continue to leak unlimited capability.
2. Chinese and English resource keys or date presentation could diverge.
3. Visible text and VoiceOver could communicate different capability states.
4. A broad Commerce change could unintentionally exceed the frozen boundary.

Verification:

1. Add a failing focused UI contract proving Access-first branch ordering,
   historical commemorative copy, localized date formatting, and explicit
   accessibility semantics.
2. Make the smallest Settings and paired localization change required for the
   contract to pass.
3. Run localization syntax and bilingual-key parity checks.
4. Run focused Commerce tests and the required unsigned Debug build.
5. Record simulator or physical-device visual and VoiceOver acceptance as
   pending unless it is directly observed; do not infer it from source tests or
   a successful build.

## Verification Result

- RED: the new `settingsFirstRecorderProjectionIsAccessFirst` contract failed
  against the original identity-first Settings projection. The first test
  attempt was stopped before execution by missing local signing; the accepted
  RED evidence is the subsequent unsigned run in which this new test alone
  failed and the other nine Commerce UI contracts passed.
- GREEN: all 10 `MemoMarkCommerceUIContractTests` passed after the bounded
  projection correction.
- Regression: the Commerce policy, persistence, store, and UI groups passed 33
  tests with no failures.
- Localization: both `Localizable.strings` files passed `plutil -lint`, and the
  Commerce UI contract confirmed bilingual key parity.
- Build: the required unsigned Debug build passed. Existing `CLGeocoder` and
  `reverseGeocodeLocation` deprecation warnings remain outside this change.
- Full regression: the isolated candidate tree passed the complete serialized
  macOS suite with `1,220` tests passed, `1` skipped, and `0` failed. The
  structured result also recorded existing media-type declaration and test QoS
  runtime warnings; no failure was hidden or reclassified.
- Release contract maintenance: Build 66 replaced the stale Build 65 assertion.
  The iOS root size guard moved from `< 2,700` to `< 2,750` after the accepted
  Build 65 purchase-flow repair raised the root from 2,688 to 2,713 lines
  without updating that test-only threshold. No root-view source changed here.
- Diff: the scoped files passed `git diff --check`.
- Not manually verified: simulator or physical-device layout, Dynamic Type,
  VoiceOver traversal, real refund/revocation, and all external StoreKit paths.
  The isolated tree is not a frozen Release Candidate until its commit, signed
  Archive, and Installation Source are recorded; no release authorization is
  implied.
