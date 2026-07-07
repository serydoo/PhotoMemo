# App Store Connect Materials - PhotoMemo 1.5

Last updated: 2026-07-07

Use this document as the copy source when creating or updating the App Store
Connect app record and TestFlight information.

## App Record

Recommended values:

- App name: `PhotoMemo`
- Bundle ID: `com.serydoo.PhotoMemo.iOS`
- SKU: `photomemo-ios`
- Primary language: `Simplified Chinese`
- Category: `Photo & Video`
- Secondary category: `Lifestyle`
- Version: `1.5`
- Build: `5`
- Copyright:
  `Copyright (c) 2026 serydoo wang. All rights reserved.`

Confirmed owner fields:

- Support URL: `https://github.com/serydoo/PhotoMemo`
- Privacy Policy URL: `https://github.com/serydoo/PhotoMemo/blob/main/PRIVACY.md`
- Marketing URL: optional
- App Review contact name: `汪瑞`
- App Review contact email: `serydoo@gmail.com`
- App Review contact phone: `18937050153`

## TestFlight Beta App Description

English:

```text
PhotoMemo is a local-first memory presentation app for Apple Photos. It helps testers generate clean memory cards from selected photos while preserving the original image.

The app does not require an account. Normal operation does not require a server. Photo processing is performed locally on the device, and original photos are not modified.
```

Chinese:

```text
PhotoMemo 是一款围绕 Apple Photos 打造的本地优先记忆呈现应用。它会根据用户选择的照片生成新的记忆卡片，同时保留原始照片不变。

应用无需注册账号，核心功能不依赖服务器。照片处理在本机完成，不会修改原始照片。
```

## TestFlight What To Test

English:

```text
Please test the core Apple Photos workflow:

1. Open Apple Photos.
2. Share one or more static photos to PhotoMemo.
3. Confirm that PhotoMemo receives the photos and starts processing.
4. Open PhotoMemo if needed to review processing state and configuration.
5. Confirm that generated output is saved back as a new image.

Please focus feedback on share intake, permission prompts, preview consistency, memory text accuracy, export quality, saved-photo behavior, crashes, and confusing interactions.
```

Chinese:

```text
请重点测试 Apple Photos 工作流：

1. 打开系统相册 Apple Photos。
2. 将一张或多张静态照片分享给 PhotoMemo。
3. 确认 PhotoMemo 能接收照片并开始处理。
4. 如有需要，打开 PhotoMemo 查看处理状态和当前配置。
5. 确认处理结果会作为一张新图片保存回系统相册。

请重点反馈分享入口、权限弹窗、预览一致性、记忆文字准确性、导出质量、保存回相册行为、闪退以及不易理解的交互。
```

## Test Information

- Feedback email: `serydoo@gmail.com`
- Alternate feedback email: `serydoo@163.com`
- Beta review contact: `serydoo@gmail.com`
- Sign-in required: `No`
- Demo account required: `No`
- Notes for tester invitation:

```text
PhotoMemo 1.5 is the first TestFlight build focused on validating the local-first Apple Photos share workflow. Please test with non-sensitive photos first and include device model, iOS version, screenshots, and reproduction steps when reporting issues.
```

## App Review Notes

Use `APP_REVIEW_NOTES_EN.md` for the App Review notes field.

Short copy:

```text
PhotoMemo does not require login. To test, open Apple Photos, select a static photo, share it to PhotoMemo, then allow Photo Library access when prompted. PhotoMemo processes the photo locally and saves a generated memory-card image back to the user's library. The original photo is not modified.
```

## App Privacy

Recommended App Privacy answers for the current build:

- Data collection: `No data collected`
- Tracking: `No`
- Third-party advertising: `No`
- Photos uploaded to server: `No`
- Account creation: `No`
- Analytics SDKs: `No`

Notes:

- The app reads user-selected photos only to generate local output.
- The app saves generated images back to the photo library.
- Shared settings and processing state are stored locally using app container
  and App Group storage.
- Privacy manifests declare no tracking and no collected data types.

## Export Compliance

Recommended summary:

```text
PhotoMemo does not provide encryption, secure messaging, VPN, file encryption, or network security functionality. The current build does not require server communication for normal operation.

The app uses Apple platform APIs, including CryptoKit SHA-256 hashing in the Share Extension, only to create local duplicate-detection identifiers for shared photo data. This hashing is not exposed to users as an encryption feature and is not used to transmit or protect network communications.
```

Final App Store Connect answer should be confirmed by the account owner before
submission, because export-compliance answers are legal/compliance declarations.

## Permission Copy

Current photo permission purpose:

```text
PhotoMemo needs Photo Library access so users can share selected photos into the app and save generated memory-card images back to Apple Photos.
```

## Review Risk Notes

- The app has no login, so review does not need demo credentials.
- The first launch should explain local-first behavior and the Apple Photos
  workflow.
- If reviewers open only the app and do not use Apple Photos Share, they should
  still see the Configuration Center and usage guide.
- TestFlight upload should use version `1.5` and build `5`.
