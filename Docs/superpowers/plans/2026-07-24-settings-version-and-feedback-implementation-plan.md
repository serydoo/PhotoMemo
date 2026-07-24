# MemoMark Settings Version And Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Display the installed MemoMark release as `1.7.47` and enrich Settings feedback channels while leaving the Home feedback card unchanged.

**Architecture:** Continue reading version and build values from the installed bundle, then combine them only in the Settings presentation. Reuse the existing native Settings inset rows for community and formal feedback channels; add no new navigation, clipboard, or state layer.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, localized `.strings`, Xcode 26.6.

---

## File Map

- Modify `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj` to keep every target at product version `1.7` and repository build baseline `47`.
- Modify `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift` to combine bundle version fields and add two informational feedback rows plus closing guidance.
- Modify `Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings` and `Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings` with symmetric version and feedback copy.
- Modify `Tests/PhotoMemoTests/ArchitectureTests/V1SettingsDisclosureContractTests.swift` with source contracts for the display and channel list.
- Preserve `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomeFeedbackSection.swift` byte-for-byte.
- Update `HANDOFF.md` with the corrected release-number convention and verification evidence.

### Task 1: Version Presentation Contract

**Files:**
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1SettingsDisclosureContractTests.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`

- [x] **Step 1: Write the failing source contract**

Add a test that requires `combinedAppVersion`, requires `"\(appVersion).\(appBuild)"`, and requires the release headline to use `combinedAppVersion` rather than `appVersion` alone.

- [x] **Step 2: Run the focused test and verify RED**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoSettingsTests \
  CODE_SIGNING_ALLOWED=NO -destination platform=macOS \
  -parallel-testing-enabled NO \
  -only-testing:PhotoMemoTests/V1SettingsDisclosureContractTests test
```

Expected: the new combined-version test fails because Settings still uses the separate version value.

- [x] **Step 3: Implement the minimal version presentation**

Add:

```swift
private var combinedAppVersion: String {
    "\(appVersion).\(appBuild)"
}
```

Use `combinedAppVersion` in the primary headline. Keep the supporting text explicit about product version and Xcode Cloud build, with localized values sourced from the bundle.

- [x] **Step 4: Run the focused test and verify GREEN**

Run the Step 2 command again. Expected: the suite passes.

### Task 2: Settings Feedback Contract

**Files:**
- Modify: `Tests/PhotoMemoTests/ArchitectureTests/V1SettingsDisclosureContractTests.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift`
- Modify: `Source/PhotoMemo/PhotoMemo/en.lproj/Localizable.strings`
- Modify: `Source/PhotoMemo/PhotoMemo/zh-Hans.lproj/Localizable.strings`

- [x] **Step 1: Write the failing feedback contract**

Require Settings source to contain all five channel identities:

```text
小红书、抖音
955680366
TestFlight 反馈
邮件反馈
GitHub Issues
```

Also require the two community rows to use the existing non-actionable information-row pattern and keep email/GitHub actions intact.

- [x] **Step 2: Run the focused test and verify RED**

Run the Task 1 focused command. Expected: the new feedback test fails because Settings does not yet contain Xiaohongshu, Douyin, or the QQ group.

- [x] **Step 3: Implement the five-channel Settings list**

Insert informational rows for social search and the QQ group before TestFlight. Preserve TestFlight as guidance, preserve the existing email and GitHub actions, and add a closing caption welcoming experience reports, defects, and customization ideas. Use the current inset background, divider, icon, and typography conventions.

- [x] **Step 4: Add symmetric localized resources**

Add matching Simplified Chinese and English values for the new community rows, closing caption, and version supporting line. Do not add keys to only one locale.

- [x] **Step 5: Run focused Settings and localization tests**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoSettingsTests \
  CODE_SIGNING_ALLOWED=NO -destination platform=macOS \
  -parallel-testing-enabled NO \
  -only-testing:PhotoMemoTests/V1SettingsDisclosureContractTests \
  -only-testing:PhotoMemoTests/MemoMarkCommerceUIContractTests test
```

Expected: both suites pass, including localization-key symmetry.

### Task 3: Boundary And Build Verification

**Files:**
- Verify: `Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomeFeedbackSection.swift`
- Update: `HANDOFF.md`

- [x] **Step 1: Prove Home remains unchanged**

Run:

```bash
git diff --exit-code -- Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomeFeedbackSection.swift
```

Expected: no output and exit 0.

- [x] **Step 2: Verify project versions and diff formatting**

Require every `MARKETING_VERSION` to equal `1.7`, every `CURRENT_PROJECT_VERSION` to equal `47`, and run `git diff --check`.

- [x] **Step 3: Build the iOS app with Xcode 26.6**

Run:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOS -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoSettingsIOS \
  CODE_SIGNING_ALLOWED=NO \
  -destination 'generic/platform=iOS Simulator' -quiet build
```

Expected: exit 0. Inspect the built app and embedded extensions to confirm `CFBundleShortVersionString = 1.7` and `CFBundleVersion = 47`.

- [x] **Step 4: Record the release correction**

Update `HANDOFF.md` with the field mapping, Settings combined display, focused test result, build result, and the fact that Home remained unchanged.

### Task 4: Signed iPhone7 Delivery

**Files:**
- Build product: `/tmp/PhotoMemoSettingsDevice/Build/Products/Debug-iphoneos/PhotoMemoiOS.app`

- [x] **Step 1: Build a signed physical-device package**

Use Xcode 26.6 and device `863C2747-6742-5E93-B715-6F89DBF90B31` with automatic provisioning. Expected: build succeeds and embedded extensions validate.

- [x] **Step 2: Install without deleting the current app container**

Install the signed package over the existing App. Do not uninstall, because this delivery should preserve the user's newly recreated local configuration and queues.

- [ ] **Step 3: Launch and verify installed inventory**

Launch `com.serydoo.PhotoMemo.iOS`, then confirm device inventory reports version `1.7` and build `47`. Manual acceptance checks the bottom Settings row displays `时光记 1.7.47` and the enriched feedback section while Home remains unchanged.

## Repository Boundary

Do not stage, commit, or push in this task. Do not include BrandMark research or private App Store media.
