# 2.3.6 feedback reliability and landscape pass — 2026-10-12

## Authority and evidence

Owner authorizes a bounded optimization pass from IMG_7156–IMG_7169.
Screenshots are observations; user reports are not reproduced failure proof.
Version stays 2.3.6 (124) during implementation. No Store submission or public
release is established by this pass.

Existing mixed-tree changes were inventoried and the tracked patch preserved
under `/tmp/MemoMarkFeedback20261012/` before edits. Only this pass's source,
tests and scoped state record are in scope; private photos remain local.

## Decision gate and slices

| Item | Primary loop | Evidence and intended outcome | Risk / owner | Verification |
|---|---|---|---|---|
| F-01 configuration save | Engineering | User reports repeated attempts; trace candidate, durable receipt, editor-generation fence and reload. One successful save must survive fresh load; newer edits must never be overwritten or declared saved. | P0 durability; aggregate repository, transaction, session reconciliation | Deterministic failure/race regression, real file reload, full host suite, signed device save/relaunch |
| F-02 localization | Product | English identity fields and generated defaults contain Chinese. Localize new system defaults and field prompts; preserve existing user strings and IDs. | P2 UI and subject creation | Four-language resources/defaults, input geometry unchanged, physical field inspection |
| F-03 landscape ISO | Engineering | Screenshot truncates camera summary; portrait and landscape differ. Measure actual slot capacity before changing text fit; preserve existing layout/export size. | P1 output fidelity; Layout Engine fit policy, renderer consumption | Measured long-parameter cases and shared preview/output, physical output when feasible |
| F-04 date | Product | Mixed-language dates and Spanish-region expectations. Correct supported-language UI formatting; preserve explicitly saved photography formats. Full Spanish/region output policy needs its own scope. | P2 interface dates; capture time/timezone remain unchanged | Four locales; no changes to EXIF parsing or persisted formats |
| F-05 history cleanup | Product | User cannot find/delete old Progress records. Inspect existing cleanup and clarify discoverability; don't delete assets or active/recovery receipts. | P1 record lifecycle | Existing API/entry review; any change requires inactive-record regression |
| F-06 overseas names | Product | Coordinates shown outside China. Investigate existing local coverage; don't add photo upload/network geocoding. | P2 local location coverage | Record limitation and bounded follow-up |
| F-07 simplify | Product | General preference, no concrete obstruction. Preserve accepted IA-002; use F-08 as actionable geometry observation. | P2 UI | No broad redesign |
| F-08 landscape geometry | Product | Both landscape directions retain the same content/rail coordinates. Derive content from actual safe viewport, reserve navigation once, allow compact-height width to fill available space. | P2 page container and navigation shell | Geometry regressions; Home/Configuration/Progress, both directions, preview open/closed, keyboard/focus, signed device |

## Boundaries

Keep `Library -> Interactive Memory Card -> Object Inspector`, one session and
native TextKit editing owner. Reuse SwiftUI safe-area/scene geometry and native
localized date formatting. No device-model or screen-size branches. Don't
infer extra usable space solely from the side of the Dynamic Island; system
safe-area constraints remain authoritative. Keep current navigation vertical
arrangement and configuration-specific actions.

Atomic aggregate writes remain durable truth; legacy projections do not write
back. A failed write must keep old data, and a newer draft must keep protection.
No automatic rewriting of saved Chinese object names or custom date literals.
No schema change, full Spanish rollout, global map-data expansion, purchases,
media originals, background ownership, or Renderer layout redesign.

## Verification and disposition

Implementation and automated verification complete. After the owner unlocked
the paired phone, physical navigation/preview and save/relaunch checks passed.
Automated physical interaction is distinct from owner visual acceptance and
saved Photos readback.

### Changes and dispositions

- F-01: reproduced a durable-revision regression. A successful receipt with newer
  live edits left the session on the previous aggregate revision, causing the next
  candidate to be stale. Advance durable truth before draft/selection fences;
  reject older receipts without regressing the baseline. Preserve newer edits and
  selection. Reconcile/project before asynchronous album refresh, and prevent
  delayed projection observations from marking durable output values dirty.
  An apply action requires a durably saved, processing-ready projection.
- F-02: localize identity field titles/placeholders/required accessibility labels,
  expression source labels and newly generated subject defaults in Chinese,
  English, Japanese and Korean. Existing user-authored values are preserved.
  Full Spanish support remains outside this pass.
- F-03: shared Classic White landscape layout policy measures the two text groups
  and grants long camera metadata unused left-column capacity. Short rows retain
  historical widths; portrait, font minimums and export sizes remain unchanged.
  Long ISO tests pass at preview/export canvas sizes. Physical saved-output visual
  readback remains open.
- F-04: supported-language UI dates use native locale formatting, including Korean;
  system-language preference respects the system locale. Explicit photography
  date formats/timezone interpretation are preserved. Spanish capture-output
  expectations remain open.
- F-05: Progress recent-history menu exposes the existing ended-record cleanup
  service with a native confirmation dialog and four-language consequence copy.
  Existing queue tests prove durable-failure preservation, active-job protection
  and receipt removal on successful cleanup. No real user history was cleared.
- F-06: investigation finds address-dependent display and coordinate fallback in
  LocationResolver, plus CoreLocationReverseGeocoder in PhotoImportService.
  This is not enough to attribute the overseas report to a missing dataset.
  Trace the actual failing photo's metadata/intake route before any geocoding or
  coverage change. No additional network lookup or asset upload was introduced.
- F-07/F-08: one navigation shell reserves rail space; compact-height pages use
  the remaining safe viewport instead of subtracting rail space again and applying
  the regular 720pt cap. Preserve regular-width readability, rail vertical
  arrangement, native safe areas and the same TabView/TextKit owners.

### Evidence

- Pre-fix persistence regression: `/tmp/MemoMarkFeedbackPersistenceRED-Suite.xcresult`,
  12 executions, 11 passed / 1 failed; next candidate revision stayed 11 after
  receipt revision 12. The initial selector which executed zero tests was discarded.
- Focused post-fix suite: `/tmp/MemoMarkFeedback20261012/Focused2.xcresult`,
  136 passed, zero failures/skips.
- Full final host suite: `/tmp/MemoMarkFeedback20261012/Full3.xcresult`,
  2,122 tests: 2,121 passed, one skipped, zero failures. Parameterized device summary
  counts 2,193 successful executions. The skipped test is
  `StillImageMetadataWriterContractTests/writesJPEGWithSourceMetadataAndRenderedDimensions`.
  Two runtime QoS warnings come from FixtureExportReadbackTests; no new failing
  assertion was recorded. Existing real-file atomic replacement, recovery and
  competing-repository tests are included.
- Signed iOS Debug build passed: `/tmp/MemoMarkFeedback20261012/iOS-build2.log`.
  App installed successfully over existing data on paired iPhone 17 Pro Max.
- Final source plus new two-direction UI harness compiled and signed successfully:
  `/tmp/MemoMarkFeedback20261012/DeviceQA-build.log` (`TEST BUILD SUCCEEDED`).
- Physical launch/UI run was blocked by CoreDevice/FrontBoard `Locked` and Xcode
  `Unlock iPhone to Continue`; user was asked to unlock. The waiting test run was
  cancelled, not counted as pass. No simulator was used.
- Governance validation passed; source/test diff whitespace checks passed.
  Existing user documentation/private assets were preserved; no staging, commit,
  push, TestFlight or App Store mutation occurred.

### Remaining acceptance

Inspect localized object fields and long Classic White metadata in an actual saved
output. Owner acceptance of rail/card spacing, physical keyboard/input behavior
and accessibility sizes remains open. Physical input/keyboard acceptance from
the previous retained-preview work is not silently inherited by this pass.

### Physical continuation after owner unlock

- `/tmp/MemoMarkFeedback20261012/DeviceUI4.xcresult`: one physical UI test passed
  on iPhone 17 Pro Max / iOS 27.2. Home, Configuration and Progress controls are
  reachable in both landscape directions; preview toggles in each direction and
  the host relaunches. Attachments remain local in `UI4Attachments`.
- Earlier UI attempts are retained as failed evidence: one looked for the
  portrait label `配置` instead of the existing rail identifier, and a rotation
  predicate required explicit Swift `self`. They are not counted as passes.
- `/tmp/MemoMarkFeedback20261012/DeviceSave4.xcresult`: one physical UI test passed.
  Toggle `补充一句话`, tap save once, wait for disabled `已保存`, terminate and
  relaunch, then verify the edited switch value. Restore the original switch,
  save once, terminate/relaunch again, and verify the original value. Original
  preference was restored before final assertions. No Photos asset or real
  processing-history cleanup was performed.
- Earlier save tests stopped before modifying the switch: first a section-label
  mismatch, then attempts to swipe the outer retained-preview container rather
  than the inner options. The final harness navigates the actual option scroller.
- No production source changed during this physical continuation; only the QA
  harness and this scoped state record changed. Device build/test, final whitespace
  check and governance checks passed. Full host-suite evidence above remains
  applicable to the production source.

This pass does not establish a superseding production certification or close
unrelated Share/background lifecycle findings.

### Owner-directed trailing-edge refinement

Owner rejects the still-excessive edge distance on the unobstructed landscape
side and explicitly authorizes reducing it while widening the central content.
Product Loop, P2, navigation-shell geometry only. Reuse the hosting UIWindow's
safe insets and UIWindowScene interface orientation; no model, cutout-coordinate
or screen-size constants. In interface landscapeRight (device landscapeLeft),
the portrait-top camera obstruction is on the left. Release only the right
inset beyond the existing inter-region spacing; keep the rail margin, leading
safe area, obstructed right inset, vertical placement and regular layouts.
Navigation shell remains the only rail-width owner. Verify policy tests and
physical rail/content frames in both directions on all three pages; preserve
TabView/TextKit identity. Owner visual acceptance remains distinct from tests.

Refinement evidence: `EdgeFull.xcresult` under the same temporary evidence root
passes 2,123 tests (2,122 passed, one existing skip, zero failures).
`EdgeDevice3.xcresult` passes physical Home/Configuration/Progress in both poses,
preview toggling and relaunch. Unobstructed-side button edge gap is 27pt rather
than 77pt, corresponding to a 22pt capsule-edge margin. Each page's actual wide
content viewport gains 50pt in that pose; the opposite pose retains the previous
obstruction clearance. Measurements and full AX hierarchies are in
`Edge3Attachments`, distinct from the earlier first-scroll-view metric that
mistakenly described the narrow rail. No new screen/cutout constants were added
to production. Signed build installed by the physical test flow; no simulator,
configuration save or Photos write was needed for this refinement.
One earlier runner launch exited before connecting, and legacy source-contract
assertions were revised to allow only the explicitly requested trailing-edge
relaxation and transient window geometry (selection still has one binding owner).
