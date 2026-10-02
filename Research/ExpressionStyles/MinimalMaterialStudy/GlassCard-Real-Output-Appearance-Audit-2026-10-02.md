# GlassCard real-output appearance audit and bounded correction

Date: 2026-10-02. Source baseline: main 72e101ed, build 116. Product Loop, P2 geometry correction; preview material mismatch is a separate P1. User requests strict appearance review against historical research, including text starts and mark position/size. No original or private media is copied into Git.

## Decision gate

Observed scenario: the supplied 3214×5712 portrait and 4896×2754 landscape outputs use a custom circular avatar. Source files have oriented 4284×5712 and 4896×3672 canvases; crop/aspect differences precede a valid equal-canvas comparison. Compare the supplied matching no-card renditions for photo coverage, not the differently cropped original JPGs.

Canonical geometry owner: GlassCardLayoutSpecification. Presentation consumes its frames; Renderer draws them. Scope: replace independently normalized divider/right-column starts with explicit local distances from the stable badge frame. Keep panel geometry, badge center, left-column capacity, authored content, row centers, font policy, native material, media/export/configuration contracts. Native SwiftUI frames remain suitable; no new framework, permission, stored field, or media processing is necessary.

Risks: changing right-column width may change text fit; the correction must never reduce previously available right-column width on normal photographic canvases. Narrow/degenerate inputs must keep finite, contained geometry. Automated checks cover 9:16, 3:4, square, 4:3, 16:9 and wide landscape; preserve full existing renderer/integration tests. Required physical gate: signed iPhone 17 Pro Max build/install/launch, followed by user visual acceptance and same-source still/Live Photo playback. Build/install is not manual acceptance.

## Historical source and confirmed differences

Historical study is `GlassCard-Reference-Appearance-Calibrated-2026-09-29.md` in the independent research worktree. Its original local P04-M01 portrait and P01-M01 landscape were inspected again. It explicitly says P04's mark at 53% is not universal; a landscape mark is about 61%. The 43-image survey's OCR centers are left 0.364/0.713 and right 0.386/0.669. Those differences are reference observations, not baseline alignment errors; OCR boxes are not glyph baselines.

Current code promotes P04-derived badge/divider/right starts 0.53/0.57/0.61 to all canvases. With portrait rail height 417.82 and landscape height 358.02:

| Gap, measured from resolved outer frames | Portrait / rail height | Landscape / rail height |
| --- | ---: | ---: |
| Badge right edge -> divider left edge | 0.023615 | 0.262932 |
| Divider right edge -> right text start | 0.293615 | 0.532932 |

This produces portrait crowding beside the avatar and landscape separation. Both right text lines already share exactly the same leading frame coordinate. Left text lines also share one leading coordinate; observed OCR starts differ because visible glyph edges/recognition differ. Do not add independent horizontal glyph nudges.

Proposed product rule: retain the stable badge center and use the existing 0.12 rail-height neighboring-clearance token for each local gap. This is a bounded MemoMark choice informed by reference grouping; it is not claimed to recover original source parameters. On supported photographic aspect ratios this moves the right start left and increases available right-column width; regression checks preserve the former capacity. Degenerate non-photographic input behavior is not expanded by this slice.

The colorful custom avatar occupies a full 0.54 rail-height circle. Reinspection of the original local P04-M01 and P01-M01 raster, restricted to manually identified mark ROIs and threshold min(R,G,B) >=245, yields visible bright boxes (545,1324)-(590,1380) and (858,964)-(903,1020): both 56 px high. This threshold diagnostic excludes anti-aliased edge pixels; it is not a full glyph mask. Against 142/140 px rails the ratio is 0.394/0.400. Adopt a bounded 0.40 rail-height GlassCard badge frame, retaining the stable horizontal and vertical center and the user-selected artwork. The linear size decreases 25.9%, circle area 45.1%; test/render/device acceptance must confirm the result. This choice measures visible height, not equal perceptual weight between all artwork. Shared BadgeRenderer and other styles are unchanged.

## Typography and material observations

New native Vision observations, run against actual original raster dimensions, confirm same-column leading alignment and two text levels. Landscape primary OCR height is 71.16/358.02 = 0.199; lower-right is 57.52/358.02 = 0.161. P04 reference primary boxes are about 0.207 and secondary about 0.164. Thus text scale is already near the reference family; increasing all fonts is unsupported. OCR extents are not exact font or glyph masks. Output-width downsampling still makes landscape text small at phone width; do not enlarge the entire panel without the earlier capacity/coverage research.

Observed real images show restrained translucent tinted panels; bright clothing/stone requires further local glyph/background readability review. Still images cannot establish frame-wise shimmer, pumping, audio, identity, or PhotoKit acceptance. Native material is a provisional candidate, not exact recovery of the source corpus's compositor.

Configuration `MemoryCardPreviewSurface` still draws only foreground over a plain background; `GlassCardCardRenderer` correctly invokes NativeBackdropMaterialCanvas. The older compact renderer test exercises the latter, not the Configuration Center surface. This was a verified source-level preview material omission; the actual-surface regression and correction below now cover the previously missing consumer.

## Evidence and remaining closure

Private input measurements and read-only Vision helper: `/tmp/MemoMarkGlassAppearance20261002/measurements.jsonl` and `inspect.swift`. Only coordinate boxes and filenames are output; recognized personal text is not retained by the helper. No internet lookup, media upload, original modification, commit or push. The complete returned review was subsequently retrieved from conversation 6abf68c7-f9d0-83ec-a4f3-3c92f09491b4 with a 20,000-character per-item bound. Its findings are review input; current local source and new evidence remain authoritative.

Geometry correction implementation and validation are recorded below when complete. Mark size, landscape column split, glyph baselines and equal-width reading are not declared visually accepted merely because geometry tests pass.

## Preview correction decision gate

The source-level omission is now included as a second bounded increment (Product Loop, P1): Configuration Center's actual GlassCard branch must render NativeBackdropMaterialCanvas at the same output canvas as the foreground and scale the pair together. Old systems retain their plain photo plus fixed-alpha foreground. No configuration, media or material policy changes. Test the actual MemoryCardPreviewSurface against the shared native canvas in a text-free interior material crop for both orientations; retain output-sized font fit. This checks the previously uncovered consumer rather than a file-string assertion. Physical visual acceptance remains required.

## Final candidate geometry for the supplied output canvases

All coordinates below are top-left image coordinates; right starts add the panel origin to local frames. These are resolved-layout calculations, not a new saved Photos output.

| Item | Portrait before -> candidate | Landscape before -> candidate |
| --- | --- | --- |
| Badge size | 225.623 -> 167.128 px | 193.331 -> 143.208 px |
| Badge center x | 1699.949 -> unchanged | 2591.906 -> unchanged |
| Right text leading x | 1947.813 -> 1886.297 px | 2975.654 -> 2751.583 px |
| Each neighboring gap | 9.867 / 122.678 -> 50.138 px | 94.135 / 190.800 -> 42.962 px |

Panel and left leading coordinates are unchanged. Right-column usable width increases by 61.516 px in portrait and 224.072 px in landscape; the same authored content can fit at equal or larger size. Fitted right-row font changes are expected within the existing policy and require visual review. The correction intentionally retains a stable 53% mark center; the reference's content-dependent landscape mark near 61% remains a separate product alternative.

## Automated closure

- Local-spacing regression failed against the previous anchors; measured-mark regression failed at the previous 0.54 size; Configuration Center material regression failed against the old foreground-only surface in both orientations.
- Final macOS result: `/tmp/MemoMarkGlassAppearance-verified20261002.xcresult`, 21 tests / 25 parameterized executions passed, zero failures/skips/runtime warnings. This includes app/test compilation, existing output-sized preview/fit and actual export/artifact integration.
- Independent native SwiftUI raster hosts differ at a small number of 8-bit rounded pixels. For the existing compact preview test, diagnostic exported PNGs differ only by 1 level in 72/691200 components (mean 0.000104), with no >1 differences. The revised regression bounds max<=1 and mean<0.001, retaining the output-versus-viewport fit assertion. The Configuration Center interior comparison bounds max<=3/mean<0.5 and asserts omitted native glass differs by mean>3. Thus material omission remains distinguishable without claiming byte-identical host rasterization. Attachments preserve calibration output images; no private inputs are used in these tests.
- The candidate is locally modified, uncommitted. Device build/install and manual acceptance are recorded separately below.

## Physical delivery and review closure

Signed MemoMarkiOS Debug build for the live iPhone 17 Pro Max destination succeeded. Strict deep codesign verification passed. Overwrite-install and normal launch succeeded on CoreDevice 863C2747-6742-5E93-B715-6F89DBF90B31; live installed-app inventory confirms 2.3.5 (116). The delivered package is `/tmp/MemoMarkGlassAppearancePhysical20261002/Build/Products/Debug-iphoneos/MemoMarkiOS.app`. This is baseline 72e101ed plus the local candidate, not a new Git commit or Store release. No uninstall/container reset or automatic Photos-study save was requested or performed.

Five-axis source review: geometry stays in Layout; no persisted/wire key changes; both right text rows share one leading coordinate; authored strings and original assets remain untouched; preview uses the existing native material contract and output-sized fitting; no added service/dependency/cache/concurrency path. The new preview work uses bounded bundled calibration assets; performance is not profiled or certified. Shared BadgeRenderer is unchanged.

Calibration preview PNGs are retained outside Git in `/Users/rui/Documents/Codex/2026-10-02/GlassCardAppearance/configuration-portrait.png` and `configuration-landscape.png`; these are macOS native-rendered test artifacts using bundled photographs, not physical screenshots or re-exported user photos. Read-only input/Vision/motion helper outputs remain in the task's /tmp directory.

Manual acceptance remains NOT VERIFIED: reprocess the same cropped 9:16 and16:9 photos on the delivered phone, inspect leading edges and mark/group balance at full image and zoom, then view the saved Live Photos through playback including bright/dark frames. Also check an empty right column, long/boundary multilingual text, and Apple mark versus custom avatar. No automated Photos mutation was performed. One supplied processed portrait MOV was inspected for dimensions/audio; a corresponding processed landscape MOV was not supplied. This pass does not certify HDR/P3, motion stability or PhotoKit readback.

## Follow-up closure decision (2026-10-02)

Engineering Loop, P1 preview consistency. Consolidate the already-corrected native source canvas and foreground into one shared GlassCardResolvedCanvas view consumed by both the card renderer and Configuration Center. Layout and fitting remain output-sized; no material, configuration or export policy changes. Existing independent expected-composition raster tests must still pass. Add bounded four-language short/long/empty slot coverage in portrait and landscape; retain authored strings and explicit overflow. Run GlassCard plus still/video/pair composition tests. Full regression interruption is recorded separately if the fixture I/O host blocks. Physical launch currently returns Locked; do not claim new device or manual evidence until it runs.

## Follow-up verification evidence

The ordinary card renderer and Configuration Center now consume `GlassCardResolvedCanvas`, which owns only composition of the source, native material and foreground at the resolved output size. Layout Engine still owns all frames and fitting. Existing independent expected-composition image tests remain unchanged.

Current-worktree focused result: `/tmp/MemoMarkGlassClosureFocused20261002.xcresult`, 41 tests / 45 executions, zero failures, skipped tests or runtime warnings. Includes GlassCard integration/prototype plus Live Photo still/video/pair composition suites. Added four-language short/long/empty-right content checks for both orientations preserve strings and geometry, and report overflow rather than truncating authored text. Native video regressions verify background changes per frame, foreground, non-panel photo area against the no-material control, and asymmetric rotated-source geometry. These controls do not establish original-source color fidelity.

Fresh attachments are retained outside Git at `/Users/rui/Documents/Codex/2026-10-02/GlassCardClosure/`: actual Configuration Center portrait/landscape PNGs, native synthetic motion MOV and source/control/native color observation. They are automated macOS artifacts, not physical screenshots or the supplied private-photo re-exports. The landscape 360px rendition remains visibly small; no claim of a closed landscape legibility gate.

Fresh signed physical Debug build and strict deep codesign verification passed, and overwrite-install succeeded. Launch of the explicit native-material/full-resolution study was rejected by SpringBoard with `Locked`. The prior successful normal launch is historical evidence for the preceding candidate only. Current study performance, Photos readback and manual visual acceptance are not verified. No Photos writes were requested by this launch (the `--glasscard-native-photos-study` flag was omitted). Device Inputs contain historical IMG_7027/IMG_7033 only; no supplied private original was uploaded or rewritten.

Color closure: current NativeBackdropVideoCompositor declares `supportsWideColorSourceFrames=false`, `supportsHDRSourceFrames=false`, samples native material through RGBA8/sRGB and renders output using ITU-R709. Still material composition rasterizes through the existing 8-bit DeviceRGB canvas before its ImageIO writer. This is evidence of a bounded SDR-oriented implementation, not proof of P3, HDR or gain-map preservation. Do not change or advertise a color-preservation policy based on metadata labels alone. HDR/P3/gain-map acceptance and actual-source outside-panel fidelity stay open, with Release authoring still closed.

Performance closure: macOS test duration and historical device manifests cannot certify current full-size peak memory, frame latency, cancellation or thermal behavior. Current device execution is blocked by lock state. Measure current native per-frame raster and end-to-end pair export on the unlocked physical device before closing this item.

Complete review closure ledger:

| Review finding | Current state | Remaining acceptance |
| --- | --- | --- |
| Configuration Center omits native material | Corrected, actual-surface raster regression passes | Physical appearance still pending |
| Preview consumers can drift | Shared resolved composition implemented, independent expected-composition tests pass | No new stored/configuration owner |
| Badge too prominent / neighboring gaps change with aspect | Candidate .40 badge and .12 local gaps implemented; six-aspect geometry passes | Original/custom mark perceptual balance, supplied same-canvas re-exports |
| Four-language long/empty copy | Automated short/long/empty-right checks pass | Full visual matrix and boundary readability |
| Frame-dependent native glass and rotation | Automatic motion/rotation controls pass | Apple Photos playback, keyframe, audio, starts/ends, transitions |
| Landscape thumbnail typography | Still open; 360px sample remains small | Bounded research-led typography/capacity decision |
| SDR/P3/HDR/gain maps | Current SDR-oriented limitations established; preservation unverified | Adopt explicit policy and source/output media evidence before opening Release authoring |
| Full-size native raster performance | Blocked on physical execution by device Locked | Frame latency, sampled/peak memory, longer clips and cancellation/thermal evidence |
| Broad regression | Source-mirror full run passed1965 tests,2007 executions,1 existing disabled JPEG test,0 failures | Final accessibility-preserving increment rerun recorded below |

The single skipped JPEG writer test is explicitly disabled for macOS ImageIO CI-host stability; it is not a newly skipped GlassCard test. Two existing FixtureExportReadbackTests QoS priority-inversion runtime warnings remain in the complete regression result. Source mirror is only a test-host I/O workaround:928 Source/Tests files byte-equal to current worktree; no private input photos copied. Original Desktop full-run host stopped during fixture file-attribute wait and is not counted as a pass.

Final candidate verification after preserving background accessibility hiding: `/tmp/MemoMarkGlassClosureFinalFull20261002.xcresult` PASSED,1965 passed tests /2007 passed executions,1 existing disabled test,0 failures,2 FixtureExportReadbackTests QoS runtime warnings. Final source mirror is byte-equal for all928 Source/Tests files. Summary JSONs and SHA256 comparisons are retained in the outside-Git GlassCardClosure folder. Final signed physical build, strict codesign verification and overwrite-install passed; no new physical launch or Photos study completed because the device remains Locked. The final shared view hides decorative backgrounds from accessibility while preserving foreground text. No global visual/media/performance certification or Release authoring change.

## Authorized device acceptance and source sync follow-up

Owner explicitly authorized GitHub push and necessary automatic acceptance after unlocking iPhone17ProMax. Engineering Loop, P1 verification-only increment: extend the existing DEBUG native study to use fresh per-run save idempotency, fetch only the just-created PHAssets, require Live Photo subtype and photo/pairedVideo resources, export those local resources with network access disabled, and request a local PHLivePhoto at bounded256px size. This closes saved-pair resource/decode evidence; it does not certify audible playback, visual transitions or HDR. No permission prompt, unrelated library enumeration, original alteration, Release behavior or stored schema changes. Compile signed physical target, execute two approved existing input pairs and inspect resource pairing identifiers, audio and canonical geometry after copy-back. Keep private files outside Git.

Device acceptance after unlock: signed candidate installed and launched, two previously approved local fixtures saved as fresh Photos Live Photos and decoded locally;4 readback resources SHA256-identical to generated files. Still/MOV identities match; start/middle/end frames and nonzero audio PCM decode. Latest pair composition observations2.154s/2.240s exclude Photos save/readback. Final normal launch passed. Instruments device is Offline despite working CoreDevice, so peak-memory profiling remains blocked. Current full regression passed1965 tests/2007 executions,1 existing disabled test,0 failures,2 existing QoS warnings; final928 Source/Tests files byte-equal to mirror.

New P1 LP-TIME-001: actual source timed metadata has still-image-time at1.400s/1.405s (value-1); each source has3 metadata tracks, each output has0, and output global metadata has no marker. This proves keyframe-time carryover is missing in the inspected existing native export path. Photos save/decode pass does not close this fidelity gate. The appearance checkpoint preserves media behavior and keeps Release authoring closed; next bounded work must preserve the semantic keyframe timing without blindly copying obsolete source orientation/transform tracks. Full accepted record:Docs/03_Engineering/2026-10-02-glasscard-appearance-verification-closure.md. Raw resources, IDs, JSON and frame PNGs remain outside Git. No new5890/5901/custom-avatar re-export or manual visual acceptance is claimed.
