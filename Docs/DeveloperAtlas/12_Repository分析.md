# Repository 分析

## 总判断

当前 Repository 层整体偏薄。

它们更像“访问边界包装器”，而不是承载大量业务规则的 Domain Repository。

这有两个直接含义：

1. 好处是入口更稳定，View 不必直连 Service
2. 风险是复杂度没有消失，而是还停留在 Service / Store / Coordinator

## 1. SettingsRepository

文件：

- [SettingsRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/SettingsRepository.swift)

### 负责什么

- 构建默认 `BatchConfigurationSnapshot`
- 读写激活配置 slot
- 保存 template / badge / subject
- 保存 photo description 相关设置
- 读取 V1 bootstrap state

### 特点

- 这是 V1 默认配置保存最重要的 repository
- 它本身很薄，但它的下游 `SettingsService` 很重

### 结论

如果新增默认配置字段，通常先从这里找入口，再追到 `SettingsService`。

## 2. QueueRepository

文件：

- [QueueRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/QueueRepository.swift)

### 负责什么

- 暴露队列 job 列表
- 暴露默认配置快照
- enqueue
- retry
- cancel
- clear history

### 特点

- 这是典型的 `store façade`
- 真正复杂逻辑主要还在 `BatchQueueStore`

### 结论

如果你想改“队列行为”，不要停在 repository，要继续往 `BatchQueueStore` 和 `BatchQueueExecution` 追。

## 3. ConfigurationRepository

文件：

- [ConfigurationRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/ConfigurationRepository.swift)

### 负责什么

- 读取默认 batch snapshot
- 读取共享 snapshot
- 根据 album id 解析标题
- upsert birthday anchor

### 特点

- 它是“配置快照边界”的关键入口之一
- 同时也承担一小段 anchor 持久化职责

### 结论

这是当前 V1 / share / queue 之间配置冻结语义的一个重要桥。

## 4. PhotoRepository

文件：

- [PhotoRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/PhotoRepository.swift)

### 负责什么

- 导入照片
- 从 data 导入照片
- 写回渲染结果

### 特点

- 它不是 photo manager repository
- 更准确地说，它是“图片处理边界包装器”

### 结论

如果你改的是导入或写回用户库这类动作，这里是个好入口；但 metadata 读取细节还是在 service。

## 5. PhotoLibraryRepository

文件：

- [PhotoLibraryRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/PhotoLibraryRepository.swift)

### 负责什么

- 读取系统相册列表
- 创建相册
- 保存输出图像到相册

### 特点

- 明显比 `PhotoRepository` 更专注于系统图库操作
- 这是一个边界非常清楚的 repository

### 结论

这类 repository 是比较健康的边界形态。

## 6. DiagnosticsRepository

文件：

- [DiagnosticsRepository.swift](/Users/rui/Desktop/PhotoMemo-main-archive-20260702/Source/PhotoMemo/PhotoMemo/Repositories/DiagnosticsRepository.swift)

### 负责什么

- 记录 share diagnostics
- 读取 share diagnostics
- 读取 shared queue jobs
- 读取 processing diagnostics snapshot

### 特点

- 这是一个典型的“只读 / 记录型仓库”
- 它对业务主链影响较小，但对排障很重要

## Repository 层总评价

### 优点

- 边界清晰
- View 不需要直接打到 Service
- 后续更容易替换底层实现

### 缺点

- 很多 repository 太薄，容易让人误以为改 repository 就等于改了业务
- 真正复杂度仍然在 service / store / coordinator

## 后续开发建议

如果你要新增功能：

- 先从 repository 入口找调用边界
- 但不要停在 repository
- 一定继续追下游 service / store / execution
