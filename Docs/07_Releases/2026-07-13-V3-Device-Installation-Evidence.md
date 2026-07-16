# MemoMark V3 Device Installation Evidence

Date: 2026-07-13
Product stage: V3 Production Quality And Delivery

## Build Identity

- Git commit: `eeffb07233d4ad983a1a8c7feecdb634dd3363bb`
- Bundle identifier: `com.serydoo.PhotoMemo.iOS`
- App version: `1.7 (7)`
- Signing team and identity: verified privately; identifiers intentionally
  omitted from the repository.
- TestDeviceA/TestDeviceB main executable SHA-256:
  `6d1ea6913aed62d9401599593c54ee12cceaaddc68153a0f5a322cba49b3ff34`
- TestDeviceC fresh rebuild main executable SHA-256:
  `846fcbed865810ea8718219c068df494170e5190bded46e2e17646a7ccf37a74`
- Embedded extensions:
  - `com.serydoo.PhotoMemo.iOS.ShareExtension`
  - `com.serydoo.PhotoMemo.iOS.WidgetExtension`

The main app and both extensions passed recursive code-signature validation.
Their provisioning profiles include the two installed devices and remain valid
until 2027-07-13.

## Verification Before Installation

- UI/configuration/filename contract group: `30/30`
- Live Photo naming/media contract group: `31/31`
- Expanded configuration lifecycle group: `110/110`
- macOS Debug build: passed
- generic iOS Debug build: passed
- Share Extension Debug build: passed
- signed generic iOS Debug build: passed

## Device Results

### TestDeviceA - iPhone 15 Pro

- Existing `com.serydoo.PhotoMemo.iOS` installation removed successfully.
- Signed `1.7 (7)` app installed successfully.
- The device required its normal first developer-app trust/open step after the
  clean removal.
- App launch subsequently succeeded through `devicectl`.
- Final device inspection reported the app as a removable developer app.
- Final process inspection confirmed `PhotoMemoiOS` running; the Widget
  extension also launched during verification.

### TestDeviceB - iPhone 17 Pro Max

- Existing `com.serydoo.PhotoMemo.iOS` installation removed successfully.
- The same signed `1.7 (7)` app installed successfully.
- App launch succeeded through `devicectl` after the device was unlocked.
- Final device inspection reported the expected bundle identifier and version.
- Final process inspection confirmed `PhotoMemoiOS` running; the Widget
  extension launched during initial verification.

### TestDeviceC - iPhone 15 Pro

- The device returned online as a paired physical iPhone with Developer Mode
  enabled.
- A fresh signed app was built from current `main` rather than reusing the
  previous temporary artifact.
- Existing `com.serydoo.PhotoMemo.iOS` installation was removed successfully.
- Signed `1.7 (7)` app installed successfully.
- App launch succeeded through `devicectl` after the device was unlocked.
- Final process inspection confirmed both `PhotoMemoiOS` and the Widget
  extension running.

## Reproduction

Build one signed app:

```bash
xcodebuild \
  -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOS \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/PhotoMemoSignedInstall \
  -allowProvisioningUpdates \
  -quiet build
```

For each connected and unlocked device:

```bash
xcrun devicectl device uninstall app \
  --device '<device-name>' \
  com.serydoo.PhotoMemo.iOS

xcrun devicectl device install app \
  --device '<device-name>' \
  /tmp/PhotoMemoSignedInstall/Build/Products/Debug-iphoneos/PhotoMemoiOS.app

xcrun devicectl device process launch \
  --device '<device-name>' \
  --terminate-existing \
  com.serydoo.PhotoMemo.iOS
```

The device must be unlocked. A clean developer-app installation may require a
one-time trust/open confirmation on the device before remote launch succeeds.
