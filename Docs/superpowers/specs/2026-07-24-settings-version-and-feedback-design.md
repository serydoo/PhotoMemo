# MemoMark Settings Version And Feedback Design

**Date:** 2026-07-24
**Stage:** V3 Production Quality And Delivery
**Status:** Pending written-spec review

## Objective

Correct MemoMark's release-number presentation and enrich the Settings feedback
section without changing the existing Home feedback card.

## Current Evidence

- The release convention is product version `1.7` plus the Xcode Cloud build
  number, producing the combined shorthand `1.7.47`.
- The project had incorrectly encoded `1.7.47` as `MARKETING_VERSION` while
  retaining `8` as `CURRENT_PROJECT_VERSION`, which produced the confusing
  local presentation `1.7.47 (8)`.
- Settings currently presents `CFBundleShortVersionString` and
  `CFBundleVersion` on separate lines.
- Home already lists direct developer contact through Xiaohongshu, Douyin, and
  QQ group `955680366`.
- Settings currently lists TestFlight, email, and GitHub Issues but omits the
  direct community channels.

## Version Decision

- Keep `MARKETING_VERSION = 1.7` for every project target and configuration.
- Keep the current repository baseline at `CURRENT_PROJECT_VERSION = 47` for
  every project target and configuration.
- Let the next Xcode Cloud build advance the cloud-owned build number to `48`.
- Settings combines the installed bundle values as `1.7.47` and uses that value
  in the primary version headline.
- The supporting line explains the two source fields separately: product
  version `1.7` and Xcode Cloud build `47`.
- The values must continue to come from the installed bundle; no user-facing
  release number is hard-coded in SwiftUI.

## Feedback Decision

The Settings feedback section uses one continuous native inset list in this
order:

1. Xiaohongshu and Douyin: search `MemoMark` to contact the developer directly.
2. QQ community group: `955680366`.
3. TestFlight feedback for screenshots, recordings, crashes, and device context.
4. Email feedback through the existing mail action.
5. GitHub Issues through the existing repository action.

The first two rows are informational and allow text selection. Email and GitHub
remain actionable. TestFlight remains guidance rather than a fake in-app action.
A short closing line welcomes product experience, bug reports, and customization
ideas.

## Home Boundary

`V1HomeFeedbackSection` remains unchanged in structure, content, state,
animation, and persistence. This pass only enriches the Settings copy and rows.

## Localization And Accessibility

- Add matching Simplified Chinese and English resource entries for all new
  Settings feedback and version-supporting copy.
- Preserve the existing interface-language selection behavior.
- Keep visible labels on every row, meaningful system symbols, selectable
  community identifiers, and the existing native link-row accessibility.

## Verification

- Add a failing source contract for the combined installed version display.
- Add a failing source contract for all five Settings feedback channels.
- Retain the existing localization-key symmetry contract.
- Confirm `V1HomeFeedbackSection.swift` has no diff.
- Run the focused Settings and localization tests.
- Run `git diff --check` and the generic iOS Simulator Debug build.

## Out Of Scope

- No Home feedback redesign.
- No social-platform deep links, QQ deep links, clipboard action, toast, or new
  state management.
- No changes to StoreKit, Commerce allowance, Renderer, Metadata, Export,
  Share Extension admission, PhotoKit, or Layout Engine behavior.
