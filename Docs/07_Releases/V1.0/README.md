# MemoMark V1.0 Testing Release

Release label: `v1.0.0-test1`

App version:

- Marketing version: `1.0`
- Build number: `1`
- Bundle ID: `com.serydoo.PhotoMemo.iOS`

Repository policy:

- Signed IPA files and provisioning profiles are not stored in source control.
- Use TestFlight or a locally generated archive for installation testing.

Packaging notes:

- This release can be exported as a signed `debugging` IPA from a local Xcode signing setup.
- The generated artifact is suitable only for internal testing or devices allowed by the active provisioning profile.
- Wider public distribution still requires a broader distribution path such as TestFlight or an ad hoc profile that includes every tester device.
- Never commit the generated IPA, archive, or embedded provisioning data.

Source:

- Branch: `v1-checkpoint-20260702`
- Tag: `v1.0.0-test1`

Build/export commands:

```bash
xcodebuild -project Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOSV1 \
  -destination "generic/platform=iOS" \
  -archivePath /tmp/MemoMark-V1.0.0-test1.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath /tmp/MemoMark-V1.0.0-test1.xcarchive \
  -exportPath /tmp/MemoMark-V1.0.0-test1-export \
  -exportOptionsPlist scripts/export_options_v1_testing.plist
```
