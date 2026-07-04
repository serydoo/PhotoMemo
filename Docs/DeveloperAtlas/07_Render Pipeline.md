# Render Pipeline

## 为什么这一章重要

PhotoMemo 的产品核心不是“表单填写”，而是把一张照片转换成一张带记忆表达的新图像。

所以无论是 V1 还是 V2，真正要守住的主链路都是 Render Pipeline。

## 当前可见生产链路

当前从源码能读到的主链路接近：

```text
source URL / batch task
-> PhotoImportService
-> PhotoMetadataReader
-> SelectedPhoto
-> RecordCardBuildService
-> ProductionMemoryResolver
-> RecordCard
-> RecordCardExportService
-> PhotoLibraryExportService
```

关键文件：

- [PhotoImportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift)
- [PhotoMetadataReader.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift)
- [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift)
- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)
- [PhotoLibraryExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift)

## 各阶段职责

### 1. Import

由 [PhotoImportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift) 负责。

它做的事包括：

- 接受 URL 或 Data
- 准备可读文件
- 读取原图
- 建立 `SelectedPhoto`
- 交给 metadata reader 解出事实信息

### 2. Metadata

由 [PhotoMetadataReader.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift) 负责。

它主要从：

- TIFF
- EXIF
- GPS

中读取事实，并归一化成 `PhotoMetadata`。

### 3. Card Build

由 [RecordCardBuildService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift) 负责。

它会组合：

- template
- metadata
- anchor
- badge
- memory payload
- export description

这里是从“事实 + 配置”进入“可渲染卡片对象”的关键桥梁。

### 4. Memory Resolve

在当前生产路径中，`RecordCardBuildService` 会调用 `ProductionMemoryResolver`。

这说明：

- Memory Engine 已开始进入真实 pipeline
- 但它还不是整个工程唯一中心

### 5. Export / Render

由 [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift) 负责主要输出逻辑。

再由 [PhotoLibraryExportService.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift) 写回系统相册。

## 以后新增功能怎么判断落点

### 新增 Metadata 展示项

优先看：

- `PhotoMetadata`
- `PhotoMetadataReader`
- `RecordCardBuildService`
- 模板变量或 card context

### 新增 Memory 语义

优先看：

- `MemoryEngine/`
- `ProductionMemoryResolver`
- `ConfigurationSnapshot`
- `MemorySubject`

### 新增输出样式或绘制细节

优先看：

- `RecordCardExportService`
- `Renderers/`

但要先确认是否会违反“Renderer 不再拥有布局真相”的 V2 规则。

## 相关图

- [04_Render_Pipeline.md](/Users/rui/Desktop/PhotoMemo/Docs/DeveloperAtlas/diagrams/04_Render_Pipeline.md)
