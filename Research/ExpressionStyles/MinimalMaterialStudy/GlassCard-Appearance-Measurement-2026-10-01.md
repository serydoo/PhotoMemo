# GlassCard 外观与尺寸测量

日期：2026-10-01。基线：main 8828dd34，加上一片未提交样式能力契约。

## 本片决策门

主循环为 Product Loop：已有真实 pair 报告指出黑色 0.42 面板改善可读性但较重，浅色面板在亮背景上失去清晰度；当前固定材质尚未定案。风险 P2，研究测量不改变生产外观或媒体算法。所有者仍为 Presentation/Layout/Renderer，原片与媒体生命周期不变。

本片使用实际 GlassCardProductionRenderer、PresentationArtifact 和既有静态 compositor，对均匀灰阶做边界测量；并直接调用 resolved plan 建立中英日韩德法、多尺寸、横竖文字 fit 矩阵。合成灰阶用于隔离变量，不能替代真实照片、真机视觉、HDR 或 Photos 认证。研究 harness 临时放入既有 macOS test target，结果以 Swift Testing attachments 保留，完成后移除临时测试文件；源码保存在本目录以供复现。

Apple 能力核对：系统 Liquid Glass 属于交互/导航的功能层，不能直接当作导出像素契约；ImageIO/Core Image 的色彩空间、HDR 解码与输出需要独立政策。普通文字 4.5:1 暂作为本研究的可读性筛选目标，不能以输出像素字号套用大字例外，也不把这一目标声明为照片产物的法规/合规认证。

## 测量记录

### 实际像素：亮背景反例

调用当前生产 GlassCard artifact 和 MemoMarkRenderedImageArtifactGuard.composingSourcePhoto；将测量区域转换为显式 sRGB。四个位置均使用 `HHHHHH`，分别合成纯黑、128 灰、纯白源图，测量每个 glyph 行框的最小/最大线性亮度。本方法取极值，是该规则场景中可达到的像素对比上界诊断，不是复杂照片上的 glyph mask/局部背景测量，也不是 WCAG 合规认证。

| 画布 | 源灰阶 | 主文字峰值像素对比 | 次要文字峰值像素对比 |
| --- | --- | --- | --- |
| 360×480 | 0 | 19.262 | 11.666 |
| 360×480 | 128 | 8.887 | 6.243 |
| 360×480 | 255 | 3.250 | 2.620 |
| 1080×1440 | 0 | 19.262 | 12.422 |
| 1080×1440 | 128 | 8.887 | 6.558 |
| 1080×1440 | 255 | 3.250 | 2.694 |

左右相同层级的结果相同；24 行原始测量在 `material-pixels.csv`。纯白底的行框基底线性亮度为 0.262251，主文字最大亮度 0.964686，1080 次要文字最大亮度 0.791298。本轮 4.5:1 筛选目标来自 [W3C 对比度说明](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)，作为内部可读性目标；W3C 对照片中偶然文字等还有适用边界，不能把 MemoMark 照片输出整体标记为 WCAG FAIL。

这足以拒绝直接把 darkLayerV1 作为已认证默认外观。均匀白色源图在纯模糊/折射后仍是白色，新增这些效果本身不会解决反例；需要底面亮度或前景对比政策。边线、外阴影与徽标亮度不能代替文字区域的可读性。

### 文字 fit：发现跨尺寸结果不一致

中英日韩德法，四档句子重复长度，3 个短边（360/1080/4284），横竖 4:3，四位置，共 576 条解析结果，192 组跨尺寸比较。7 组出现 fits/overflow 改变。样本刻意覆盖长文，不代表真实用户的失败率；不能据总溢出数设置全局字符限制。

| 内容/位置 | 360 短边 | 1080 短边 | 4284 短边 |
| --- | --- | --- | --- |
| 中文 21 字，竖向左上 | overflow | overflow | fits |
| 英文 45 字，竖向左上 | overflow | fits | fits |
| 德文 58 字，横向左上 | overflow | fits | fits |
| 法文 56 字，横向左上 | overflow | fits | fits |

其余三组为英文 90 字横向左下、德文 58 字竖向左下、法文 56 字竖向左下；前两档 overflow，4284 fits。原始明细和所有七组在 `text-fit-matrix.csv` / `summary.json`。

### 字体度量的原因证据

Geometry 同比缩放，但 NSFont.systemFont(ofSize:) 返回的文字度量不按尺寸线性缩放。直接测量最小允许字号的 CTLine 字宽：

| 内容 | 短边 | 行框宽 | 最小字号下实际行宽 | 行宽/短边 |
| --- | --- | --- | --- | --- |
| 中文 21 字 | 360 | 125.827 | 127.060 | 0.352945 |
| 中文 21 字 | 1080 | 377.482 | 380.036 | 0.351885 |
| 中文 21 字 | 4284 | 1497.344 | 1435.787 | 0.335151 |
| 英文 45 字 | 360 | 125.827 | 143.738 | 0.399271 |
| 英文 45 字 | 1080 | 377.482 | 375.640 | 0.347814 |
| 英文 45 字 | 4284 | 1497.344 | 1386.681 | 0.323688 |

中文前两档即使最低字号也超宽，大档则能放下；英文小档超宽，而中、大档能放下。系统字体的 optical size、dynamic tracking 和 fallback 度量是合理原因，[Apple Fonts](https://developer.apple.com/fonts/) 明确描述随字号变化的轮廓与字距。测量确认的是总字宽变化，没有分解每一种字体机制的贡献。

源码位置：GlassCardTextFitSpecification.swift:70–76 每次重新取 UIFont/NSFont；MemoryCardPreviewSurface.swift:92–97 按控件 proxy.size 解析；GlassCardCardRenderer.swift:27 也按容器尺寸解析，而正式 artifact 使用输出 canvas。共享函数不等于共享同一次排版结果。本轮量化在 AppKit/macOS；iOS 使用 UIFont，差异具体数值和肉眼反馈需要 paired iPhone 验证。

### 从当前几何推导的显示与遮挡成本

360 短边下：面板高 46.8，主/次字号基值 8.649/6.571，缩小下限 6.227/4.600。它们是图片渲染坐标，不是编辑器输入字号；不得混入 40pt/28pt 的输入几何契约。再增大缩小范围会让小尺寸阅读更困难，不能当作修复。

按连续几何计算 capsule 面积（不含阴影/抗锯齿），3:4 竖向约占照片 9.127%，4:3 横向约 12.377%。这是覆盖面积，不是主体遮挡比例；真实 pair 的手/身体遮挡仍需逐帧标记。此研究支持先保持固定 anchor、审阅遮挡，未授权自动避让或拖动模型。

当前底部 overlay 在 4284×5712 的理论 8-bit RGBA 体积为 13,023,360 bytes（12.42 MiB），但同尺寸全图 RGBA 为 93.35 MiB；8064×6048 全图 RGBA 为 186.05 MiB。它们是裸缓冲推导，不是 Instruments 峰值或 BP-001 认证。动态材质即使只处理底部 ROI，也必须核对视频解码、纹理、滤镜 halo、输出缓冲和拷贝同时存在的成本。

## 后续实施方案

### G2a：先闭合 preview/output fit 同源（Engineering Loop，P1）

当前观察是内容完整性状态随显示尺寸变化；所有者为 resolved presentation 与 preview 消费者，Layout 边界不变。建议按真实配置校准源的已定向输出 canvas 解析一次，然后预览缩放该层/同一排版计划。禁止把小控件尺寸作为导出资格判断；禁止只把字体 pointSize 乘比例后重新申请 systemFont，那仍可能改变字宽。

两种候选：

1. 复用生产 artifact 的底部 bitmap，预览只缩放 bitmap；保真最直接，但须验证更新延迟、缓存与分配成本。
2. 在生产 canvas 构建同一 resolved layer，再整体缩放显示；需要验证 SwiftUI 实际绘制、CoreText fit 和 UIKit 字体行为，不能假定 scaleEffect 自动达到像素保真。

第一片先复现上述中文/英文在 UIKit 的情况，确定配置校准源的真实尺寸所有者；保持当前生产 export 像素和 fit 不变，仅让预览消费该生产判断。验证横竖、旋转、不同卡片宽度、短/边界/超长中英日韩内容、空区域和 badge anchor；新回归必须验证结果同源。最终以 signed paired iPhone 视觉验收关闭，不调用 Simulator。若用固定 1080 逻辑画布统一所有生产输出，需要另行审阅输出兼容性，不在这片静默引入。

### G2b：统一材质候选矩阵（Product Loop，P2）

先比较三个独立因素：底面亮度约束、前景 opacity/weight、背景细节抑制；所有照片用相同规则与参数。次要行先比较与主行相同亮度、以字号/字重表达层级的候选，避免仅用 0.78 opacity 牺牲日期/时间结果的可读性。该候选未接受为生产 token。

简化的纯白反例模型（排除实际阴影/色彩转换/字形覆盖）显示，encoded-sRGB alpha 合成达到 4.5 时，黑底 alpha 对 0.96 白字约需 0.5478，对 0.78 白字约需 0.6178；在线性光合成模型下分别为 0.8240/0.8586。差异说明材质不能脱离 working/output color space 定案；这些数值是模型边界，不是建议直接改用的参数。

因此应分别比较：固定透明基线+更亮次要文字、全局更强背板、受限源像素响应。后者允许对所有素材使用同一确定函数（blur/局部亮度约束），不按场景选预设；“统一规则”不必等于“固定 bitmap”。是否增加该复杂度取决于同批真实素材证明的收益。先亮度/细节，再有条件研究折射；光学装饰不能代替文字承载。

### G3/G4：媒体与色彩边界

真实 pair 的方向/clean aperture/时间戳研究保留，但普通 MOV 不具有 Photos 配对、关键照片、保存回读证据。当前生产视频仍用固定 overlay/CoreAnimation；其未显式定义全部色彩参数不能直接证明输出丢失 HDR，需要编码后读回实测。

静态 artifact guard 与 LivePhotoStillImageCompositionService 使用 8-bit DeviceRGB；当前 ImageIO writer 路径使用 CGImageDestinationAddImage，没有在所检索路径中建立 gain-map 读取/重算/辅助图写入契约。Apple 的 [HDR WWDC24](https://developer.apple.com/videos/play/wwdc2024/10177/) 说明完整 HDR 路径涉及解码、编辑、显示和写入；修改后的 SDR/HDR 配对可重算 gain map。给 SDR 基图加栏后沿用原 gain map 并不自动正确：栏与 glyph 的 HDR 亮度语义也需要定义。P3、HDR和gain map 不得合并为一个开关。

### 材质版本与证据归属

GlassCardMaterialRecipe.researchID 是代码研究标识，尚不是冻结配置的 durable 材质版本。定案时需要明确材质更新是兼容性改善还是需要可复现版本；不能因为字符串带 v1 就宣称任务已冻结材质 recipe。此处不新增 schema。

研究工作区 Product Contract 等旧文档中的“未注册”是当时状态，已被 main 完整集成记录取代。Full-Decoded-Frame Audit 证明的是固定边界位置，不证明动态模糊、对比或 HDR；Local-Contrast Proxy 的 OCR 阈值数据不是实际字形对比，不拿来为本次Renderer签发外观结论。

## 可复现证据

- 研究源码：`GlassCardAppearanceMeasurementProbe.swift`；分析器：`analyze_glasscard_appearance.py`，只需 Python 标准库。
- 运行方式：确认 `Tests/MemoMarkTests/RendererTests/GlassCardAppearanceMeasurementProbe.swift` 不存在，再复制研究 probe 到该位置；用 MemoMarkTests / Debug / platform=macOS / CODE_SIGNING_ALLOWED=YES 执行 `-only-testing:MemoMarkTests/GlassCardAppearanceMeasurementProbe`；以 xcresulttool export attachments 导出。完成后仅在 cmp 确认与研究源一致时移除临时复制文件。
- 若仅运行一个 Swift Testing 方法，必须使用完整 identifier，如 `-only-testing:MemoMarkTests/GlassCardAppearanceMeasurementProbe/fontScaleMetrics()`；省略括号曾得到 **TEST SUCCEEDED 但 0 tests**，该次不算验证。
- 像素/fit probe：`/tmp/MemoMarkGlassCardAppearance-2026-10-01.xcresult`，2 个 probe 通过。
- 字体 probe：`/tmp/MemoMarkGlassCardFontMetrics-exact-2026-10-01.xcresult`，1 个 probe 通过。
- 稳定数据、PNG、日志：`$HOME/Documents/Codex/2026-10-01/GlassCardAppearance/`；24 像素行、576 fit 行、6 字体行，合成素材无私人照片。
- 本轮未修改生产源码或上一片测试；临时 probe 已移除。macOS test build/运行通过，diff 检查通过；未运行全量测试、iOS probe、真机视觉、Photos 保存回读、HDR 或 Instruments。三个 probe 通过只代表测量完成。
- agent-reach Jina 读取未返回正文，随后使用 web 工具读取 W3C 和 Apple 官方资料；Materials HIG 页面要求 JavaScript，系统材质结论以可读取的 Apple WWDC25 transcript 支撑：[Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)。
