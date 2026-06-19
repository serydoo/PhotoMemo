# PhotoMemo AI Guide

这份文档用于帮助后续任何 AI 工具快速接手 PhotoMemo 项目，不依赖历史聊天记录，也不需要先靠猜来理解项目方向。

如果你是新的 AI 会话，建议把这份文档当作第一入口，再按里面的顺序继续读取其他文件。

## 1. Project Snapshot

- 项目路径：`/Users/rui/Desktop/PhotoMemo`
- 当前主分支：`main`
- 远端仓库：`git@github.com:serydoo/PhotoMemo.git`
- 当前产品形态：
  - macOS 主应用：模板校准中心
  - iOS 基础：`PhotoMemoiOS` target 已可编译
  - 分享扩展：`PhotoMemoShareExtension` target 已可编译

一句话：

PhotoMemo 是一个 **local-first、基于 EXIF 与时间锚点生成照片记忆信息卡的 Apple 平台应用**。

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

1. `README.md`
2. `AI_CONTEXT.md`
3. `HANDOFF.md`
4. `AGENTS.md`
5. `Docs/CURRENT_STATUS.md`
6. `git status`

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
- 只能清 PhotoMemo 自己复制进去的托管文件
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
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`

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

- `photomemo-exif`
- `photomemo-product-manager`
- `photomemo-release-manager`
- `photomemo-renderer`
- `photomemo-swiftui-reviewer`

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
保持 PhotoMemo 作为 local-first 的模板校准中心，不修改原图。
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
