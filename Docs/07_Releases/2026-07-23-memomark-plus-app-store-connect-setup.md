# MemoMark+ App Store Connect Setup

Date: 2026-07-23

This checklist configures the StoreKit product used by the single MemoMark iOS binary in TestFlight Sandbox and App Store Production.

## Product

- App: `时光记` / bundle identifier `com.serydoo.PhotoMemo.iOS`
- Type: Non-Consumable
- Reference name: `MemoMark+ Lifetime`
- Product ID: `com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime`
- Initial China storefront price: CNY 48 price tier
- Family Sharing: Enabled
- Chinese display name: `MemoMark+ 永久解锁`
- Chinese description: `无限创建成长记录，单次最多处理 40 张照片。`

The app reads `Product.displayPrice`; do not hard-code the localized price in release UI.

## Submission

1. Accept the Paid Apps Agreement and complete banking and tax information.
2. Create the non-consumable with the exact product ID above.
3. Add localization, pricing, availability, Family Sharing, and review screenshot.
4. Upload one Release build and test it through TestFlight. TestFlight transactions automatically use Sandbox and do not charge the tester.
5. Submit the MemoMark+ in-app purchase with the first app version that contains the purchase UI.
6. Select the same tested build for App Review. App Store installations use Production transactions without a different binary.

## Offer Codes

After the non-consumable is approved, create an Offer Code campaign for early TestFlight users, creators, and launch supporters. Prefer redemption URLs; the app also exposes Apple's system redemption sheet through `兑换 MemoMark+ 代码`.

Successful eligible redemptions receive the same MemoMark+ entitlement and first-recorder date mark as paid purchases.

## Device Acceptance

- Confirm TestFlight purchase clearly shows the Sandbox environment and produces no real charge.
- Confirm deleting and reinstalling the TestFlight build restores the Sandbox entitlement.
- Confirm the App Store build does not inherit Sandbox entitlement or Sandbox record count.
- Confirm a Production Offer Code unlocks MemoMark+ after installing from the App Store.
- Confirm Family Sharing restores the non-consumable for an eligible family member.
- Confirm free users accept 20 photos, MemoMark+ accepts 40, and the 41st photo is rejected before intake.
