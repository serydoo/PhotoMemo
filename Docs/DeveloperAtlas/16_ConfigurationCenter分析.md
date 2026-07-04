# ConfigurationCenter 分析

## 总判断

Configuration Center 不是“另一个设置页”。

它是当前仓库中最明确承载 IA-002 冻结结构的区域，其核心职责是：

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

## 核心文件

- [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift)
- [ConfigurationSession.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationSession.swift)
- [ConfigurationCenterState.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/ConfigurationCenterState.swift)
- [InteractiveMemoryCard.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/MemoryCard/InteractiveMemoryCard.swift)
- [ConfigurationCenterRegionDraftStore.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenterRegionDraftStore.swift)

## 1. 页面结构

从 [ConfigurationCenteriOSView.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift) 可以读出一个很清楚的结构：

### 顶部

- top preview
- profile / preset 相关入口

### 左侧

- sidebar
- subject / card / memory module / output / guide 等入口

### 右侧

- detail surface
- 对当前选中对象进行编辑

这不是传统表单页，而是一个对象驱动的编辑中心。

## 2. `ConfigurationSession` 是对象中心

`ConfigurationSession` 持有：

- `state: ConfigurationCenterState`
- `presentationState`

它负责的不是单纯 ViewModel 文本，而是：

- 当前选中 subject
- 当前选中 preset
- 当前 card region
- 当前 selected block
- region preview text

从 `selectSubject(...)`、`selectRegion(...)`、`updateSelectedSubject(...)` 这些方法可以看出，它已经承担了对象级状态协调责任。

## 3. `ConfigurationCenterState` 是当前真相快照

`ConfigurationCenterState` 的职责更偏“当前中心状态数据”：

- subjects
- presets
- selection
- token library
- decorations
- preview texts

它不负责具体页面交互，而是承载当前对象世界的可计算真相。

## 4. `ConfigurationCenterRegionDraftStore` 是局部编辑草稿层

这是一个很关键的设计点。

它说明 Configuration Center 没有把所有输入中的“编辑过程态”都塞进 `ConfigurationSession`。

它单独维护：

- region draft text
- inserted modules
- continuation text
- 当前选中的 region configuration ID
- 配置名称

这使得 Configuration Center 形成了比较健康的分层：

```text
ConfigurationSession
= 当前对象真相

ConfigurationCenterRegionDraftStore
= 局部编辑草稿
```

## 5. `InteractiveMemoryCard` 的位置

`InteractiveMemoryCard` 不是一个普通 preview widget。

它是 Configuration Center 的核心交互表面之一，作用是：

- 展示真实 Memory Card 结构
- 承接 region selection
- 连接对象编辑中心

所以它的价值不只是“显示卡片”，而是“让对象编辑围绕卡片展开”。

## 6. 与 V1 的边界

### V1 更像产品工作表面

V1 页面更偏：

- 一次性配置和预览
- 输出目标
- 当前产品壳

### Configuration Center 更像对象管理中心

Configuration Center 更偏：

- subject
- preset
- region
- block
- object inspector

### 重要结论

不要把 Configuration Center 误改成另一个 V1 页面，也不要把 V1 页面强行重塑成 Configuration Center 内部结构。

它们目前是并存关系，不是简单替代关系。

## 7. 以后新增功能时怎么落

### 如果你新增的是对象级长期配置

优先考虑放进 Configuration Center。

例如：

- 新 subject 属性
- 新 preset 行为
- 新 card region 对象能力

### 如果你新增的是当前 V1 产品体验

优先考虑留在 V1 surface。

例如：

- V1 页面流程优化
- 当前输出页交互
- 当前首页摘要

## 当前风险

- 不要重开 IA-002 架构
- 不要把 sidebar / card / inspector 三段关系打散
- 不要把大量局部编辑临时态直接并进 `ConfigurationSession`
