# GlassCard SDR metadata snapshot

Engineering Loop, research-only P2. Evidence: current research adapter and production writer consume [CFString: Any], which cannot be sent between actors as an immutable value. Nested Foundation mutable containers also survive a shallow dictionary copy.

Owner: research metadata boundary. Use Foundation binary property-list serialization to freeze supported ImageIO property values into Sendable Data; reject unsupported values rather than silently dropping fields. Caller must exclusively own mutable input during capture. Decode fresh properties at the consumer boundary; do not claim arbitrary ImageIO metadata compatibility until tested. No production writer, export, schema, original assets or default material changes.

Plan: verify nested EXIF/GPS/Date/Data/array/boolean preservation, mutation isolation, unsupported-object rejection, and a concurrent consumer. Metadata serialization does not certify file encoding retention or move the actual writer off MainActor.

## Writer isolation scan

Current production owner is `Services/MetadataPreservingImageWriter.swift`, not the protocol/adapters in `MediaPipelineVNext/StillImageMetadataWriting.swift`. Its class has no explicit actor annotation, but the app target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. The writer calls ImageIO, `ImageIOStillImageMetadataCleanup`, `JPEGExifUserCommentPatcher`, and FileManager date updates. The patcher is a separate helper chain; it must be evaluated together with cleanup before isolation changes. Do not create a second research writer or mark the production writer unchecked Sendable. The snapshot remains an in-memory transport; it is not a persisted schema and does not alter metadata policy.

## Verification

macOS build and 3 focused tests passed, 0 failed/skipped and no recorded runtime warnings: `/tmp/MemoMarkGlassMetadataSnapshot.xcresult`. Verified EXIF capture string, GPS latitude/longitude, Date, mutable binary payload, mixed array/boolean/integer/Unicode string, empty dictionary, nested URL rejection, and off-main concurrent decoding. After capture the original NSMutableDictionary and NSMutableData were changed; decoded snapshot retained the earlier values. This does not test mutation concurrent with initialization (unsupported caller behavior), arbitrary vendor objects, cyclic containers, encoded-file retention or memory budget. Temporary copies were byte-verified and removed.
