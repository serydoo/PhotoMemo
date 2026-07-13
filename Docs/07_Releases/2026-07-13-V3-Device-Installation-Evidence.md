# MemoMark V3 Device Installation Evidence

Date: 2026-07-13  
Product stage: V3 Production Quality And Delivery

## Build Identity

- Git commit: `eeffb07233d4ad983a1a8c7feecdb634dd3363bb`
- Bundle identifier: `com.serydoo.PhotoMemo.iOS`
- App version: `1.7 (7)`
- Signing team: `UK7ZR8G564`
- Signing identity: `Apple Development: serydoo@163.com (GE3672Z8WA)`
- Main executable SHA-256:
  `6d1ea6913aed62d9401599593c54ee12cceaaddc68153a0f5a322cba49b3ff34`
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

### IPhone5 — iPhone 15 Pro

- Existing `com.serydoo.PhotoMemo.iOS` installation removed successfully.
- Signed `1.7 (7)` app installed successfully.
- The device required its normal first developer-app trust/open step after the
  clean removal.
- App launch subsequently succeeded through `devicectl`.
- Final device inspection reported the app as a removable developer app.
- Final process inspection confirmed `PhotoMemoiOS` running; the Widget
  extension also launched during verification.

### iPhone7 — iPhone 17 Pro Max

- Existing `com.serydoo.PhotoMemo.iOS` installation removed successfully.
- The same signed `1.7 (7)` app installed successfully.
- App launch succeeded through `devicectl` after the device was unlocked.
- Final device inspection reported the expected bundle identifier and version.
- Final process inspection confirmed `PhotoMemoiOS` running; the Widget
  extension launched during initial verification.

### Hong — iPhone 15 Pro

- The device was off-site and unavailable to CoreDevice.
- No uninstall, data deletion, installation, or launch was attempted.
- The user explicitly deferred this device until it returns.
- When available, reuse the same clean deployment sequence below and create a
  new signed build from the then-current verified commit rather than relying on
  the temporary build directory.

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
