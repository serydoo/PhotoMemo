# 开发入口（Developer GPS）

## 这一章怎么用

当你想新增一个功能时，不要先全局搜索。

先判断它属于下面哪一类，再从对应入口开始。

## 1. 想改 V1 页面表现

先看：

- [PhotoMemoiOSV1View.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSV1View.swift)
- [V1HomePageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1HomePageSurface.swift)
- [V1OutputPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1OutputPageSurface.swift)
- [V1SettingsPageSurface.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1SettingsPageSurface.swift)

适合的功能例子：

- 首页摘要显示
- V1 页面按钮和分组
- 输出页交互
- 设置页展示

## 2. 想改 V1 模块编辑或预览文本

先看：

- [V1PreviewCompositionEngine.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift)
- [V1DraftOrchestrationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftOrchestrationCoordinator.swift)
- [V1DraftMutationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1DraftMutationCoordinator.swift)
- [V1PreviewSyncCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewSyncCoordinator.swift)

适合的功能例子：

- 新增模块 token
- 调整预览显示值
- 改默认文本
- 调整区域预览更新逻辑

## 3. 想改默认配置保存 / 读取

先看：

- [V1ConfigurationApplyCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1ConfigurationApplyCoordinator.swift)
- [ConfigurationCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ConfigurationCoordinator.swift)
- [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)
- [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift)

适合的功能例子：

- 新的默认配置字段
- 保存相册目标
- 保存对象 / Preset 选择

## 4. 想改系统分享 / 批处理入口

先看：

- [PhotoMemoRootSceneView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift)
- [PhotoMemoAppRuntime.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift)
- [ExternalPhotoIntakeCenter.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift)
- [ShareCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/ShareCoordinator.swift)
- [QueueCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Coordinators/QueueCoordinator.swift)

适合的功能例子：

- 分享来源接单策略
- 队列生成逻辑
- 外部 URL 刷新
- intake 去重

## 5. 想改照片事实或导入支持

先看：

- [PhotoImportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift)
- [PhotoMetadataReader.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift)
- [PhotoMetadata.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift)

适合的功能例子：

- 新增 metadata 字段
- 输入图片支持判断
- 导入时源文件信息保留

## 6. 想改最终输出图像

先看：

- [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift)
- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)
- [PhotoLibraryExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift)

注意：

根据当前仓库规则，不要把新的布局真相继续塞进 renderer。

## 7. 想改对象编辑中心

先看：

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
- [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)

## 最后一个判断

如果一个功能你不知道该从哪开始，先问两句：

1. 这是“配置输入”问题，还是“生产输出”问题
2. 它属于 V1 页面、Configuration Center，还是共享 pipeline

大多数问题都会因此缩小到很少几个文件。
