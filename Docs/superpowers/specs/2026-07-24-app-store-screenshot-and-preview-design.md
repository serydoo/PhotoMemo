# MemoMark App Store Screenshot And App Preview Design

**Date:** 2026-07-24
**Stage:** V3 Production Quality And Delivery
**Status:** Draft implementation complete; submission-ready recapture pending
**Primary storefront:** Simplified Chinese, iPhone 6.9-inch portrait

## Objective

Create one coherent App Store launch package that presents MemoMark as a
local-first child-growth Memory Presentation Engine rather than a photo editor
or watermark utility.

The package contains:

- seven portrait App Store screenshots;
- one 26-second portrait App Preview;
- one strong App Preview poster frame;
- a submission-readiness checklist and a precise recapture list.

The launch story is:

```text
Processed Memory Card
-> Child Growth Timeline
-> Configure Once
-> Portrait And Landscape Results
-> Preserve The Original
-> Local-First Privacy
-> Apple Photos Lifecycle
```

## Product Positioning

The first release-facing narrative is child growth.

The visual story may use an authorized child photograph, but the product copy
must continue to describe MemoMark's own capability:

```text
照片留下这一刻
时光记留下他长大的位置
```

The material must not present MemoMark as:

- a watermark utility;
- a general photo editor;
- a cloud photo product;
- an image importer;
- a photo-management replacement for Apple Photos.

The daily workflow remains:

```text
Apple Photos
-> Share
-> MemoMark
-> Processing
-> Notification
-> Apple Photos
```

## Approved Visual Direction

The approved direction combines emotional results with real product evidence.

- The first impression is a real processed child-growth Memory Card.
- Product UI appears only after the user understands the result's value.
- Backgrounds use warm white, restrained warm beige, soft Apple-native blue,
  and very light gray.
- Typography uses the Apple system font stack and restrained bold hierarchy.
- Marketing copy remains outside the captured App UI.
- Device frames are not used in the initial set.
- The screenshots use status-bar-free compositions, so the active microphone
  indicator and Dynamic Island in the source captures are not published.
- UI and result images are always scaled proportionally. They are never
  stretched, compressed, or forced into a fixed-height crop.

## Source And Privacy Boundary

The provided originals are read-only source material.

- Never modify the original files.
- Never upload the originals to an online screenshot generator.
- Never commit the child photographs, private screenshots, or generated launch
  images containing them to this repository.
- Build only from local working copies.
- Remove GPS, EXIF, device identifiers, and other embedded metadata from every
  submission-ready exported image and video.
- Do not infer or add a child's legal name, birthday, location, relationship,
  or other identity information.
- Use only content the user has explicitly authorized for public release.

The current authorized result images may be used for the first local visual
draft. Submission-ready UI and result captures must use a fictional demo
profile. The authorized child photographs may remain, but visible names, dates,
locations, album names, contact details, and anchor values must be fictional or
generalized. The App must render the replacement data; post-production must not
fabricate a UI state or result the App did not produce.

## Static Screenshot Contract

### Output

- Canvas: `1320 x 2868` pixels.
- Orientation: portrait.
- Format: PNG or maximum-quality JPEG accepted by App Store Connect.
- Alpha: none.
- Color: sRGB final delivery.
- Count: seven.
- Language: Simplified Chinese.

### Screenshot 1: Final Memory Card

**Headline**

```text
照片留下这一刻
时光记留下他长大的位置
```

**Supporting line**

```text
真实拍摄时间 · 真实成长结果
```

**Content**

- Use the authorized portrait processed result.
- Display the complete result image at its original aspect ratio.
- Treat the photograph and bottom white Memory Card as one inseparable asset.
- Reserve a compact title area above it.
- Keep the entire camera, capture-time, mark, and growth-result region visible.
- Do not crop or compress the bottom Memory Card.

### Screenshot 2: Growth Timeline

**Headline**

```text
为孩子建立
专属成长时间线
```

**Supporting line**

```text
生日、百天与重要日子，都能成为时间锚点
```

**Content**

- Use a clean recapture of the Memory Subject and Time Anchor screen.
- Use complete demo profile fields instead of visibly unfinished fields.
- Keep birthday, hundred-day, and important-day anchors visible.
- Remove the active microphone state before recapture.

### Screenshot 3: Configure Once

**Headline**

```text
配置一次
让照片自然表达
```

**Supporting line**

```text
真实 Memory Card 同步预览
```

**Content**

- Use a clean Configuration Center recapture.
- Show the real Memory Card preview and the three configuration regions.
- Use a MemoMark-owned or neutral mark instead of highlighting the Apple logo
  as a selectable decoration.
- Remove the active microphone state before recapture.

### Screenshot 4: Portrait And Landscape Results

**Headline**

```text
横图竖图
都有完整的成长位置
```

**Supporting line**

```text
同一套记忆规则，适应不同照片方向
```

**Content**

- Use both authorized processed results.
- Place the complete portrait result above.
- Place the complete landscape result below.
- Keep a clear gap between them; they must not overlap.
- Preserve each image's original aspect ratio.
- Show both bottom Memory Card borders completely.
- Do not use decorative review outlines in the final export.

### Screenshot 5: Preserve The Original

**Headline**

```text
生成新图片
原图保持不变
```

**Supporting line**

```text
保留拍摄事实，保存新的记忆版本
```

**Content**

- Use a clean recapture of Output and retention settings.
- Replace the current album name with a neutral MemoMark/时光记 demo album.
- Emphasize non-destructive output and metadata retention.
- Do not make broad RAW/DNG or Live Photo preservation claims beyond the
  release's verified evidence.

### Screenshot 6: Local-First Privacy

**Headline**

```text
所有计算
都在本地完成
```

**Supporting line**

```text
照片不上传，记忆留在设备里
```

**Content**

- Recapture Settings with `隐私与数据` expanded.
- Show only verified local-first, no-upload, and original-preservation facts.
- Do not publish development-state compatibility copy.

### Screenshot 7: Apple Photos Lifecycle

**Headline**

```text
从 Apple Photos 开始
也回到 Apple Photos
```

**Supporting line**

```text
分享、处理、通知、保存
```

**Content**

- Build from real lifecycle evidence rather than the current empty task view.
- Show the Share Extension entry, a consistent processing/completed state, and
  the generated result in Apple Photos.
- Do not show a `0` active-task summary beside a visible processing task.

## App Preview Contract

### Technical Delivery

- Duration: 26 seconds.
- Canvas: `886 x 1920` portrait.
- Codec: H.264.
- Container: `.mp4` or `.mov`.
- Frame rate: no more than 30 fps.
- Target video bitrate: 10–12 Mbps.
- Maximum file size: 500 MB.
- Audio: optional restrained music or sound design; no required narration.
- Poster frame: manually select a strong final-result frame near the opening,
  rather than relying on an arbitrary default frame.

### Content Rules

- The final App Preview must use genuine App screen recordings.
- Static screenshots may guide the storyboard but must not masquerade as live
  App interaction.
- No hand-held device footage.
- No fictional transitions that imply unavailable behavior.
- Minimal blue tap indicators are allowed when they clarify interaction.
- Marketing overlays use at most two short lines and never hide the action.
- Record with microphone activity, other Live Activities, notifications, and
  unrelated status indicators disabled.

### Timeline

| Time | Scene | Required Evidence |
| --- | --- | --- |
| `0–3s` | Result first | Real screen recording of the complete processed Memory Card and launch headline |
| `3–6s` | Apple Photos share | Real photo selection, Share sheet, MemoMark extension |
| `6–9s` | Choose subject/configuration | Real Home selection state |
| `9–12s` | View Time Anchors | Birthday, hundred-day, and important-day anchors |
| `12–16s` | Preview responds | One real configuration change updates the real preview |
| `16–20s` | Process to completion | Consistent progress and terminal completed state |
| `20–23s` | Save back | Notification or completed result in Apple Photos |
| `23–26s` | Result close | Complete portrait and landscape results, `本地完成 · 原图不变` |

## Mandatory Recapture List

The current sources are sufficient for the first static visual draft. A final
submission-ready package requires these clean captures:

1. Home with no microphone/Live Activity indicator and a non-zero or otherwise
   complete demo state.
2. Memory Subject with complete demo fields and visible Time Anchors.
3. Configuration Center with a neutral/MemoMark-owned mark.
4. Output settings with a neutral demo album name.
5. Settings with `隐私与数据` expanded.
6. Apple Photos Share sheet and MemoMark Share Extension entry.
7. A real processing task moving to a consistent completed state.
8. Notification or saved result visible back in Apple Photos.
9. Continuous screen recordings covering the App Preview timeline.
10. Clean portrait and landscape results generated by the release build with
    fictional demo data, corrected typography, and complete Memory Card bottoms.

## Validation

### Static Images

- Confirm every export is exactly `1320 x 2868`.
- Confirm no export contains an alpha channel.
- Confirm sRGB output.
- Confirm all text remains readable at App Store product-page scale.
- Confirm Screenshots 1 and 4 show complete Memory Card bottoms.
- Confirm no image is stretched, compressed, or accidentally cropped.
- Confirm GPS and EXIF metadata are absent from delivery files.
- Confirm status bars, microphone indicators, private contact details, and
  development-state copy are absent.

### App Preview

- Confirm duration is between 15 and 30 seconds.
- Confirm `886 x 1920`, H.264, and no more than 30 fps.
- Confirm bitrate and file size meet App Store Connect limits.
- Confirm every functional claim appears in the submitted App build.
- Confirm the poster frame communicates the final Memory Card value.
- Watch the full encoded export on a phone-size display before submission.

## Deliverables And Storage

Private launch assets must be produced outside the Git repository, under a
dedicated local delivery directory such as:

```text
/Users/rui/Desktop/PhotoMemoLaunchAssets/
```

Expected structure:

```text
PhotoMemoLaunchAssets/
  Drafts/
  Screenshots/zh-Hans/6.9-inch/
  AppPreview/zh-Hans/6.9-inch/
  RecaptureGuide/
  Validation/
```

No private source photo or generated launch asset is added to Git.

## Out Of Scope

- App UI implementation changes;
- Renderer or Layout Engine behavior changes;
- English localization;
- iPad, macOS, or Android launch assets;
- paid acquisition ads or social-media campaign artwork;
- claims for unverified RAW/DNG or Live Photo behavior.

## Acceptance Criteria

The design is complete when:

1. The seven screenshots form one coherent child-growth story.
2. Screenshots 1 and 4 preserve complete Memory Card proportions and bottoms.
3. The App Preview uses real captured interaction and fits the 26-second plan.
4. All source and delivery privacy boundaries are satisfied.
5. Every marketing statement is supported by the submitted build.
6. The final deliverables pass technical inspection and manual visual review.
