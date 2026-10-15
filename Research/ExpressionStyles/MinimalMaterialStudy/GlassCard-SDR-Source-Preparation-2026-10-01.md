# GlassCard 研究源准备与方向映射

Engineering Loop，P2。前片准入检查不能证明调用者up声明；本片在研究侧提供ImageIO数据入口，记录实际EXIF方向、解码后尺寸及画布映射。生产代码、Metadata、原片、Minimal、Photos、Live Photo不变。

源准备先读ImageIO方向/尺寸，拒绝方向缺失或不在1...8；只允许明确的受控SDR测试来源。用ImageIO thumbnail transform归一，缩放上限原始长边；仅接受明确sRGB输入，工作输出为8bit sRGB。随后显式选择exact或centered aspect-fill画布，报告drawRect；Layout在该画布上提供ROI。透明源仍拒绝，不加铺底。HDR来源识别不在此入口中完成，controlledFixture标签不可作为生产HDR鉴别结果。

所有者：研究源准备负责方向/坐标映射与处理报告，原准入负责normalized raster条件；共享准入实现避免重复。测试用非对称四角色块TIFF，独立预期表检查全部八方向，而非从被测API生成预期。exact尺寸不符、未知方向、P3、透明、非法画布拒绝。aspect-fill用独立红色中心带验证中心裁切，并报告裁切范围。测试app/test build后保留研究源、移除临时副本。

Apple能力：ImageIO方向transform及CoreGraphics显式sRGB画布。风险包括双重旋转、镜像错误、CG上/下坐标混淆、无意缩放、透明premultiplication、错误色彩声明；本片不引入Renderer-owned几何。

## 已执行的方向与映射结果

4项macOS测试在 `/tmp/MemoMarkGlassPreparationGreen.xcresult` 实际通过，零失败/跳过，包括原准入回归。八方向均与独立四角预期表相等：1...4输出60×40，5...8输出40×60；orientation=6的旋转与orientation=7的旋转镜像分别独立检查，没有用尺寸替代像素位置断言。60×40中心带填充40×40时drawRect=(-10,0,60,40)，内部像素均为红色；exact拒绝同一尺寸不符案例。P3、透明与非整数画布拒绝通过。

第一轮 `/tmp/MemoMarkGlassPreparation.xcresult` 为2通过/2失败：ImageIO不透明TIFF解码会采用省略alpha的格式，直接送strict admission产生unsupportedPixelFormat。修复在准备阶段显式转为8-bit sRGB RGBA存储，并保留透明alpha后再检查；没有放宽最终准入。原文件没有改写。原始方向CSV本地保存。

共享准入现已提取到 `GlassCardSDRResearchSource.swift`，原 `GlassCardSDRSourceAdmissionProbe.swift` 仅保留测试，重放需同时加入该共享研究文件。`prepareControlledFixture` 明确限制canvas单边≤4096，只供受控小尺寸实验，非48MP生产预算。原始float输入在转换前拒绝，避免把float源偷偷归一为8位成功。

## 端到端研究合成

新增 `GlassCardSDRLuminanceProbe.preparedComposition()`：带EXIF6的384×216受控亮棋盘TIFF→ImageIO正向216×384→准入→Layout明确ROI→blur(panelH×0.025)→soft knee c=0.12→clear surface、white0.96 Overlay→真实artifact compositor。记录encoded/normalized/canvas/drawRect、半径、cap和fixture来源；检查布局fit、源处理掩膜外像素保护、blur halo参考以及最终尺寸。

最后一步仍为现有DeviceRGB compositor；中间sRGB规范不能被报告成最终显式sRGB输出认证。源准备记录只证明这条ImageIO研究路径，未验证UIImage fallback/平台全方向、原始HDR识别、Photos资源链、逐帧Live Photo、峰值内存或真实设备。


端到端 targeted probe在 `/tmp/MemoMarkGlassPreparedComposition.xcresult` 实际执行1项通过，零失败/跳过，app/test build完成。blurRadius=0.9828，所有坐标/尺寸报告保存；合成图已查看，底栏限定于预期下部。此小尺寸合成图用于连通/坐标检查，不用于字体阅读验收；也没有重跑上一轮144行材质矩阵。输出在 `$HOME/Documents/Codex/2026-10-01/GlassCardSDRPreparation/`。四个临时研究测试文件均与保留源比对后移除，`git diff --check`通过。生产未改、未提交/推送。

下一有边界工程片：为研究入口建立显式sRGB最终合成对照，不替换全局生产compositor；对齐相同源/Overlay并验证输出标签、同坐标对比、ROI外差异和透明语义。明确最终输出颜色后，再测一组实际输出尺寸/缩放候选。
