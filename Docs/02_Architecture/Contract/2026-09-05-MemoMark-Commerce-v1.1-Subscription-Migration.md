# MemoMark Commerce v1.1 — Subscription Migration

Status: Accepted for the 2.3.0 / build 103 release slice

## Decision

MemoMark keeps the historical non-consumable product only as a legacy entitlement
source. It is no longer displayed or offered to new users. New users receive one
auto-renewable MemoMark+ subscription product:

`com.serydoo.PhotoMemo.iOS.memomarkplus.subscription.annual`

The initial commercial configuration is one annual subscription. The App Store
price is managed in App Store Connect; the app must display Apple's localized
`displayPrice` and period instead of hard-coding a currency amount.

The product name shown to users is `MemoMark+ 订阅会员` (localized by the app).
The old verified lifetime entitlement is shown as `MemoMark+ 永久权益`; where a
stored First Recorder identity exists, the account also shows `MemoMark 首批记录者`.

## Entitlement and identity boundaries

Capability and transaction origin are separate dimensions:

| Capability | Effective access | First-party expression styles | Collaborative content |
| --- | --- | --- | --- |
| Free | one memory object, one Time Anchor per object, unlimited processing within the base path | natural expression only | not included |
| Historical lifetime / activated historical code | permanent full core access | all first-party styles | separate SKU or grant |
| Active MemoMark+ annual subscription | access while valid | all first-party styles | separate SKU or grant |
| TestFlight temporary access | sandbox-only simulation | all first-party styles | not included |

Existing configurations, records, exports, and saved outputs are never deleted
or silently rewritten when access changes. A subscription expiry blocks only a
new paid operation; it does not invalidate already-created memories.

The historical lifetime product ID remains recognized by StoreKit. A verified
transaction from the old product is sufficient for the permanent entitlement;
the app does not need to distinguish direct purchase from an already-issued
historical activation code for capability purposes. New offer codes must belong
to the subscription product or a separately documented collaboration grant.

## Natural paywall moments

The purchase surface is opened only after a user expresses an intent that needs
paid capability:

- adding a second memory object;
- adding a second Time Anchor to an object;
- selecting a non-natural first-party expression style;
- selecting a separately licensed collaborative design;
- starting a batch above the free admission limit.

The surface is not opened on first launch, during permission requests, for an
error, when viewing or exporting existing data, or while restoring purchases.
After a successful purchase, the original editing or processing intent resumes.

## StoreKit and shared snapshot requirements

`MemoMarkCommerceStore` resolves entitlements in this order:

`historicalLifetime > activeSubscription > sandboxTemporary > free`

The shared snapshot must encode the effective access kind, the subscription
valid-through date when applicable, and the last verified time. Share Extension
admission may use the snapshot, but must never interpret an expired subscription
as a permanent entitlement. StoreKit verification remains the source of truth;
the snapshot is a bounded cross-target projection.

Legacy snapshots decode safely: old `verifiedPlus` values migrate to the
historical lifetime capability, while old TestFlight values remain sandbox-only.

## Release language

New public release and purchase copy must not mention the former early-bird
amount, the former standard amount, or a new lifetime purchase. Historical
users may see accurate account-specific language about their existing permanent
rights. All first-party expression styles are included in MemoMark+; only
explicitly marked collaborative designs may be sold or granted separately.
