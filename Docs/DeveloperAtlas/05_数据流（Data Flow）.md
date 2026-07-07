# 数据流（Data Flow）

## 先看最重要的一句话时光记当前最关键的数据流不是“某个 View 持有什么变量”，而是：

```text
Photo / URL
-> Import
-> Metadata
-> Configuration Snapshot
-> RecordCard Build
-> Renderer / Export
-> Save Back / Queue State
```

V1 页面和 Configuration Center 更多是在影响这条链路里的“配置输入”和“预览表现”。

## 数据流一：V1 页面预览流

### 目标

用户在 V1 页面修改模块、时间锚点、对象、Logo 等内容时，预览文本和预览卡片如何更新。

### 主链路

```text
PhotoMemoiOSV1View state
-> V1EditorDraft / regionDrafts
-> V1DraftOrchestrationCoordinator
-> V1PreviewCompositionEngine
-> V1PreviewRenderModel
-> V1PreviewSyncCoordinator
-> ConfigurationSession.regionPreviewTexts
```

关键文件：

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
- [V1DraftOrchestrationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftOrchestrationCoordinator.swift)
- [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift)
- [V1PreviewSyncCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSyncCoordinator.swift)

## 数据流二：默认配置保存流

### 目标

用户在 V1 中“应用当前配置”时，设置如何变成可持久化默认状态。

### 主链路

```text
PhotoMemoiOSV1View
-> V1ConfigurationApplyCoordinator
-> ConfigurationCoordinator
-> SettingsRepository
-> SettingsService
-> UserDefaults / stored state
```

关键文件：

- [V1ConfigurationApplyCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift)
- [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift)
- [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)
- [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift)

## 数据流三：系统分享接单流

### 目标

外部照片如何进入时光记后续处理链路。

### 主链路

```text
system share / open url
-> PhotoMemoRootSceneView / Share Extension
-> ExternalPhotoIntakeCenter
-> ShareCoordinator
-> QueueRepository / BatchQueueStore
-> BatchProcessingCoordinator
```

关键文件：

- [PhotoMemoRootSceneView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift)
- [ExternalPhotoIntakeCenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift)
- [ShareCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift)
- [BatchQueueStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift)

## 数据流四：生产构建与导出流

### 目标

真正生成结果图像时，数据如何流动。

### 主链路

```text
Batch task / SelectedPhoto
-> PhotoImportService
-> PhotoMetadataReader
-> RecordCardBuildService
-> ProductionMemoryResolver
-> RecordCardExportService
-> PhotoLibraryExportService
```

关键文件：

- [PhotoImportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift)
- [PhotoMetadataReader.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift)
- [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift)
- [BatchProcessingCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift)
- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)
- [PhotoLibraryExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift)

## 目前最值得记住的判断

### V1 不直接等于最终生产流

V1 页面负责很多配置和预览，但最终生产流更多由 `Queue / Import / Build / Export` 支持。

### 配置流和生产流已经开始分离

这是一个好现象。

因为它意味着：

- 页面可以改得更轻
- 批处理可以更稳定
- Configuration Snapshot 可以逐渐成为真正冻结上下文

## 相关图

- [03_数据流总图.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/diagrams/03_数据流总图.md)
- [04_Render_Pipeline.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/diagrams/04_Render_Pipeline.md)
