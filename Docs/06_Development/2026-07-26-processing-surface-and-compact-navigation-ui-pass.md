# 2026-07-26 Processing Surface And Compact Navigation UI Pass

## Objective

Improve the iPhone Processing surface so that it communicates the meaningful
result of the Apple Photos workflow instead of presenting a completed task as
an in-progress diagnostic checklist.

The target scenario is a completed one-photo job. The current surface repeats
the same job in Current Task and Recent Tasks, shows a 100 percent gray progress
bar, and gives every completed pipeline step the same timestamp.

## Decision Gate

- Primary loop: Product Loop.
- Evidence: signed-device screenshots captured on 2026-07-26.
- Risk: P1. This is a primary Apple Photos -> MemoMark -> Apple Photos
  confirmation surface; incorrect state mapping could hide an actionable
  failure or make navigation inaccessible.
- Source of truth: `PhotoMemoBackgroundJobSnapshot.presentationState` remains
  the task-state owner. `V1SettingsPagePresenter` projects that truth for the
  view.
- Apple-native evaluation: keep SwiftUI's standard `TabView` unchanged because
  it owns destination state and does not expose a public compact-width tab-bar
  width. No new permissions, persistence, Photos, export, or background-work
  behavior is introduced.

## Scope

### Processing Surface

The page must project four states:

1. Waiting: concise readiness guidance and recent results.
2. Processing: current action, actual progress, and optional pipeline detail.
3. Completed: a short success result with one completion time and the existing
   Apple Photos link. It must not show a 100 percent progress bar or a visible
   step-by-step checklist by default.
4. Needs attention: the actionable status message and pipeline detail remain
   visible. This pass does not invent retry behavior.

The just-completed job must not appear again as the first item in Recent Tasks.
Completed state remains identifiable with both text and a success symbol;
color is secondary reinforcement only.

## Implementation Plan

1. Add presentation contracts for the display mode, current job identifier,
   and de-duplicated history.
2. Use those contracts to render state-specific Processing sections.
3. Verify with focused Swift Testing, iOS and macOS builds, and a signed-device
   installation on iPhone 17 Pro Max.

## Files In Scope

- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPagePresenter.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/V1TaskPageSurface.swift`
- focused Architecture tests for the presenter and Processing surface contract

## Verification

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO test
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'platform=iOS,id=863C2747-6742-5E93-B715-6F89DBF90B31' -derivedDataPath /tmp/PhotoMemoDeviceDerivedData build
```

Manual acceptance requires checking Waiting, Processing, Completed, and Needs
Attention content on compact width, then confirming that the completed result
opens the existing Apple Photos destination.

## Boundaries

- Always: retain the existing queue snapshot as task truth, preserve the
  Apple Photos link, retain Dynamic Type and VoiceOver labels, and run builds
  before device installation.
- Ask first: task lifecycle, retry semantics, background scheduling,
  persistence, Photos authorization, or the four destination set.
- Never: use progress fraction or color to infer task state, alter the
  renderer/export pipeline, or reintroduce a Dashboard or Task Center workflow.
