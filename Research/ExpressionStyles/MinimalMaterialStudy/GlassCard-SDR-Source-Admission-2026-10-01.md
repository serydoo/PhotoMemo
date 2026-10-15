# GlassCard 静态 SDR 研究输入准入

## 实施前决策

Engineering Loop，P2，研究工具边界，不更改生产导出。证据：RecordCardExportPipeline 优先 CGImageSourceCreateThumbnailWithTransform=true，fallback 取平台图像 CGImage；MemoMarkRenderedImageArtifactGuard 使用 8-bit DeviceRGB、aspect-fill、没有源响应材质输入契约。不能据此认定方向、sRGB、HDR语义已经满足新算法。

所有者：研究 composition adapter 的 admission，Layout继续拥有 panel/ROI。输入CGImage不带EXIF方向保证，调用者必须提供可信的 normalized orientation；尺寸与画布必须一致，不做裁切/重采样。工作范围仅明确sRGB、8-bit整数、32-bit RGBA、opaque像素。颜色转换/透明铺底/方向归一由独立前置阶段证明，不由材质猜测。Apple原生CGImage声明及CGContext只用于受控验证。

风险：误把P3或未标记图像当sRGB、把premultiplied透明RGB直接用于亮度函数、旋转后ROI错位、把HDR降到8位却宣称保留。拒绝必须有类型化原因，无输出成功fallback。这不改变现有生产对上述输入的处理能力。

验证：合法sRGB接受；P3、gray、float、错误尺寸/非有限画布、非up方向拒绝；真实透明像素拒绝、含alpha但全部opaque接受、skip-alpha格式拒绝。不得以bitsPerComponent=8证明原文件无gain-map；仅接受显式声明为研究SDR栅格，源文件HDR鉴别仍独立。

## 源码核查结论

- `RecordCardExportPipeline.imageIOExportImage`通过ImageIO thumbnail transform归一方向；方向证据来自该操作，不能从CGImage尺寸推断。
- `sourcePhotoCGImage` fallback至`PlatformImage.photoMemoExportCGImage`，iOS分支直接返回UIImage.cgImage；此getter自身不消费UIImage.imageOrientation。上游可能已经归一，但此处没有显式结果契约。本片不认定所有fallback都错，也不扩展为全路径修复。
- 现有compositor会aspect-fill且使用DeviceRGB。研究算法ROI基于输出坐标，因此须先得到同画布源栅格，再处理ROI，不能直接套用原始源坐标。
- CGImage不携带完整文件gain-map/资源历史；name=sRGB与8bit只说明当前栅格格式，不能证明来源从未HDR。admission是调用边界校验，不是媒体资源鉴别器。未来adapter必须携带可信来源/转换记录。
- 本片接受只限premultipliedLast 32bit格式并检查所有alpha=255，故没有unpremultiply/铺底语义；其他合法opaque格式也暂拒绝，由前置规范明确转换后再接入。
- orientation参数是调用者声明；它能拒绝未归一的声明，不能证明像素视觉方向。未来需要非对称定位图的ImageIO/平台fallback全方向测试。

下一实施片必须把源准备与材质处理组合成研究入口，固定归一策略并输出处理报告；不能仅凭这组准入测试接入production。当前扫描为整帧研究检查，无48MP性能/峰值内存声明。

## 验证

`/tmp/MemoMarkGlassAdmission.xcresult` 实际执行2项macOS测试通过，零失败/跳过，app/test build完成。拒绝用类型化原因断言，合法opaque源返回同一个CGImage对象，没有转换或修改源。临时测试副本与研究源比对后移除；`git diff --check`通过。生产源码本片未改变，未进行Simulator、真机、Photos、HDR、Live Photo或性能认证，未提交或推送。


2026-10-01 后续：准入实现提取至共享研究文件 `GlassCardSDRResearchSource.swift`，本probe只保留测试；复现需一并加入共享文件。新增ImageIO准备和八方向验证见 `GlassCard-SDR-Source-Preparation-2026-10-01.md`。原拒绝边界保持，4项准备/准入回归通过。
