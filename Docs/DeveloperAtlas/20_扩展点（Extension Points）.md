# 扩展点（Extension Points）

## 这一章怎么用

当你想到一个新功能时，先在这里找它属于哪一类。

目标是减少“全项目搜索一圈再凭感觉改”的情况。

## 1. 新增 V1 预览模块

### 优先入口

- [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift)
- [V1ModuleLibraryPresenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ModuleLibraryPresenter.swift)
- [V1ModuleUsageTracker.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ModuleUsageTracker.swift)

### 注意

新增模块要同时考虑：

- 用户看到的标题
- 预览 display value
- 保存到 template 的 token value
- module library 分类

## 2. 新增 metadata 字段

### 优先入口

- [PhotoMetadata.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift)
- [PhotoMetadataReader.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift)
- [MetadataContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift)
- [CardVariableProvider.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift)

### 注意

metadata 新字段不是只加一个变量名。

通常要同时检查：

- 是否能从 ImageIO 读到
- 是否需要 normalized
- 是否进入 template context
- 是否影响 export description

## 3. 新增 Memory Subject 能力

### 优先入口

- [MemorySubject.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models/MemorySubject.swift)
- [MemorySubjectAdapter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift)
- [MemoryExpressionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift)
- [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)

### 注意

先判断这是：

- subject identity
- relationship
- time anchor
- expression behavior
- decoration

不同分类对应不同落点。

## 4. 新增对象编辑中心能力

### 优先入口

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
- [ConfigurationCenterState.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterState.swift)
- [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
- [ConfigurationCenterRegionDraftStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionDraftStore.swift)

### 注意

不要打散：

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

如果只是局部编辑草稿，优先考虑草稿 store；如果是对象真相，才考虑 session / state。

## 5. 新增默认配置字段

### 优先入口

- [V1ConfigurationApplyCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift)
- [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift)
- [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)
- [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift)
- [BatchProcessing.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift)

### 注意

新增默认配置字段常常需要考虑：

- V1 保存
- bootstrap 读取
- shared snapshot
- batch snapshot
- share extension 是否需要

## 6. 新增批处理 / 分享行为

### 优先入口

- [ExternalPhotoIntakeCenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift)
- [ShareCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift)
- [QueueRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/QueueRepository.swift)
- [BatchQueueStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift)
- [BatchProcessingCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift)

### 注意

先分清是在改：

- 接单
- 去重
- 入队
- 执行
- 保存
- 通知

## 7. 新增输出样式

### 优先入口

- [TemplatePreset.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/TemplatePreset.swift)
- [RecordCardRenderer.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift)
- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)

### 注意

新输出样式的风险很高。

如果它是新布局语言，先走：

```text
Research
-> Specification
-> Layout Engine
-> Renderer
```

## 总结

扩展点的核心判断不是“文件在哪里”，而是功能属于哪条链：

- UI preview
- metadata
- memory
- configuration
- batch / share
- render / export
