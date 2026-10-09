# Share → 主 App 后台接管：下一步门槛

## 目标
Photos 多素材 Share 后不打开 MemoMark 主界面，由受系统允许的执行机会推动同一 durable 队列。主 App 已有处理、配置和媒体语义不重写。

## 实施边界
Engineering Loop；P0 系统执行权边界调查。证据是 host callback 缺失与扩展 assertion 归属。只影响 DEBUG 启动入口、DEBUG Share 入口与真机 harness；durable intake/ledger/receipt/configuration 的 source of truth 不变。复用 BackgroundTasks、App Group、系统签名和 Photos Share。风险包括错误安装探针、遗留调试任务、误把 UI 成功当 runtime 成功；用独立构建目录、独立证据命名空间、正常包恢复和逐轮 readback 控制。

## 已有证据
主 App 自提交 marker 通过；扩展自注册 marker/有界 JPEG 探针通过；扩展提交 host 注册标识仍无 host callback。当前 Beta 的 RunningBoard assertion 绑定 Share Extension。完整 Renderer 扩展实验不能代替 host 接管验收。

## 第一门槛：隔离复现
构建条件 MEMOMARK_HOST_HANDOFF_MINIMAL，仅 DEBUG 生效。相同 bundle ID/签名/App Group，替换启动入口，不初始化 MemoMarkAppRuntime；Share 只计数，不读取 provider 内容、不导入文件、不创建队列任务、不访问配置。所有证据使用独立 isolatedHostHandoff 命名空间。正常构建完全不启用。

矩阵：host 自提交阳性对照；extension → host 标识（warm）；extension 自提交阳性对照；iOS 27 async 与 legacy 提交对照；需要时追加冷进程 marker（不等同用户强制退出）。所有条件精确 concrete identifier，一次性 marker，不使用 Renderer 或 PhotoKit。

验收：提交回执、completeRequest、callback 来源/PID、marker 完成、RunningBoard assertion 归属均独立记录；UI test 绿色不等于后台 marker 完成。分享后禁止启动/激活主 App，直到该轮观察结束。

## 第二门槛：处理路径决策
若 host 接管通过，用原 BackgroundBatchQueueWorker runUntilQuiescent + 原 arbiter/receipt 接入。若最小复现仍绑定扩展，不能继续声称 host 能自然接管；保存系统日志与最小代码，核对稳定版/官方支持边界。扩展受限执行是另一架构选项，必须独立评估原分辨率、Live Photo、内存和 GPU，不能临时用预览降采样代替正式画质。

## 第三门槛：生产矩阵
多 Share 与幂等；取消/暂停；过期/系统终止/恢复；多 JPEG/HEIC/Live Photo 输出与元数据/配对资源读回；系统 progress 单一 authority；稳定系统与 iOS 18–25 BGProcessing 回归；完整自动测试/构建/diff check。

## 保护与收尾
不清空配置/历史数据库，不改原始素材，QA cleanup 仅指定 Outputs。隔离安装前保存最新正常签名 app；隔离轮结束恢复正常 app 与关闭 DEBUG 探针。不提交、不推送 dirty 工作树。

## 2026-10-08 隔离真机结果

iPhone 17 Pro Max / iOS 27.2 Beta，同一签名、App Group、bundle ID。未初始化业务 runtime、未加载任何图片；Share 仅计数三项输入。

| 条件 | 提交 | 实际 callback / marker | 判断 |
|---|---|---|---|
| host 自提交 async | confirmed | host / completed | 阳性对照通过 |
| extension → host async | confirmed | 观察窗口内无 host callback | 接管不通过 |
| extension → host legacy | returned | 观察窗口内无 host callback | 接管不通过；returned 非 daemon 完成证据 |
| extension 自注册 async | confirmed | extension / completed，completeRequest 后约 0.3 秒 | 扩展阳性对照通过 |

RunningBoard 对 host-async 请求的 Continued Processing assertion 指向 Share Extension。当前证据排除业务队列、Renderer、图片解码内存作为最小接管失败的原因；不能据此宣称所有稳定系统都不支持该路径，或直接定性系统 bug。UI harness 通过仅证明多素材提交、保持 Photos、Outputs 为零。

下一步：保留最小复现及事件 readback；核对 Apple 对 Continued Processing 扩展请求的具体执行归属与稳定系统差异。在 host 接管被证实前，暂停全量接入该未经验证的通道；继续保留原 BGProcessing / foreground recovery 与 durable queue。不得用预览降采样或打开主 App 的结果替代后台验收。

## 正常包恢复与回归

隔离矩阵结束后已重新构建并安装正常 Debug iOS 包，关闭 Continued Processing DEBUG 探针；安装保留配置和 App Group 数据。2026-10-08 最新完整正常回归 xcresult：2025 passed / 1 skipped / 0 failed（含参数化执行 2072 passed），正常 iOS 签名构建成功、git diff --check 成功。测试读取最终 xcresult，不以流式日志判断。自动测试不构成无主 App 激活的生产照片后台验收。

## 提交线程修正门槛

Engineering Loop / P1 SDK 调用合规：BGTaskScheduler.h iOS 27 新提交 API 明确要求避开主线程；现有两个 DEBUG 探针位于 MainActor。改动限定共享提交适配器与两个 DEBUG 调用点；不触碰 intake/ledger/receipt/configuration 真源。请求在 concurrent executor 内构建并提交，仅传入 Sendable 值，记录提交线程；先重现线程不符合条件，再重跑 isolated host 自提交与 extension→host，最后恢复正常包。不能先把该发现定为接管失败根因。

## 取消素材生命周期门槛

Engineering Loop / P0 数据保留：现有取消入口直接清理 queued source，终态清理同样缺少其他未完成任务引用检查。先用独立 temporary intake 与两个 durable jobs 复现；只调整 BatchQueueStore 清理边界，保留 ledger/receipt 状态机和不可中断 PhotoKit 保存策略。检验同源不同会话取消后剩余任务源文件仍存在，最后消费者终态后才清理。

提交线程验证：旧 main=true 由独立实时 syslog 复现。修正后 host 自提交 BA34AD1B 与 extension→host 7B055A98 均记录 main=false；host 自提交 marker 完成，extension→host 接受但观察期内无 host callback。UI harness 两项通过不等于后台接管通过。SDK 线程边界已修正，未证实其为接管失败根因。正常签名构建通过并恢复安装，配置保留。移除两个 App 同步组文件的多余显式 Share membership，避免重复编译；线程诊断改用 pthread_main_np，兼容 Swift 6 async 检查。

取消测试纠正：最初夹具用 admit 插入两项，准入策略合法地将连续 Share 归为同一会话，因此那次整体取消不是缺陷证据，已撤回该解释。改用恢复历史独立会话的 durable commit 后，无保护清理再次导致引用素材提前删除；保护版本的 Store persistence + durable runtime 共 34 项通过（含 job/session 两种取消参数）。清理保护统一覆盖取消、回执恢复与终态清理；终态入口先刷新独立写者账本。

继续真机验证首页 7 张多素材暂停/继续/取消，结束清理本轮 QA Outputs。这项测试明确激活主 App，只验收控制链路，不冒充独立后台输出。

## 用户要求的重装前取消门槛

暂停新素材发送。只读队列证据显示 14 项恢复记录停在 savingToPhotoLibrary，取消规则禁止该阶段导致长期保留。Engineering Loop / P0：仅在排他执行锁证明无并行执行者、且非当前处理器实际保存任务时允许取消恢复项；保留 receipt/readback 不重写，不能因此把不确定保存重新排队。测试覆盖外部 owner 拒绝、取消落盘与重启保持、回执保留。真机用既有任务验证，按钮生效后才按用户授权删除旧安装并安装新包；随后等待用户重新配置再测试。

删除入口采用终态会话记录 tombstone（BatchJob.historyDeletedAt 可选字段），拒绝删除仍在运行的会话；UI 隐藏记录，保留内部 ProcessingIdentity 与 save receipt 证据。旧 JSON 缺字段按 nil 解码，未增加第二队列或复制事实来源。Home 页终态卡片显示原生 trash + 二次确认，四语言文案明确不删除已保存照片。只用既有遗留会话进行真机取消/删除/重启检查，不新增 Share。

## 重装前实际按钮验收通过

真机既有任务取消/删除/重启测试通过，未发送新 Share。独立队列读回显示原会话 5 个 jobs 全部终态、historyDeleted=true，pending 14→0；已有完成项不改写。按钮触发后约 0.1 秒返回，重启未恢复处理。完整自动回归 2029 passed / 1 skipped / 0 failed；Release 签名构建成功。按用户明确要求，保留本轮证据后进行全清空卸载重装；重新配置由用户完成，在配置完成前不发送新素材。

清空卸载及新包安装已完成；fresh-install 独立读回 jobs=[]（0 项历史/未完成队列），随后无调试参数正常打开 App。未代替用户设置记忆对象/锚点/相册，未发送新素材。等待用户完成配置是本次用户明确要求的测试前置条件。

## 用户重新配置后的 GlassCard 三素材轮

配置 revision 5，presentationRoute=glassCard，目标 QA Outputs ID 已核对。正常 BGProcessing 路径、Share 后不激活主 App：三项 intake 持久化、调度 accepted、completeRequest 均记录；四分钟八次独立 PhotoKit 读回全部 0，未记录后台 callback。此轮不通过，不将 scheduler accepted 当执行承诺。

单独主 App 恢复后输出 3 项（1 Live Photo + 2 still），尺寸分别 2268×4032、4536×8064、3888×6912；媒体子类型不是完整配对/EXIF 保真验收。恢复测试在清理阶段系统删除确认未处理而超时，输出成功与收尾失败分开。Engineering Loop / 仅 harness：复用已有确认处理 cleanup，先前 xcresult 提供失败复现，不改业务队列/配置。

扩展 GlassCard 三素材轮：callback 后进入原 production worker，事件停在 extension.import.beforeDecode；没有 decoded/share.completeRequest，进程随后不在 processes 中；八次 Outputs 均为 0。已复制 keep 模式 crash/Jetsam，当前无匹配本轮的终止报告，内存根因未证实。

Engineering Loop / DEBUG 验证顺序修正：系统 callback 可以早于 Share 接收流程返回，MainActor 重解码可能阻塞 0.7 秒后的关闭入口。为生产 probe 设置按 requestID 的 completionRequested 门槛；在 Share 发出 completeRequest 前记录，worker 在有界异步等待后才开始，测试仍以 Photos 前台与 host 非前台验证实际界面，不把 flag 等同关闭完成。不改 Release 调度或输出画质。

后续独立 shared preferences 补到 bgProcessing.callback / leaseAcquired / queuePrepared / processingStarted / finished：2026-10-09 00:13:03 开始，00:13:20 completed。它晚于扩展轮四分钟窗口结束，早于后续恢复 harness 00:21:50 启动，撤回将这批 3 输出归因于恢复测试启动的解释。缺该时点连续 host foreground 状态证据，不能直接宣告严格后台验收；但实际系统 handler 执行已成立，调度延迟与执行失败必须分开。

重复意图关闭门槛轮在分享前导航失败，未提交新任务。AX 显示 Photos 仍是 QA Inputs 多选，原 navigationBar.firstMatch 点到了全选。修正只用明确 QA album title、取消后等选择按钮，禁止盲点首个导航按钮；保留真实未提交失败证据，不计为处理失败。

关闭门槛重试：share.completeRequest / shareCompletionRequested 先于 import.beforeDecode，顺序修复成立。kernel 在 00:36:33 明确记录 MemoMarkShareExtension pid8586 ActiveHard 220 MB、225281KB、per-process-limit jetsam，当前内存根因首次取得直接证据。重复意图观察 harness 绿色仅证明三项提交/无 host foreground/Outputs=0，进程被杀意味着不能宣称幂等完成。之后既有任务取消/删除测试通过，没有新增 Share。

Engineering Loop / 有界预览切片：MediaDecodeService 新增可选 maxPixelDimension，默认行为保持；仅 DEBUG extension worker 导入使用2048预览预算，bounded 解码失败不退回无界 Data/UIImage。正式 RecordCardExportPipeline 仍重读原图且按原 metadata 尺寸输出；以实际缩小预览+原尺寸 GlassCard JPEG读回/原文件bytes保持验证。此改动仅排查解码卡点，不能冒充整条扩展内存验收。

有界预览通过实际 JPEG几何专项：14 tests / 19 parameterized runs，完整2030 passed /1 skipped /0 failed。真机有界预览记录2048×1152 decoded；正式输出依旧8064×4536，在 artifactReady 后正式源图 thumbnail 解码再次命中220MB硬上限，238913KB/per-process-limit，未到 sourceDecoded。本轮取消/删除通过，故不继续无变化重复。

DEBUG 下一个切片：仅 upright orientation=1 改用 ImageIO deferred direct image，避免 full-size transformed thumbnail 的 eager allocation；非upright保留既有正确 orientation path，Release 不变。系统低级 JPEG readback probe 已用 direct decode 成功，但不据此假设完整 native GlassCard compositor 内存可行。独立事件追踪 sourceDecoded / compositionReady 与kernel峰值；不用系统 UI绿色或重复意图零输出替代完成验收。

官方参考：Apple Core Image Programming Guide 指出 CIImage 是 lazy recipe；WWDC20 10008 建议复用 context/不缓存视频中间项。它们没有保证220MB内任意静态JPEG/NativeGlass流水线。Apple QA1895 提供不重压缩的ImageIO元数据拷贝，仅作为下一步备选基础，未接入。

Deferred upright 源图试验进入 sourceDecoded，随后合成时 225282KB/220MB 被杀，未到 compositionReady，明确不是仅解码优化可解决。Engineering Loop / 下一切片限定 DEBUG CPU JPEG writer：复用 MetadataPreservingImageWriter 原 sanitizedMetadata 和 Unicode patch/file dates，不另造元数据真源；真实文件测试尺寸/EXIF/中文说明/源字节保持先红后绿。还没接玻璃材质/PhotoKit，不宣称输出验收。

CPU JPEG writer 实际整个 GlassCard suite 15 tests /20 parameterized runs 通过（单方法CLI过滤最初匹配0项，已用整个suite确认，不记假绿）。保留1080×1440、EXIF拍摄时刻/ISO/Make、中文UserComment/TIFF说明和源bytes。使用MainActor lazy context避免正常Debug启动平白初始化CPU资源。

Engineering Loop / DEBUG renderer-neutral CPUStillImageExportExperiment：消费既有 artifact，不新增卡片布局；源文件lazy CIImage+原尺寸aspect-fill；原生Glass仅在覆盖区域及保护边界raster，最终CI组合直接文件编码。复用原writer metadata/Unicode patch，CPUcontext32MB render memoryLimit（不是整个进程保证）。先像素位置/原生暗轨/full-canvas读回，再真机220MB边界测试。Release不选择该路径，Live Photo视频配对没有因此通过。

CPU native区域真机已到 regionRendered/materialReady/beforeFileWrite，随后直接CIContext JPEG写入228401KB被杀。32MB memoryTarget只约束render任务而非JPEG编码输出全帧；该试验不能继续冒充有界内存。下一DEBUG切片用8行CPU raster写临时RGBA文件、read-only mmap供原ImageIO writer同步编码；总尺寸上限512MB与磁盘剩余量门槛，任何异常defer关闭/解除map/删临时文件，每条strip检查取消。不对稳定版/整个进程足迹作未经测试保证，文件map能否避免编码峰值以kernel实测决定。

分块磁盘raster真机三张完整JPEG文件写入通过，分别8064×4536/8064×4536/4536×8064；每张约数秒，stripsWritten后可用预算约114–136MB，本轮无jetsam。零相册输出是重复意图原保存结果已清理造成回执读回阻塞，不宣称PhotoKit完成。完整2032 passed /1 skipped /0 failed。

下一真实三输出轮通过正式配置界面临时启用照片说明补充“后台验证记录”，形成真正不同的输出metadata意图，保存原toggle/text并在观察结束后恢复、保存，记忆对象/锚点/GlassCard/QA相册不改。不注入假nonce、不清空幂等/回执。Share后三张[1,3,5]保持Photos，独立相册必须3，取证后授权清理；恢复UI属于本轮结束后的收尾，不冒充后台执行。

## 2026-10-09 02:06 — Three actual original-size still outputs after Share dismissal

- `MemoMarkCPUFreshIntentRetryRound.xcresult`: 1 passed, 0 failed. The first 30-second Photos-only checkpoint contained 3 fresh JPEG assets; two 8064×4536 and one 4536×8064. No host activation occurred between Share submission and output observation.
- Independent App Group events confirm request CECCF203-8FEC-4727-A068-AB7CDC5E949C, Share completion request, and three full-size CPU mapped-file exports followed by task return. This is actual PhotoKit album output, beyond the earlier encoding marker.
- UI test used a real temporary photo-description semantic variant. Cleanup readback returned 0 assets; original custom-description toggle returned false. Whitespace left by keyboard submission was detected; test now dismisses via native Done instead of inserting a newline, and normalizes blank placeholder text when restoring.
- First attempt failed before Share because the text field lacked keyboard focus; corrected harness focus and actual Save Configuration label. It is not evidence of a pipeline failure.
- Next gate: a mixed 3-item round with one Live Photo and two different still sources, preserving original-format semantics and verifying Live Photo classification. DEBUG experiment remains unpromoted; no full V5 or stable-OS certification.

## 2026-10-09 02:13 — Live Photo mixed-round memory rejection

`MemoMarkCPUMixedRound.xcresult` failed the four-minute Photos-only output gate. Request 49CE2E15-783D-4A5A-914F-E874C3A8726B reached Share completion and bounded still import. Kernel at 02:08:33 reports ShareExtension PID 8811 exceeded ActiveHard 220 MB and was killed at 225282 KB, per-process-limit. This is not an accepted Live Photo path. Add DEBUG-only stage markers around card/overlay/pair composition to locate allocation; do not infer the exact stage from absence of static-export markers. Separate cancel/delete test dispatched after bounded observation ended. User configuration restoration belongs after the observation and cannot establish background completion.

### Follow-up control and restoration evidence

- `MemoMarkLiveRestoreAndDelete.xcresult`: 2 passed, 0 failed. Failed-session history removed and stayed removed after restart. Initial cancel-only harness was incorrect for an already-terminal failed session; it now checks the available delete action when cancellation is no longer applicable.
- Independent frozen configuration readback confirms custom-description is disabled. Remaining whitespace in the disabled custom-text storage has no active output semantics; exact text-field clearing requires additional harness verification. Do not describe the stored text as byte-identical to baseline.
- Diagnostic mixed rerun C262DAEF-10C6-49D9-B854-87D123154B43 hit 220 MB at 02:19:49 before import/card markers. This moves investigation to admission/bootstrap/identity compilation and prevents assuming every memory failure is video composition. Additional available-memory markers inserted at those boundaries. No production behavior change from these markers.

### Admission diagnosis correction

Independent preferences can lag the immediately written events. A later read of C262DAEF shows beforeCard / beforeOverlay / beforePairComposition; the earlier missing markers do not prove admission failure. The following 30-second diagnostic request independently passed all admission boundaries with about 205 MB available at beforeTaskLoop, then reached beforePairComposition and was terminated. Its UI-test pass denotes completion of the diagnostic observation with zero outputs, NOT production output acceptance. Additional pair-composer markers distinguish still and video next; avoid unnecessary identity or ledger modifications without evidence.

## Gate before mapped Live Photo still experiment

Latest pair diagnostic reached beforeStillComposition but not beforeVideoComposition before memory termination. Preserve existing source/geometry/artifact and `ImageIOLivePhotoStillImageWriter` as metadata/pairing authority; extract reusable lazy CPU recipe and scoped mapped-raster callback from proven JPEG experiment. DEBUG Share-only admission; normal host and Release unchanged. Unit gates: JPEG and HEIC original dimensions, Apple Maker key 17 pairing identifier, unchanged source bytes and scratch cleanup. Then rerun three mixed assets without host foreground. This does not certify video output, color/HDR fidelity, cancellation or stable OS by itself.

### Mapped Live Photo still unit gate

`MemoMarkLiveStillGreen.xcresult`: 17 test cases, 23 parameterized executions, 0 failures. New JPEG/HEIC fixture verifies MakerApple key 17 pairing identity, 1080×1440 output, unchanged source bytes and empty scratch directory. Shared lazy composition recipe plus synchronous mapped-raster encoder callback delegates all Live Photo metadata to the existing writer. Only DEBUG Share selects this route; normal host/Release remain on the established composer. iPhone build-for-testing passed. Dispatch full three-item mixed Photos-only output gate and full automated suite next; pairing-header unit evidence is not Live Photo asset/movie readback certification.

## Three mixed assets succeeded without host foreground

`MemoMarkMappedLiveMixedRound.xcresult`: 3 passed (controls cleanup, mixed output, restoration), 0 failed. Request 55DD01D4-BFBF-4C8D-9CF1-3A43F16DA3AF independently reached beforeStillComposition then beforeVideoComposition, all 3 task returns and extensionProductionCompleted. Photos inventory: 1 Live Photo 2268×4032 exposing photo + pairedVideo, 2 JPEG stills 4536×8064 and 3888×6912. User never had to open MemoMark between Share and output observation. Album was subsequently cleared by the QA helper.

Full suite caught experimental ImageIO metadata reads in the composer, violating the media-geometry boundary. Moved observation to existing media input adapter, left composer delegating canonical artifact + writer. `MemoMarkMappedLiveArchitectureGreen.xcresult`: 18 cases / 24 executions passed. Full rerun underway. Next same-session gate retains outputs long enough for actual PhotoKit resource metadata readback and repeated Share comparison before cleanup; inventory and temporary-file unit results are kept distinct.

### Real-resource description gate remains open

`MemoMarkMixedReadbackRepeatRound.xcresult` stopped before repeated Share because actual PhotoKit TIFF text did not contain the temporary QA supplement. Three outputs existed, Live Photo input/output inventory and pairing resource assertions passed. A separate diagnostics-only test read all three saved resources: TIFF description exists for all; JPEG EXIF UserComment exists, but neither contains the expected QA supplement; HEIC UserComment absent under the existing non-ASCII policy. Frozen job confirms supplement enabled, so do not claim full supplement semantics acceptance. Also discovered test caret deletion accumulated strings across rounds; native Select All replacement + exact-value check now required. Restore user baseline separately. Continue independent repeated-intent gate without representing metadata-field existence as successful supplement-content verification.

Mapped raster failure and orphan scope tests passed: 19 cases / 25 executions. The cleanup adapter only removes UUID-named regular .rgba files within UUID Live Photo work directories; symlinks and unrelated files survive. Invocation stays after exclusive execution lease acquisition.

## Shared semantic projection parity repair gate

Metadata investigation found `MEMOMARK_SHARE_EXTENSION` exclusions in CardVariableProvider and CardTextBlockEngine. Those bypass resolved MemoryResult/module summary and production expression context in Share while RecordCardBuildService already compiles the same frozen semantic objects. This explains missing custom summary in extension-generated pixels/description without blaming PhotoKit. New architecture test first failed on both files. Remove only these pure-data target forks; retain UI/application guards elsewhere and existing formatter/description writer. Build actual extension, read real PhotoKit description with a precisely replaced QA supplement, and re-share same frozen intent before cleanup. No configuration migration or user UI replacement required for the projection repair.


### 2026-10-09: isolated frozen description fixture and device automation blocker

The metadata readback fixture now overrides only the admitted request snapshot photoDescriptionOverride, under DEBUG + Share Extension + active bounded production probe. It does not save the configuration library or alter GlassCard layout text. The saved configuration was independently read back with custom text disabled and empty.

Three consecutive signed-device executions failed before UI testing initialized: timed out while enabling automation mode. No new Share was sent; these results do not grade background output, metadata or repeat-intent behavior. Bundles: /tmp/MemoMarkFrozenDescriptionRepeatRound.xcresult, /tmp/MemoMarkFrozenDescriptionRepeatRetry.xcresult, /tmp/MemoMarkFrozenDescriptionRunnerRecovery.xcresult. Device lockState reports passcodeRequired=false and unlockedSinceBoot=true. Stale runner already exited when termination was attempted.

Latest unsigned generic iOS Release build completed exit 0: /tmp/MemoMarkV5FinalRelease.log. Actor-isolation warnings remain; this is compilation evidence, not signed Release runtime acceptance. Full Mac test run /tmp/MemoMarkFrozenFixtureFull.xcresult remains in progress. Explicit missing destination albums fail closed; do not silently redirect into the general Photos library if the user deleted the album itself.

Full latest Mac regression completed: /tmp/MemoMarkFrozenFixtureFull.xcresult reports 2,036 passed, 1 skipped, 0 failed (2,086 parameterized executions). Two existing FixtureExportReadbackTests priority-inversion runtime warnings are reported. git diff --check passed. The remaining frozen-description and repeated-Share device acceptance is still blocked before test initialization; it must not be represented as passed.


### 2026-10-09: user-requested device retry passed

/tmp/MemoMarkFrozenDescriptionUserRetry.xcresult: 1 passed, 0 failed. Warm background Photos Share, without host activation between submission and output, produced three assets at 2268x4032 (Live Photo), 4536x8064 and 3888x6912. Actual saved resources passed frozen TIFF description readback, Live Photo still MakerApple identity presence, pairedVideo resource presence and existing capture-date/original-preservation gates. Repeated identical Share retained the exact same three asset identifiers. Both Continued Processing extension owners recorded extensionProductionCompleted before post-test host activation. First request 89CD7450-6D22-405B-8287-EC26B7B0312C; repeat 72D9E7AD-8CC3-4DA3-8285-DC7D84739228. Repeat still performed rendering before receipt-based save suppression; no claim of computational deduplication. Cleanup inventory is zero. Configuration readback: custom text disabled and empty; temporary description fixture key removed.

This is DEBUG opt-in signed-device evidence on iOS 27.2 Beta, not production Release or cold host launch acceptance. Remaining gates include paired movie embedded identifier equality, cross-Share concurrent sessions, interruption/lock/cancellation recovery, formal execution/presentation integration and supported stable OS matrix.


### Next gate: actual paired movie resource verification

Bounded objective: extend signed-device acceptance only; no production media behavior change. PhotoKit remains canonical asset/resource owner, ImageIO reads saved still MakerApple[17], AVFoundation reads saved MOV content identifier, video duration/tracks and still-image-time timed metadata. Access is local/no network; readback temp files deleted at scope exit, QA outputs only cleaned after evidence. Use a distinct frozen photo-description value (real output semantics) because prior outputs were deliberately deleted; do not clear durable receipts or bypass ambiguous-save reconciliation. P0 gate: still/movie identity equality and readable movie; P1 gate: still-frame marker within duration. Evidence is DEBUG warm-background on current signed beta device only.

Signed actual saved paired-resource readback passed in /tmp/MemoMarkSavedMoviePairReadbackOnly.xcresult (1 passed). The first new async UI test failed in its synchronous DispatchQueue-main observation interval before resource checks; it is not a rendering failure. Test entry changed to synchronous XCTest and async AVFoundation reads bridged under a bounded expectation. Actual readback verifies equal still MakerApple[17] and MOV content identifier, positive finite duration, one video track, exactly one still-image-time sample in range. Cleanup succeeded. Full fresh background round remains necessary to combine these gates in one independently observed run.

Next continuous-Share gate: two immediately consecutive Share submissions select [0,1,2,3,4] and [2,3,4,5,6], ten selections/seven unique sources. No output wait between submissions, no host activation. New DEBUG per-request lease acquisition/release/session probes provide evidence for exclusivity and membership. Natural timing determines whether execution truly overlaps; never report an overlap if first lease was released before second submission. Production ownership and receipt semantics unchanged.

/tmp/MemoMarkContinuousShareAndMoviePair.xcresult: 2 passed, 0 failed. Fresh mixed background round now combines actual MOV pairing readback, saved TIFF description, three full-dimension outputs and cleanup=0. Continuous five-plus-five overlapping-source selections produced exactly seven output assets and cleanup=0. Natural request timing did not overlap: first lease ended 1791493936.979176, second submission 1791493938.537615. Distinct session IDs are therefore expected, not proof of active-session joining. Expand first selection to all seven and second selection to five; twelve selections/seven unique sources, new real frozen description semantics.

Actual overlapping submission passed /tmp/MemoMarkSevenSourceShareOverlap.xcresult (1 passed, twelve selections/seven outputs, cleanup=0). Second submission at 1791494237.783614 preceded first release at 1791494243.893867; second acquire 1791494244.314078. No concurrent executor. P1 reproduced: second job admitted after first completed, so received-overlap was lost and session IDs differ.

Bounded repair: BatchJob.createdAt for Share candidates is the already durable request.receivedAt; no new persisted schema. Domain session admission may join a visible successfully completed predecessor only if the new request creation timestamp is inside that predecessor creation-to-final-task-update interval. Later, failed, cancelled or hidden-history sessions must not be reopened. Ledger owns atomic admission, existing execution file lease stays intact. Regression tests reproduce delayed admission and reject later/failed/hidden predecessors before the policy fix; actual overlapping signed-device repeat then validates membership.

Delayed-admission domain reproduction RED: /tmp/MemoMarkDelayedSessionRed.xcresult 1 failure; GREEN /tmp/MemoMarkDelayedSessionGreen.xcresult 26 cases passed. Full regression /tmp/MemoMarkSessionBoundaryFull.xcresult: 2,038 passed, 1 skipped, 0 failed. Signed overlap retry /tmp/MemoMarkDelayedSessionDeviceGreen.xcresult: 1 passed. Independent probe shows both requests session=39BB8F35-5CC9-41B2-9ECC-7A5CABF4D757 with serialized leases.

Next bounded P1 repair: system Continued Processing updates currently use only the executing BatchJob even when session membership is shared. ExecutionSession (read-only projection, not durable state) will project 100 progress units per admitted task with incomplete task fractions capped at 95%; worker reports the complete refreshed session. Durable ledger remains sole queue owner. Regression checks completed previous batch, in-progress current batch, unrelated session exclusion and premature completion protection. This does not merge multiple system BG task cards or claim a single system task per session; that scheduling/presentation consolidation remains open.

Session progress regression /tmp/MemoMarkSessionProgressGreen.xcresult: 12 cases passed. Full /tmp/MemoMarkSessionProgressFull.xcresult: 2,039 passed, 1 skipped, 0 failed. Release generic iOS compile /tmp/MemoMarkSessionProgressRelease.log exit 0. Device /tmp/MemoMarkSessionProgressDeviceRound.xcresult UI test passes, but independent timestamps show owner 2 still executing at cleanup/host reactivation; therefore repeated-owner completion acceptance is rejected. Album count alone is inadequate when all outputs already exist from owner 1.

P1 follow-up: DEBUG QA runner receives the same App Group entitlement for read-only completion evidence. It waits for both round-specific submitted identifiers to record extensionProductionCompleted before cleanup/host activation, and validates foreground absence. No queue/receipt/config writes from the test observer. Worker progress now uses actor snapshot immediately after atomic apply/admit, avoiding a redundant disk read per update, and logs only completed/total count changes; Progress still updates each committed phase. Existing pending diagnostic session will be cancelled/deleted through actual Home controls before the fresh round. Signing/App Group access is a separate gate; do not claim observer access without signed runner execution.

QA runner App Group signing failed normally and with automatic provisioning updates: entitlement could not be included in profile. The added QA signing setting was removed; no profile/permission workaround. Completion gate uses existing authorized CoreDevice read-only App Group extraction during a bounded 60-second Photos-only post-output observation window, with round timestamps attached. UI test pass alone never establishes owner completion. Independent submitted/completed timestamps must precede observation boundary and cleanup/host launch; verify final inventory too. The previous observer proposal above did not ship or gain entitlement.

/tmp/MemoMarkSessionInterruptedCleanup.xcresult: 2 passed; real cancel/delete/relaunch and named QA output cleanup. /tmp/MemoMarkOwnerCompletionGuardedRound.xcresult: 1 passed. Independent /tmp/MemoMarkOwnerCompletionIndependent.json confirms both owners completed before the attached Photos-only observation boundary, no interruption, one session DD2C5189-7886-4A63-BB2D-013EA39F549D, serialized leases, second submission before first completion, final progress 12/12 (1200/1200), seven outputs and cleanup=0. This supersedes the incomplete-owner progress acceptance above.

P1 performance audit: DEBUG processingBackgroundProbe writes append unbounded UUID keys and synchronizes shared preferences. Repeated tests increase per-update file work and distract progress. Bound only this owned diagnostic namespace to the newest 512 records, with injected defaults/time for regression tests; preserve all configuration/intake/receipt/probe-evidence namespaces. No production queue retention change. Validate trimming order, new record retention and unrelated preferences before signed runtime recheck.

Probe retention GREEN /tmp/MemoMarkProbeRetentionGreen.xcresult: 1 passed, including 520 historical entries, unrelated preference preservation and clock rollback retention. DEBUG signed build /tmp/MemoMarkBoundedProbeDeviceBuild.log succeeded. Next media acceptance: nonuniform asymmetric RGB fixture with EXIF orientations 1/6/8, compare mapped ImageIO JPEG pixels against independently rasterized upright CoreImage reference and require saved orientation=1. This closes a gap left by solid-gray fixtures; no renderer or original resource behavior change planned unless evidence fails.

### 2026-10-09 Native progress surface: bounded failure, not background acceptance

- `/tmp/MemoMarkBoundedProbeMediaFull.xcresult`: 2,041 passed, 1 skipped, 0 failed. Asymmetric EXIF orientation/pixel gate passed (orientations 1/6/8).
- `/tmp/MemoMarkNativeProgressSurfaceRound.xcresult`: failed the four-minute output observation. Independent observer saw normal intake and BGProcessing submission, no new Continued Processing submission/owner completion. This does not establish a renderer failure or background success.
- Tightened QA launch arguments to explicit baseline and explicit production fixture. Added DEBUG-only launch flag booleans (production/disable), without logging arguments or private configuration, to diagnose activation before another media acceptance round.
- Cancel/delete any leftover normal intake through real controls, and clean only the named generated QA output album before the next round. Preserve source assets, user configuration, and durable save receipts.

### Native surface rerun: output accepted, presentation not accepted

- `/tmp/MemoMarkNativeProgressExplicitLaunch.xcresult`: 1 passed, 7 outputs read back with frozen description, named output album cleaned to zero. Independent owner `971539D8-5429-4F08-A63A-686FD7D7D0C1` submitted 1791498000.350226, completed 1791498020.747170; 7/7 and 700/700 units, no interruption. Completion precedes the Photos-only observation boundary 1791498098.344320.
- Explicit launch flags read back as production=true, disable=false. Original missing activation cause is not conclusively established; explicit fixture avoids ambiguous inherited arguments.
- Notification screenshot showed a historical custom completion card (05:47), a system failure residue, and ActivityKit authorization prompt. These are not proof that the newly completed owner failed. Presentation gate remains open.
- DEBUG host driver now suppresses/ends host-owned fallback activities during the explicitly selected continued-production experiment, before Share submission. Extension enumeration alone was insufficient. Release policy remains unchanged. Added native assertion rejecting the historical custom completion card alongside the experiment.

### Native fallback suppression device gate

- `/tmp/MemoMarkNativePresentationUniqueRound.xcresult`: 1 passed. Historical custom completion card absent (device assertion and screenshot), seven frozen-description outputs verified, named output album cleaned to zero.
- Independent owner D0305211-135D-42A3-87FC-7C8607D1FFBC completed in ~22 seconds, lease released, 7/7, no interruption, before Photos-only observation ended.
- P1 still OPEN: system card displays failure despite successful owner evidence. Earlier attribution to historical residue is provisional: UI exposes no matching request identity. Must dismiss only the MemoMark card, reproduce with fresh output semantics, and compare new UI with execution markers. Do not accept the system presentation gate yet. Native notification screenshots contain unrelated private notifications; retain locally only, do not publish.

### User steering: visible post-Share status on island and non-island devices

- User requests acceptance, in-progress percentage/count, and completion visible without manually discovering notification center; include devices without Dynamic Island.
- Apple BGContinuedProcessingTask documentation: system owns Live Activity and cancellation; app updates title/subtitle/Progress. Do not add a competing custom activity while system execution owns presentation. HIG supports Lock Screen and update banners on non-island devices; system permission/Focus decides interruption.
- DEBUG experiment now uses explicit percentage plus completed/total count, and changes completion title/subtitle to photo processing complete / saved N photos only when the session's actual completed count reaches total.
- QA captures Photos immediately after Share dismissal and notification center both during and after completion. No claim of forced banner visibility or custom system-island layout.
- `/tmp/MemoMarkSystemResidueDismissRetry.xcresult`: 1 passed; dismissed only MemoMark system-card residue without launching host or clearing unrelated notifications. Previous attempt failed a harness screenshot call against a non-running host; fixed to XCUIScreen capture.

### Native completion delivery slice

- Clean-surface `/tmp/MemoMarkStatusReadabilityRound.xcresult`: 1 passed; actual system card displayed `11% · 已完成 0 / 7 张`; independent owner completed all seven without host foreground. After completion the system card disappeared. The previous failure card was removable historical residue.
- Post-Share screenshot previously captured an extension sheet still dismissing; QA now waits for the actual Share-specific heading to disappear, rather than only the submitting button.
- Extracted existing `BatchNotificationMessageFormatter` into a shared Foundation file, retaining one localized text source. Completion draft projects durable session jobs, counts distinct saved asset identifiers, rejects queued/saving/cancelled/failed/missing-receipt states, and uses one stable session notification identifier.
- `/tmp/MemoMarkSessionNotificationRed.xcresult` failed for missing model, as expected. `/tmp/MemoMarkSessionNotificationGreenRetry.xcresult`: 10 cases passed (13 parameterized executions), including existing formatter/localization audit. First green build exposed a test typo (`saving` instead of actual `savingToPhotoLibrary`), corrected without production change.
- DEBUG Share adapter schedules a native completion notification only with already-granted authorization, then acknowledges existing durable final-notification markers. A delivery/acknowledgement error is recorded separately and cannot turn a saved-photo result into a processing failure. Main-app finished title now uses the actual interface language, matching its body.
- Full regression and signed native notification/device round running. Release eligibility and non-island/stable OS runtime remain separate gates.

### Native completion notification accepted on paired Beta device

- `/tmp/MemoMarkNativeCompletionRound.xcresult`: 1 passed. Seven actual saved assets, frozen description readback, no host foreground until after the independent observation window. Named output cleanup readback zero.
- Independent owner 40966176-CF3D-49C0-B3C5-9E42D27FD3B8 completed at 1791500738.733468, after native notification acceptance and durable delivery acknowledgement; session 6E620AC9-7F9C-4835-A553-2A5894E2EAF8, stable session identifier, saved=7. This is successful delivery, not a guarantee of interruption under Focus/count-mode settings.
- Native AX readback shows `07:05 处理 7 张照片已完成` and `已保存到「MemoMark QA Outputs」。`. Lock-screen count mode initially collapses text below visible bounds. QA now taps only the observed notification-count control to expose actual native content for screenshot review. User system settings remain unchanged.
- This round took ~60 seconds, concentrated in first Live Photo (~42 seconds), with the remaining six completed rapidly. No fixed-duration claim. Added current task stage to the existing read-only ExecutionSession projection and a shared four-language formatter for system progress: actual percentage, completed/total, phase. No timer-generated progress.
- `/tmp/MemoMarkNativeNotificationFull.xcresult`: 2,044 passed, 1 skipped, 0 failed; only the two existing fixture priority-inversion warnings.
- `/tmp/MemoMarkContinuedTextRed.xcresult`: expected missing-formatter failure. `/tmp/MemoMarkContinuedTextGreen.xcresult`: 27 cases passed (40 parameterized executions), including locale parity/audit and session admission/progress.
- Latest localized phase/device round and complete regression underway. Dynamic Island visibility still needs actual post-animation screenshot proof; no non-island or stable-OS runtime certification inferred from this device.

### Latest phase slice and stricter native visibility gate

- `/tmp/MemoMarkNativeStageFull.xcresult`: 2,046 passed, 1 skipped, 0 failed (2,104 parameterized executions). Only the two pre-existing fixture QoS warnings.
- `/tmp/MemoMarkNativeStageRound.xcresult`: seven outputs/metadata, owner completion and native notification scheduling passed; named output cleanup zero. Owner 086614DB-6155-4BDE-A6A3-8C8126F61FBB completed in ~24 seconds with stable session C265C3CF-6518-4854-8271-7B8896C027C8, no host foreground until after observation boundary.
- UI acceptance correction: generic saved-album text matched an older 07:05 notification. Thus this round is NOT fresh notification visibility proof. Current Work Focus groups latest MemoMark notifications. Tightened QA to expand only the observed MemoMark Focus group and require a hittable completion title whose minute falls inside the current round, alongside independently correlated native notification scheduling.
- Post-animation Photos screenshot now clearly shows Share closed. No visible Dynamic Island progress in that image; island discoverability remains OPEN and cannot be inferred from the notification-center progress card.
- Stable Xcode installation verified live: `/Applications/Xcode.app`, Xcode 27.0 (27A266a). Latest Release-condition generic build started with explicit DEVELOPER_DIR and isolated derived data. This is compile validation only, not rollout of DEBUG experiments.

### Fresh native notification visibility accepted

- `/tmp/MemoMarkNativeFocusVisibilityRound.xcresult`: 1 passed. Focus-group expansion exposes current `07:43 处理 7 张照片已完成`, hittable inside this round's time window; screenshot and AX both agree. Independent completion/scheduling matched one current owner, seven outputs and frozen metadata, named output cleanup zero. System Focus settings unchanged and other notifications retained.
- Formal Xcode 27.0 generic Release build `/tmp/MemoMarkNativeStatusStableRelease.log`: exit 0. No new warning involving the new shared formatter/session notification sources. This does not graduate the DEBUG Share worker into Release.
- Apple DTS https://developer.apple.com/forums/thread/804515 states that apps cannot control BGContinuedProcessingTask UI timing. Reported device behavior differences in the question are not universal guarantees. Continue actual Photos-foreground vs Home-background comparison without launching MemoMark or starting a competing activity.
