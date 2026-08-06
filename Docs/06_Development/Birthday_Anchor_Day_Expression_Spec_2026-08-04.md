# Birthday Anchor Day Expression Specification

Date: 2026-08-04

Status: Accepted; Calendar-Day Scope Amended 2026-08-06

## 2026-08-06 Calendar-Day Amendment

The current accepted rule applies calendar-day comparison to every Time Anchor,
not only birthdays. Crossing local midnight enters the next calendar day even
when fewer than 24 hours have elapsed. Same-day time-of-day ordering does not
turn an anchor result into a countdown. Sub-day compatibility components remain
residual and bounded to `0...23` hours, `0...59` minutes, and `0...59` seconds.

Before this amendment, non-birthday anchors compared exact timestamps. That
behavior is retained here as historical context, not as the current rule. A
future requirement may reintroduce precision-time semantics for a specific
anchor type only through a bounded type-level product decision and verification
plan; it must not silently restore mixed semantics across the Memory Engine.

## Decision Gate

- Primary loop: Product Loop.
- Observed scenario: a photo captured on the same calendar day as a configured
  birthday anchor currently falls through the elapsed-age wording and exposes
  `0天`, producing mechanical copy such as `今天宝宝0天`.
- Affected ownership: capture time remains Metadata Engine input; calendar-day
  comparison and relative result remain Memory Engine responsibilities;
  sentence wording remains Memory Expression / Presentation responsibility.
- Source of truth: the photo capture date, configured birthday anchor date,
  and capture calendar already carried by the accepted IA-003 pipeline.
- Apple-native capability: Foundation `Calendar` provides calendar-day
  comparison. No new framework, permission, entitlement, storage, or network
  behavior is required.
- Risk: P1 because the defect is visible in the primary memory output and can
  misstate the meaning of a birth-day photo. Failure modes are treating an
  earlier time on the same day as a countdown, retaining `0天` in a variable,
  or unintentionally changing non-anchor-day behavior. At initial acceptance,
  non-birthday exact-time ordering was intentionally outside this slice; the
  2026-08-06 amendment above supersedes that boundary.

## Accepted Behavior

For a birthday anchor, when the photo capture date and anchor date resolve to
the same calendar day in the capture calendar:

- the direction is `onAnchor`, regardless of time-of-day ordering;
- the complete Simplified Chinese memory expression is
  `{主体}今天来到这个世界啦！`;
- all birthday expression-style choices share this one anchor-day expression;
- the reusable birthday age result is `出生当天`, not a complete sentence;
- the complete English memory expression is
  `{Subject} arrived in the world today`;
- no primary birthday-day result may expose `0天` or `0 days`.

Before-anchor countdowns and after-anchor age results retain their existing
style-specific wording. The original 2026-08-04 decision left non-birthday
anchors unchanged; the 2026-08-06 amendment now aligns their day relationship
with the same calendar-day rule while preserving their type-specific wording.

## Boundaries

- Do not move meaning into Renderer, Layout Engine, or SwiftUI views.
- Apply the amended calendar-day comparison consistently across production
  anchor paths. Preserve the former non-birthday exact-time rule only as
  historical evidence for a future scoped precision review.
- Do not change original-photo, EXIF extraction, export, PhotoKit, Share
  Extension, or persistence behavior.
- Preserve the rule that smart anchor variables output reusable results rather
  than complete sentence copy.
- Keep compatibility output aligned with the canonical Memory Engine result.

## Verification Plan

1. Reproduce the existing `0天` behavior with failing unit tests.
2. Verify same-day dates with different times resolve as the anchor day.
3. Verify all five birthday expression styles use the accepted sentence.
4. Verify the reusable age result and compatibility path do not expose `0天`.
5. Verify English anchor-day wording.
6. Run focused tests, the complete `PhotoMemoTests` suite, the required Debug
   build, and `git diff --check`.

Manual visual acceptance is not required for the engine-only change. Final
rendered output on a representative same-day photo remains useful acceptance
evidence but does not replace the automated contract.
