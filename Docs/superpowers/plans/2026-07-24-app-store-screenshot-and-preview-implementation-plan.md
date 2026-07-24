# MemoMark App Store Screenshot And App Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a locally generated seven-image Simplified Chinese iPhone 6.9-inch App Store screenshot draft, a clearly labeled non-submittable 26-second App Preview motion prototype, and a precise recapture package for final submission assets.

**Architecture:** Keep all private source and generated media outside Git under `/Users/rui/Desktop/PhotoMemoLaunchAssets`. A deterministic Node generator uses Playwright for exact typography/layout rendering and Sharp for metadata removal, sRGB conversion, alpha removal, and dimension enforcement. A Swift AVFoundation renderer turns approved storyboard frames into a pacing prototype; final App Preview replacement remains blocked on genuine App screen recordings.

**Tech Stack:** Node.js 26, Playwright 1.61.1, Sharp 0.34.5, Swift 6.4, AVFoundation, CoreGraphics, ImageIO, Node built-in test runner.

---

## File Map

All private and generated files live outside the repository:

```text
/Users/rui/Desktop/PhotoMemoLaunchAssets/
  Generator/
    package.json
    asset-manifest.json
    generate-static-assets.mjs
    render-app-preview.swift
    inspect-app-preview.swift
    validate-assets.mjs
    tests/asset-contract.test.mjs
  WorkingSources/
  Drafts/Screenshots/zh-Hans/6.9-inch/
  Drafts/AppPreview/zh-Hans/6.9-inch/
  RecaptureGuide/
  Validation/
```

Repository documentation only:

```text
Docs/superpowers/specs/2026-07-24-app-store-screenshot-and-preview-design.md
Docs/superpowers/plans/2026-07-24-app-store-screenshot-and-preview-implementation-plan.md
HANDOFF.md
```

Private media must never be staged or committed.

### Task 1: Establish Private Working Package

**Files:**
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/package.json`
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/asset-manifest.json`
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/WorkingSources/`
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Validation/source-sha256.txt`

- [ ] **Step 1: Create the private directory structure**

Run:

```bash
mkdir -p \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/tests \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/WorkingSources \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/Drafts/Screenshots/zh-Hans/6.9-inch \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/Drafts/AppPreview/zh-Hans/6.9-inch \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/RecaptureGuide \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/Validation
```

Expected: all seven directories exist outside `/Users/rui/Desktop/PhotoMemo`.

- [ ] **Step 2: Record source hashes before any processing**

Run:

```bash
shasum -a 256 \
  /Users/rui/Downloads/IMG_1645.jpeg \
  /Users/rui/Downloads/IMG_1646.jpeg \
  /Users/rui/Downloads/IMG_1647.jpeg \
  /Users/rui/Downloads/IMG_1648.jpeg \
  /Users/rui/Downloads/IMG_1649.jpeg \
  /Users/rui/Downloads/IMG_1650.jpeg \
  /Users/rui/Downloads/IMG_1652.jpeg \
  /Users/rui/Downloads/IMG_1653.jpeg \
  /Users/rui/Downloads/IMG_1654.jpeg \
  /Users/rui/Downloads/IMG_1655.jpeg \
  /Users/rui/Downloads/IMG_5372.JPEG \
  /Users/rui/Downloads/IMG_6278.JPEG \
  > /Users/rui/Desktop/PhotoMemoLaunchAssets/Validation/source-sha256.txt
```

Expected: 12 hash lines.

- [ ] **Step 3: Create the dependency manifest**

Write `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/package.json`:

```json
{
  "name": "photomemo-app-store-assets",
  "private": true,
  "type": "module",
  "scripts": {
    "generate": "node generate-static-assets.mjs",
    "validate": "node validate-assets.mjs",
    "test": "node --test tests/asset-contract.test.mjs"
  }
}
```

The scripts use the bundled workspace modules through `NODE_PATH`; do not install or download packages.

- [ ] **Step 4: Create the source and output manifest**

Write `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/asset-manifest.json` with:

```json
{
  "staticCanvas": { "width": 1320, "height": 2868 },
  "previewCanvas": { "width": 886, "height": 1920 },
  "sources": {
    "portraitResult": "/Users/rui/Downloads/IMG_6278.JPEG",
    "landscapeResult": "/Users/rui/Downloads/IMG_5372.JPEG",
    "subject": "/Users/rui/Downloads/IMG_1655.jpeg",
    "configuration": "/Users/rui/Downloads/IMG_1652.jpeg",
    "output": "/Users/rui/Downloads/IMG_1653.jpeg",
    "privacyDraft": "/Users/rui/Downloads/IMG_1650.jpeg",
    "workflowDraft": "/Users/rui/Downloads/IMG_1654.jpeg"
  },
  "screenshots": [
    "01-growth-position-draft.png",
    "02-growth-timeline-draft.png",
    "03-configure-once-draft.png",
    "04-portrait-landscape-draft.png",
    "05-preserve-original-draft.png",
    "06-local-first-draft.png",
    "07-photos-lifecycle-draft.png"
  ]
}
```

- [ ] **Step 5: Recheck source hashes**

Run the Step 2 command into `/tmp/photomemo-source-sha256-after.txt`, then:

```bash
diff -u \
  /Users/rui/Desktop/PhotoMemoLaunchAssets/Validation/source-sha256.txt \
  /tmp/photomemo-source-sha256-after.txt
```

Expected: no output.

### Task 2: Define Automated Asset Contracts

**Files:**
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/tests/asset-contract.test.mjs`
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/validate-assets.mjs`

- [ ] **Step 1: Write the failing contract test**

The test must use Sharp to assert:

```js
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import sharp from "sharp";

const root = "/Users/rui/Desktop/PhotoMemoLaunchAssets";
const manifest = JSON.parse(
  await readFile(path.join(root, "Generator/asset-manifest.json"), "utf8")
);

for (const fileName of manifest.screenshots) {
  test(`${fileName} is App Store ready`, async () => {
    const output = path.join(root, "Drafts/Screenshots/zh-Hans/6.9-inch", fileName);
    const metadata = await sharp(output).metadata();
    assert.equal(metadata.width, 1320);
    assert.equal(metadata.height, 2868);
    assert.equal(metadata.hasAlpha, false);
    assert.equal(metadata.space, "srgb");
    assert.equal(metadata.exif, undefined);
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
cd /Users/rui/Desktop/PhotoMemoLaunchAssets/Generator
NODE_PATH=/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  /Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  --test tests/asset-contract.test.mjs
```

Expected: seven failures because outputs do not exist.

- [ ] **Step 3: Implement the reusable validator**

`validate-assets.mjs` must:

1. read `asset-manifest.json`;
2. validate exactly seven static outputs;
3. validate `1320 x 2868`, sRGB, no alpha, and no EXIF;
4. compute SHA-256 for every output;
5. write `Validation/static-assets.json`;
6. exit non-zero on any mismatch.

The report shape is:

```json
{
  "status": "pass",
  "expectedResolution": "1320x2868",
  "count": 7,
  "files": [
    {
      "file": "01-growth-position-draft.png",
      "width": 1320,
      "height": 2868,
      "hasAlpha": false,
      "space": "srgb",
      "sha256": "8f3f47c6b5c9c03b6f25363c4a7b9ebdc614afc30ce82de7f6fbe4c91cb17d31"
    }
  ]
}
```

### Task 3: Generate Seven Static Drafts

**Files:**
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/generate-static-assets.mjs`
- Generate: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Drafts/Screenshots/zh-Hans/6.9-inch/*.png`

- [ ] **Step 1: Implement the exact-canvas renderer**

`generate-static-assets.mjs` must:

- launch bundled Chromium through Playwright;
- create metadata-free sRGB working copies under `WorkingSources/` through
  Sharp before any image enters Chromium;
- create a `1320 x 2868` viewport with device scale factor `1`;
- embed source images as local data URLs;
- render each screenshot from a full opaque HTML document;
- use `-apple-system`, `PingFang SC`, and sans-serif fallbacks;
- save a temporary Chromium PNG;
- pass it through Sharp with `.flatten()`, `.removeAlpha()`,
  `.toColourspace("srgb")`, and `.png()`;
- assert final width and height before keeping the file.

The output helper contract is:

```js
async function renderScreenshot({ fileName, headline, supportingLine, bodyHtml }) {
  // Produces one opaque 1320 x 2868 sRGB PNG with no metadata.
}
```

- [ ] **Step 2: Implement Screenshot 1 without result cropping**

Use the approved composition:

```text
headline area: compact top region
portrait result: centered, width 84%, height auto
bottom: complete Memory Card remains visible
```

Exact headline:

```text
照片留下这一刻
时光记留下他长大的位置
```

- [ ] **Step 3: Implement Screenshots 2 and 3 with status-bar-free UI crops**

- Crop the UI presentation container, not the source file.
- Translate each screenshot upward inside an overflow-hidden rounded container
  until the active microphone/Dynamic Island area is completely outside the
  visible region.
- Keep all marketing text outside the App UI.
- Add a small `视觉草稿 · 需干净重截` review label outside the UI so these files
  cannot be mistaken for submission-ready assets.

- [ ] **Step 4: Implement Screenshot 4 as two non-overlapping complete results**

Use the approved invariant:

```text
portrait result: top, centered, width 52%, height auto
landscape result: below, centered, width 86%, height auto
gap: positive and visible
overlap: none
```

Both complete white Memory Card bottoms must remain visible.

- [ ] **Step 5: Implement Screenshots 5–7 as labeled visual drafts**

- Screenshot 5 uses the current Output view only to validate composition.
- Screenshot 6 uses the current Settings view but carries a visible draft label
  because `隐私与数据` is not expanded.
- Screenshot 7 uses the current Task view but carries a visible draft label
  because its statistics and active task are inconsistent.
- No draft label may overlap App UI or marketing claims.

- [ ] **Step 6: Generate the screenshots**

Run:

```bash
cd /Users/rui/Desktop/PhotoMemoLaunchAssets/Generator
NODE_PATH=/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  /Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  generate-static-assets.mjs
```

Expected: seven PNG files in the 6.9-inch draft directory.

- [ ] **Step 7: Run automated validation**

Run:

```bash
NODE_PATH=/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  /Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  --test tests/asset-contract.test.mjs
NODE_PATH=/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules \
  /Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  validate-assets.mjs
```

Expected: seven passing tests and `Validation/static-assets.json` with status `pass`.

### Task 4: Produce A Non-Submittable App Preview Motion Prototype

**Files:**
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/render-app-preview.swift`
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Generator/inspect-app-preview.swift`
- Generate: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Drafts/AppPreview/zh-Hans/6.9-inch/MemoMark-AppPreview-DRAFT-NOT-FOR-UPLOAD.mp4`

- [ ] **Step 1: Render eight storyboard frames at preview resolution**

Extend `generate-static-assets.mjs` to render eight `886 x 1920` opaque scene
PNGs matching the approved timeline. Every scene must contain a visible
`动效分镜草稿 · 最终版需真实录屏` label.

- [ ] **Step 2: Implement the AVFoundation writer**

`render-app-preview.swift` must:

- create an H.264 `AVAssetWriter` at `886 x 1920`;
- use 30 fps and a 10,000,000 bps target bitrate;
- read the eight scene PNGs through ImageIO;
- create `CVPixelBuffer` frames in sRGB;
- hold scenes according to `3,3,3,3,4,4,3,3` seconds;
- use 0.25-second crossfades while preserving a 26-second total duration;
- write no audio track;
- fail if any source frame is not exactly `886 x 1920`.

- [ ] **Step 3: Compile and render the prototype**

Run:

```bash
cd /Users/rui/Desktop/PhotoMemoLaunchAssets/Generator
xcrun swiftc render-app-preview.swift \
  -framework AVFoundation \
  -framework CoreGraphics \
  -framework CoreVideo \
  -framework ImageIO \
  -o /tmp/photomemo-render-app-preview
/tmp/photomemo-render-app-preview
```

Expected: one clearly labeled draft MP4. This file is for pacing review only and
must not be uploaded to App Store Connect.

- [ ] **Step 4: Implement and run the video inspector**

`inspect-app-preview.swift` must load the generated file with `AVURLAsset`,
load the first video track's natural size and nominal frame rate, read the
format-description media subtype, and write
`Validation/app-preview-draft.json`. It must exit non-zero unless all of these
conditions hold:

```text
resolution: 886 x 1920
duration: 26.0 seconds, tolerance ±0.1 seconds
frame rate: 30 fps maximum
codec: H.264
```

Write results to `Validation/app-preview-draft.json` and keep
`status: "draft-not-for-upload"`.

Run:

```bash
cd /Users/rui/Desktop/PhotoMemoLaunchAssets/Generator
xcrun swift inspect-app-preview.swift
```

Expected: `Validation/app-preview-draft.json` records `886x1920`, 26 seconds
within ±0.1 seconds, H.264, no more than 30 fps, and
`draft-not-for-upload`.

### Task 5: Create The Recapture And Replacement Guide

**Files:**
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/RecaptureGuide/README.md`
- Create: `/Users/rui/Desktop/PhotoMemoLaunchAssets/RecaptureGuide/shot-list.md`

- [ ] **Step 1: Write the device preparation checklist**

Include these exact requirements:

```text
- Disable microphone activity, Voice Control, recording, timers, navigation, and unrelated Live Activities.
- Use a fictional demo subject and fictional dates.
- Use a neutral/MemoMark-owned mark in Configuration Center.
- Use a neutral 时光记 demo album.
- Do not show contact channels, private notifications, or external app return labels.
- Record portrait at native iPhone resolution with no post-recording crop.
```

- [ ] **Step 2: Write the nine-shot replacement list**

The list covers Home, Memory Subject, Configuration Center, Output, Privacy,
Apple Photos Share sheet, real Processing-to-Completed state, saved result in
Apple Photos, and continuous App Preview interaction footage.

- [ ] **Step 3: Document replacement mechanics**

Explain that final generation requires only source-path replacement in
`asset-manifest.json` followed by these exact commands; no layout redesign is
required:

```bash
cd /Users/rui/Desktop/PhotoMemoLaunchAssets/Generator
export NODE_PATH=/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules
/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node generate-static-assets.mjs
/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node --test tests/asset-contract.test.mjs
/Users/rui/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node validate-assets.mjs
```

### Task 6: Final Review And Repository Handoff

**Files:**
- Modify: `HANDOFF.md`
- Generate: `/Users/rui/Desktop/PhotoMemoLaunchAssets/Validation/manual-review.md`

- [ ] **Step 1: Create a local contact sheet**

Use Sharp to generate a review-only contact sheet containing all seven static
drafts at readable scale. Store it under `Validation/`; do not commit it.

- [ ] **Step 2: Perform manual visual review**

Record pass/fail for:

```text
- Screenshot 1 complete bottom Memory Card
- Screenshot 4 portrait result above landscape result
- Screenshot 4 no overlap
- Screenshot 4 both bottom Memory Cards complete
- all Chinese headlines readable
- no visible active microphone status
- draft-only files clearly labeled
- no stretched or compressed source image
```

- [ ] **Step 3: Recheck private source immutability**

Repeat Task 1 Step 2 and diff against `Validation/source-sha256.txt`.

Expected: no differences.

- [ ] **Step 4: Update repository handoff**

Append a concise entry to `HANDOFF.md` recording:

- approved seven-frame launch narrative;
- exact static and video target resolutions;
- private-output location;
- completed draft validation;
- the fact that final App Preview remains gated on genuine screen recordings;
- the exact recapture items still required.

- [ ] **Step 5: Confirm repository scope**

Run:

```bash
git status --short
git diff --check -- \
  Docs/superpowers/specs/2026-07-24-app-store-screenshot-and-preview-design.md \
  Docs/superpowers/plans/2026-07-24-app-store-screenshot-and-preview-implementation-plan.md \
  HANDOFF.md
```

Expected: no private media appears in Git status and documentation has no
whitespace errors. Do not stage or commit unless the user explicitly asks.

## Completion Gate

The first production pass is complete only when:

1. all seven static draft PNGs are exactly `1320 x 2868`;
2. all seven are sRGB, opaque, and contain no EXIF/GPS metadata;
3. Screenshot 1 preserves the complete portrait Memory Card;
4. Screenshot 4 shows complete portrait and landscape results without overlap;
5. the motion prototype is exactly `886 x 1920`, H.264, no more than 30 fps,
   and 26 seconds within ±0.1 seconds;
6. the prototype is visibly marked not for App Store upload;
7. the genuine-recording recapture guide is complete;
8. source-file hashes remain unchanged;
9. no private media is present in the Git working tree.
