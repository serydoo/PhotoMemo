# MemoMark 1.5 TestFlight Release Materials

Last updated: 2026-07-08

This folder contains the prepared materials for MemoMark 1.5 TestFlight and
App Store Connect setup.

## Build Identity

- App version: `1.5`
- Build number: Xcode Cloud generated, currently `13`, next expected `14`
- Bundle ID: `com.serydoo.PhotoMemo.iOS`
- Team ID: `UK7ZR8G564`
- Signing path verified: Cloud Managed Apple Distribution
- Primary workflow:

```text
Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos
```

## Files

- `APP_STORE_CONNECT_MATERIALS.md` - copy-ready App Store Connect fields
- `TESTFLIGHT_GUIDE_EN.md` - English TestFlight tester guide
- `TESTFLIGHT_GUIDE_ZH.md` - Chinese TestFlight tester guide
- `APP_REVIEW_NOTES_EN.md` - notes for Apple Beta App Review
- `APP_REVIEW_NOTES_ZH.md` - Chinese internal copy of review notes
- `PRIVACY.md` - privacy and data-handling statement
- `KNOWN_ISSUES.md` - current MVP limitations for testers
- `POST_TESTFLIGHT_DEVELOPMENT_PLAN.md` - follow-up development plan after
  TestFlight feedback

## Before Upload

- Confirm App Store Connect category and final support/privacy URLs.
- Run a final Release archive/export after all version and material updates.
