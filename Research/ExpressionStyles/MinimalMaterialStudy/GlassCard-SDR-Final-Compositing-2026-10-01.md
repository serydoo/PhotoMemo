# GlassCard 显式 SDR 最终合成研究

Engineering Loop，P2；研究侧闭合前片最终DeviceRGB边界，生产compositor/导出/Photos不变。源码依据：MemoMarkRenderedImageArtifactGuard当前为8bit DeviceRGB+aspect-fill；source preparation已经明确归一与画布映射。研究compositor只消费已准入的同画布opaque sRGB源及renderer-neutral artifact，不做二次缩放、旋转或源映射，拒绝非全画布photoFrame及无效layer。

工作/输出固定8bit sRGB RGBA；保留artifact zIndex及opacity，以CoreGraphics normal blend绘制layer。Layout继续拥有layer frame/ROI；不增加glassCard样式分支。不透明源背景上透明overlay自然混合，不增加铺底。Overlay的声明色彩空间由CG绘制转换到sRGB，报告原layer空间；不假定ImageRenderer固定为sRGB。

验证：受控源与同一Overlay，比较现有DeviceRGB与研究sRGB合成的同坐标字形核心对比、全图字节差异、输出空间；图层范围上方源像素逐字节保护；显式PNG编码回读标签/字节；独立半透明红色覆盖蓝底的alpha与blend检查、zIndex/opacity语义、无效映射拒绝。标准文字材料为c=0.12/white0.96，1080×608研究画布，保留compatible1.4排版。新矩阵为8源×4slot=32行；不是重新认证全部144行或实际照片/HDR/Live Photo。测试build完成后保留研究源、移除临时副本。

风险：命名sRGB不代表线性光混合；CG normal blend是本研究确定的8bit sRGB绘制语义，HDR/extended/linear blend另立规范。PNG回读不替代生产MetadataPreservingImageWriter的JPEG/HEIC+EXIF标签生命周期或Photos认证。

## 实测与处理决定

8个受控源×4位置共32行，两个compositor的输出通过同一个显式sRGB读取context比较，最大归一字节差为0，同坐标核心对比差为0。这里不是比较不同颜色声明的原始provider字节，也不能证明任意Display P3/设备或全部生产路径等价。

| 项目 | 结果 |
|---|---|
| 现有输出colorSpace.name | kCGColorSpaceDeviceRGB |
| 实测ImageRenderer Overlay空间 | kCGColorSpaceSRGB |
| 研究输出colorSpace.name | kCGColorSpaceSRGB |
| PNG解码colorSpace.name | kCGColorSpaceSRGB |
| 最低核心对比 | 5.001239，红色控制 |
| 最低P10 | 5.592240，绿色控制 |
| 低于4.5的组 | 0/32 |
| PNG无损回读差异 | 0，全部样本 |
| Overlay范围上方源像素差异 | 0，全部样本 |

本轮1080×608有独立字形采样和较小模糊半径，结果不能要求与1920×1080的5.037相等。本片未重跑横向缩放/实际字体阅读矩阵。输出图已保留，未取得物理设备视觉验收。

独立像素控制证明：半透明premultiplied红覆盖opaque蓝与opaque红layer.opacity=0.5在1字节容差内相等，输出alpha255；不同zIndex按顺序覆盖；opacity0跳过；opaque源下canvasBackground两值结果相同。photoFrame非全画布和超界secondary layer分别拒绝。

保留显式sRGB研究compositor作为后续受控SDR实验基线，不替换生产全局合成器。下一片应把同一输出送进实际MetadataPreservingImageWriter，验证PNG/JPEG/HEIC及metadata回读；writer当前从sourceProperties拷贝再清理/覆盖指定字段，颜色标签、EXIF色彩与新工作输出是否一致需实际验证，不能从裸PNG编码成功外推。之后再重跑输出尺寸/缩放矩阵，最后用真实设备及Photos取得验收。

## 验证闭环

- `/tmp/MemoMarkGlassFinalColor.xcresult`：targeted矩阵probe实际执行1项通过、0失败/跳过。
- `/tmp/MemoMarkGlassFinalControls.xcresult`：独立blend/geometry实际执行2项通过、0失败/跳过。
- app/test build完成；分析器验证32行、键唯一、源保护及PNG roundtrip；`git diff --check`通过。
- 4个临时测试文件与保留源比对后移除。研究代码/分析器保留，CSV、JSON及PNG位于 `$HOME/Documents/Codex/2026-10-01/GlassCardSDRFinalComposition/`。
- 未改生产代码、未运行Simulator、未提交/推送，无新真机/Photos/实际writer/JPEG/HEIC/HDR/Live Photo认证，无BP-001性能认证。
