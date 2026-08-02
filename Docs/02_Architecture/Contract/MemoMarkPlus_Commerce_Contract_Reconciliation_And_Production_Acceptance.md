# MemoMark+ Commerce Contract Reconciliation And Production Acceptance

Date: 2026-08-03

Status: Internal Closure Complete / Release Evidence Preparation

Primary loop: `Engineering Loop`

Risk: `P1`

## 1. Decision

MemoMark+ is an implemented Commerce baseline. It is not waiting for a new
product design or a first StoreKit architecture proposal.

The current sequence is:

```text
Product Baseline
-> Commerce Implementation
-> Contract Reconciliation
-> Commerce v1 Internal Closure
-> Release Evidence Preparation  [current phase]
-> External StoreKit Evidence
-> Release Authorization
```

This document reconciles the accepted product model, current source behavior,
recorded automated evidence, and remaining Apple-managed acceptance work. It
does not authorize a product-model change, a new entitlement, a StoreKit
rewrite, or a release claim.

Commerce v1 feature expansion is closed in this phase. A new entitlement,
price strategy, purchase entry, membership tier, or Preset commercial model
requires a separate Commerce v1.1 proposal and is not part of Release Evidence
Preparation.

The V4 Expression Style implementation stop does not suspend maintenance and
acceptance work for the already implemented Commerce baseline. Commerce remains
outside Renderer, Layout Engine, Memory Engine, Metadata, Export, and original
photo ownership.

## 2. Evidence Language

This document uses four explicit evidence states:

- `Recorded`: an accepted repository document defines the behavior.
- `Verified`: source and automated or device evidence demonstrate the behavior
  at the stated boundary.
- `External Acceptance Pending`: Apple-managed state cannot be established by
  repository source, unit tests, or an unsigned build.
- `Still Researching`: a product or policy decision has not been accepted.

`Verified` never implies that a different boundary was tested. In particular,
source routing and a signed app launch do not prove App Store Connect product
availability or presentation of Apple's purchase confirmation sheet.

## 3. Authorities And Ownership

The current authorities are:

1. StoreKit verified transaction state owns paid MemoMark+ entitlement,
   restoration, revocation, refund effects, ownership type, storefront price,
   Offer Code redemption, and Family Sharing eligibility.
2. `MemoMarkCommercePersistence` owns the local successful-save ledger,
   idempotent task identities, version gifts, First Recorder date, and the
   minimal App Group snapshot.
3. `MemoMarkCommercePolicy` derives free allowance, batch admission, and
   milestone events.
4. `MemoMarkCommerceStore` observes StoreKit and publishes the main-app
   Commerce snapshot and purchase-operation state.
5. `BatchQueueStore` owns main-app queue admission and records allowance only
   when a task first reaches completed with a saved Apple Photos asset ID.
6. The Share Extension reads a compatible App Group snapshot. It does not call
   StoreKit or own entitlement truth.
7. SwiftUI Commerce surfaces project the snapshot and purchase operation. They
   do not grant entitlement.

Apple Photos continues to own the photo library and original assets. Commerce
observes successful save completion but does not own rendering, export, or
PhotoKit persistence semantics.

## 4. Existing Implementation Alignment

| Domain | Accepted contract | Current implementation | Reconciliation status |
| --- | --- | --- | --- |
| MemoMark+ entitlement | One non-consumable lifetime entitlement | Verified `Transaction.currentEntitlements` and `Transaction.updates` in `MemoMarkCommerceStore` | Recorded and source-verified; real Sandbox purchase pending |
| Storefront price | Apple-localized price only | `Product.displayPrice` | Recorded and source-verified; real product response pending |
| Free allowance | 200 initial successful records | `baseFreeAllowance = 200` plus eligible additive gifts | Recorded and focused-test verified |
| Counting point | Successful Apple Photos persistence only | First transition to completed with a non-nil saved asset identifier | Recorded and focused-test verified |
| Idempotency | One count per durable task identity | Environment-scoped completed-task UUID set | Recorded and focused-test verified |
| Batch admission | Free 20, MemoMark+ 40, bounded by remaining allowance | Policy-derived main queue and Share Extension admission | Recorded and focused-test verified |
| First Recorder | Direct eligible transaction date, independent from capability | Durable `firstRecorderDate`; Family Sharing ownership is excluded | Recorded and focused-test verified |
| Family Sharing | Apple distribution entitlement, not MemoMark family identity | Verified Plus capability with `ownershipType` used only for First Recorder eligibility | Recorded and source-verified; real shared entitlement pending |
| Offer Code | Apple-owned redemption UI and verified transaction | `AppStore.presentOfferCodeRedeemSheet(in:)` plus transaction refresh | Recorded and source-verified; real redemption pending |
| Restore | Apple sync followed by current-entitlement refresh | `AppStore.sync()` then `refresh()` | Recorded and source-verified; real restore pending |
| Environment isolation | Xcode, Sandbox, and Production must not leak state | Environment-namespaced ledger and compatible shared snapshot | Recorded and focused-test verified |
| Purchase entry recovery | Every non-entitled user gets a real StoreKit action or visible retry | Product reload, Store-unavailable failure, and retryable purchase action | Recorded, automated-test verified, and device UI verified |

## 5. Orthogonal Commerce State Contract

Commerce state must not be collapsed into one expanding `UserState` enum. The
baseline is four orthogonal axes plus one cross-cutting environment namespace.

### 5.1 Access Axis

```text
free
testFlightTemporary
verifiedPlus
```

- `free` uses the finite local allowance and the free batch limit.
- `testFlightTemporary` is a Sandbox-only legacy access source. Existing
  persisted access can still be recognized and deactivated, but the release
  purchase page no longer offers new local activation.
- `verifiedPlus` requires a current verified StoreKit entitlement and grants
  unlimited records plus the MemoMark+ batch limit.

Access does not encode direct purchase versus Family Sharing. Both grant the
same capability. Apple transaction ownership remains metadata.

### 5.2 Allowance Axis

The allowance phase is derived, not separately persisted:

```text
normal       remaining > 10
approaching  remaining in 1...10
exhausted    remaining == 0
```

This finite axis is evaluated only while Access is `free`. For
`verifiedPlus` or `testFlightTemporary`, finite allowance presentation is
inactive because unlimited capability comes from Access; it must not be
misreported as a `normal` finite allowance.

The durable values are successful record count, base allowance, and additive
gift ledger. Queue and in-flight reservations are transient admission inputs,
not consumed allowance.

Milestone presentation is event-based:

- emit the approaching event when remaining allowance first reaches 10;
- emit the completed event only after the final allowed output saves;
- do not emit finite milestones for unlimited access.

For a fresh installation, these transitions occur at records 190 and 200. For
an installation with an additive gift, the thresholds derive from total
allowance rather than literal record numbers.

The accepted 2026-07-29 Settings information-hierarchy pass supersedes the
original 2026-07-23 Settings progressive-disclosure detail: Settings now shows
the current remaining free-record state from the Commerce snapshot. This is a
presentation change only; it does not change allowance policy.

### 5.3 Purchase Axis

```text
idle
loading
purchasing
pending
purchased
cancelled
failed(message)
```

This axis describes the current StoreKit operation and presentation. It does
not grant capability by itself.

- `restored` is an event path, not a durable purchase state. A successful
  restore resolves to `purchased` plus `verifiedPlus`.
- refund and revocation are entitlement events, not permanent purchase-screen
  modes. A verified loss of current entitlement resolves Access to `free`; the
  purchase operation returns to a non-purchased presentation state.
- an unverified transaction never produces `verifiedPlus`.

### 5.4 Identity Axis

```text
none
firstRecorder(date)
```

First Recorder is a commemorative identity, not an entitlement source.

- eligibility requires a direct, non-Family-Shared transaction within the
  active campaign boundary;
- the date comes from the verified original purchase date;
- restoration does not create a new date;
- Family Sharing capability does not create a First Recorder identity;
- a later refund or revocation removes capability but does not erase the
  historical First Recorder date;
- unlimited presentation requires current `verifiedPlus` Access and must never
  be inferred from identity alone;
- the identity never enters Memory Card, Renderer, Export, or original photos.

The current implementation stores a date but not an identity `source` field.
No purchase, Offer Code, or campaign-source taxonomy is part of the accepted
runtime baseline.

### 5.5 Environment Namespace

```text
xcode
sandbox
production
```

Environment scopes the allowance ledger, gifts, temporary access, First
Recorder date, and shared snapshot compatibility. An unverified App
transaction environment falls back to Production Free; a persisted Sandbox
snapshot must never grant Production access.

## 6. Event And Transition Contract

| Event | Required transition | Must not happen |
| --- | --- | --- |
| App refresh with verified current entitlement | Access becomes `verifiedPlus`; purchase presentation becomes purchased | Local allowance is reset or rewritten |
| App refresh without verified current entitlement | Access derives from compatible local state, otherwise `free` | An unverified transaction grants Plus |
| Purchase begins | Purchase becomes purchasing | A queue task is created or allowance is consumed |
| Purchase becomes pending | Purchase becomes pending; current Access remains unchanged | Plus is granted before verification |
| User cancels | Purchase becomes cancelled; current Access remains unchanged | Error alarm, count change, or data loss |
| Purchase fails | Purchase becomes retryable failed state | Silent tap, local unlock, or count change |
| Verified purchase succeeds | Access becomes `verifiedPlus`; transaction is finished; eligible identity is recorded once | Localized price or ownership is invented by MemoMark |
| Restore succeeds | Refresh verified current entitlement and original purchase truth | A new purchase date or duplicate identity is created |
| Family-shared entitlement appears | Access becomes `verifiedPlus`; identity remains absent unless separately eligible | A MemoMark family relationship is created |
| Refund or revocation is verified | Unlimited access is removed; future admission returns to finite policy | Existing outputs, configurations, or original photos are modified |
| Free output first saves to Apple Photos | Record its task identity once and increment successful count once | Preview, failure, cancellation, or duplicate callback consumes allowance |
| Major-version gift is eligible | Add the gift once in the active environment | Usage resets or a fresh 2.0 install receives the legacy gift |
| Clean reinstall | Local free ledger may restart at the initial allowance; StoreKit entitlement remains restorable | An account, upload, or custom server is introduced to resist reset |

## 7. Boundary Decisions

### 7.1 Frozen

- MemoMark+ remains one Apple-managed non-consumable lifetime product.
- Free begins with 200 local successful records; 200 is an accepted launch
  baseline, not a measured permanent optimum.
- Only successful Apple Photos saves consume allowance.
- Existing outputs and configurations remain untouched after entitlement loss.
- The local allowance is intentionally soft across a clean reinstall.
- Family Sharing is transaction ownership metadata and Apple-managed
  eligibility, not a MemoMark family model.
- The Share Extension consumes a minimal compatible snapshot and never calls
  StoreKit.
- MemoMark defines no custom entitlement-expiry timer. StoreKit verified
  current entitlement remains the authority; the local snapshot is a runtime
  and extension projection, not independent purchase proof.

### 7.2 Accepted Projection Correction Implemented

- A refunded or revoked direct purchaser retains the historical First Recorder
  commemoration. Refund and revocation remove current MemoMark+ capability, not
  the fact that the eligible original transaction occurred.
- Capability presentation derives only from Access. Settings now evaluates
  current Plus Access before projecting a retained First Recorder date.
- For `verifiedPlus + firstRecorder(date)`, the UI may combine First Recorder
  identity with unlimited capability. For `free + firstRecorder(date)`, the UI
  may show only restrained commemorative identity and date; it must not claim
  unlimited records.
- The accepted historical-free status is `首批记录纪念 · <本地化原始日期>` /
  `First Recorder Keepsake · <localized original date>`. The Settings button
  exposes an explicit MemoMark+ accessibility label, a value derived from the
  visible status and detail, and a historical-identity hint that does not claim
  current Plus capability.

No new `eligible` Boolean or identity-source field is required by this
decision. Identity presence is represented by the existing durable date;
current Access remains the sole capability authority.

### 7.3 Later Decisions Outside The Current Acceptance Slice

- Whether the purchase action should change from identity language such as
  `Become a First Recorder` to the explicit command `Unlock MemoMark+`, while
  keeping First Recorder as price context and post-purchase recognition.
- The operational close condition for the First Recorder campaign. The current
  code leaves the optional campaign end date open.
- Post-launch evidence for whether 200 records remains the correct commercial
  threshold. Any later change requires real product evidence and a separate
  product decision.

These later items do not block the external StoreKit evidence run and do not
authorize a source or copy change in this contract pass.

## 8. Reconciled Differences From Earlier Design

1. The 2026-07-23 design described Settings allowance visibility only for the
   final ten records. The accepted 2026-07-29 Settings pass now presents the
   current remaining allowance in its MemoMark+ Hero.
2. The current purchase button still combines First Recorder identity with the
   purchase action. Separating identity context from the unlock command remains
   a bounded copy candidate, not implemented behavior.
3. The 2026-07-24 design listed revoked entitlement as a required recovery
   condition. Runtime capability loss is represented by Access returning to
   `free`; there is no durable `revoked` purchase-state case.
4. A restore is an action followed by entitlement refresh, not a `restored`
   state.
5. The current First Recorder record contains a date only. A separate identity
   source is not implemented and must not be claimed.
6. Sandbox temporary access remains readable for legacy testers, but new local
   activation was removed from the release purchase page after App Review
   recovery.
7. A retained First Recorder date and revoked Plus Access are independently
   representable in persistence. Settings preserves the commemoration with its
   localized original date while deriving all capability language from Access;
   the focused Commerce UI contract verifies this branch order, bilingual copy,
   date formatting, and explicit accessibility semantics.

## 9. Production Acceptance Matrix

Execution results are recorded in
`Docs/07_Releases/MemoMarkPlus_Production_Acceptance_Checklist.md`. This
contract defines the pass conditions; the checklist records observations and
evidence without changing them.

| Acceptance item | Current result | Required closure evidence |
| --- | --- | --- |
| Release Candidate identity | `Not Frozen` | Record one version, Build Number, Commit SHA, Archive, and Installation Source before external execution |
| Product identifier and real storefront product response | `External Acceptance Pending` | Clean Sandbox/TestFlight install returns the configured non-consumable and localized price |
| Purchase action routing | `Verified` at source and retry UI boundaries | Preserve existing focused tests |
| Apple purchase confirmation sheet | `External Acceptance Pending` | Observe the Apple-owned sheet on clean physical iPhone and iPad installs |
| Purchase cancellation | `External Acceptance Pending` | Observe cancellation with no entitlement or allowance change |
| Pending transaction | `External Acceptance Pending` | Observe pending state and later verified resolution |
| Successful purchase | `External Acceptance Pending` | Observe verified unlock, unlimited admission, and transaction refresh |
| Restore purchases | `External Acceptance Pending` | Observe restored entitlement and unchanged original purchase date |
| Offer Code redemption | `External Acceptance Pending` | Observe system sheet and verified redeemed entitlement |
| Family Sharing | `External Acceptance Pending` | Observe verified family-shared capability and absence of First Recorder identity |
| Refund or revocation | `External Acceptance Pending`; local projection correction verified | Observe removal of unlimited access, unchanged existing outputs, retained commemoration, and identity copy that does not claim revoked capability |
| Free allowance and idempotency | `Verified` by focused automated evidence | Preserve boundary, duplicate-callback, and environment-isolation tests |
| Queue and Share Extension admission | `Verified` by source and focused automated evidence | Preserve remaining-allowance and 20/40 admission tests |
| Purchase unavailable and retry | `Verified` by automated and signed-device UI evidence | Preserve visible retry and no silent action |
| iPhone and iPad layout/accessibility | `External Acceptance Pending` for the real StoreKit path | Manual purchase-page acceptance at supported sizes and accessibility settings |

## 10. Production Gate

Production Acceptance remains `PENDING` until all of the following are true:

1. One Release Candidate is bound to a version, Build Number, Commit SHA,
   Archive, and Installation Source.
2. App Store Connect agreements, product metadata, tax category, pricing,
   review assets, availability, Family Sharing configuration, and candidate
   version association are complete.
3. The real product and localized price load on clean physical-device Sandbox
   or TestFlight installations.
4. Selecting the primary action presents Apple's purchase confirmation sheet
   on both iPhone and iPad.
5. Cancellation, pending, success, restore, unavailable/retry, and environment
   isolation are observed without local entitlement fabrication.
6. Offer Code and Family Sharing claims are either physically accepted or
   removed from release-facing claims until accepted.
7. The accepted First Recorder projection correction is implemented and proves
   that revoked Access cannot display unlimited capability.
8. Refund/revocation capability loss and retained historical commemoration are
   verified at the StoreKit and presentation boundaries.
9. Existing automated Commerce, queue, Share Extension, localization, build,
   and packaging evidence remains passing for the submitted candidate.

## 11. Current Verdict

```text
MemoMark+ Commercial Model v1

Commerce v1 Internal Closure:
PASS

Current Phase:
Release Evidence Preparation

Product Model:
Frozen

Product Contract:
PASS / Accepted / Reconciled

Implementation:
Baseline Complete

Known Issue:
None (FRI-002 Closed)

Commerce Feature Expansion:
Not Authorized (Commerce v1.1 Proposal Required)

Internal State:
Closed

External Evidence:
Pending

External State:
Awaiting Apple Evidence

Release State:
Locked

Release Authorization:
Not Authorized
```

## 12. Verification For This Contract Pass

The FRI-002 implementation pass is verified with:

```bash
git diff --check

xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:PhotoMemoTests/MemoMarkCommerceUIContractTests \
  test

rg -n "Contract Reconciliation Complete|External StoreKit Evidence Validation|Product Model Changes" \
  Docs/02_Architecture/Contract/MemoMarkPlus_Commerce_Contract_Reconciliation_And_Production_Acceptance.md \
  Docs/CURRENT_STATUS.md

rg -n "case free|case testFlightTemporary|case verifiedPlus|case purchased" \
  Source/PhotoMemo/PhotoMemo/Models/MemoMarkCommerceModels.swift

rg -n "presentOfferCodeRedeemSheet|ownershipType|Transaction.currentEntitlements|AppStore.sync" \
  Source/PhotoMemo/PhotoMemo/Services/MemoMarkCommerceStore.swift
```

This focused source and automated evidence does not prove a StoreKit
transaction, simulator or physical-device VoiceOver traversal, refund or
revocation event, App Review purchase path, or release candidate.
