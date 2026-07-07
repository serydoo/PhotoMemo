# PhotoMemo TestFlight Guide

Thank you for helping test PhotoMemo.

PhotoMemo is a local-first memory presentation app for Apple Photos. It helps
people turn meaningful photos into clean memory-card images while preserving
the original photo.

This TestFlight build is PhotoMemo `1.5 (5)`, the first broad MVP test focused
on the Apple Photos share workflow.

## Before You Start

- No account is required.
- Normal operation does not require a server.
- Photo processing is performed locally on your device.
- Your photos are not uploaded by PhotoMemo.
- Original photos are not modified.
- PhotoMemo creates a new generated image as output.

## Recommended Test Flow

1. Open Apple Photos.
2. Select one or more static photos.
3. Share the selected photos to PhotoMemo.
4. Confirm that PhotoMemo receives the photos and starts processing.
5. Open PhotoMemo if needed to review the processing state and configuration.
6. Confirm that the generated image is saved back to Apple Photos.
7. Compare the generated image with the original photo.

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

Confirm whether PhotoMemo receives the photos and creates processing status
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

Expected limitations:

- Advanced customization is still limited.
- Some photo types may be rejected or skipped.
- Static photos are the preferred input.
- Very large, panoramic, or unusual-ratio images may not be ideal.
- The Share Extension may be constrained by iOS share-sheet behavior.

## Feedback

Screenshots and screen recordings are very helpful.

When reporting an issue, please include:

- Steps to reproduce
- Expected behavior
- Actual behavior
- iPhone model
- iOS version
- Whether the issue happened in Apple Photos Share or inside PhotoMemo

Thank you for being part of the first TestFlight phase.
