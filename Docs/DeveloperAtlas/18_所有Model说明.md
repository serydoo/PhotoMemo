# 所有 Model 说明

## 总判断

当前 `Models/` 目录里的模型更偏 V1 / 通用处理模型，而 Configuration Center 和 Memory Engine 自己也各自带了一部分模型。

所以要把模型分成 4 组看：

1. 照片事实模型
2. 输出组合模型
3. 批处理模型
4. 模板与变量模型

另外还有两组重要模型在别处：

- `ConfigurationCenter/Models`
- `MemoryEngine` 相关上下文模型

## 1. 照片事实模型

### `PhotoMetadata`

文件：

- [PhotoMetadata.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift)

#### 角色

- 承载 EXIF / TIFF / GPS 等事实信息
- 是 metadata 的核心事实对象

### `MetadataContext`

文件：

- [MetadataContext.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/MetadataContext.swift)

#### 角色

- 把事实字段映射成模板渲染上下文
- 是从“结构化事实”走向“模板变量文本”的桥

### `SelectedPhoto`

文件：

- [SelectedPhoto.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/SelectedPhoto.swift)

#### 角色

- 处理中的照片对象
- 包含 image、metadata、source info

## 2. 输出组合模型

### `RecordCard`

文件：

- [RecordCard.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/RecordCard.swift)

#### 角色

- renderer / export 的关键输入对象
- 聚合 template、metadata、anchor、badge、memoryModule

### `Anchor`

文件：

- [Anchor.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/Anchor.swift)

#### 角色

- 用户定义的时间锚点输入模型

### `AnchorResult`

文件：

- [AnchorResult.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/AnchorResult.swift)

#### 角色

- `AnchorEngine` 计算后的结果模型

## 3. 批处理模型

### `BatchConfigurationSnapshot`

文件：

- [BatchProcessing.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift)

#### 角色

- 冻结一次批处理所需配置
- 是生产处理里的重要稳定输入

### 同文件中的其他核心对象

- `BatchJobState`
- `BatchJobLaunchSource`
- `BatchTaskPhase`
- `BatchTaskIntakePayload`

#### 角色

- 描述批处理状态机与输入单元

## 4. 模板与变量模型

### `Template`

文件：

- [Template.swift](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/Models/Template.swift)

#### 角色

- V1 和当前输出语义里的模板主对象
- 定义各区域 `TemplateArea`

### 相关模型

- `TemplateArea`
- `TemplateItem`
- `TemplateItemType`
- `TemplatePreset`
- `TemplateVariable`
- `TemplateVariableCategory`
- `TemplateVariableLibrary`

#### 角色

- 共同组成模板与变量系统

## 5. 其他常用模型

### `Badge` / `CustomBadge`

负责：

- 徽标与自定义图像装饰语义

### `PersonalProfile`

负责：

- 旧配置层里与人物 / 关系 / 生日等相关的个人资料输入

### `InlineContentTextComposer`

负责：

- 将分段内容拼成单行文本
- 在 V1 preview 组合中很关键

## 6. 不在 `Models/` 目录但同样重要的模型

### Configuration Center 模型

目录：

- [/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models](/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/ConfigurationCenter/Models)

关键对象包括：

- `MemorySubject`
- `ConfigurationSnapshot`
- `MemoryBlock`
- `MemoryBehavior`
- `CardRegion`

### 为什么重要

这些模型更接近 V2 对象世界，不应该被误当成普通 V1 展示模型。

## 最重要的模型分层判断

### 原始事实

- `PhotoMetadata`
- `SelectedPhoto`

### 输入配置

- `Anchor`
- `Template`
- `Badge`
- `PersonalProfile`

### 冻结快照

- `BatchConfigurationSnapshot`
- `ConfigurationSnapshot`

### 最终组合输出

- `RecordCard`
- `AnchorResult`
- `MemoryModule`

理解模型时，先判断它属于哪一层，会比只记名字更有用。
