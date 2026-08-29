# MemoMark：基于更新后 Skills 的 UI、交互与代码审查

- 日期：2026-08-28
- 状态：Audit / Recommendation Only；未授权实施
- 源码基线：`main @ 053abc96553b06572928a132fbeb91ed3acab613`，`2.2.2 (95)`

## 范围与证据边界

本轮响应用户要求，应用今天维护过的本地 Skills，复核当前主入口、卡片内容编辑、
对象/锚点维护、输出配置、媒体导出与测试边界。不是全仓逐行审计，也不是生产认证。

- 主循环：Engineering Loop，以源码、现有契约与可重复检查为依据。
- 后续涉及视觉取舍、手势体验和大字号设计的工作，应另开 bounded Product Loop UI pass。
- 保留 Configuration Center、Memory Engine、Layout Engine、Renderer 和 durable aggregate 的所有权。
- 本轮只新增审查记录、更新状态；没有修改生产源码、测试源码、项目设置或 Skills。
- 没有迁移 Swift 语言模式、安装工具链、上传照片、修改原始媒体、安装 iPhone 包或外部发布。
- 配对实体 iPhone 17 Pro Max 的开发者模式已开启，但本轮设备查询显示连接不可用。
  未获取当前 App 截图，未执行 VoiceOver、输入法、动态字号、手势或 Photos 真机验收。
- TX-001/BP-001 carryover 与 `FAIL (Conditional)` 保持不变；不重启用户已停止的 BP-001 Instruments 项目。

## 实际应用的 Skills

| Skill | 本轮作用 |
| --- | --- |
| `memomark-ui-reviewer` | 状态所有权、Object Inspector、TextKit、浮层语义和验收边界 |
| `memomark-quality-gates` | 区分无障碍、本地化、性能和实体设备证据 |
| `swiftui-patterns` | SwiftUI 状态传播、异步任务、视图组合与 actor 边界 |
| `code-reviewer` + Swift/universal rules | 引用生命周期、错误处理和实际调用链 |
| `karpathy-guidelines` | 控制范围，避免根据代码味道直接要求重写 |
| `memomark-product-manager` | V4 优先级、冻结架构和不扩张功能面 |
| `memomark-media-fidelity` + `photokit` | 资源身份、权限、原图保护、照片生命周期 |
| `memomark-renderer-contract` | 预览/输出契约及导出执行位置 |
| `swift-testing` + `swift-protocol-di-testing` | 选择聚焦测试、异步边界注入和证据分类 |
| `verification-loop` | 测试、检查、结果记录和未验收项 |

Skills 是审查规则，不是自动修复或质量证明。没有因为可用就启用 ActivityKit、后台处理、
Simulator、Liquid Glass 或新依赖；也没有机械地把所有 ObservableObject 改为 Observable。

## 优先发现

### 1. P0 风险：对象/锚点保存期间的后续修改可能没有进入 durable aggregate

**证据：静态调用链已确认；未进行真实持久化延迟注入或真机丢失复现。**

入口：`iOS/Views/V1IOSSubjectAnchorDetailSection.swift:196–234`。
锚点删除、提交编辑先改变 `session`，随后调用 `onPersistSubjectChanges()`。
该面没有接收或使用根视图的 `isPersistingSubjectChanges` 来限制后续操作。

保存：`iOS/Views/MemoMarkiOSV1View.swift:1828–1905`。

- `:1830` 遇到正在保存时直接返回，没有登记待保存的新快照。
- `:1864–1873` 冻结 candidate 后异步保存；`ConfigurationCoordinator.swift:280,291`
  有真实的异步 diagnostics/repository 边界。
- `:1874–1878` 完成后直接把旧 candidate 作为 configuration library 引用写回。
- `:1892` 写回 `.subjectSynced`，没有核对当前 subject、configuration 或编辑代次。
- `ConfigurationSession.swift:189–193` 的该 setter 是直接赋值，不会自动合并较新编辑。
- `V1ConfigurationStatus.swift:76–83` 把 `.subjectSynced` 视为没有待提交修改。

风险时序：保存 A 挂起 → 用户又改/删锚点 B → B 的保存请求被忙碌 guard 丢弃 → A 完成并显示
“已同步”。B 可能仍存在于临时 session，却没有进入 durable aggregate，离开或重启后有丢失风险。
这不证明已有用户数据事故，也不把每次快速操作都描述为必然丢失。

**方向：**在现有配置持久化所有者内合并后续保存请求；回执仅更新对应版本，较新编辑继续保持
待保存状态。复用已有 reconciliation 原则，不新建第二个对象真值，也不简单给整条链加 MainActor。

**验证：**可控 continuation 挂起保存 A；期间提交 B、删除锚点、切换对象；释放 A 后核对当前 session、
磁盘读回、重启恢复和状态提示。另测失败、重试和 compatibility projection warning。

### 2. P1：相册加载等待期间，用户修改可能不被标记为未保存

**证据：源码与提取的状态判断探针；未执行 SwiftUI 真机时序复现。**

- `MemoMarkiOSV1View.swift:2483–2530` 在等待相册加载前把
  `isApplyingSavedOutputConfiguration` 置为 true，只在请求结束时复位。
- `V1RootChangeObservationModifier.swift:130–161` 在该标志为 true 时忽略输出格式、照片说明、
  相册选择和新相册名称的 dirty 标记。
- `V1OutputPageSurface.swift:313–326,461–478,529–567` 的相关输入仍可编辑。
- `V1ConfigurationOptionList.swift:1265–1273` 在状态仍为 `.saved` 时禁用保存按钮。

例如：配置已保存 → 刷新相册或 App 回到前台触发加载 → 等待期间修改保存位置/说明 → 值变了，
状态可能仍是已保存。请求身份校验能拒绝旧相册结果，但不能补回已经跳过的 dirty 标记。

**方向：**把“加载中”与“正在应用已保存投影”分开；仅抑制对应系统投影的变化，不能覆盖整个 await
窗口。需要显式区分用户编辑与系统投影来源，验证 SwiftUI onChange 的实际交付时机。

**验证：**延迟相册返回，在每个可编辑字段操作；断言 dirty、保存按钮、切换配置提示和最终持久化。
保留已有 generation/subject/configuration/output selection 身份校验。

### 3. P1：TextKit 命令回调存在实际强引用环

**证据：源码 + 从生产文件提取的命令总线类和回调构造的独立 Swift 引用生命周期探针。**

- `V1TextKitEditorSession.swift:7–9`：command bus 强持有 insert handler。
- `:938–945` 与 `:958–965`：handler 虽然弱捕获 session/view，但仍访问 `commandBus` 属性，
  隐式保留绑定上下文；该上下文又持有 command bus 和 session。
- representable 没有对应拆卸清理；`V1EditorInteractionState.swift:17–31` 保有四个区域的总线。

探针结果：外部 owner 作用域结束后，bus 和 session 仍被持有，view 已释放；清除 handler 后，
bus 和 session 均释放。探针使用了 UIKit/session stub，因此证明的是被提取代码的引用关系，
不等于完整 iPhone 编辑器的 Memory Graph 或泄漏体积测量。

**方向：**显式弱捕获总线，避免闭包隐式持有整个 representable；为注册/拆卸建立所属关系。
拆卸时不能清掉新 view 已经接管的回调。继续保留 UIKit caret、selection、IME 和原子模块编辑。

**验证：**关闭/重建编辑器后的弱引用释放；重新挂接后插入只交付一次；旧 view 拆卸不清掉新注册；
再执行输入、撤销、复制粘贴和模块路由真机回归。不能据此声称关闭一次面板就必然增加一个泄漏实例。

### 4. P1：自定义卡片编辑浮层缺少完整的无障碍模态与焦点契约

**证据：模态语义缺口为源码事实；VoiceOver 实际遍历结果 NOT VERIFIED。**

`V1EditorPresentationModifier.swift:17–36` 使用 `.overlay` 呈现，底层 content 没有随之隐藏于
无障碍树；`:222–229` 仅使用 `.accessibilityElement(children: .contain)` 与 label。
该路径未发现 `.isModal`、等价 UIKit 模态设置、初始/恢复焦点或 accessibility escape 处理。

风险：视觉上用户已经进入编辑器，但辅助功能焦点可能仍进入底层配置控件；关闭后的焦点目的地
也没有定义。不能把 children containment 当作 sibling exclusion。

**方向：**先补齐现有浮层的模态、焦点进入/恢复、退出动作和底层不可交互语义；若评估原生 sheet，
须先证明不会破坏已接受的键盘、模块面板与 canonical line box 行为，不在本轮替换。

**验证：**真机 VoiceOver 前后遍历、两指退出、关闭后返回触发按钮、Voice Control、外接键盘和输入法。
参考：[Apple 自定义模态无障碍说明](https://developer.apple.com/documentation/accessibility/delivering_an_exceptional_accessibility_experience)、
[SwiftUI isModal](https://developer.apple.com/documentation/swiftui/accessibilitytraits/ismodal)。

### 5. P1：UIKit 编辑字段的辅助功能文字绕过本地化路径

**证据：直接赋值为源码事实；未录制四语言 VoiceOver。**

`V1TextKitEditorSession.swift:184–185` 直接把 `"\(region.displayTitle)内容"` 和
`region.editorSubtitle` 赋给 UIKit accessibility label/hint。
`ConfigurationCenter/Models/CardRegion.swift:65–97` 返回中文 String；该赋值路径没有调用项目本地化器。

四份 Localizable.strings 各 1,437 个 key、集合相同，并不证明这些 UIKit 字符串经过了查询。
这是实际调用路径缺口，不是把合法的中文 SwiftUI localization key 一概视为错误。

**方向：**以格式化 key 和适当语义生成 label/hint，使用界面语言；保留可访问的真实输入值和模块语义。
在语言改变或 representable 更新时同步，不能只在 attach 时设置。

**验证：**四语言直接字符串断言 + UIKit 字段属性检查 + 真机 VoiceOver。同步补齐既有系统相册权限
说明的 InfoPlist 本地化；系统权限对话框语言与应用内部语言偏好分开验证。

### 6. P2：编辑浮层动画与项目已有 Reduce Motion 处理不一致

**证据：源码已确认；体感和系统实际降级结果 NOT VERIFIED。**

`V1EditorPresentationModifier.swift:33–36` 固定底部移动转场，`:261` 固定 spring 回弹，
没有读取 Reduce Motion。其他入口，如 `InteractiveMemoryCard.swift`、
`V1SettingsPageSurface.swift` 和 `V1OutputPageSurface.swift` 已有对应处理。

**方向：**复用既有 motion policy，减少位移/弹簧，保留有意义的状态反馈；不必去掉所有动画。
参考：[Apple Reduce Motion 环境值](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)。

同一 bounded UI pass 应检查：拖拽手势目前附着在整个浮层且使用 simultaneousGesture，
只按方向、阈值与键盘状态判断退出，没有滚动位置/起始区域仲裁。滚动模块列表是否误关闭必须
真机复现后再决定改法，不能仅凭源码确认冲突。

### 7. P1 验收缺口：Card Content Editor 的大字号和动态变化尚未闭环

`V1TextKitEditorSession.swift:166–179,855–879` 同时包含 preferred font、字号自动调整、
单行 clipping 与固定 40pt 控件；这不自动形成大字号可用性保证。

这已是 8 月 27 日输入规范明确列出的待扩展边界，不是本轮新发现的默认字号 baseline 缺陷。
首页、设置和对象资料的若干入口已有 ViewThatFits/动态字号垂直布局，不能称整个 App 没有适配。

**方向：**先定义大字号的输入高度、标题排列、附件 canvas 和换行策略，再实现；默认字号继续保留
已接受的 half-leading、独立 attachment attributes 与单一 UIKit caret。不要以缩小字号或 +1/-1pt
补偿解决可访问性。参考：[Apple Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)。

## 既有工程问题：本轮保留，避免重复包装成新发现

| 优先级 | 问题与依据 | 后续边界 |
| --- | --- | --- |
| P0 carryover | TX-001 导出事务/恢复与 BP-001 单任务内存约束尚未取得 superseding certification | 继续保留；本轮未关闭，也未重启已停止采样 |
| P1 | `Services/RecordCardExportPipeline.swift:6,40–59,111–130` 在 MainActor 上同步处理原图级解码、合成、编码 | 把纯重工作移到明确执行边界；UI 必需部分保留正确 actor；输出不变需 read-back。尚无本轮卡顿/耗时测量 |
| P1 | Swift 6 模式目前不能编译；同一源码之前的 complete checking 得到 33 条去重警告/10 文件 | 沿用当天独立评估的构建证据，本轮不重复迁移，也不把警告数说成缺陷数 |
| P1 媒体风险 | `LivePhotoAssetLoading.swift:355–359,439–461` 重取资源数组后仍依旧 index 取资源 | 复核资源身份、版本和 still/motion 配对；未复现错误配对，不新增虚构身份字段 |
| P1 | 两个 App Info.plist 的 Photos 权限说明为中文；本轮扫描没有 InfoPlist.strings/xcstrings | 四语言 bundle 资源与首次授权真机验证；无需扩大权限 |
| P1/P2 条件风险 | 静态和 Live Photo 在显式相册 ID 失效后的行为不同 | 先统一删除/重命名/权限丢失/同名相册的产品契约，再修改适配器 |
| P2 | root 3,329 行，TextKit 1,128 行，Settings 1,812 行，Device QA harness 2,177 行 | 以独立职责和生命周期为切口，优先保存调度、媒体选择、编辑器绑定；不为满足行数阈值而拆碎 |
| P2 | UI/source contracts 与本地化 allowlist 无法覆盖全部运行时行为 | 保留架构契约，补真实行为测试和实体设备矩阵；不以换测试框架代替补场景 |

前一份评估还记录了队列旧快照恢复、未接生产的 metadata scaffold、Xcode Cloud 门禁等问题。
参见 [工程优化与 Swift 6 评估](2026-08-28-engineering-optimization-and-swift6-assessment.md)。
本轮没有再次查询远端门禁，不把先前结果当作新的远端复核。

## 已有设计中应保留的部分

- 相册请求已有 generation、对象、配置和选择值匹配；问题 2 不能通过删掉这些校验解决。
- Logo 和头像处理已有请求/对象上下文与旧结果拒绝；不是“所有异步回调都缺保护”。
- 一般配置保存已有 candidate/reconciliation 抽象；对象锚点路径应补齐相同不变量，而非重写配置库。
- 文本/attachment 属性分离、IME marked-text 保护、原生 caret 和 undo 方向正确。
- 设置/对象/首页的部分入口已有大字号、Reduce Motion 与语义化按钮支持。
- Memory/Layout/Renderer 边界、生成新输出而不改原图的产品契约不因本次审查改变。
- 四语言 key parity 通过；先前报告声称缺失的三条首页翻译并未缺失。

## 本轮验证

临时证据目录：
`/var/folders/4t/983xkfjx51q_pv8sqp3tymkw0000gn/T/MemoMarkSkillsAudit-20260828-ljyjuiw8`。
它不是仓库依赖或可移交的永久 CI 路径。

执行命令已保存为该目录的 `test-command.json`，核心为：

```bash
xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkTests -configuration Debug \
  -derivedDataPath /tmp/MemoMarkFullTests95.l4mQVZ \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:MemoMarkTests/IPhoneResponsiveLayoutContractTests \
  -only-testing:MemoMarkTests/V1OutputAlbumLoadIdentityTests \
  -only-testing:MemoMarkTests/V1EditorLineBoxGeometryTests \
  -only-testing:MemoMarkTests/ActiveLocalizationUsageAuditTests \
  -only-testing:MemoMarkTests/V1SubjectLibrarySupportTests \
  -quiet test
```

| 检查 | 结果 | 能证明什么 / 不能证明什么 |
| --- | --- | --- |
| 五组 macOS 宿主测试及其构建 | PASS | xcresult：66 个测试用例，含参数化共 73 次执行；0 failed、0 skipped。不是完整 1,600+ 测试重跑或 iPhone UI 验收 |
| 仓库治理与脚本测试 | PASS | governance checker、119 个 scripts/tests 测试及 diff whitespace 检查通过；不是产品运行时验收 |
| 提取的 TextKit ARC 探针 | PASS（成功复现引用环） | bus/session 在 owner 结束后仍存活，清除 handler 后释放；不是 App 内存峰值测量 |
| 提取的 dirty 判断探针 | PASS（确认屏蔽行为） | load 标志期间编辑不置 dirty，复位本身不补发；不是 SwiftUI 时序真机复现 |
| 四语言资源解析/集合比较 | PASS | 每种语言 1,437 keys 且集合相同；不证明每个 UIKit/系统提示查了正确资源 |
| 系统权限多语言资源 | FAIL | 没有发现 InfoPlist.strings/xcstrings，本地 plist 仍是中文 |
| VoiceOver、焦点、Reduce Motion、对比度 | NOT VERIFIED | 发现代码缺口，但未获取当前真机无障碍树或人工验收 |
| 大字号、实时字号切换、长译文 | NOT VERIFIED | 默认字号几何契约/宿主测试不能关闭这个 gate |
| 响应性、峰值内存、预览重算次数 | NOT VERIFIED | 没有 Instruments/Release 真机前后测量，不报告性能改善 |
| 实体 iPhone 17 Pro Max | BLOCKED | 配对存在且开发者模式 enabled，连接 unavailable；未安装/启动新包 |
| Photos/Live Photo/输出 read-back | NOT VERIFIED | 本轮只沿源码核对，未处理媒体 |

现有 IPhoneResponsiveLayoutContractTests 大量检查 source.contains；本地化 audit 只扫描维护的
文件 allowlist 和特定命名空间。它们通过不能否定上面发现的引用环、await 窗口和 UIKit 语义缺口。

## 建议实施顺序（需另行确定切片）

1. **配置可靠性切片：**对象/锚点保存的在途修改与回执 reconciliation；相册加载和 dirty 标记分离。
   先加可控延迟、失败、切换和重启读回测试，再实现。该切片不接触媒体输出。
2. **编辑器生命周期切片：**TextKit 回调注册与释放；复测模块、选区、IME、撤销和复制粘贴。
   不改输入几何或 Renderer。
3. **一次完整的 UI 无障碍 pass：**现有浮层的模态/焦点、退出动作、Reduce Motion、四语言 label/hint；
   先明确手势与大字号验收矩阵，避免连续局部 spacing 试错。大字号扩展须有新规范。
4. **Swift/媒体工程切片：**按当天独立评估分阶段处理并发边界、Swift 6 编译与 Live Photo 资源身份。
   UI 重构、Xcode 升级与语言模式切换不要混在一起提交。
5. **维护性整理：**在行为测试保护下提取 root/编辑器独立职责，补 CI 与真机证据；不增加第二套架构。

每个切片都有独立 owner、规格、失败场景和验收；本记录本身不批准实现、提交或发布。

## 后续实现记录（2026-08-28）

本审查先于实现切片完成；以下结果是对上面建议的增量闭环，不改写前面的审查快照：

- 配置可靠性：新增 `ConfigurationCenter/V1SubjectPersistenceRequestGate.swift` 及 3 个 Swift
  Testing 用例。对象保存现在保留在途期间的最新请求，旧回执不会覆盖新编辑；相册选项加载不再
  以异步标志屏蔽用户对输出配置的 dirty 状态。
- 编辑器生命周期与无障碍：TextKit 插入处理器改为对 command bus 弱捕获；浮层增加 `.isModal`，
  转场和下拉回弹遵守 Reduce Motion；编辑器 label/hint 改从 `CardRegion` 的四语言资源读取。
- 系统权限资源：已加入四套 `InfoPlist.strings`，并在 iOS 与 macOS 构建产物中确认存在；首次授权、
  VoiceOver、动态字体和视觉层级仍必须由规定的 iPhone 17 Pro Max 真机验收。
- Swift 6：`PhotoProcessingInputPolicy` initializer 已安全标为 `nonisolated`，
  `MemorySubjectEditorView` 明确为 `@MainActor`。Swift 6 探测继续停在 `PhotoKitLivePhotoAssetWriter`
  将主线程闭包送入 `PhotoLibrarySaveGate` 的 Sendable 边界，未用不安全标注绕过；工程仍保持 Swift 5
  语言模式。详细迁移状态见[工程优化与 Swift 6 评估](2026-08-28-engineering-optimization-and-swift6-assessment.md)。
- 验证：完整 `MemoMarkTests` 为 1,607 通过、1 个既有跳过项；切片相关测试为 69 用例/76 次执行，
  全部通过；macOS Debug 与 generic iOS Debug unsigned 构建、119 个脚本测试和 governance checker
  通过。后续设备恢复连接后，已对规定的 iPhone 17 Pro Max 完成旧包卸载、新签名包安装和启动；仍未
  代替用户操作照片或授权流程，人工验收结果应另行记录。
