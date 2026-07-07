# Service 分析

## 总判断

如果说 Repository 层目前偏薄，那么 Service 层就是时光记当前复杂度最集中的地方之一。

尤其值得优先理解的 6 个 service / store 是：

- `PhotoImportService`
- `PhotoMetadataReader`
- `RecordCardBuildService`
- `BatchProcessingCoordinator`
- `BatchQueueStore`
- `SettingsService`

## 1. PhotoImportService

文件：

- [PhotoImportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift)

### 职责

- 接受 URL 或 Data
- 准备临时导入文件
- 读取图像源
- 结合 metadata reader 生成 `SelectedPhoto`

### 为什么重要

它是生产 pipeline 的最前面一段真实入口。

### 扩展点

- 支持类型判断
- source info 保留
- 导入文件准备策略

## 2. PhotoMetadataReader

文件：

- [PhotoMetadataReader.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift)

### 职责

- 读取 `CGImageSource` 属性
- 解析 TIFF / EXIF / GPS
- 归一化为 `PhotoMetadata`

### 为什么重要

它是时光记的事实入口之一。

如果这里解析不到，后面很多表达都无从谈起。

### 扩展点

- 新 metadata 字段
- 时间解析策略
- GPS / 设备信息补充

## 3. RecordCardBuildService

文件：

- [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift)

### 职责

- 生成 `RecordCard`
- 解析 anchor result
- 载入 relationship label
- 在非 share-extension 路径上注入 `memoryModule`
- 生成 export description

### 为什么重要

它是“配置世界”和“最终输出对象世界”的桥。

### 风险

- 很多新需求都会想往这里塞
- 但它应该只负责组合，不应该无边界吸纳 UI 规则

## 4. BatchProcessingCoordinator

文件：

- [BatchProcessingCoordinator.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift)

### 职责

- 在批处理语境里串起：
  - import
  - build
  - export
  - save back
  - cleanup

### 为什么重要

它是生产 pipeline 的串联器之一。

### 特点

- 它不保存长期状态
- 它负责执行步骤组合

## 5. BatchQueueStore

文件：

- [BatchQueueStore.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift)

### 职责

- 持有 jobs 和 processing 状态
- 管理默认 snapshot
- enqueue / retry / cancel
- resume / persist / history / notification

### 为什么重要

它是“生产状态中心”，不是普通 service。

### 判断

如果你改的是队列真实行为，几乎一定要读它。

## 6. SettingsService

文件：

- [SettingsService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift)

### 职责

- 默认配置持久化
- anchors / template / badge / subject / editor state
- 构建 batch snapshot
- 兼容旧设置语义

### 为什么重要

这是当前配置真相最重的基础层之一。

### 风险

- 功能多
- 历史兼容多
- 很容易因为新增字段而引发 bootstrap 或 snapshot 行为变化

## 一个重要观察

### Service 层已经开始分化成三种角色

#### 1. 纯处理服务

例如：

- `PhotoMetadataReader`
- `PhotoImportService`

#### 2. 组合桥服务

例如：

- `RecordCardBuildService`
- `BatchProcessingCoordinator`

#### 3. 状态 / 持久化核心

例如：

- `BatchQueueStore`
- `SettingsService`

这三种角色的维护策略应该不同，不能都按“普通 service”处理。

## 后续开发建议

### 新增 metadata / import 能力

先看 `PhotoImportService` 和 `PhotoMetadataReader`。

### 新增表达或 card 组合能力

先看 `RecordCardBuildService`。

### 新增批处理行为

先看 `BatchQueueStore` 和 `BatchProcessingCoordinator`。

### 新增默认配置字段

先看 `SettingsService`，再回推 repository / coordinator / view。
