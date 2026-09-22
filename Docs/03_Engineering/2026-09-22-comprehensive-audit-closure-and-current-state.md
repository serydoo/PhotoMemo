# MemoMark 总体审核结论与当前收口基线

- 日期：2026-09-22
- 当前源码基线：`935f5b29d90e94c1e470e10115405f4426a496da`
- 分支：`main`；当前 `origin/main` 与 HEAD 指向一致
- 当前版本：`2.3.2 (108)`
- 审核范围：近期 iPhone/Duo 设计思路对照、Apple 原生界面与无障碍规范、补充 Skills 指导、浏览器/模拟器观察、ChatGPT/COS 讨论、源码修复、自动化测试、构建与发布边界
- 证据边界：本文件只记录已经能在当前仓库、当前 Git、当前测试结果或明确设备记录中归因的事实；没有把外部窗口中未保存的意见补写成项目事实

## 结论先行

MemoMark 当前已经完成一轮实质性的代码健康化和 Configuration Center / FilmMark 收口，源码可以作为继续验证的候选基线；但项目还没有完成“生产认证关闭”。准确状态是：

```text
SOURCE AND AUTOMATED CANDIDATE — HEALTHIFICATION COMPLETE;
DEVICE / MEDIA / RELEASE CERTIFICATION OPEN
```

这不是一个需要再次大范围重写的状态。当前主要剩余风险属于真实 Apple 系统边界、设备性能和外部发布证据，不应通过继续添加 UI 补丁来假装关闭。

## 总体产品与架构结论

近期审核最终收敛到以下稳定判断：

1. Apple Photos 仍是完整照片库和原始照片的所有者；MemoMark 只处理用户明确选择的照片，并生成派生呈现。原始照片不修改，输出回到 Apple Photos 的生命周期必须继续由 PhotoKit 证据证明。
2. MemoMark 的长期模型仍是 `Source Asset -> Memory State -> Presentation Projection`。用户保留最终选图和表达权，MemoMark 不是第二图库、自动选图器、自动完整写故事工具或打印优先产品。
3. 主流程仍保持：`Photo -> Metadata -> Memory -> Presentation -> Layout -> Renderer -> Export`。Memory Engine 负责记忆语义和 Life Position，Layout Engine 负责几何真值，Renderer 负责绘制；最新代码没有把语义或布局真值重新塞回 Renderer。
4. Configuration Center 仍是 `Library -> Interactive Memory Card -> Object Inspector`。本轮最重要的状态修复是把“编辑上下文”与“处理默认”分开：打开或浏览 Preset 不会偷偷改变下一次 Share/Batch 的处理默认，只有明确命令才会改变它。
5. FilmMark 仍是受边界约束的表达方向，不是已经生产认证的独立产品线。它必须使用独立的 `FilmMarkContentSchemaV2`、appearance/placement 和版本化 recipe；缺失或不一致的生产载荷必须失败关闭。

## 已在源码和契约层关闭的内容

以下项目可标记为 `CLOSED — source / contract level`，但不把它们扩大成真机或发布认证：

| 领域 | 已完成优化与结论 | 证据边界 |
| --- | --- | --- |
| 配置状态 | 编辑 Preset、保存 Preset、设为下次处理默认、新建/复制/删除保护和过期回执已经拆成明确命令；当前配置无法解析时失败关闭，不再静默回退 Classic White | 当前代码、Configuration lifecycle / actions / production contract 测试；仍需设备路径复核 |
| FilmMark 内容 | 独立内容载荷、独立 preview projection、appearance recipe version、内容/外观/位置一起冻结；不再用旧 `TemplateArea` 或 Classic 内容冒充 FM authored content | FilmMark presentation、snapshot、queue、migration 测试；仍需设备输出读回 |
| Preview / Renderer | 预览、静态输出和 Live Photo overlay 继续消费同一 resolved presentation/layout contract；坐标桥接和文字 fit/overflow 诊断集中处理 | Renderer / layout / production contract 测试；不能替代真实照片输出验证 |
| PhotoKit / 队列基础 | durable ledger、receipt、placeholder/local identifier、延迟读回、Live Photo 配对身份、幂等和失败恢复边界已有类型化保护；Share 仍是 intake boundary | 自动化测试和源码审查；TX-001 的真实中断/重启/相册读回仍开放 |
| UI 结构 | 配置中心保留原生选择控件、明确层级、适配窄宽度和大字尺寸；方向控制保留 44pt 触控目标；保存反馈和底部操作层级已统一 | 契约测试、模拟器/浏览器观察与当前提交修复；不能代替实体 iPhone 视觉验收 |
| 无障碍与本地化契约 | 四语资源和 active-localization 检查通过；VoiceOver label/value/hint、Reduce Motion / Reduce Transparency、Dynamic Type 分支和可达性布局缺陷已有源代码契约保护 | 代码/契约层关闭；四语真实 VoiceOver、Dynamic Type、外观矩阵仍开放 |
| 代码质量 | 最新健康化提交完成配置事务、PhotoKit/FilmMark 路径和测试保护的集中修复，没有发现需要用大规模重写处理的本地 P0 | 五轴代码审查通过当前变更方向；性能仍需 Instruments/真机测量 |

## 当前直接验证结果

本轮针对当前 HEAD 重新执行了轻量门禁和完整 macOS 测试：

- `python3 scripts/validate_codex_governance.py .`：通过。
- `git diff --check`：通过。
- `MemoMarkTests`：`1905 passed / 0 failed / 1 skipped`，结果为 `Passed`；动态参数展开后设备汇总为 1938 次通过，xcresult 总测试项为 1906。
- 当前 xcresult：`/tmp/MemoMarkAuditCurrentHEAD/Logs/Test/Test-MemoMarkTests-2026.09.22_20-26-09-+0800.xcresult`。
- 测试运行仍记录 2 条既有 `FixtureExportReadbackTests` QoS priority-inversion runtime warning；它们不是本轮失败，但也不应写成零警告。
- Xcode beta 仍报告 `CLGeocoder` 弃用、历史兼容别名和少量测试契约的 deprecated/no-usage 警告；这些是维护项，不是本轮新增的生产失败。
- 工程版本字段当前为 `2.3.2 / 108`，相关 target 的版本字段已对齐。
- 当前工作区有 39 个未提交路径：其中 27 个是已经移入
  `/tmp/MemoMarkCleanup-20260922/`、等待确认的可恢复整理候选，8 个是工程状态/审核文档候选，
  另 4 个位于受保护的 `Docs/Outreach/`。本轮没有把 Outreach 外部材料并入源码审查范围，也没有
  覆盖、删除、暂存或提交它们；本轮未执行 GitHub push。

## 尚未关闭的项目

### P0：认证门仍开放

- `TX-001`：PhotoKit 外部提交后的进程中断、精确读回、延迟可见、重启恢复和重复输出防护，必须在真实 Apple Photos/实体设备上完成证据矩阵。
- `BP-001`：高分辨率单任务内存峰值，包含真实高分辨率静态照片和 Live Photo；必须用实体设备和 Instruments 或等价测量，不能由 Mac 测试或模拟器替代。
- 上述两项关闭后还需要新的 superseding production certification；历史的条件性认证不能自动变为通过。

### P1：设备和运行时验收仍开放

- 当前 `935f5b29` 的最新源码没有一份可归因的完整实体 iPhone 17 Pro Max 手工验收记录。旧的 `2.3.2 (108)` 覆盖安装记录只能证明安装阶段，不能自动迁移为当前 HEAD 的逐屏验收。
- 需要在解锁且保持可用的配对 iPhone 上完成：Configuration Center、Classic/Minimal/FilmMark、横竖屏、窄宽度、Dynamic Type、VoiceOver、Reduce Motion、Reduce Transparency、浅色/深色、四语、保存/重开和底部操作可达性。
- 需要完成 `Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos` 的静态照片、Live Photo、原片不变和输出读回；安装成功、启动成功或模拟器观察都不能替代。
- 导出路径仍有 `@MainActor` 的高负载疑点；需要先用 Instruments/实体设备测量延迟、卡顿、峰值内存和取消行为，再决定是否做行为保持的执行边界拆分。
- 当前设备媒体认证还受到 iOS 27.2 / Xcode beta QA runner 断连或锁定状态影响。应恢复设备状态后继续一次有边界的验证，不应反复重装、清容器或切换设备来掩盖证据缺口。

### 外部与协作边界

- 当前 Git 事实是 `main` 与 `origin/main` 指向同一 HEAD；这只说明引用一致，不把它解释成 TestFlight、App Store Connect 或正式发布已完成。
- 2.3.2 的 App Store 文案和 TestFlight 说明仍是 Draft/准备材料；未记录 TestFlight 上传、App Store Connect 修改或正式提交。
- Chat On Steroids 本轮没有取得新的可归因复核：读取窗口再次触发 `ScreenCaptureKit -3811`。因此保留源码和本地测试作为主要证据，不把旧 COS 线程或桥接状态写成当前独立复核通过。
- `Docs/Outreach/` 仍是未发布、待事实复核和单独授权的本地材料；不得因为源码基线稳定而自动发布、联系、投放或上传。

## 材料关闭口径

- 9 月 18–21 日的审查、FM UI 梳理、发布清单和配置根因文档继续作为历史证据，不改写原始时间点的测试数量、设备状态或未验证声明。
- 本文件是 2026-09-22 起的总事实源；后续新增证据应更新本文件或建立带日期的增量记录，并链接回本文件。
- “代码问题已关闭”只表示源码/契约/自动化层达到对应门槛；只有在设备、Photos、Live Photo、性能、无障碍和外部发布证据齐全后，才可以关闭对应的 release gate。
- FilmMark 的 `HOLD` 决策仍有效；不能仅通过把 picker、版本字段或商店文案改名来把它升级为生产认证。

## 下一步顺序

1. 解锁并保持配对 iPhone 17 Pro Max 可用，安装与当前 HEAD 对应的签名包，完成设备矩阵和手工收口。
2. 在同一设备上执行 TX-001 和 BP-001 需要的 PhotoKit/Live Photo/内存证据；记录 exact build、输入媒体、输出相册和读回结果。
3. 对高负载导出做 Instruments 测量，再决定是否建立独立的 prepared-image/write transaction；没有测量前不做大规模 actor 重构。
4. 如确实需要独立 COS 复核，先恢复完整 ChatGPT/Core/connector 链路，再对当前 checkout 发起一次新的只读调用；不得把当前失败的屏幕捕捉反复重试成“已复核”。
5. 用新的 superseding certification 关闭或明确保留每个 gate，之后才分别判断 GitHub、TestFlight、App Store Connect 和正式发布动作。
