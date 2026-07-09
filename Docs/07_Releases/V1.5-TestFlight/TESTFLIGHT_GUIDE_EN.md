# MemoMark TestFlight Guide

Thank you for helping test MemoMark.

MemoMark is a local-first memory presentation app for Apple Photos. It helps
people turn meaningful photos into clean memory-card images while preserving
the original photo.

This TestFlight build is MemoMark `1.5`, the first broad MVP test focused
on the Apple Photos share workflow.

## Before You Start

- No account is required.
- Normal operation does not require a server.
- Photo processing is performed locally on your device.
- Your photos are not uploaded by MemoMark.
- Original photos are not modified.
- MemoMark creates a new generated image as output.

## Recommended Test Flow

1. Open Apple Photos.
2. Select one or more static photos.
3. Share the selected photos to MemoMark.
4. Confirm that MemoMark receives the photos and starts processing.
5. Open MemoMark if needed to review the processing state and configuration.
6. Confirm that the generated image is saved back to Apple Photos.
7. Compare the generated image with the original photo.

For builds created from commit `c6b97d99` or later, you can also test the Main
App Picker Live Photo release-candidate path:

1. Open MemoMark.
2. Select a normal Live Photo from the main app picker.
3. Use original-format output.
4. Confirm Photos recognizes the saved result as a Live Photo.
5. Long-press playback and check portrait/landscape geometry.

## Suggested Test Scenarios

### Apple Photos Share Flow

Please try sharing:

- Portrait photos
- Landscape photos
- Indoor photos
- Outdoor photos
- Photos with location metadata
- Photos without location metadata
- A single photo
- Multiple photos

Confirm whether MemoMark receives the photos and creates processing status
clearly.

### Configuration Center

Please check whether:

- The current Preset is understandable.
- The Memory Subject and Time Anchor setup is clear.
- Preview content matches the selected configuration.
- The app explains what will happen when photos are shared from Apple Photos.

### Rendering And Output

Please pay attention to:

- Overall layout
- Typography
- Icon and badge rendering
- Information alignment
- Text spacing
- Border rendering
- Sharpness and color consistency
- Output saved as a new image

### Stability

Please report:

- Crashes
- Freezes
- Share Extension failures
- Processing failures
- Export or save failures
- Unexpected permission behavior
- Confusing or misleading UI

## Current MVP Scope

This build intentionally focuses on the core local-first memory workflow.

Current supported scope and output format:

- Static photos shared intentionally from Apple Photos.
- Single-photo and small multi-photo share flows.
- Photos with or without location metadata.
- Output is a new still image saved back to Apple Photos.
- Builds from `c6b97d99` or later: Main App Picker Live Photo release-candidate
  output, with motion-preserving Live Photo or static image output depending on
  output settings.
- MemoMark does not modify the original photo.

Expected limitations:

- Advanced customization is still limited.
- Some photo types may be rejected or skipped.
- Static photos are the preferred input.
- Share Extension Live Photo remains a production-validation limitation.
- Very large, panoramic, or unusual-ratio images may not be ideal.
- Videos, advanced batch management, cloud processing, account sync, and full custom layout editing are outside the current TestFlight scope.
- The Share Extension may be constrained by iOS share-sheet behavior.

## Development Plan

After `1.5`, the next development phase will focus on reliability and
feedback closure:

- Apple Photos share intake edge cases
- Permission clarity and save-back behavior
- Failed-task retry polish
- Clearer Configuration Center guidance
- Render consistency and metadata-retention validation

## Feedback

Please use TestFlight's built-in feedback when possible, especially for
crashes, screenshots, and screen recordings. You can also send feedback by
email:

- `serydoo@gmail.com`
- `serydoo@163.com`

Chinese testers can also contact Xiaohongshu ID `49956456623` for group
discussion.

Public reproducible issues can also be filed on GitHub Issues:

- `https://github.com/serydoo/PhotoMemo/issues`

Screenshots and screen recordings are very helpful.

When reporting an issue, please include:

- Steps to reproduce
- Expected behavior
- Actual behavior
- iPhone model
- iOS version
- Whether the issue happened in Apple Photos Share or inside MemoMark

Thank you for being part of the first TestFlight phase.
