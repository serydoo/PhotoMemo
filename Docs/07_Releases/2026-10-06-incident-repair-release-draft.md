# MemoMark incident repair — release draft, 2026-10-06

Status: local engineering repair; no version bump, Git sync, upload or review submission performed.

Suggested release identifier: 2.3.6 (123), subject to current release-owner confirmation and fresh remote/build checks. Installed debugging package remains 2.3.5 (122); do not use its unchanged numeric identifier to claim the App Store contains this repair.

## Review scope

Existing approved lifetime SKU becomes directly purchasable beneath subscriptions. Verified Apple transaction and restore rules remain authoritative. No new IAP or local activation system. Annual/monthly products remain available, but the temporary first-year-free campaign is withdrawn when repaired public version becomes downloadable.

Live Photo motion formats outside native-backdrop capability use the existing compatible card surface for both still and motion; original assets and pair identity remain protected. This closes the source-level nativeBackdropColorUnsupported path, not broad HDR/P3/performance certification. Device reproduction and Photos paired readback are required before release.

## Draft What's New

zh-Hans: 新增 MemoMark+ 永久解锁选项。改善部分 Live Photo 保存失败的问题，并优化失败后的重试提示。照片在本地处理，原图保持不变。

en: Added a lifetime unlock option for MemoMark+. Improved saving for some Live Photos and clarified retry guidance. Photos are processed locally, and originals remain unchanged.

ja: MemoMark+ の永久アンロックを選べるようになりました。一部の Live Photo の保存失敗を改善し、再試行の案内を見直しました。写真はデバイス内で処理され、元の写真は変更されません。

ko: MemoMark+ 평생 잠금 해제 옵션을 추가했습니다. 일부 Live Photo 저장 실패 문제를 개선하고 재시도 안내를 다듬었습니다. 사진은 기기에서 처리되며 원본은 변경되지 않습니다.

## Acceptance before submission

- Original failing task and original batch retried on paired iPhone; inspect saved pair playback/keyframe and diagnostic fallback provenance.
- Lifetime card visible for a non-lifetime holder, localized free price/paid price and missing SKU behavior; Apple purchase/restore transaction evidence.
- Signed Release build and final version readback. Scoped Git diff/staging and remote check only upon sync authorization.
- Fresh campaign dates based on actual public availability: lifetime free for two further days, then mainland CNY 68. Read back regional prices and remove remaining annual introduction if still active. Annual introduction currently naturally ends Oct 7.
- Screenshot draft acceptance is independent of repair release. Avoid delaying urgent reliability fix for unfinished family imagery or marketing experiments.

Signed physical-target Release build also passed (xcodebuild exit 0); package remains 2.3.5 (122), signature verification passed. Release artifact /tmp/MemoMarkIncidentReleaseDerived/Build/Products/Release-iphoneos/MemoMarkiOS.app. No upload/submission.
