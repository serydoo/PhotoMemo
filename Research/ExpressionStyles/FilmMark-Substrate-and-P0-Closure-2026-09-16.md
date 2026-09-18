# FM（FilmMark）承载底材与 P0 收口规格

**日期：** 2026-09-16
**产品阶段：** V4.0 Research And Product Definition
**状态：** 本轮架构复核与 P0 修复依据；底材生产开放仍需 Product Design Review 与媒体验收

## 1. 本轮决定

FM 的展示区域不再只理解为“文字叠加层”，而是一个由 Layout Engine 解析的
`content layer + substrate layer` 组合。底材（substrate）负责承载文字的视觉
可读性与表达气质，不能拥有 Memory Engine 语义、时间锚点或图片位置策略。

用户的构思成立，但必须区分两种“玻璃”：

1. **交互预览材质**：可以使用当前系统可用的原生材质来帮助用户感受层次；
2. **输出底材**：必须在当前照片上解析为确定的静态图层，并同时进入静态图片和
   Live Photo still/movie 的输出合同。

不能把不可 Codable、依赖系统版本和运行环境的 SwiftUI `Material` 直接当作
Photo Library 输出结果。否则预览与保存结果无法形成稳定合同。

## 2. 底材模型

FM 的底材应是独立的、版本化的纯值配置，和内容、字体、颜色、位置分离：

```swift
struct FilmMarkSubstrateConfiguration: Codable, Hashable {
    var kind: FilmMarkSubstrateKind
    var padding: FilmMarkSubstratePadding
    var cornerRadius: FilmMarkSubstrateCornerRadius
    var opacity: Double
}
```

第一版建议保留以下语义：

| kind | 预览 | 输出 | 说明 |
|---|---|---|---|
| `transparent` | 仅显示 FM 输出 | 仅输出文字/装饰层 | 不生成底色，不改变照片 |
| `paperWhite` | 白色承载窗口 | 确定性的白色 raster layer | 类似极简展示窗口，但不复用 Minimal 布局 |
| `systemGlass` | 系统材质感 | 当前照片上的确定性玻璃配方 raster layer | 需 OS availability、对比度和色彩验收 |
| `softShadow` | 透明底 + 阴影 | 确定性的阴影效果 | 作为现有兼容选项继续单独验证 |

`systemGlass` 不应持久化 SwiftUI `Material`、系统私有对象或某个操作系统的
内部实现名称。应持久化稳定的应用内语义 ID，并在渲染时解析为：

- 背景取样/模糊半径；
- tint 色与 alpha；
- 边缘高光与阴影；
- 圆角与内边距；
- sRGB 或明确的输出色彩空间；
- 当前系统不支持时的显式降级策略。

如果暂时不能为玻璃定义可重复的静态 recipe，则它只能是 preview-only，不能
作为可保存的生产输出选项。

## 3. 所有权与数据流

```text
Card Content
    -> resolved text
FM Layout Engine
    -> text bounds + substrate bounds + placement
FM Renderer
    -> resolved text/substrate layers
PresentationArtifact
    -> static image / Live Photo still + movie
```

- Card Content 决定显示什么；
- Layout Engine 决定文字和底材的完整矩形、safe area、anchor 和 overflow；
- Renderer 只消费已解析的文字、底材和几何；
- Export/Photos 继续拥有新资源写入、元数据和配对生命周期；
- Classic White / Minimal 不共享 FM substrate 状态，也不迁移到 FM 坐标协议。

底材矩形必须由同一份 resolved presentation 产生。不能在 Preview 中给文字加一
个本地 padding，又在 Export 中由 compositor 重新推导一份底材大小。

## 4. 产品层级

FM 首页继续保持：

```text
Time Anchor
Card Content
字体 / 字号 / 颜色
底材形式（透明 / 白色 / 可用的玻璃）
更多设置
  - 位置与细节
  - anchor 起始位置
  - 方向微调
  - substrate 细节与恢复默认
保存位置
照片说明
```

“透明 / 白色 / 玻璃”是形式选择，不应把底材的每个参数全部展开在首页。
圆角、内边距、玻璃强度、对比度提示和恢复默认属于二级细节；只有经过真实
照片可读性验证的选项才可以开放。

预览应继续采用紧凑校准窗口，但必须显示实际的 FM output、底材状态和明确的
空内容状态。它不是第二个独立编辑器，也不能重新计算另一套位置。

## 5. 媒体与 Apple 平台边界

- 透明底材是最安全的第一默认能力：照片像素不被底色覆盖，只新增 FM 输出；
- 白色底材必须验证亮部、肤色、夜景和透明度边界；
- 系统玻璃的交互表现与导出表现必须分开验证；
- 静态图和 Live Photo 的 still/movie 必须使用同一 resolved substrate recipe；
- 不允许把实时 UI 材质作为 Live Photo 的动态依赖；
- 输出始终是新资源，原始 PHAsset 不修改；
- metadata、orientation、P3/HDR、HEIC 与 Live Photo pairing 仍按各自媒体合同
  验收，不能因底材选项存在就默认通过。

## 6. 本轮 P0 收口要求

### P0-A：Preview/Export 原点统一

`FilmMarkCardOverlayLayerRenderer` 的全画布 frame 必须显式使用
`.topLeading`，与 Preview 和 `FilmMarkCardRenderer` 共用同一原点。底材接入
不得复制第二套 offset 或 Y 转换。

### P0-B：Durable route/payload fail-closed

持久化解码必须区分：

- 缺少 route：保留历史 Classic White 兼容；
- 显式未知 route：失败闭合；
- 非 FM route 缺少 FM payload：允许兼容默认；
- 显式 FM route 缺少 FM payload：失败闭合。

Batch、Share 和 production snapshot 的已有校验继续保留，不能由 durable decoder
提前把 malformed 状态抹平。

## 7. 验收门槛

P0 修复后必须完成：

1. overlay top-leading source contract 与 preview/export parity 测试；
2. unknown route、FM missing payload、legacy missing route 三组 persistence 测试；
3. MemoMark macOS focused tests；
4. MemoMarkiOS 与 Share Extension build；
5. 签名 iPhone 17 Pro Max 上的透明/白色静态输出；
6. 在底材未通过对比度、颜色、Live Photo 和原图保护验证前，不开放 `systemGlass`
   生产输出，只允许作为实验性预览或保持不可选。

本规格不授权修改 Classic White / Minimal，也不授权提交、推送、TestFlight、
App Store Connect 或其他外部发布动作。

## 8. 截图复核后的配置层级收口

2026-09-16 的真机截图暴露出一个独立于渲染 P0 的配置中心问题：FM 首页同时出现
“卡片内容”二级菜单规格、位置右侧下拉与重复进入按钮，以及字体、字号、颜色等
本应属于细节编辑的控件。点击位置细节后还会打开覆盖预览的全屏页面，导致预览与
编辑上下文断开。

本轮将 FM 首页收口为两条清晰的入口：

```text
FM 主配置页
  -> 卡片内容                 （唯一内容入口）
  -> 胶片样式与细节             （唯一样式/细节入口）

胶片样式与细节（二级页）
  -> 位置与底色
  -> 起始位置与方向微调
  -> 字体 / 字号 / 颜色
  -> 表达方式
  -> 时间与地点
```

这不是把编辑职责搬进 Renderer，而是收紧 Configuration Center 的投影边界：

- `ConfigurationOptionList` 只负责呈现入口与导航，不再直接展开 FM 细节控件；
- `FilmMarkConfigurationControls` 是二级页唯一的 FM 样式编辑容器；
- `FilmMarkPositionDetailsContent` 只负责在该容器内呈现位置、微调和底色，不再
  自己创建第三个全屏编辑器；
- 所有控件仍通过根配置 draft 的 Binding 写回，预览继续读取同一份运行时快照；
- FM 二级页使用紧凑 sheet detent，并允许用户主动展开，不以全屏细节页遮断预览；
- Classic White / Minimal 继续沿用既有 `cardLayout` 分组与入口，不共享 FM 的
  层级状态。

因此，截图中“同一功能有下拉和相邻按钮”“主页面完整展开二级设置”“细节页遮住
预览”三类问题分别由唯一入口、二级页归属和紧凑 sheet 三条结构约束解决。截图仅
作为当前行为证据，不作为像素临摹目标。

## 9. 2026-09-16 实现收口记录

本轮实现保持旧 `FilmMarkSubstrate` raw value 不变，并新增：

- `paperWhite`：导出确定性白色衬底；
- `systemGlass`：预览使用系统材质，导出解析为 `paperWhite`，不把实时材质带入
  静态图或 Live Photo；
- `FilmMarkLayoutSpecification` 计算衬底内边距与 `substrateFrame`，文字 frame
  保持为其内部内容 frame；
- layer-only `PresentationArtifact` 明确采用 `.floating` 兼容语义，允许 FM
  全画布 layer 与 photoFrame 重叠，避免误走 legacy footer 校验。

这意味着 Preview、静态 artifact 和 Live Photo 继续共享 FM 的 resolved layout，
而不是让媒体管线按样式重新推导底材几何。旧的 `none`、`softShadow` 和
`translucentLabel` 编码值继续可解码；本轮没有改变 Classic White / Minimal 的
持久化或生产 snapshot 形状。
