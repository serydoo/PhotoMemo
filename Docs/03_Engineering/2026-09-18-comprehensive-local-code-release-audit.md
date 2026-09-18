# MemoMark 2.3.0 (105) 本地代码与发布准备综合审查

- 日期：2026-09-18
- 审查类型：Engineering Loop；本地只读审查与证据整理
- 范围：代码结构、持久化、队列恢复、PhotoKit/Live Photo、元数据、FM、并发、日志隐私、测试、构建与发布证据
- 明确边界：本轮不操作真机、不清理或回退工作区、不提交/推送、不上传 TestFlight、不修改 App Store Connect

## 结论先行

当前源码可以作为继续收口的候选版本，但还不能称为“已完成发布认证”。本地自动化质量门是绿的，持久化和 FM 关键关系已有较强保护；未关闭项主要集中在必须依赖真实 Apple Photos、设备、中断场景或性能工具的证据，而不是可以凭静态代码审查合理推断的结果。

本轮没有发现应当用大范围重写处理的本地 P0 代码缺陷。为了不把高风险 PhotoKit/Renderer 变更混入发布收口，本轮保留以下证据门，不将它们伪装成已解决：

1. TX-001：PhotoKit 外部提交后的进程中断、精确读回、重复输出防护，需要签名真机证据。
2. BP-001：单任务高分辨率内存峰值和并发约束，需要真实设备/性能工具证据。
3. 导出流水线的高负载执行位置和延迟，需要 Instruments 或真实设备测量；当前静态代码仍显示同步导出段位于 `MainActor`。
4. Share → Processing → Notification → Apple Photos、静态照片与 Live Photo、StoreKit、VoiceOver、Dynamic Type、Dark Mode 和多语言视觉验收，需要用户后续真机执行。

## 证据快照

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| 完整 `MemoMarkTests` | PASS | 1,865 passed / 0 failed / 1 skipped；xcresult 总结果 `Passed` |
| 跳过测试 | NOT VERIFIED | `StillImageMetadataWriterContractTests` 的 ImageIO fixture 在当前 Xcode 测试运行器收尾时跳过 |
| 运行时警告 | P2 | `FixtureExportReadbackTests` 产生 2 条 QoS priority-inversion warning |
| macOS Debug build | PASS | 独立 DerivedData，退出码 0 |
| 通用 iOS Debug build | PASS | `MemoMarkiOS` generic iphoneos 编译通过 |
| Share Extension Debug build | PASS | generic iphoneos 编译通过 |
| 治理与空白检查 | PASS | `validate_codex_governance.py`、`git diff --check` |
| COS 独立复核 | BLOCKED | Chat On Steroids 窗口读取触发 ScreenCaptureKit `-3811`；不能声称本轮有新 COS 结论 |
| 真机 | NOT VERIFIED | 按用户安排留给后续手工验收，本轮未启动 |

## 架构与代码结构

### 已确认的健康点

- 主流程仍保持 `Photo → Metadata → Memory → Presentation → Layout → Renderer → Export`，没有发现把 Memory 语义或 Layout 真值重新塞回 Renderer 的新生产路径。
- FM 的内容载荷独立于旧 `TemplateArea` 兼容载体；冻结的 FM 生产快照要求完整内容和外观数据，缺失时失败关闭。
- 队列运行时由 `BatchQueueDurableLedger` 统一提交，`BatchQueueStore` 只在持久化成功后更新投影；启动时的 receipt reconciliation 是明确的 bootstrap 阶段，不是并行的第二队列真值。
- 活跃源码未发现重新引入旧 `MainView`/Workspace 编辑流的生产构造；当前大文件主要是职责仍较集中的历史边界，不应仅凭行数机械拆分。

### 结构性风险与后续边界

- `BatchQueueStore.swift`、`BatchProcessing.swift`、`MacConfigurationCenterPage.swift` 等仍然偏大。它们暂时有明确的运行时所有者，但后续拆分必须以行为边界为单位，不能在发布收口前做无证据的大规模迁移。
- `RecordCardExportPipeline` 仍标记为 `@MainActor`，而其同步路径包含源图读取、Core Graphics 合成和编码前的准备。生产队列的卡片构建已有 off-main 边界，但这不等于导出全部工作已脱离 UI actor。该项保留为 P1 性能/架构审查，不在本轮冒险改动。

## 持久化与恢复

### 队列

`BatchQueuePersistence` 的生产初始化使用 App Group 下的文件快照，并保留旧 `UserDefaults` 作为首次访问迁移源。文件写入使用 atomic 选项，写后再次读取比对；已有文件优先于旧快照，迁移失败会阻止继续处理而不是暴露一个重启后会消失的内存投影。

`BatchQueueDurableLedger` 以 actor 串行化 revision、事务与失败恢复；并发事务、旧快照迁移、损坏数据、写入失败后保留上一个 durable snapshot、retry/recovery 和 intake 幂等均有测试覆盖。

### Configuration Library

主配置库使用 `primary.json` 与 `last-known-good.json`，写入前通过 expected-primary 比对防止旧 candidate 覆盖新版本；解码后校验 aggregate、活动 subject/configuration 身份和 revision。独立的本地备份库还校验 checksum 与文件路径身份，并在 revision 冲突时不覆盖新版本。

### 仍需关注的兼容性点

- `LegacySettingsStore` 仍是兼容投影与旧 key 读取入口；部分旧设置写入使用 `try?`/无返回值 API。当前主配置保存回执和 projection warning 已保护主要配置路径，但旧兼容投影失败的可观测性仍是 P2 维护项。
- 不应在发布前删除旧 key、改变 SchemaV1 文件名、把 FM 重新塞回 legacy template，或让 Share Extension 自己形成第二个持久化真值。

## PhotoKit、媒体与元数据

静态照片保存路径已经具备：授权检查、共享保存串行门、保存 intent、PhotoKit placeholder identifier、receipt、精确 local identifier 读回、延迟可见时的 `readbackPending`、失败后保留幂等证据，以及 receipt ledger 恢复。Live Photo 还具备静态资源/视频配对 identifier、尺寸、时长、capture date、GPS 和 QuickTime creation date 的文件读回契约。

这些是强的源码与自动化基础，但不等于真实 Photo Library 已验证。尤其不能从 `performChanges` 回调成功推断用户相册中最终可见、相册归属正确、Live Photo 可播放、原片未变或重启后没有重复输出；这些仍属于 TX-001 与用户真机矩阵。

元数据读取覆盖方向修正、EXIF/TIFF 日期、GPS、镜头、ISO、光圈、快门、焦距等规范化字段；EXIF timezone policy 按既有决策保持不变，没有在本轮擅自扩展。

## FM、预览/导出契约

- FM authored content、appearance、layout specification、resolved presentation 和 renderer 路由已有独立模型与契约测试。
- 预览空内容不会再编造通用句子；生产 render-health 与照片说明投影使用 FM-owned content resolver。
- Core Graphics 坐标桥接已经集中，避免在各消费者里散落坐标换算；本轮没有改变 canvas 或输出几何真值。
- 当前本地 FM 测试、四语资源对齐、active-localization audit、macOS/iOS/Share 编译均通过。
- 仍缺少真实设备上的字体尺寸、长文本、宽高比、Dynamic Type、VoiceOver、保存重开、静态照片和 Live Photo 视觉/读回验收。

## 隐私、权限、日志与发布资源

- 主 App、iOS、Share Extension 的 App Group 标识一致；Photos usage strings、entitlements 与 PrivacyInfo.xcprivacy 均存在。
- 未在生产源码扫描中发现 API key、Bearer token、私钥或硬编码凭据。
- StoreKit 的 `print` 调试语句均在 `#if DEBUG` 内；Share intake 使用 OSLog private hash。当前日志没有发现把用户照片内容作为公开日志输出的证据。
- Xcode 文件系统同步组已将 Share Extension 的嵌套 Info.plist 和 `README.md` 列为相关 App target 的 membership exception；已构建的 macOS App bundle 未发现这两类误打包资源。
- 版本配置目前统一为 `2.3.0 / 105`。但当前工作区仍有 68 个 staged、31 个 unstaged、3 个 untracked 项，不能把它当作一个可交付的干净 release slice。

## 问题分级

### P0：发布认证阻塞项（未关闭）

- TX-001 真机中断/精确读回/重复输出矩阵未完成。
- BP-001 单任务高分辨率内存峰值证据未完成；历史决策明确暂缓，不能用本地主机测试替代。

### P1：发布前必须明确的项

- 真实设备上的 Apple Photos 与 Share 生命周期、静态/Live Photo、权限、保存重开和原片不变证据。
- 导出高负载在 MainActor 上的实际延迟、卡顿、峰值内存和取消行为；需要测量后再决定是否拆分执行边界。
- 四语 VoiceOver、Dynamic Type、Reduce Motion、Dark Mode、输入法和 FM 长文本/宽高比验收。
- 发布工作区需要形成明确的 release snapshot；当前脏工作区不能直接作为“已审查完成”的发布输入。
- COS 独立复核尚未取得可归因结果。

### P2：不阻断本地候选，但应进入后续清单

- 1 个 Xcode fixture skipped 与 2 条 QoS priority-inversion warning 应在工具链稳定后重新确认。
- 兼容投影的静默写入失败应逐步改为可观察的 typed result，但不应和 FM/PhotoKit 发布收口混做。
- 大文件拆分应以责任边界和可独立测试的生命周期为依据。

## 发布判断

当前判断：`LOCAL CODE CANDIDATE — AUTOMATED GATES PASS; RELEASE CERTIFICATION OPEN`。

推荐顺序：先由用户在真机完成设备/Photos/Live Photo/无障碍/StoreKit 矩阵；随后恢复 COS 窗口读取并取得一次针对当前 workspace 的只读复核；再建立 release snapshot、复跑完整测试和目标构建，最后单独处理 GitHub/Xcode Cloud/App Store Connect 停止点。任何一步失败都应停在对应证据层，不以本地主机绿灯替代。
