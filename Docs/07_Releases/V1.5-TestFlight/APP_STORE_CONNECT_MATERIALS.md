# App Store Connect Materials - MemoMark 1.5

Last updated: 2026-07-09

Use this document as the copy source when creating or updating the App Store
Connect app record and TestFlight information.

## App Record

Recommended values:

- App name: `MemoMark`
- Bundle ID: `com.serydoo.PhotoMemo.iOS`
- SKU: `photomemo-ios`
- Primary language: `Simplified Chinese`
- Category: `Photo & Video`
- Secondary category: `Lifestyle`
- Version: `1.5`
- Build: Xcode Cloud generated, currently `13`, next expected `14`
- Next planned development label: `1.6`
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
MemoMark is a local-first memory presentation app for Apple Photos. It helps testers generate clean memory cards from selected photos while preserving the original image.

The app does not require an account. Normal operation does not require a server. Photo processing is performed locally on the device, and original photos are not modified.
```

Chinese:

```text
时光记是一款围绕 Apple Photos 打造的本地优先记忆呈现应用。它会根据用户选择的照片生成新的记忆卡片，同时保留原始照片不变。

应用无需注册账号，核心功能不依赖服务器。照片处理在本机完成，不会修改原始照片。
```

## TestFlight What To Test

English:

```text
Please test the core Apple Photos workflow:

1. Open Apple Photos.
2. Share one or more static photos to MemoMark.
3. Confirm that MemoMark receives the photos and starts processing.
4. Open MemoMark if needed to review processing state and configuration.
5. Confirm that generated output is saved back as a new image.

For builds created from commit c6b97d99 or later, please also test the Main App Picker Live Photo release-candidate path: select a normal Live Photo inside MemoMark, export with original-format output, and confirm Photos recognizes the saved result as a Live Photo with stable portrait/landscape geometry.

Please focus feedback on share intake, permission prompts, preview consistency, memory text accuracy, export quality, saved-photo behavior, crashes, and confusing interactions.
```

Chinese:

```text
请重点测试 Apple Photos 工作流：

1. 打开系统相册 Apple Photos。
2. 将一张或多张静态照片分享给时光记。
3. 确认时光记能接收照片并开始处理。
4. 如有需要，打开时光记查看处理状态和当前配置。
5. 确认处理结果会作为一张新图片保存回系统相册。

如果测试的是 commit c6b97d99 或之后生成的构建，也请测试主程序 Picker 的 Live Photo release-candidate 路径：在时光记内选择一张正常 Live Photo，使用原格式输出，确认保存结果能被系统相册识别为 Live Photo，并且横竖图几何稳定。

请重点反馈分享入口、权限弹窗、预览一致性、记忆文字准确性、导出质量、保存回相册行为、闪退以及不易理解的交互。
```

## Test Information

- Feedback email: `serydoo@gmail.com`
- Alternate feedback email: `serydoo@163.com`
- Xiaohongshu contact: `49956456623`
- Public issue tracker: `https://github.com/serydoo/PhotoMemo/issues`
- Beta review contact: `serydoo@gmail.com`
- Sign-in required: `No`
- Demo account required: `No`
- Notes for tester invitation:

```text
MemoMark 1.5 is the first TestFlight build focused on validating the local-first Apple Photos share workflow. Please test with non-sensitive photos first and include device model, iOS version, screenshots, and reproduction steps when reporting issues.
```

## Supported Scope And Output Format

Use this when testers or reviewers ask what the current TestFlight build
supports.

English:

```text
MemoMark 1.5 primarily focuses on user-selected static photos shared from Apple Photos. It supports single-photo and small multi-photo share flows, photos with or without location metadata, and local generation of a memory-card result.

Builds created from commit c6b97d99 or later also include Main App Picker Live Photo release-candidate support. This path can save a new motion-preserving Live Photo or a static image depending on output settings. Share Extension Live Photo remains a known production-validation limitation.

MemoMark does not modify the original photo. Videos, advanced batch management, cloud processing, account sync, and full custom layout editing are outside the current TestFlight scope.
```

Chinese:

```text
时光记 1.5 主要聚焦从 Apple Photos 主动分享的静态照片。它支持单张照片和少量多张照片分享，支持有位置信息或无位置信息的照片，并在本机生成记忆卡片结果。

commit c6b97d99 或之后生成的构建还包含主程序 Picker 的 Live Photo release-candidate 支持。该路径可根据输出设置保存新的动态 Live Photo 或静态图片。Share Extension 的 Live Photo 路径仍属于后续 production validation 的已知限制。

时光记不会修改原始照片。视频、高级批量管理、云端处理、账号同步和完整自定义布局编辑不属于当前 TestFlight 范围。
```

## Feedback Channels

Recommended public tester copy:

```text
Please send feedback through TestFlight's built-in feedback button when possible, especially for crashes, screenshots, and screen recordings. You can also email serydoo@gmail.com or serydoo@163.com. Chinese testers can contact Xiaohongshu ID 49956456623 for group discussion.

For reproducible issues, please include device model, iOS version, MemoMark build number, whether the issue happened in Apple Photos Share or inside MemoMark, steps to reproduce, expected result, actual result, and screenshots or recordings if available.
```

Optional public issue tracker:

```text
GitHub Issues: https://github.com/serydoo/PhotoMemo/issues
```

## Post-TestFlight Development Plan

Short public-facing version:

```text
After the 1.5 TestFlight validation, the next development focus is reliability and feedback closure: share intake edge cases, permission clarity, save-back behavior, failed-task retry polish, and clearer Configuration Center guidance. Later builds will continue render fidelity, metadata retention, and Memory Engine integration without changing the local-first and non-destructive workflow.
```

## App Review Notes

Use `APP_REVIEW_NOTES_EN.md` for the App Review notes field.

Short copy:

```text
MemoMark does not require login. To test, open Apple Photos, select a static photo, share it to MemoMark, then allow Photo Library access when prompted. MemoMark processes the photo locally and saves a generated memory-card image back to the user's library. The original photo is not modified.
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
MemoMark does not provide encryption, secure messaging, VPN, file encryption, or network security functionality. The current build does not require server communication for normal operation.

The app uses Apple platform APIs, including CryptoKit SHA-256 hashing in the Share Extension, only to create local duplicate-detection identifiers for shared photo data. This hashing is not exposed to users as an encryption feature and is not used to transmit or protect network communications.
```

Final App Store Connect answer should be confirmed by the account owner before
submission, because export-compliance answers are legal/compliance declarations.

## Permission Copy

Current photo permission purpose:

```text
MemoMark needs Photo Library access so users can share selected photos into the app and save generated memory-card images back to Apple Photos.
```

## Review Risk Notes

- The app has no login, so review does not need demo credentials.
- The first launch should explain local-first behavior and the Apple Photos
  workflow.
- If reviewers open only the app and do not use Apple Photos Share, they should
  still see the Configuration Center and usage guide.
- TestFlight upload should use version `1.5` and the next Xcode Cloud build.
