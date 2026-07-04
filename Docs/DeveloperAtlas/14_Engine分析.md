# Engine 分析

## 总判断

当前仓库里有两类 Engine：

1. 较早期的通用处理引擎，位于 `Engines/`
2. V2 方向更明确的 `MemoryEngine/`

这两类引擎并存，正好反映了仓库处在 V1 到 V2 的过渡阶段。

## 一、`Engines/` 目录的角色

目录：

- [/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Engines](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Engines)

主要包括：

- `AnchorEngine`
- `BadgeLibrary`
- `CardTextBlockEngine`
- `TemplateEngine`
- `TemplatePresetEngine`
- `TemplateVariableEngine`

### 特征

- 更接近 V1 的表达和模板处理基础层
- 功能边界相对清楚
- 不强调“对象世界”，更强调“文本 / 模板 / 计算”

## 二、`MemoryEngine/` 目录的角色

目录：

- [/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/MemoryEngine](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/MemoryEngine)

主要包括：

- `MemoryExpressionEngine`
- `MemoryExpressionPreviewResolver`
- `MemorySubjectAdapter`
- `MemorySubjectStrategies`
- `MemoryVariableProvider`
- `ProductionMemoryResolver`
- `BirthdayAgeCalculator`
- `BirthdayAgeExpressionProvider`

### 特征

- 更接近 V2 的 Memory Engine 方向
- 明确围绕 `MemorySubject`、`ConfigurationSnapshot`、`MemoryExpressionContext`
- 已开始进入真实生产路径

## 三、最关键的几个 Engine

### 1. `AnchorEngine`

文件：

- [AnchorEngine.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift)

#### 负责什么

- 根据 `Anchor` 和 `photoDate`
- 计算 `AnchorResult`
- 输出年龄、时长、倒计时、里程碑等文本与数值

#### 当前地位

- 这是当前时间锚点能力的基础引擎之一
- 仍然很重要

### 2. `TemplateVariableEngine`

文件：

- 当前在 `Engines/` 目录中

#### 负责什么

- 把模板字符串和 `MetadataContext` 渲染成最终文本

#### 当前地位

- 它仍然是从 metadata / card context 走向文本输出的重要桥

### 3. `MemorySubjectAdapter`

文件：

- [MemorySubjectAdapter.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemorySubjectAdapter.swift)

#### 负责什么

- 把旧 `PersonalProfile + Anchor`
- 适配成新的 `MemorySubject`

#### 为什么重要

- 这是 IA-003A 风格的典型桥接点
- 它让旧配置层可以进入新 memory 世界

### 4. `ProductionMemoryResolver`

文件：

- [ProductionMemoryResolver.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/MemoryEngine/ProductionMemoryResolver.swift)

#### 负责什么

```text
PersonalProfile / Anchor / captureDate
-> MemorySubjectAdapter
-> ConfigurationSnapshotBuilder
-> MemoryExpressionEngine
-> ProductionMemoryPayload
```

#### 为什么重要

- 它是当前 Memory Engine 进入生产 build 路径的关键桥
- `RecordCardBuildService` 会用它生成 `memoryModule`

### 5. `MemoryExpressionEngine`

文件：

- [MemoryExpressionEngine.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionEngine.swift)

#### 负责什么

- 根据 `MemoryExpressionContext`
- 生成 `MemoryModule`
- 根据 anchor type definition 选择 calculator 和 expression provider

#### 为什么重要

- 它已经有了典型的 V2 方向结构：
  - subject strategy
  - output strategy
  - anchor type registry
  - semantic result

### 6. `MemoryExpressionPreviewResolver`

文件：

- [MemoryExpressionPreviewResolver.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryExpressionPreviewResolver.swift)

#### 负责什么

- 用一个默认 captureDate
- 快速生成 memory preview text

#### 为什么重要

- 它把 Memory Engine 从“生产路径”向“预览路径”延展了一步

## 四、当前 Engine 结构的意义

### 旧引擎层

强调：

- template
- variable
- anchor
- text block

### 新 memory 层

强调：

- subject
- snapshot
- expression
- semantic result
- module

这说明工程确实在往更明确的 Memory Engine 方向走，而不是只在 renderer 或页面层迭代。

## 五、后续开发建议

### 新增时间语义或年龄语义

先看：

- `AnchorEngine`
- `MemoryAnchorTypeRegistry`
- `BirthdayAgeCalculator`

### 新增 memory 表达逻辑

先看：

- `MemoryExpressionEngine`
- `MemoryExpressionContext`
- `MemoryExpressionProtocols`

### 新增旧配置到新 MemorySubject 的桥接规则

先看：

- `MemorySubjectAdapter`
- `ProductionMemoryResolver`
