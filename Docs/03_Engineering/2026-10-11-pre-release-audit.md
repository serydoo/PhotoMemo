# MemoMark 发布前审查：当前工作树

日期：2026-10-11。Primary loop：Engineering Loop。工作性质：审查、隔离复现和发布建议，不实施产品修复。

## 结论与范围

当前候选不建议发布。已确认 4 个 P1 缺陷和 1 个 P2 行为不一致，另有 3 个需要关闭的 UI/后台发布风险。没有据此宣称原始照片损坏、照片上传或新的全局生产认证结论。

对象是 `008e3d6e3866f99e1a5cbd7bd268ef991f407670` 之上的**当前本地工作树**，包括 Release Share Continued Processing、Home 操作/通知调整和横屏保留预览等未提交修改。当前构建身份仍为 `2.3.6 (124)`，不是已提交商店包的等价证明。源码/测试的 979 文件 SHA-256 清单记录在 `/tmp/MemoMarkAuditSnapshot20261011/audit-source-sha256.json`；审查结束时原工作树这些文件均与起始清单一致。

审查重点：配置发布 → Share 持久接收 → 执行租约 → 入队/恢复 → 保存记账 → 状态通知，以及近期配置/卡片编辑的布局与 TextKit 生命周期。Apple Photos 权限能力、媒体导出分支、四语言资源和发布证据同时核对。未安装新包、触发真实 Photos 写入、进行商店操作或全面 StoreKit/所有媒体规格认证。

## 确定缺陷

### AUD-01 / P1：经典白与 Minimal 的 Share 快照缺少 canonical configuration

触发：保存/激活经典白或 Minimal 配置后，从 Apple Photos 分享照片。

- `ConfigurationProjectionService.swift:184` 只为 FilmMark、GlassCard 发布完整 `frozenShareSnapshot`；经典白、Minimal 的对应键会被 `LegacySettingsStore.swift:355` 删除。
- `BatchConfigurationSnapshotProvider.swift:302` / `:354` 的 Share Extension 编译分支不创建 canonical snapshot，但 `:157` 仍给 transport 加上生产配置 reference。
- `BatchQueueCoordinator.swift:41` 验证带生产版本的快照；`ProductionConfigurationContract.swift:319` 因 canonical 缺失抛出 `missingCanonicalSnapshot`，返回空 admission。
- readiness 却仍可为 true，Share 接收成功后才失败。该 transport 已被冻结，单纯重试不能恢复缺失内容；不可用“降成 legacy transport”绕过生产契约。

隔离复现：对经典白和 Minimal 分别保存 projection，readiness 通过，但 `projection.frozenShareSnapshot` 和发布键均为 nil，两个参数执行均失败。这里复现的是生产发布契约；iOS extension 条件分支和 admission guard 来自源码核对，不冒称本轮已跑真实 Release Share。

历史补充：2026-10-10 七照片 Debug 真机记录同样报告 `missingCanonicalSnapshot` 和 0/7 输出，见 `2026-10-10-release-share-continued-processing.md`。这是既有设备证据，本轮没有重复该真机流程。

修复方向：由同一 canonical configuration owner 为四种样式发布完整不可变快照，并让 readiness 与 production admission 共用完整性约束。验证须覆盖四样式 × 保存/切换/重启/Share，不重构 Renderer 或记忆语义。

### AUD-02 / P1：恢复对账重复消耗免费额度

触发：具有新 `processingIdentity` 的照片保存成功，然后队列启动/刷新进行 commerce reconciliation。

- `BatchQueueCommerceAccounting.swift:105` / `:115` 用 `task.successfulSaveAccountingID` 记账。
- 同文件 `:145–152` 的 reconciliation 仍收集 `task.id`。
- `MemoMarkCommercePersistence.reconcileSuccessfulSaves` 合并两类 UUID，按集合数量提高计数。`BatchQueueStore.swift:306` 启动即调用该流程，`:954` 还有运行期调用。

隔离复现：只保存一个具有 processing identity 的完成 task，成功计数为 1；调用真实 reconciliation 后计数为 **2**，期望保持 1 的断言失败。现有 repeated-intent 测试只验证保存时去重，没有覆盖随后对账。

修复方向：保存、恢复和迁移采用同一记账身份；兼容没有 identity 的历史任务。已受影响的持久计数可能被 `max(previousCount, expectedIDs.count)` 保留，不能只替换 `.map(\.id)` 后宣称历史额度已修复，也不能盲目将所有计数减半；需制定有证据支持的有界去重/兼容策略。

### AUD-03 / P1：无关历史 intake 阻断新会话成功提醒

触发：旧会话有一个未入队、已经挂起的 durable intake；新会话已完成并有全部保存 receipts。

- `ShareContinuedProductionWorker.swift:234` 起读取**全部**未消费请求并将全部 IDs 交给完成投影。
- `ExecutionSessionCompletionNotification.swift:17` 在筛选当前 session 之前，要求这些 IDs 全部已存在于 jobs。
- 无关旧请求使投影返回 nil；当前会话没有完成提醒，且 final-notification marker 没有推进。旧请求一直被保留时，后续正常完成也可能持续没有提醒。

隔离复现：真实 request store 中保存旧 session 的 suspended intake，另建已完成新 session 和有效 saved-asset receipt；按 worker 的方式构造 pending IDs。投影返回 **nil**，期望存在成功消息的断言失败。

修复方向：completion barrier 只覆盖当前 continuation/session 的已接受请求，既防止同会话过早完成，也允许无关 held requests 保持独立。不可直接删除全局 guard 而丢失 overlapping Shares 的完整性保护。

### AUD-04 / P1：Continued Processing 的失败提醒存在两处漏口

源码确认，尚未执行本轮真机通知投递：

1. 入队前拒绝（AUD-01、identity/额度 admission 失败等）时，没有 job。adapter catch 在 `ShareContinuedProcessingAdapter.swift:193` 必须先找到 request 对应 job 才创建暂停消息，故该分支不会投递本地失败提醒。
2. 任务全部进入 `.failed` 等 terminal 状态时，worker 的成功检查失败并抛出 `unfinished`；`ExecutionSessionSuspensionPolicy.suspend` 不暂停全 terminal job，`ExecutionSessionSuspensionNotification.swift:20` 又要求 suspended member 和 nonterminal task。此状态既不符合成功消息，也不符合暂停消息，缺少 terminal-failure delivery。

系统可能仍展示 task failure；这里指应用自己的本地结果提醒缺失，不声称系统 UI 也必定消失。通知权限、Focus 和系统设置是另一层条件。

修复方向：区分 request admission failure、处理中断、terminal partial/full failure 和 confirmed completion，保留稳定 request/session route 和幂等投递记录。通知生成不能把“存在 job”作为所有失败的前置条件。

### AUD-05 / P2：安静完成策略只应用于新 extension 路径

`ShareContinuedCompletionNotification.swift` 的成功投递已经不设声音；旧系统 BGProcessing/前台恢复仍经 `BatchQueueNotifications` → `BatchNotificationService.notifyJobFinished`，后者 `:124` 无条件 `content.sound = .default`，包括完全成功。

影响：同一次普通 Share 的成功提示，会随系统版本或执行 fallback 路由改变声音行为，不符合 2026-10-10 所有者接受的安静成功默认值。失败/中断保留声音是另一个策略，不宜一起移除。

修复方向：由统一的结果提示策略根据成功/需关注状态决定声音，覆盖 extension 与 host 两条执行路径。

## 尚未完成真机复现/验收的风险

### R-01 / P1：横竖屏切换重建编辑子树

`MemoryCardEditorPageSurface.swift:95` 以 compact-height 分成外层 ScrollView 与 `fixedPreviewContent` 两个 structural branches。后者的 AnyLayout 只保护其自身分支内部的切换，不能保护两分支之间的身份。`MemoryCardTextKitSessionEditor` 在 `MemoryCardTextKitEditorSession.swift:850` 通过 `@State` 持有编辑 session，UIKit 输入框通过 `makeUIView` 创建。

源码显示旋转跨分支可能重建 TextKit session/UITextView；草稿 Binding 保留不等于 undo、selection、IME marked text 和 first-responder 连续。未声称用户文字已实际丢失。真机复现顺序：输入中文未确认拼音 → 旋转 → 选区/模块插入 → undo/redo → 保存读回；四样式和 preview 开关均覆盖。修复应先明确布局身份与输入会话 owner，不能改动 canonical input geometry。

### R-02 / P1：Debug 与 Release 媒体路径不同，内存证据不能外推

- `RecordCardExportPipeline.swift:48` 在 Debug Share/JPEG 下直接选择 `CPUStillImageExportExperiment`，Release 不走该分支。
- `LivePhotoStillImageCompositionService.swift:344` 同样在 Debug extension 使用 CPU experiment，Release 使用另一条完整 still composition 路径。
- Release `MemoMarkRenderedImageArtifactGuard.swift:15` 分配 `width × height × 4` 的整画布缓冲，GlassCard 还需 source canvas/material/final composition。一个 48MP RGBA canvas 单独就是 192,000,000 bytes，尚不包括源图、图层、编码及其它对象；这不是实测 RSS。
- `MediaMemoryBudget` 主要描述并发 tier，没有证明 extension 可在该媒体尺寸下可靠完成。

确定事实是编译路径差异和整画布分配；没有证据把已有失败归因于 jetsam。Release 签名真机需要静态/Live Photo、48MP、四样式、自定义 Logo、连续 Share、锁屏/低电量/热压力的 completion/receipt 与峰值资源证据。不得直接把 Debug CPU experiment 提升为生产修复而跳过媒体保真契约。

### R-03 / P1：排队 reservation 的固定 180 秒到期与系统排队生命周期不一致

`ExternalIntakeRequestStore.swift:44/54` 用 180 秒 reservation 合并 Shares；heartbeat 仅在 adapter handler 进入后开始。`.queue` 在系统忙时等待执行，并无这段代码所假设的 180 秒开始保证。等待期间若新 Share 在到期后接入，会替换当前 continuation，新旧 system request 的归属需进一步验证；旧 handler 的 `nextContinuation` 对 identifier mismatch 会失败，`renewContinuation` 的 false 返回值又被 adapter 忽略。

这是排队/崩溃恢复状态建模风险，尚未观察到本轮 stable-iOS 用户故障。需测试 submitted-but-not-started、callback delayed、强制关闭、到期后重新 Share、stale callback，证明新旧请求可恢复且状态提示不会互相干扰。Apple 官方说明 `.queue` 可延后运行，app switcher 关闭会取消 queued requests；该取消条件不等于应用能收到 expiration 回调。

Apple 来源（2026-10-11 核对）：[queue](https://developer.apple.com/documentation/backgroundtasks/bgcontinuedprocessingtaskrequest/submissionstrategy/queue)、[Performing long-running tasks](https://developer.apple.com/documentation/backgroundtasks/performing-long-running-tasks-on-ios-and-ipados)。

## 本轮验证

| 项目 | 状态 | 证据与边界 |
|---|---|---|
| 当前 iOS Release 构建 | PASS | 正式 Xcode 27.0、MemoMarkiOS、generic iOS、unsigned，exit 0；身份 2.3.6/124 |
| 当前 macOS 完整测试 | PASS | `.xcresult` 顶层 2,090 passed / 1 skipped / 0 failed；参数执行 2,153 passed；2 条既有 FixtureExportReadbackTests QoS warnings |
| 新增审查复现 | FAIL | 3 个新测试、4 个参数/测试执行失败：两样式发布缺失，记账 1→2，无关 intake 导致消息 nil；仅写入 `/tmp` 副本 |
| 四语资源键 | PASS | zh-Hans/en/ja/ko 各 1,895 keys，差集为空；不等于译文、长文本或 VoiceOver 验收 |
| Info.plist / 治理 / diff whitespace | PASS | 当前 plist lint、governance checker、git diff --check |
| Release probe 排除 | PASS | 实际 Release extension binary 无 ContinuedProcessingSpike/MemoMarkBackgroundProbe/continuedProductionPipelineProbe markers |
| 当前签名 Release Photos 生命周期 | NOT VERIFIED | 本轮未安装/Share/保存；既有 Debug/Beta 不能替代 |
| UI/IME/undo/VoiceOver/Dynamic Type | NOT VERIFIED | 核心横屏交互有历史暂定接受，完整矩阵及新配置滚动不在本轮完成 |
| stable iOS 26、iOS 18–25 fallback | NOT VERIFIED | 需对应设备/系统/候选的证据 |
| 峰值内存/性能/压力 | NOT VERIFIED | 静态分析说明风险，不宣称 Instruments 测量或 jetsam 复现 |
| StoreKit / Store 状态 | NOT VERIFIED | 没有执行 commerce sandbox 或外部商店状态审查 |

完整测试与审查复现不是同一结果：原有 suite 可以全部通过，同时新边界断言失败。`BackgroundProcessingContractTests.releaseShareContinuedProcessingRoute` 主要检查源码字符串存在，无法证明 SDK callback、真实 admission、内存或系统取消行为。

临时证据：`/tmp/MemoMarkPreReleaseAuditFull20261011.xcresult`、`/tmp/MemoMarkPreReleaseAuditReproSuites20261011.xcresult`、`/tmp/MemoMarkPreReleaseAuditNotificationRepro20261011.xcresult`。第一次以方法名筛选的复现命令匹配 0 tests、result unknown，明确弃用；后续 suite-level 运行才是复现证据。

## 收口顺序

1. 修 AUD-01 与 AUD-02：完整快照和持久额度身份，保护四样式/历史配置/旧任务。
2. 修 AUD-03 与 AUD-04，并同步 AUD-05：以 request/session 为边界整理成功、失败、中断和 fallback 提示。
3. 确认 R-01 的旋转 TextKit 连续性和横屏配置各分组可达；不重新设计已接受的配置中心。
4. 在**同一签名 Release 候选**上关闭 R-02/R-03 及真实 Photos/权限/取消/恢复矩阵。产出新候选时按商店构建身份规则维护 build；不把当前 124 的新源码当成旧商店包。
5. 复跑失败复现、相关回归和最终候选全套，再执行明确 allowlist 的同步/发布准备。

本轮仅新增审查文档、可复现断言记录和 chronicle 条目。原有 dirty worktree、生产源码及 Tests 未被修改；无 staging、commit、push、upload 或 Store submission。
