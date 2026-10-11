# 发布前审查逐项修复

2026-10-11。所有者授权逐项定位和修复。Primary loop：Engineering Loop。

## 实施前决定

- 依据：`2026-10-11-pre-release-audit.md` 的源码路径与三组失败复现，不按历史测试推断当前生产可用。
- 所有权：ConfigurationProjection/production snapshot、CommercePersistence/accounting、request/session notification、durable continuation、SwiftUI/TextKit 编辑生命周期及既有媒体执行 owner。
- 风险：持久配置/记账/跨进程恢复按 P0 保护；后台可靠性与编辑连续性 P1；成功静音策略 P2。维持配置 aggregate、不可变任务快照、保存 receipts、原片保护和 Layout/Renderer 契约。
- Apple 能力：复用 BackgroundTasks registration/queue/expiration、UserNotifications、UIKit/TextKit/undo；不把系统调度时间视为固定 SLA，不在后台请求 Photos 权限。
- 依赖方向：先修 canonical snapshot 和记账身份，再修 notification barrier/失败投递，随后处理 continuation 排队状态与 UI 身份。媒体 experiment 不直接提升为 Release。
- 范围：每项先失败测试，再最小实现及相关回归。UI 调整须保持上一轮接受的横屏保留预览行为和输入几何。Release 媒体风险须用真实候选证据诊断，不能凭猜测宣称内存故障或任意降低输出保真度。
- 保护：起始 Source/Tests 979 文件与 dirty status 保存至 `/tmp/MemoMarkRepairBaseline20261011`；不用 broad staging/reset/clean。

## 验证与交付

1. 将审查复现正式加入现有测试文件，补四样式/损坏快照、旧 task 与 identity、同/不同 session 等边界。
2. 在临时镜像运行 focused tests；每片通过才继续。最后完整 macOS suite、正式工具链 iOS Release build、治理和 diff review。
3. UI/Photos/后台需要签名配对 iPhone 17 Pro Max 安装、启动和受控真机路径；构建、安装、人工验收和生产认证分开。
4. 保留逐项状态与未完成证据；不提交/推送/上传/商店发布。

## 进展

开始于既有审查工作树。具体结果在每片验证后追加。

### 编辑器生命周期修复范围

观察：verticalSizeClass 条件将整个 ScrollView/编辑器在两棵结构间替换，TextKit 会话和 UIView 撤销栈不能保持。目标：使用始终存在的 GeometryReader / ScrollView / AnyLayout 容器，compact 维持完整预览与有限编辑区域、其他尺寸填满可用高度；不改变文本属性、模块、输入几何及配置 ownership。固定 divider 子节点也避免 split 改变兄弟节点身份。验证：iOS 签名构建、物理设备旋转/键盘/滚动/撤销连续性；自动化不能替代人工中文 IME 和视觉验收。

### 真机反例扩展根因

签名 Release 真机 `testCardEditorFocusSurvivesPhysicalRotation` 在横屏 first responder 断言失败。发现 EntryNavigationSurface 仍按 orientation 从 NavigationStack/TabView 切到 NavigationStack/sidebarDestination，跨越更上层 UIKit hosting identity。扩展范围仅导航容器：保留一个 NavigationStack 与 primary TabView，让 tabBar 显隐和 trailing safeAreaInset 调整导航外观；Settings/Output 的明确目的地切换与 sidebar capability 保留，未增加产品入口。随后复跑真机同一失败用例与 preview/accessory 既有用例。

### 失败状态完整性复核

待处理请求解码失败不能等价于空队列：适配器保留可读性事实，向通知投影传递 unknown pending count。终态失败 job 与 unreadable intake 同时出现时，仍不得确认最终通知；已有四语言 unknown 投影回归扩展此边界。平台适配器接线由 iOS Release 编译确认，macOS 投影测试不能证明真实文件损坏后的系统回调。

## 当前逐项状态

| 项目 | 根因与处理 | 证据边界 |
| --- | --- | --- |
| AUD-01 四样式分享 | canonical transport 过去仅为 FilmMark/GlassCard 发布；四样式统一投影，processing admission 仍严格校验。持久编辑允许尚未选 anchor，不能将 incomplete draft 当生产可用 | 四样式及 incomplete editing 回归通过；Classic/Minimal 真机分享未完成 |
| AUD-02 恢复重复计数 | immediate accounting 使用保存身份，reconcile 曾使用 task UUID；统一 successfulSaveAccountingID，仅依据 durable completed receipts 归并已证明旧别名，保留无证据历史额度 | 首次记账/恢复/重复恢复/旧别名与历史计数回归通过；不重置设备额度 |
| AUD-03 完成通知阻塞 | 全局 pending intake 阻塞无关会话；barrier 缩至本会话成员，legacy unassigned live intake 仍保守等待 | 同会话阻塞、无关 held 会话隔离回归通过 |
| AUD-04 失败通知缺失 | 入队前失败或全终态失败没有 suspended job，原投影不产生通知；新增事实计数/未知状态路径，只有确知无 pending 的终态才允许投递后确认 | 四语言回归通过；真实故障注入与系统通知展示未完成 |
| AUD-05 成功声音 | 主 App 与 Extension 策略不一致；成功静音，需要处理的失败保持系统提醒 | 源码/构建复核；系统通知听觉验收未完成 |
| R-02 Debug/Release 差异 | Debug 默认启用 CPU experiment；改为明确 opt-in，普通 Debug 分享遵循现有 Release rendering path | opt-in 回归通过；不能据此认证 Release 媒体/资源压力 |
| R-03 OS 排队超时 | 本地 180 秒 reservation 被当作系统 queue 生命周期；查询已排队系统标识保留 owner，旧 callback 无续约权不得处理，heartbeat 失权取消 operation | 600 秒排队、已关闭 owner、drain/renew 回归通过；长等待真机系统回调未完成 |
| R-01 编辑器连续性 | 编辑器及导航上层条件容器都存在身份替换；稳定容器已实施，真机仍曾丢焦点，需取得新 harness 的 before/after 原生身份后继续诊断 | 暂不关闭。第三次诊断受折叠的布局分组阻挡，未到达旋转；harness 已补稳定进入，尚待运行 |

### 当前验证记录

- Full macOS：`/tmp/MemoMarkRepairNavigationFinalFull20261011.xcresult`，2,098 passed / 1 existing skipped / 0 failed。随后 unknown pending 本地化 focused：`/tmp/MemoMarkRepairAttentionFinal20261011.xcresult`，3 test definitions / 9 executions，0 failed。更晚的 unreadable-pending 边界另有 focused 与候选构建，不应与此完整 suite 混称。
- 正式 Xcode iOS signed Release 已构建并用于真机；版本仍 2.3.6 (124)。修改后的候选不是原商店 build 124 的二进制，未提交任何 release。
- 真机 Release 单张 JPEG Photos 路径尚未提交照片：分享界面显示免费成长记录已完成。所有者说明已有沙盒测试权益并自行准备；等待准备完成期间暂停手机自动化。没有额度重置、绕过 commerce 或真实购买。
- 修改相对保护基线为 28 个 Source/Tests 文件；其他起始 dirty 工作保留。四语言 strings lint、治理、diff whitespace 检查通过。
- 真机 IME/selection/undo、横屏焦点、四样式 Photos 保存读回、权限组合、OS 排队/过期/资源压力及 superseding production certification 继续开放。测试、签名构建与安装均不能替代这些验收。

- 最后 focused unreadable-pending 回归：`/tmp/MemoMarkRepairUnreadablePending20261011.xcresult`，3 definitions / 9 executions，0 failed。当前 28 个修改文件与 focused 镜像逐字节一致，候选哈希保存 `/tmp/MemoMarkRepairCandidateManifest20261011.json`；四语 1,896 keys parity 无重复。

- 最终当前源码 signed Release `MemoMarkDeviceQA build-for-testing` exit 0：`/tmp/MemoMarkRepairFinalCandidateBuild20261011.log`。仅构建，无安装/启动/Photos 操作；最新未知 pending 接线已进入编译候选。权益准备完成后再继续物理设备验收。

### Share 权益 blocker 的后续关闭

用户报告 host 已购买后，发现 extension 的 distribution 判定与 StoreKit 2 不一致。原 legacy receipt locator 修复不足，最终复用 verified AppTransaction 判断 confirmation/admission/worker 环境，严格缓存隔离保留。最新 signed Release 已覆盖安装，warm-background 单 JPEG 真机 Share/Photos readback 通过；不再将该样例记为免费额度阻挡。最终 full 2,100 passed / 1 skipped / 0 failed。其他样式/Live Photo/权限、UI continuity 和整体 production certification 仍开放。详见 2026-10-11-commerce-extension-environment-repair.md。

### 用户新增复现：Share 返回与自适应首页旋转

观察：用户在最新安装包中报告 Share 到 MemoMark 直接报错、切回主程序未见进度条；横屏展示时侧边操作已出现，但底部按钮再次出现；横屏转竖屏后首页放大且未恢复。目标：让同一导航根独占系统 TabView 可见性；确认 Home 使用的 viewport 在方向切换后回到竖屏 safe-area 与内容宽度；让已接受的后台请求在主程序可见进度。范围：`AdaptiveNavigationShell`、主页/活动状态投影和设备 QA harness，只有经证据指向时扩展。风险 P1（主工作流、生命周期、设备适配）。先建立所有权回归，再签名构建并在配对 iPhone 做连续横屏-竖屏检查和 Share->返回主程序活动状态检查；照片只用 QA 输入，保留原片。

### 自适应导航修复与真机证据边界

- 回归先失败：旧 `TabView` 在自身声明 orientation-dependent `.toolbar(for: .tabBar)`；唯一 Tab Bar owner 契约失败后，把同一可见性偏好移至稳定 `NavigationStack` 内容根，保留同一 `TabView` 与侧栏 safe-area 布局。
- 该契约复跑通过，`IPhoneResponsiveLayoutContractTests` focused suite 全部通过；`git diff --check` 与 governance 通过。签名 QA Release app 与 test runner 成功构建。
- 配对 iPhone 17 Pro Max 当前为 disconnected；当时唯一可连接的实体机是 iPhone 15 Pro。两种 build configuration 下的 XCUITest Runner 均在测试启动前以 exit code 74 退出、未建立 XCTest 连接；没有旋转断言实际执行。此次 physical gate 仍 NOT VERIFIED。
- 为故障分离而在 iPhone 15 Pro 安装并启动了 build 124 QA 候选；第一张截图在 Configuration 页面。随后 orientation 探针截图切到了其他前台 app，未构成 Home 页面或恢复布局证据。未访问/修改任何用户照片。
- QA harness 新增连续 Portrait -> Landscape -> Portrait 的 tab-bar/rail 与 viewport 尺寸恢复检查，并新增 Release Share 后重新激活主程序的 Home 活动卡检查。后者要求已准备的 QA Inputs 相册及沙盒资料，因本次 17 Pro Max 离线且 15 Pro 资料未确认，没有执行。
- 用户提供最新安装包截图后，Share 链路证据更新：扩展界面已到“已准备好 / 等待开始”，系统随后显示“时光记正在处理照片 / 任务失败”，再切回主程序首页；主界面当时没有活动卡。截图没有显示扩展内部的具体错误文字或 NSError。
- 源码确认 `ShareContinuedProcessingAdapter.handle` 的失败出口会将系统任务标为失败；它先把 continuation 接受的请求写为 suspended，再尝试用已入队 job 创建暂停通知。`ShareContinuedProductionWorker` 在 ledger bootstrap、intake 读取、payload admission、commerce capacity、持久化或执行未完成等边界均可在入队前抛错。此时没有 `BatchJob`，而 Home 活动卡只由 `MemoMarkBackgroundStatusService` 的外部 jobs 投影；因此“系统任务失败 + 首页没有进度卡”存在确定的状态投影缺口，挂起 intake 本身并没有 Home 可见的活动记录。
- 主程序激活路径会调用 `refreshExternalIntakeState()` 并 drain 持久 intake（包括 suspended 请求），但源码无法证明本次设备上 App Group 读回、drain/admission、系统回调与首页重绘的实际先后。不能仅凭截图认定具体是哪一个 worker error，也不能将可能的激活竞态说成已修复。
- 目前 Release adapter 的详细 continued-processing diagnostics 仅在 `DEBUG` 构建写入 probe；生产失败只调用 `setTaskCompleted(false)`，截图里的系统通用“任务失败”不足以区分具体失败边界。后续真机复现需在 iPhone 17 Pro Max 上读取 Share diagnostics / OSLog、验证请求是否仍在 App Group、是否形成 suspended job，并同时检查 Home snapshot。
- 继续遵从用户最新设备要求：后续只将签名构建推送到 iPhone 17 Pro Max。该机当前未连接；不再使用 iPhone 15 Pro 进行安装或验收。轮转恢复与真实 Share/Home 状态仍为 NOT VERIFIED。
- Release generic iOS build 以 Xcode 27.0 完成，`BUILD SUCCEEDED`；`git diff --check` 与 governance 通过。尝试在 macOS 跑 `IPhoneResponsiveLayoutContractTests` 时选错了 `MemoMark` scheme（该 scheme 无 Test action）；改用 `MemoMarkTests` 后测试已启动，但 Xcode 在保存测试记录阶段长时间阻塞，人工中断，不能记为 PASS。此前已有的 focused suite 记录仍按原边界保留。

### 2026-10-11：17 Pro Max 方向恢复验收与 Release Share 诊断补强

- 后续真机目标固定为配对 iPhone 17 Pro Max，UDID `00008150-000A043136A1401C`；本轮没有再向 iPhone 15 Pro 安装。
- 方向切换复核：Landscape 中右侧导航轨存在、系统底部 Tab Bar 消失；回到 Portrait 后首页恢复完整内容宽度与唯一底部导航。最新候选主程序在 17 Pro Max 前台截图也显示正常 Portrait 首页。截图是人工真机证据，不代表 XCUITest 已执行。
- 首页当前任务截图显示 `1 / 1 张 · 后续 1 个` 且状态为失败；这是现存失败记录的首页投影，不能与用户 09:48 的 Live Activity 截图证明为同一个 Share 请求。该截图证明当前候选首页能显示失败记录，但不证明失败任务已恢复，也不证明最初系统失败已定位。
- Release Share 的具体错误此前确实无法从设备证据还原。根因之一已由代码确认：Continued Processing 适配器的详细事件全部委托给 `MemoMarkBackgroundProbe`，而该 probe 被 `#if DEBUG` 包住；Release catch 最终只向系统报 `setTaskCompleted(false)`。因此 Release 用户只看到系统通用“任务失败”，没有可供主程序诊断导出的错误阶段。
- 增补边界：在共享 Share diagnostics 中记录 Release 失败事件，仅保存请求 UUID、NSError domain/code；不保存 localized description、照片路径、文件名或照片内容。unexpected task 类型、continuation owner 丢失、无请求可处理也以固定原因记录。此修复提升下一次真实 Release 复现的可诊断性，不等于修复了尚未查明的具体执行失败。
- 验证边界：`MemoMarkTests` 在本机 Xcode 27.2 macOS 执行时，多次出现 Xcode 报“exit code 0 but produced no further output”，并生成缺少 `Info.plist` 的损坏 `.xcresult`；focused test target 未产出 `.xctest`，相关测试结果为 NOT VERIFIED，不能报通过。新签名 Release `MemoMarkDeviceQA build-for-testing` 使用 Xcode 27.0 完成（`** TEST BUILD SUCCEEDED **`），`codesign --verify --deep --strict`、覆盖安装、启动均成功，版本仍为 2.3.6 (124)，属于本地 QA 候选，不是商店包。
- 更新后手动方向矩阵：在该安装版本上执行 Landscape -> Portrait；Landscape 截图 `/tmp/MemoMark17ProMaxInstalledLandscape20261011.png` 显示右侧侧栏、无底部系统 Tab Bar；Portrait 截图 `/tmp/MemoMark17ProMaxInstalledPortraitRestored20261011.png` 显示首页内容宽度和唯一底部 Tab Bar 恢复。主程序最新截图 `/tmp/MemoMark17ProMaxInstalledFinal20261011.png` 显示 MemoMark+ 权益标识与现存 1/1 失败记录。未进入 Share 扩展，未操作照片。
- Share 故障原因为 NOT VERIFIED：设备诊断时间线与 09:48 截图未关联到同一请求；不能仅凭 `任务失败` 推断为队列、权限、照片读取或商业权益故障。没有触发新的照片 Share、额度清理、真实购买或 Photos 写入。

### 用户新增复现：Share 失败后的提醒与主程序进度缺失

观察：最新截图显示系统 Continued Processing 最终为任务失败，随后用户回到主程序首页；无明确完成/失败提醒，首页没有该分享的处理卡。源码已证实两项相关事实：失败请求会被标记 `executionSuspendedAt` 并保留在 App Group；若尚未入队形成 `BatchJob`，首页现有 `HomeActivityPresenter` 仅接受 `MemoMarkBackgroundJobSnapshot`，没有可呈现的任务，因此会留空。提醒另受系统通知授权影响，当前没有本次设备的授权状态及 Release 事件时间线，不能据此认定唯一底层 worker 错误。

目标：持久暂停的外部分享请求必须在主程序首页有清晰状态和可执行的“继续处理”入口；点击入口应先重试现有 intake drain，再打开进展页。通知获准时继续使用系统通知；通知未授权时也保留应用内恢复路径，不宣称一定能打断用户。保留原请求、商业 admission 与媒体处理 owner，不合成 BatchJob、不重置额度、不改写照片。

主 loop：Engineering Loop。所有者：ExternalPhotoIntakeCenter/ExternalIntakeDrainCoordinator 持有请求事实；HomePageSurface 只渲染不可变 pending-share projection；既有 retry/admission 仍由 ShareCoordinator/BatchQueueStore 执行。风险 P1（Share 主流程与跨进程恢复）。Apple 能力：BGContinuedProcessingTask 负责系统续处理，UserNotifications 负责获准后的提示，App Group 持久请求负责恢复事实。范围限于暂停请求的状态投影、首页恢复动作、共享 scroll viewport 对方向变更重获实时宽度；不扩展媒体能力。

验证：先添加 presenter/scroll contract 回归，再最小实现；focused tests 与 iOS Release build；签名安装只推送到 iPhone 17 Pro Max。手动 Share/通知验收使用用户准备的沙盒权限与测试照片，未准备前不提交照片、不操作额度。当前真机 17 Pro Max 连接状态需实时确认。

### Share 恢复投影与 10 月 7 日自适应布局复核

Share 失败截图显示系统任务结束为失败，而主程序此前只从 BatchJob 读取活动状态；请求已持久化但未 admission 成 job 时，首页就没有可操作恢复入口。现将已暂停的 Share intake 数量与对应 session id 投影到首页恢复卡；点击后按原 session drain intake 并进入进展页，不伪造 progress/job。只处理 exact suspended session。通知授权或系统投递失败时，首页仍提供进展入口。没有通过新照片触发该路径，系统通知展示仍待受控验收。

横屏根因按 10 月 7 日 handoff 重新核对：SwiftUI `containerRelativeFrame` 在方向切换/容器层级下仍得到旧窄宽度；直接用页面 GeometryReader 修复后，17 Pro Max 截图证明其变为 720pt，但 `TabView` 内 GeometryReader 接收整块宽度，内容右边缘再次进入侧栏。最终将悬浮栏宽、外边距与内容间距集中为 `AdaptiveFloatingRailMetrics`，由主页面以实时 GeometryReader 宽度减去该预留后计算可读列，再将滚动容器保持为原完整视口。内容列仍受 720pt 上限与双侧语义留白约束。纵向仍使用底部 TabView，没有第二套底部栏。

验证：iOS Release generic build exit 0；Share Extension Release generic build exit 0；`MemoMarkDeviceQA` Release build-for-testing exit 0，签名 strict verification 通过并覆盖安装到配对 iPhone 17 Pro Max（2.3.6/124 本地候选）。纯宽度策略 probe（实际编译 `AdaptivePageLayout.swift` 并断言 402pt 竖屏、956pt 横屏及 78pt rail reservation）通过。连续设备截图 `/tmp/MemoMark17ProMaxHomePortraitViewportFix20261011.png`、`/tmp/MemoMark17ProMaxHomeLandscapeRailInset20261011.png`、`/tmp/MemoMark17ProMaxHomePortraitRestoredRailInset20261011.png` 显示横屏内容展开且避开右栏，回竖屏恢复完整首页与底部栏。设备 UI test runner 再次于 XCTest bootstrap 前以 code 74 退出，首页/配置/进展自动交互用例未执行；host focused XCTest 编译完成并启动，但 Xcode 卡在 test record 保存阶段且 `.xcresult` 缺 `Info.plist`，已终止，不计为通过。目前视觉人工设备证据仅覆盖首页旋转。先前 viewport-only 截图 `/tmp/MemoMark17ProMaxHomeLandscapeViewportFix20261011.png` 作为失败中间版本保留，不宣称通过。四语言照片分享验收、进展页/配置页人工旋转、真 Share/通知恢复、IME 和 Dynamic Type 仍开放。
