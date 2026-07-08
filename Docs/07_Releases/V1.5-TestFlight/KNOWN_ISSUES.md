# MemoMark 1.5 Known Issues And Current Limitations

Last updated: 2026-07-08

This document describes expected limitations for the MemoMark `1.5`
TestFlight MVP.

## Current Scope

MemoMark 1.5 focuses on the core local-first workflow:

```text
Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos
```

The goal of this build is to validate share intake, local processing,
configuration clarity, rendering quality, and save-back behavior.

## Supported Inputs And Output

Supported inputs:

- static photos intentionally shared from Apple Photos
- single-photo share flows
- small multi-photo share flows
- photos with or without location metadata

Current output:

- a new generated still image saved back to Apple Photos
- the original photo remains unchanged
- generation is local to the device

## Known Limitations

- Static photos are the preferred input for this build.
- Very large images may take longer to process.
- Panoramas, long screenshots, and unusual aspect ratios may be skipped or may
  not produce ideal output.
- Videos and Live Photo motion playback are outside the current TestFlight
  scope.
- Account sync, cloud processing, advanced batch management, and full custom
  layout editing are outside the current TestFlight scope.
- Some advanced customization options are intentionally unavailable.
- More Presets and presentation styles are planned but not part of this MVP.
- The iOS share sheet controls the outer Share Extension presentation, so
  MemoMark cannot fully control that host container.
- Location display depends on metadata available in the selected photo.
- Photos without capture metadata may use fallback presentation values.

## What Testers Should Still Report

Please report these even if they happen inside the current MVP scope:

- crashes
- freezes
- failed share intake
- failed processing
- failed save-back to Apple Photos
- incorrect Memory Subject or Time Anchor output
- generated images with obvious layout breakage
- confusing permission prompts
- unclear first-run or guide copy

## Useful Report Details

Please include:

- iPhone model
- iOS version
- whether the issue happened in Apple Photos Share or inside MemoMark
- number of photos shared
- whether the photo had location metadata
- screenshot or screen recording if possible
