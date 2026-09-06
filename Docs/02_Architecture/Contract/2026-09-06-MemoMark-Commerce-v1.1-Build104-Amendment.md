# MemoMark Commerce v1.1 — Build 104 Amendment

Status: Accepted for MemoMark 2.3.0 / build 104

This amendment supersedes the build-103 product-count statement in the
subscription migration contract. It does not rewrite build-103 evidence.

## Subscription products

MemoMark+ exposes two auto-renewable products in the same App Store
subscription group:

- Annual: `com.serydoo.PhotoMemo.iOS.memomarkplus.subscription.annual`
- Monthly: `com.serydoo.PhotoMemo.iOS.memomarkplus.subscription.monthly`

Both products provide the same MemoMark+ entitlement. Annual is presented as
the long-term value option and monthly as the flexible option. Period, price,
currency, renewal language, and regional availability are supplied by
StoreKit/App Store Connect; the app does not hard-code a commercial amount.
Upgrade, downgrade, renewal, cancellation, and expiration semantics remain
Apple-managed.

The historical lifetime product and previously granted activation entitlement
remain restore-only for existing users. They are not offered to new users and
remain higher priority than an active subscription when a verified entitlement
exists.

## Effective-access invariant

The effective priority is:

`verified historical lifetime > active annual/monthly subscription > sandbox temporary > free`

An expired subscription is normalized to the free policy before either the main
app or Share Extension makes an admission decision. Existing memories,
records, exports, and saved outputs remain available; only new Plus-only
operations return to the free boundary.

The shared snapshot is a cross-target projection, not proof of entitlement.
StoreKit current entitlements remain the source of truth. A legacy
`verifiedPlus` activation snapshot is migrated with an explicit
`hasDurableLegacyActivationGrant` provenance marker and may remain as a durable
historical grant. An ordinary `founderLifetime` snapshot does not carry that
marker and is not used to override a fresh StoreKit refresh that no longer
verifies the lifetime product.

## Build-104 interaction contract

- The Home photo-picker entry remains visible.
- After ten successful entries into the picker, a settings guide is shown for
  24 hours.
- The guide is invalidated at the expiration instant and re-evaluated when the
  app returns to the foreground.
- After 24 hours, only the guide disappears; the photo-picker entry and normal
  Apple Photos workflow remain available.
- The ten-use counter is a discoverability signal, not a free processing quota.

## Purchase disclosures

The purchase surface presents localized Privacy Policy and Terms of Use links.
The Privacy Policy points to the repository's published `PRIVACY.md`; Terms of
Use points to Apple's Standard EULA. App Store Connect metadata must continue
to use the same public policy URLs and the same two-product subscription group.
