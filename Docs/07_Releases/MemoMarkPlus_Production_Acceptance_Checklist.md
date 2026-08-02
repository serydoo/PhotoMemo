# MemoMark+ Production Acceptance Checklist

Date: 2026-08-03

Status: Release Evidence Preparation / Pending External StoreKit Evidence

Primary loop: `Engineering Loop`

Risk: `P1`

Candidate baseline: `Not Frozen`

Historical candidate evidence: `MemoMark 2.0 (65)`; it predates the current
post-FRI-002 workspace and is not the Release Candidate for the next evidence
run.

StoreKit product ID:

```text
com.serydoo.PhotoMemo.iOS.memomarkplus.lifetime
```

## 1. Purpose

This checklist closes production evidence for the implemented MemoMark+
Commerce baseline. It does not redesign the product, add a Commerce feature,
or replace the canonical contract:

`Docs/02_Architecture/Contract/MemoMarkPlus_Commerce_Contract_Reconciliation_And_Production_Acceptance.md`

The checklist records one observable chain:

```text
User action
-> Apple-owned StoreKit surface or event
-> verified transaction truth
-> MemoMark Access projection
-> queue and UI behavior
-> durable evidence
```

Production Acceptance may pass only from observed evidence at the named
boundary. Source inspection, unit tests, signed installation, and an unavailable
product retry screen do not prove Apple's purchase sheet or a verified Sandbox
transaction.

## 2. Status Vocabulary

Use only these statuses:

- `NOT RUN`: no current observation exists.
- `IN PROGRESS`: an evidence run has started but has no final result.
- `PASS`: observed result matches every expected result for the row.
- `FAIL`: observed result differs from an expected result.
- `BLOCKED BY APPLE CONFIGURATION`: execution cannot start because an external
  App Store Connect or StoreKit prerequisite is unavailable.
- `KNOWN IMPLEMENTATION GAP`: source behavior is known not to satisfy the
  accepted contract.
- `NOT APPLICABLE`: the row does not apply to the accepted release claim, with
  a written reason.

Do not use `PASS` for a plan, expected behavior, screenshot of configuration,
source path, or historical result from another build.

## 3. Evidence Handling

Every executed row must record:

```text
Action:
Expected:
Observed:
Evidence:
Status:
```

Evidence metadata must include:

- candidate Commit SHA;
- app version and build number;
- Archive identifier or retained `.xcarchive` reference;
- installation source;
- date and local time;
- device model and OS version;
- environment and storefront;
- clean install, overwrite install, or retained-container state;
- transaction ownership type when relevant;
- screenshot, screen recording, redacted log, or App Store Connect reference;
- tester initials or role without recording an Apple Account address.

Do not commit Apple Account details, transaction secrets, redemption codes,
private photos, private library contents, or unredacted personal screenshots.
Store private evidence outside the repository and record only a redacted
reference or factual result here.

### 3.1 Release Candidate Identity Gate

No Sandbox, TestFlight, App Review, or Production result may become release
evidence until one immutable candidate identity is recorded:

```text
MemoMark Version:
Build Number:
Commit SHA:
Archive:
Installation Source:
Candidate Status: NOT FROZEN
```

The primary workspace contains unrelated uncommitted V4 and Memory Engine
changes. Candidate preparation therefore uses an isolated worktree that
excludes those changes. Until the fields above are fixed to one commit and
Archive, any build or test result proves only the observed candidate tree and
cannot pass the Candidate Automated Regression gate.

## 4. Environment Matrix

| Environment | Purpose | Current repository state | Acceptance role | Status |
| --- | --- | --- | --- | --- |
| Xcode Debug StoreKit Configuration | Deterministic local purchase, pending, refund, and revocation rehearsal | No tracked `.storekit` configuration file was found on 2026-08-03 | Optional development evidence; cannot replace Sandbox | `NOT RUN` |
| Physical-device Sandbox | Real StoreKit product, sheet, and verified Sandbox transaction | Previous device run returned no configured product; App Store Connect must be reconfirmed | Required | `BLOCKED BY APPLE CONFIGURATION` |
| TestFlight Sandbox | Beta distribution behavior from the submitted binary | Purchase entry exists; real product and sheet are not accepted | Required before resubmission or release claim | `NOT RUN` |
| App Review Sandbox | Apple's review execution of the submitted build | Version `2.0 (53)` was rejected under Guideline 2.1(b); historical build `2.0 (65)` contains the App Review purchase-entry repair but is not the post-FRI-002 candidate | Required | `NOT RUN` |
| Production | Approved storefront transaction and post-release entitlement | Cannot be observed before approval | Post-approval confirmation | `NOT RUN` |

Absence of a tracked Xcode StoreKit Configuration is an environment fact, not
automatic release failure. Adding one requires a separate scoped decision and
must not delay real Sandbox evidence when App Store Connect is ready.

## 5. App Store Connect Preconditions

Reconfirm these items immediately before an external run. Historical release
notes are not substitutes for current App Store Connect state.

| ID | Precondition | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| ASC-001 | Paid Apps Agreement | Active | Not reconfirmed in this checklist | None | `NOT RUN` |
| ASC-002 | Product identity | Exact non-consumable product ID matches the candidate | Not reconfirmed | None | `NOT RUN` |
| ASC-003 | Product availability | Available for intended storefronts | Not reconfirmed | None | `NOT RUN` |
| ASC-004 | Price | Active price schedule returns localized StoreKit price | Not reconfirmed | None | `NOT RUN` |
| ASC-005 | Tax and banking | Required tax, banking, and category state is complete | Not reconfirmed | None | `NOT RUN` |
| ASC-006 | Product localization | Display name and description are complete for release languages | Not reconfirmed | None | `NOT RUN` |
| ASC-007 | Review metadata | Review screenshot and notes are complete | Not reconfirmed | None | `NOT RUN` |
| ASC-008 | Version association | MemoMark+ is associated with the frozen Release Candidate as required | No current candidate is frozen | None | `NOT RUN` |
| ASC-009 | Family Sharing | Enabled if the release continues to claim it | Not reconfirmed | None | `NOT RUN` |
| ASC-010 | Offer Code campaign | Valid non-consumable Offer Code exists if redemption is included in acceptance | Not reconfirmed | None | `NOT RUN` |

All required ASC rows must pass before a missing product response is diagnosed
as an application defect.

## 6. Local Baseline Before External Testing

The following historical evidence was recorded for the July 30 candidate work.
It must be rerun against the exact submitted candidate before final acceptance.

| ID | Check | Command or method | Current evidence | Final status |
| --- | --- | --- | --- | --- |
| LOC-001 | Focused Commerce policy, persistence, store, and UI contracts | `xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -destination 'platform=macOS' -only-testing:PhotoMemoTests/MemoMarkCommercePolicyTests -only-testing:PhotoMemoTests/MemoMarkCommercePersistenceTests -only-testing:PhotoMemoTests/MemoMarkCommerceStoreTests -only-testing:PhotoMemoTests/MemoMarkCommerceUIContractTests test` | 33 workspace tests passed on 2026-08-03; exact Release Candidate is not frozen, so candidate rerun remains required | `NOT RUN` |
| LOC-002 | Required unsigned Debug build | `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build` | Workspace build passed on 2026-08-03; exact Release Candidate is not frozen, so candidate rerun remains required | `NOT RUN` |
| LOC-003 | Signed candidate packaging and nested signatures | Signed device build plus strict signature inspection | Recorded pass for `2.0 (65)` | `NOT RUN` |
| LOC-004 | Bilingual Commerce key parity and plist syntax | Existing localization contract and `plutil -lint` | Workspace parity contract and both plist syntax checks passed on 2026-08-03; exact candidate rerun remains required | `NOT RUN` |
| LOC-005 | First Recorder capability projection | Revoked/free Access with retained date must not display unlimited capability | Access-first Settings projection, paired localized copy, and explicit accessibility semantics passed `MemoMarkCommerceUIContractTests` on 2026-08-03 | `PASS` |
| LOC-006 | Complete serialized macOS regression | `xcodebuild ... -scheme PhotoMemoTests -destination 'platform=macOS' -parallel-testing-enabled NO test` | Isolated candidate tree passed `1,220`, skipped `1`, and failed `0`; exact Commit SHA and Archive are not frozen yet | `NOT RUN` |

## 7. Product Discovery And Purchase Evidence

| ID | Environment | Action | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| SKP-001 | Physical Sandbox | Open Settings, then MemoMark+ | Product loads and `Product.displayPrice` is shown | Not run | None | `NOT RUN` |
| SKP-002 | Physical Sandbox | Compare displayed price with active Sandbox storefront | Currency and localized price match StoreKit | Not run | None | `NOT RUN` |
| SKP-003 | Physical Sandbox | Tap primary purchase action | Apple-owned purchase confirmation sheet appears | Not run | None | `NOT RUN` |
| SKP-004 | Physical Sandbox | Cancel the Apple sheet | Access remains Free, allowance is unchanged, and context remains usable | Not run | None | `NOT RUN` |
| SKP-005 | Physical Sandbox | Produce a pending transaction | Purchase shows pending; Access does not become Plus before verification | Not run | None | `NOT RUN` |
| SKP-006 | Physical Sandbox | Complete purchase | Verified transaction produces `verifiedPlus`, unlimited records, and batch limit 40 | Not run | None | `NOT RUN` |
| SKP-007 | Physical Sandbox | Relaunch after successful purchase | Verified Plus is restored from current StoreKit entitlement without local activation | Not run | None | `NOT RUN` |
| SKP-008 | Physical Sandbox | Make product unavailable, then retry | Visible unavailable message remains actionable; no silent tap or local unlock | Device retry UI was previously observed; exact final run not executed | Prior 2026-07-30 record | `NOT RUN` |
| TFL-001 | TestFlight Sandbox | Repeat product load and primary purchase entry | Same real StoreKit purchase path is used; no new temporary local activation is offered | Not run | None | `NOT RUN` |
| TFL-002 | TestFlight Sandbox | Launch with a legacy temporary-access record, if available | State is labeled temporary; permanent StoreKit action remains available; exit action removes only temporary access | Not run | None | `NOT RUN` |

## 8. Restore, Redemption, And Family Sharing Evidence

| ID | Environment | Action | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| RST-001 | Physical Sandbox | Use Restore Purchases with the purchasing Apple Account | `AppStore.sync()` refreshes to `purchased + verifiedPlus` | Not run | None | `NOT RUN` |
| RST-002 | Physical Sandbox | Restore after clean reinstall | MemoMark+ returns; original purchase date is unchanged; local free ledger is not presented as purchase truth | Not run | None | `NOT RUN` |
| RED-001 | Physical Sandbox | Select Redeem MemoMark+ Code | Apple's redemption sheet appears; no custom code field is shown | Not run | None | `NOT RUN` |
| RED-002 | Physical Sandbox | Redeem an eligible Offer Code | Verified entitlement grants the same Plus capability as purchase | Not run | None | `NOT RUN` |
| RED-003 | Physical Sandbox | Cancel or use an invalid/ineligible code | Access and allowance remain unchanged; Apple owns the feedback | Not run | None | `NOT RUN` |
| FAM-001 | Family Sharing Sandbox setup | Launch as eligible family member | Verified family-shared transaction grants `verifiedPlus` capability | Not run | None | `NOT RUN` |
| FAM-002 | Family Sharing Sandbox setup | Inspect MemoMark+ identity | No First Recorder date or owner identity is fabricated for the family member | Not run | None | `NOT RUN` |

A restore is an evidence action, not a durable `restored` state. After a
successful restore, Purchase resolves to `purchased` and Access resolves to
`verifiedPlus`.

## 9. Refund, Revocation, And Identity Projection Evidence

The accepted semantic rule is:

```text
Capability = current Access
Commemoration = historical First Recorder identity
```

The existing date is sufficient identity data. This checklist does not require
a new `eligible` Boolean or identity-source field.

| ID | Environment | Action or setup | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| REV-001 | Xcode configuration or Sandbox | Revoke or refund a verified direct entitlement | Access becomes `free`; future admission follows finite allowance | Not run | None | `NOT RUN` |
| REV-002 | Same revoked state | Inspect existing outputs and configurations | Existing outputs, configurations, and original photos remain unchanged | Not run | None | `NOT RUN` |
| FRI-001 | `verifiedPlus + firstRecorder(date)` | Open Settings and MemoMark+ | First Recorder identity and unlimited capability may appear together | Not run | None | `NOT RUN` |
| FRI-002 | `free + firstRecorder(date)` | Open Settings and MemoMark+ | Historical commemoration may remain; no unlimited capability is claimed | Settings projects `First Recorder Keepsake` with the localized original date only after current Plus Access has been excluded | 2026-08-03 focused `MemoMarkCommerceUIContractTests` and Settings source | `PASS` |
| FRI-003 | `verifiedPlus` with Family Sharing ownership | Open Settings and MemoMark+ | Unlimited capability appears without First Recorder identity | Not run | None | `NOT RUN` |
| FRI-004 | Restored direct entitlement | Inspect commemorative date | Original eligible date is retained; restore date is not substituted | Not run | None | `NOT RUN` |

`FRI-002` passed its source and focused UI-contract boundary. The accepted
commemorative wording is now recorded in the product-language guide. Actual
refund/revocation, visible UI, and VoiceOver traversal evidence remain separate
external or device acceptance rows and must not be inferred from this pass.

## 10. Allowance And Admission Regression

For unlimited Access, finite Allowance is inactive. Do not record it as
`normal`; unlimited capability comes from Access.

| ID | Setup or action | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| ALL-189 | Free count becomes 189 | No approaching milestone | Not rerun | Historical focused tests | `NOT RUN` |
| ALL-190 | Free count becomes 190 | Final-ten milestone appears after successful save | Not rerun | Historical focused tests | `NOT RUN` |
| ALL-199 | Free count becomes 199 | Remaining allowance is 1 and one new task can be admitted | Not rerun | Historical focused tests | `NOT RUN` |
| ALL-200 | Final free output saves | Save completes first; completed milestone follows; remaining becomes 0 | Not rerun | Historical focused tests | `NOT RUN` |
| ALL-201 | Request new work at remaining 0 | No new processing task is created; MemoMark+ path remains dismissible | Not rerun | Historical focused tests | `NOT RUN` |
| ALL-FAIL | Processing or Apple Photos save fails | No allowance is consumed | Not rerun | Historical queue evidence | `NOT RUN` |
| ALL-RETRY | Retry or duplicate completion occurs | One task identity consumes at most once | Not rerun | Historical persistence tests | `NOT RUN` |
| ALL-RESERVE | Queue has in-flight work | Admission subtracts reservations without consuming them early | Not rerun | Historical policy tests | `NOT RUN` |
| BAT-020 | Free submits 20 photos | Accepted if at least 20 records remain | Not rerun | Historical policy tests | `NOT RUN` |
| BAT-021 | Free submits 21 photos | Rejected before task creation | Not rerun | Historical policy tests | `NOT RUN` |
| BAT-040 | Verified Plus submits 40 photos | Accepted | Not rerun | Historical policy tests | `NOT RUN` |
| BAT-041 | Verified Plus submits 41 photos | Rejected | Not rerun | Historical policy tests | `NOT RUN` |

## 11. Device And Accessibility Acceptance

Execute the real purchase path on both a compact iPhone and iPad. Record exact
devices and OS versions rather than relying on these category names.

| ID | Check | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| UI-001 | iPhone purchase page | Product, price, primary action, redemption, restore, and error state remain visible and operable | Not run | None | `NOT RUN` |
| UI-002 | iPad purchase page | Same controls remain visible and the Apple sheet presents correctly | Not run | None | `NOT RUN` |
| UI-003 | Accessibility text sizes | Text reflows without clipping or hiding purchase consequences | Not run | None | `NOT RUN` |
| UI-004 | VoiceOver | Price, purchase action, pending, success, restore, and identity/capability status are announced accurately | Not run | None | `NOT RUN` |
| UI-005 | Reduce Motion | No required state depends on animation | Not run | None | `NOT RUN` |
| UI-006 | Light and dark appearance | Price, state, error, and warm-gold identity remain legible without color-only meaning | Not run | None | `NOT RUN` |

## 12. App Review Purchase Flow

| ID | Action | Expected | Observed | Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| REVW-001 | Install the exact submitted candidate cleanly | Version/build and embedded targets match submission | Not run | None | `NOT RUN` |
| REVW-002 | Follow `Settings -> MemoMark+ -> permanent unlock action` | Route is discoverable without account or hidden test steps | Not run | None | `NOT RUN` |
| REVW-003 | Select the primary action in review Sandbox | Apple's purchase sheet appears; an unavailable state must retain retry but does not pass this row | Not run | None | `NOT RUN` |
| REVW-004 | Complete reviewer purchase flow | Verified transaction unlocks MemoMark+ without local activation | Not run | None | `NOT RUN` |
| REVW-005 | Compare review notes with submitted behavior | Notes contain no unsupported price, Family Sharing, redemption, or acceptance claim | Not run | None | `NOT RUN` |

## 13. Execution Order

1. Reconcile the dirty workspace without discarding unrelated user work, then
   create one scoped Candidate commit.
2. Record the candidate version, Build Number, Commit SHA, Archive, and
   Installation Source in the Release Candidate Identity Gate.
3. Run the exact-candidate local baseline and record command output.
4. Reconfirm all required App Store Connect preconditions and candidate version
   association.
5. Resolve any missing product response before interpreting purchase-flow
   behavior.
6. Execute clean physical iPhone Sandbox purchase, cancellation, pending,
   success, relaunch, and restore evidence.
7. Repeat product, purchase-entry, and layout acceptance on iPad and TestFlight.
8. Run Offer Code and Family Sharing evidence only when those release claims
   remain enabled and configured.
9. Execute revocation and retained-identity evidence against the completed
   First Recorder projection correction.
10. Reconcile every result into the final gate without converting `NOT RUN` or
   configuration screenshots into `PASS`.

## 14. Final Gate

| Gate | Pass condition | Current result |
| --- | --- | --- |
| Commerce Contract | Canonical contract remains reconciled with implementation and accepted semantics | `PASS` |
| Release Candidate Identity | One version, Build Number, Commit SHA, Archive, and Installation Source identify the tested candidate | `NOT RUN` |
| Candidate Automated Regression | Exact submitted candidate passes focused Commerce, localization, build, and packaging checks | `NOT RUN` |
| First Recorder Projection | Free/revoked Access cannot display unlimited capability while commemoration remains | `PASS` |
| StoreKit Sandbox | Product, localized price, Apple sheet, verified purchase, cancellation, pending, and restore pass | `NOT RUN` |
| Offer Code | System redemption and verified entitlement pass, or release claim is removed | `NOT RUN` |
| Family Sharing | Verified shared capability and identity separation pass, or release claim is removed | `NOT RUN` |
| App Review Purchase Flow | Exact candidate passes Apple's review purchase path | `NOT RUN` |
| Production Confirmation | Approved build observes expected Production product and entitlement behavior | `NOT RUN` |
| Release | Every required pre-release gate is `PASS`; post-approval Production confirmation is scheduled and bounded | `NOT AUTHORIZED` |

## 15. Current Result

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

## 16. Final Acceptance Record

Complete this section only after every required row has a durable result.

```text
Candidate Version:
Build Number:
Commit SHA:
Archive:
Installation Source:
Date:
Reviewer:

Commerce Contract:
Candidate Automated Regression:
First Recorder Projection:
StoreKit Sandbox:
Offer Code:
Family Sharing:
App Review Purchase Flow:
Production Confirmation Plan:

Final Verdict:
PASS / FAIL / PENDING

Release Authorization:
AUTHORIZED / NOT AUTHORIZED

Evidence References:
-
```

## 17. Checklist Verification

Verify repository consistency and the focused projection contract with:

```bash
git diff --check

xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:PhotoMemoTests/MemoMarkCommerceUIContractTests \
  test

rg -n "Pending External StoreKit Evidence|First Recorder Projection|NOT AUTHORIZED" \
  Docs/02_Architecture/Contract/MemoMarkPlus_Commerce_Contract_Reconciliation_And_Production_Acceptance.md \
  Docs/07_Releases/MemoMarkPlus_Production_Acceptance_Checklist.md \
  Docs/CURRENT_STATUS.md
```

The focused test does not execute a StoreKit transaction, simulator UI run,
App Review submission, or physical-device accessibility acceptance.
