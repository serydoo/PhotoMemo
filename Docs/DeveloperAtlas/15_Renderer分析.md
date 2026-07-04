# Renderer 分析

## 总判断

Renderer 当前仍然是 PhotoMemo 最终视觉输出的关键实现层，但它不应该继续变成新的布局真相中心。

当前更准确的理解是：

```text
RecordCard
-> RecordCardRenderer
-> ClassicWhiteCardRenderer / ImmersWhiteCardRenderer
-> RecordCardExportService
-> output image
```

## 核心文件

- [RecordCardRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift)
- [ClassicWhiteCardRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift)
- [ClassicWhiteRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift)
- [ImmersWhiteRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift)
- [RenderTheme.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/RenderTheme.swift)
- [RendererConstants.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/RendererConstants.swift)
- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)

## 1. `RecordCardRenderer`

### 它是什么

`RecordCardRenderer` 是 renderer 路由层。

它根据 `TemplatePreset.renderLayout` 决定走：

- Classic White
- Immers White

### 它为什么存在

它把“选择具体 renderer”的逻辑集中起来，避免 export service 直接知道每种卡片布局的实现细节。

### 风险

这里适合增加 renderer 路由，不适合写具体布局规则。

## 2. Classic White renderer

### 关键文件

- [ClassicWhiteCardRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteCardRenderer.swift)
- [ClassicWhiteRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift)
- [RenderTheme.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/RenderTheme.swift)

### 它负责什么

- 上方照片显示
- 下方信息栏
- 左中右三段区域
- badge / logo 中间模块
- 文本 module 渲染

### 重要结构

`ClassicWhiteCardRenderer.layoutMetrics(...)` 会根据总宽度和 theme 计算：

- left module width
- center module width
- right module width
- content height

### 风险

Classic White 当前仍然有 renderer 内的布局计算。

这在 V1 是现实存在，但 V2 方向里，新的布局真相应该逐步进入 Layout Engine，而不是继续堆进 renderer。

## 3. Immers White renderer

### 关键文件

- [ImmersWhiteRenderer.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift)

### 它负责什么

- Immers-inspired 白边信息栏
- portrait / landscape 两套信息栏比例
- logo、divider、左右文本列的位置与比例

### 重要结构

它有一套 `Layout` ratio 模型，例如：

- border to image height ratio
- horizontal / vertical padding ratio
- left / right column width ratio
- logo / divider / font ratio

### 风险

这是当前最容易继续堆视觉调参的区域。

如果只是修 V1 输出 bug，可以按当前结构维护；如果是新布局语言，应该先走 Research / Specification / Layout Engine。

## 4. `RenderTheme` 和 `RendererConstants`

### `RenderTheme`

更像 Classic White 的主题 token 容器：

- bottom bar
- color
- grid
- typography
- spacing
- divider
- center module

### `RendererConstants`

更像一组跨 renderer 或历史布局常量：

- grid
- color palette
- typography
- border
- slot spec
- compact information bar spec

### 风险

这两个文件容易被当成“随手放常量”的地方。

更稳的方式是：

- 现有 renderer bug 修复可以局部改
- 新布局规则不要直接加成 renderer 常量

## 5. Export 和 renderer 的关系

### 关键文件

- [RecordCardExportService.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift)

### 调用关系

```text
RecordCardExportService.export(...)
-> outputPixelSize(...)
-> RecordCardRenderer(image:card:)
-> ImageRenderer
-> CGImageDestination
-> metadata patch / file date
```

### 它负责什么

- 创建输出尺寸
- 调 SwiftUI renderer
- 生成 CGImage
- 写入文件
- 保留和修正 metadata
- 设置文件日期

### 风险

这里不是单纯“画图”。

它同时关系到：

- 输出图像尺寸
- 临时文件
- metadata 保留
- Photo Library 写回前的文件状态

## 6. 新增功能怎么判断要不要进 Renderer

### 可以考虑进 Renderer 的情况

- 修复当前视觉输出 bug
- 增加已有 preset 的小范围绘制支持
- 修正 preview / export 不一致
- 处理具体绘制实现问题

### 不应该直接进 Renderer 的情况

- 新布局系统
- 新语义 slot 设计
- 新 Memory 表达规则
- 新 metadata 选择规则
- 新产品概念

这些应该优先从：

- Memory Engine
- Presentation / Template
- Layout Specification
- future Layout Engine

开始。

## 7. 验证建议

Renderer 相关改动至少要考虑：

- portrait / landscape
- long text
- missing metadata
- custom logo / default logo
- export readback
- preview / export parity

## 结论

当前 renderer 是 V1 输出保真层，不是未来布局规则中心。

理解它时，要同时看：

- `RecordCard`
- `RecordCardRenderer`
- concrete renderer
- export service
- metadata writeback

只看 SwiftUI View 本身，会漏掉一半风险。
