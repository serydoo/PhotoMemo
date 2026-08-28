# MemoMark GitHub iOS / Apple Skills Research

## 研究目的

本记录把用户提供的审核意见，与 2026-08-28 对 GitHub 和本地
`.codex/skills` 的复核结果合并。目标不是收集最多的 Skill，而是为 V4
Expression Style System 建立一个低噪声、可验证、不会重新打开冻结架构的能力地图。

本次研究遵循以下判断顺序：

1. MemoMark 当前的 V4 产品和工程边界。
2. Apple 原生能力和本地项目 Skill 是否已经覆盖。
3. GitHub 项目的真实性、维护状态、许可和可复用范围。
4. 是否有一个真实任务能证明新增 Skill 的缺口。
5. 是否值得引入额外上下文成本。

研究日期：2026-08-28。GitHub 的 star、更新时间和可用 API 随时间变化，不能单独作为质量证明。

## 先给结论

MemoMark 目前不缺一个“80+ iOS Skills 大包”。当前仓库已经有一组覆盖
MemoMark 领域和 Apple 平台基础能力的本地 Skill；上一轮治理还增加了
`memomark-quality-gates`，用于按需执行 accessibility、localization、performance
和实体设备证据审计。

这次 GitHub 复核得到的最重要修正是：

- `openai/skills` 已在 README 中标为 deprecated，并建议改看
  `openai/plugins`；本次没有从 OpenAI GitHub 官方仓库核验出用户审核意见中所说的
  可直接安装的 SwiftUI/iOS 专项 Skill Bundle。因此不能把
  `swiftui-performance-audit`、`ios-debugger-agent` 等名称当作“OpenAI 官方已发布”的事实。
  参考：[openai/skills](https://github.com/openai/skills)、[openai/plugins](https://github.com/openai/plugins)。
- 当前最完整、最接近 iOS 任务型 Agent Skills 的公开候选是第三方
  [`dpearson2699/swift-ios-skills`](https://github.com/dpearson2699/swift-ios-skills)。
  它的覆盖面很强，但许可证是 PolyForm Perimeter 1.0.0，不应未经法律和仓库许可审查就复制进
  MemoMark 或重新发布。
- [`BohdanOrlov/ios-skills-matrix`](https://github.com/BohdanOrlov/ios-skills-matrix)
  是 iOS 知识指标清单，不是可触发的 Agent Skill；它适合作为人工审核 checklist，不能当作安装包。
- [`ameyalambat128/swiftui-skills`](https://github.com/ameyalambat128/swiftui-skills)
  的价值在于从本机 Xcode/Apple 文档生成上下文，且采用 MIT；但它仍是外部上下文工具，不能替代
  MemoMark 的产品语言、架构所有权和真机证据规则。

因此，本次不批量安装 GitHub Skill，也不把第三方内容整段复制到本地。推荐采用
“本地 MemoMark contract + Apple 原生/社区参考 + 任务触发验证”的组合。

## 当前本地可用能力

当前 `.codex/skills` 实际包含 18 个目录。它们分为三层：

| 层 | 当前 Skill | 作用与边界 |
| --- | --- | --- |
| MemoMark 领域 | `memomark-ui-reviewer` | Configuration Center、Memory Card、Object Inspector、SwiftUI/UIKit/TextKit 审计；默认 audit-first |
| MemoMark 领域 | `memomark-product-manager` | V4 产品循环、研究证据、冻结架构边界和范围决策 |
| MemoMark 领域 | `memomark-renderer-contract` | Preview/Renderer/Export fidelity；Renderer 不拥有语义和 layout |
| MemoMark 领域 | `memomark-media-fidelity` | Apple Photos resource、EXIF、Live Photo、RAW、色彩、权限和输出完整性 |
| MemoMark 领域 | `memomark-release-readiness` | Release readiness、证据和建议；默认不执行 commit/push/TestFlight/App Store mutation |
| MemoMark 领域 | `memomark-quality-gates` | 按需聚合 accessibility、localization、performance、实体 iPhone 证据 |
| Apple 媒体 | `photokit` | PhotosPicker、PhotoKit、AVFoundation、权限和资源生命周期 |
| Apple 生命周期 | `background-processing` | BGTaskScheduler 和后台处理；仅在明确的后台需求触发 |
| Apple 生命周期 | `activitykit` | Live Activities/Dynamic Island；当前不是 MemoMark 默认能力 |
| SwiftUI / 测试 | `swiftui-patterns` | SwiftUI 状态、组合和生命周期；明确避免把 `@MainActor` 作为全局修复 |
| SwiftUI / 测试 | `swift-testing` | Swift Testing、XCTest 边界和测试迁移 |
| SwiftUI / 测试 | `swift-actor-persistence` | actor 隔离的本地持久化参考 |
| SwiftUI / 测试 | `swift-protocol-di-testing` | 协议化依赖注入和可测试边界 |
| SwiftUI / 测试 | `ios-simulator` | 仅限模拟器诊断；不能替代配对 iPhone 17 Pro Max 验收 |
| 工程治理 | `architecture-decision-records` | 只在接受架构或所有权决策改变时记录 ADR |
| 工程治理 | `code-reviewer` | 多语言代码质量审查；不能替代 MemoMark source-of-truth |
| 工程治理 | `karpathy-guidelines` | 小步、最小改动、显式验证和边界意识 |
| 工程治理 | `verification-loop` | 证据闭环和回归检查 |

这意味着用户审核意见中的大部分目标已经有本地落点。真正的缺口不是
“再加一个同名 Skill”，而是为特定任务补充可审查的参考资料和证据模板。

## GitHub 候选复核

### 1. `dpearson2699/swift-ios-skills`：高覆盖，条件吸收

仓库自称覆盖 iOS 26、Swift 6.3、SwiftUI 和现代 Apple Frameworks，README 列出约
86 个 Skill。与 MemoMark 最相关的目录包括：

- [`swiftui-performance`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/swiftui-performance)：要求先提出性能假设，再使用 Instruments/Release/实体设备证据，适合 Preview invalidation、图片解码和渲染耗时专项。
- [`swift-concurrency`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/swift-concurrency)：围绕 Swift 6 isolation、Sendable、actor、取消和编译器设置排查，适合媒体管线和异步 Photos 回调。
- [`ios-accessibility`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/ios-accessibility)：VoiceOver、Voice Control、Dynamic Type、焦点、语义和可达性审计，适合 Configuration Center UI pass。
- [`ios-localization`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/ios-localization)：String Catalog、`LocalizedStringResource`、plural、RTL 和 FormatStyle，适合作为本地化技术参考。
- [`swiftui-uikit-interop`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/swiftui-uikit-interop)：`UIViewRepresentable`、Coordinator、TextKit/UIKit 桥接和生命周期，直接对应 Card Content Editor。
- [`swiftui-navigation`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/swiftui-navigation)：NavigationStack、split view、sheet、tab 和深链，适合 Configuration Center 导航审计。
- [`debugging-instruments`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/debugging-instruments)：LLDB、Memory Graph、Instruments、hang 和崩溃诊断，适合有明确症状时触发。
- [`app-store-review`](https://github.com/dpearson2699/swift-ios-skills/tree/main/skills/app-store-review)：提交前审核清单；每次应重新拉取 Apple 当前规则并记录日期，不能把静态 Skill 当作政策源。
- `storekit`、`metrickit`、`ios-ettrace-performance`、`ios-memgraph-analysis`：有价值但属于条件能力，不能默认加载。

风险和处理方式：

- 许可证是 PolyForm Perimeter 1.0.0，而不是 MIT；只做链接和人工参考，不复制原文或直接 vendoring。
- 覆盖面很大，容易与本地 `photokit`、`swift-testing`、`swiftui-patterns`、
  `memomark-*` 重复，批量安装会增加触发冲突和 Plus 上下文消耗。
- 其 iOS 26/Swift 6.3 假设需要与 MemoMark 的实际 deployment target、Xcode 工具链和当前
  `MemoMark.xcodeproj` 逐项核对。

结论：暂不安装整库；只在对应任务开始时打开一个目录作为外部参考，或在许可证允许且确有
缺口时提炼“规则摘要 + 项目适配说明”，并保留来源链接。

### 2. `ameyalambat128/swiftui-skills`：文档来源有价值，工具链需审查

该项目以 MIT 发布，核心方向是从本机 Xcode/Apple 文档生成 SwiftUI Skill，并提供 Codex
插件结构。它对 MemoMark 的价值是 Apple 文档 provenance，而不是一套新的产品架构。

适用场景：需要核对一个当前 SDK API 或 SwiftUI 生命周期行为时，优先引用本机 Xcode/Apple
文档生成的上下文。限制：安装脚本会写入用户 Skill 目录，且需要 macOS/Xcode 26；在执行前必须
检查脚本、生成内容和路径，不应为了“有一个 SwiftUI Skill”而直接安装。

参考：[仓库](https://github.com/ameyalambat128/swiftui-skills)。

### 3. `SwiftyJourney/ios-architecture-expert-skill`：低采用度，供架构对照

这是一个 MIT 的小型架构 Skill，强调 composition root、protocol boundary 和 Swift 6
concurrency。它与 MemoMark 已冻结的 Memory Engine、Layout Engine、Renderer、Export
所有权存在较大重叠，且采用度很低。可在需要比较架构建议时阅读，不能据此重新设计 V4。

参考：[仓库](https://github.com/SwiftyJourney/ios-architecture-expert-skill)。

### 4. `BohdanOrlov/ios-skills-matrix`：人工 checklist，不是 Agent Skill

仓库 README 明确其目标是整理 iOS 知识指标，没有 `.codex/skills/*/SKILL.md` 形态，也没有
可直接触发的 Skill contract。可以把它当作人工能力盘点表，但不能加入 `.codex/skills`。

参考：[仓库](https://github.com/BohdanOrlov/ios-skills-matrix)。

### 5. OpenAI GitHub 来源：纠正审核意见中的归属

本次 GitHub 复核未找到一个可核验的 OpenAI 官方“build-ios-apps Skill Bundle”，也未找到
名为 `swiftui-performance-audit` 或 `ios-debugger-agent` 的官方公开 Skill 路径。
`openai/skills` README 已标记 deprecated，当前官方插件目录也没有对应的 iOS 专项目录。

这不代表这些能力不存在或不可用；它们可以由本地 MemoMark Skill、第三方参考、Apple 文档和
Instruments/真机证据共同实现。但后续文档必须把“官方来源”“社区来源”“MemoMark 自有 contract”
分开写，避免把推测当成供应商承诺。

## 按 MemoMark 任务的能力地图

| 真实任务 | 首选本地能力 | GitHub/Apple 参考 | 触发条件 | 暂不做什么 |
| --- | --- | --- | --- | --- |
| Configuration Center UI polish | `memomark-ui-reviewer` + `memomark-quality-gates` | `swiftui-navigation`、`ios-accessibility`、Apple HIG | 一次完整 UI pass 前后 | 不因单个 spacing 重新设计 IA-002 |
| Card Content Editor / TextKit | `memomark-ui-reviewer`、`swiftui-patterns` | `swiftui-uikit-interop` | 修改输入几何、IME、caret 或 attachment | 不让 Renderer 接管输入几何 |
| Preview 卡顿或重算 | `memomark-renderer-contract` + `memomark-quality-gates` | `swiftui-performance`、Instruments | 有用户可感知卡顿或性能假设 | 不凭肉眼宣称 60/120 FPS |
| Photos / Live Photo / RAW / EXIF | `photokit` + `memomark-media-fidelity` | dpearson `photokit` 仅作 API 参考 | 资源解析、权限、降级回调、元数据或输出变更 | 不重复复制 Apple API 文档 |
| Swift 6 并发或异步回调 | `swiftui-patterns`、`swift-protocol-di-testing` | `swift-concurrency` | 编译器隔离诊断、竞态、取消、late callback | 不把所有 ViewModel blanket `@MainActor` |
| 真实设备 Bug | `verification-loop`、`ios-simulator`（仅诊断） | `debugging-instruments`、LLDB、Instruments | 可复现或间歇性生命周期/性能问题 | 不用 Simulator 代替 iPhone 17 Pro Max 验收 |
| 本地化治理 | `memomark-quality-gates` + 产品语言规范 | `ios-localization`、Apple String Catalog 文档 | 新增文案、格式化、RTL、四语言回归 | 不未经规范把界面、输出、Preset、Task Snapshot 语言混为一谈 |
| Plus/IAP/提交审核 | `memomark-release-readiness` | `storekit`、`app-store-review`、Apple 当前政策 | release candidate 或政策变更 | 不自动改 build、上传 TestFlight 或提交审核 |
| 上线后 crash/hang/响应性 | `memomark-release-readiness` | MetricKit | 有真实用户遥测授权和上线后数据 | 当前不提前引入 MetricKit 作为 V4 默认工作 |
| Liquid Glass / ActivityKit | `swiftui-patterns`、`activitykit` | dpearson 对应目录 | 明确的浮层、Live Activity 需求 | 不因 SDK 支持就把 Settings/Subject/Anchor 全部玻璃化 |

## 推荐的实施顺序

### 现在：保持本地栈，按需使用 GitHub 参考

1. `memomark-quality-gates` 作为一次 UI 或 release pass 的统一入口。
2. `memomark-ui-reviewer` 先做产品和 Apple-native audit，再决定是否改代码。
3. 只有出现性能、并发、可达性、本地化或调试证据缺口时，才读取对应的 GitHub 目录。
4. 任何外部 Skill 先验证许可证、目标 SDK、触发词和与本地 contract 的冲突。

### 下一轮 UI pass：优先吸收四个窄能力

若当前 UI System Polish 需要继续，最值得参考的顺序是：

1. `swiftui-uikit-interop`：Card Content Editor 的 UIKit/TextKit 生命周期和尺寸同步。
2. `ios-accessibility`：VoiceOver、焦点、Dynamic Type、语义和最小点击区域。
3. `swiftui-navigation`：Configuration Center 的 sheet/navigation 状态和返回路径。
4. `swiftui-performance`：有明确前后指标的 Preview/图片/Renderer 性能专项。

这四项都不能覆盖 MemoMark UI Reviewer 的职责；它们只回答“实现和验证是否正确”。

### 工程闭环：等真实证据出现再触发

- Swift Concurrency：只有 compiler diagnostics、race、cancellation 或 actor ownership
  问题出现时读取。
- Instruments/Debugger：只有可复现症状或性能假设时读取。
- MetricKit：放到 V4 稳定且有真实用户遥测边界之后。
- StoreKit/App Review：在 Release Readiness 任务中按当前 Apple 资料复核，不把第三方静态文档
  当成政策源。

## Skill 选择规则

每次考虑新增或引入一个 Skill，必须回答：

1. 它解决的是 Product Loop 还是 Engineering Loop 问题？
2. 当前本地 Skill 为什么不够？
3. 它是否改变 Memory Engine、Layout Engine、Renderer、Export 或 Photos 的所有权？
4. 许可证是否允许当前使用方式？
5. 是否能定义自动化测试、build、Instruments 或实体 iPhone 证据？
6. 完成后是否可以删除重复上下文？

如果第 2、4、5 题答不清楚，就不安装。Skill 的数量不是完成度指标；能否减少错误、减少
无证据改动并支持真机验收，才是指标。

## 与用户审核意见的逐项对照

用户意见中关于 Context Diet、audit-first、Renderer/Media Fidelity/Release Readiness
边界、真机优先、Accessibility/Localization/Performance 质量门的方向是正确的，且已经在本地
治理基线中落地。

需要修正或收窄的地方有三项：

1. “OpenAI 官方 iOS Skill Bundle”目前没有 GitHub 可核验依据，应改写为“社区 iOS Skill
   候选 + Apple 文档/工具链参考”。
2. “ios-skills-matrix”不是可安装 Skill；只能做人工 checklist。
3. `dpearson2699/swift-ios-skills` 虽然覆盖很全，但 PolyForm 许可证和重复上下文风险决定了
   它只能选择性参考，不能整库纳入 MemoMark。

## 当前结论

MemoMark 的推荐技能栈不是 14 个固定目录，而是一组有优先级的路由：

- 常驻本地：MemoMark domain skills、`swiftui-patterns`、`swift-testing`、`photokit`、
  `memomark-quality-gates` 和治理/验证能力。
- 按需参考：`swiftui-uikit-interop`、`ios-accessibility`、`swiftui-navigation`、
  `swiftui-performance`、`swift-concurrency`、`debugging-instruments`、
  `ios-localization`、`app-store-review`。
- 条件能力：ActivityKit、Background Processing、MetricKit、ETTrace、Memory Graph、
  Liquid Glass、StoreKit 专项。

后续逐项优化以真实任务为单位推进：先审计，再最小修改，再自动化验证，再在配对实体
iPhone 17 Pro Max 上验收；不会因为 GitHub 上存在一个更大的目录就改变 MemoMark 的 V4
架构或增加默认上下文。

## 2026-08-28 必要维护结果

基于本次研究和用户审核意见第 3–16 条，已对现有本地 Skill 做一轮必要升级：

- `memomark-ui-reviewer`：增加完整 UI pass 记录、Accessibility/Localization/Performance
  检查、UIKit/TextKit 输入边界和 Liquid Glass 条件使用规则。
- `memomark-product-manager`：增加 V4 maturity rule、产品语言与输出语言分离，以及对
  ActivityKit、MetricKit、StoreKit、BackgroundTasks 等能力的场景筛选。
- `memomark-media-fidelity`：从“字段审查”增强为 source-to-output media evidence，覆盖资源身份、降级、
  late callback、取消、内存 residency 和输出 read-back。
- `memomark-renderer-contract`：增加 preview/export parity、same-source 切换、异步 relevance check
  和性能证据规则。
- `memomark-release-readiness`：增加 Accessibility、Localization、StoreKit、Photos lifecycle、
  Performance、App Review 和 MetricKit 的条件化发布门。
- `swiftui-patterns`：增加 Preview invalidation 和 Instruments/Release/实体设备证据规则，明确
  Liquid Glass 不是默认 UI 风格。
- `photokit`：明确它只负责 Apple API mechanics，并补充 limited/iCloud/Live Photo/cancellation
  和资源生命周期检查。
- `swift-testing`：明确 unit、UI、performance、physical-device、certification 五类证据不能互相替代。
- `verification-loop`：增加 MemoMark 项目验证 profile。
- `background-processing`、`activitykit`：明确条件启用、本地优先、取消和实体设备生命周期证据。

本轮没有新增第三方 Skill 目录，没有复制第三方 Skill 内容，也没有改变生产源代码。新增规则由
`scripts/validate_codex_governance.py` 进行最小稳定性检查。
