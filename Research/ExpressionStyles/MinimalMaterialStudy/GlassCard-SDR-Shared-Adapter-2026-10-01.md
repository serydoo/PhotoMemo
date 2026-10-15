# GlassCard 共享 SDR 研究适配器

Engineering Loop，P2，行为保持的研究代码提取。ROI blur、soft knee、像素读取重复嵌入luminance probe；已取得方向/色彩/实际writer证据，需要单一可复用实现。提取前的final-color CSV/PNG为回归基线，生产源码/默认/持久化/Photos/Minimal不变。

职责：源准备负责方向/画布与来源报告；material处理消费Layout提供的panel；adapter消费已准备源与resolved presentation，绘制Overlay并显式sRGB合成；writer仍是实际生产writer。算法不新增布局推导，不自行改变文本fit或徽标位置。保留全帧参考/掩膜检查作为研究控制，不声称优化或离UI actor运行。

显式参数：blur panelH×0.025，cap0.12，secondary opacity0.96；构造入口拒绝非有限/越界参数、画布不符及内容溢出。文本为空的plan只用于无字背景研究对照，非production成功输出。输出属性策略仅对明确sRGB图像将EXIF ColorSpace写1、profile name由编码图像产生；保留其他来源metadata并交实际writer处理，不改全局writer及HDR/P3行为。

验证：提取后重跑final-color矩阵，比较提取前CSV与PNG；adapter输出与显式手工组合逐字节比较；参数/画布/溢出拒绝；调用实际writer HEIC确认输出color1及所列metadata保持。macOS app/test build及diff检查；临时文件比对移除。避免机械新增ADR，研究未改变生产所有权。

## 实现边界

`GlassCardSDRResearchMaterial.swift`不导入Testing，分配失败与源保护失败抛出明确错误；原probe保留薄包装，既有调用/指标语义保持。圆角半径由adapter或probe从Layout specification取得后显式传入kernel，kernel不推导半径。完整参考与mask控制保留，不能将其称为生产优化kernel。

`GlassCardSDRResearchAdapter.swift`消费Prepared+resolved plan。输出同时保留processedSource、artifact和final image以及源准备报告/参数/裸halo字节，这是研究witness，不是生产内存模型。ImageRenderer所在入口为MainActor，当前同步pixel处理仍是研究行为；实际采用前需拆出非UI像素处理与生命周期/取消/内存所有者，不能原样用于48MP或视频。

新outputProperties策略仅在cgImage明确sRGB时将EXIF色彩值设为1，并移除继承ProfileName让图像编码空间产生profile；保留其他属性，随后由实际writer继续尺寸/方向/Live Photo静态清理/描述处理。P3图像被该策略拒绝，不修改其metadata。它不承诺清理来源中所有ICC/XMP/auxiliary属性，也不能替代真实HDR识别。

首轮提取遇到Swift guard trailing-closure语法编译失败，补充表达式括号后通过；`/tmp/MemoMarkGlassSharedAdapter.xcresult`实际2项通过。后续圆角显式输入调整后执行最终回归。

## 最终回归与闭环

`/tmp/MemoMarkGlassSharedFinal.xcresult`实际执行finalColorComparison/sharedAdapter共2项通过、零失败/跳过，app/test build完成。1080×608矩阵32行CSV及final-sdr-checker.png与提取前 `GlassCardSDRFinalComposition` 原件逐字节相等；SHA256和结果存入extraction-parity.json。最低核心5.0012386/最低P10 5.5922399保持。

Adapter与显式手工组合sRGB像素逐字节相等；NaN参数、异画布plan、真实长文本溢出分别拒绝，P3输出属性策略拒绝。新metadata策略→实际writer→HEIC回读空间sRGB、EXIF ColorSpace=1、所列原始拍摄时间与GPS保持。没有给P3/未知profile或HDR输入套用此策略。

源准备/材质/最终合成3层共享实现均保留；luminance probe移除了6段算法本体，以薄包装调用。原有研究probe中的旧实现作为历史独立证据保留，本片未批量改动其他研究文件。不把research adapter加入production目标，不新增持久化参数或改变默认。

5个临时测试文件与保留源比对后移除，`git diff --check`通过。数据/图/HEIC在 `$HOME/Documents/Codex/2026-10-01/GlassCardSDRSharedAdapter/`，包括完整回归摘要及parity校验。无Simulator、新真机/Photos/HDR/Live Photo或性能验收，未提交/推送。下一片可用共享入口测量最终编码图的实际尺寸/缩放，替代继续复制材质逻辑；生产接入仍需材质与媒体契约、UI actor拆分、大图内存、真机及Photos证据。
