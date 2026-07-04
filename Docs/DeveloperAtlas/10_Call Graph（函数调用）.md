# Call Graph（函数调用）

## 方法

本章不追求全仓库自动化函数图，而是先抓最有价值的 5 条真实调用链。

原因很简单：

- SwiftUI 页面层会产生大量低价值噪音
- 真正有开发价值的是“一个用户动作最终调用了哪些关键对象”

## 1. V1 预览刷新链

### 关键文件

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
- [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift)
- [V1PreviewSyncCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSyncCoordinator.swift)

### 调用链

```text
PhotoMemoiOSV1View.refreshPreview(for:)
-> previewRenderModel(...)
-> V1PreviewCompositionEngine.renderModel(...)
-> V1PreviewSyncCoordinator.refreshPreview(...)
-> ConfigurationSession.updateRegionPreview(...)
```

### 含义

这一链条说明：

- V1 页面并不自己持有最终 preview text 真相
- 它是先生成 `V1PreviewRenderModel`
- 再把 `displayText` 推到 `ConfigurationSession`

## 2. V1 配置应用链

### 关键文件

- [V1ConfigurationApplyCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift)
- [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift)
- [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)

### 调用链

```text
PhotoMemoiOSV1View.applyCurrentV1Configuration()
-> V1ConfigurationApplyCoordinator.apply(...)
-> resolveAlbumSelection(...)
-> saveConfiguration(...)
-> ConfigurationCoordinator.saveV1Configuration(...)
-> SettingsRepository / ConfigurationRepository
-> SettingsService
```

### 含义

这一链说明 V1 页面没有直接写 defaults，而是：

- 先解析输出目标
- 再生成保存请求
- 再经由 coordinator / repository 写入

## 3. 系统分享接单链

### 关键文件

- [PhotoMemoRootSceneView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift)
- [PhotoMemoAppRuntime.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift)
- [ShareCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift)

### 调用链

```text
PhotoMemoRootSceneView.onOpenURL / onReceive
-> PhotoMemoAppRuntime.refreshExternalIntakeState()
-> PhotoMemoAppRuntime.flushExternalRequests()
-> ProcessShareIntent.executeSynchronously()
-> ShareCoordinator.process(...)
-> QueueRepository.enqueue(...)
-> BatchQueueStore.enqueue(...)
```

### 含义

系统分享真正接进生产不是直接靠 View，而是运行时和 intake / queue 链路驱动。

## 4. 生产构建链

### 关键文件

- [BatchProcessingCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift)
- [PhotoImportService.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift)
- [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift)

### 调用链

```text
BatchProcessingCoordinator.importPhoto(...)
-> PhotoImportService.importPhotoOffMainThread(...)
-> PhotoMetadataReader.read(...)

BatchProcessingCoordinator.buildCard(...)
-> RecordCardBuildService.buildCard(...)
-> baseCard(...)
-> ProductionMemoryResolver.resolve(...)
```

### 含义

这说明生产处理链已经把：

- metadata
- memory
- card build

串成了一个真实路径。

## 5. 最终导出链

### 关键文件

- [ExportCoordinator.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Coordinators/ExportCoordinator.swift)
- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)
- [PhotoLibraryExportService.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift)

### 调用链

```text
ExportCoordinator.exportCard(...)
-> RecordCardExportService.exportToTemporaryFile(...)

ExportCoordinator.saveRenderedPhoto(...)
-> PhotoLibraryRepository.saveRenderedPhoto(...)
-> PhotoLibraryExportService.saveImageResult(...)
```

## 结论

### View 层真正值钱的不是直接调用，而是入口动作

越往下看，越会发现：

- View 负责触发
- Coordinator 负责收口
- Repository 负责边界
- Service 负责真实处理

### 后续最值得补图的函数

下一轮最值得继续细化的是：

- `RecordCardBuildService.baseCard(...)`
- `ShareCoordinator.process(...)`
- `ConfigurationSession.selectSubject(...)`
- `V1DraftMutationCoordinator.updateDraft(...)`
