# PhotoMemo Handoff

这份文件用于帮助新的 Codex 会话快速接手当前项目，避免只依赖历史聊天上下文。

现在仓库根目录还新增了一份更偏“持续接力开发手册”的文档：

- `AI.md`

建议新的 AI 会话把它也作为第一批必读文件之一。

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
