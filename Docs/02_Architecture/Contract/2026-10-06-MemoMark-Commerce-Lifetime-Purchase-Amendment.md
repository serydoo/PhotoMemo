# MemoMark Commerce — Lifetime purchase amendment, 2026-10-06

Status: owner accepted; implementation local; public release and purchase acceptance pending.

## Observed failure and owner decision

New users cannot claim the approved lifetime product because the loader and purchase surface only offer subscriptions. The owner explicitly reinstates new lifetime purchases below subscriptions. This supersedes the restore-only paragraph in the build-104 amendment and the new-purchase exclusion in the September subscription migration contract; historical evidence remains unchanged.

Reuse `com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime`, approved non-consumable 6793883583. Apple verified transactions remain authoritative. Lifetime priority, restore, legacy grant provenance, shared snapshot rules, monthly/annual semantics, and durable keys remain unchanged. Lifetime purchase does not cancel an existing subscription.

## Purchase surface

Request all three products. Render separate lifetime action with StoreKit localized displayPrice. Use free-claim wording only when StoreKit product price equals zero. An unavailable SKU is retryable and never routes to a subscription. Serialize subscription/lifetime purchase actions. Existing lifetime holders retain their entitlement surface. Translate new strings in Simplified Chinese, English, Japanese, and Korean.

## Campaign accepted by owner

The repaired release must be publicly downloadable before the two-day lifetime window starts. At that point withdraw the temporary annual first-year-free introduction. Keep lifetime free for two further days; then restore China mainland lifetime price to CNY 68. Global storefront pricing must follow Apple's price schedule rather than a hard-coded app amount.

Current ASC observation: approved lifetime, all territories available, current AUTO_FREE, no scheduled restoration. A reference name saying two days does not impose an expiration. No backend pricing mutation made during diagnosis. The exact release instant is unknown, so no guessed calendar deadline is scheduled. The public campaign transition must read back Apple dates and prices when that instant is known. Removing an introductory offer does not revoke verified transactions already granted or cancel existing subscribers.

## Evidence boundary

1984 tests passed, 0 failed, 1 existing skipped; 2027 executions in xcresult. Signed physical iOS build, install and launch passed. Lifetime card visual acceptance, real StoreKit purchase/restore and production availability remain separate gates. See incident record for details.
