# GlassCard 开发基础回流核对

2026-09-30。范围：第四 renderer 的开发基础；正式产品注册另行验收。

## 当前代码

已将四区域内容投影、Layout 固定锚点、CoreText 文字适配、固定透明层配方、研究 renderer、Memory Engine 内容桥接及 DEBUG 外观页接入 main 工作区。尚未 Git 提交或推送。Minimal 已正式回流，保留原有未提交改动；既有宣传、研究、配置文件未覆盖。

主线研究入口：Debug 启动参数 `--glasscard-prototype-review`。`--glasscard-long-text-review` 提供溢出样例，`--glasscard-artifact-review` 自动尝试固定透明层静态合成。renderer、内容桥接和研究页受 DEBUG 条件限制，未注册新的生产样式或持久化键。

四区域代表位置，内容含义继续由既有 TemplateItems / CardTextBlockEngine 定义。徽标锚点不依赖字段内容。53% 等精确数值及明暗材质仍是研究候选。

纯空白被识别为空，但不重写投影中的原始文案。提示与样例导出复用适配测量；已知溢出、全空、系统材质及旧左侧徽标构图不导出成功样例。全空正式产品规则尚待定案。

## 五维代码审查

- 正确性：固定锚点与比例缩放已有覆盖；增加纯空白和长文溢出覆盖。导出入口拒绝已知不完整内容。CoreText 与 SwiftUI 使用同一系统字体对象；仍需要跨平台像素和多语种矩阵核对。
- 可读性：只新增 GlassCard 文件和小范围 Debug 入口；错误路径显式提示。候选名称保持研究语义。
- 架构：位置投影不依赖 RecordCard；模板桥接属于 Memory Engine；几何来自 Layout。未改动生产 planner、配置、Share、Batch、PhotoKit 或 Live Photo exporter。
- 隐私：仅本地读取临时目录中的指定研究照片，生成临时样例；未上传照片或将私人素材复制到仓库。
- 性能：每字段二分查找最多 12 次；当前研究页面同步测量存在重复计算，暂只允许开发用途。正式接入前需冻结一次 resolved render plan 并复用，测量大图与长文成本。

## 必要后续

1. 核对 main 的定向测试、Debug 与 Release 构建；安装 main Debug 包到本地模拟器，确认入口与溢出失败路径。
2. 在研究分支冻结外观候选：统一材质、边框、字重字号、四区域及徽标净空；完成横竖、明暗、多语、空值矩阵。
3. 形成生产 presentation / configuration / artifact 契约后，按四区域既有编辑能力接入正式预设。正式入口需本地化、无障碍、配置兼容与输出一致性。
4. 真机检查静态保存、Photos 回读与 Live Photo 配对、关键帧、音轨、方向、色彩。独立 Core Image 普通视频实验不构成 Live Photo 验收，不据此替换生产视频路径。

本次基础回流不表示外观已冻结，也不表示新增第四样式已可供正式用户保存。

## 本轮最终核对

- main 定向测试：7/7 通过（macOS）；研究分支同组 7/7 通过。
- main MemoMarkiOS 最终 Debug / Release Simulator 构建：通过。Release 包符号检查未发现研究 View、renderer 或内容桥接的符号；结合源码 DEBUG 条件确认排除边界。
- main Debug 包已安装/启动于本地 iPhone 17 Pro Max / iOS 26.5 模拟器；未安装到实体设备。
- 短文固定透明层：成功合成 1080×1440，AX 及截图确认样例展示。
- 长文：AX 与截图确认“样例未生成：左上文字超出边界”，未展示成功合成结果。
- git diff --check：通过。未进行全量测试、App Store 交付或 PhotoKit/Live Photo 验收。

本轮开发基础回流清单已完成。外观精确参数冻结与生产接入属于后续验收阶段；当前主线默认路径仍沿用已有正式样式。研究分支继续作为外观与媒体实验的独立工作区。
