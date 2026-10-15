# GlassCard SDR 研究源/像素阶段并发边界

Engineering Loop，P2，研究入口增量。依据：同步研究test完整采样约17s，final xcresult有QoS priority inversion warning，尚未归因具体调用；不是生产性能认证。将源准备与ROI像素运算移出MainActor，保持ImageRenderer独立UI阶段。Swift现代并发使用nonisolated值类型+@concurrent入口，结构化await，不引入detached任务或全局队列状态。

源prepared/report/admitted采用Sendable不可变结果；原material算法标明nonisolated，CPU行循环加取消检查，ImageIO/CI/CG调用前后及阶段切换检查。取消不发布新输出；原生同步解码/filter不能强制中断，只能检查边界。本片只拆source/pixel；实际writer及最终composition仍保留原调用边界，不偷偷修改生产类型的actor隔离。后续需要独立Sendable layer/metadata输送契约，再拆编码/合成。

async研究adapter在UI阶段验证plan/参数并形成纯像素request，await worker完成后再次检查取消，再进行原Overlay/render/composition。同步入口保留作像素对照。大图内存/取消时延不在本片；完整参考与中间图保留，未优化。

验证：同一ImageIOfixture源及request，源准备/像素阶段报告off-main，异步与同步输出逐字节相等；预取消任务抛CancellationError，stage gate拒绝取消结果；原final-color矩阵可按实际变动需要回归。macOS构建/targeted测试，临时副本比对移除，生产不变。

## 实施与证据

`GlassCardSDRResearchWorker.swift`提供@concurrent prepare/process；输入与结果为Sendable不可变值，CGImage依赖平台已有并发声明，未自行增加unchecked传输。source preparation与material明确nonisolated；ImageIO/CoreImage对象在调用内创建，不跨阶段共享可变context。参数验证仍使用Layout传入的ROI/圆角。

Adapter的render与renderAsync共用pixelRequest验证及draw阶段；async入口await worker前后、ImageRenderer前后及返回输出前检查取消。亮度CPU循环逐行检查取消，CI/ImageIO同步调用只能在边界检查；没有强制打断或取消时延声明。测试只证明启动前取消，不证明处理中取消或UI发布竞争。

`/tmp/MemoMarkGlassAsyncFinal.xcresult`实际执行asyncStages/sharedAdapter两项通过，零失败/跳过，app/test build完成。源准备与像素工作Thread.isMainThread均false；异步/同步最终像素及processedSource逐字节相等；两种预取消任务均抛CancellationError。既有adapter参数/溢出及HEIC属性回读测试通过。生成的shared-adapter-output.png与前片原件逐字节相等，SHA256证明保存。未重跑完整224行缩放矩阵。

本次小范围xcresult runtimeWarnings为空，不能宣称前片完整采样流程QoS warning已修复。实际writer及最终composition仍在原边界；编码/合成移出UI需独立typed layer/metadata契约及实际writer兼容回归，生产actor规则未改。无48MP峰值、取消时延、真机或Photos/HDR/Live Photo证据。

第一轮worker缺少testable模块导入导致internal up访问编译失败，补齐后绿色；同步/异步draw抽取后最终回归通过。6个临时测试文件比对移除、git diff --check通过，输出在 `$HOME/Documents/Codex/2026-10-01/GlassCardSDRAsyncStages/`。未提交/推送，生产默认及媒体路径未改。
