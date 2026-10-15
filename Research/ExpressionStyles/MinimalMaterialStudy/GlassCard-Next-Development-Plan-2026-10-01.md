# GlassCard 下一阶段开发方案

日期：2026-10-01。源码基线：main / 8828dd34。授权：用户要求结合当前 main 梳理路线并开始实施。

## 当前事实与对话校正

main 已接通第四样式、独立四区域模板、Layout/文字 fit、统一 preview/artifact、静态输出、Live Photo 入口和 Share 冻结快照。Minimal 仍为单一 primaryOutput。生产 GlassCard 使用 darkLayerV1（黑色 alpha 0.42），视频沿用固定 bitmap overlay 与 CoreAnimation；这不是逐帧 backdrop blur/refraction。

研究 worktree HEAD 为 5936bffc，包含大量未提交源码及未跟踪研究文档。对话所称与 main 相同的配方/fit 文件是研究工作区状态，不能当作该分支已提交内容；直接比较 branch ref 会看到这些文件缺失。继续按工作区文件与证据逐片吸收，禁止整支合并。

9 月 30 日交付记录的 1947 通过、1 跳过与真机初步功能反馈是历史证据。本次重新执行的检查另列。两个真实 pair 的 Core Image 实验报告保留了 clean-aperture 问题和修正、47/53 帧时间戳及音轨；输出 MOV 无配对 identifier、未完成 PhotoKit 保存回读，不能算 Live Photo 认证。未重新解码私人素材或核实对话中的完整语料数量。

## 决策门：第一片 availability contract

- 主循环：Engineering Loop。
- 证据：RecordCardPresentationStyle.selectableStyles 只在 UI 用 DEBUG 隐藏 GlassCard；Codable、模板、快照和 renderer 在 Release 仍识别该样式。
- 所有者：RecordCardPresentationStyle。注册由 enum/Codable 穷尽集表达；authorable 与 processable 为运行时派生能力，不进入持久化。
- 风险：P1，错误地用 UI 门槛拒绝旧配置/冻结任务，或在 Release 意外开放实验入口。
- 依赖：UI 从样式能力派生 selectableStyles；既有处理、布局和媒体路径保留。无 schema/encoded key 变更，无新保存系统。
- Apple 能力：保留 SwiftUI 原生选择控件；编译条件只决定当前构建 authoring 能力。系统玻璃 UI 不能作为媒体导出实现。
- 实施：集中能力模型，显式可测试 Debug/Release policy，修正模板字典说明，增加兼容性与选择列表测试。
- 能力语义：本片 authorable 表示允许在样式选择入口提供该样式；不增加对已恢复配置的编辑禁令。processable 是已注册样式的兼容性声明，当前所有注册样式均为 true，不新增生产拒绝分支。若未来需要限制已有配置编辑或停用处理，必须另有产品决定与失败/恢复契约。
- 验证：先失败测试，再 macOS 聚焦回归；Debug/Release 构建；不调用 Simulator。本片不改输入、材质像素或交互，安装不作为媒体验收。

## 后续切片及退出标准

| 顺序 | 范围和所有者 | 完成条件 |
| --- | --- | --- |
| G1 | 样式能力契约（本片） | Release 不提供新选择，已注册 GlassCard 仍解码、持久化、渲染；既有样式不变 |
| G2 | 固定透明材质产品定案；Presentation/Layout/Renderer | 同一全局配方覆盖亮暗/复杂背景、横竖照片；中英日韩及长文本、空区域、徽标矩阵；原生真机审阅可读性和照片遮挡；固定几何与完整字符串拒绝政策先锁定 |
| G3 | Live Photo 基线认证；媒体 adapter/PhotoKit | 真机原始 HEIC+MOV，核对方向、clean aperture、still/key photo、配对 identifier、时间戳、音频、Photos 保存及回读、原片保护、取消/失败恢复；与 Minimal 对照 |
| G4 | 色彩契约与实现；ImageIO/媒体 adapter | 分别定义 SDR sRGB、Display P3、HDR/gain-map 的输入、工作空间、输出及降级政策；验证像素/标签和 still-motion 色彩一致性、48MP 峰值内存；8-bit DeviceRGB 更换本身不能宣称 HDR 保留 |
| G5 | 源像素响应材质可行性；独立研究 harness | 在 G2 同批素材上固定透明层达不到目标的证据；共用 mask/recipe 与 clean-aperture 映射；帧时序、音频、色彩、内存预算；普通 MOV 成功不等于 Live Photo |
| G6 | 有条件引入 renderer-neutral material artifact | G5 与产品评审通过后，先契约/失败测试，再 still/video adapter，最后真实 Photos 认证；不得在 exporter 中添加 style==glassCard 特例 |

G2/G3 可以作为同一次真机审阅的两个独立证据集；G4 在研究侧并行定义，但不得未经色彩契约直接替换生产媒体管线。Release authoring 开放依赖外观定案和逐项媒体/性能/无障碍验收。版本与 Store 发布另有授权和证据边界。

### 2026-10-01 深入测量后的优先级调整

实际 macOS Renderer 纯白底测得主/次文字峰值像素对比分别为 3.250/2.694；576 条多语言 fit 结果中，192 组跨尺寸比较有 7 组 fits/overflow 不一致。新增字体度量确认 systemFont 字宽不按字号线性缩放。G2 因此先拆出 **G2a 同源 preview/output fit（Engineering Loop，P1）**，再推进 **G2b 材质候选定案（Product Loop）**。具体场景、方案选择、UIKit/真机边界和原始证据见 `GlassCard-Appearance-Measurement-2026-10-01.md`。本轮仅研究测量，没有改变现有导出或 UI 行为。

## 验证记录

- G1 已实施：RecordCard.swift 集中 Availability 与 authorableStyles；selectableStyles 投影当前构建策略。没有改编码值、模板、快照、材质或媒体算法。
- RED：新增测试在契约实现前编译失败，明确缺少 availability/authorableStyles；见 `/tmp/MemoMarkGlassCardNext-red.log`。
- GREEN：macOS Debug 的 GlassCardIntegrationTests、GlassCardRendererPrototypeTests、MinimalRendererLayoutTests 全部通过。xcresult 摘要计 30 个测试、33 次设备执行（含参数化展开），0 失败、0 跳过；`/tmp/MemoMarkGlassCardNext-renderer-tests.xcresult`。
- iOS Release（generic/platform=iOS，关闭签名）构建通过，包含 Share/Widget extensions；`/tmp/MemoMarkGlassCardNext-ios-release.log`。Debug macOS 测试宿主使用项目开发签名构建并运行成功。
- 最初 quiet 编译出现无进一步输出的诊断，随后完整输出重试完成编译。包含 ConfigurationOptionListContractTests 的运行未完成；宿主采样定位到读取 Desktop 仓库源码的 open 调用停顿。移除该额外源码契约套件后行为测试完成；没有改写或禁用该套件。临时 ad-hoc 签名尝试因 app entitlements 要求开发证书失败，之后采用项目开发签名。
- git diff --check 通过；人工复核策略穷尽分支、未知 route 解码拒绝、既有模板/renderer 路径和原有样式顺序。
- NOT VERIFIED：本次未运行全量测试、独立 Release 测试宿主、真机安装、外观/VoiceOver、Photos/Live Photo 媒体认证、P3/HDR、性能预算。Release 策略在 Debug 测试中显式传入 false 验证；实际 iOS Release 已构建。
- 未提交、推送或发布；保留原有推广/发布文案/其他研究/config 工作区差异及研究分支未提交内容。

## 2026-10-01 current checkpoint — after Swift PNG/HEIC repair research

- Production foundation: main fourth GlassCard renderer/independent content/layout/preview/artifact/media entry exists; appearance defaults stay existing darkLayerV1. Working changes remain scoped and uncommitted.
- Research material: controlled SDR source blur/luminance cap/contrast, display and encoded readback evidence retained. Candidate is not accepted default; small landscape typography, actual photo perception and HDR/P3 remain open.
- Research execution: source prepare, pixel processing and final composition separated from MainActor overlay generation; metadata frozen Sendable snapshot and actual-writer off-main control verified. Production scheduling not migrated.
- Production reliability fix: JPEG non-ASCII UserComment capacity reservation + required Unicode patch passed permanent regression/native build. PNG/HEIC Unicode correction remains research-only.
- Current new result: shared Swift TIFF ownership checks + PNG/HEIC research repair, 22 exact Python-reference outputs and native Unicode readback; final 10 test items/11 executions pass. Restricted references/private metadata fail closed; no generic format certification.
- Next bounded Engineering work: research writer orchestration with capacity reservation, explicit unsupported-result policy, cancellation/temporary-file ownership and memory/latency measurements. Keep conservative production route until evidence closes.
- Product/manual gates: real-photo appearance and readable size, paired device/Photos lifecycle, HDR/color and temporal Live Photo compositor. These remain separate acceptance obligations; research successes do not close them.


Encoding orchestration checkpoint: PNG/HEIC research now connects frozen properties → capacity reservation → actual writer → bounded shared repair → native readback → immutable output Data, with scratch cleanup and cancellation boundaries. Two native tests/12 output controls pass (see Encoding-Orchestration record). Production adoption still needs metadata eligibility/failure-policy specification, memory/performance evidence, broader container coverage and Apple Photos certification; this checkpoint does not enable a new default.


Full-size eligibility checkpoint supersedes any inference from tiny HEIC success: controlled 1024/2048/4096 native HEIC uses method1 grid/idat; current shared adapter rejects it. Next implementation slice: bounded method1 local idat extent ownership/alias support, retain method0/Exif constraints and private MakerNote rejection. Metadata matrix and early retained-MakerApple preflight are verified. Mac resource observations are single synthetic calls/process-lifetime HWM, not production memory certification. See GlassCard-SDR-Encoding-Eligibility-2026-10-01.md.


Same-session grid closure: bounded local grid method1/idat ownership implemented; Exif stays method0/single mdat extent, protected/external/unknown/reserved/aliased structures reject. Three native full-size pixel/Unicode/whitelist controls and existing shared repair matrix pass; final combined 16 items/17 executions retains one QoS warning. Separate full encoding observations now verify all8 PNG/HEIC outputs through12MP (no warning in standalone run). Private MakerNote eligibility, high-entropy encoded-size/memory evidence, HDR/P3/Live Photo and device/Photos gates remain. See GlassCard-SDR-HEIC-Grid-2026-10-01.md for superseding evidence.


## 2026-10-01 — Native-first visual scope correction

Owner questions whether competitors simply reuse system Liquid Glass and whether this research overcomplicates the visual goal. Current source confirms native `.glassEffect(.regular.interactive(), in:Circle())` in preview controls, but GlassCard surface is darkLayerV1; old branch system-material comparator uses ultraThinMaterial, not glassEffect. Competitor internal implementation is unknown; supplied downloaded references cannot identify exact blur/refraction or native/custom renderer. Do not infer complex implementation from attractive screenshots.

Prioritize a bounded same-photo/same-layout/same-content comparison: current fixed surface, native Liquid Glass regular/clear, and at most one simple source-aware blur/tint alternative. Reuse existing Layout/content and exporter. First determine native displayed material and actual saved output behavior; ImageRenderer only guarantees directly rasterized SwiftUI primitives, and UIVisualEffectView snapshot requires containing window/screen support. These are experiments, not proof native export is impossible. Avoid whole media abstraction/shader/HEIC/EXIF expansion before demonstrated visual/native-export gap. Preserve original protection, existing metadata and pairing behavior; broader HDR/temporal perfection is a separate scoped objective, not a default visual-study prerequisite. No production token or product-owner acceptance invented.

High-entropy study completed (five verified outputs/one expected12MP PNG rejection,1 native test): size cap prevents downstream load/repair but cannot constrain native encoder memory/disk. Source/test/data retained; cancellation instrumentation and private/container expansion deferred behind visual evidence. Scoped high-entropy record and `$HOME/Documents/Codex/2026-10-01/GlassCardHighEntropy/` contain results. Native equivalence/export comparison has not yet run; physical iPhone acceptance still required for iOS behavior.

2026-10-02 superseding native checkpoint: signed paired iPhone17ProMax/iOS27.2 exported8 same-source PNG controls through ImageRenderer; regular/clear effects survive rasterization, and dark regular is the provisional readable candidate. A30-frame changing-source native MOV control exports successfully in0.262s (single1080x1440 synthetic Debug run); native readback confirms1s/30fps and decoded changing-source glass. Earlier uncertainty about native raster omission is resolved for these tested runtimes. Next scope is the minimum source-dependent PresentationArtifact/media adapter, preserving existing transforms/audio/pairing/Photos contracts. Custom shader/extra container repair remains deferred. This is not final photo appearance, paired Live Photo, color or interaction certification; details in GlassCard-Native-First-Delivery-2026-10-01.md.

Official API evidence checked: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views ; https://developer.apple.com/documentation/swiftui/imagerenderer ; https://developer.apple.com/documentation/uikit/uivisualeffectview .
