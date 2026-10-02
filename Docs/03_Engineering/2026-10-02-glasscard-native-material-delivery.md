# GlassCard native material delivery — 2026-10-02

## Scope and decision

Product Loop, P1. Product owner authorizes native-first implementation, selective integration into main and paired iPhone verification. Earlier custom material/container experiments remain research evidence and are not production dependencies. No durable schema, Memory semantics, original assets or Configuration Center architecture changes.

Use Apple SwiftUI regular Liquid Glass in a dark material environment on iOS/macOS26+. Layout resolves panel, corner and media frames; Renderer describes optional source-dependent material plus foreground pixels; media composition reuses existing metadata, export, pairing, audio and Photos services. Preview resolves at output pixel size before scaling. Older systems keep the existing dark alpha surface. Release authoring remains closed; existing GlassCard configurations remain processable. Minimal retains one primaryOutput and independent rendering.

Native ImageRenderer exports are supported by observed device pixels. AVFoundation's convenience CI-filter composition cannot accept canonical render-size/instruction mutation according to the SDK contract, so a small AVVideoCompositing adapter samples each source frame and only hops to MainActor for native raster work. No custom shader, container parser or alternative encoder.

## Reliability findings

An outside-material synthetic red regression exposed a color responsibility violation: claiming canConformColorOfSourceFrames while disabling CI color conversion. Fixed by delegating source SDR conformance to AVFoundation, reading source attachments through managed CI and rendering BT709 output. The same strict comparison against the existing video export passes without relaxing its tolerance. Native material updates with motion, foreground remains above it, and asymmetric rotated input agrees with the existing path. Cancellation owns each frame completion once. Legacy synchronous still consumers reject material they cannot process rather than dropping it.

JPEG Unicode EXIF UserComment research exposed a separate writer defect. The bounded fix checks Unicode scalars, reserves UTF16 capacity and requires the patch to succeed. Keep that fix separate from material behavior in Git history.

## Evidence and limits

Mac tests use MemoMarkTests, not an iOS Simulator. Synthetic and source geometry/pixel tests cover material scaling and validation, output source preservation outside the material, changing backgrounds, preview output-plan parity, actual static export, rotated motion, metadata/pairing and writer regression. Final regression:44 tests,52 parameterized executions,zero failures/runtime warnings (/tmp/MemoMarkNativeDeliveryRegression.xcresult). Signed iOS final build also passed (/tmp/MemoMarkNativeFinalSigned.log). Result bundles are retained under /tmp.

Signed iPhone 17 Pro Max build, overwrite-install and launch passed, preserving app data. Two owner-provided HEIC+MOV pairs were composed by LivePhotoPairCompositionService on the physical phone, then saved by PhotoKitLivePhotoAssetWriter and read back as Live Photos. Source copies match original SHA256; originals remain read-only. Private photographs and outputs are not committed/uploaded.

| Pair | Still canvas | Encoded motion | Audio tracks | Pair+save Debug elapsed |
| --- | --- | --- | --- | --- |
| IMG_7027 | 4284x5712 | 2880x3840 | 1 | 2.361s |
| IMG_7033 | 4032x3024 | 3840x2880 | 1 | 2.213s |

New still/video identities are nonempty and match. Motion dimensions reflect the existing export preset/encoder limit; do not claim identical still/video pixel sizes or original video pixel preservation. The earlier1080-short-edge run took0.576s/0.524s and also passed pair identity/orientation checks. Timing is observation for these two Debug samples, not a broad performance certification.

Evidence: /Users/rui/Documents/Codex/2026-10-02/GlassCardNativeRealPairs1080 and GlassCardNativeRealPairsFull. Photos verification is programmatic creation/readback, not manual playback/long-press acceptance. HDR/P3 preservation, accessibility and whole-product certification remain separate. Output adapter is SDR. No release submission or remote push is implied.

## Review

Correctness: pixel/source parity, foreground, geometry, pairing and actual Photos readback covered. Architecture: Layout has no dependency on the media artifact; Renderer adapts immutable geometry. Privacy: only local files and paired phone; private inputs excluded. Maintainability: shared policy/foreground/native raster, unchanged existing save/export services. Performance: full-canvas native raster is a known bounded cost; two full-size real samples completed successfully; peak memory and broader clips are not certified. No material/color blocker remains for this bounded integration; manual Photos playback and broader certification are explicitly pending.

Final closure: production integration committed on main at4392f3e1, Unicode fix b447f11a, explicit DEBUG device harness2855fd84. Release macOS build passed with signing disabled (/tmp/MemoMarkGlassCardRelease.log). Final signed Debug iOS build, signature verification, overwrite-install and normal app launch passed; no preset/app data reset. These local commits have not been pushed remotely.
