# MemoMark

> Let photos keep not only the moment, but also where that moment belongs in a life.

MemoMark is a local-first memory tool designed for Apple Photos. It does not replace the system library and never edits the original photo. It reads capture time, location, device and other available photo facts, combines them with dates you define, and creates a new memory version of the photo.

Current local release candidate: **MemoMark 2.2.2 (build 99)**. The formal-release range starts at the user-selected Monday, August 24 morning push wave (about 06:54), aligned to the nearest pushed commit `c0f11a7` at 06:49:40 +0800. This candidate includes the current settings, welcome guidance, and editor-interaction maintenance pass. Xcode Cloud is expected to build automatically after the GitHub `main` push; App Store submission remains open. See the [2.2.2 (99) release notes](Docs/07_Releases/2026-08-29-2.2.2-release-notes.md).

The everyday flow is intentionally small:

```text
Apple Photos -> Share -> MemoMark -> Local Processing -> New Memory Photo -> Apple Photos
```

MemoMark turns capture time into a human relationship with time: a child’s age, the day of a trip, a relationship milestone, or the distance to an important future date. These relationships are called **Time Anchors**. MemoMark calculates reusable results; you remain in control of the final wording and the four-region memory-card layout.

The app can use capture date and time, weekday, location, camera and shooting parameters to provide context. It continues to adapt to PhotoKit, Live Photo resources, EXIF handling and Apple Photos saving boundaries. Core processing is local, the original remains unchanged, and the output is a newly generated photo.

MemoMark is not a watermark clone, photo manager, cloud photo product or template marketplace. Apple Photos remains the home for the library, timeline, search, albums and sharing. MemoMark focuses on one question: **where did this photo belong in your life?**

Internally, the project keeps photo facts, memory calculation, expression, layout, rendering and export in separate responsibilities:

```text
Photo -> Metadata -> Memory Engine -> Expression -> Layout -> Renderer -> Export
```

MemoMark is an independent Apple-native project built with Swift, SwiftUI and PhotoKit. It is currently in the V4 Expression Style System research and refinement stage. Reliability, Live Photo/media handling, accessibility, localization and device validation remain ongoing work; research notes should not be read as production-certification claims.

See the [Chinese README](README.md) for the full product story and the repository documentation under `Docs/` for engineering history.

Release preparation follows the [MemoMark Release Sync Standard](Docs/07_Releases/RELEASE_SYNC_STANDARD.md), keeping source synchronization, TestFlight delivery, App Store submission, and public release as separately authorized states.
