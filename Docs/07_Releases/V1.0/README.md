# PhotoMemo V1.0 Testing Release

Release label: `v1.0.0-test1`

App version:

- Marketing version: `1.0`
- Build number: `1`
- Bundle ID: `com.serydoo.PhotoMemo.iOS`

Artifacts:

- `PhotoMemo-V1.0.0-test1.ipa`

Packaging notes:

- This release is exported as a signed `debugging` IPA from the current local Xcode signing setup.
- It is suitable for internal testing, developer-device installation, or any device allowed by the active provisioning profile.
- Wider public distribution still requires a broader distribution path such as TestFlight or an ad hoc profile that includes every tester device.

Source:

- Branch: `v1-checkpoint-20260702`
- Tag: `v1.0.0-test1`

Build/export commands:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOSV1 \
  -destination "generic/platform=iOS" \
  -archivePath /tmp/PhotoMemo-V1.0.0-test1.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath /tmp/PhotoMemo-V1.0.0-test1.xcarchive \
  -exportPath /tmp/PhotoMemo-V1.0.0-test1-export \
  -exportOptionsPlist scripts/export_options_v1_testing.plist
```
