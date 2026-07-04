# 状态流（State Flow）

## 总判断

PhotoMemo 当前的状态流不是单一 store 架构。

从 V1 和 Configuration Center 的实际实现看，更像是三种状态系统并存：

1. V1 页面本地 `@State`
2. `ConfigurationSession` 这种对象中心状态
3. `BatchQueueStore` 这种共享处理状态

理解这三种状态谁负责什么，比记单个变量更重要。

## 一、V1 页面状态流

### 核心文件

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
- [V1DraftMutationCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftMutationCoordinator.swift)
- [V1DraftOrchestrationCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftOrchestrationCoordinator.swift)
- [V1PreviewSyncCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSyncCoordinator.swift)
- [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)

### 主要状态分层

#### 1. 页面壳状态

直接放在 `PhotoMemoiOSV1View` 里的状态很多，主要包括：

- 当前 tab
- 展开面板
- 当前编辑 region
- 输出目标与相册选择
- Logo 选择
- Bootstrap 标记
- 诊断与提示信息

这类状态的特点是：

- 强 UI 性
- 大多不应直接参与生产 pipeline
- 很容易越长越大

#### 2. 草稿编辑状态

最重要的是：

- `regionDrafts`
- `activeTextItemIDs`

它们通过 `V1DraftMutationCoordinator` 和 `V1DraftOrchestrationCoordinator` 被更新和转换。

这部分状态负责：

- 当前 region 的草稿文本
- 插入模块后的草稿结构
- 当前激活文本 item

这说明 V1 编辑不是“一个字符串直接改到底”，而是：

```text
UI 输入
-> Draft mutation
-> Draft orchestration
-> Preview draft / render model
```

#### 3. 预览同步状态

`V1PreviewSyncCoordinator` 并不持有复杂状态，它更像一个桥：

```text
V1PreviewRenderModel.displayText
-> ConfigurationSession.regionPreviewTexts
```

它的价值在于把 V1 预览结果同步进 `ConfigurationSession`。

这意味着：

- `ConfigurationSession` 在当前 V1 路径里也被当作一个预览文本承载层
- V1 页面不是完全孤立于 Configuration Center 状态体系

### V1 状态流总图

```text
PhotoMemoiOSV1View @State
-> V1DraftMutationCoordinator
-> V1DraftOrchestrationCoordinator
-> V1PreviewCompositionEngine
-> V1PreviewRenderModel
-> V1PreviewSyncCoordinator
-> ConfigurationSession.regionPreviewTexts
```

## 二、Configuration Center 状态流

### 核心文件

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
- [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
- [ConfigurationCenterState.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterState.swift)
- [ConfigurationCenterRegionDraftStore.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionDraftStore.swift)

### 状态核心

`ConfigurationCenteriOSView` 自己也有本地 `@State`，例如：

- 当前 panel
- 是否重命名
- `regionDraftStore`

但真正的核心状态中心是 `ConfigurationSession`：

- `state: ConfigurationCenterState`
- `presentationState`

其中 `ConfigurationCenterState` 主要承载：

- subjects
- selectedSubjectID
- memoryPresets
- selectedMemoryPresetID
- cardSelection
- selectedBlockID
- tokenLibrary
- decorations
- `regionPreviewTexts`

这是一种明显的“对象编辑中心状态”，而不是临时页面输入状态。

### `ConfigurationCenterRegionDraftStore` 的位置

这个对象很关键，因为它说明 Configuration Center 也存在局部编辑草稿态，但它没有直接塞进 `ConfigurationSession`。

它主要管：

- 某个 region 当前选中的配置 ID
- 某个 region 的草稿文本
- 已插入模块
- continuation 文本
- 配置名称

因此 Configuration Center 的状态架构更像：

```text
ConfigurationSession
负责对象级当前真相

ConfigurationCenterRegionDraftStore
负责局部编辑草稿
```

## 三、批处理与后台状态流

### 核心文件

- [BatchQueueStore.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift)
- [PhotoMemoAppRuntime.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift)
- [PhotoMemoiOSHomeView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSHomeView.swift)

### 核心状态

`BatchQueueStore` 是一个共享处理状态中心，持有：

- `jobs`
- `isProcessing`
- `activeJobID`
- `activeTaskID`
- `lastErrorMessage`
- `defaultConfigurationSnapshot`

这类状态的特点是：

- 会影响真实生产行为
- 需要持久化或恢复
- 不是单纯 UI 层状态

### 为什么它重要

它说明 PhotoMemo 已经不只是“点一下预览”的 app。

它已经有：

- 队列
- 后台执行
- 默认配置快照
- resume / persistence / history / notification

## 四、最重要的状态边界结论

### 1. 不是所有状态都该进入 `ConfigurationSession`

V1 里大量状态只是页面协调态，不该盲目并入对象中心状态。

### 2. 不是所有状态都该留在 View

像草稿编辑和预览同步，已经证明适合下沉到 `V1Draft*Coordinator`。

### 3. `BatchQueueStore` 属于生产状态，不是 UI 状态

它改动时要按“生产后果”思考，而不是按“页面显示”思考。

## 新增功能时的状态判断

先问：

1. 这是页面临时态
2. 这是对象编辑真相
3. 这是批处理共享态
4. 这是持久化默认配置

不同答案，对应的修改入口完全不同。
