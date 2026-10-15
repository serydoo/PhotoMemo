# GlassCard SDR 亮度压缩研究

## 实施前决策记录

- Primary loop: Product Loop；风险 P2，研究候选，不改变生产默认。
- 观察：固定黑色背板在亮背景需要足够遮盖，但也压低暗部；ROI 模糊只抑制细节，不能约束均匀白背景。
- 范围：独立研究 probe，复用实际 Layout、Overlay、artifact compositor；不修改 durable configuration、原片、Metadata、Minimal、Photos 或 Live Photo。
- Apple 能力：Core Image Gaussian blur、Core Graphics sRGB、SwiftUI ImageRenderer。全部输入显式限制为不透明 8 位 sRGB。
- 固定布局为 1920×1080 compatible 1.4，模糊半径 panelHeight×0.025，文字 opacity 0.96。比较黑色背板 alpha 0.56 与 clear surface 下的三条软膝函数。
- 函数：先解码 sRGB，Y=0.2126R+0.7152G+0.0722B；Yout=c×tanh(Y/c)，RGB 同比缩放，c=0.10/0.12/0.14。无场景分类、无全局统计、无逐帧自适应。
- 验证：真实渲染同坐标 glyph core 90% 最小/P10 对比；黑/灰/白、纹理、渐变、RGB 控制；底栏外像素相等；连续函数单调、有限、黑点稳定、线性色度误差。低位量化不是感知色相认证。
- 失败模式：暗部压缩仍存在，白字对彩色亮背景的最坏值可能不足；8 位量化、色彩空间转换、边缘覆盖、性能和 HDR 均不能从这一片外推。
- 验证采用 macOS 原生测试，不使用模拟器。正式视觉及 Photos/Live Photo 接入需要真机证据。

## 实测结果与候选收敛

9 种输入 × 4 候选 × 4 位置，共 144 行。使用真实 Overlay/artifact/compositor；每个位置均有 90% 字形核心采样。指标限定在这些样本，不是 WCAG/照片阅读认证。

| 候选 | 最低核心对比 | 最低 P10 | 低于 4.5 的组 / 36 | 白底最低 | 暗灰32背景平均 Y |
|---|---:|---:|---:|---:|---:|
| 固定黑色 alpha 0.56 | 4.647 | 5.214 | 0 | 4.647 | 0.004025 |
| soft knee c=0.10 | 5.572 | 6.596 | 0 | 5.823 | 0.014444 |
| soft knee c=0.12 | 5.037 | 5.797 | 0 | 5.195 | 0.014444 |
| soft knee c=0.14 | 4.596 | 5.214 | 0 | 4.647 | 0.014444 |

c=0.12 的最低值来自红色控制而非白色；不能只靠灰阶确定亮度上限。暗灰32平均 Y 是固定背板的约 3.59 倍。该控制在 8 位量化后几乎保持其输入亮度；不意味着其他暗部、任意色彩或 HDR 完全无损。

渐变的软膝输出显示中高亮度趋于平台：c=0.12 的 gray128 背景平均 Y=0.114435，white=0.119538，亮度差只有 0.005103；固定背板为 0.035601/0.141263，差 0.105662。这符合函数约束，但牺牲局部明暗层次，不能称为无代价的玻璃改进。

保留 c=0.12 为下一轮静态 SDR 研究中心候选，c=0.10 保留作较强约束对照。c=0.14 最低 4.596，余量较小，不作为首选。生产仍使用既有默认；0.56/0.96 本身也是研究对照，并非已接受的默认。

## 组合边界

源响应材质必须由显式 composition 输入承载：Layout 提供 panel mask/ROI/尺寸；材质规范提供固定参数及工作色彩策略；源像素处理发生在合成环节；Renderer 绘制文本、badge、keyline。不能用透明 Overlay 假装包含已经采样过源照片的玻璃。预览、静态导出、每帧视频必须共享同一函数与参数；不得隐含使用 SwiftUI 系统 material 替代可导出的算法。

研究 probe 的整帧 CPU 循环、数组和掩膜是控制工具，不是生产实现，不证明 BP-001、峰值内存或处理时延。下一步先检查源色彩声明/透明度/方向的接入前置条件，再为 SDR still 构建明确的研究 composition adapter；HDR 和 Live Photo 继续保持独立证据门槛。

## 色彩控制、照片检查及验证闭环

4096 个均匀 RGB 网格样本（每通道步长17），c=0.12 经编码、取整、解码后，对 ideal/quantized 各自 RGB 总量归一，最大单分量方向误差为 0.007319251。该指标不按亮度加权，也不是 Delta E、感知色相、P3 或 HDR 验证；量化前同比关系误差 <1e-14 的控制通过。黑点稳定；三 cap 的 10001 点函数单调/有界控制通过。

本地 bundled 校准照片经显式 sRGB/encoder-safe 1672×942 归一，固定同一布局与模糊，对照固定0.56背板与c=0.12。600宽图上方固定、下方软膝；下方底栏保留更多暗部纹理、视觉重量减轻。照片局部复杂度也增加，不能把静态对照当作小屏可读性或手持体验验收。照片文件未修改、未上传。

- `/tmp/MemoMarkGlassSDR.xcresult`：2项 macOS 测试通过，0失败/跳过，app/test build完成。
- `/tmp/MemoMarkGlassSDRCalibration.xcresult`：1项 targeted macOS 测试通过，0失败/跳过。
- 分析器验证144行、键唯一和所有位置采样非空；mask零覆盖像素逐字节保持，blur halo对照通过。
- `git diff --check`通过。临时Tests probe与研究源比对相同后移除；最终研究源、分析器、CSV/JSON和图保留。
- 输出位于 `$HOME/Documents/Codex/2026-10-01/GlassCardSDRLuminance/`。生产代码/默认本片未修改，未运行Simulator、未提交/推送，未取得新iOS真机、Photos、HDR或Live Photo验收证据。
