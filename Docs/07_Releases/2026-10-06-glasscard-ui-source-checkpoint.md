# GlassCard and configuration UI source checkpoint — 2026-10-06

Owner explicitly authorized GitHub sync in this chat. This is a source checkpoint based on 53b7edd3, keeping 2.3.5 (122), not a new release candidate. No version, Store copy, TestFlight upload or App Store submission is included.

Scope: content-measured GlassCard trailing layout; native material opacity and sRGB motion rendering parity; native-backdrop SDR capability admission with explicit HDR/P3 rejection; immutable foreground preparation; DEBUG device measurements; active-only preview and native bottom accessory; regression and physical UI tests; scoped engineering evidence.

Evidence: full MemoMarkTests 1981 passed / 0 failed / 1 pre-existing disabled test, 2024 parameter executions, 2 existing QoS warnings. Signed iOS restored build passed (/tmp/MemoMarkUIRestoredBuild-20261006.log). Physical configuration editor round trip and preview/accessory lifecycle tests passed in separate result bundles. Settings welcome navigation test remains FAILED, not certified; registration trial was reverted. Owner confirmed two SDR-fixture Photos Live Photos visually normal and stable. Six repeat exports succeeded; end-cycle footprint about 200 MiB, cumulative peak 718 MiB. Motion output dimensions downscale. SDR fixture evidence is not original P3/HDR preservation or automatic production fallback.

Open: welcome entry manual confirmation and navigation diagnosis, keyboard/large-font/VoiceOver/Reduce Motion/orientation/iPad acceptance, source HDR/P3 support, encoded resolution policy, peak memory, QoS warnings and disabled ImageIO fixture. This checkpoint does not close release evidence.

Excluded: prior Store/release drafts, Outreach, unfrozen Research and private media, config, screenshot/video attachments, device manifests and identifiers, Xcode artifacts. CURRENT_STATUS includes only this checkpoint event in the commit; earlier unrelated local edits remain local.

No localization keys or dependencies changed; no release materials or product availability claims updated. Staging uses an explicit scoped list. Live remote main matched HEAD before preparing this checkpoint.
