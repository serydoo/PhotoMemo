# Processing reliability implementation

Owner authorization: 2026-10-07 current request, superseding the V4 scope limit
only for the listed processing reliability changes. Engineering Loop. Existing
UI, media contracts, frozen configuration, durable intake, ledger and receipts
remain authoritative. V5 is an intended outcome, not a certification claim.

## Boundaries and order

1. PhotoLibraryCapability: separate full, limited, add-only, none. PhotoKit
   status is a live platform fact, never a persisted authorization promise.
   Full permits album management; limited permits visible-asset readback and
   creation but not album access. Add-only permits creation, not receipt
   readback. Never interpret inaccessible output as absence/retry permission.
   Explicit album without full access fails before transaction. Default album
   degrades to system library without claiming album delivery. Background must
   not request authorization. Existing receipt pipeline requires visible
   readback; add-only processing remains blocked until acknowledgement-only
   delivery is explicitly implemented and verified.
2. ProcessingIdentity: source identity plus frozen output semantics, canonical
   versioned encoding; old pending task receipt keys must remain unchanged.
   Provider URL/name and intake UUID are not source identity. No global receipt
   pruning based only on retained job history.
3. ExecutionSession: durable grouping of nonterminal jobs, separate job history
   and cancellation scope. Restart/migration preserves membership.
4. ExecutionLease: one execution owner, cancellation quiesces owner before
   handoff; stale expiration cannot cancel a new owner. Presentation follows
   the acquired owner, not a submitted scheduling request.
5. Continued Processing: DEBUG signed marker/JPEG spike first. No production
   queue or ActivityKit authority change until real Photos extension handoff,
   sheet closure, no foreground takeover, and host callback are proven.
6. iOS 18–25 retain deferred BGProcessing and foreground recovery.

## Risk and evidence

P0: duplicate outputs, ambiguous PhotoKit commits, incompatible schema or lost
pending input. P1: permission/album routing, owner races, background lifecycle.
Changes are additive, tested by boundary. No original edits, uploads, app-data
reset, unrelated source changes or release submission.

Source: Apple PhotoKit enhanced privacy documentation and installed SDK.
Automated: Swift Testing permission matrix, destination policy, receipt tests;
then focused macOS test scheme and macOS/iOS device builds. Device matrix:
full/limited/add-only/denied; explicit/default/system album; repeated Share,
configuration variation, cancellation, expiration/restart; still/Live Photo.
Required system-only evidence remains NOT VERIFIED until observed on a signed
physical device. No simulator substitutes.

## Verification commands

`xcodebuild -project Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkTests -destination 'platform=macOS' -derivedDataPath /tmp/MemoMarkProcessingReliability test CODE_SIGNING_ALLOWED=NO`

`xcodebuild -project Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkiOS -destination 'generic/platform=iOS' -derivedDataPath /tmp/MemoMarkProcessingReliability-iOS build CODE_SIGNING_ALLOWED=NO`

`git diff --check`

## Progress

Baseline: tracked patch/status and untracked SHA256 manifest captured under
work/v5-baseline. No preexisting production Swift modifications. User release,
outreach, research and config material retained. Steps 1–10 remain open until
implementation and evidence are recorded here.

### Implemented boundaries

- Capability matrix shared by static/paired writers, album resolution, receipt
  lookup and background preflight. Full access alone manages albums; limited
  default saves use system library. Add-only remains blocked by required readback.
- ProcessingIdentity schema v1 and additive optional task field; malformed future
  schema blocks queue decode. Canonical frozen semantics ignore transport UUID/time,
  include real output configuration and referenced badge/avatar bytes. Streaming
  source hashes use 1 MiB chunks off the main actor. PhotoKit-only sources use a
  readable asset/version, never identity alone. Unresolvable legacy/mock sources
  retain UUID compatibility; this is not universal retrospective deduplication.
- Global receipts survive history pruning/bulk cleanup. Intent-derived accounting
  prevents repeated receipt reuse consuming a second free record.
- Ledger admission attaches nonterminal session membership; ActivityKit uses its
  stable session identity/counters. Publisher projections use emitted queue values.
- System worker reserves a generation lease before intake drain. Grace owner is
  excluded while BGProcessing/Continued owner exists. Expiration targets generation;
  cancellation before worker entry remains carried by Task cancellation. Recovery
  normalization precedes handoff. UI background grace covers that normalization.
- DEBUG marker probe is opt-in for one hour, fail-on-unavailable scheduling and
  independent submitted/callback/marker evidence. Intake stays recoverable; probe
  does not open host or process full queue. Custom activities are suppressed by
  actual Continued lease, including delayed request/retry paths.

### Evidence and remaining gates

Automated full run: 2,000 tests, 1,999 passed, 1 skipped, zero failures, result:
`/tmp/MemoMarkProcessingReliability/Logs/Test/Test-MemoMarkTests-2026.10.07_21-05-01-+0800.xcresult`.
Focused permission, receipts, ledger, identity, real mixed still/Live Photo,
commerce, session and stale owner tests passed in preceding increments. Additional
actual frozen-configuration/concurrent-intent tests are recorded at closeout.
Debug macOS/iOS build and signed iOS build passed. Signed Debug 2.3.6/124 installed
in place on iPhone 17 Pro Max, preserving app container; installation is not launch
or PhotoKit/media acceptance. `git diff --check` passed. Original tracked diff and
all preexisting untracked SHA256 values matched before the milestone append.

Device: iOS 27.2 Beta, build 24B5099f. Xcode physical Photos probe could not start:
`Unlock iPhone to Continue`. Normal devicectl launch independently failed with
`BSErrorCodeDescription = Locked`. No unlock/security bypass attempted. User unlock
request is pending. Test run was interrupted while waiting, not declared passing.

NOT VERIFIED: Photos sheet closure, no host foreground takeover, host background
callback/marker completion, all permission states, physical cancellation/recovery,
repeated Share output count, paired-resource/EXIF fidelity on this new build,
iOS 26 versus iOS 27, iOS 18–25 and Watch presentation matrix. Full BatchQueue
Continued Processing hookup remains intentionally gated by the required probe.
No commit, push, upload, App Store submission or V5 production certification.

Closeout: additional actual frozen-configuration and eight concurrent identical
save-intent tests passed. Formal Xcode Release iOS build passed; DEBUG spike code
is excluded there. Final signed Debug build passed and was reinstalled in place.
Device inventory readback: `com.serydoo.PhotoMemo.iOS`, version `2.3.6`, build `124`.
Final normal launch still reports Locked. Final protected-file comparison and
preexisting untracked SHA256 checks passed; CURRENT_STATUS has only the authorized
milestone append beyond its baseline user changes. Final diff check passed.

### Unlocked physical follow-up (2026-10-07)

User reports system progress popup failed, then normal processing completed after returning to MemoMark. App Group evidence separately confirms extension submission succeeded but no hostCallback/markerCompleted; wildcard handler registration returned false. This is a failed background handoff, not a completed Continued Processing validation. Apple WWDC25 specifies expanding the wildcard suffix at registration and submission. The minimal probe now uses one fixed `.marker` identifier in Info.plist, host registration, and extension submission. Signed rebuild/install succeeded; live readback confirms `registered` at timestamp 1791379283.296331. Full queue hookup remains gated on Photos handoff and marker callback evidence.

The unlocked automated run failed because the named QA album was not visible from Photos Library, selecting no personal input. The harness now first navigates the observed CollectionsTab and searches the named album. Result bundle: `/tmp/MemoMarkProcessingReliability-PhotosSpike-static.xcresult`.

### Physical probe outcome

`PhotosSpike-confirmed-label.xcresult`: UI test passed (1/1), confirming submission flow and host not brought foreground. This does NOT certify share sheet dismissal or background callback. Readback recorded static marker submission 1791379685.460648 and successful registration 1791379666.567625, but no hostCallback, executionOwnerBusy, markerCompleted, or acknowledgement. User observed system activity failure and slow eventual real output after opening host. Continued Processing production handoff remains failed/unverified. Added callback-before-lease diagnostics and scoped probe cancellation on disable; signed build passes. User screenshots show custom completed Activity plus ongoing system probe, retained as a presentation integration risk. No full BatchQueue hookup.

## 2026-10-08 补充验证：扩展回调与账本边界

- Photos Share 的 Continued Processing 注册在扩展内时，已观测到 extension callback；15 秒 marker 在 `extensionContext.completeRequest` 后继续推进，并完成有界 JPEG 编解码与读回。此证据不代表主 App 被系统后台唤起，也不代表完整渲染/Live Photo/PhotoKit 输出链路通过。
- 新探针加入 `extensionProbeV3IndependentRegistration` 标识，显式原位安装签名构建，用于排除未启动主程序的 UI 测试仍使用旧扩展的情况。2026-10-08 本轮真机运行被 Xcode 的 `Unlock iPhone to Continue` 阻塞，不能报告新版探针通过。
- 独立文件账本并发 admission 测试真实复现丢任务：两个 actor 各自基于缓存写回同一文件。补充独立 `.ledger.lock`，在同步 read-modify-write 范围持锁，重新读盘并使过期 revision 冲突。执行锁 `.execution.lock` 与事务锁分离；事务不跨 await。
- 第一轮修复后的账本 10 项测试通过；额外跨实例 stale commit 与执行锁回归正在验证。完整扩展处理队列仍未启用。
- 后续定向验证完成：账本、跨进程执行锁、lease 共 16 项通过，包括独立实例 stale commit 冲突、并发 admission、进程终止释放锁。日志 `work/v5-baseline/cross-ledger-final.log`。`git diff --check` 通过。等待解锁的 UI 测试已停止，未执行设备步骤。

## 2026-10-08 06:22 真机恢复验证

- 用户确认 QA Outputs 已清空。两组 QA Inputs 分别选择索引 `[0,2,4]` 与 `[1,3,6]`，不选择私人相册素材。
- V3 显式安装后，版本标识、extension callback、share completeRequest、15 步 marker、JPEG readback 全部读回。第一轮准备时启动主程序开启诊断，分享后未启动；第二轮测试完全没有 launch/activate 主程序。第二轮独立相册 inventory 为 0。
- V4 将编解码校验从首张扩大到所有 request URLs，逐张 autoreleasepool、取消检查、临时文件读回和删除。`/tmp/MemoMarkProcessingReliability-all-inputs-v4.xcresult` 通过；request `2B46CE53-D3AF-4602-9BF4-A746AA79466A` 的 index 0/1/2（count=3）均在 06:22:10 读回通过，随后 markerCompleted。共享偏好证据保存在 `work/v5-baseline/all-inputs-v4.plist`。
- 探针是最长边 1920 的临时 JPEG 校验，不是正式渲染，也没有 PhotoKit 写入；不能将其认定为 Live Photo 保真或 BatchQueue 后台产品验收。约 217 MB 的 available memory 只是当时进程观测值，不是跨设备内存保证。
- 全量测试汇总：2013 passed、1 failed、1 skipped（参数化展开计数不同）。唯一失败为 debug 事件 `share.persisted/share.bgProcessingSubmission` 被界面翻译键扫描识别。改为独立 `intakeProbe.*` 命名后，ActiveLocalizationUsageAuditTests 定向复测通过；未修改审计规则。
- 后续仍需：正式 pipeline 的 extension-safe 依赖拆分与资源预算、真实多图 PhotoKit receipt/readback、取消与恢复、多 Share 全局幂等实机回归、系统/自定义活动唯一展示权，以及 iOS 26 稳定系统矩阵。
- 后续尝试直接让 Share Extension 调用主 App 的 `PhotoImportService`、`RecordCardBuildService`、`RecordCardExportPipeline` 未通过编译：这些源码未加入 Share Extension target，且目标同步构建组刻意排除了大量模型与服务。临时解除两个 `#if !MEMOMARK_SHARE_EXTENSION` 后编译仍报类型不存在；这两项临时改动已恢复原样，未留下未通过的接入代码。正式复用必须按 target 边界逐步拆出可共享服务及其模型依赖，不能用扩展 fallback 的旧卡片语义冒充生产 Renderer。
- 全量单元测试在 debug 事件命名修复前的记录为 2013 passed / 1 failed / 1 skipped；唯一失败对应 `share.*` 诊断字符串被本地化键审计误识别。改为 `intakeProbe.*` 后，ActiveLocalizationUsageAuditTests、ProductionMemoryResolverTests、RecordCardBuildServiceTests、ProductionConfigurationContractTests 定向通过。账本/执行锁/lease 16 项通过。全量套件尚未在最后源码状态重跑并全绿。
- 最后源码状态全量 MemoMarkTests 于 2026-10-08 10:17 构建并通过：2,014 passed、1 skipped、0 failed（测试计划总计 2,015）。仍存在 `FixtureExportReadbackTests.swift` 的 QoS inversion runtime warning，不是本轮失败项。iOS generic build 正在复核。
- 同一源码状态下正式 Xcode (`/Applications/Xcode.app`) iOS Release generic build 通过，日志 `work/v5-baseline/formal-ios-release-build.log`。当前进行只读 QA Outputs PhotoKit inventory，再确认本轮后台测试没有遗留输出。

## 2026-10-08 10:30–10:36 续期、冷启动与排队策略复测

- 用户确认 QA Outputs 已清空后，先以一组三张 QA Inputs 续期开发探针，再以另一组三张素材进行完全冷启动 Photos 分享。两轮都未在分享后启动 MemoMark 主 App；输入只来自命名 QA 相册，扩展关闭 Share 后继续执行。
- 续期轮 request `29C003D9-B207-40DB-90DC-0360D0BEB9B5`：`share.completeRequest` 发生于 1791426657.889892，扩展 marker step 1 随后于 1791426658.222679 开始，step 15 结束于 1791426672.766972；三张输入 index 0/1/2 均通过 JPEG 读回，之后 `extensionMarkerCompleted`。
- 冷启动轮 request `F780E48E-746B-43BF-B854-86885CC6274A`：同样是 share.completeRequest 先于扩展 step 1；15 步均完成，三张素材 index 0/1/2 读回通过，结果包 `/tmp/MemoMarkProcessingReliability-cold-after-renewal.xcresult` 通过 1/1。
- 发现并修正探针策略风险：继续处理请求此前显式使用 `.fail`，系统在暂时无法立即启动时会拒绝。改为 `.queue`，以免系统资源瞬时竞争或前一个分享造成顶部失败提示。Apple 文档说明 `.queue` 会把请求加入队列；系统可能在并发容量受限时延后启动，强制退出 App 时也可能取消排队请求。durable intake 仍保留为恢复事实来源。源码：`ContinuedProcessingSpike.swift`。
- 用更新策略重新构建并在设备执行冷启动三素材分享，结果 `/tmp/MemoMarkProcessingReliability-cold-queue-strategy.xcresult` 通过 1/1；App Group 事件记录 `share.completeRequest` 后扩展 callback、15 步 marker 完成，三张输入全数 readbackPassed。主 App 未进入 foreground。
- 每轮后只读盘点 `MemoMark QA Outputs`：测试 `/tmp/MemoMarkProcessingReliability-output-inventory-post-probe.xcresult` 通过，授权为 authorized，资产数 0。探针未调用 PhotoKit 保存；无需清理输出。
- 更新后 `git diff --check` 通过。真机证据来自 iPhone 17 Pro Max / iOS 27.2 Beta 24B5099f；仍不构成正式 Renderer、PhotoKit receipt/readback、Live Photo 输出或系统稳定版矩阵验收。BGProcessing 曾启动并返回 `retryScheduled`，旧 intake 请求是否最终产生迟到输出仍需持续盘点。
- 连续双 Share 真机测试 `/tmp/MemoMarkProcessingReliability-two-shares.xcresult` 通过 1/1。用户授权的素材限定在 `MemoMark QA Inputs`：第一组 `[0,3,5]`、第二组 `[1,2,6]`，彼此不重叠。两笔 request 分别为 `F42A8D54-23F0-4DB1-A67E-BC75373C322B`、`88AC5EF9-C85F-435E-8863-7008317A329D`；两组各自 index 0/1/2 全部读回通过，均完成 extension marker，系统没有提交拒绝/失败事件。第二次 `submissionConfirmed` 后，第二个 extension callback 在第一 marker 完成前约 0.96 秒抵达，证明竞争时系统接受并启动了第二项；前一项完成后后一项继续完成。
- 第二轮后输出相册再次只读清点为 0，结果 `/tmp/MemoMarkProcessingReliability-output-inventory-after-two-shares.xcresult` 通过 1/1。没有删除或改动 Photos 资产。

## 2026-10-08 首页任务控制与失败诊断补强

- 首页活动任务进度条尾部增加暂停/继续与取消按钮；取消需用户确认。暂停状态写入 App Group UserDefaults，应用重启后仍保持暂停；取消最终一个待处理任务时自动解除全局暂停，避免后续 Share 被意外卡住。
- 暂停会阻止接纳下一处理步骤；若当前任务已进入 `.savingToPhotoLibrary`，允许当前 PhotoKit 写入事务结束，再停止后续工作，避免主动取消造成不确定提交。取消活动任务沿用相同的保存事务保护；既有 receipt/readback 恢复机制保持权威。
- 诊断附件 `MemoMark-Diagnostics-20261008-025140.json` 包含渲染/排队过程和后台过期事件，但没有终态失败事件或 PhotoKit 错误码，故不能据此认定当时保存失败的具体原因。新增长期化的 `batch.task.failure` 安全摘要，仅包含阶段、稳定错误码、系统错误域/码和支持编号；不导出照片路径、文件名或原始错误描述。
- 本轮最终定向测试：暂停/队列/后台结果/首页控制/本地化 53 项通过，macOS 测试构建通过，iOS generic build 通过，最终 `git diff --check` 通过。当前 UI/诊断验证未进行 Photos 输出写入；Continued Processing 正式照片处理仍未通过真机验收。
