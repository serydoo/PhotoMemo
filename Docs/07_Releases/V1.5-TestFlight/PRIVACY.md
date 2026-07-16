# MemoMark Privacy Statement

Last updated: 2026-07-07

MemoMark is designed as a local-first memory presentation app for Apple
Photos.

## Summary

- MemoMark does not require an account.
- MemoMark does not upload photos to a server.
- MemoMark does not modify original photos.
- MemoMark generates a new image as output.
- MemoMark does not track users.
- MemoMark does not use third-party advertising SDKs.
- MemoMark does not declare collected data types in its privacy manifests.

## Photo Access

MemoMark requests Photo Library access so users can:

- share selected photos from Apple Photos to MemoMark
- process those selected photos locally
- save generated memory-card images back to Apple Photos

MemoMark should be used with photos the tester is comfortable using in a beta
build.

## Local Storage

MemoMark stores configuration, processing state, and shared workflow data
locally on the device using the app container and App Group container.

Examples include:

- selected Preset and output behavior
- Memory Subject configuration
- queue and processing state
- local duplicate-detection identifiers for shared items

## Networking

Normal MemoMark operation does not require server communication. The current
MVP is built around local processing and the Apple Photos share workflow.

## Original Photo Safety

MemoMark does not destructively edit the original photo. The intended output
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
