# 2026-08-10 Subject Avatar Framing And Crop Interaction

## Decision Gate

- Primary loop: Product Loop, driven by the supplied iPhone 17 Pro Max screen
  observation and direct interaction feedback.
- Risk: P1. The work changes a primary identity-editing interaction and the
  persisted derivative avatar assets, but does not change Memory Subject
  identity ownership or Configuration Library persistence.
- Scope: the iOS Memory Subject summary avatar, the existing local avatar crop
  surface, and its PhotosPicker handoff.
- Out of scope: Contacts integration, contact identity storage, Renderer,
  Layout Engine, Export, Apple Photos originals, EXIF, commerce, and Subject
  count policy.

## Observed Behavior

1. The basic-information card uses a fixed 68-point avatar beside a centered
   text column. On the iPhone 17 Pro Max this leaves the identity image visually
   subordinate and makes the card feel horizontally unbalanced.
2. PhotosPicker returns the selected image, but MemoMark's crop surface only
   approximates the Contacts avatar editor. Its pan bounds are calculated from
   the full square canvas even though the valid crop target is the inset circle.
   This removes legitimate horizontal or vertical travel near the circle edge.
3. The selected PhotosPicker item remains retained after loading. Re-selecting
   the same library item may therefore fail to trigger a new edit transaction.
4. The avatar image itself is not the primary edit affordance; the user has to
   discover the separate text action below it.

## Accepted Behavior

- Increase the basic-information avatar to 84 points while preserving Dynamic
  Type, the existing card hierarchy, and circular presentation.
- Keep Apple's out-of-process PhotosPicker as the library-selection boundary;
  it needs no broad Photos authorization and does not upload the image.
- After selection, present one focused circular crop step with visible masking,
  drag positioning, pinch zoom, reset, cancel, and apply actions.
- Calculate pan limits against the actual circular crop diameter, so the image
  can move throughout every position that still fully covers the circle.
- Reset PhotosPicker selection after the image has been decoded so choosing the
  same photo again starts a new crop transaction.
- Make the avatar itself an explicit photo-selection/edit target and retain a
  separate readable action label for accessibility and discoverability.
- The original photo remains unchanged. Only MemoMark's local avatar derivative
  resources are regenerated after Apply.

## Verification

- RED/GREEN geometry tests for inset-circle translation limits and zoom.
- Source contract for the 84-point summary avatar and avatar edit affordance.
- Focused avatar and iPhone responsive suites, then complete PhotoMemoTests.
- Unsigned iOS build followed by signed iphoneos build, in-place install, launch,
  and manual interaction on the connected iPhone 17 Pro Max without Simulator.
