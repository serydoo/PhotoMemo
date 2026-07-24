# MemoMark Apple-Managed Commerce Design

Date: 2026-07-24
Status: Current commercial baseline; final UI copy pending localization freeze

## 1. Decision

MemoMark uses an Apple-managed commercial model for the current product stage.
Apple owns paid entitlement transactions, promotional redemption, restoration,
refund, revocation, storefront pricing, and Family Sharing eligibility.
MemoMark owns only the local free-record allowance and successful-save usage
ledger.

The current release does not require a custom commerce website, redemption
server, account system, consumable record packs, or operator database.

This document supersedes the earlier proposal for a custom Growth Record Gift
service and commerce administration website. That infrastructure remains a
future option only if demonstrated operational demand cannot be handled by
Apple Offer Codes and version gifts.

## 2. Product Model

### MemoMark Free

- 200 initial Growth Records;
- full-quality output;
- no advertisements;
- no forced watermark or reduced image quality;
- maximum 20 photos in one admitted batch;
- photos remain local and originals remain unchanged;
- only successful Apple Photos saves consume allowance.

Preview, render failure, cancellation, retry, failed PhotoKit save, and repeated
completion callbacks do not consume allowance.

### MemoMark+

- CNY 48 initial China storefront price;
- one-time non-consumable purchase;
- unlimited successful Growth Records;
- maximum 40 photos in one admitted batch;
- Family Sharing enabled where Apple determines eligibility;
- restoration through StoreKit;
- warm-gold MemoMark+ identity and First Recorder recognition when eligible;
- future core capability updates included within the frozen purchase promise.

StoreKit product identifier:

```text
com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime
```

The App always renders `Product.displayPrice`. CNY 48 is an App Store Connect
price decision, not a hard-coded UI string or global price promise.

### Deferred Record Packs

The previously discussed 100/300/800 record packs are not part of the current
commercial baseline. They should be reconsidered only when real usage evidence
shows a meaningful group that repeatedly reaches the free limit, declines the
lifetime purchase, and asks for lower-cost incremental access.

Deferring record packs avoids:

- weakening the clarity of the CNY 48 lifetime offer;
- consumable delivery and cross-device reconciliation complexity;
- additional App Store Connect products and review scope;
- a purchase page that feels like a quota shop;
- premature custom account or server requirements.

## 3. Commercial Ownership

### Apple Manages

- MemoMark+ product availability and localized storefront price;
- paid transactions and signed transaction evidence;
- Apple Offer Codes for MemoMark+;
- redemption eligibility, regional rules, and expiration;
- restore purchases;
- refunds and entitlement revocations;
- Family Sharing eligibility;
- Sandbox and Production transaction environments;
- App Store Connect transaction and campaign evidence.

### MemoMark Manages Locally

- initial 200-record allowance;
- additive major-version gifts;
- successful Apple Photos save count;
- idempotent completed-task identifiers;
- finite remaining allowance;
- progressive allowance disclosure;
- shared entitlement snapshot for the Share Extension;
- First Recorder presentation after a verified eligible entitlement.

### MemoMark Does Not Build Now

- custom redemption codes;
- recipient accounts;
- custom transaction or entitlement server;
- public balance lookup;
- external web checkout;
- consumable record-pack ledger;
- operator campaign console.

## 4. First Recorder Program

### Purpose

The First Recorder program thanks TestFlight contributors, early supporters,
creators, and people who provided meaningful product feedback. It is an
identity and appreciation program, not a visible scarcity promotion.

### Entitlement

Selected recipients receive an Apple Offer Code for the MemoMark+
non-consumable product. Successful redemption grants the same lifetime
entitlement as a paid purchase.

The App does not show:

- remaining purchaser count;
- countdown;
- fake stock;
- public ranking;
- pressure copy.

Internal campaign quantity can remain an operator decision inside App Store
Connect.

### User Experience

Before redemption:

```text
commerce.apple_code.action
commerce.apple_code.supporting_text
```

After a verified redemption:

```text
commerce.plus.title
commerce.plus.unlimited
commerce.first_recorder.title
commerce.first_recorder.date
```

Final Chinese and English strings remain blocked on the active localization
pass. Code and layouts must reference semantic localization keys.

### Operations

1. configure eligible MemoMark+ Offer Codes in App Store Connect;
2. record the Apple-provided expiration and regional terms;
3. distribute each code without payment or compensation;
4. include Apple's redemption instructions and applicable terms;
5. user redeems through Apple's system;
6. MemoMark observes a verified StoreKit entitlement;
7. the App switches to unlimited access and First Recorder presentation.

Apple Offer Code limits and expiration are accepted constraints. The
program does not promise indefinite code availability.

## 5. Version Growth Gifts

### Rule

Starting with MemoMark 2.0, each major version grants every Free user an
additional 100 Growth Records once.

Examples:

```text
Initial allowance     +200
MemoMark 2.0 gift     +100
MemoMark 3.0 gift     +100
Successful save         -1
```

The grant is additive. It never resets total allowance or successful usage.

### Why Additive Instead Of Reset

Resetting to 200 creates unequal value:

- a user with 150 remaining receives only 50 effective records;
- a user with zero remaining receives 200 effective records;
- users may intentionally spend allowance before an update;
- support cannot explain the resulting history clearly.

An additive gift preserves every user's existing balance and produces an
auditable local history.

### Idempotency

Each gift uses a stable identifier scoped by commerce environment, for example:

```text
major-2
major-3
```

Repeated launches, reinstalls that preserve the app container, repeated
migrations, and multiple callbacks must not apply the same gift twice.

### Presentation

The gift is announced once after it is applied:

```text
commerce.major_gift.title
commerce.major_gift.amount
commerce.major_gift.supporting_text
```

Example data, not frozen copy:

```text
MemoMark 2.0 Growth Gift
+100 Growth Records
```

MemoMark+ users do not need finite allowance. The gift may remain recorded for
future entitlement-revocation correctness, but the App does not interrupt an
unlimited user with quota messaging.

## 6. Allowance State Model

### Free, Before Record 190

- do not persistently show `used / total` on Home;
- Settings may describe the free experience without emphasizing depletion;
- do not show a progress bar that invites quota anxiety.

### Free, Records 190 Through Completion

- reveal remaining allowance in the existing progressive disclosure flow;
- record 190 presents the first gentle reminder;
- the final free record completes successfully before the purchase invitation;
- no task is admitted beyond the allowance after accounting for queued and
  in-flight reservations.

### Free, After A Major-Version Gift

- announce the added amount once;
- return to normal progressive disclosure when the new remaining allowance is
  above the reminder threshold;
- detailed Settings state may show the new total when the user explicitly opens
  commerce details.

### MemoMark+

Replace all finite progress UI with:

```text
commerce.plus.title
commerce.plus.unlimited
commerce.plus.lifetime_active
```

- do not show remaining records;
- do not show a finite progress bar;
- do not describe MemoMark+ as removing a restriction;
- retain the local finite ledger without presenting it.

If Apple revokes the entitlement, the App returns to the correctly derived
finite state rather than creating or resetting allowance.

## 7. Purchase And Redemption UI

### Settings

The MemoMark+ entry remains near the top of Settings because it is account-like
product status, not a secondary help feature.

Free state:

- MemoMark+ title;
- emotional continuity message;
- progressively disclosed allowance state;
- action to view MemoMark+.

Unlimited state:

- warm-gold MemoMark+ treatment;
- unlimited status;
- First Recorder identity when eligible;
- no purchase call to action.

### Purchase Page

The page remains focused on one decision:

1. continuity-focused headline;
2. unlimited Growth Records;
3. maximum 40-photo batch admission;
4. Family Sharing;
5. included core capability updates;
6. localized StoreKit price;
7. one primary purchase action;
8. Apple code redemption;
9. restore purchases;
10. purchase support and terms.

Do not add record-pack cards, custom code fields, a plan comparison grid,
countdowns, or purchaser counters in the current release.

### Redemption Entry

There is one code action:

```text
commerce.apple_code.action
```

It opens Apple's system redemption experience. MemoMark does not parse, store,
or validate Apple Offer Codes itself.

## 8. StoreKit State And Recovery

### TestFlight Temporary Experience

When the verified App transaction environment is Sandbox, a Free user may
explicitly activate temporary MemoMark+ TestFlight access. The activation is
stored only in the Sandbox namespace and grants unlimited records plus the
40-photo batch limit for product evaluation.

Temporary TestFlight access:

- never writes a Production entitlement;
- never grants First Recorder identity;
- remains visibly labeled as TestFlight access;
- keeps the real Sandbox purchase, Apple-code, and restore flows available for
  deliberate testing;
- is ignored automatically when the same binary runs with a Production App
  transaction environment.
- falls back to Production Free state when App transaction verification is
  unavailable; a persisted Sandbox environment is never trusted as a fallback.

### Required States

- idle;
- loading product;
- purchasing;
- pending approval;
- verified and purchased;
- user cancelled;
- failed verification or Store connection;
- revoked entitlement.

### Source Of Truth

- a verified current StoreKit entitlement grants MemoMark+;
- unverified transactions never grant entitlement;
- the App listens to transaction updates;
- restore calls `AppStore.sync()` and then refreshes current entitlements;
- refund or revocation removes unlimited access after verified state refresh;
- localized price always comes from StoreKit;
- Sandbox, Xcode, and Production local records remain isolated.

The Share Extension does not call StoreKit. It reads a minimal App Group
snapshot containing the explicit access source (`free`, `testFlightTemporary`,
or `verifiedPlus`), current finite allowance, and batch limit.

## 9. Website Scope

No custom commercial application website is required for this phase.

Required web-facing material is limited to:

- App Store product page;
- privacy policy;
- purchase and restore support page;
- First Recorder code distribution instructions when a campaign is active;
- contact channel for verified purchase problems.

The website does not include:

- external iOS digital-content checkout;
- custom code redemption;
- user allowance dashboard;
- transaction database;
- operator campaign console.

App Store Connect is the operator console for the current model.

## 10. Localization Contract

The commercial model is frozen before final copy. UI implementation must not
embed Chinese or English source text in commerce logic.

Required key families:

- `commerce.plus.*`
- `commerce.free_allowance.*`
- `commerce.major_gift.*`
- `commerce.first_recorder.*`
- `commerce.apple_code.*`
- `commerce.purchase_state.*`
- `commerce.restore.*`
- `commerce.support.*`

App Store Connect localization is maintained separately for:

- MemoMark+ display name;
- MemoMark+ description;
- App review notes;
- Offer Code distribution terms;
- App version release notes.

Final terminology and long-text layout validation occur after the active
language-resource pass reaches its first stable baseline.

## 11. App Store Connect Configuration

### MemoMark+

- type: Non-Consumable;
- reference name: `MemoMark+ Lifetime`;
- product identifier:
  `com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime`;
- initial China price: CNY 48;
- Family Sharing: enabled;
- availability: only storefronts where the App is distributed;
- localized product name and description: pending language freeze;
- review screenshot: purchase page showing the real product context.

### First Recorder Codes

- generate only after confirming current Apple eligibility and campaign limits;
- record request date and Apple expiration;
- distribute for free;
- include supported storefront and redemption instructions;
- do not sell, exchange, or require compensation for a code;
- reserve part of the campaign for TestFlight contributors, creators, media,
  and support cases.

## 12. Release Workflow

1. finish the current localization baseline;
2. update the MemoMark+ UI to use localization keys;
3. verify free, unlimited, pending, restore, redemption, and revoked states;
4. upload one Build to Xcode Cloud;
5. test the same Build through TestFlight Sandbox;
6. confirm counting, concurrency reservations, purchase, restore, and system
   redemption entry on a physical device;
7. attach MemoMark+ to the new App version;
8. submit the App version and first in-app purchase together when required;
9. after approval, distribute First Recorder promotional codes;
10. observe Production transactions and support reports before expanding the
    commercial model.

The same binary uses Sandbox in TestFlight and Production after App Store
release. Environment selection is derived from verified Apple transaction
evidence, not a user or build-time toggle.

## 13. Verification Matrix

### Free Allowance

- 189 successful records: no early depletion alert;
- 190 successful records: remaining-10 reminder;
- 199 successful records: one remaining;
- 200th record: save completes, then allowance-complete presentation;
- failure, cancellation, retry, and duplicate callback: no extra usage;
- queued and in-flight tasks reserve remaining allowance.

### MemoMark+

- verified Sandbox purchase grants unlimited Sandbox access;
- verified Production purchase grants unlimited Production access;
- restore recovers the eligible entitlement;
- Family Sharing is accepted only when present in verified Apple entitlement;
- refund or revocation removes unlimited access;
- purchase price matches StoreKit storefront display price;
- unlimited state removes finite progress presentation.

### Promotional Redemption

- Apple redemption sheet opens from the app;
- verified redeemed entitlement activates MemoMark+;
- cancelled or invalid redemption does not grant access;
- code distribution terms include expiration and region;
- eligible First Recorder presentation appears only after verified entitlement.

### Major-Version Gift

- major version 1 receives no automatic major-version gift;
- major version 2 grants exactly 100 once;
- repeated launch does not grant another 100;
- major version 3 independently grants exactly 100 once;
- gift is additive and never resets usage;
- MemoMark+ continues to display unlimited state.

## 14. Future Expansion Gates

Record packs or a custom service may be reconsidered only when evidence meets a
clear gate.

### Add Consumable Record Packs When

- a meaningful number of engaged users reaches the free allowance;
- lifetime-purchase rejection is primarily price shape rather than product
  value or trust;
- users explicitly request incremental access;
- consumable delivery and recovery behavior has an acceptable design.

Candidate future prices remain research only:

- 100 records: CNY 6;
- 300 records: CNY 15;
- 800 records: CNY 30.

### Add A Custom Redemption Service When

- Apple campaign limits repeatedly block legitimate operations;
- repeated targeted grants become a routine support requirement;
- operator audit needs exceed App Store Connect evidence;
- the service has a justified privacy, security, hosting, and maintenance
  budget.

Neither future path should be implemented merely because it has already been
designed.

## 15. Acceptance Criteria

- the current purchase page presents one clear lifetime offer;
- selected First Recorders can receive full MemoMark+ through Apple codes;
- Apple manages paid and redeemed entitlement evidence;
- MemoMark never uploads photo or memory data for commerce;
- Free users receive 200 initial records;
- major-version gifts add 100 once without resetting usage;
- only successful Apple Photos saves consume allowance;
- MemoMark+ always presents unlimited access;
- no custom backend or external checkout is required for launch;
- the complete commercial UI is localizable before final copy is frozen;
- future record packs and custom services remain gated by real usage evidence.
