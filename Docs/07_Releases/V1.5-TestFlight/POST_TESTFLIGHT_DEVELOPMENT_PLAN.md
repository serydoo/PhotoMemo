# MemoMark Post-TestFlight Development Plan

Last updated: 2026-07-08

This plan starts after MemoMark `1.5` enters TestFlight. It keeps the next
work focused on real tester evidence instead of expanding the product surface
too quickly.

## Current Release

- Version: `1.5`
- Build: Xcode Cloud generated, currently `13`, next expected `14`
- Purpose: first TestFlight validation of the Apple Photos share workflow
- Primary workflow:

```text
Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos
```

## Next Version Label

Use `1.6` for the next development cycle unless App Store Connect or emergency
release needs require a smaller build-only increment.

## Development Order

### 1. TestFlight Feedback Closure

- crashes and hangs
- failed share intake
- failed processing or save-back
- confusing permission prompts
- unclear first-run or guide copy

Acceptance check:

- reported blocking issues are reproduced or explicitly classified
- each accepted issue has a fix, a deferral reason, or a known limitation note

### 2. Reliability And Recovery

- failed-task retry polish
- clearer task-state language
- album refresh and save-back confirmation
- Share Extension edge-case handling

Acceptance check:

- testers can tell whether a shared photo is processing, completed, skipped, or
  needs attention

### 3. Render And Metadata Hardening

- preview/export consistency
- output sharpness and layout stability
- metadata retention validation
- location fallback clarity when photo metadata is missing

Acceptance check:

- generated output remains a new image and never modifies the original photo
- obvious layout breakage from common photo shapes is either fixed or documented

### 4. Memory Engine Continuation

- continue the approved IA-003 sequence without reopening Configuration Center
  architecture
- keep smart anchor variables as time results, not automatic full prose
- keep future renderer and layout changes behind specification and validation

Acceptance check:

- Memory Engine integration improves real output without adding unscoped UI or
  renderer-only layout changes

## Feedback Channels

Preferred tester channels:

- TestFlight built-in feedback for screenshots, recordings, and crash context
- email: `serydoo@gmail.com`
- public reproducible issues:
  `https://github.com/serydoo/PhotoMemo/issues`

Useful report details:

- device model
- iOS version
- MemoMark version and build
- whether the issue happened in Apple Photos Share or inside MemoMark
- steps to reproduce
- expected result
- actual result
- screenshots or screen recordings when available
