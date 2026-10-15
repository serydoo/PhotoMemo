# SDR research composition isolation

Engineering Loop; P2 research-only. Evidence: source preparation and pixel processing already run outside MainActor, but final full-canvas composition still runs inside the UI adapter.

Scope: immutable Sendable layer snapshot, shared nonisolated compositor, concurrent worker, async adapter cancellation gate. Geometry remains supplied by Layout; ImageRenderer and PresentationArtifact extraction remain on MainActor. No production artifact, writer, default material, or media contract changes. Native CoreGraphics is reused.

Verification: focused macOS async/synchronous pixel parity, worker off-main execution, cancellation controls, and existing shared adapter regression. This does not establish latency, mid-operation cancellation, Photos/device acceptance, or production writer isolation. Metadata freezing and writer isolation remain a separate follow-up.

## Verified outcome

macOS MemoMarkTests build and two focused tests (`asyncStages`, `sharedAdapter`) passed in `/tmp/MemoMarkGlassCompositionIsolation.xcresult`. Worker composition ran outside the main thread; sync/async final RGBA pixels matched exactly. A pre-cancelled composition task threw CancellationError. Existing shared-adapter controls passed. Temporary test copies were byte-checked against retained research sources and removed. No production source changes in this slice. Mid-composition cancellation latency and UI responsiveness are not measured.
