# 横屏配置中心：实机观察与空间方案

> Current checkpoint (2026-10-07): the owner provisionally accepts the small-phone landscape UI and authorizes source synchronization. The current implementation reserves the rail region, supports contextual preview collapse, unifies panel/header alignment and uses icon-only navigation selection. Earlier observations below are chronological evidence. Small-phone two-pane exploration is superseded; native Duo integration and the comprehensive keyboard/accessibility matrix remain open. See [source checkpoint](2026-10-07-landscape-source-checkpoint.md).

日期：2026-10-07。状态：导航避让首个增量已实施；预览/编辑分区仍为实施前规格，实机验收待完成。
基线：2.3.6（124）签名Debug研究包，包含当前未提交floating rail。
本次产品所有者要求先研究横屏整体方案，尤其两端安全区、二级页面和卡片内容编辑可达性。

## 观察证据

原始截图位于所有者Downloads，本文件只引用，不复制私有内容进Git：

| 证据 | 观察 | 分类 |
| --- | --- | --- |
| IMG_6484 | 首页卡片右边缘与导航胶囊接近/重叠；横屏顶栏和主内容重复占用高度 | P1交互避让；P2层级 |
| IMG_6485、6487、6488、6490 | 保存按钮漂浮于当前滚动内容之上；尾部选择/箭头贴近导航；展开内容很宽 | P1可达性/避让；P2可读宽度 |
| IMG_6489 | 时间表达说明与控件横向拉开，示例占整块宽度，层级与对齐关系松散 | P2密度/分组 |
| IMG_6486 | 完整预览几乎占满横屏高度，下面保存操作仅部分可见 | P1高度预算 |
| IMG_6491 | 卡片内容编辑页大预览之后仅剩标题与动作，输入区没有有效显示空间 | P1主编辑路径 |
| IMG_6492 | 同一内容页竖屏能同时显示预览、四个输入区和说明，可作为保持行为的参照 | 竖屏兼容基线 |

本轮live截图`/tmp/MemoMarkAdaptive236-landscape-live.png`为2868×1320进展页，已查看。
其任务卡片右缘也接近rail，证明问题跨首页/配置/进展，不是单个卡片的局部padding。
截图不证明灵动岛位于哪一端，也未覆盖系统Menu弹出、照片/地点编辑、键盘和辅助功能全部状态。

## 代码原因与归属

- AdaptiveNavigationShell 在 NavigationStack 外用trailing overlay +10pt偏移绘制rail。overlay不为子页面保留空间，故页面不知道它的交互区域。
- MemoryCardEditorPageSurface 的previewPane不在editorScrollView中，compact vertical不进入split；横屏仍是上预览/下编辑。
- MemoryCardPreviewSection从宽度和aspect ratio求高度。图片按宽度增大时，预览可耗尽页面高度。
- ConfigurationPreviewVisibilityState在卡片内容编辑期间强制预览可见。这条“编辑时可见”的语义合理，但目前与“宽度驱动的全尺寸固定顶部预览”绑定，导致编辑区饥饿。
- MemoryCardRegionEditorCluster已经拥有自己的ScrollView/ScrollViewReader和TextKit焦点揭示。外面再套同方向ScrollView会引入两个滚动所有者，不能作为快捷修补。
- ConfigurationActionFooter在bottom safeAreaInset内，但透明宿主允许内容视觉上从按钮后经过；截图证明视觉碰撞，不证明最后一项永远滚不到。
- 既有readable maxWidth=720限制存在，不等于所有展开内容都获得适合短文本/二级编辑的可读宽度。

Product Loop/P1：只调整Presentation空间、避让、滚动与动作宿主。
Session、Memory Engine、Layout Engine输出、Renderer/Export、Photos/Live Photo、Preset schema不变。
原有输入line box、附件/caret/IME/undo和四个区的语义不变。

## 设计原则

### 所有者对两侧空间的补充问题

所有者询问横屏主体能否从居中改为向左右利用空间：可以，而且符合本轮空间适配目标。
当前adaptivePageContent采用maxWidth720 + 居中；这只是项目已有可读列规则，不是Apple要求。
下一候选布局的外层区域应填满“系统safe area减rail保留区”后的可用宽度；
内部照片保持比例、短文本/输入保留合理行长，局部控件不机械拉成全宽。
rail位于一侧时可用内容区本来不对称，内容不必继续围绕物理屏幕中心强制左右等留白。
若只是移除720限制而仍在顶部按宽度扩大预览，会进一步增加高度、恶化编辑不可达，
所以外层空间利用必须与预览/编辑双区和高度预算一起落实。

本轮随后再次采集卡片内容页`/tmp/MemoMarkAdaptive236-card-content-landscape.png`（2868×1320），
已查看：输出预览与标题/插入信息/完成可见，四个输入区仍无有效显示空间，
预览右箭头贴近rail。与所有者IMG_6491一致，确认问题持续。
这一截图仍不能独立证明两种横屏方向的全部safe-area差异。

完整展示输出 = 整张真实卡片按比例可见；不等于最大宽度、固定顶部或默认裁切放大。
编辑时优先保证当前控件可达，完整预览提供反馈；阅读输出细节使用现有放大审阅入口。
普通配置页的已接受展开/收起状态、竖屏标题节奏继续保留；本次观察授权新的compact-height空间研究，不自动改写历史规则。

## 导航与两端安全区

保持导航逻辑位置稳定，不因灵动岛端变化自动左右跳动。布局依据当前window/view safeAreaInsets、layout direction和实际可用区域，不查设备型号、物理屏幕尺寸或猜测朝向。

将rail的实际可交互宽度、内外边距纳入统一trailing保留区域，优先评估safeAreaInset或等价受测布局容器。浮动视觉与内容避让可以同时成立：背景仍可延伸，文字/输入/按钮/预览导航不进入rail区域。

灵动岛同端：系统该端避让 + rail自身占位 + 内容与rail的设计间隔。
灵动岛异端：两端各自使用系统safe area；导航端另外保留rail自身占位。
不得重复叠加系统已消费的safe area，也不得用固定额外“刘海宽度”。
系统安全区随窗口/横屏方向变化；设计间隔采用已有spacing token。最终数值在同端/异端实机证据下验收，不从截图加减1pt。

## 预览/编辑方案比较

| 方案 | 好处 | 代价 | 结论 |
| --- | --- | --- | --- |
| 全宽预览固定顶部 | 大图直接 | compact-height挤掉编辑区/键盘区 | 停止作为横屏编辑默认 |
| 整页向上滚动 | 容易到达下方，低高度适用 | 输出反馈滚出屏幕；须消除重复滚动owner | 作为低空间回退候选 |
| 局部内容放大常驻 | 输出文字易读 | 失去完整构图、不同四类卡片区域不统一 | 只用于显式细节审阅，不作默认 |
| 完整预览与编辑区并排 | 同时看完整结果和控件，利用横向空间 | 需明确最小编辑宽度和字体/键盘回退 | 推荐横屏空间足够时采用 |

2026-10-07所有者后续确认：普通小屏iPhone横屏卡片内容保留当前编辑方式，通过侧边开关收起/恢复预览，不继续推进双栏。以下并排候选仅继续用于Duo等空间充足的形态，须原生布局集成与独立验收。

宽屏候选：完整预览伴随区 + 独立滚动的配置/输入区 + 被避让的导航。
预览在逻辑leading一侧，编辑在trailing一侧，rail在编辑区外侧保留位置；RTL保持逻辑顺序。
这只是同一Interactive Memory Card + Object Inspector的空间安排，不新建编辑流程。

预览fit同时受可用宽度和高度限制：以真实输出aspect ratio计算容纳尺寸，不拉伸、不裁掉底部信息。
编辑区先取得使现有输入和局部动作可用的最小宽度，预览使用剩余空间；不固定各50%，不按设备名定宽。
候选minimum/ideal ranges必须在下一实现规格中用控件测量、四语言和字体大小确定；本轮不把估计pt值提升为产品常量。

小窗口/辅助功能大字/键盘导致双区不可用时，回退可滚动单列；如保留顶部预览，必须有经测量的高度预算且不得压缩当前输入区为零。
回退涉及preview/editor滚动所有者，先证明UIView/TextKit实例、draft、selection/markedText、undo和focus保持，再切换容器。
不使用滚动到阈值自动裁切/突然缩小图的装饰动画。

卡片内容页：四个区域仍维持明确的竖向顺序，不把输入框拉成整屏宽，也不仓促改为2×2。右侧标题/插入信息/完成形成局部动作区；输入列表滚动由既有cluster负责。
键盘出现时当前输入优先可见，module library不可占满编辑剩余高度；允许滚动到active region。输出详情继续走独立放大审阅，不能为了查看文字强制放大常驻预览。

## 二级内容与保存动作

- 首页/进展：保持可读内容列，rail占位由shell统一提供；不逐卡片补右边距。
- 时间锚点/保存相册：label/value保持语义相邻；Menu采用系统popover避让，不铺满横屏。
- 时间表达：说明、选择控件、示例使用同一有界内容列；短选项优先固有宽度，四语言不足时复用现有ViewThatFits/menu回退。
- 四类卡片样式与时间/地点页：适配available width，不复制手机纵向页面后机械放宽；当前截图未覆盖全部具体二级页，实施前补证据。
- 卡片内容：使用上述预览/编辑双区，不改变输入geometry。
- 保存：保留已接受的compact保存按钮/更多动作与回调，在横屏提供明确的背景和被保留区域；不复制第二个保存入口，不重新启用已撤回的wide footer/tab accessory方案。
- 内容滚动最终位置须能完整停在保存区上方；按钮不能遮挡仍需操作的最后一行。

## 有界实施顺序与验收

1. 修复shell级rail占位/双端safe area，三个目的地统一消费；focused geometry/contract tests与两方向实机。
2. 根据本研究记录low-height预览/编辑布局规格，复用AnyLayout/现有surface；不同时重写iPad/macOS/Duo。
3. 容器级高度与滚动owner先验证，再适配card-content与其他二级内容。
4. 保存区域与展开内容在一次整体UI pass中收尾；所有布局数值从语义token/控件要求取得。
5. signed-device build/install/launch之后验收：两横屏方向×预览展开/收起×四类样式×键盘开/关；dirty draft、focus/IME/undo、module insertion、navigation和preview inspection state不变；四语言/VO/DT/Reduce Motion。

当前A1仍为未通过，截图已证明需要修正，不能用此前89个host测试宣告视觉通过。
本轮只研究与记录，不修改产品Swift、不重新安装未经设计的布局。

## 官方依据

- Apple Layout：https://developer.apple.com/design/human-interface-guidelines/layout
- Apple Scroll views：https://developer.apple.com/design/human-interface-guidelines/scroll-views
- safeAreaInset：https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)

Apple指导支持safe areas/可用空间适配并避免同方向滚动嵌套；双区推荐是本项目的设计判断，不声称Apple要求此特定布局。
# Accepted implementation sequence — 2026-10-07

The owner accepted use of the available side space and requested joint Duo
research. This supersedes the earlier requirement that the ordinary landscape
rail must overlay the full content viewport.

First increment (Product Loop, P2): use a trailing native safe-area inset for
the existing three-button rail, with 12pt content separation and the existing
10pt outer margin. Safe-area ownership remains with SwiftUI; do not duplicate
notch insets or detect a device orientation. Content is centered inside its
remaining region. Preserve destination binding, input geometry, configuration,
preview visibility and all media/output behavior. Verify existing architecture
contracts, signed iPhone build and physical landscape screenshots. This fixes
the navigation overlap; it does not close preview/editor height starvation.

Following increment (Product Loop, P1): specify preview/editor height and width
budgets, keyboard and accessibility fallback before changing the page container.
Keep a single editor scroll owner and the existing TextKit session. Duo native
navigation and arrangement need a separate capability integration and device
acceptance; an ordinary-phone screenshot cannot certify Duo.

First increment evidence: 65 focused host tests passed, signed iPhoneOS Debug
build and strict signature verification passed, installed/launched on the paired
iPhone 17 Pro Max. Applying the inset outside NavigationStack was ineffective
on Home; the final placement is inside its destination host. Viewed final
landscape Home capture `/tmp/MemoMarkLandscapeRail-inside-navigation.png`:
content shifts left and its card edge clears the rail. Both notch-side rotations,
card editing, keyboard and manual owner acceptance remain open. Output package
version is still 2.3.6(124), not a new release.
