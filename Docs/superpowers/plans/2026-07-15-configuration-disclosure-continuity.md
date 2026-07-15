# Configuration Disclosure Continuity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Configuration Center disclosure rows expand and collapse with an interruptible, critically damped spring while preserving Reduce Motion behavior.

**Architecture:** Keep `IOSCompactEntryDisclosureRow` as the sole owner of disclosure presentation. Change only its animation curve; preserve bindings, layout, content construction, hit targets, and accessibility values.

**Tech Stack:** SwiftUI, Swift Testing, Xcode

---

### Task 1: Lock the animation contract

**Files:**
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1NativeSystemInteractionContractTests.swift`

- [x] **Step 1: Write the failing contract test**

Add a test that reads `IOSCompactEntryRow.swift` and requires `interactiveSpring`, the approved `response: 0.32`, `dampingFraction: 1`, and the existing `accessibilityReduceMotion` branch.

- [x] **Step 2: Run the focused test and verify RED**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/PhotoMemoDisclosureContinuityTests CODE_SIGNING_ALLOWED=NO -only-testing:PhotoMemoTests/V1NativeSystemInteractionContractTests test -quiet
```

Expected: the new disclosure-animation contract fails because the source still uses `.easeInOut(duration: 0.18)`.

### Task 2: Apply the minimal interaction change

**Files:**
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/IOSCompactEntryRow.swift`

- [x] **Step 1: Replace the fixed easing**

Use this animation when Reduce Motion is disabled:

```swift
.interactiveSpring(
    response: 0.32,
    dampingFraction: 1,
    blendDuration: 0.08
)
```

Keep `nil` animation when Reduce Motion is enabled.

- [x] **Step 2: Run the focused test and verify GREEN**

Run the same focused test command. Expected: all `V1NativeSystemInteractionContractTests` pass.

- [x] **Step 3: Build the app**

Run:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Expected: build exits with status 0.

### Task 3: Record the verified UI slice

**Files:**
- Modify: `Docs/CURRENT_STATUS.md`

- [x] **Step 1: Append a concise chronicle entry**

Record the interaction change, scope boundary, focused test result, build result, and whether physical-device behavior was manually verified.

- [x] **Step 2: Check patch integrity**

Run `git diff --check` and inspect the scoped diff for the plan, test, implementation, and status entry.
