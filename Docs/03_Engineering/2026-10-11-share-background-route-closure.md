# Share 后台入口与编辑连续性收口 — 2026-10-11

## 实施前决定

用户在本次会话授权审核当前源码并落实 Share 后无需切回 MemoMark 的处理与 UI 优化；历史研究仅为线索。基线为 `06bed619`，mixed dirty 文档/私人研究保留；Source/Tests 指纹及完整 Git 清单在 `/tmp/MemoMarkShareRestore20261011`。

Engineering Loop，P1：当前 `ShareExtensionIntakeCoordinator` 在持久接收后始终请求 foreground handoff；这使已经实现并修复 admission 的 Continued adapter 不可达。四样式 canonical publication、额度 identity reconciliation、session 通知范围、preadmission/terminal failure、安静成功和 verified commerce environment 已在当前源码中，不重复修复。

范围：恢复 iOS 26+ 已授权、系统接受后的 Continued route；先提交 BGProcessing 恢复请求，Photos 权限不足或 Continued 不可用/提交失败才走既有 foreground handoff。不宣称 submission 是开始/完成证据。续接、进度、保存仍复用现有 durable intake → execution lease → ledger → media executor → PhotoKit receipt/readback。系统 callback 目前由 Share extension owner 执行，不描述为 host 自动唤醒，也不扩大为常驻后台。ADR-012 的现有生产适配为此项权威；普通 extension intake 中不得直接调用重处理。

产品体验沿用已接受的紧凑 Home、取消入口、失败简短提示、重新分享恢复；Configuration Center 保持 Library → Memory Card → Object Inspector。UI 本轮先复核旋转编辑器焦点和当前布局，只有真机复现后才修改具体 owner；保持 canonical line-box/IME/undo 边界。不安装外部 Skills，不依据第三方 Duo API 描述改动生产代码。

验证：对真实路由决策加 async 行为测试（接受不打开 host、权限/不支持/失败 fallback、handoff 失败仍保持 durable request）；更新既有架构契约并运行 focused/full macOS tests；正式 Xcode 27.0 signed Release；paired iPhone17ProMax 上普通 Photos Share 混合素材与当前编辑旋转。素材按内容、方向、尺寸和真实资源组合选取，不限定 JPEG，不要求删除旧 QA 输出制造零基线。先选 Live Photo、RAW+JPEG representation、普通静态图片，再覆盖当前全部 15 张 QA 输入；使用已保存的临时描述区分本轮，并通过 UI 恢复原配置；以新增 asset identity 与资源读回为事实，重复同一意图应不新增输出。保留 QA 输出与原图，禁止清空配置/相册/请求。稳定 iOS26 与 iOS18–25、峰值资源及全媒体认证分别记录。

研究输入已读取：ChatGPT「MemoMark学习GitHub汇总」「MemoMark后台图片处理方案参考！」「深入研究iPhone Duo方案」及 Codex「实施 MemoMark 后台处理架构优化」。Apple 官方 Continuous task 文档和当前 SDK用于平台约束，HIGAgentSkills routing-index 仅用于选择交互审查主题。事实判定均以当前源码及本轮结果为准。

## 实施与验证

### 当前代码审查结论

- 主链仍为 Photo → Metadata → Memory → Presentation → Layout → Renderer → Export；本轮不改布局、记忆语义、原图或持久配置 schema。
- 最新 shared projection 已发布可验证的 canonical frozen snapshot；过去 revision 41 的 `missingCanonicalSnapshot` 是历史失败证据，不能据此判断修复后的当前代码仍缺此能力。普通 Share 的无条件 foreground handoff 才是本轮实际入口问题。
- 执行仍通过文件互斥租约、actor ledger、ProcessingIdentity、PhotoKit receipt/readback 和额度 accounting；系统调度/展示与完成事实分开。Share 普通接收只做持久接收/提交；重处理仅位于 system-granted Continued callback。
- 系统 Continued 进度使用 ExecutionSession 的实际阶段、计数与进度单位；其拥有展示权时抑制/结束自定义 ActivityKit，避免两个互相矛盾的进度。成功通知保持现有静默行为。
- Configuration Center 当前使用稳定的 TabView 内容身份和 TextKit editing session。旋转焦点应先实测，保留已接受的紧凑 Home、四区域编辑与横屏滚动，不依据研究帖重做工作流。

### 已完成的自动化与构建

- `ShareProcessingHandoffTests` 与 `BackgroundProcessingContractTests`：6 个定义 / 7 次执行通过，0 失败、0 跳过、0 runtime warning。结果 `/tmp/MemoMarkShareHandoffGreen2_20261011.xcresult`。
- 完整 `MemoMarkTests`：2108 passed、1 个既有跳过、0 failed；两条既有 FixtureExportReadbackTests QoS warning。结果 `/tmp/MemoMarkShareRestoreFull20261011.xcresult`。后续修改仅在 device QA harness；生产路由未再次变动。
- 正式 Xcode 27.0、签名 Release physical build-for-testing 和严格 deep codesign 通过。候选仍是本地 2.3.6 (124)，不等同商店已发布的同版本包。
- Governance 和 `git diff --check` 通过；保留原有 mixed dirty 文档/研究，不 staging、commit、push 或外部发布。

### 真机验收记录

本轮 7 张混合 Share 实测失败：7 项接收并 admission，四分钟内新增输出 0；系统界面明确任务失败。详见后续重装与测试方案。已有旋转检查通过的是焦点/键盘存在和文本不变，尚不代表完整横屏视觉、IME、undo、VoiceOver 或 Dynamic Type 的人工验收。

最初单 JPEG 选择因既有 QA 输出重用了可选素材，尚未进入 Share；该尝试不构成处理失败。扩大矩阵后修复 QA harness 的空原生 TextField、Photos 搜索控件及相簿结果页定位。既有 15 张 QA 输入的原始资源读取遇到 `PHPhotosErrorDomain 3164`（正式 SDK `PHError.h` 确认为 networkAccessRequired）；允许取回既有 iCloud 原件的准备尝试又返回 -1009 离线错误。因此改用用户本地素材，未限制格式，未上传图片。

已从「儿子水印相册」「Live Photo测试」复制 7 个真实输入（4 个 JPEG、1 个 HEIC、2 组 Live Photo，共 9 个原始资源），通过 QA runner 在设备 Photos 建立独立的 `MemoMark QA Local Inputs` 相簿，准备检查通过。本地原件 SHA256 九项保持不变；设备端验收要求分享前后原始资源逐字节相等。保留所有既有及新增 QA 输出；动态非零基线发生外部变化时，中止本轮归因，避免将其他运行的输出算成本次成功。

设备为 iPhone 17 Pro Max / iOS 27.2 Beta，正式 Xcode 27.0 签名 Release。普通 Share 已实际进入处理但没有输出，系统顶部任务失败；前置导航失败另外记录。用户要求重装后已覆盖安装签名 Release，恢复临时配置，单张精确定位验收正在进行。生产候选路由与完整 macOS 测试后的源码未再次修改，后续修改限于真实设备 QA harness 和状态文档。

## 用户要求重新安装后的测试方案

- 上一轮 Release 普通 Share `11CEB537-B592-481F-BBA0-E609BEF913F2` 实际接收 7 项，系统接受后关闭 Share，host 未切前台；独立输出基线 4 项，在四分钟观察内仍为 4 项。当前手机截图明确显示「时光记正在处理照片 / 任务失败」。记录为失败；不将随后主 App 恢复处理算作后台成功。
- QA 日期定位与重复搜索存在脚本错误：往年照片标签为 `2025年7月20日`，而原断言只搜索 `07月20日`；Photos 网格顺序也不等同 PhotoKit 按日期排序。失败后继续分享是验收脚本错误，改为 guard 中止；逐项选取按该照片唯一日期标签匹配并验证唯一性，禁止按网格偏移映射 PhotoKit ID。搜索先清除原查询；第一轮未完成不得提交重复分享。
- 已覆盖安装本轮最新签名 Release 2.3.6 (124)，保留 App 数据/权益和 Photos 原件。先固定输入及输出相簿 localIdentifier、输入照片 localIdentifier/日期/尺寸/资源 SHA、配置 revision、安装包/source 指纹；受控观察开始前确认没有旧运行任务混入基线。
- 先一张真实高分辨率输入定位实际失败阶段，再验证多张及 Live Photo；每轮采集 Share request ID、系统 callback/lease、Release 导入前后可用内存、进程在场情况、无 host foreground、原始屏幕截图及新增输出 identity。四分钟没有输出或进程退出即结束该轮，恢复临时配置，不继续发送第二批。
- DEBUG 探针的预览导入为 2048px；当前 Release 为 nil，即完整尺寸，第一项 44811648 pixels。该代码差异已经确认，内存终止仍是待证假设；尚未获取对应 crash/termination report，不凭进程缺席直接宣称 jetsam。Release 添加有界元数据诊断，不启用实验 CPU renderer 或修改输出尺寸以制造成功。

新增诊断候选的 formal Xcode 27.0 signed Release physical build-for-testing 已通过，覆盖安装成功；更新后 focused Share 路由/架构 7 次执行通过。此前完整 2108 项结果来自路由改动后、诊断改动前；诊断不改处理行为，仍不把其视为最新设备成功证据。

### 导入预览资源修复决定（实施前）

单张重装 Release 请求 `D263C8DE-01BA-43F1-804B-182781D38965` 已按唯一目标日期定位，无前置定位断言错误。callback/lease/admission 已记录；`extension.import.beforePreviewDecode` 为 availableMemory=214579384、maxPixelDimension=full，目标 8064×5557，单缓冲 179246592 bytes，之后无 previewDecoded，Share extension 进程不在场，后台输出保持基线 4。现有 crash 日志尚无对应 jetsam，按「完整预览解码阶段退出」记录，不夸大为已证实内存杀进程。

Engineering Loop / P1，owner 为 PhotoImportService/MediaDecodeService 的内部 preview representation。共享扩展生产导入与 DEBUG 探针一样使用 2048px 预览上限；Metadata、MediaAsset 原始像素尺寸、sourceURL、布局契约、导出尺寸/格式/原图保持不变。RecordCardBuildService 使用原始 metadata，RecordCardExportPipeline 仍从 sourceURL 读取原始导出图像，不用缩小预览替代原图。先验证解码完成与渲染下一阶段，再独立验证 full-size 新输出；若导出还有资源失败，另立有界资源修复，不启用未验收实验 renderer 来跳过失败。

### 静态 JPEG 导出资源修复决定（实施前）

预览修复候选的单张请求 `12454D6B-C138-469D-A455-18154FCAD4BB` 已在真机确认：2048×1411 previewDecoded，import=0.483s、build=0.002s、render.healthCheck.passed；随后导出未完成，新增输出仍为 0。完整尺寸静态合成路径同时需要 source transformed raster 与完整 CGContext/复制像素，未具备 extension 的有界资源条件。

Engineering Loop / P1：将已有可测试的软件 Core Image 配方与磁盘 raster 基础设施提取为责任命名的生产 helper，仅供 Share 扩展静态 JPEG 导出使用；DEBUG opt-in wrapper 保留，生产不读取 DEBUG 开关、不调用实验类型。依然消费同一个 PresentationArtifact，保留原始 sourceURL、输出像素、原生 material、图层排序/透明度、orientation、MetadataPreservingImageWriter 与 PhotoKit receipt。磁盘工作文件有尺寸/空间检查、取消检查、defer 清理，并由既有 shared lease 清理中断遗留；不缩小结果图、重绘布局、修改原件或扩大功能。

macOS 验证包括软件输出 full-size/方向/色块、中文描述/EXIF、原件及 scratch 清理，并补 classicWhite 单张小预览→完整输出读回。再以同一个 4480 万像素输入执行签名 Release Share，无 host foreground 的 PhotoKit 新 asset/metadata/解码验收。JPEG 之外、Live Photo 身份恢复、稳定系统与完整认证继续分别列门槛，不推断通过。


### 首个真实完整尺寸后台输出（16:23）

软件导出候选 build16，单张请求 `52E6AC8B-20D9-4D07-8931-DECF276E81C9`：原始输入 8064×5557，2048×1411 内部预览；strip 0/2048/4096/6144、ImageIOEncode/fileWritten 连续完成，export=1.843s、save=0.315s、task total=3.605s，progress=100/100，saved=1、processed=true。过程中主程序未前台。PhotoKit 输出相簿基线4→5，新增 `3DC27CAA-5C16-467F-BB8F-1E3CBDBCF2D5/L0/001`，8064×6808（包括原样式白边）；拍摄时间 `2025-07-20T09:50:34Z` 保留，本轮配置描述写入 TIFF/EXIF，保存资源可重新解码。

该 XCTest 仍为 FAIL，必须保留结果 `/tmp/MemoMarkShareRestoreSinglePhysical3_20261011.xcresult`：静态图却调用历史要求1个Live配对的helper；原件目录比较包含 PhotoKit modificationDate，选中原图该字段变化，但所有资源 SHA、所有其他身份/内容字段完全一致。仅修改新验收流程传入实际预期Live数量，保留配对校验；原件验收分开保存目录时间变化和内容身份/原始字节一致性，不将目录时间视作原始字节变化。未删改Photos原件，无原件PHAssetChangeRequest路径。重新执行以取得完整通过结果；不把FAIL改写为PASS。

最新 macOS全量结果 `/tmp/MemoMarkShareRestoreFullFinal20261011.xcresult` 为2109测试定义通过、1既有跳过、0失败（2179次通过执行）。软件导出focused为43次执行通过。设备单张输出仅证实当前配置/当前Beta系统的这一静态路径；Live身份歧义、其他输出格式、稳定系统、锁屏/终止/权限/资源压力仍待验证。

手机原始截图确认前两轮原生状态为「时光记正在处理照片 / 任务失败」。最新输出完成后直接截取当前屏幕为Home，顶部仅Photos任务图标及系统麦克风；尚未捕获展开的本次完成文案，不能宣称接收/处理/完成三态UI已人工验收。截图及设备资源留在/tmp，不加入Git。


下一有界真机批次：选择本地相簿5张静态分类图片（4 JPEG/1 HEIC，内容/尺寸各异），逐张按唯一日期定位，保留原始资源哈希与新增输出读回，第一批成功后才验证重复意图。显式Live分类2张保留独立身份恢复门槛；不把静态分类但携带pairedVideo的目录状态当成Live成功。Share关闭后按实际截图已观察的任务气泡位置长按展开系统界面，记录原始屏幕和AX，观察接收/处理/完成；不点击打开MemoMark。


完整单张重跑 `/tmp/MemoMarkShareRestoreSinglePhysical4_20261011.xcresult`：1 passed /0 failed。设备iPhone17ProMax/iOS27.2Beta，signedRelease build17；新增输出、原始captureDate、配置描述及ImageIO解码读回、全部本地原始资源SHA和内容身份一致、Share后无主程序前台、临时配置恢复均通过。目录modificationDate继续留存在证据中。此结果才是单张验收PASS，前一FAIL记录不改写。


### 五张真实静态内容与重复意图异常

签名Release build18，第一请求 `441A715F-C729-4C8C-98C5-C6C94BE1DC05`：本地输入相簿静态分类5张（原资源JPEG/HEIC，Photos Share实际提供public.jpeg），输出相簿基线6→11，progress依次0/5→1/5→2/5→3/5→4/5→5/5，notification saved=5、phases全部completed。新增asset、captureDate、每张描述/解码、原始资源SHA/内容身份、无host前台检查通过。不能将provider转为JPEG的这一测试说成原始HEIC格式导出验收。

同一已保存配置的重复请求 `19706F17-E3AF-492E-A40B-B26E779CDB2A`：完成后输出11→12，出现1个额外asset。重复意图门槛FAIL；不清输出、不改期望数量、不取消去重断言。源码processing identity在无可信PhotoKit sourceIdentifier时基于provider文件SHA；当前均hasSourceIdentifier=false。provider再次提供的JPEG是否字节变化仍需比较身份摘要，不能仅按照片日期猜测或降低身份契约。后续验收若新增超过期望立即失败结束，避免浪费四分钟轮询。

屏幕录制CLI明确返回设备不支持Screen Recording capability；改用原始截图与XCTest自带录像。Home顶部实际显示Photos任务气泡，麦克风活动同时占据主岛。一次坐标长按未可靠捕获展开状态，因此不宣称完成文案/三态已人工验收。


展开截图复核修正：导出附件后，`ordinary-share-expanded-system-surface` 的第一批截图确实记录两条系统任务：上方历史「时光记正在处理照片 / 任务失败」，下方当前「39% · 已完成1/5张 · 正在保存到Apple Photos」；同步AX在相邻瞬间记录36%/正在生成图片→39%/保存。此前依据稍后的收起Home截图判断未捕获展开状态不成立，现以该原始截图为准。旧失败系统记录与新任务同屏造成反馈歧义；新任务实时处理中反馈已证实，完成文案仍需独立截图。该原生系统UI归属Photos扩展宿主，不能声称已显示MemoMark自有图标或清除旧系统失败记录。

重复额外输出已定位为HEIC静态分类输入（sourceDate `2026-10-02T06:12:36Z`），新增 `84B71BCF-76EB-4FB8-B109-A8C95E0A02D5/L0/001`，3214×6246。第一批5张读回全部通过，但整轮含重复验证仍为FAIL：`/tmp/MemoMarkShareRestoreStaticPhysical1_20261011.xcresult`。已保存用户原始配置，未删除任何输出。


最终候选build19 signedRelease重建/严格签名/覆盖安装通过；仅移除生产JPEG分支之后不可达的DEBUG旧实验调用，及QA超额输出立即失败逻辑。Release处理行为与已通过的单张/五张首批一致。工作树差异与governance校验通过。补充精确设备读取边界：CoreDevice拒绝BatchQueue/jobs-v1.json，明确原因是根目录路径不在Library/Documents/tmp允许读取目录，非文件不存在或队列清空；未为诊断移动持久队列路径。


### 用户明确最终输出边界及每轮清理（16:47）

用户拒绝降低最终输出，尺寸、格式及各类素材规范保持当前契约；仅允许实际所需的中间处理优化。此前4096输出讨论未实施，内部2048预览已通过，暂无证据要求继续降低。测试使用Photos→精选集→顶部固定：最左MemoMark QA Inputs，旁边MemoMark QA Outputs；真实当前截图和PhotoKit核对，输入ID `3E434601-A1D5-45DB-8B31-CE7CAF57976D/L0/040` 15张，输出ID `BE0EF089-3CAD-4E16-82E4-6973F1140F01/L0/040` 当前2张，资源ID无交集。用户直接授权每轮证据保存后删除输出测试图片，确认0再下一轮；该授权取代此前本会话保留输出的测试约束。不得删除输入、非测试照片、清空队列或配置。下一轮使用固定15张输入的Live/RAW+JPEG/静态内容，不继续搜索临时本地相簿。


### 固定15输入首项Live阻塞定位与中间资源修复决定（实施前）

输出清理1已PASS，固定输入15张从输出0开始。请求 `B80654C6-8028-4DBB-8F67-C6E65A6351C3` 全部admitted；首项 `3FE21614-4DA8-4746-9AC5-B2AAD6C3A834` 为可信sourceIdentifier的Live Photo（PhotoKit ID `396F62DA-6F58-4AC1-9C44-2BF91FD18B03/L0/001`），读取原有HEIC/MOV与编辑资源，preview2048解码通过、render.healthCheck.passed，然后系统任务失败；后续未推进，新增0。不是此前本地复制Live的身份歧义，也不是JPEG静态成功。

Engineering Loop/P1，LivePhotoStillImageCompositionService/LivePhotoStillImageWriting资源owner：现有DEBUG Share使用已有mapped raster配方，Release仍准备完整source CGImage与完整canvas。提取现有测试覆盖的责任命名软件Live still helper用于共享扩展生产，消费同一个canonical geometry/artifact，原有JPEG/HEIC outputType及writer保持、同一配对ID/MOV/still-time/视频尺寸/质量不变；不关闭Live、不输出静态替代、不缩结果。先加入Release Overlay/Still/Video边界与可用内存诊断，重跑才能确定退出精确位置。影片合成的GPU/资源约束另据实际结果处理，不凭假设修改。对应共用JPEG/HEIC完整尺寸/配对/中文Metadata/scratch/original测试及signedRelease真机证据分别验证。

每轮清理QA加入原件ID无交集拒绝保护、输入内容身份前后比较、输出0确认；相簿名称有多个匹配时拒绝任选首项。重复分享属于同一受控验收轮，第一批读回后才重复；轮结束保存证据后清输出再下一轮。


软件Live still extraction focused已PASS：29测试定义/39次执行/0失败，`/tmp/MemoMarkLiveSoftwareFocused2_20261011.xcresult`，包含JPEG/HEIC完整尺寸、配对ID、原文件字节和scratch清理。首次测试使用错误scheme MemoMark（没有test action）未执行测试，已改用仓库MemoMarkTests并通过，不记录为源码测试失败。全量回归与signedRelease候选重建进行中。固定15全量旧候选轮保存失败证据后，下一轮先清输出，再只测固定输入首张Live，定位静态帧/视频/存储边界，成功才扩大混合批次。


最新全量 `/tmp/MemoMarkLiveSoftwareFull20261011.xcresult`：2109测试定义通过、2179次通过执行、1既有skip、0失败，2既有FixtureExportReadback QoS warnings。formal signedRelease build20/21、strict codesign、覆盖安装通过。清理2新QA保护流程PASS，输入15内容身份不变、输出0；单Live物理验收已开始。未修改输出格式/尺寸或视频渲染路径，只让共享扩展Live静态帧采用共用mapped raster实现。


### 固定输入单张 Live Photo 真机闭环（17:00）

`/tmp/MemoMarkPinnedLivePhysical1_20261011.xcresult` 为1 passed/0 failed。signed Release build21，固定输入首张 Live Photo，请求 `78BD2D9B-4F2D-44BF-8DC6-69896634A07E`：2048内部预览、canonical overlay、mapped still strips、现有视频合成、PhotoKit保存读回全部完成；runtime 3.906s，saved=1、processed=true、progress100。Share关闭后到新增输出与资源读回结束，主App不前台；之后仅为恢复原有描述配置打开主App。

新asset `4DEB7B0F-9BE9-48B2-9952-ECFD2AC73502/L0/001`，2268×4410（原样式白边）、原captureDate保留，HEIC与MOV完整；still/MOV配对ID相等，3.0s视频内1个still marker（1.4666666666666666s），正视频轨道与尺寸。物理读回验证marker有效且唯一，尚未直接比较原视频marker时间，不扩张为逐项原源时序验收。原配置已恢复，输入内容身份不变。

展开原生系统截图 `pinned-live1-attachments/9E40CCDD-4050-4A35-92EC-5F2DC9B58504.png` 实际显示当前「时光记照片处理完成 / 本轮照片处理已完成。」及勾号；同屏旧失败卡仍在上方，必须分别归属。不是MemoMark自有LiveActivity独立运行证明，不声称已清旧OS任务卡。设备仍为iOS27.2Beta。

附件已导出留存在/tmp，cleanup3 (`/tmp/MemoMarkPinnedOutputsCleanup3_20261011.xcresult`) PASS，仅删本轮QA输出，输出0、输入15内容身份不变。下一轮 `MemoMarkPinnedAllPhysical2_20261011` 从该零基线开始，固定15输入第一批成功读回后才执行相同冻结配置的重复分享；Photos提供的14静态输入为JPEG representation，不能据此宣称原始RAW解码或RAW输出已物理验收。


固定15首批请求 `E6728805-33D0-42A0-9B9D-9D9002791B75` 已全部完成后台save，PhotoKit输出0→15，全部still元数据/解码、Live配对、输入内容身份及无host前台检查通过。直接截图可见46%/6 of15/saving，独立检查9张，然后15张。整轮physical2仍FAIL：重复动作Photos「选择」AX tap进入one-up，后续「全选」不可用，第二次Share未提交。保存该失败与15张输出读回；QA新增one-up优先返回、按真实选择按钮frame操作、必须确认选择模式后才能选素材的防护。仅改QA导航，不改变生产输出或去重契约；下一轮清输出0再完整重跑。


### 用户指出最终Renderer空白：立即撤销内容合格判断（实施前）

用户指出照片正常但文字/模块/标识区域空白；已查看physical2实际保存的ImageIO解码附件，静态JPEG新增footer确为空白，不能将15张保存/尺寸/metadata PASS描述为最终输出合格。Live缩略图可见内容，仍需逐资源核对；此前元数据/可解码测试没有覆盖实际可见内容，是验收缺口。当前physical3受控轮已启动，不再扩大/清输出，保留新图用于内容定位。

Engineering Loop/P1：owner为canonical PresentationArtifact图层生成与软件合成输入，在既有布局/文案/格式/尺寸不变条件下，分别检查非空Card内容、footer layer raster和最终output pixels。先增加有可见文本/标识的经典白边回归，要求artifact本身和导出footer都含前景，并比较预期region；再依据失败点修复。补真机保存图footer内容检查与可见截图，拒绝把空白结果记作内容成功。不得用改变字号、版式、关闭模块、缩小最终输出或仅写EXIF来通过验收。


Mac可见内容focused为26定义/36执行PASS (`MemoMarkClassicForegroundFocused1_20261011`)，同一经典footer artifact与最终保存footer均实际显示文字及Apple标识；单个Swift Testing方法过滤第一次没有执行测试，不记PASS。physical3 (`MemoMarkPinnedAllPhysical3_20261011`) 原有gate 1PASS，15张保存+重复输出无新增，但用户指出空白缺陷后不能用于最终内容成功结论。新增QA仅读回现有15张、按原始captureDate唯一配对及源高度定位新增footer、2048px检测缩略图和footer证据、不修改保存资源；要求深色不透明前景存在，同时保存footer截图。输出保留直到该缺陷定位及附件备份。


`MemoMarkPinnedContentRed20261011` 真实设备只读检查FAIL：首张Live footer包含完整当前文字/标识，第一张static输出 `BA87C7AA-C01F-402B-B7CF-18C00B426BF9/L0/001` footer前景0。保留两个footer PNG、15资产目录及physical3全部附件后，cleanup5仅清指定QA Outputs并保留Inputs不变。下一诊断只分享固定输入首张静态素材，Release记录canonical layer尺寸与256px有界抽样前景计数，分离图层生成和最终合成，不记录私人文本/照片像素到持久日志。


### 像素交接定位及修复决定（实施前）

单static诊断 `MemoMarkPinnedStaticLayerDiagnostic20261011` 1PASS；请求 `E9E2562B-FA9F-4313-8389-7A0A5AC50738` 原有SwiftUI footer 4032×512，CoreGraphics抽样darkPixels421，实际保存footer内容也通过。与没有抽样绘制的真实空白失败相比，图层本身有内容，CoreGraphics实际消费图层后软件CI输出恢复。证据支持deferred SwiftUI CGImage→softwareCI像素交接问题，不再声称SwiftUI在后台无法产生内容。

P1有界修复：PresentationArtifact注册点中Share扩展的SwiftUI图层（Classic/Minimal/Glass）先在同尺寸CoreGraphics bitmap完成显式像素拷贝，交给原有softwareCI recipe；CoreText FilmMark已为位图不重复拷贝。主App路径保持；原sourceURL/照片像素/布局/图层frame/z/opacity/格式/metadata/pair/video不改。暂时抽样诊断必须移除，避免依赖偶然预热。新增像素拷贝颜色/alpha/文字前景回归，随后签名Release无诊断重新验证单static及15张真实输出footer可见。

额外发现旧重复验收只在30s观察到数量相等即PASS，不能证明重复任务已终止；后续读取系统presentation completion/本请求terminal状态，且不能在仍有处理任务时删除下一轮输出或覆盖安装。physical3旧gate PASS不等于去重终态通过，保持此门槛开放。


实现完成责任命名SoftwarePresentationLayerRasterizer：只对Share的三个SwiftUI layer完整原尺寸绘制到sRGB RGBA bitmap，不拷贝照片或CoreText FilmMark整图，不再保留抽样诊断。Mac稳定图层focused 26定义/36执行PASS，footer字形/标识所在行与原图层一致、完整输出footer可见。补2×2颜色/半透明/透明精确像素测试；全量及signedRelease build25运行。QA重复观察至少4×30秒，期间额外输出立即FAIL；最终仍需外部diagnostic确认本请求terminal，不能用120秒稳定数量替代system terminal。


稳定图层最终全量 `MemoMarkStableLayerFull20261011` 为2110定义/2180执行PASS、1既有skip、0失败，包含颜色/透明精确像素交接及经典footer字形位置/保存前景检查。formal Xcode27 signedRelease build25及strict codesign通过。无临时layerContent抽样，单静态与整批的真机内容门槛仍必须通过后再结论。


无临时抽样的生产候选build25，`MemoMarkPinnedStaticStableLayer20261011` 真机单static 1PASS：请求 `FEEA6FF8-1D15-41FF-B0D9-C63ED04A06E1`，4032×2780 JPEG，新增 `23B59A8A-915C-40EA-895A-B490EF0261EC/L0/001`，完整footer文字/标识已独立读回，元数据/解码/原件内容身份/Share后host不前台及配置恢复均通过。footer附件 `static-stable-layer-attachments/15A86D08-4CE0-4EC4-80F4-337AE822E886.png`，所有源尺寸未降低。此结果才证明显式bitmap交接能独立修复单静态空白；整批与延迟重复终态仍待新轮。


稳定图层整批首轮请求 `3C848A8A-B613-4FD2-A0A1-9D754210BDD7`，冻结revision91：15/15实存，所有任务completed、processed=true，原生progress1500/1500；从Share关闭至输出/全部footer/配对/metadata/源身份读回无host前台。QA逐张新增footer内容检查15项均通过后才重复，避免继续把白条空白算合格。重复请求 `06061943-2842-4DF5-B7A4-574D28374A76` 目前仍在后台处理中，30/60秒输出15不增尚不能闭合；等本请求terminal再收口，期间不清输出不覆盖安装。


### 整批截图复核推翻像素门槛：黑底假阳性（修复前）

`MemoMarkPinnedAllStableLayer20261011` XCTest 1 PASS，首批及重复请求均15项completed，重复输出ID不变；但实际逐张footer PNG中Live正常、14静态区域为黑色/近黑色。旧darkPixel>0门槛把黑底当作文字，不能证明内容；撤销本轮最终内容PASS，保留全部15输出及附件、不清输出直到修复前证据与新门槛确立。单static成功不能外推批次。

Engineering Loop/P1：继续在canonical PresentationArtifact像素owner内，评估ImageRenderer.render向显式CPU CGContext直接绘制，避免cgImage的图形后端/延迟表示；读取SDK真实API，不更改布局、文字、最终尺寸/格式/metadata/Live视频。经典白边物理门槛同时要求大部分像素为浅色底及存在深色文字/标识，拒绝纯白与黑底两类失败。先保留并只读重验现有输出得到RED，再新候选清输出并整批Share复核；完成任务/去重终态与最终可见内容分别记录。


直接CPU位图候选：依据正式SDK `ImageRenderer.render(rasterizationScale:renderer:)` 与Apple文档，使用同一个View/proposedSize/scale向sRGB RGBA CGContext（bottom-left原点）直接绘制，扩展路径不先读cgImage；主App路径保持。focused1的严格逐行阈值比较在1px抗锯齿边缘差异失败，未调整坐标，测试改为占据范围±1px抗锯齿容差并保留前景/浅底/尺寸检查；focused2 28定义全部通过，包含3尺寸×3次连续绘制及完整JPEG写回。正式signed Release build26/strict codesign通过；新浅底物理门槛只读重验旧输出后再清本轮输出，不清队列。


浅底修正门槛只读旧输出 `MemoMarkPinnedContentBlackRed20261011` 真实FAIL（第一静态浅色背景像素0），证据导出`pinned-content-black-red`，不是工具未执行。cleanup8通过，仅清指定Outputs，Inputs15身份不变/Outputs0。direct CPU候选最新full `MemoMarkDirectLayerFull20261011` 2111定义/2181执行通过、1既有skip、0失败。`MemoMarkPinnedAllDirectLayer20261011` 从0基线运行中；不得因runtime completed或Mac通过提前描述最终15图内容合格。


### 直接CPU图层整批实际内容与重复终态闭环（17:51）

正式签名Release build26，`/tmp/MemoMarkPinnedAllDirectLayer20261011.xcresult`：1passed/0failed。首批请求 `D9400038-7434-47C0-9485-CC3B3C409515` 15项completed/processed=true，重复 `BD93C042-63D3-4C15-BD2A-611168B77E11` 同样15completed/processed=true、stop/cancelled/paused=false，独立共享prefs终态在恢复主App前已获取；重复output asset ID集合完全相同。不是仅120秒数量稳定即成功。

保存资源读回15项，按原始拍摄日期唯一匹配源、原宽保持且白条高度来自既有几何：2160×4200、2268×4410、3888×7558、4032×2780、4536×8818、8064×5558。Live原件2268×4032加经典条后2268×4410，HEIC/MOV配对ID一致、视频3s/正轨道、唯一still marker1.4666666667s。14静态为Photos提供的JPEG表示，不扩大为原始RAW直接解码认证。来源内容身份/资源目录未变；优化/iCloud源本轮未全量SHA。

15份实际保存footer PNG全部逐张人工查看：中文标题、日期、地点、时间结果、Apple标识与QA唯一描述可见，无白条空白或黑底。独立导出PNG统计浅底93.2%–94.4%、深色前景5.1%–6.0%，修正浅底+前景门槛通过；检测缩略图用于证据，不改变最终保存像素。附件`/tmp/MemoMarkShareRestore20261011/all-direct-layer-attachments`，如静态first `44F868A3-A71C-4659-A360-8B22EF8AF7AE.png`、Live `7A9B64EA-C13C-416C-97E3-A18EE5F80154.png`。原生展开截图确实显示13%准备照片及15%已完成2/15读取原图，旧失败卡另在上方，成功completed/processed=true由本请求日志独立确定。本轮没有最新顶部展开completion文字截图，不借旧截图冒充。

源码最终全量2111定义/2181执行/1skip/0fail、governance及diff检查；最终输出尺寸/格式/布局/文字语义、metadata、Live视频不改。扩展静态CPU直接绘制替代cgImage-copy，主程序沿用原路径。仅在本设备Beta/当前经典配置/可处理Photos表示/已有授权及暖后台范围关闭该门槛，稳定OS、cold/terminated/lock/压力/其他style等未认证。老local-five额外HEIC输出仍独立记录。每轮清理必须等待终态及证据保存；本轮cleanup9进行中。


收尾：cleanup9 (`/tmp/MemoMarkPinnedOutputsCleanup9_20261011.xcresult`) 1PASS，证据已导出后只删本轮15个QA Outputs；输入15内容身份前后相等，输出15→0。附件`cleanup9-attachments`独立目录保存前后。`MemoMarkSystemResidueDismiss20261011` 1PASS，Photos保持前台/主App未前台，通过通知中心仅左滑清除时光记旧“正在处理照片/任务失败”卡，前后PNG确认旧卡消失，其他App通知保留。通知中心另一个MemoMark自有ActivityKit卡显示17:32历史会话完成/77队列，不是本轮17:45新任务UI证据；不得拿它充当最新完成显示。原生新任务进度、后台终态与15实际内容闭环已通过；本轮最新完成banner逐字/时序持久性仍未截图独立验收。最终差异与governance通过，无进一步源码改动，未commit/push/Store/上传。


### 历史终态ActivityKit重建误导修正（实施前）

Engineering Loop/P1，观察通知中心17:32旧完成记录：LiveActivityDriver.updateAndEndActivity在没有tracked activity的terminal payload上调用requestActivity，主App后续启动因此会把历史记录当成新的活动卡。owner仅iOS ActivityKit driver，状态/队列/processing/durable history不改；BGContinuedProcessing继续权威展示实际Share进度，已有Activity更新及最终end保留。改为untracked terminal取消待重试并记为已应用，不创建活动；requestActivity加终态防护覆盖延迟retry，避免竞态在任务完成后再创建。不修改历史记录/已存照片/Widget布局，不引入APNs或新后台执行路径。验证已有bootstrap/retry/背景契约全量、signed物理启动/前后诊断无新terminal activity request，以及原生UI旧卡清理；当前15图闭环证据仍保留。


历史卡修正最终验证（17:59）：正式Xcode27 signedRelease build27/strict codesign通过并已通过真机test-without-building安装。`MemoMarkTerminalHistoryPhysical20261011` host启动1PASS，前后shared prefs独立核对：当前最新会话为重复请求BD93C042…，completed/progress100；出现reason=untrackedTerminal;activityNotCreated，期间liveActivity.request.created=0、app.drain=0。原历史状态未删除，已有活动的update/end保留，terminal delayed retry不能创建新活动。最新full `MemoMarkTerminalActivityFull20261011` 2111定义/2181执行/1既有skip/0fail。最后该改动仅main iOS driver；媒体整批与Share关闭后台全程证据为build26，不把host启动新检查冒充新整批。治理/diff通过，无外部发布、照片上传或Git同步。
