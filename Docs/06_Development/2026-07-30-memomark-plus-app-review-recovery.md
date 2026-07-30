# MemoMark+ App Review Recovery

Date: 2026-07-30

Status: Accepted Maintenance Scope

Primary loop: `Engineering Loop`

Risk: `P1`

## Outcome

Repair the MemoMark+ purchase interaction rejected under App Review Guideline
2.1(b), without changing the product, entitlement, pricing, allowance, or
Apple-managed commerce model.

For a user without a verified MemoMark+ entitlement, the purchase page must
present one real StoreKit purchase action. Selecting that action must produce
one of two observable outcomes:

1. Apple's purchase confirmation sheet is presented; or
2. MemoMark explains that the App Store is unavailable and keeps a retry path
   available.

The action must never appear to accept a tap while silently doing nothing.

## App Review Evidence

- Submission ID: `8f342045-9397-4b4f-bb29-ce8737ee1243`
- Review date: 2026-07-30
- Reviewed version: `2.0 (53)`
- Devices: iPhone 17 Pro Max and iPad Air 11-inch (M3)
- Systems: iOS 26.5.2 and iPadOS 26.5.2
- Guideline: `2.1(b) - Performance - App Completeness`
- Reported behavior: tapping MemoMark+ did not prompt a purchase.
- Associated IAP: `MemoMark+ 永久解锁`, non-consumable.

Apple explicitly states in the rejection that IAP products do not need prior
approval to function during review. The IAP's returned/rejected status is a
consequence of the associated app rejection and is not treated as the root
cause by itself.

## Confirmed Implementation Evidence

The supplied App Store Connect screenshot verifies the product identifier,
worldwide availability, and Family Sharing setting; price, tax, review
metadata, version association, and a real Sandbox transaction remain external
verification items. The reviewed `2.0` source line contains two deterministic
review risks:

1. `MemoMarkCommerceStore.refresh()` converts both a thrown product request and
   an empty product result into `product == nil`, then ends in `.idle` for a
   free user. The product-load failure is therefore not represented.
2. `MemoMarkPlusPurchaseView` disables the purchase control whenever
   `product == nil`. Because the disabled control cannot call
   `purchasePlus()`, the service's existing unavailable-store error is
   unreachable from the failed-load UI.
3. A Sandbox environment exposes a local `TestFlight` temporary-activation
   control as the prominent action and moves the real StoreKit purchase into a
   secondary action. App Review also exercises IAP through Sandbox, so Sandbox
   is not a reliable signal that the reviewer should receive a non-StoreKit
   activation path.

The same control flow exists in the repository's `2.0` release commit
`7cf36071`. This maintenance change corrects it for the next submission.

## Ownership And Boundaries

In scope:

- `MemoMarkCommerceStore` product loading and retry behavior
- `MemoMarkPlusPurchaseView` purchase, loading, unavailable, and legacy
  temporary-access presentation
- focused commerce regression tests and bilingual commerce copy
- App Review response and resubmission verification notes

Out of scope:

- product identifier changes without App Store Connect evidence
- price, product type, Family Sharing, free allowance, or batch-limit changes
- entitlement verification, transaction finishing, or restore semantics
- Renderer, Metadata, Export, Share Extension admission, PhotoKit, Layout
  Engine, configuration, or original-photo behavior
- a second purchase service or a new commerce architecture

StoreKit remains the canonical owner of product price, purchase confirmation,
verified entitlement, restoration, and Family Sharing eligibility.

## Apple-Native Evaluation

- Continue using StoreKit 2 `Product.products(for:)`, `Product.purchase()`,
  verified transactions, `Transaction.currentEntitlements`, and
  `AppStore.sync()`.
- Do not substitute a custom purchase confirmation or local unlock for the
  system purchase sheet.
- Keep App Review, TestFlight, and other Sandbox transactions on the same real
  StoreKit purchase path. Sandbox changes charging behavior; it must not change
  which purchase system owns the action.
- Preserve previously stored temporary TestFlight access long enough to let an
  existing tester leave it, but stop offering new local activation from the
  release purchase page.

## Failure Modes

- App Store Connect returns no product for the configured identifier.
- Product loading throws because the store is temporarily unavailable.
- A user taps while initial product loading is still in progress.
- A clean Sandbox/App Review install is routed to local activation instead of
  `Product.purchase()`.
- Existing temporary TestFlight access hides the permanent StoreKit purchase.
- A duplicate tap starts more than one purchase attempt.

## Bounded Implementation Plan

1. Add a failing regression contract for a retryable product-missing action and
   a single real StoreKit purchase path in Sandbox.
2. Make `purchasePlus()` reload the product when needed and surface a localized
   unavailable state when loading still yields no product.
3. Preserve the initial loading state, then publish either an available,
   purchased, or explicit unavailable result instead of silently returning to
   idle.
4. Present the same permanent StoreKit purchase action to every user without a
   verified entitlement, including App Review Sandbox and existing temporary
   TestFlight users. Keep only the legacy exit action for temporary access.
5. Run focused commerce tests, localization parity, an iOS build, diff review,
   and manual Sandbox acceptance on iPhone and iPad before resubmission.

## Verification Gate

Automated evidence:

- missing-product purchase attempts end in an explicit failed state
- the purchase control is not disabled merely because the product is absent
- release UI contains no local TestFlight activation action
- Sandbox and Production use the same `purchasePlus()` action
- focused commerce tests pass
- Simplified Chinese and English localization keys remain symmetric
- generic iOS Debug build passes

Required external evidence before resubmission:

- Paid Apps Agreement is active
- App Store Connect screenshot evidence from 2026-07-30 confirms the product
  ID exactly matches `com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime`, sales
  are enabled for all countries or regions, and Family Sharing is enabled
- IAP metadata, price, tax category, review screenshot, and corrected-version
  association are complete
- a clean physical-device Sandbox/TestFlight install displays the StoreKit
  price and Apple's purchase confirmation sheet
- purchase, cancellation, pending, success, restore, and unavailable/retry
  paths are manually observed
- iPhone and iPad layouts keep the purchase action visible and operable

Automated tests and unsigned builds cannot prove App Store Connect product
availability or Apple's system purchase sheet. Those claims require the named
external and physical-device evidence.

## 2026-07-30 Device Verification

- The settings-route contract first failed against the released V1 settings
  surface, then passed after the surface was connected to the runtime-owned
  commerce store. The focused commerce Store/UI suites passed `10` tests.
- A generic iOS Debug build and a signed `PhotoMemoiOS` Debug build both
  completed. The signed `2.0.1 (48)` package was installed in place and
  launched on the paired iPhone 17 Pro Max.
- On the physical device, `Settings -> MemoMark+ -> 查看权益` now presents the
  MemoMark+ purchase page. Its unavailable state shows a visible retry action
  and localized explanation instead of accepting a tap with no response.
- StoreKit still cannot return the configured product in the current Sandbox
  state, so this device result does not establish the Apple confirmation sheet.
  Correcting and resubmitting the App Store Connect IAP remains the external
  release gate.

## 2.0 (65) Candidate Alignment And Delivery

- The next App Review candidate retains the rejected app-release train as
  `2.0 (65)`. `MARKETING_VERSION` is `2.0` and `CURRENT_PROJECT_VERSION` is
  `65` for the iOS app, Share Extension, Widget Extension, macOS host, and
  test target. Historical `2.0.1 (48)` V3 release records remain unchanged.
- The in-app Update Log is aligned to `2.0 (65)` in Simplified Chinese and
  English. It explains the repair accurately: the permanent-unlock action
  requests StoreKit, while an unavailable App Store service explains the issue
  and preserves a retry action.
- The focused release-notes contract and focused commerce Store/UI, policy, and
  persistence suites passed. Both localization files passed syntax validation,
  and `git diff --check` passed.
- Generic iOS Debug and signed `PhotoMemoiOS` Debug builds completed. The signed
  bundle passed strict nested-signature verification; its app, Share Extension,
  and Widget Extension each report version `2.0 (65)`.
- The signed candidate was installed in place and launched on the wired paired
  iPhone 17 Pro Max (`iPhone7`) without uninstalling or clearing its container.
  The device reports `com.serydoo.PhotoMemo.iOS` as `2.0 (65)` and its main app
  and Widget Extension were observed running.
- This deployment proves packaging and launch only. It does not prove App Store
  Connect product availability or Apple's purchase-confirmation sheet, which
  remain the required clean Sandbox/TestFlight evidence before resubmission.

## Resubmission Notes

App Review path:

`Settings -> MemoMark+ -> permanent unlock action`

The permanent unlock action always invokes the StoreKit 2 purchase path for
the configured non-consumable product:

`com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime`

No reviewer account, local activation, or hidden test path is required. In
Sandbox, selecting the action requests the same Apple-owned purchase sheet as
production; Sandbox only changes the transaction environment and charge.

Suggested App Review response:

```text
Hello App Review Team,

We addressed the MemoMark+ in-app purchase issue reported for version 2.0.

Path: Settings -> MemoMark+ -> permanent unlock action.
The action now always invokes StoreKit for the non-consumable product
com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime, including in the Sandbox
environment used for review. No account or special test steps are required.

We verified the product-missing retry path and StoreKit purchase routing in
automated tests and will submit the corrected build for review.

Thank you.
```
