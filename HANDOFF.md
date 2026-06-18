# PhotoMemo Handoff

这份文件用于帮助新的 Codex 会话快速接手当前项目，避免只依赖历史聊天上下文。

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

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` 仍然过大，目前约 `3974` 行，虽然已经显著下降，但仍承担了太多职责：

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
- `MainView+ComposerWidgets.swift`
- `MainView+ComposerPanels.swift`
- `MainView+TemplatePanels.swift`
- `MainView+SetupPanels.swift`
- `MainView+PreviewPanels.swift`

这轮已经把 preview/detail 的显示壳层抽出，下一阶段应继续清理剩余的编辑态、插入路由和同步 helper，优先往 coordinator 方向收束，但不要破坏当前真实链路。

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

- `记忆进度` 的帮助说明现在也可关闭
- `个性化区域` 的说明不再是写死文本，而是可关闭提示卡
- `补充信息` 已真正收成单卡，不再上下两块
- 帮助中心不再单独保留权限主题，改成只保留与当前主流程更相关的主题

如果后续继续这条线，优先检查：

- 切换配置后左侧字段和右侧预览是否同步刷新
- 未保存槽位是否正确回退到默认模板骨架
- 当前活动配置是否始终和 batch queue 默认配置快照保持一致

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
- 优先收束剩余 inline 编辑态 / 路由 helper
- 继续收束四个区域的编辑状态
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

## Git 与同步说明

- 远程仓库：`origin git@github.com:serydoo/PhotoMemo.git`
- 当前主分支：`main`
- 已经建立了项目内 `.codex/skills`
- 发布/同步时，优先先检查构建、再看 `git status`、`git diff --stat`、最后 commit/push

## 给下一位 Codex 的一句话

不要把 PhotoMemo 当成“加边框工具”继续堆功能。  
它现在的真正方向是：**以模板、EXIF、时间锚点和后台处理为核心的本地照片记忆生成系统。**
