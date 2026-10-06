# GlassCard appearance correction and physical verification checkpoint
> 2026-10-06: The historical fixed53% anchor in this record is superseded by the owner-approved trailing-group contract in `Docs/03_Engineering/2026-10-06-glasscard-trailing-group-layout.md`; other historical evidence retains its original scope.


Date: 2026-10-02. Source baseline: main72e101ed. Version2.3.5(116), source checkpoint; Release Evidence Open. Owner explicitly authorized scoped commit/push and necessary automatic acceptance on unlocked iPhone17ProMax. No version increment or Store delivery.

## Bounded change and ownership

Product Loop: Layout owns the mark size candidate0.40 rail height and the two0.12 rail-height neighboring gaps, replacing independent divider/right-column percentage anchors. Keep the53% badge center, panel, left-column capacity, same-column leading edges, authored content and row centers. Right-column width increases on supported photo aspects. These are research-informed candidates, not a completed visual freeze.

Engineering Loop: Configuration Center and ordinary card previews consume GlassCardResolvedCanvas at output size, preserving native material, foreground order, fallback, fitting and decorative-background accessibility hiding. Extend the existing DEBUG/iOS study only to save fresh per-run outputs, fetch those assets, export local resources and request a256px PHLivePhoto with cloud access disabled. No production Photos writer, configuration, export, metadata or Release availability policy changes.

## Verification

- Focused current-worktree regression:41 tests/45 executions,0 failures/skips/runtime warnings.
- Final push candidate complete macOS regression:1965 passed tests/2007 passed executions,1 existing disabled JPEG ImageIO fixture test,0 failures,2 existing FixtureExportReadbackTests QoS priority-inversion warnings. Result:/tmp/MemoMarkGlassClosurePushFull20261002.xcresult. Temporary tracked-source mirror works around Desktop test-host I/O; all928 Source/Tests files byte-equal to final current worktree. Hash/summary evidence remains outside Git.
- Signed physical Debug build, strict codesign, overwrite-install, explicit native/full-resolution study launch and final ordinary launch pass on iPhone17ProMax. Existing app data preserved.
- Two previously approved local fixture pairs, IMG_7027 and IMG_7033, each create a new Photos Live Photo. Each exposes photo and pairedVideo resources and decodes through local PHLivePhoto. Four exported Photos resources are SHA256-identical to the generated HEIC/MOV files. No cloud downloads requested. This is the existing fixture pair matrix, not a re-export of the newly supplied5890/5901 family-photo pair or custom-avatar visual acceptance.
- HEIC outputs:4284x5712 and4032x3024, orientation1, sRGB profile. MOV outputs:2880x3840 and3840x2880, identity transform,1 video/1 audio track. Still/MOV pairing identifiers match and are nonempty. Start/middle/end video frames decode; audio decodes85113/110691 samples with nonzero PCM. Audio presence/decode is not subjective sound or playback acceptance.
- Latest uninstrumented pair composition observations:2.154s and2.240s, excluding Photos save/readback. Synthetic1080x1440,30-frame/30fps material/raster/copy/encoding observation remains separate from full-size per-frame performance.
- Instruments Activity Monitor recording could not start: xctrace lists the physical device Offline and timed out waiting for boot, while CoreDevice launch/copy succeeded. No recorded peak-memory, thermal or frame-latency certification.

## P1 newly observed: LP-TIME-001

The two source MOVs each expose3 timed metadata tracks. Decoded metadata contains com.apple.quicktime.still-image-time at1.400s and1.405s, value-1, alongside orientation/live-photo-info/still-image-transform data. Both native output MOVs expose0 metadata tracks and no global still-image-time item. Thus original still-keyframe timing is not retained in these outputs even though Photos saves and local PHLivePhoto decode succeed. Automated pairing/decode PASS must not be expanded to full Live Photo fidelity PASS.

This is an observed carryover in the existing media composition path, not a metadata behavior change in this appearance patch. Next bounded Engineering Loop work must specify source keyframe-time resolution and output timeline mapping, selectively synthesize/retain the required timed still marker, and prove static/motion transitions on physical Photos. Do not blindly copy original orientation/transform tracks into upright, resized/cropped output. Preserve original assets and generated pairing identity. Add a fixture with a noncentral keyframe and end-to-end source/output timed-marker checks.

## Remaining gates and sync scope

Release authoring stays closed. Open: LP-TIME-001, landscape360px readability, complete multilingual/background visual freeze, supplied5890/5901 same-canvas/custom-avatar acceptance, manual Photos playback/audio/transitions, HDR/P3/gain-map policy and full device performance/accessibility.

Private media, decoded frames, Photos identifiers, app containers, trace attempts and diagnostic JSON remain outside Git in /Users/rui/Documents/Codex/2026-10-02/GlassCardClosure. Only bounded source/tests and accepted text records are synchronized. Unrelated Outreach, old release drafts, unfrozen research, config and existing research chronicle edits remain local. Source synchronization does not imply TestFlight upload, App Store submission or production certification.


## 2026-10-02 LP-TIME-001 superseding closure

后续限定修复已关闭源still-image-time标记丢失：普通／原生玻璃配对导出保留精确时刻、持续时间与Int8数值；不复制旧方向／变换轨。全回归1968通过测试／2011通过执行、1既有禁用、0失败；签名iPhone17ProMax两组7027／7033新Photos资产回读在1.400s／1.405s保留-1标记，配对身份、资源哈希、视频解码和非静音音轨通过。上述先前“LP-TIME-001开放”记录为发现时的历史状态，已被本段及[专项关闭记录](2026-10-02-live-photo-keyframe-time-closure.md)取代。人工播放／封面切换、5890／5901自定义标识同画幅外观、HDR／P3、性能／无障碍与Release入口仍未关闭。版本2.3.5(116)不变；本轮仅源码同步，不改变TestFlight／App Store状态。
