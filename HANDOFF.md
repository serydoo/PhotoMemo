# PhotoMemo Handoff

## 2026-06-20 v0.7.4 Product polishing docs established

- 本轮目标：
  - 不改代码
  - 把 PhotoMemo 正式推进到“产品打磨期”的文档基线
- 本轮新增文档：
  - `Docs/ShareExtensionReview.md`
  - `Docs/DesignSystem.md`
  - `Docs/ProductBacklog.md`
- 本轮关键结论：
  - Share Extension 目前还是“技术交接面”，还不是完整的主产品体验
  - Main App 继续朝配置中心收敛
  - 之后所有 UI 需要开始遵守统一设计系统
  - 新想法以后先进入 backlog，不直接打断当前开发节奏
- Share Extension review 的核心判断：
  - 第一次使用的人仍然会有一点迷路
  - 当前成功态更像“已加入收件箱”，还不是“已完成生成并保存”
  - 最值得推进的是：预览、当前配置、生成、保存这条最短主链
- 本轮 backlog 分层：
  - `Now`：Share-first 主链、Alpha 可用性、真实设备体验、预览/导出信任
  - `Next`：Share Extension 内配置切换、保存反馈、术语统一、Design System 收敛
  - `Later`：批量分享、Quick Actions、更多默认智能化
  - `Icebox`：零配置智能模式、自动分类、模板生态扩张
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.3 Product direction docs aligned

- 本轮目标：
  - 不改代码行为
  - 只把产品方向正式写进仓库文档
- 本轮新增文档：
  - `Docs/ProductDirection.md`
  - `Docs/UX_PRINCIPLES.md`
- 本轮统一后的核心口径：
  - PhotoMemo is a memory generator built around Apple Photos, not a photo editor.
  - PhotoMemo 不是修图工具，而是围绕系统相册构建的记忆生成器。
  - Share Extension 是主工作流
  - Main App 是配置中心
  - 未来 UX 以更少决策、更少滚动、更少阅读为优先
- 本轮同步调整：
  - `README.md` 首页定义已按新口径更新
  - `Docs/CURRENT_STATUS.md` 已补充这次方向对齐记录
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.2 Alpha 可用性迭代（第一轮）已落地

- 本轮目标：
  - 不加新功能
  - 不动架构边界
  - 只围绕 Alpha 阶段的真实上手体验收敛主界面
- 本轮主界面改动：
  - 照片导入区已前移到工作区更靠上的位置
  - `PhotoImporterView` 现在优先提供系统 `PhotosPicker`
  - 文件导入改为次级入口，保留给桌面素材与外部图片
  - iPhone 预览流里原先重复出现的工作区配置卡片已移除
  - 空照片态在滚动容器里不再强占整块高度，减少无意义留白
- 本轮配置与模板交互收敛：
  - 工作区配置区不再显示“当前配置”独立摘要卡
  - 三个配置槽位改成更直接的模块列表样式
  - 点选槽位会立即切换并刷新预览
  - 每个槽位都提供内联“编辑”菜单，用于重命名、保存当前内容、恢复默认
  - 模板区去掉更偏开发期的“预设骨架 / 默认右下”等表述
  - 模板区现在更强调“当前名称 + 直接编辑下方内容”
- 本轮可用性修正：
  - iOS 自定义区域编辑器对 CJK 输入法改为优先走系统原生合成流程，降低中文输入被编辑投影层打断的概率
  - 时间点管理按钮改为更明确的“管理与编辑”
  - 时间点列表中的“编辑”入口已放大为明确按钮，并补充“设为当前”
  - 手动导出文件如果遇到同名目标，现在会自动生成：
    - `filename (1)`
    - `filename (2)`
    - `filename (3)`
    避免直接覆盖
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - iOS 构建仍有既存警告：
    - interface orientations
    - launch configuration / launch storyboard
- 本轮尚未手动验证：
  - 真机上 `PhotosPicker` 导入一张系统照片后的完整 EXIF 读取体验
  - 中文输入法在长段连续编辑、删除 chip、跨 chip 插入时的最终手感
  - 时间点编辑页在 iPhone 上的最终触感
- 下一轮最值得继续：
  - 真机逐项复核 `PhotosPicker`、中文输入、时间点编辑
  - 继续检查预览页纵向节奏和各卡片间距是否还能更紧凑
  - 如果这轮手感稳定，再进入更细的 iPhone 主流程 polish

## 2026-06-20 v0.7.1 Fixture-backed Export Read-back 已落地

- 本轮目标：
  - 不改架构
  - 不改 renderer / workspace / batch 行为语义
  - 让 Sprint-009 的 smoke foundation 真正进入 fixture-backed correctness 验证
- 本轮新增测试与资产：
  - `Tests/Fixtures/GenerateSyntheticFixtures.swift`
  - `Tests/Fixtures/Synthetic/`
  - `Tests/PhotoMemoTests/Support/SyntheticFixtureLibrary.swift`
  - `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/BatchFixtureCoverageTests.swift`
- 当前已提交的 synthetic fixture 覆盖：
  - `01_iPhone_JPEG.jpg`
  - `02_iPhone_HEIC.heic`
  - `05_GPS.jpg`
  - `06_NoGPS.jpg`
  - `07_Portrait.jpg`
  - `08_Landscape.jpg`
  - `10_LowMetadata.jpg`
- 仍保留为 reserved-only：
  - `03_Canon.CR3`
  - `04_Nikon.JPG`
  - `09_LivePhotoStill.heic`
- 本轮自动化覆盖新增：
  - JPEG fixture export -> read-back
  - HEIC fixture import + export read-back
  - EXIF / TIFF / GPS / orientation / dimensions / description families 的显式断言
  - batch fixture enqueue / cancel / retry eligibility
- 本轮修到的真实 correctness 问题：
  - `RecordCardExportService` 之前用目标 render size 回写 metadata
  - 在实际渲染位图尺寸与目标尺寸出现 1px 差异时，可能导致：
    - 顶层 `PixelHeight`
    - EXIF `PixelYDimension`
    不一致
  - 现在已改为以最终 `CGImage` 实际尺寸回写 metadata
- 本轮当前验证状态：
  - `PhotoMemoTests` 已通过，共 19 个 tests
  - `PhotoMemo` build 已通过
  - `PhotoMemoiOS` build 已通过
  - `PhotoMemoShareExtension` build 已通过
- 下一轮最值得做：
  - renderer snapshot prep 继续往正式 snapshot 基线推进
  - 再评估是否要加入 Photos save-back read automation
  - 对 reserved 的 Nikon / Live Photo still fixtures 再补第二批 synthetic 或 licensed sample

## 2026-06-20 v0.7.0 Memory Engine Foundation 已落地

- 本轮目标：
  - 不改 renderer / export / batch / UI 行为
  - 引入真正的 Memory domain foundation
  - 让记忆语义从“零散逻辑”进入可测试、可扩展的独立边界
- 本轮新增架构文档：
  - `Docs/ADR/ADR-006-MemoryEngineFoundation.md`
  - `Docs/MemoryEngine.md`
- 本轮新增实现：
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryContext.swift`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryCalculationResult.swift`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift`
- 本轮接入点：
  - `CardVariableProvider` 现在通过 Memory Engine 供给记忆变量
  - `TemplateVariable` 现在公开：
    - `{{days_since}}`
    - `{{years_since}}`
    - `{{months_since}}`
    - `{{weeks_since}}`
    - `{{baby_age}}`
- 当前刻意保持不变：
  - `AnchorEngine`
  - Renderer
  - Export
  - Batch
  - Share Extension 流程
  - 现有 `memory_summary` 的 story-first / anchor-summary-first 语义
- 本轮测试：
  - 新增 `MemoryEngineTests` suite（当前放在 `PhotoMemoTests` target 内）
  - 覆盖：
    - 不满 1 岁年龄文案
    - 闰年生日
    - 时区边界
    - 未来时间点 clamp
    - `CardVariableProvider` 集成
    - public variable catalog 暴露
- 版本节奏：
  - 从这一轮开始，面向 release / changelog / 外部总结时，优先使用版本号
  - 当前版本基线记作：
    - `v0.7.0`
  - 旧的 `Sprint-*` 记录继续保留为内部开发历史，不要求回写改名
- 本轮验证状态：
  - `PhotoMemoTests` 已通过
  - `PhotoMemo` build 已通过
  - `PhotoMemoiOS` build 已通过
  - `PhotoMemoShareExtension` build 已通过

## 2026-06-20 Sprint-009 回归验证基础已落地

- 本轮目标：
  - 不改架构
  - 不改 renderer / editor / workspace / batch 设计
  - 建立可长期复用的 fixture / regression / test foundation
- 本轮新增文档：
  - `Docs/FixtureSpecification.md`
  - `Docs/RegressionMatrix.md`
  - `Docs/AcceptanceCriteria.md`
  - `Docs/CIReadiness.md`
- 本轮新增目录与基础资产：
  - `Tests/Fixtures/README.md`
  - `Tests/Fixtures/FixtureManifest.json`
  - `Tests/PhotoMemoTests/`
- fixture 侧当前共识：
  - 现在先不提交真实照片二进制
  - 先把保留文件名、元数据要求、命名规范、后续引入规则固定下来
  - 预留的第一批 fixture 名称已覆盖：
    - iPhone JPEG / HEIC
    - 非 Apple 相机 JPEG
    - GPS / No GPS
    - Portrait / Landscape
    - Live Photo still 边界样本
    - Low metadata 样本
- 本轮工程变化：
  - `PhotoMemo.xcodeproj` 新增 `PhotoMemoTests` target
  - 新增 shared scheme：
    - `PhotoMemo.xcscheme`
    - `PhotoMemoTests.xcscheme`
  - 当前 `PhotoMemoTests` 依赖主 macOS app target，采用最小 unit-test bundle 形态
- 本轮新增 smoke tests：
  - `PhotoMetadataReaderTests`
    - EXIF timezone 解析
    - GPS ref 正负号归一化
  - `PhotoMetadataNormalizationTests`
    - aspect ratio / megapixels / location display
    - 坐标回退文案
  - `MetadataContextTests`
    - capture timezone 驱动的日期组件生成
  - `TemplateVariableEngineTests`
    - token 替换与缺失 token 清空
  - `RecordCardBuildServiceTests`
    - 说明写入开关关闭时不再导出说明
    - 开启时显式 override 生效
- 本轮实际验证结果：
  - `PhotoMemoTests` 测试通过，共 8 个 smoke tests
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮过程中修掉的工程问题：
  - 空目录占位文件最初都叫 `.gitkeep`，Xcode 会把它们当成资源复制进 test bundle，导致输出冲突
  - 已改为唯一占位名：
    - `.batch-tests.keep`
    - `.export-tests.keep`
    - `.renderer-tests.keep`
  - 另外补了 `PhotoMemo.xcscheme`，避免新增 shared test scheme 后主 app scheme 在 `xcodebuild -list` 中消失
- 当前真实边界：
  - 已经有了第一层可持续回归验证能力
  - 但还没有真实 fixture 二进制，所以这轮更偏“模型/服务逻辑 correctness 锁定”
  - 还没有进入：
    - renderer snapshot
    - export binary diff
    - Photos integration automation
    - batch fixture E2E
- 下一轮最值得做：
  - 引入可合法提交的真实或合成 fixture 二进制
  - 建立 `PhotoMetadataReader -> export -> read-back` 的 fixture 驱动测试
  - 再评估是否要补 renderer snapshot 与导出文件 metadata 细粒度断言

## 2026-06-20 Sprint-008 输出完整性核对已完成

- 本轮目标：
  - 不做架构重构
  - 不改渲染设计
  - 不改 editor / workspace
  - 优先核对导出完整性、回读能力、批处理可靠性、Live Photo 边界
- 本轮新增文档：
  - `Docs/ExportMetadataAudit.md`
  - `Docs/ExportReadbackVerification.md`
  - `Docs/JPEG_HEIC_Compatibility.md`
  - `Docs/BatchExportReliability.md`
  - `Docs/LivePhotoAssessment.md`
  - `Docs/OutputIntegrityReport.md`
- 本轮确认的关键事实：
  - `RecordCardExportService` 当前采用的是“原始 metadata 字典透传 + 少量显式修补”的导出策略
  - 显式修改的主要字段包括：
    - 输出宽高
    - EXIF 像素尺寸
    - 顶层 orientation = `1`
    - `TIFF Software = PhotoMemo`
    - 说明类字段（开启时）
  - `PhotoLibraryExportService` 会把 `metadata.captureDate` 写到 `PHAssetCreationRequest.creationDate`
  - 但 `PhotoMetadataReader` 当前只回读：
    - width / height
    - TIFF
    - EXIF
    - GPS
    不会把 description/comment 再读回 `PhotoMetadata`
  - batch 路径仍然是单一主链：
    - import -> build -> render/export -> save to Photos
    没有第二套批量专用导出器
- 本轮确认并修掉的 correctness 问题：
  - `shouldWritePhotoDescription` 之前没有真正阻止导出 metadata 写入说明文本
  - 现在 `RecordCardBuildService` 已在该开关关闭时返回空的 export description
  - `MainView+TemplatePanels.swift` 的说明写入预览文案也已同步修正
- 本轮结论：
  - 当前 PhotoMemo 对“静态照片、JPEG-first、写回系统图库”的可靠性已经比较不错
  - 但以下边界仍应如实对待：
    - ICC / 色彩配置文件目前没有显式校验
    - HEIC 目前是可导出/可手动选择，但不是 batch 主验证路径
    - Live Photo 目前只能按 still-image 心智理解，不能宣称支持成对资源保留
    - 说明字段虽然现在能正确写入/关闭，但 app 自己还不能完整回读这些字段
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 下一轮最值得做：
  - 建立小型导出 fixture 集，做真正的导出前后 metadata 对照
  - 评估是否把 description/comment 纳入 `PhotoMetadataReader` 的回读范围
  - 再决定是否要进入更细的 EXIF 保真验证或 Photos 写回回归测试

## 2026-06-20 Sprint-007 元数据归一化与变量目录对齐已落地

- 本轮目标：
  - 不改架构
  - 不改渲染/导出/批处理主链
  - 只在现有 metadata pipeline 内提升 correctness、consistency、catalog alignment
- 现在的关键事实：
  - `PhotoMetadataReader` 仍然是唯一 EXIF/GPS 读取入口
  - `PhotoMetadata.normalized()` 现在是 raw model 的统一归一化出口
  - `MetadataContext.Key` 现在是 runtime key 的统一定义
  - `PhotoMetadata.canonicalInventory` 现在是 metadata field inventory 的统一代码定义
- 本轮新增/改善：
  - 解析 capture-date 字符串中的 timezone suffix，保存到 `captureTimezoneOffsetSeconds`
  - `MetadataContext.build(from:)` 在渲染日期组件时，若 metadata 自带 timezone，则按 capture timezone 计算年/月/日/时/分/秒/weekday
  - GPS 现在会根据 `LatitudeRef` / `LongitudeRef` / `AltitudeRef` 处理正负号
  - 新增并公开的 metadata-facing variables：
    - `{{lens_brand}}`
    - `{{location}}`
    - `{{location_display}}`
    - `{{country}}`
    - `{{province}}`
    - `{{city}}`
    - `{{district}}`
    - `{{latitude}}`
    - `{{longitude}}`
    - `{{altitude}}`
    - `{{weekday}}`
    - `{{capture_date_short}}`
    - `{{capture_time_short}}`
    - `{{capture_timezone}}`
    - `{{orientation}}`
    - `{{aspect_ratio}}`
    - `{{megapixels}}`
    - `{{memory_summary}}`
  - `TemplateVariableLibrary.recognized` 的优先级也已按当前 PhotoMemo 使用价值重新排序
  - `TemplateVariableEngine` 的 token regex 现在缓存，不再每次 render 重新编译
- 有意保留为 internal-only 的 runtime keys：
  - `badge_name`
  - `anchor_hours`
  - `anchor_minutes`
  - `anchor_seconds`
- 本轮文档：
  - `Docs/MetadataInventory.md`
  - `Docs/VariableCatalogAlignment.md`
  - `Docs/MetadataNormalizationPlan.md`
  - `Docs/CURRENT_STATUS.md`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 没做的事：
  - 没新建 test target
  - 没做 reverse geocoding / location enrichment
  - 没改 share extension 的 metadata ownership
- 下一轮最值得做：
  - 为 `PhotoMetadataReader -> MetadataContext -> TemplateVariableEngine` 补回归测试
  - 再评估是否进入 `Sprint-008` 的 location enrichment / high-value variables

## 2026-06-20 Composer projection 已抽成独立 EditorProjectionEngine

- 已完成 `Sprint-005` 的保行为抽取：
  - 新增 `Source/PhotoMemo/PhotoMemo/Views/Main/EditorProjectionEngine.swift`
  - 删除旧的 `MainView+ComposerDisplayEngine.swift`
- 当前共识：
  - `String` 仍然是唯一真实来源
  - 没有引入 `ComposerDocument`
  - 没有引入 node tree / rich text / renderer-side projection
- 新引擎当前承接的责任：
  - raw template string -> display text
  - module span 生成与清洗
  - selection clamp
  - caret / selection 调整
  - chip 删除时 replacement range 调整
  - projection state 同步
- 已切换调用点：
  - `MainView+ComposerSession.swift`
  - `MainView+TemplateEditingActions.swift`
  - `MainView+ComposerEditor.swift`
  - `MainView+LayoutSections.swift`
- 明确保持不变：
  - `Template` 持久化格式
  - `RecordCardBuildService`
  - `TemplateVariableEngine`
  - Renderer / Export / Batch / Workspace / Settings
- 这轮目标不是改编辑模型，只是把 editor-specific projection 从 `MainView` 语义下抽离成独立引擎，方便后续继续做 composer 侧治理。

## 2026-06-20 WorkspaceSession Phase A 已铺架构壳层

- 已新增 4 个 workspace session 预备类型：
  - `WorkspaceSessionController`
  - `WorkspaceState`
  - `WorkspaceAction`
  - `WorkspaceEnvironment`
- `MainView` 只做了最小接线：
  - 新增 `workspaceSession` 持有者
  - `onAppear` 时把当前 `MainView` 状态与依赖 seed 进 session
- 这轮明确**没有**迁移：
  - 导出逻辑
  - 权限逻辑
  - 生命周期逻辑
  - 模板编辑逻辑
  - batch / queue 逻辑
- 当前真实状态：
  - `WorkspaceSessionController.send(action:)` 只承接基础状态更新壳层
  - 现有业务仍然全部走原来的 `MainView+*.swift` 实现
  - 这是为下一轮“分阶段把现有 workflow 移进 session”做准备，不代表迁移已开始
- 编译边界：
  - 这些新类型同样通过 `#if !PHOTOMEMO_SHARE_EXTENSION` 避免被 Share Extension target 编译
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

## 2026-06-20 BatchQueueStore 已拆为 4 个聚焦组件

- 已完成 `Review-002`：
  - `BatchQueueStore` 保留为公开 façade 与 `ObservableObject` 状态拥有者
  - 内部职责已拆到：
    - `BatchQueueExecution`
    - `BatchQueuePersistence`
    - `BatchQueueHistory`
    - `BatchQueueNotifications`
- 本轮明确保持不变：
  - UI / 渲染 / 导出行为
  - 队列执行顺序
  - 重试与取消语义
  - `UserDefaults` key 与持久化格式
  - 启动恢复语义
  - 通知发送与 sentAt / stage 回写时机
- 这次没有引入额外 `QueueState` 层，也没有为了行数再继续拆更多人工抽象层。
- `PhotoMemoShareExtension` 当前通过 `#if !PHOTOMEMO_SHARE_EXTENSION` 编译边界避免把 app-side queue façade / notification wiring 拉进 extension target；后续不要误把这些 guard 删除。
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 仍未做的验证：
  - 真机/手动回归 `retry`
  - 真机/手动回归 `cancel`
  - 真机/手动回归启动恢复后的继续处理
- 下一步更适合做：
  - 对 `BatchQueueStore` 子系统补最小可行的回归测试
  - 再考虑更高层的架构工作，不要在这轮拆分后立刻继续改 batch 语义

## 2026-06-20 BatchConfigurationSnapshot 单一来源已收口

- 已新增 `BatchConfigurationSnapshotProvider`，作为批处理默认快照与共享配置装配的单一来源。
- `SettingsService.buildBatchConfigurationSnapshot()` 已改为委托给该 provider，不再自己重复拼装默认模板 / 徽标 / 锚点 / 相册标识。
- `SharedBatchConfigurationSnapshotService.loadSnapshot()` 已改为直接复用同一 provider，Share Extension 与主 app 不再各自维护一套装配逻辑。
- 保持不变：
  - `UserDefaults` keys
  - 序列化格式
  - 默认值
  - UI、渲染、导出、通知与队列行为
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 后续合适的下一步：
  - 继续拆 `BatchQueueStore`
  - 再收束 `MainView` 的 workspace/export 协调逻辑
  - 暂时不要回退这次 provider 收口，避免再次出现快照装配漂移

这份文件用于帮助新的 Codex 会话快速接手当前项目，避免只依赖历史聊天上下文。

现在仓库根目录还新增了一份更偏“持续接力开发手册”的文档：

- `AI.md`

建议新的 AI 会话把它也作为第一批必读文件之一。

## 2026-06-19 分享摘要已进一步贯穿到桌面端与主 app drain 校正

这一轮继续围绕 share-intake 主链收口，但重点不再是 iPhone sheet 本身，而是让同一份“分享时发生了什么”的摘要在更多真实入口里保持一致。

新增/调整：

- `ExternalPhotoImportSummary` 现在除了会跟着 share extension 请求一起进入 `BatchJob`
- 也会继续挂进：
  - `ExternalIntakeSummary`
  - macOS 主界面的 `记忆进度` 面板

用户现在能看到的变化：

- macOS 左侧 `记忆进度` 里，最近一次外部导入不再只写“来了几张”
- 如果是分享入口，并且分享时有：
  - 重复跳过
  - 导入失败
  - 选中数和真正入队数不一致
  现在文案会直接说清楚
- 也就是说，桌面端现在也能看到更像“处理回执”的信息，而不是只在 iPhone 后台状态里知道异常

这一轮还顺手补了一个主 app 侧的摘要口径修正：

- `PhotoMemoAppRuntime.flushExternalRequests()` 在 drain 共享请求时，会先重新检查真正仍然有效的文件 URL
- 如果 share extension 当时写进收件箱的部分文件，到了主 app 真正接单时已经失效：
  - 现在会把 `importSummary` 重新修正到真实可入队数量
  - 避免后续通知 / 记忆进度把“已经失效、其实没入队”的图片继续算成成功入队

注意：

- 这里修过一次 double-count 细节，最终保留的口径是：
  - 只把“原本标记为 imported，但主 app drain 时已经失效”的数量补进 `failedCount`
  - 不会重复累计

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 分享接收摘要已贯穿到通知与 iPhone 后台状态

这一轮继续沿着 iPhone / share-intake / background queue 主链做，但重点不是再扩 ActivityKit，而是把“分享时已经发生的部分成功、跳过、失败”真正带进后续反馈链路。

完成内容：

- 新增共享摘要模型：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
  - `ExternalPhotoImportSummary`
- `ExternalPhotoIntakeRequest` 现在可携带：
  - 成功入队数
  - 重复跳过数
  - 导入失败数
- `PhotoMemoShareExtensionIntakeService` 在 share extension 侧会把这份摘要一起持久化进共享收件请求
- `PhotoMemoAppRuntime` / `BatchQueueStore` 会继续把这份摘要挂到最终 `BatchJob`

这带来的直接效果：

- 后台任务的开始通知现在不再只说“接收了多少张”
- 如果本次分享里有重复项被跳过、或有图片根本没能导入，现在通知里会明确说出来
- iPhone 后台状态页新增了“本次接收结果”卡片，能看到：
  - 分享选中
  - 成功入队
  - 重复跳过
  - 导入失败

这一轮还补了一刀取消保护：

- `BatchQueueStore.swift` 在真正调用 `saveRenderedPhoto` 前又加了一次终态检查
- 这样如果用户在“将要写入系统相册”前一刻取消，就不会再误把后续保存继续跑下去

补充说明：

- share extension 的 Data fallback 去重现在已经是基于内容 `SHA256`，不是旧的“大小 + 名称”近似判断
- 这一轮没有做模拟器启动回归，因为当前机器上的 `CoreSimulatorService` 仍然不可用；但三条构建命令都重新通过了

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 队列取消与分享去重再硬化

这一小轮没有继续扩界面，而是优先补了三个更容易变成“偶发失灵”的边界。

1. `BatchQueueStore` 取消边界补强

- 文件：
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- 修正点：
  - 如果用户在任务处理中途取消，当前活跃 task 不再继续把后续流程一路跑到底
  - 现在在 `importPhoto` 返回后、`exportCard` 返回后，都会重新检查 task 是否已经进入终态
  - 如果取消导致处理中抛错，也不再把已取消任务错误地改写成 `failed`
- 结果：
  - 降低“明明取消了，结果还继续保存进系统相册”这类错误行为的风险

2. 失败项重试语义更准确

- 同样在 `BatchQueueStore.swift`
- 修正点：
  - managed intake 源文件如果仍然存在，失败项现在保留重试资格
  - 只有真正找不到受管源文件时，才把 `canRetry` 压成 `false`
- 结果：
  - 更符合之前已经确定的方向：
    - PhotoMemo 自己复制进 `ExternalIntake` 的文件可以临时保留
    - 单张失败不应该轻易丢掉重试机会

3. Share Extension 的 Data fallback 去重更稳

- 文件：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- 修正点：
  - 之前 Data fallback 的去重 key 近似于 `data.count + suggestedName`
  - 这会让“不同图片刚好大小相同、名字也接近”的情况有误判概率
  - 现在改成基于 `SHA256` 的内容哈希去重
- 结果：
  - 多图分享时，误把不同图片当成重复项跳过的风险更低

顺手补的一点：

- `PhotoMemoiOSLiveActivityDriverService.swift` 现在会在 activity 被结束/失效后更完整地同步 `lastAppliedPayloads`
- 这属于小型状态收口，主要是避免重复应用同一终态 payload

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 Live Activity widget extension 已接通

这一小轮把上一轮还没收口的 ActivityKit / widget 侧工程接线真正补完了。

完成内容：

- 新增真实 widget extension 入口：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- 新增 extension plist：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `PhotoMemoLiveActivityPresentation.swift` 继续作为共享的 Live Activity 展示定义，被 widget extension 直接编译使用
- `PhotoMemoiOS` 现在会同时嵌入：
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

这轮顺手解决的关键工程坑：

- 之前 share extension 嵌入失败的核心原因，基本确认是 `ShareExtension-Info.plist` 缺少基础 bundle 键，导致嵌入校验时 bundle identifier 被视为 `(null)`
- widget extension 第一版又踩到 `Info.plist` 同时被“处理”和“Copy Bundle Resources”双重产出
- 处理方式是把 widget extension 的 plist 挪到同步组目录外，改成：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过
- 额外验证了 `PhotoMemoiOS.app/PlugIns` 里已经存在：
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

当前真实结论：

- iPhone 线不再只是“app 可编译 + 分享扩展可编译”
- 现在已经进入“app + share extension + Live Activity widget extension 可一起构建并嵌入”的阶段
- 后续更值得优先做运行时与设备侧验证，而不是继续卡在 `xcodeproj` 嵌入层

## 项目根路径

- 实际项目路径：`/Users/rui/Desktop/PhotoMemo`
- 当前 Codex 工作区里通常会通过 `desktop_project -> /Users/rui/Desktop/PhotoMemo` 映射访问真实项目

## 产品一句话

PhotoMemo 是一个 **local-first 的 macOS 原生照片信息纪念卡生成器**。  
它不是修图软件，也不是云相册，而是一个基于 EXIF 和时间锚点，把照片转成“带记忆语义的信息卡”的工具。

## 核心原则

- 完全本地运行
- 不上传照片
- 不修改原图，生成新图
- 主界面是“模板校准中心”，不是未来的批量工作台
- 日常处理流程要逐步转向外部接入 + 后台处理 + 写回系统图库
- 不能为了 UI 漂亮而脱离真实渲染/导出链路

## 当前主链路

1. 设置模板
2. 设置时间锚点
3. 导入一张预览照片
4. 读取真实 EXIF
5. 生成真实预览内容
6. 实时预览底部信息卡
7. 保存配置
8. 后续通过外部导入/分享进入后台任务
9. 生成新图并存回系统图库/目标相册

## 已经成形的能力

- SwiftUI macOS 主应用
- EXIF 读取
- 时间锚点引擎
- 四个自定义区域
- 模板预设
- 图标/徽章区域
- 预览渲染
- 导出成新图
- 写回系统图库
- 默认 PhotoMemo 相册策略
- 后台队列、通知、权限引导

## 时间锚点系统共识

智能模块只输出“时间结果本身”，不直接生成整句文案。

例如：

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_duration_text}}` -> `2年4个月18天`
- `{{anchor_elapsed_text}}` -> `已过32天`
- `{{anchor_countdown_text}}` -> `还有86天`
- `{{anchor_day_index_text}}` -> `第128天`

最终表达由用户自己在前后补文字，例如：

- `途途今天` + `{{anchor_age_text}}`
- `距离高考` + `{{anchor_countdown_text}}`

这条原则很重要，不要回退到“模块直接输出整句文案”。

## 当前界面共识

- 整体风格走白色、极简、系统级方向
- 主预览区只保留一张校准照片
- 下面四个区域都必须能独立编辑
- 插入 EXIF/智能模块时，必须进入“当前选中的区域”
- 深色模式下也要可用，但主视觉优先保证浅色系统风格
- Immers 风格只借鉴底部白边语言，内容仍以 PhotoMemo 的记忆语义与智能模块为主
- 当前“徽章/badge”语义已经统一往“Logo 标识”方向收束
- `immersWhite` 在未自定义标识时，保留经典 Apple 小 logo 作为默认回退

## 最近已经处理过的重要问题

最近对 `MainView.swift` 做过一轮关键修正，新的会话不要把这些修回去：

1. 去掉了“没有明确选区时默认插到右下角”的隐式兜底
2. 模块插入前必须先明确选中左上/右上/左下/右下某一区域
3. 开始把四个区域的模块编辑态从“字符串即时反解析”往“更稳定的本地状态”方向收
4. 修正了拖拽重排的目标索引逻辑
5. 模板切换、恢复默认、模板改名后，需要同步刷新模块编辑态

如果后续继续重构 `MainView.swift`，优先保留这些行为。

## 当前最大技术债

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` 已经明显瘦身，目前约 `72` 行，基本就是 coordinator state shell。

- 模板编辑
- 焦点/插入路由
- 拖拽与模块整理
- 权限状态
- 相册选择
- 导出动作
- 批量任务状态展示

最近已经抽出的 `MainView` 子文件包括：

- `MainView+MemoryProgress.swift`
- `MainView+OutputSection.swift`
- `MainView+Permissions.swift`
- `MainView+ComposerEditor.swift`
- `MainView+ComposerPanels.swift`
- `MainView+ComposerSession.swift`
- `MainView+TemplatePanels.swift`
- `MainView+SetupPanels.swift`
- `MainView+PreviewPanels.swift`
- `MainView+PermissionLifecycle.swift`
- `MainView+WorkspaceConfigurationState.swift`
- `MainView+ExportActions.swift`
- `MainView+DerivedState.swift`
- `MainView+CoordinatorSupport.swift`
- `MainView+TemplateEditingActions.swift`
- `MainView+PresentationState.swift`
- `MainView+StateModels.swift`
- `MainView+LayoutSections.swift`
- `MainView+UIPrimitives.swift`
- `MainView+ModalAndLifecycle.swift`
- `MainView+Feedback.swift`

这轮已经把 preview/detail 的显示壳层，以及 editor session / workspace configuration / export-save / permission lifecycle / derived state / template editing actions 都抽出去了。随后又把剩余 editor session 状态做了轻量分组，当前下一阶段更适合继续清理访问级别、少量 panel binding，以及补一轮手动回归，而不是为了拆而拆。

最近还补了三项当前体验修正：

- 相册权限被拒绝后，不再假装还能重新弹系统授权框，而是明确引导去系统设置恢复权限
- 年龄类智能模块在未满 1 岁时不再输出 `0岁...`
- `补充信息` 区已改成单卡片，勾选时使用单独批量说明，不勾选时回退到右下区域最终内容

随后单独起了一轮，把下面两条一起推进：

- 三个固定本地配置槽位，默认对应 `模板 1 / 模板 2 / 模板 3`
- 右侧负责“当前哪套配置生效”、保存到当前配置、恢复当前默认、打开操作指南
- 左侧复杂说明优先改成可关闭提示卡，完整说明收进右侧操作指南 sheet

这条线已经继续向前推进了一步，当前又补上了两项：

- 三个配置槽位现在支持单独自定义命名，用来区分“宝宝成长”“旅行纪念”“高考倒计时”等不同方案
- 右侧操作指南已升级为更像正式帮助中心的分组导航，入口菜单和帮助 sheet 都按主题分组

当前额外共识：

- 槽位命名只改配置槽位标签，不改模板名称
- 恢复槽位默认骨架时，只清除该槽位保存的配置快照，不会顺手清掉自定义槽位名称
- 左侧说明卡即使被用户关闭，完整说明仍可通过右侧帮助中心查看
- 当相册和通知都已授权时，侧边栏里的权限区不再继续占位
- 输出区优先保持“选相册 + 保存新图”主链，不再把元数据验证按钮留在主界面

最近又顺手做了一轮界面收口：

- `个性化区域` 的说明不再是写死文本，而是可关闭提示卡
- `补充信息` 已真正收成单卡，不再上下两块
- 帮助中心不再单独保留权限主题，改成只保留与当前主流程更相关的主题
- `MainView` 里原来那条已经没有界面入口的元数据验证调试支线也已经删掉

随后又完成了一轮更实质的 coordinator 收口：

- `MainView+ComposerSession.swift` 现在承接四个区域编辑器的 display text / selection / module span 会话态
- `MainView+WorkspaceConfigurationState.swift` 承接三个配置槽位的保存、切换、恢复默认和快照应用
- `MainView+ExportActions.swift` 承接相册权限申请、相册刷新、导出并写入系统图库
- `MainView+PermissionLifecycle.swift` 又继续承接了权限首启、scene active 刷新和通知权限反馈
- `MainView+DerivedState.swift` 承接预览、锚点、模板摘要等派生展示态
- `MainView+CoordinatorSupport.swift` 承接 anchor / preview 尺寸这类轻量 coordinator helper
- `MainView+TemplateEditingActions.swift` 承接模板值更新、模块插入和当前编辑区域路由
- `MainView+PresentationState.swift` 承接 rename / guide 相关 sheet 与本地 draft 状态
- `MainView+LayoutSections.swift` 承接 sidebar / detail 与各 section 的视图拼装
- `MainView+UIPrimitives.swift` 承接 `MainFieldSlot` 与主界面共用样式基元
- `MainView+ModalAndLifecycle.swift` 承接 body 外层 sheet / alert / 生命周期接线
- `MainView+Feedback.swift` 承接 alert helper 与 preview stub
- 同时已经把旧的 block-style composer widget / scrubber / literal-composer sheet 遗留清掉
- `MainView.swift` 当前大约回落到 `72` 行
- 这一轮 refactor 收口后，本地 `xcodebuild` 已重新通过

随后又补了一刀轻量 state grouping：

- `MainView+StateModels.swift` 现在统一承接 `MainAlertState`、`MainPresentationState`、`MainEditorSessionState`
- `MainEditorSessionState` 收起了 `focusedField`
- `MainEditorSessionState` 收起了四个区域的 display text / selection / module spans 会话态
- 这一步没有改插入逻辑、光标路由、模板同步或导出行为，只是把剩余 coordinator 状态按语义重新归位

这条线又继续推进了一小步，当前最新共识是：

- `个性化区域` 左侧不再保留顶部“额外控制/说明块”，界面只保留四个真实区域和插入按钮
- 自定义文字不再走原来的 raw token / inline editor 路径，而是作为和 EXIF、智能模块并列的单独文字 chip 进入区域内容流
- 再次点击已选中的文字 chip，可以直接回到文字编辑 sheet 修改当前这段文字
- `识别数据`、`智能数据` 继续保持按钮式插入，不把 `{{anchor_duration_text}}` 这类 token 直接暴露给普通编辑流程
- `补充信息` 和 `输出` 顶部说明都已经改成可关闭提示卡，完整说明继续放在右侧帮助中心
- 模板区里给用户看的“默认右下”文案已经改成更口语化的人类可读摘要，而不是 raw token

不过这条线又被用户继续纠偏了，当前最新真实方向应以这版为准：

- 四个自定义区域优先走“直接点进去输入”的内联编辑，而不是把用户短语拆成单独文字模块
- 点击上方 EXIF / 智能模块按钮时，要按当前光标位置插入到对应区域
- 正常编辑时不再把 raw `{{token}}` 暴露出来，而是显示成更人类可读的内联标签文本
- 如果后续继续打磨这一块，优先验证“光标位置是否准确保留”和“模块插入后前后继续输入是否顺手”，而不是先回到块状拖拽编辑

这条线随后又补了一步，当前最新交互目标还包括：

- 虽然底层已经回到光标式内联编辑，但模块在编辑区里的视觉表现要尽量接近“独立小方块”
- 光标贴着模块时，按删除应优先整块删除，而不是拆字符
- 编辑器显示映射不能只覆盖基础 token，像 `camera_summary` 这类模板里常用的组合 token 也必须转成可读标签，避免出现“半中文标签、半 raw token”的混合显示

如果后续继续这条线，优先检查：

- 切换配置后左侧字段和右侧预览是否同步刷新
- 未保存槽位是否正确回退到默认模板骨架
- 当前活动配置是否始终和 batch queue 默认配置快照保持一致
- 光标停在模块前后时，连续插入/删除是否仍然保持预期

## 建议优先阅读的文件

### 产品与文档

- `README.md`
- `AI_CONTEXT.md`
- `AGENTS.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/PRODUCT_SPEC.md`
- `Docs/MVP.md`
- `Docs/DEVELOPMENT_PLAN.md`
- `Docs/ANCHOR_SYSTEM_DESIGN.md`
- `Docs/BATCH_TASK_SYSTEM_DESIGN.md`

### 核心代码

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`

## 新会话接手时建议先做什么

1. 确认当前工作目录是否直接是 `/Users/rui/Desktop/PhotoMemo`
2. 读取 `README.md`、`AI_CONTEXT.md`、`HANDOFF.md`、`AGENTS.md`
3. 读取 `Docs/CURRENT_STATUS.md`
4. 看 `git status`
5. 检查 `MainView.swift` 与最新的 `MainView+*.swift`
6. 如需编译，用既有命令：

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## 当前工作流共识

本地已经安装适合后续开发的 skills：

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

后续处理非小改动时，优先按这个顺序推进：

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

## 当前最值得继续推进的方向

- 继续拆分 `MainView.swift`
- 优先收口访问级别与 ownership 表达
- 继续整理 badge / output / workspace 这类局部 binding
- 保证预览与最终导出一致
- 继续增强元数据保留策略
- 为未来 iOS 迁移减少 macOS 特有耦合

## 当前验证状态

最近几轮 `MainView` 拆分后，本地构建已通过。

已知情况：

- 编译通过
- 只存在 Xcode destination 选择 warning
- 当前 Xcode project 仍没有单独 test target，这一轮验证以 build 和结构 review 为主
- 仍建议补做手动 UI 回归检查：
  - 模板切换
  - 模板改名
  - 时间锚点选择
  - 照片导入
  - Live Context 与实时预览是否仍按当前模板刷新
  - `immersWhite` 默认 logo 回退
  - 预览与导出一致性
  - workspace slot 切换时的 caret 保留
  - 连续插入 EXIF / 智能模块时的光标路由

## Git 与同步说明

- 远程仓库：`origin git@github.com:serydoo/PhotoMemo.git`
- 当前主分支：`main`
- 已经建立了项目内 `.codex/skills`
- 发布/同步时，优先先检查构建、再看 `git status`、`git diff --stat`、最后 commit/push

## 给下一位 Codex 的一句话

不要把 PhotoMemo 当成“加边框工具”继续堆功能。  
它现在的真正方向是：**以模板、EXIF、时间锚点和后台处理为核心的本地照片记忆生成系统。**

## 2026-06-19 本轮补充

这一轮又继续往“稳住四个自定义区域的编辑模型”推进了一步，新增了：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift`

这次的关键调整不是视觉，而是编辑语义：

- 不再把所有长得像 `〔...〕` 的可见文字都当成真实模块
- 只把真正插入或从模板同步出来的模块，记录为带范围信息的 module spans
- macOS 与 UIKit 两条编辑路径都改为共享这一套范围语义
- 删除或替换跨过模块时，不再只误伤模块本体而丢掉外围普通文本

这意味着后续如果继续打磨这块，优先方向不该再回到 raw token 暴露，而是继续围绕：

- caret 是否稳定
- 选择替换是否自然
- 模块插入与整块删除是否顺手

本轮额外记录文件：

- `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- `Docs/COMPETITOR_NOTES_2026-06-19.md`
- `Docs/IOS_READINESS_2026-06-19.md`
- `Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md`

其中第一份记录了：

- 这次真正改了什么
- 为什么值得
- `MainView.swift` 下一轮最值得继续拆的三个区块

如果下一位 Codex 继续往下做，当前最值得继续清理的 3 块已经更新为：

- 访问级别收口
- badge / output / workspace 相关 binding
- 手动回归光标 / 槽位切换 / 保存反馈这三条高风险交互

第二份记录了：

- 2026-06-19 基于官网信息整理的相邻竞品/参考产品
- 各自最值得借鉴的亮点
- 对 PhotoMemo 后续产品提升最有价值的方向判断

第三份记录了：

- 当前仓库距离 iOS 开发的真实准备度
- 已具备的跨平台基础
- 当前主要 blockers 和最短启动路径

第四份记录了：

- 当前重构阶段最值得优先手动回归的链路
- 光标 / 模块插入 / 时间点 / 配置槽位 / 相册保存的检查步骤
- 每一步的预期结果与高风险回归信号

## 2026-06-19 晚些时候补充

这一小轮继续做了主界面收口，没有改导入、渲染、导出行为，主要是把用户能看到的主流程表述统一到当前固定模板 1 + 配置槽位方向：

- 右侧帮助中心不再混用“批量说明”“切换模板”等旧说法，统一改成当前的补充信息输入、配置槽位切换与保存语义
- 模板摘要不再展示 raw token 风格描述，`模板 1` 默认右下改为人类可读的“今天 + 年岁”
- 预览区、后台通知、补充信息预览等文案统一从“当前模板”进一步收口到更贴合现状的“当前配置”语义

本轮验证：

- 已再次通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 仍只有既有的 Xcode destination warning

这轮没有做新的手动 UI 操作验证，后续最值得继续盯的仍是：

- 参数摘要模块在模块左侧普通文本被删除后的显示/删除边界
- 配置槽位切换时四个自定义区域的光标与编辑态刷新
- 补充信息留空回退到右下内容时，预览与最终写回说明是否始终一致

## 2026-06-19 iOS 起步骨架

这一轮开始正式为 iOS 版本铺文件库与入口基础，但还没有在 `xcodeproj` 里新增 iOS target。

已经落地的结构：

- 新增共享 app runtime：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- 新增共享 root scene：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift`
- 新增 iOS 专属目录骨架：
  - `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSApp.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSHomeView.swift`

这一步的意义：

- macOS `PhotoMemoApp` 不再自己背外部图片接单与队列注入逻辑，入口层开始可复用
- 后续新增 iOS target 时，可以直接复用 `PhotoMemoAppRuntime` 和 `PhotoMemoRootSceneView`
- 现在的 iOS 文件库已经有了明确落点，后面继续加 iOS 专属 import/export/navigation 代码时不会再混回 macOS 入口

这轮特别注意：

- 还没有修改真实导入、渲染、导出链路
- 还没有真正把 iOS target 写进 `PhotoMemo.xcodeproj`
- `PhotoMemoiOSApp.swift` 与 `PhotoMemoiOSHomeView.swift` 目前是受 `#if os(iOS)` 保护的起步壳层，先为后续 target 接入做准备

本轮验证：

- 已通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 中途遇到一次新的 `MainActor` 初始化编译错误，已在 `PhotoMemoAppRuntime` 中改为 runtime 内部构造默认对象后解决

下一轮如果继续 iOS 线，最合理的顺序是：

- 给 `PhotoMemo.xcodeproj` 真正新增 iOS app target
- 把共享源纳入 iOS target，先追求可编译
- 再拆 app entry / intake / export 的 iOS 专属实现

## 2026-06-19 iOS target 已接入

这一轮已经把真正的 iOS app target 接进工程：

- 新 target / scheme：
  - `PhotoMemoiOS`
- 工程文件：
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

同时顺手补了两类基础兼容工作：

- 给现有 `AppIcon.appiconset` 补齐了 iPhone / iPad / marketing icon 描述与实际 PNG 文件，继续与 macOS target 共用同一套 asset catalog
- 帮助中心 `MainOperationGuideSheetView` 改成双平台导航实现：
  - macOS 继续 `NavigationSplitView`
  - iOS 改为 `NavigationStack + 分组列表 + NavigationLink`

这意味着当前仓库已经从“只有 iOS 文件库骨架”推进到“工程里真实存在一个可编译的 iOS target”。

本轮验证：

- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 iOS Simulator 泛目标：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

这轮真实踩到并解决的 iOS 阻塞：

- iOS target 最开始缺少可用 AppIcon
- 帮助中心的 `List(selection:)` / `NavigationSplitView` 用法不适合 iOS

下一轮如果继续 iOS 线，最值得优先推进的是：

- 让 `MainView` 在 iPad 竖屏/横屏下都更像正式可用界面，而不是仅仅“能编译”
- 开始拆 iOS 专属导出路径，例如 Photos-only / share sheet
- 开始整理 iOS 下不该继续暴露的 macOS 语义和交互细节

## 2026-06-19 iPhone 首轮适配

用户已经明确表示暂时不单独考虑 iPad，所以这一轮开始把 iOS 重点改成 iPhone 紧凑宽度体验。

这轮的核心不是“自动适配所有机型”，而是先把主界面改成更像手机产品的结构：

- iOS 首页不再是“预览 + 全量编辑”的超长单页
- 改成顶层 `预览 / 编辑` 分段切换
- 预览页优先展示：
  - 当前配置面板
  - 实时预览
- 编辑页优先展示：
  - 当前配置面板
  - 权限、照片、模板、时间点、四区编辑、补充信息、Logo、输出

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`

这一步的意义：

- iPhone 17 Pro Max / 15 Pro 这类设备现在虽然还是同一套 SwiftUI 代码，但已经不再单纯依赖系统“自动缩放”
- 现在主信息架构开始主动面向紧凑宽度编排，用户进入时先看预览，再切到编辑，心智更清楚

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- 输出区在 iPhone 上改成更明确的单主动作流程
- 导入/导出做更像 iOS 的路径，而不是继续沿用桌面心智
- 继续收紧手机端顶部信息密度和部分 section 的默认展开顺序

## 2026-06-19 iPhone 主链路第二轮

这一轮继续只做 iPhone 紧凑宽度体验，不碰底层渲染和相册写回实现。

重点推进了两件事：

- iPhone 的“预览”页现在不再只有预览本体，已经前置了：
  - 当前配置面板
  - 照片导入区
  - 输出区主动作
- 输出区在紧凑布局下改成更明确的单主动作表达：
  - 按钮文案直接带当前相册去向
  - 补了一条更贴近手机流程的说明，强调“先看预览，再保存”

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`

这意味着当前 iPhone 页面里，用户已经可以更顺地走完整个主链路：

- 导入照片
- 看预览
- 直接保存到当前相册

而不用一上来先掉进超长编辑页里找入口。

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- iOS 下导出后的分享路径或系统相册完成反馈，做得更像原生手机 app
- 继续把“编辑”页里次要内容往后放，减少第一次进入时的认知负担

## 2026-06-19 iPhone 反馈与降噪

这一轮继续沿着 iPhone 体验收口，但仍然没有改底层导出/保存实现。

主要补了两件事：

- iPhone 紧凑布局下，保存成功后不再只有系统 alert
  - 额外补了一张短时出现的轻量成功反馈卡片
  - 文案会直接告诉用户已经写入哪个相册，并提示可以继续下一张
- 编辑页继续降噪
  - 首次进入编辑页时，主视觉更集中在模板、时间点、四区编辑和输出

## 2026-06-19 主界面职责再收口

用户已再次明确：

- 主界面永远只负责设定参数、自定义信息和实时预览
- 后台处理进度不应继续占用主界面区域

因此这一轮又补了一次职责收口：

- macOS 主界面移除了 `记忆进度` 可见面板
- iPhone 编辑页也移除了 `记忆进度` 展示入口
- 帮助中心 overview 中不再把 `记忆进度` 当成主界面组成部分描述

这意味着当前仓库的真实共识已经变成：

- 主界面 = 校准中心
- 后台自动处理 / 通知 / 后续灵动岛 = 独立的后台能力
- 两者可以共用同一套配置，但不应在一个界面里混着表达

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Feedback.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- 把保存完成后的下一步动作做得更像 iOS，例如分享或继续处理的轻动作
- 继续梳理编辑页里哪些 section 适合默认折叠/后置，进一步降低第一次使用压力

## 2026-06-19 后台自动处理感知层

用户已经进一步明确真实使用模式应当是：

- 在系统相册或其他位置选中图片
- 通过分享发送到 PhotoMemo
- 后台自动处理
- 按预设配置直接写入指定相册
- 用户不需要逐张盯着保存

这一轮先没有直接上分享扩展或灵动岛，而是先把现有后台队列的“进度感知层”补强，作为下一步的基础。

已落地：

- 后台批次不再只有“开始接收”和“最终完成”两次通知
- 新增了三个批次级阶段进度通知：
  - `imported`
  - `rendering`
  - `saving`
- 每个批次会记住自己上一次已发送的阶段，避免同一阶段重复刷通知

相关文件：

- `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchNotificationService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`

这一步的实际意义：

- iPhone / Mac 端现在更接近“设好相册后不用继续操心”
- 通知栏里能看到后台任务不是卡死，而是在读取、生成、写入中的哪一段
- 后续如果继续接灵动岛 / Live Activity，这一套 stage 摘要可以直接复用，不用重新发明一遍后台进度模型

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续按用户这条“后台自动处理”路线推进，最值得优先做的是：

- 真正接入 iOS share extension，让系统分享可以把图片送进当前后台队列
- 再做 `Live Activity / 灵动岛` 方向的进度展示，而不是继续只依赖本地通知

## 2026-06-19 外部接单持久化基础

这一轮没有把进度放回主界面，而是继续沿着“分享进入后台自动处理”的真实方向补底层：

- 新增共享容器与 App Group 基础：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- 新增持久化外部收件箱：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- `ExternalPhotoIntakeCenter` 现在不再只靠内存暂存请求：
  - 外部 URL 进入时会优先复制到共享收件箱目录
  - 请求描述会持久化到共享 `UserDefaults`
  - App 下次激活时仍可继续自动消费
- `SettingsService`、`BatchQueueStore`、`PermissionCenter` 已切到共享 `UserDefaults` 入口，给未来 iOS Share Extension 复用默认配置和基础状态留好接口
- `PhotoMemoAppRuntime` / `PhotoMemoRootSceneView` 现在会在激活与初次进入时主动刷新外部接单状态并消费持久化请求

这一步的意义：

- 后面即使分享扩展与主 App 不是同一进程，也已经有可复用的收件箱和配置来源
- 主界面依旧保持“参数设定 + 自定义信息 + 预览”职责，没有重新引入后台进度面板

下一轮如果继续这条线，最合理顺序是：

- 正式新增 iOS Share Extension target
- 让扩展端把共享图片/URL 写入当前收件箱
- 主 App 继续沿现有 runtime 自动入队，不改主界面信息架构

## 2026-06-19 外部收件箱清理补充

这一小轮继续只补后台接单基础，不动主界面信息架构。

新增收口：

- `ExternalPhotoIntakeStore` 现在除了持久化请求，还负责清理自己复制进共享收件箱的源文件
- `BatchQueueStore` 在两条安全终态路径上接入了回收：
  - 单张任务处理完成后
  - 整个 job 被用户取消时

这次特意没有在失败态就删文件，因为失败任务还需要保留源图用于后续重试。

当前共识：

- 只清理 `ExternalIntake` 目录内、由 PhotoMemo 自己复制进去的托管文件
- 不碰用户原始文件路径
- 不影响现有导入、渲染、导出、写回图库行为

## 2026-06-19 外部收件箱孤儿目录整理

这一小轮继续补后台接单地基，目标是覆盖“上次处理中途退出”之后的残留目录。

新增收口：

- `BatchQueueStore` 现在会暴露当前任务仍在引用的托管源图 URL 集合
- `PhotoMemoAppRuntime.refreshExternalIntakeState()` 在每次启动/激活刷新外部接单状态前，会先让 `ExternalPhotoIntakeStore` 扫描 `ExternalIntake` 目录
- 没有任何请求或任务继续引用的孤儿文件/目录，会被自动整理掉

当前共识：

- 正在排队、处理中、失败待重试的托管源图不会被误删
- 只清理共享收件箱里的孤儿内容，不扫描用户原始目录

## 2026-06-19 iOS Share Extension 最小骨架

这一轮开始把真正的 iOS 分享入口接进工程，但仍然坚持“小切片、先求可编译”的节奏。

已落地：

- 新增分享扩展接单服务：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- 新增极简分享扩展入口控制器：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- 新增扩展专用 `Info.plist` 与 entitlement：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtension-Info.plist`
  - `Source/PhotoMemo/PhotoMemo/PhotoMemoShareExtension.entitlements`
- `ExternalPhotoIntakeStore` 现在支持：
  - 扩展端先把分享进来的图片复制到共享收件箱
  - 再直接写入持久化请求，而不依赖主 App 进程内状态
- `PhotoMemoiOSApp.swift` 已加编译条件，避免 share extension target 编译时与 app 的 `@main` 入口冲突
- `PhotoMemo.xcodeproj` 已新增：
  - `PhotoMemoShareExtension` target

当前结果：

- iOS 主 app 仍可编译
- 新的 `PhotoMemoShareExtension` target 已可编译
- 当前还有一个非阻塞告警：
  - 扩展 target 的 Copy Bundle Resources 里包含了它自己的 `Info.plist`
  - 不影响当前构建通过，后续可以继续做工程级清理

这一步的真实意义：

- PhotoMemo 已经不再只是“未来可能支持分享扩展”
- 现在仓库里已经有了一个真实、可编译、能把分享图片送进共享收件箱的最小扩展骨架

下一轮如果继续这条线，最值得优先做的是：

- 用真实 `NSExtensionContext` 手动回归分享一张/多张图片的行为
- 继续清理 extension target 当前仍不必要编进来的主 app UI/服务文件范围
- 再决定是否要做“分享成功后自动唤起主 App”这类体验层动作

## 2026-06-19 ExternalIntake 纯临时策略收紧

这一轮根据最新共识，把共享收件箱里的托管源图进一步明确为“纯临时文件”，不再走失败后长期保留路线。

已落地：

- `ExternalIntake` 托管副本在三类终态都会清理：
  - 成功完成
  - 用户取消
  - 处理失败
- 对于这类失败任务，`BatchTaskFailure` 现在会显式标记：
  - `canRetry = false`
- `BatchQueueStore.retryFailedTasks` 只会真正重排那些仍可重试的失败项
- 批量任务持久化前会对终态历史做数量裁剪，避免队列记录无限增长

当前共识：

- `ExternalIntake` 里的托管文件不是长期缓存，也不是恢复仓库
- 真正边界仍然不变：
  - 只能清 PhotoMemo 自己复制进 `ExternalIntake` 的文件
  - 不碰用户原始路径
  - 写回系统相册的成品不当缓存处理

## 2026-06-19 少量失败作为例外处理

这一轮继续沿后台自动处理路线，把“很多照片里只失败 1 张”的表达方式收得更符合真实使用体验。

已落地：

- 当一批任务大多数已成功完成时，不再把整批语义简单打成“失败”
- `BatchJob` 现在会区分：
  - 整批失败
  - 部分完成
  - 大部分完成，仅少量例外
- 通知文案、失败摘要文案都已同步收口：
  - 例如更接近“已完成 99 张，另有 1 张作为例外未处理”
- 对于已经按纯临时策略清掉托管源图的失败项，会明确标记不可重试，不再给出误导性的重试入口

这样处理的原因：

- 用户真正关心的是“成功的大多数已经进相册了没有”
- 少量失败项应该作为例外单独提示，而不是把整批结果整体抹黑

当前共识：

- 成功结果先算成功写回
- 少量失败单独列出
- 失败原因保留可查
- 只有仍具备真实重试条件的失败项，才继续提供重试动作

## 2026-06-19 Share Extension 工程告警收口

这一小轮还顺手把 share extension 的 `Info.plist` 资源告警收掉了：

- 扩展专用 `Info.plist` 已挪到同步组外层：
  - `Source/PhotoMemo/ShareExtension-Info.plist`
- `PhotoMemoShareExtension` target 改为引用这份 plist

当前结果：

- macOS app 可编译
- iOS app 可编译
- `PhotoMemoShareExtension` 可编译
- share extension 原来的 `Info.plist` Copy Bundle Resources 告警已消失

## 2026-06-19 Share Extension 首轮瘦身

这一轮没有改主界面，也没有改真实导入/渲染/导出链路，主要是把分享扩展对主 app 设置系统的依赖先拆薄一层。

已落地：

- 新增轻量共享快照读取器：
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- `PhotoMemoShareExtensionIntakeService` 不再直接依赖完整的 `SettingsService`
- 扩展端现在只通过共享 `UserDefaults` 读取：
  - 模板
  - 徽标
  - 时间点
  - 说明写入开关
  - 相册标识
  然后组装 `BatchConfigurationSnapshot`

这一步的意义：

- share extension 不再为了拿默认配置而拖进整套设置观察/保存语义
- 后续继续瘦 target 时，有了更清晰的共享边界

当前结果：

- macOS app 可编译
- iOS app 可编译
- `PhotoMemoShareExtension` 可编译

下一轮如果继续这条线，最值得优先做的是：

- 继续把 extension target 当前仍然会编进来的主 app 视图/权限/照片库写回相关文件尽量剥离
- 为真实系统分享手动回归做准备

## 2026-06-19 Share Intake 稳定性补强（二次）

这一轮继续沿着 iOS 分享入口做，但重点不是扩功能，而是先把“看不见的坏情况”压下去。

本轮已落地：

- 新增共享相册选择语义：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAlbumSelection.swift`
- `SharedBatchConfigurationSnapshotService` 不再为了“自动相册”标识去依赖 `PhotoAlbumOption`
- `SettingsService` 也已切到同一套共享相册标识规范化逻辑
- `ExternalPhotoIntakeStore.persistManagedRequest(...)` 在请求列表写入失败时，会立即清理已经复制进去的托管临时文件
- `ExternalPhotoIntakeStore.persistRequest(...)` / `ExternalPhotoIntakeCenter.submit(...)` 都会先做重复 URL 去重
- `PhotoMemoAppRuntime.flushExternalRequests()` 现在会先过滤掉已经不存在的源文件：
  - 全部失效：直接跳过，并清理 PhotoMemo 自己管理的临时副本
  - 部分失效：只把仍然存在的那部分照片入队
- `PhotoMemoShareExtensionIntakeService` 现在返回一个结构化导入结果：
  - `importedCount`
  - `skippedCount`
  - `failedCount`
- share extension 侧的真实行为现在变成：
  - 单个 provider 失败，不再把整次分享直接判死
  - 只要至少有一张成功写进共享收件箱，就算接单成功
  - UI 文案会区分“全部成功”和“部分成功、附带跳过/失败计数”
- 分享 fallback 目前只保留两类：
  - `file URL`
  - `raw Data`
- 已明确**不**使用：
  - `UIImage -> JPEG` 重编码 fallback

这一条很重要，不要为了“更多来源都能进”把它再加回去，因为那样会有两个真实风险：

- 可能丢 EXIF
- 可能在进入 PhotoMemo 之前就已经改变图片二进制内容

当前这一轮的真实意义：

- 共享收件箱更接近“可靠的临时接单层”，而不是“偶尔会留下垃圾和坏单子的黑盒”
- 失败和部分成功的语义更贴近真实用户感受
- 元数据保留优先级继续压过“表面兼容更多输入”

本轮构建验证：

- 已通过：
  - `PhotoMemoShareExtension`
  - `PhotoMemoiOS`
  - `PhotoMemo`
- 告警情况：
  - macOS 仍只有原来的 destination-selection warning

下一轮最值得优先做的事：

1. 真实设备/模拟器手动回归系统分享一张、多张、部分失效的情况
2. 继续观察 share extension target 当前仍被同步组编进去的主 app 文件范围，评估是否还值得再拆共享边界
3. 如果系统分享来源出现只给 `UIImage` 不给原始文件/数据的 App，再单独设计“拒收并解释原因”策略，而不是偷偷重编码接入

## 2026-06-19 Share Extension 编译面收口

这一轮继续做 share extension，但不是继续加功能，而是把 target 真正压回“共享接单核心”。

本轮已落地：

- 在 `PhotoMemo.xcodeproj/project.pbxproj` 里，为 `PhotoMemoShareExtension` 新增了同步组例外配置：
  - `PBXFileSystemSynchronizedBuildFileExceptionSet`
- 这套例外配置已经把一大批与分享接单无关的文件排出扩展 target：
  - `Views/*`
  - `PhotoMemoApp.swift`
  - `PhotoMemoAppDelegate.swift`
  - `PhotoMemoRootSceneView.swift`
  - `PhotoMemoiOSApp.swift`
  - 大部分 renderers / export / permission / queue / engine 文件
- 这条路已经被证明可行，不需要靠更多 `#if` 去硬隔离主 app UI

这一轮还顺手抽出了一份真正该共享的模型：

- 新增：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- 原因：
  - 之前 `ExternalPhotoIntakeRequest` 还定义在 `ExternalPhotoIntakeCenter.swift`
  - 一旦扩展 target 把 `ExternalPhotoIntakeCenter.swift` 排掉，`ExternalPhotoIntakeStore` 就失去请求模型定义
- 现在共享边界更干净了：
  - `ExternalPhotoIntakeStore` 依赖共享请求模型
  - `ExternalPhotoIntakeCenter` 只负责主 app 侧的提交与 drain 协调

当前最直观结果：

- `PhotoMemoShareExtension.SwiftFileList` 目前约 `19` 行
- 也就是 share extension 现在主要只编：
  - 共享收件箱持久化
  - 共享默认配置快照读取
  - share extension 自己的 intake / view controller
  - 少量必要模型

这一步的意义很实在：

- 真正把“主 app 校准中心”和“iOS 分享接单入口”拆成了两个更清楚的责任面
- 后续如果分享入口出 bug，不需要再怀疑 `MainView`、预览、模板视图是否拖进 target 造成噪音
- 后续继续做 iPhone 分享流、后台接单、失败例外处理时，工程复杂度会低很多

本轮还补了一个小体验修正：

- share extension 的成功提示现在只会展示非零的 `跳过 / 失败` 计数
- 不会再出现“失败 0 张”这种不自然提示

本轮构建验证：

- 已通过：
  - `PhotoMemoShareExtension`
  - `PhotoMemoiOS`
  - `PhotoMemo`

下一轮最值得继续的方向：

1. 真机/模拟器手动验证分享 1 张、多张、部分失效、重复来源
2. 视情况继续把扩展 target 资源面也收一轮，例如是否还需要把共享 asset/catalog 继续缩小
3. 如果真实分享来源暴露出新的 provider 形态，再决定是否补更明确的拒收提示或来源兼容策略
