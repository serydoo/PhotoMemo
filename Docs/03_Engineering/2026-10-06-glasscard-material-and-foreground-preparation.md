# GlassCard 材质与性能优化 — 2026-10-06

## 范围与结果

本轮接续已接受的右侧锚点布局，只改共享原生材质和视频指令的不可变前景准备。Minimal、持久化schema、配对身份、音轨逻辑、Photos写入与HDR能力限制均保持原状。无新Renderer、无缓存全局状态，未暂存、提交或推送。

材质最终保留系统regular玻璃，玻璃层覆盖强度由默认1降至0.88，使原照片更多参与呈现。该值是合成覆盖强度，不是从竞品测出的物理透明率；白色文字/Logo不受此透明度影响。系统仍负责背景磨砂、折射及边缘光效。共享NativeBackdropMaterialCanvas使预览/still/motion使用同一规则。旧系统兼容材质未改。

参考素材同时存在透明和磨砂样式，未取得同背景无遮挡源图，不能证明某个alpha唯一正确。clear候选分别试过局部压暗、系统tint和合成组，均在Configuration Center预览一致性测试中产生4级像素偏差，超过既有3级界限。候选已撤回，测试阈值没有放宽；不以通过视觉候选为由放弃parity。Apple关于clear可读性的要求见 https://developer.apple.com/documentation/swiftui/glass/clear 。

性能：NativeBackdropVideoInstruction创建时一次性排序图层、创建CIImage并设置opacity/缩放/平移，每帧只执行与当前画布的叠加。缓存仅随不可变指令存在，引用图像不复制整张bitmap。照片与玻璃仍逐帧取样；取消和完成的单一回调所有权未改。没有跨源复用玻璃patch或改变HDR色彩路径。

## 验证

54项targeted tests全部通过，参数执行共59次，0失败/跳过/运行时警告。测试包括玻璃输出/预览一致性、输出几何、逐帧背景变化、方向变换、非中央still-image-time、HDR/P3入口限制；新增三层不同zIndex/opacity、分数变换、三种背景的像素等价测试。原算法与预处理算法输出bitmap逐字节一致。

局部成本测量：Debug/macOS测试环境，三层fixture、1000次图构建，原35.467916ms，预处理8.951375ms，约减少74.8%。包括构图及extent求值，不包含GPU raster、玻璃生成、编码、Photos保存和指令首次初始化；不能据此声称整段导出快四倍，也不是设备基准。没有加入时间阈值断言。

结果：`/tmp/GlassCardMaterialFinal-20261006.xcresult`。首次并行启动iOS构建被Xcode共享build.db锁拒绝，已改为测试结束后顺序构建。顺序重跑iOS Debug generic-device未签名构建成功：`/tmp/GlassCardMaterialFinalIOS-20261006.log`。未安装设备。已有测试夹具使用AVAssetReader旧API的编译弃用警告未在本轮迁移。

## 实际改动文件

- NativeBackdropMaterialRenderer.swift：仅玻璃层覆盖强度。
- NativeBackdropVideoCompositor.swift：不可变前景按指令准备，取消/完成流程不变。
- LivePhotoVideoCompositionServiceTests.swift：像素等价回归与局部成本附件。

## 仍需真机验证

- 明暗、复杂纹理和人物背景下白字可读性与原生玻璃边缘；素材并非单一透明度，当前是有边界的默认调整。
- still与关键帧的材质观感及Photos播放切换；自动化不等于真机视觉验收。
- 大分辨率导出时间、MainActor玻璃耗时、峰值内存、温度。full-canvas RGBA8转换与原生ImageRenderer仍逐帧执行，是下一轮测量重点。
- HDR/P3拒绝提示与队列恢复。本轮仍为SDR能力，没有新增自动fallback或HDR保真支持。
