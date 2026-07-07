# App Review Notes

Thank you for reviewing MemoMark.

MemoMark is a local-first memory presentation app for Apple Photos. It helps
users generate clean memory-card images from photos they choose, while
preserving the original photo.

No account, login, subscription, or demo credentials are required.

## How To Test

1. Open Apple Photos.
2. Select a static photo.
3. Use the iOS share sheet and choose MemoMark.
4. Allow Photo Library access if prompted.
5. Confirm that MemoMark receives the shared photo and starts processing.
6. Open MemoMark if needed to review processing state and configuration.
7. Confirm that MemoMark saves a generated memory-card image back to the
   user's photo library.

## Privacy And Data Handling

MemoMark does not upload photos to a server. Normal operation does not require
server communication. Photo processing is performed locally on the device.

Original photos are not modified. MemoMark creates a new generated image as
output.

Photo Library permission is requested only so users can share selected photos
into MemoMark and save generated images back to Apple Photos.

The current build declares no tracking and no collected data types in its
privacy manifests.

## Current TestFlight Scope

This TestFlight build is an MVP focused on validating the core Apple Photos
share workflow, local processing, memory-card generation, and save-back
behavior. Advanced customization and additional presentation styles are still
under development.

Thank you for your review.
