# MemoMark AI Guide

这份文档用于帮助后续任何 AI 工具快速接手时光记项目，不依赖历史聊天记录，也不需要先靠猜来理解项目方向。

## 0. V2 Reset Notice

时光记已进入 V2 Research Phase。

功能开发暂停，Renderer 打磨暂停，UI 扩展暂停。

新的最高优先级入口是：

1. `PROJECT_CONSTITUTION.md`
2. `Docs/MASTER_PLAN.md`
3. `PROJECT_RESET.md`
4. `RepositoryAudit.md`
5. `Research/README.md`

新的目标不是继续做照片水印 App，而是建设一个 local-first Memory Presentation Engine。

V2 主链路：

```text
Photo -> Metadata Engine -> Memory Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export
```

Renderer 不再负责 layout。任何布局相关修改都必须先经过：

```text
Research -> Specification -> Layout Engine -> Renderer -> Validation -> Release
```

如果你是新的 AI 会话，先读上面的 V2 入口，再继续读取本文件里的历史上下文。

旧文档暂时不要迁移。当前优先级是建立新的 Research 文档，等研究规格稳定后再整理旧 Docs。

## 1. Project Snapshot

- 项目路径：`/Users/rui/Desktop/PhotoMemo`
- 当前主分支：`main`
- 远端仓库：`git@github.com:serydoo/PhotoMemo.git`
- 当前 V1 代码基础：
  - macOS 主应用：模板校准中心
  - iOS 基础：`PhotoMemoiOS` target 已可编译
  - 分享扩展：`PhotoMemoShareExtension` target 已可编译

一句话：时光记 V2 是一个 **local-first、基于 metadata、memory engine、presentation specification 和 layout engine 的 Memory Presentation Engine**。

照片有时间戳，记忆有位置。时光记要保存的不只是照片怎么显示，而是这张照片在用户人生时间线里的位置。

它不是：

- 云相册
- 修图软件
- 批量任务控制台

它是：

- 模板校准中心
- 元数据与记忆语义叠加工具
- 外部图片接入后，后台生成新图并写回系统相册的处理链路

## 2. Startup Routine

任何新的 AI 会话，先按这个顺序读取：

1. `PROJECT_CONSTITUTION.md`
2. `Docs/MASTER_PLAN.md`
3. `PROJECT_RESET.md`
4. `RepositoryAudit.md`
5. `Research/README.md`
6. `README.md`
7. `AI_CONTEXT.md`
8. `HANDOFF.md`
9. `AGENTS.md`
10. `Docs/CURRENT_STATUS.md`
11. `git status`

如果任务涉及主编辑流程，还要继续看：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- 最新的 `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+*.swift`

## 3. Product Guardrails

这些规则不要被改坏：

- 完全本地优先
- 不上传照片
- 不修改原图
- 生成一张新的成品图
- 主界面是模板校准中心，不是未来的批量工作台
- 预览必须继续绑定真实渲染/导出链路
- 功能扩张速度不能超过真实 import-render-export pipeline 的承载能力

时间锚点相关共识：

- 智能模块只输出时间结果，不输出整句文案
- 用户自己组合前后文

例子：

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_countdown_text}}` -> `还有86天`

## 4. Current Architecture

### MainView

`MainView.swift` 已经不是巨型单文件视图，而是很薄的 coordinator shell。

当前方向：

- 状态留在 `MainView`
- 持久化和副作用仍由 `MainView` 协调
- 展示密集区拆到 `MainView+*.swift`
- 不把业务逻辑藏进纯装饰子视图

必须保留的交互行为：

- 模块插入必须进入当前明确选中的自定义区域
- 不要恢复“默认插到右下角”的旧兜底逻辑
- 模板切换 / 重置 / 改名后，要刷新 composer 编辑状态
- 不要破坏 drag-sort 和本地编辑状态同步

### Share / External Intake

当前外部接入主线已经具备：

- app-group 共享容器
- 共享默认配置快照
- `ExternalIntake` 托管收件箱
- 主 app 侧 flush -> batch queue
- iOS 分享扩展写入共享收件箱

关键边界：

- `ExternalIntake` 是纯临时存储，不是长期缓存
- 只能清时光记自己复制进去的托管文件
- 绝不能碰用户原始照片路径
- 写回系统相册的成品图不能当缓存处理

### iOS Readiness

当前真实状态不是“未来可以做 iOS”，而是已经具备基础：

- `PhotoMemoiOS` 可构建
- `PhotoMemoShareExtension` 可构建
- 分享扩展的编译面已缩到小型共享核心

已知结果：

- `PhotoMemoShareExtension.SwiftFileList` 当前约 `19` 行
- 说明扩展 target 已经不再拖进 `MainView`、预览视图、模板视图、权限/导出/队列等主 app 责任面

## 5. Key Files

### Product / state docs

- `AI.md`
- `AI_CONTEXT.md`
- `AGENTS.md`
- `HANDOFF.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/IOS_READINESS_2026-06-19.md`
- `Docs/IOS_NEXT_SPRINT_2026-06-19.md`
- `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- `Docs/BATCH_TASK_SYSTEM_DESIGN.md`
- `Docs/DEVELOPMENT_PLAN.md`
- `CHANGELOG.md`

### Main editor

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerSession.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplateEditingActions.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

### Shared intake / iOS

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift`
- `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoBackgroundStatusService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSBackgroundExecutionService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoBackgroundLiveActivityPayload.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityBridgeService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoiOSLiveActivityDriverService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Activity/PhotoMemoLiveActivityPresentation.swift`
- `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSBackgroundStatusSheet.swift`

### Render / export / metadata

- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`

## 6. Development Environment

默认工作目录：

- `/Users/rui/Desktop/PhotoMemo`

已验证可用的构建命令：

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Git 同步信息：

- 当前默认远端：`origin`
- 当前主分支：`main`

## 7. Available Skills

### 项目内 skills

位于：`/Users/rui/Desktop/PhotoMemo/.codex/skills`

- `activitykit`
- `background-processing`
- `ios-simulator`
- `photokit`
- `photomemo-exif`
- `photomemo-product-manager`
- `photomemo-release-manager`
- `photomemo-renderer`
- `photomemo-swiftui-reviewer`
- `swift-testing`
- `swiftui-patterns`

这批新增的项目本地 skills，主要用于补强时光记的 iPhone 方向开发：

- `photokit`：相册读取、权限、选择器、保存链路
- `background-processing`：分享入口后的后台任务、继续处理、取消与恢复
- `activitykit`：灵动岛 / 锁屏进度展示
- `swiftui-patterns`：主界面状态归位、视图拆分、MV 风格
- `swift-testing`：后续单测改用更现代的 Swift Testing
- `ios-simulator`：后续 iPhone 模拟器调试、权限预置、推送/定位模拟

补充说明：

- 这些 skills 已经安装到项目目录，可被后续会话直接读取
- 但当前已经开启的旧会话，通常不会自动刷新顶部可用 skill 列表
- 如果想让它们以“会话内已安装 skill”的形式被自动识别，通常需要重启 Codex 或开启新会话

### 通用开发 skills

位于：`/Users/rui/.codex/skills`

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

建议工作节奏：

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

## 8. Current Priorities

现在更值得继续的方向，不是盲目加功能，而是：

1. 分享入口真实手动回归：
   - `1张`
   - `多张`
   - `部分失效`
   - `重复来源`
2. 继续补强外部接入和后台处理的异常反馈
3. 保持 `MainView` 继续做 coordinator，不回退成巨型视图
4. 继续保证预览、渲染、导出、元数据保留的一致性
5. 在不破坏现有主链的前提下推进 iPhone 工作流
6. 保证 share-extension / ExternalIntake 来源的失败项可以保留源文件并重试，而不是失败后直接丢失重试机会
7. 继续沿着 `时光记BackgroundStatusService` 这类中间层推进 iPhone 进度能力，而不是让 ActivityKit 或 iPhone UI 直接耦合 `BatchQueueStore`
8. iPhone 端的后台状态优先通过独立入口或 sheet 呈现，不把进度内容重新塞回主编辑内容区
9. iPhone 主 app 在队列处理中进入后台时，优先保持系统标准 background-task 托底，而不是先把复杂 BGTaskScheduler / Live Activity 强塞进主链
10. 如果继续做灵动岛/锁屏进度，优先接 `PhotoMemoiOSLiveActivityBridgeService`，不要让 ActivityKit 直接读取 `BatchQueueStore`
11. 现在 app 侧已经有 `PhotoMemoiOSLiveActivityDriverService`，后续更适合补 widget / Live Activity UI target，而不是重新发明 request/update/end 生命周期
12. 当前新的 Live Activity 锁屏 / 灵动岛展示壳已经接入独立的 `PhotoMemoWidgetExtension` target，并已验证能随 `PhotoMemoiOS` 一起构建和嵌入

## 9. Verification Expectations

对于有意义的 UI、架构、分享入口、权限或导出改动：

- 结束前至少跑一次相关构建
- 明确说明验证了什么
- 明确说明没有手测什么

重点不要只说“看起来没问题”。

## 10. Good Next Prompt For Another AI

如果后续你想让别的 AI 快速接手，可以直接给它类似这样的提示：

```text
项目路径是 /Users/rui/Desktop/PhotoMemo。
先按 AGENTS.md 的 startup routine 读取 README.md、AI.md、AI_CONTEXT.md、HANDOFF.md、AGENTS.md、Docs/CURRENT_STATUS.md，并检查 git status。
保持时光记作为 local-first 的模板校准中心，不修改原图。
继续沿着当前产品方向开发，优先遵循 /spec -> /plan -> /build -> /test -> /review。
如果涉及主编辑流，检查 MainView.swift 和最新 MainView+*.swift；
如果涉及分享入口或 iOS，优先检查 ExternalIntake、PhotoMemoAppRuntime、SharedBatchConfigurationSnapshotService、PhotoMemoShareExtensionIntakeService。
不要改变已经明确保留的交互行为。
```

## 11. Last Reminder

后续任何 AI 工具都不要默认认为：

- 这是一个云产品
- 可以随意重编码图片
- 可以为了“兼容更多来源”而牺牲 EXIF
- 主界面应该变成后台进度面板
- 智能模块应该替用户自动写整句文案

如果拿不准，先回到：

- `AGENTS.md`
- `AI_CONTEXT.md`
- `HANDOFF.md`
- `Docs/CURRENT_STATUS.md`

这四份文档里校准方向。
