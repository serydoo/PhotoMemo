# Home preset metadata single-line pass — 2026-10-02

Product Loop, P2. Owner screenshot IMG_5741.png shows the selected preset switching to the vertical fallback: subject, anchor/style and saved time stack across three lines, selection mark moves below and row height increases. Cause: ViewThatFits measures uncompressed intrinsic metadata width because the horizontal rail uses fixedSize(horizontal:true). Longer style description triggers the fallback at ordinary text size.

Bounded outcome: ordinary Dynamic Type keeps the horizontal row, title above one complete metadata line, with modest native text tightening/scaling (minimum0.8) for the reported content. One joined Text lets the metadata compress uniformly. Accessibility Dynamic Type keeps the existing vertical readable layout; full VoiceOver label and selected trait remain. Arbitrarily long authored names may still truncate at the minimum scale; do not shrink indefinitely or hide information from accessibility.

Owner/source: HomeMemoryPresetRow presentation only; selection callback, durable presets, renderer, exports and media untouched. Reuse SwiftUI Text lineLimit/minimumScaleFactor/allowsTightening. No schema, copy or editor input changes.

Verification: reconcile existing surface contract tests with the accepted normal-size layout; focused Mac source contracts; signed physical iPhone17ProMax build/install/launch; owner checks current selected row on device. No simulator. Preserve unrelated documents and research work.

Verification update: static single-line/selection/accessibility checks pass. Mac XCTest host compiled, but the existing source-contract test stalled in Foundation open while reading Desktop repository source; process sample retained at /tmp/MemoMarkHomeSingleLineTestSample.txt. Run was interrupted rather than reported as a test pass. Physical device query currently returns unavailable; signed generic iOS build is being prepared for installation when connection returns. No simulator or data reset.

Signed iOS Debug build and strict signature verification passed (/tmp/MemoMarkHomeSingleLineSigned.log; /tmp/MemoMarkNativeDeviceStudy/Build/Products/Debug-iphoneos/MemoMarkiOS.app). Device install/visual acceptance remains pending connection. Source edits are uncommitted and scoped to Home row plus existing surface contract test.

Device redelivery: paired iPhone17ProMax reconnected; existing signed single-line fix package passed strict signature verification, overwrite-install and normal launch. Post-launch process remains alive. Original app data preserved. Owner visual confirmation of the reported row remains pending.

116同步验证：通过/tmp本地源码镜像运行原Home表面契约、发布契约及全量回归，解决Desktop读取停滞的验证环境问题，未改产品文件权限。聚焦28／全量1961测试通过（1既有跳过）；Home单行修正纳入116正式同步。116签名包覆盖安装通过，启动被锁屏阻止；显示与辅助功能人工验收仍开放。
