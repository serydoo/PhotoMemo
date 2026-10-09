# 2026-10-08 清洁安装后台验证

## 基线重建

此前测试混入历史未完成任务和两个七图 QA 分享批次，无法归因。停止追加提交；备份 Documents、主 App Library、共享 Preferences 到 `/tmp/MemoMarkFreshBaseline-20261008`。2026-10-08 完整卸载 `com.serydoo.PhotoMemo.iOS`，安装当前签名 Debug 构建。卸载后共享容器仅含空 Library/Caches/Preferences，未恢复旧队列、intake、receipt、暂停标志或探针。

仅恢复六个配置键：模板、目标相册、照片说明开关、时间显示、位置显示、共享配置迁移标志。原配置与研究材料保留在备份中。此基线用于测试，不是用户完整数据迁移。

## 每轮规则

1. 输入仅使用 MemoMark QA Inputs；记录 localIdentifier、creationDate、媒体类型。输出仅使用 MemoMark QA Outputs；开轮必须为零。
2. 一轮只发一个批次，先选三张不同素材。Photos 分享确认后保持 Photos 前台；不激活主 App。记录分享关闭时间、通知、系统活动与实际输出。
3. 30 秒间隔检查输出，最多 4 分钟。超过上限即失败取证，禁止继续提交；保留请求与任务诊断。探针完成与真实渲染保存分别验收。
4. 成功需要每个输入对应一个可读取输出；验证相册归属、时间/资源、Live Photo 配对与原件不变。百分比或成功通知不作为保存证明。
5. 同配置重复分享必须无新增输出；该验证在清理输出前进行，避免删除已保存证据影响幂等判断。不同配置另轮允许输出。
6. 暂停/恢复/取消单独开轮，验证持久化与当前会话全部批次，而不是按钮点击成功。取消保护 PhotoKit 已提交边界。
7. 清理只删除本轮新增输出标识；读回确认零。终止/锁屏/恢复测试另轮进行。

## 证据门槛

记录自动测试、构建签名、物理设备执行、后台无 host 激活、实际 PhotoKit 读回各自结果。任何一项未证明都保留未通过状态。iOS 18–25 的 BGProcessing 不承诺即时后台完成；当前 Beta 的证据不代替稳定版矩阵。

## 当前结果

- 会话取消策略与 durable ledger 定向测试通过；iOS App/Share/Widget 签名构建通过。
- 完整卸载和新安装成功；空共享容器已检查。
- 清洁安装首页与输出相册基线真机测试通过（1/1）。
- 16:21 分享三个不同素材，单一请求 `48F8CBB8-AEF5-46E4-B4BB-7EBFA8A6E9D9`；请求持久化、BGProcessing 提交、分享关闭都有日志。
- 分享后主 App 未激活，八次 30 秒读回均为零；四分钟后台验收失败。没有 worker 接管日志。正式路径仍为 BGProcessing，Continued Processing 只处理 opt-in 探针，不能用探针证明生产后台完成。
- 16:26 单独激活主 App 恢复同一请求，PhotoKit 读回 3 个输出：1 Live Photo、2 JPEG。单张静态处理日志约 1.237 秒。Live Photo 接收静态回退日志不是最终输出分类；恢复匹配后生成了配对资源。
- 首次收尾删除等待 60 秒超时（恢复测试整体未通过，不能把生成成功与测试全绿混淆）。后续明确限定这三个输出标识、处理系统删除确认后，cleanup 测试通过（1/1），相册读回零。
- 两次早期启动断言失败发生于提交前，没有增加任务；真正分享只发生一次。
- 完整证据与卸载前备份已复制到 `/Users/rui/Documents/Codex/2026-10-07/referenced-chatgpt-conversation-this-is-an/artifacts/MemoMarkFreshBaseline-20261008`。

## 后台生产执行接入的第一步

既有账本、持久化、任务事件、状态策略、恢复检查与 retention 组件原先被 `MEMOMARK_SHARE_EXTENSION` 条件排除。已移除这些纯基础组件的排除条件，使扩展复用同一事务锁、schema、状态机；最初的绿色构建未包含这些源文件，不能证明扩展复用成立。17:19 已补充真实 target membership，并重新成功构建共享核心。执行 owner/lease arbiter、执行协议和不可变上下文也已纳入扩展；仅主 App 的 Store 适配保留条件编译。账本/状态策略回归以及任务事件/转换策略回归均通过，`git diff --check` 通过。尚未接 Renderer 或部署新扩展执行代码，此改动不构成正式后台能力验收。

新增 P0：`RecordCardBuildService` 的 extension 编译分支跳过 canonical memory payload 与完整表达上下文；`BatchConfigurationSnapshot` 的 canonical snapshot 解码也被 extension 条件排除。正式媒体执行接入前必须统一这两个边界，不能沿用简化分支生成生产输出。既有时间锚点与对象语义必须以同一冻结配置解释。

下一步依次拆出无 App UI 依赖的处理依赖工厂、串行媒体执行/保存/回执服务，使用同一 ledger 与 execution lock，再接系统任务进度、过期与取消；严禁复制一套简化渲染或保存链。生产接入前不再重复追加照片测试。

## 17:25 冻结语义回归

修正扩展的简化 RecordCard 分支，复用 ProductionMemoryResolver、MemoryPayload 和 ExpressionContext。BatchConfigurationSnapshot 能解码旧扩展传输的 frozenCanonicalSnapshotData 并恢复完整 canonical 配置，保留主 App schema。新增四种样式的 opaque Share 传输测试，按对象、锚点、日期、表达与 token 比较语义（计算结果的随机 UUID 不作为语义身份）。冻结语义/RecordCard/快照/账本/租约定向测试通过。

正在将原有正式 Renderer、EXIF 写入与 PhotoKit receipt 组件纳入扩展；当前尚未部署、尚未再次提交照片、尚未通过正式后台写入验收。扩展的权限检查仅使用已有授权，不调用 UIApplication.shared 或从后台触发授权弹窗。

## 19:05 受控生产路径与验收阻塞

- Share Extension 实际编译清单已包含 BatchQueueExecution、BatchTaskProcessor、LivePhotoBatchTaskProcessor、Renderer、PhotoKit writer、receipt ledger。完整 iOS Debug 签名构建成功；不是仅编译空条件分支。
- 新增 DEBUG-only ShareContinuedProductionWorker，通过 `-continuedProductionPipelineProbe` 临时开启十分钟。它使用相同冻结配置、Live Photo 接收恢复、ProcessingIdentity compiler、账本、执行文件锁、串行处理与保存回执。Release Share 调度策略未切换。
- 扩展受控执行先入账，再 acknowledge intake。先占用执行权的另一个 owner 会被等待；已消费请求可以从原 intakeRequestID 的账本任务恢复，不能因 request 已删除就误报失败。
- 账本 admission 在跨进程事务中核对 reservation；主 App 也采用该入口。新增并发容量测试证明两个独立实例不会同时用掉最后一个位置。
- DurableBatchTaskExecutionRuntime 每次读取状态都刷新文件事务，限定本次 job scope；取消后的推进被拒绝，别的 Share job 不能被本执行器修改。
- 进度 presentation heartbeat 与 execution lease 分离，带 generation/expiry；系统 Continued owner 执行时结束旧 MemoMark Activity，并抑制 host 新建 fallback。该展示交接尚待真机验收。
- 54 项冻结语义/快照/RecordCard/账本/租约定向测试通过；随后 23 项 runtime/账本/执行权/额度/presentation 定向测试通过，两组有交叉，不能相加作为全量测试数量。
- ShareDrainMigrationRegressionTests 回归遇到宿主对 Desktop fixture 的 getxattr/Open 阻塞，采样保存。系统界面工具明确返回 Mac 已锁屏，无法检查权限窗口。已停止无进展测试。暂时的 stat 优化已撤回，不能把它当作根因修复。
- 新增真机测试入口 `testContinuedProductionThreePhotosWithoutHostActivation`，使用 QA Inputs 索引 [1,3,5]，与上一轮 [0,2,4] 区分。尚未执行；没有追加输入、安装新构建、修改用户配置或清理其他数据。
- 下一门槛：解锁 Mac，完成 Share 接收回归与最新构建检查，再安装和执行受控三张正式输出测试，继续独立读回/Live Photo/幂等/暂停取消/恢复矩阵。生产验收仍未通过。

补充构建门槛：Share Extension Release 签名构建成功，DEBUG-only 生产探针不进入 Release；完整 iOS Debug 构建成功。真机生产照片输出与最新 Share 迁移回归仍未验收。

## 20:10 解锁后全量回归与正式三张后台验收

- 解锁后 ShareDrainMigrationRegressionTests 17 项通过，之前 fixture 卡住没有通过修改读取逻辑掩盖。最新 iOS Debug 构建与保留数据安装通过。
- 全量回归首次 2022 通过、3 失败、1 跳过：两个源码契约仍指向已迁移声明位置；跨进程锁 helper 的 /usr/bin/python3 是 xcrun shim，沙盒禁止启动。修正契约指针并改用系统 Perl 直接 flock 后，跨进程三项通过。全量重跑 xcresult 为 2025 通过、1 跳过、0 失败（参数化执行计数 2072 通过）。
- 真机自动化两次初始化超时；结束遗留 Runner 后恢复。此前无 Share。基线发现 QA Outputs 有 1 张遗留输出，已先独立读回并限定 QA 相册清理，cleanup 通过。
- 19:57 正式三张 [1,3,5] 请求 0D7E8B62-13FE-4916-9B7A-40915AF9F89E：extensionRegistered/submissionConfirmed/extensionCallback/extensionProductionStarted 均确认；完整 executor 入账，第一张进入 static import。
- 八次 30 秒 PhotoKit 读回仍未得到三张，严格无 host foreground 测试失败。扩展第一张 import 后没有 stageDuration、完成或中断日志，进程后来不在列表中；未找到对应 crash/近期 Jetsam 证据。
- 测试结束后 20:01:27 host 出现新 registration/drain/恢复处理，20:01:42 三项保存完成。这是恢复路径证据，不能算扩展后台验收通过。
- 三张均为约 3658 万像素 JPEG，估计单张解码 146 MB，扩展 callback 可用内存 214 MB。资源压力为推测，尚未确认，不能据此偷偷降画质。
- 已增加 DEBUG-only 导入阶段 marker 和独立 full-import 诊断入口（不渲染、不保存、不 acknowledge），用于区分 decode 内存、位置 enrichment 和扩展 lifecycle。测试控制流程完成并不等于 import marker 完成，必须另读共享证据。

## 用户复核后的路线校正

重新读取《后台图片处理方案》完整原对话。原方案明确是 Share durable commit → Continued submission → host background handler → 原有 BatchQueue；反对扩展硬撑完整渲染。扩展回调/解码探针成功不构成 host handoff 成功。当前扩展正式 worker 仅保留 DEBUG 证据，不作为生产主线。

- 独立 full-import 定位曾确认 completeRequest 后进入 import.beforeDecode，无 decoded/completed 标识；因此尚不能认定内存终止，只有解码边界停滞证据。诊断没有正式输出。
- 用户指出方向问题后，撤回未验收的 bounded-preview API、对应测试以及 full-import 扩展诊断分支；没有改变原分辨率和正式渲染/保存语义。保留轻量 DEBUG 阶段 marker。
- 回到 host marker 探针：扩展只提交 host 已注册的具体 identifier，不注册扩展 handler；host 再次启动应恢复相同 identifier，不再每次随机生成新值覆盖待提交/待处理标识。后者是重新核查发现的注册恢复风险。
- 新入口 continuedHostHandoffProbe 和真机测试只证明无前台提交/Photos readback，必须另读 hostCallback + markerCompleted，不能因 UI 测试绿色就报告接管成功。

### 21:00 校正后的 host 接管探针

- 真机 UI 测试 1/1 通过，只证明三张 [0,3,6] Share 提交、sheet 关闭及 30 秒无 host foreground、输出相册为零。
- 同一 concrete identifier 600437B5-7456-4882-B1BB-4FE7475B2D98：host registered 20:59:18、extension hostHandoffSubmission/submissionConfirmed/submitted 20:59:39、completeRequest 20:59:40。独立共享容器读回没有 hostCallback/markerCompleted，交接未验收。
- 恢复原 import 后 PhotoImportService/MediaDecodeLayer 契约定向回归通过；原画质与预览默认解码策略没有变化。
- 当前 P0 重心为跨进程任务归属与 host callback，而不是扩展 Renderer 性能。下一项是主 App 自提交的阳性对照，以区分 BackgroundTasks 整体不可用和 extension-to-host 路由问题。

### 21:03 主 App 自提交阳性对照

新 concrete identifier 7A6AA95B-3F29-4472-8C10-86C193AB29C5：registered → foreground submissionConfirmed/submitted → hostCallback → markerCompleted 全部出现；callback 比 submitted 晚约 0.03 秒。这是明确的前台自提交对照，不能算 Share 无前台成功。先前复用已经提交过的 identifier 得到 BGTaskSchedulerErrorDomain 3，因此新一轮使用新 identifier，重启恢复则保留待处理 identifier。

对照结论：主 App 的基本 register/submit/callback 路径可用；Photos Extension → host 的请求归属/路由仍是 P0 未通过边界。内存调查不再作为当前主线。

### 21:11 .fail 即时资格对照

首次在分享前基线断言发现 1 张输出（此前主 App 对照恢复产生），没有追加 Share。限定 QA output 清理通过后重试。9AE31C9C-207F-4C8D-BD18-ABE56F68A9AF 的 extension hostHandoffSubmission/submissionConfirmed/submitted 均出现，策略为 .fail，30 秒没有 hostCallback/markerCompleted。因此目前不能仅解释为 .queue 排队；仍不能据此宣布 OS bug 或 API 永远不支持。UI 1/1 通过只代表零跳转/零输出观察。

Apple SDK BGTaskScheduler.h 的 register 文档明确说某些扩展可以 submit，only the host app will be launched to handle background work；BGTaskRequest.h 的 Continued init 又说明 app 与 extension 可用。这为原方案提供合理依据，但特定 Continued 跨进程路径尚未被实机证明。继续以最小复现和任务归属核查为门槛。

### 系统调度归属证据

只捕获匹配 com.serydoo.PhotoMemo 的 idevicesyslog。21:17:32 RunningBoard/powerd 在释放 9AE31C9C 的 Continued Processing assertion 时，目标明确是 xpcservice<com.serydoo.PhotoMemo.iOS.ShareExtension([app<com.apple.mobileslideshow>...])>，而非 MemoMarkiOS 主进程。该 assertion 已存在约 6 分 36 秒。这直接支持“当前设备上扩展提交的 Continued task 绑定扩展”的判断；不能仅用 host bundle 前缀把任务当作已路由到 host。

本次新 UI 轮在前台状态断言阶段失败，没有发送新素材；系统日志记录的是先前 9AE31C9C 任务的释放，不能当成新轮 handoff。下一步应以消除测试状态竞态、准确记录请求归属和最小复现为主。

收尾状态：已用 disableContinuedProcessingSpike 清除本轮调试开关并取消限定前缀探针任务，避免留给用户一个假后台路径。没有删除基础配置、UI/research 改动或原始素材。真机 harness 的主 App 离开前台检查改为有界等待（仍在 Share 前），防止把状态过渡当后台证据。
