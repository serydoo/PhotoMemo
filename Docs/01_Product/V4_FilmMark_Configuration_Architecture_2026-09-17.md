# FM 配置与呈现系统架构规格

状态：实现前规格，基于 2026-09-17 用户截图反馈与 Chat On Steroids Core 只读审查复核。

## 目标

FilmMark（FM）是 V4 正在搭建的表达样式能力。它需要在继续扩展之前先建立健康的内容、样式、布局、预览和导出关系，避免把旧 Template 当作 FM 的隐式内容来源，也避免预览和导出各自解释同一份配置。

用户在配置中心中应能看到一个唯一的顶部 FM 主预览，并在预览仍然可见的上下文中完成高频设置：卡片内容、位置、字号、颜色和底色衬托。预设与自定义颜色统一放在主页面；字体、时间与地点进入不带预览的紧凑详情页。顶部预览展示的是统一的 FM resolved presentation；所有输出方向、字号、颜色、底色和时间/地点变化都必须通过同一条配置与解析链反映到预览和导出。

## 前提与边界

- 本规格允许为 FM 重新整理底层职责和载荷，不以保留当前实现细节为目标。
- Classic White、Minimal、Apple Photos、Live Photo、原图保护和既有持久化兼容不因 FM 重构而改变。
- FM 内容仍由 Card Content/Memory Engine 负责解析；FM 只接收已解析的表达内容、样式配置和画布上下文。
- Layout Engine 是位置、安全区、字体测量和底色几何的唯一真相；Renderer 只绘制已解析结果。
- 主配置页的视觉调整不是另一个数据源；它只编辑同一个 FM draft/aggregate。
- `systemGlass` 不能依赖不可导出的系统 Material。若保留为用户可选样式，必须有明确、静态、跨预览与导出的同一 recipe；否则必须降级为不可保存的实验项，而不是静默伪装成已完成能力。
- 预览若继续使用 2:1 校准画布，文案必须明确其为位置校准示意；不得把模拟渐变误称为真实照片效果。

## 目标数据流

```text
Card Content / Memory Engine
        │ 已解析 FMContentProjection
        ▼
FilmMarkPresentationResolver
        │ content + FilmMarkConfiguration + canvas context
        ▼
FilmMarkResolvedPresentation
        ├── Configuration Center preview
        ├── still-image overlay export
        └── Live Photo still/movie presentation adapters
                 │
                 ▼
              Renderer
```

FM 的独立内容载荷必须随配置和生产 snapshot 一起冻结。显式 FM route 缺少独立内容时，生产快照、队列和渲染入口都必须 fail closed；不得回退到通用 `template`。Classic White/Minimal 仍可按既有兼容规则读取旧 Template。

## 配置中心信息架构

主页面顺序固定为：

1. 卡片内容
2. 位置（起始位置 + 精细调整位置）
3. 字号
4. 颜色（居中预设色板及系统自定义颜色）
5. 底色衬托
6. 胶片样式与细节（字体、时间与地点）

“卡片内容”“位置”“胶片样式与细节”使用同一个 FM 一级行布局：标题/说明列、固定 trailing column、值或 disclosure。字号和颜色是直接控制区，仍使用同一标题/副标题内容列；辅助字号允许转为纵向布局，不为了直线而压缩可读文本。

位置区域的普通字号布局为左侧说明、右侧四向控制；每个方向保留至少 44pt 触控区域。复位居中于左侧说明列下方，使用 88pt 宽、28pt 可见高度的胶囊，外层保留 44pt 触控区域，底部与下箭头对齐，不使用负 offset。辅助字号下方向控制可转到说明下方。

底色衬托使用四张自适应视觉选择卡，不使用 segmented control：普通宽度四列等宽；窄宽或辅助字号 2×2。每张卡同时展示名称和不同的实际 substrate recipe：无、纸白、系统玻璃/静态玻璃感、柔和阴影。选中态、VoiceOver value 和导出 recipe 必须一致。

详情页不放第二个完整或缩略 FM 预览，只承载字体、时间与地点，并使用紧凑表单；字号、颜色和底色不再重复出现。原生 sheet 展开时可以遮挡主页面；需要即时预览的高频调整已保留在主页面。

## 架构修复范围

- 提取非 Renderer 的 FM 内容与 presentation resolver。
- 让 Planner 在一次事务中生成不可变 `FilmMarkResolvedPresentation`，Overlay Renderer 直接消费它。
- 让预览和导出共享同一 Layout/appearance 解析，不在 View 内另行复制测量规则。
- 在生产配置工厂和队列快照校验中保护 FM 独立内容载荷。
- 把 `systemGlass` 的预览/导出语义收口到同一个静态 recipe，或在能力未闭合前明确禁用持久化选择。
- 将主配置页的高频 FM 设置从详情页提级，删除重复卡片和不一致 trailing 布局。
- 为空内容、超出安全区、不可用字体和不支持的 substrate 提供可见、可测试的失败状态；不能用硬编码示例遮盖空内容。

## 测试与验收

自动化至少覆盖：

- FM 独立内容保存、重载、生产 snapshot、Share transport 的完整冻结与缺失 fail-closed。
- resolver 只产生一份 presentation；preview/export 使用同一 canvas、geometry、typography 和 substrate recipe。
- 横图、竖图、极端长文本、空内容、四种底色、四档字号、颜色和左右落点。
- Classic White/Minimal 路由与旧 Template 兼容不回归。
- 主配置行 trailing column、动态字体纵向降级、44pt 方向按钮和 88pt 宽复位按钮的源码/行为契约。

验证命令：

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -list
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMark -configuration Debug -derivedDataPath /tmp/MemoMarkDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark.xcodeproj -scheme MemoMarkTests -configuration Debug -derivedDataPath /tmp/MemoMarkTestsDerivedData CODE_SIGNING_ALLOWED=NO test
```

工程验证后必须使用配对的实体 iPhone 17 Pro Max 检查浅色/深色、辅助字号、VoiceOver、横竖照片、方向微调、复位、保存重开、详情无重复预览及关闭后主预览恢复，并分别检查静态图与 Live Photo 的输出、原图保护和目标相册。原生详情 sheet 可以遮挡主页面。构建、安装、启动不能替代这些手动验收。

## 暂不提前承诺

- 尚未经过字体资源、许可证和 CJK fallback 验证的第三方字体不开放为可选字体。
- 不把系统 Material 的运行时背景依赖伪装成可确定的导出效果。
- 不在详情页保留第二视觉权威。
- 不把当前截图中的固定模拟背景当作真实照片渲染能力。
- 不把这次 FM 基础重整扩展成批处理工作台、云端照片功能或旧主流程恢复。
