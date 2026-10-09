# MemoMark V5 验收准备与参考方案对照

核对日期：2026-10-09。参考：ChatGPT「MemoMark后台图片处理方案参考！」，会话 6ac63127-6a80-83ec-ad87-b4bf46b60598，已重新读取四轮记录。参考中的研究判断属于设计依据，不替代 SDK、实现与真机证据。

## 当前结论

可靠性主线与原方案一致：保持原素材、冻结配置、持久接收、跨 Share 身份、连续会话、独占执行权、PhotoKit 回执与读回。当前处于生产验收准备阶段，尚未达到 V5 发布条件。

关键架构差别：原方案提出 extension 提交后由 host 后台 handler 接管；隔离实机测试尚未证明此路线。已成功的是 iOS 27.2 Beta 上 DEBUG opt-in 的扩展拥有 Continued Processing 执行机会、复用处理流水线。它不是普通 Share 生命周期内硬撑处理，也不证明 host 能冷启动。必须先明确生产采用哪一条已验证且受支持的执行路径，再晋升 Release。

## 对照矩阵

| 原方案目标 | 已有证据 | 尚缺的验收 |
|---|---|---|
| PhotoLibraryCapability | 模型与专项测试；目标相册能力边界改造 | Full→Limited/撤销/Add-only 的真机任务恢复，不得静默改存储位置 |
| 全局 ProcessingIdentity | 两 Share 12 次选择最终 7 输出；同会话 8 次选择最终 7 输出 | 同照片不同有效配置再次处理；无实际配置变化的 revision 语义；版本化兼容旧回执 |
| ExecutionSession | 9 张处理中追加重复 1 张＋新素材 2 张；同 session，最终 11 输出 | 入队前取消、硬失败后的整会话收敛 |
| 单一执行 owner | 独立 App Group 记录显示租约串行 | foreground/BGProcessing/continued 交叉争用、进程被系统终止后的重新获取 |
| durable intake/ledger/receipt | 保留；完整自动测试与多个专项测试 | 入队前/等待租约时取消；磁盘不足、写盘失败、跨版本迁移失败关闭 |
| 系统后台处理 | 扩展拥有执行机会，Photos 前台期间真实输出 | host 接管路线未通过；稳定 iOS 26；Release 生产执行路径 |
| 系统与自定义 Live Activity 单一权威 | DEBUG 路线结束 fallback Activity；状态权威模型 | 多 Share 系统请求是否产生多个卡片；Release 全链路抑制 fallback |
| Session 级通知 | 已接收未 admission 时暂缓完成；重叠实机最终 saved=11；稳定通知标识 | 硬失败/部分失败提示、检查后新 Share 的时序边界 |
| 用户可控 | 7 张系统停止、原生暂停通知、重启保持暂停、明确恢复通过 | 用户取消与系统 expiration 无可靠分类信号，当前均保留为暂停；不得误称永久删除 |
| 删除历史 | 当前记录删除且重启不恢复；较早历史保留 | 正式生产候选包回归，不以“所有记录消失”作为删除当前记录标准 |
| Live Photo/EXIF/GlassCard | 静态元数据、Live Photo 分类、早期 MOV 配对读回、当前 CPU 行序测试 | 最终生产候选上的 MOV 配对、时长、方向、拍摄时间、目标相册；HDR/P3/RAW 不扩大承诺 |
| iOS 18–25 | 保留 BGProcessing 与前台恢复；暂停不反复调度可运行工作 | 老系统实机恢复回归；不承诺即时后台完成 |
| Watch/非灵动岛设备/区域语言 | 四语言暂停文案；原 ActivityKit fallback | Watch small family、非灵动岛实机、Focus/通知关闭、区域与语言组合 |
| 资源边界 | DEBUG 有界 CPU 条带；已有结束恢复证据 | 主执行 actor 长同步工作、峰值内存、锁屏/低电量/热状态、20 项压力 |

## 可复核证据

证据目录：`/Users/rui/Documents/Codex/2026-10-07/referenced-chatgpt-conversation-this-is-an/artifacts/MemoMarkV5Acceptance-20261009/`。

已从实际 xcresult 重新读取并保存十份汇总与 evidence-manifest.json；不是从日志尾部推断成功。记录 HEAD 5073d7257c9e6d722c345d1cf440430ab0044fec 和关键当前源文件 SHA256。工作区仍有大量未提交改动，HEAD 本身不代表被验证的全部代码；这些指纹也是部分绑定，不替代最终候选的完整版本标识。

- 最新完整自动测试：2057 通过、1 跳过、0 失败；既有两个 fixture QoS 警告保留。
- 重叠 Share：第二次提交早于第一次完成约 5 秒，两个请求同 session，租约不重叠，8 次选择只有 7 个保存结果。
- 7 张系统停止、原生暂停通知、明确恢复及清理：通过；原素材 7 张保留，输出清理至 0。
- 当前历史记录删除：通过，重启不恢复。
- Release 编译：通过，既有 backdrop actor-isolation 警告仍需归档。
- 最新可访问性容器调整晚于完整自动测试，已有签名编译及实机删除验证；最终候选仍需统一执行全套门槛。

较早 MOV 配对结果不能自动认证后续改过的全部媒体路径。Beta 与模拟器结果不能替代稳定版本或其他硬件的后台执行证据。

## 按依赖顺序的后续准备与验收

### A：冻结验收候选与执行路径（P0）

范围：处理路径决策与版本绑定；不启用新 UI 功能。

- [ ] 决定 host 接管继续作为待证明路线，或扩展执行作为独立生产候选；记录依据、资源上限和降级策略。
- [ ] 将实验状态、生产运行策略、观测事件分离，不能将 DEBUG 开关直接去掉当作生产接入。
- [ ] 候选安装包、源状态、签名/系统版本、测试参数唯一绑定；保留用户 dirty UI/research，采用明确文件范围。

验证：Release 实际安装路径审查、权限/后台标识检查；独立读取实际执行者与 marker/单 JPEG，之后再运行全流水线。未通过时禁止宣传“分享后主 App 自动后台接管”。

### B：补齐会话与幂等边界（P0，依赖 A 的决策，基础模型测试可先做）

- [ ] 将参考核心案例映射为源素材：Share A+B+C，未结束时 Share C+D+E；D/E 必须是新素材，最终恰好 A–E 五份。
- [ ] 补同源不同配置输出及相同配置重复 Share；若调整 identity 算法，采用新版本和旧回执兼容，不清回执、不原地改旧键。
- [ ] 覆盖等待 owner、尚未 admission 时的取消与恢复；部分失败不得显示整批成功。

验证：模型/跨实例事务测试 + 真机独立提交时间、session、租约、输出 assetID、最终通知计数；第二次提交不早于第一次完成的轮次只算顺序发送证据。

### C：生产结果与异常恢复（P0，依赖 A/B）

- [ ] 最终候选的 JPEG/HEIC/Live Photo 输出，验证尺寸、方向、拍摄时间、说明、相册、MOV/still 配对与原素材未改。
- [ ] full/limited/add-only/none、权限撤销、输出相册消失、磁盘不足、PhotoKit 提交后终止，恢复不得重复保存。
- [ ] 锁屏、系统 expiration、用户系统停止、前台暂停/取消/删除；已提交保存允许结算，取消不撤销已保存照片。

验证：每轮留存独立输出清单与回执证据，再清理指定生成结果。系统终止、用户 force quit、冷进程是不同用例，分开记。

### D：统一系统呈现与兼容矩阵（P0/P1，依赖 B/C）

- [ ] Continued active 时仅一个呈现权威；同时验系统请求卡片数量，不能仅凭自定义 Activity 已结束判通过。
- [ ] admission/drain 尚未收敛时不能过早发送最终成功；通知稳定标识的替换不等于“只发了一次最终通知”。
- [ ] 稳定 iOS 26、当前 Beta、iOS 18–25、非灵动岛、Watch；语言至少中/英/日/韩，另记区域、Focus、通知关闭状态。

验证：系统界面实际读回；不强制系统弹出、扩大权限或绕过 Focus。无可用设备的项保持待验，不用模拟器后台时序替代。

### E：最终发布门槛（依赖 A–D）

- [ ] 同一候选完整测试、正式工具链 Release 构建、diff 检查、升级迁移及失败恢复。
- [ ] 收敛已知警告与失败，列明影响；所有 P0 验收缺口关闭。
- [ ] 保持 iOS 18–25 的机会调度承诺；iOS 26+ 也不保证永不终止。
- [ ] 生产能力与对外文案逐条对应；构建成功、TestFlight、审核、上线是独立门槛。

## 每轮测试协议

1. 配置只读盘点、确认指定输出相册为空、原素材数量不变；记录 frozen 配置及输出语义，不覆盖用户配置。
2. 新输出轮使用独立测试意图；重复意图轮保留先前结果直至 readback。删除相册结果不是删除保存回执。
3. Share 完成后不主动启动 MemoMark；先独立观察执行者、输出、通知，再进入明确的前台恢复阶段。
4. 结束后先保存证据，再清理本轮生成结果并验证输出 0、原素材数量与配置保留。
5. 相册清理不等于“最近删除”永久清除；不扩大到其他照片或整个历史。设备解锁/测试启动误报不算业务处理失败。

当前可用真机为 iPhone 17 Pro Max / iOS 27.2 Beta。其他登记设备不可用；稳定系统、非灵动岛和 Watch 的运行验收保持未通过。素材已于本轮更新为 15 份；15 份整批验证已通过，仍不是 20 份独立源媒体的压力验收。

## 2026-10-09：15 份素材实机补验

- 独立基线：Inputs 15、Outputs 0。整批 Share 后不激活主 App，15/15 完成；独立执行记录约 34.36 秒。XCTest 最终结果 1 通过、0 失败。
- 15 份输出与原素材拍摄时间、像素尺寸多重集合一致；说明与 Live Photo still/MOV 配对检查通过，原素材 15 份保留，结束清理 Outputs 0。RAW 来源使用可获得的图像表示；不宣称 DNG/HDR/P3 保真。
- ABC/CDE 和 7+3 轮分别得到 5、9 个独立输出，但第二次提交晚于第一批结束，仅为顺序去重证据。
- 9+3 轮：重复第 3 份，新增第 10/11 份，最终 11 个输出。第二次提交早于第一批完成约 1.87 秒；同一 session，租约顺序接管。实机测试 1 通过、0 失败，输出清理 0。
- 该重叠轮发现 P1：第一 owner 在第二 Share 已持久接收但尚未 admission 时提前发送 saved=9 的最终通知；之后替换为 saved=11。已增加 pending intake 检查；读取失败也暂缓成功。针对性测试最终结果 8 个逻辑测试通过、0 失败（参数化运行共 14 次）。新包实机复测进行中，尚不记为关闭。
- 当前证据仍限定 DEBUG opt-in、extension-owned、主 App 已初始化后转入后台、iOS 27.2 Beta。稳定 iOS 26 / 冷启动 host handoff / Release 接入 / 单一系统卡片仍待验。

### 完成通知修正复测结果

新包 `MemoMarkFinalSummaryOverlapRound.xcresult` 最终 1 通过、0 失败。独立记录：第二 Share 提交早于第一批完成约 15.59 秒，两请求共用 session；第一租约释放后第二才获得执行权。第一 owner `completionDeferred: pendingIntakes=1`，没有 notificationScheduled；第二 owner 最终只记录 saved=11。11 个输出拍摄时间与尺寸对应前 11 个源素材，Live Photo 配对与说明通过，Inputs 15 / 清理后 Outputs 0。

P1 的“已持久接收而未 admission 时提前完成”在本轮已修正并实机通过；不承诺对检查之后新提交的未来 Share 做原子预测，也不等于两条系统 Continued 请求卡片已合并。

最新完整测试：2,057 个逻辑测试通过、1 跳过、0 失败；参数化执行 2,120 次通过。两条既有 fixture QoS 警告保留。正式 Xcode 27.0 Release 构建退出 0，既有 NativeBackdrop actor isolation 编译警告仍在；`git diff --check` 通过。Release 编译成功不等于该 DEBUG 扩展路径已进入生产。

本轮机器可读证据保存在任务 artifacts/MemoMarkV5Acceptance-20261009；包含测试最终摘要、独立执行记录与匿名计数/尺寸核对。私有照片及界面附件仅留本机临时测试包。下阶段保持 A–E 门槛：生产路径决策、取消 admission 前边界、权限变化、版本迁移、稳定系统与单一系统呈现。

## 整体完成度盘点与当前推进顺序

不使用单一百分比混合“实现”和“生产认证”。

| 层级 | 当前完成 | 未关闭项 |
|---|---|---|
| 核心可靠性实现 | 权限能力模型、版本化身份、会话、执行租约、并发账本、保存回执与额度核算 | 身份版本升级策略、revision 无语义变化、admission 前取消 |
| 当前 Beta 实机执行 | 15 张整批、实际重叠追加新素材、重复去重、说明/尺寸/日期、Live 配对、已入队暂停恢复删除 | 等待租约中断、锁屏/权限变更/跨 owner 故障 |
| 用户状态呈现 | 单一 fallback 权威模型、原生暂停通知、最终通知延迟修正 | 多系统请求卡片收敛、失败/部分失败、非灵动岛/Watch/Focus 矩阵 |
| 发布准入 | 最新完整测试、稳定工具链 Release 编译、差异检查 | Release 路径决策与接入、稳定 iOS 26/旧系统实机、完整候选绑定及升级迁移 |

下一薄片仅增加 `testContinuedSameSourcesWithDifferentFrozenDescription`：同源同配置重发仍 3 输出；只改 frozen 输出说明再发送允许 6 输出，分别读回说明与配对，不改用户已保存配置。风险 P1，所有生成输出本地且保持原素材；PhotoKit 原生资源读回作为验收事实来源。

取消检查发现：ShareContinuedProductionWorker 的等待租约循环在 admission 前响应 Task cancellation，尚无 BatchJob/session 可被 suspend；请求保留在 intake store，host 后续 drain 仍可能接收。当前不得称“等待租约时系统停止后持续暂停已覆盖”。后续必须用持久接收状态表达 hold 并被 extension/host 两端读取；不可简单 acknowledge/删除接收请求，否则丢失输入，也不可在被取消任务中强行 admission。此项维持 P0 未关闭。

### 同源不同冻结配置：实机通过

`MemoMarkDifferentConfigRound.xcresult` 最终 1 通过、0 失败。前三个源（含 Live Photo）相同配置首次 3 输出、重发仍同三个 PhotoKit assetID；只修改 frozen 照片说明后总计 6 个输出，两组说明分别读回，新增组 Live Photo 配对通过。六个输出的拍摄时间与像素尺寸对应三源各两份，Inputs 15 / 清理 Outputs 0。独立记录三个扩展后台 owner 均完成，每次 Share 处理期间未主动激活主 App；配置修改发生在两轮之间的明确前台设置阶段。未修改用户持久配置。

本项证明有实际输出语义变化时合法再处理；不认证任意 style/outputMode 切换、无语义 revision 变化或 identity 算法升级。本轮仅新增测试与更新验收记录，生产源文件未改，先前完整 2057 测试为生产代码当前基线；新 UI 测试已签名构建并实机通过，diff 检查通过。

## 后续取消可靠性薄片：身份编译取消

范围 P1：BatchProcessingIdentityCompiler 是 extension/host 共同使用的身份编译入口；使用 Swift Task 原生取消检查，不新增并行身份真相，不改 receiptKey/schema。取消应在开始编译、逐项读取源版本及发布 prepared job 前被观察。回归用已取消 Task 验证不得返回成功；先前 RED `MemoMarkCancelledIdentityRed.xcresult` 在 cancelledPreparation 真实失败，GREEN `MemoMarkCancelledIdentityGreen.xcresult` 12 项通过。

注意：这是编译阶段协作取消边界，不关闭持久 intake hold，也不提供跨 actor admission 的原子取消保证。入队前 hold 的下一实现必须：

1. ExternalPhotoIntakeRequest 可选持久 executionSuspendedAt，旧请求缺字段默认未暂停；只在既有 intake 文件事务锁内更新，不另造无锁 defaults 标记。
2. 扩展在等待租约/身份编译取消后保留请求及 managed 源；区分尚未 admission 与已 admission 的账本事实，失败关闭，不 acknowledge 丢输入。
3. host 和 extension admission 共同消费 hold 并在同次 durable admission 写入 BatchJob.executionSuspendedAt；不能先入队再暂停，否则 auto-run 窗口会执行。
4. 复用 Home 明确恢复/取消/删除与 receipt reconcile；给 held job 独立 session，避免暂停其他已接收任务。
5. 验证取消与 admission 争用、两实例更新、旧 schema 解码、写盘失败、host 重启不自动输出，再实机停止等待 owner 的第二 Share。

Release 后台入口仍保留旧安全路径；当前 DEBUG 扩展实验不晋升生产。完整 hold 实现及稳定系统验证依然是发布阻塞。

取消编译修正最终回归：`MemoMarkCancelledIdentityFull.xcresult` 2,058 个逻辑测试通过、1 跳过、0 失败（参数化执行 2,121 次通过）。正式 Xcode Release 编译退出 0，差异检查通过；既有 fixture QoS 和 backdrop actor 警告未因本片而关闭。该生产源变更尚未重新签名安装做完整真机整批回归，先前 15 张及不同配置实机证据不能自动升级为本片最终候选实机证据。

## 入队前暂停实施候选（验收未关闭）

已实施：ExternalPhotoIntakeRequest 增加可选 executionSuspendedAt；ExternalIntakeRequestStore 在既有文件事务锁内持久更新，读坏数据拒绝写入，保留素材与冻结配置。host admission 在事务前读 hold、actor 入队后再读 hold，在自动执行前落入现有 durable session pause。预暂停 candidate 分配独立 session；扩展 admission 后也再次检查，运行循环观察账本 hold。系统 cancellation catch 将未入队请求保留为 held，若已存在 job 则使用原有暂停事务。旧 JSON 缺字段仍正常解码，未修改 processing-intent-v1 或 save receipt。

关联漏洞已实测复现：主 App 身份编译 CancellationError 曾进入旧素材兼容分支并继续入队；现在直接返回 nil。`MemoMarkCancelledAdmissionRed.xcresult` 方法过滤实际运行 0 项，不能算证据；改用整个 suite 的 `MemoMarkCancelledAdmissionRedSuite.xcresult` cancelledAdmissionDoesNotUseLegacyFallback 失败，随后 core green 已通过。

新增测试：接收 hold 持久化与旧 schema、host 入队持久暂停/重建、held admission 不影响无关 active session。完整测试、新包十五份后台回归、Release 构建进行中。不得因实现已存在就关闭等待 owner 系统取消实机、强制终止瞬间 race 或 Release 生产接入门槛。

残余边界：intake 与 BatchQueue 是两个持久存储；以先写 intake hold、再对已入队 job 设置 hold及入队两侧重读来交接，并非跨两个文件的原子事务。需补终止/竞态注入证据，尤其事务间 kill；不承诺零在途 PhotoKit 保存或对系统终止原因作永久取消分类。

入队前 hold 候选回归完成：最新完整测试 2,062 通过、1 跳过、0 失败（参数化 2,125 次通过）；签名 device build 成功。`MemoMarkIntakeHoldFifteenRound.xcresult` 新包 1 通过、0 失败，独立 extension owner 15/15、1500/1500，约 40.47 秒；未主动激活主 App，尺寸/日期对应 15 原素材、说明及 Live MOV 配对通过、原素材 15 / 输出清理 0。Release 最终退出 0；构建中有一次 SwiftCompile “exit code 0 but produced no further output” 诊断及既有 actor 警告，最终成功不代表这些诊断已关闭。差异检查通过。

候选已完成代码/模型回归和正常路径实机回归，但等待租约第二请求的系统停止、跨文件交接 kill 注入仍 NOT VERIFIED。尚未达到 Release 扩展路径上线门槛，不提交/推送、不清理用户 dirty UI/research。

## 新包停止、重启与恢复专项

`MemoMarkFifteenSystemStopRound` 实机通过：15 张 Share 的已入队 owner 原生停止、输出停止增加，主 App 打开和重启保持暂停；独立租约释放/中断/暂停事件一致。`MemoMarkFifteenExplicitResumeRound` 首次 CoreDevice 主 App launch PID 无法确认，失败在启动、未执行业务恢复；重试 `MemoMarkFifteenExplicitResumeRetry` 通过，明确继续补齐 15 份、原素材 15、输出清理 0，两条设备 QoS 警告保留。新增 intake 异常边界 suite 10 项通过：坏数据不覆写、重复 hold 保留初始日期及后续 Share。

### 等待 owner 停止专项：未通过，发现多系统任务风险

`MemoMarkWaitingStopRound` 先 Share 全 15，再 Share 重复前三张。等待卡片存在但取消按钮当时不可点击，XCTest 在 isHittable 断言失败。此轮未获得可靠用户取消证据，不认证等待 owner 停止。UI 测试之后独立继续观察：第一 owner 完成 15/15（约 136.53 秒，显著慢于上一单请求 40.47 秒），第二请求获得 owner 后发生系统 expiration，progressCancelled=false，最终 unfinished 并持久暂停。终止原因是记录到的系统 expiration；是否由进度停滞/资源压力触发未知。

第二请求创建了额外系统 Continued task 并等待租约，此调度方式有实际可靠性风险。不得给等待任务编造进度保活。后续优先做单一系统执行入口对连续 intake 的 drain，证明接收、交接、进度及最终通知一致；仍需跨进程登记/崩溃恢复，不可单靠无锁 defaults bool。

本轮未完成请求已通过 `MemoMarkWaitingStopCancelDelete` 的 Home 取消/删除、重启不恢复实机验证，较早历史保留。生成结果清理正在执行；无配置清空、无回执清除、无重装。待阶段 final summary 写入清理事实。

本阶段结算：`MemoMarkWaitingStopOutputCleanup` 实机最终 1 通过、0 失败，清理附件读回输出 0。failed 等待专项、已通过停止恢复专项、取消删除与清理均分别归档，不将失败隐藏或混入通过计数。第一 owner 开始 thermal=0 / lowPower=false；第二获得 owner 时 thermal=1 / lowPower=false，因此不能仅凭开始条件归因为严重热限制，也不确定等待请求造成速度变化的单一原因。

## 单一系统入口连续接收候选（2026-10-09）

根因边界：已确认每次 Share 创建独立 Continued task、然后竞争独占执行租约，后来的系统任务会无有效处理进度地等待。前一失败轮记录到 expiration，但其 OS 触发条件以及首批变慢原因仍未知，不能归因于确定的内存/热压力。

DEBUG extension production 实验改为既有 intake 文件事务锁下 reserve/append/drain；空队列观察与关闭原子化。请求记录 continuedExecutionSessionID，冻结配置与 ProcessingIdentity/save receipt 不变；未 admission 的 intake 计入真实总量。系统中断先在同一锁下持久暂停全部接受的 intake，随后关闭入口并暂停已入账 job；坏数据拒绝覆写。过期预约 180 秒、运行时每 5 秒续期，崩溃保留 intake。该候选未开启 Release 扩展执行，不构成稳定 iOS 26/旧系统生产保证。

专项证据：MemoMarkContinuationIntegratedUnits 21 逻辑测试通过（参数化 24 次）；MemoMarkAtomicContinuationHoldRed 因缺少 suspendRequestsAt 参数编译失败，Green 13 测试通过；MemoMarkLateSessionAdmissionRed 真实复现迟到 intake 重开取消/删除历史，Green 20 测试通过。修复让明确会话成员继承已取消/删除状态，不更改不确定 PhotoKit 保存证据。

### 用户交互收敛基线

用户最新指示强调小工具定位：分享、后台处理、必要时查看进度，异常时简单退出。产品目标为处理中「取消」，失败/中断「重试、删除任务」，完成简短提示。首页无需常驻暂停操作；系统暂停是内部恢复状态，不能误报为处理失败。取消不回滚已保存照片；删除任务不删除原图/已输出照片，且不得自动复活。此段为交互基线，当前源码界面尚待按行为验证结果收敛，不宣称已经完成 UI 改造。

单一入口实机完成：`MemoMarkCoalescedElevenRound.xcresult` 1 通过、0 失败。首 Share 九张，运行中第二 Share 一张重复+两张新素材；独立 CoreDevice 证据确认 nativeSystemTaskCount=1/coalescedRequestCount=1，第二请求接收早于第一请求结束，同会话、执行租约串行。账本任务最终 12/12，通知确认 11 个不同保存结果。测试完成 capture-date/静态 metadata/Live Photo pairing 读回，原素材 15 张，最终输出清理读回 0。安全摘要已归档 `coalesced-eleven-independent.json`，照片截图与 MOV 仅临时 xcresult。

产品方向再次收敛：用户明确不需要主动暂停和重试，希望失败短提示、重新分享。首页现已移除主动暂停与新试作 retry 按钮，内部持久 hold 不删除。异常暂保留既有任务删除入口，待“中断后重新分享”实际验证通过后再收敛。不允许在后台恢复未证实前只靠文案要求重发。`testContinuedStopThenResendWithoutHostActivation` 已新增、签名构建通过但尚未执行：要求先有真实部分保存，再原生停止，连续两次输出读回稳定；同冻结配置重新 Share 全 15，最终 15、原已保存 identifiers 保留、metadata/Live Photo/originals 校验后清理。不打开 host 恢复是必需条件。

设备离线前源码基线完整自动测试 `MemoMarkSimpleCancelHomeFull` 为 2069 通过/1 跳过/0 失败，fixture 两条 QoS runtime warning 仍存在。此后修正正式 Xcode 的纯函数 actor 隔离声明（MemoMarkAlbumSelection 和 artifact guard 私有计算方法）；最终完整测试/正式构建重新执行，尚待结算。已签名测试构建不构成真机重发 gate 通过。设备暂离线，未启动该重发测试；下午联机才继续。

## 离线发布前整理结算

最终源码 `MemoMarkOfflineReleaseReadinessFull.xcresult` 全套测试通过；正式 Xcode `MemoMarkSimpleHomeStableRelease.log` Release 构建退出 0，无 warning/error 匹配。相册纯值类型与图像检测私有纯函数的 actor 隔离警告已关闭。Beta `MemoMarkOfflineFinalDeviceBuild.log` generic iOS 签名 build-for-testing 退出 0，无 warning/error 匹配；diff 检查通过。不推送、不上传、不安装、不清空用户配置。测试 fixture 历史 QoS runtime warning 与跳过项以最终 xcresult 原样保留。

下午联机优先执行：
1. `testHomeActivityCancelWithAllFifteenQAInputs`：15 素材、无暂停/重试控件，Home 取消真实生效；读取原素材并清理本轮结果。
2. 确认测试输出相册为空，再 `testContinuedStopThenResendWithoutHostActivation`，与独立只读 CoreDevice mixed-terminal observer 配对。部分保存必须非零且少于 15；停止后两次 identifiers 稳定，重发同冻结语义得到 15、先存结果保留、无重复、Live Photo pairedVideo/metadata 与原 15 验证后清理。该新用例尚未实机运行，不能算已通过。
3. 再补连续追加时原生停止、系统终止/崩溃恢复、权限变更；稳定 iOS 26 / 18–25、非灵动岛设备 / Watch 验收仍 OPEN。当前 DEBUG 路径不晋升 Release，host handoff 启动未被真机证实，不能宣布完整 V5 发布验收。

历史 `testHomeActivityPauseResumeCancelWithAllSevenQAInputs` 已替换为最新 15 素材 cancel-only 用例，原 pause/resume 结果仅是当时证据。旧系统停止用例中的 Home「继续处理」断言需按新的重新发送方案更新，未纳入下午首轮；它们不证明最新 UI。失败通知中旧「暂停/打开 App 继续」文案也需在重发 gate 通过后统一简短未完成提示。首页现保留旧任务删除兜底，待成功重发及异常生命周期清理 gate 完成后才能删除兜底，不将用户期望误写为已经实现。

## 离线最终可靠性补充验收

最新源码 `MemoMarkQuiescentHostFinalFull.xcresult` 为 2084 通过、1 跳过、0 失败（参数化实际执行 2147 通过）；保留两条 FixtureExportReadbackTests 的历史 QoS runtime warning。`MemoMarkContinuedSessionInterruptionGreen.xcresult` 45 项专项测试通过。此结果不等同于真机后台处理验收。

新增并修复三个实际问题：系统 prepareQueue admission 不再提前自动渲染；准备过程中取消会先停止残留执行再释放租约；Continued Processing 中断只持久 hold 当前会话，后续新 Share 可执行且不受全局暂停开关阻塞。重复分享同处理意图按唯一 successfulSaveAccountingID 预约额度，避免重复预约拒绝合法的重新发送；不同配置保留不同意图。PhotoKit 不确定保存仍读回等待，不能为简化交互盲目重写。

正式主程序 BGContinuedProcessingTask adapter 已注册并通过正式编译，但 Share 尚未自动提交到它：之前 host handoff 无回调的根因边界尚待签名真机证明。该 adapter 调用原有 worker/queue/render/save/receipt，系统成功要求非空会话全部完成，取消/失败/hold 不误报成功。Beta 扩展实验的成功不晋升正式路径承诺。

`MemoMarkV5HostCandidate-20261009.xcarchive` 正式 Xcode Release 签名归档退出 0，主程序与 Share/Widget 三个 bundle codesign 检查通过。当前为开发签名（get-task-allow=true），版本 2.3.6 / build 124；不是商店分发包，不作为可发布结论。安全测试及签名摘要保存到当前聊天 artifacts/MemoMarkV5Acceptance-20261009。设备离线期间未安装、未唤醒主程序、未修改配置或相册。

发布阻塞继续明确保留：正式 host 独立后台回调及真实输出；停止后重新发送、异常终止恢复与权限变化的当前源码实机验收；稳定系统与旧系统兼容覆盖；最终分发签名及构建号。待设备联机后先证明 host callback，再执行对应照片输出矩阵。不要将旧 Beta 结果或当前自动测试写成这些 gate 通过。

最新源码 generic iOS 签名测试构建 `MemoMarkQuiescentHostFinalDeviceBuild.log` 退出 0。Release 主程序/Share/Widget 的符号扫描均未发现 ContinuedProcessingSpike 或 MemoMarkBackgroundProbe 调试符号；Info.plist 中仍有历史 spike permitted identifier，符号检查不等同于完整运行时认证。未安装到设备。

## 联机测试连接与选择边界

无线连接时 Beta/正式 Xcode runner 都在业务测试前因 XCTest 通道拒绝退出（code 74）；切换有线后 runner 成功执行测试。第一轮 PhotoKit 输入 inventory 为 15、输出 0、权限 authorized，随后 Photos 可见 cells 为 9 导致旧测试失败。修正仅限 QA 选择：命名输入相册内使用系统全选，PhotoKit inventory 继续作为 15 张数量边界，不将虚拟化可见 cells 数当作素材总数。该失败发生在分享前，不是输出丢失。重测结果另行记录。

`MemoMarkConnectedHomeCancel15SelectAll.xcresult` 真机通过 1 项：PhotoKit 确认输入 15 / 输出基线 0、全选 Share、主程序取消确认、无主动暂停/新重试控件；最终输出 0。该测试主动打开主程序，不作为独立后台执行证据。两条 QoS runtime warning 原样保留。随后启动单独的“不打开 host，中断后重新分享”测试，结果待结算。

`MemoMarkConnectedStopResend15.xcresult` 真机 1 通过、0 失败，无 runtime warning。15 素材首轮部分保存后原生取消，首次完成 1/15，lease release 与持久 hold 均独立读回；两次稳定保存标识检查通过。相同冻结说明重新 Share 15 素材后总输出 15，保留首轮标识，静态 metadata / Live Photo pairedVideo / 原素材 15 检查并清理至 0。处理观察期间不打开主程序。独立 CoreDevice 两轮终态摘要存档。此为 iOS 27.2 Beta DEBUG 扩展 owner 路径验收，不代表正式 host 后台启动 gate 已通过。

联机进一步发现 P1 状态投影缺陷：新的三张已完成并输出，但旧中断 15 张会话的未终结 tasks 被 resolvedSnapshot 优先当作 running，页面卡在准备中。Mac 回归 `MemoMarkHeldStatusProjectionRed` 真实复现，Green 8 项通过。修复将 executionSuspendedAt 非空会话排除自动运行候选与 activeJobCount；明确查看中断历史时为 needsAttention，保留原回执/资源。全套 `MemoMarkHeldProjectionFinalFull` 2085 通过、1 跳过、0 失败，保留两条历史 fixture QoS warning。

新增仅 DEBUG 的 continuedHostQueueProbe opt-in，以固定正式 handler identifier 提交真实三张处理意图；不将扩展实验开启到 Release。首次 exact-host test 因输出相册中存在前一轮 host 恢复的三张而在分享前停止；`MemoMarkConnectedMarkerCleanup3` 通过，原素材 15，清理三张后至零，随后执行干净基线的 exact-host test。host callback 与实际输出仍以此独立结果为准。

正式入口 `MemoMarkConnectedFormalHostQueueClean` 未通过：固定 host identifier 提交 confirmed，Share 返回，四分钟内输出 0、独立读取无 host.continuedQueueCallback，durable intake 保留 1。安全事件与 failed summary 已存档。随后 host foreground recovery 的 intake 被消费，但三张未暴露完成面，stageDuration 记录导入/构建/导出完成、save failed；Live Photo 路由也有 failed 记录。不能将状态修复或队列 drain 误写为该恢复 gate 通过，实际保存失败原因仍需追踪。

`MemoMarkConnectedFailedHostCancelDelete` 1 通过：失败现场取消本轮、删除对应记录、重新启动后记录不复活；独立队列快照确认三张 cancelled / historyDeleted=true。未删除原图或配置。最终相册/无活动任务基线检查正在执行。`MemoMarkHeldProjectionStableRelease` 正式构建及 `MemoMarkV5HeldProjection-20261009.xcarchive` 新签名归档退出 0，codesign deep/strict 检查通过；仍为开发签名候选，不是商店发布验收。

### 保存失败归因更正及最终已知边界

先前 host recovery 的 save failed 与正式 host callback 缺失必须分开。捕获的 request transport 确有 19 字说明覆盖，却仍引用原 durable revision；ShareCoordinator.resolvedConfiguration 按合法生产引用解析原配置，临时 QA 覆盖不再是输出意图。扩展实验此前直接使用 transport，因此不能混淆两条配置解析证据。只在 DEBUG hostQueueUntil 有效时将临时 QA transport 标记为既有 legacy compatibility，明确不冒充用户的 durable revision；不修改生产解析或用户配置。

`MemoMarkHostFixtureForegroundRecovery` 真机 1 通过、0 失败：明确主动打开主程序，三个不同素材按临时说明保存、静态 metadata 与 Live Photo pairing 读回通过并清理至零。这是 foreground recovery / QA transport 证据，不是 canonical-production-background 或 Photos-only host callback 证据。`MemoMarkConnectedFinalBaseline` 1 通过：前一失败会话取消删除后无 processing card、输出 0，未重装应用。新夹具的 Share-to-host background gate 尚未按此夹具再测，不能把旧失败试验写成新夹具输出结论；旧四分钟试验的无 callback 证据仍成立。

后续发布阻塞：固定 host handler 的 Photos-only 回调（当前 Beta 实机未出现）；正式生产引用路径的完整后台输出；稳定 iOS 26/旧系统及设备展示覆盖。禁止将 DEBUG extension owner 或 DEBUG legacy QA transport 当作 Release 正式可用路径。原素材和配置保留，失败任务已取消/删除，安全结果摘要归档，未提交、推送或上传商店。

最后 `MemoMarkFormalHostRegistrationReadback` 启动/素材版本读回通过，独立日志明确 fixed handler accepted=true。可排除注册被拒绝，但不能据此声称 Photos-only dispatch 有效或已确认系统缺陷。`MemoMarkConnectedCleanFinalState` 真机 1 通过、0 失败：无 processing card、QA 输出相册 0；四个临时 probe 开关已独立读回均关闭。新 fixture 已通过前台恢复，但正式后台回调与新 fixture 的 Photos-only 全链路仍未关闭。未重装、未修改用户配置或原素材。
# 2026-10-09 execution-ownership re-audit

The original research's extension-to-containing-app handoff assumption is disproven on the connected iOS 27.2 Beta device. The signed formal adapter receives callbacks for both fixed-ID and fresh-ID app-origin foreground submissions. Both Photos-origin variants accept submission yet produce no containing-app callback/output during four-minute independent observation. Device scheduler logs explicitly identify ShareExtension PID 2634 as the client, Photos PID 1857 as the host, and grant the continued-processing assertion to PID 2634. Changing the task identifier cannot transfer that execution grant to MemoMarkiOS.

The corrected route is a system-granted extension executor invoking the existing shared durable/media/save pipeline, plus containing-app foreground/BGProcessing recovery. Ordinary extension lifetime after dismissal remains insufficient; the explicit Continued Processing grant is the execution opportunity. This evidence is specific to the tested OS and does not certify stable-system support or Release activation. Details and primary sources: `2026-10-09-host-continued-processing-release-boundary.md`. Safe device excerpts and control results are in the task's MemoMarkV5Acceptance-20261009 artifacts directory. Raw device archives remain local in /tmp.

The failed route's current-session cancel/delete/relaunch and scoped QA output cleanup pass. The canonical-configuration test first exposed an outdated native accessibility selector, which was corrected without changing product UI. Both long and seven-character real supplement fixtures then failed all 15 inputs at `glassCardContentOverflow`. The root cause is the composer's explicit newline between automatic memory and the authored supplement being measured and drawn as one line. Shortening the fixture alone did not solve it. Production GlassCard now permits two explicit secondary lines within the existing rail padding, preserving the authored text, single-line geometry and overflow rejection for three lines. The production regression first failed (23 passed, 1 failed), then passed (24 passed, 0 failed). Full macOS tests: 2,087 passed, 1 skipped, 0 failed; two existing fixture QoS warnings remain. The real-config 15-source signed-device rerun passed: all 15 saved without host foreground activation, creation dates and authored description verified, Live Photo MOV pairing verified, originals retained, QA outputs cleaned to zero. The refreshed formal-Xcode Release archive and strict deep signature verification passed; it is a development-signed archive, not distribution/App Store acceptance. Cancellation/resend and identity follow-up are running. Release Share scheduling remains gated. A metadata-only DEBUG override is not equivalent proof. The original supplement configuration was restored through native UI before this rerun.

## Post-fix signed-device reliability gates

`MemoMarkRootGlassReliability.xcresult`: three passed, zero failed, no runtime warnings. Back-to-back overlapping Share selects 12 items but saves seven unique intents under one continuous session. Repeated identical frozen semantics preserve saved identifiers; a changed frozen description permits three additional outputs. Native cancellation after real partial output stops further saves independently; resending all 15 completes exactly 15 while preserving prior successful identifiers. Metadata and Live Photo pairing checks pass, all 15 original inputs remain, and each round clears only QA outputs to zero. These follow-up identity fixtures use the explicit metadata override; canonical authored-text coverage is supplied separately by the real-config 15-source gate.

Only the iOS 27.2 Beta physical device is currently connected. Stable-system and older-system physical acceptance remain unavailable; simulator, archive and Beta results cannot close those gates. Release Share Continued Processing is still disabled pending that certification and separation of the experimental adapter from its debug instrumentation.

## Home compact layout and interrupted-record deletion

User requested the existing portrait top-spacing policy, not an arbitrary reduction. Home top padding/navigation policy remains the pre-change portrait baseline. Cancel/delete controls now share the count/status row, retain 44-point hit targets and do not add a separate tall row beside the thin progress bar; panel vertical padding is 8 points.

Deletion previously silently rejected a held session containing nonterminal export/save phases. The store now refreshes durable state and invokes the existing cancellation command before terminal-history deletion. Ownership checks still protect live PhotoKit saves and receipts. The regression failed before the correction and passed afterward; ledger/store tests total 54 passed. The connected device's existing 1/15 interrupted session was directly deleted without a prior cancel step; it disappeared and stayed absent after relaunch, with no current-task card in the captured screenshot. This does not certify immediate deletion during an active foreign-process PhotoKit transaction.

Latest full macOS suite: 2,088 passed, 1 skipped, zero failures; two existing fixture QoS warnings remain. Signed device direct-delete test: one passed, no runtime warnings. diff whitespace check passed. Device build installed the compact layout and deletion fix without reinstalling or clearing saved user configuration.
