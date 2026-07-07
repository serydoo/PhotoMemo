# PhotoMemo Privacy Statement

Last updated: 2026-07-07

PhotoMemo is designed as a local-first memory presentation app for Apple
Photos.

## Summary

- PhotoMemo does not require an account.
- PhotoMemo does not upload photos to a server.
- PhotoMemo does not modify original photos.
- PhotoMemo generates a new image as output.
- PhotoMemo does not track users.
- PhotoMemo does not use third-party advertising SDKs.
- PhotoMemo does not declare collected data types in its privacy manifests.

## Photo Access

PhotoMemo requests Photo Library access so users can:

- share selected photos from Apple Photos to PhotoMemo
- process those selected photos locally
- save generated memory-card images back to Apple Photos

PhotoMemo should be used with photos the tester is comfortable using in a beta
build.

## Local Storage

PhotoMemo stores configuration, processing state, and shared workflow data
locally on the device using the app container and App Group container.

Examples include:

- selected Preset and output behavior
- Memory Subject configuration
- queue and processing state
- local duplicate-detection identifiers for shared items

## Networking

Normal PhotoMemo operation does not require server communication. The current
MVP is built around local processing and the Apple Photos share workflow.

## Original Photo Safety

PhotoMemo does not destructively edit the original photo. The intended output
is a newly generated image saved back to Apple Photos.

## App Privacy Labels

Recommended App Store Connect privacy label for the current TestFlight build:

```text
Data Not Collected
Tracking: No
```

The account owner should confirm final App Store Connect privacy answers before
submission.

## Public Privacy Policy URL

Use this URL in App Store Connect:

```text
https://github.com/serydoo/PhotoMemo/blob/main/PRIVACY.md
```

## Contact

- serydoo@gmail.com
- serydoo@163.com
