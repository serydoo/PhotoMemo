# MemoMark 2.2.4 (101) 重构后文件整理清单

- 日期：2026-09-03
- 范围：`0954bea..当前工作树`
- 状态：当前重构切片已收口，进入持续使用观察模式
- 原则：整理归属，不改变行为；不在本记录中执行 Git 暂存、提交或推送

## 整理结论

本轮重构已经形成四条主要责任线：

```text
SwiftUI / UIKit presentation
        -> Application transactions
        -> Domain policies
        -> Infrastructure platform and durable boundaries
```

现有 Xcode 工程使用文件系统同步分组，所以源码文件不需要通过
`project.pbxproj` 逐个维护显式引用。这个特性降低了文件移动成本，但也带来
一个交付要求：本地未跟踪文件会参与本地构建，必须在最终候选整理时确认它们
是否全部属于版本范围。

## 当前目录归属

| 目录 | 当前责任 | 不应承担的责任 |
| --- | --- | --- |
| `App/` | 生命周期、外部 intake、跨目标状态投影 | 业务规则、PhotoKit 写入、第二队列真相 |
| `Application/` | 应用事务、用例编排、运行时组合 | SwiftUI 展示状态、独立持久化真相 |
| `Domain/` | 纯队列/任务策略与轻量领域值 | PhotoKit、文件系统、SwiftUI |
| `Infrastructure/` | 并发门、durable ledger、PhotoKit 事务端口 | 页面状态、产品文案、第二配置聚合 |
| `ConfigurationCenter/` | macOS 配置中心、Session、编辑器和 Inspector | 队列执行、媒体导出 |
| `iOS/Views/` | iOS 配置中心、编辑、首页、任务和支持页面 | 持久化、队列、PhotoKit 输出 |
| `Services/` | 现有生命周期服务和兼容 facade | 重新承载已迁出的事务/策略 |
| `MediaPipelineVNext/` | 媒体、Live Photo、输出规则和读回 | UI 状态和布局真相 |

## 已完成的文件整理

- 旧的 `ConfigurationCenteriOSView.swift` 和临时双入口路径不再属于活动源码。
- iOS 当前入口统一为 `MemoMarkConfigurationCenterView` 及其职责拆分文件。
- 应用事务集中到 `Application/`；队列策略进入 `Domain/Processing/`；
  receipt、并发门和 PhotoKit 事务端口进入 `Infrastructure/`。
- 配置中心、Memory Card、Home、Subject、Settings、Task、Photo Intake 等
  活跃 UI 文件改为责任导向名称。
- `V1` 只保留在仍代表兼容 schema、存储格式或尚未单独验证的迁移桥接处；
  不再新增新的活动 `V1*` 文件。
- 测试文件跟随责任归属迁移，旧的 source-contract 路径不作为当前入口。

## 最终候选整理时的核对顺序

1. 以 `git status --short` 生成完整文件清单，逐项确认新增文件是否属于
   `2.2.4 (101)`；私有照片、设备导出、归档包和本地产物不得进入候选。
2. 检查同名旧/新文件对是否确实是迁移关系，确认没有遗漏调用点或测试。
3. 在干净检出环境运行 `xcodebuild -list`、目标构建和稳定的 focused tests。
4. 确认四种本地化资源 Key 集合一致，兼容 key、schema raw value、App Group、
   URL scheme、后台任务标识和商品 ID 没有被重命名。
5. 只有在候选文件集合、测试结果和设备证据都记录后，才进入独立的 Git
   暂存/提交授权流程。

## 暂不继续的事项

- 不为了降低行数继续拆分 `BatchQueueStore`、`ShareManagedFileImporter`、
  `BatchProcessing` 或 `SettingsPageSurface`。
- 不机械重命名 `SchemaV1`、`LegacyV1`、pasteboard type、UserDefaults key
  或历史文件名。
- 不把用户确认的人工通过扩大解释为全量自动化测试通过、Instruments 通过或
  正式生产认证。
- 后续持续使用中如发现具体问题，按“现象 -> 最小复现 -> 责任归属 -> focused
  test -> 设备复验”重新打开最小切片。
