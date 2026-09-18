# FM（FilmMark）Renderer 可落地规格

**日期：** 2026-09-14
**产品阶段：** V4.0 Research And Product Definition
**状态：** 待 Product Design Review；本文件是可实现规格草案，不直接改变生产代码
**协作工具：** COS = Chat On Steroids
**功能简称：** FM = FilmMark

## 1. 目标与非目标

FM 是一个独立的 Expression Style Renderer，用于把拍摄时间和 Memory
Engine 的时间结果，以可调整的胶片时间标记形式叠加到新生成图片上。

FM 的第一版目标：

- 在现有 Configuration Center 中提供独立的样式选择和配置表面；
- 让用户在一个输出窗口中组合普通文字、拍摄时间和时间锚点结果；
- 让用户通过上下左右方向键进行可重复、可访问、可持久化的精细定位；
- 让用户选择受许可证约束的字体、字号和任意自定义颜色；
- 在一张大图上实时显示 FM 输出结果相对于图片的位置；
- 让预览和最终导出使用同一份已解析的布局输入；
- 保持原始照片不变，输出仍然是新生成的图像或现有支持的配对资源；
- 保持本地优先，不上传照片，不把 COS 或任何第三方服务放入照片处理链路。

FM 明确不做：

- 不修改 Classic White 或 Minimal 的任何布局、方向分支、导出尺寸或持久化行为；
- 不把现有两个 Renderer 迁移到 FM 的坐标模型；
- 不创建独立的 Workspace、批处理面板、导入流程或通用图片编辑器；
- 不让 Renderer 解析 Memory Engine 语义、生成完整记忆句子或决定布局；
- 不首版支持用户导入任意字体文件；
- 不把“免费字体”直接等同于“可以随 App 分发”，每个具体文件仍需许可证核查。

## 2. 冻结边界

### 2.1 现有 Renderer

`Classic White` 和 `Minimal` 是已存在的行为契约。FM 实现不得修改：

- 两者现有的横屏布局；
- 两者现有的竖屏布局；
- 两者现有的 `RecordCardPresentationPlanner` 分支；
- 两者现有的输出像素尺寸和照片/底部信息区关系；
- 两者现有的配置投影、区域草稿和持久化键；
- 两者现有的预览、导出、Live Photo、Photos 保存路径。

任何为了“统一”而触碰上述内容的改动都不属于 FM 范围，应单独立项。

### 2.2 产品架构

用户路径保持：

```text
Library -> Interactive Memory Card -> Object Inspector
```

FM 只是 Object Inspector 中新增的一种表达形式，不新增第二套编辑器心智模型。
用户看到的语言继续使用 Preset、Memory Card、Object Inspector 等既有产品语言。

### 2.3 所有权

```text
Memory Engine
  -> 提供 capture time 和 time-result

Card Content
  -> 决定输出窗口里显示什么、顺序和字面组合

FM Layout Engine
  -> 决定图片相对位置、边界、文字测量和最终 frame

FM Renderer
  -> 绘制已解析的文字、底色和装饰图层

Export
  -> 使用与预览相同的 FM layout/artifact，创建新输出
```

FM Renderer 不拥有 MemoryBlock 解析、Life Position 计算、位置策略或持久化。

## 3. 用户可见的 Configuration Center 方案

### 3.1 样式切换

当用户选择 FM 时，现有 Configuration Center 只切换到 FM 专属的配置内容：

```text
表达形式
  Classic White
  Minimal
  FilmMark

FilmMark
  卡片内容
  布局与形式
```

Classic White 和 Minimal 仍按当前代码渲染和显示。FM 的新控件只在 FM 选中时出现，
不能向现有样式共享新的位置状态。

### 3.2 卡片内容：调整“内容是什么”

卡片内容区提供一个明确的“输出窗口”，不再让用户面对多个隐含 slot。输出窗口
仍然使用当前编辑器的文字和模块组合能力，并遵守既有输入几何规范：

- 普通文字和模块由 UIKit/TextKit 的现有编辑能力承载；
- 普通文字、attachment 和 caret 保持独立几何所有者；
- 输入 draft 最终回到现有 MemoryCard/MemoryBlock 投影；
- 不在 Renderer 中创建第二套输入框或自绘 caret。

内容可以由以下部分组成：

```text
普通文字
capture_time
anchor_age_text / 其他已支持的时间结果
分隔符
普通文字
```

默认示例：

```text
{{capture_time}} · {{anchor_age_text}}
```

原则：

- smart anchor 只输出时间结果，不自动生成完整句子；
- 用户控制字面文本、模块顺序和分隔符；
- capture time 缺失时必须有可见的空值处理，不得偷偷使用导出时间；
- anchor 无值时必须保留稳定的空值/隐藏策略，并在编辑器中可理解；
- 内容变化只影响测量后的文字 bounds，不改变 FM 的坐标协议。

### 3.3 布局与形式：调整“如何呈现”

布局与形式区提供以下分组：

1. **位置**：左下/右下两个默认起始位置、上下左右方向键、当前位置摘要；
2. **字体**：FM 字体目录中的有限选项；
3. **字号**：有限等级，不允许首版输入任意像素值；
4. **颜色**：系统 Color Picker、自定义颜色和预设色板；
5. **透明度/对比度**：仅在完成真实照片可读性验证后开放；
6. **胶片承载形式**：可选的白色底片/标签背景，不改变照片画布方向逻辑。

卡片内容区和布局与形式区可以分别修改。任何形式变化都不应复制一份 Card
Content；任何内容变化都不应重建另一套位置状态。

### 3.4 大图预览

预览使用一张大图作为校准表面，显示：

- 当前真实 Memory Card 解析出的 FM 内容；
- 当前字体、字号和颜色；
- 当前图片相对位置；
- 可选的胶片承载区域；
- 方向键修改后的即时结果。

预览不提供横屏/竖屏模式开关，也不生成两张模板截图。当前图片是什么比例，
预览就按当前图片画布比例显示；FM 位置始终由同一套归一化坐标映射。

预览仅是当前真实输出的 calibration surface，不是与导出路径分离的装饰性 mockup。

### 3.5 与现有 UI 的复用关系

FM 的 UI 应落在现有 Configuration Center 表面上：

- macOS 复用 `MacConfigurationCenterPage` 和现有的
  `ConfigurationOptionList` 样式切换入口；
- iOS 复用 `MemoMarkConfigurationCenterView` 的配置路径和
  `MemoryCardPreviewSection` 预览层级；
- Card Content 复用 `MemoryCardRegionEditorCluster` 及其现有
  UIKit/TextKit 编辑会话，不创建 FM 私有输入框；
- Layout/Form 复用当前 section、Disclosure、Picker、Button 和原生
  `ColorPicker` 的系统控件语言；
- FM 专属状态由 FM draft/Configuration 对象持有，通过现有 Session 和
  draft projection 进入保存流程；
- 选中 Classic White 或 Minimal 时，不渲染 FM 的位置、字体和色板控件，
  也不读取 FM 状态来影响它们的预览。

这样可以保留当前“Library -> Interactive Memory Card -> Object Inspector”的
层级、间距、标题和反馈方式，同时让 FM 的大图校准面成为新增内容，而不是新的
Workspace 或通用图片编辑器。

## 4. FM 独立数据模型草案

以下类型是实现方向，正式加入生产模型前需要完成兼容性评审。它们不会改变
Classic White 或 Minimal 的旧值。

```swift
struct FilmMarkConfiguration: Codable, Hashable {
    var content: FilmMarkContentDraft
    var appearance: FilmMarkAppearanceDraft
    var placement: FilmMarkPlacementDraft
}

struct FilmMarkContentDraft: Codable, Hashable {
    var blocks: [MemoryBlock]
    var dateFormat: FilmMarkDateFormat
    var emptyValuePolicy: FilmMarkEmptyValuePolicy
}

struct FilmMarkAppearanceDraft: Codable, Hashable {
    var fontID: FilmMarkFontID
    var size: FilmMarkFontSize
    var color: FilmMarkRGBAColor
    var opacity: Double
    var substrate: FilmMarkSubstrate
}

struct FilmMarkPlacementDraft: Codable, Hashable {
    var anchor: FilmMarkPlacementAnchor
    var normalizedOffset: FilmMarkNormalizedOffset
}

struct FilmMarkRGBAColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
}
```

建议的实现约束：

- 所有颜色分量限制在 `0...1`，统一使用 sRGB；
- 所有浮点值写入前规范化并限制精度，避免重复编辑产生无意义漂移；
- `fontID` 是稳定的应用内标识，不直接持久化系统 PostScript 名称；
- `MemoryBlock` 仍是内容资产，不携带 FM 的坐标或字形布局；
- `FilmMarkConfiguration` 作为一个配置快照原子保存，不分别写入多个相互独立的键。

## 5. 单一图片相对坐标协议

### 5.1 坐标定义

FM 使用左上角为原点的归一化图片坐标：

```text
x = 0.0 ... 1.0  // 从左到右
y = 0.0 ... 1.0  // 从上到下
```

`normalizedOffset` 是相对于所选锚点的偏移，不是预览像素值。持久化使用固定精度
单位（`10_000 units = 1.0`），每个轴分别按照当前 resolved photo canvas 的宽或高
映射到像素，因而不依赖预览尺寸，也不会因为连续方向键操作累积二进制浮点漂移。

FM 不区分横屏/竖屏配置。唯一的输入是已经完成方向归一化的 photo canvas size，
加上内容测量结果和安全区。Classic White 和 Minimal 不使用这套协议。

锚点和安全边距都使用图片物理位置 `bottomLeft` / `bottomRight` 与 `left/right`，
不能使用可能在 RTL 环境中被重新解释的 `leading` / `trailing`。UI 可以本地化为
“左下”“右下”，但持久化语义保持物理方向。

### 5.2 解析顺序

```text
resolved photo canvas
    -> resolve content
    -> resolve font and fallback runs
    -> measure text/substrate bounds
    -> choose anchor base point
    -> apply normalized offset
    -> apply safe area
    -> clamp complete output rect
    -> return FilmMarkResolvedLayout
```

Renderer 只接收最终的 `FilmMarkResolvedLayout`，不能在绘制时重新计算这些步骤。

`FilmMarkResolvedLayout` 携带它实际解析使用的 canvas size。其左上坐标到
`PresentationArtifact` / Core Graphics 坐标只允许经过一个 `FilmMarkCoordinateBridge`：

```text
artifactY = canvasHeight - uiRect.maxY
```

Preview、Renderer、静态导出和 Live Photo 不能各自重复转换。

### 5.3 锚点和步进

第一版默认锚点：

- `bottomLeft`
- `bottomRight`

这两个是用户选择其一的默认起始位置，不是同时绘制两个输出窗口。方向键允许
用户在安全矩形内继续向上、下、左、右精细移动，因此不需要为每一种最终位置
增加额外的预设按钮。

方向键使用相同的、与画布尺寸无关的归一化步进。建议初始步进为每轴 `0.005`，
即对应当前画布该轴长度的 0.5%；每次修改都经过统一的 clamp 函数。该数值属于
FM Layout Specification 的可测试参数，不得散落在 SwiftUI View 或 Renderer 中。

完整输出矩形必须位于安全矩形内。若文字宽度超过安全矩形，布局层返回明确的
overflow 状态，由 UI 显示可理解的提示；不能在 Renderer 中偷偷缩小字体或裁掉文字。

### 5.4 方向键交互

每个方向键必须：

- 使用系统 Button 语义和足够的点击区域；
- 有明确 VoiceOver label，例如“向左移动 FilmMark”；
- 有 value/position summary，例如“横向 82%，纵向 91%”；
- 支持键盘方向键时复用同一 command；
- 重复按压只调用同一 `nudge(direction:)` 变更，不创建连续浮点漂移；
- Reduce Motion 开启时不使用必要性不足的位移动画。

首版不强制加入自由拖动。若日后加入拖动，拖动结束后的结果必须回到相同的
normalized offset 和 clamp 函数，不能产生第二套坐标真相。

## 6. 字体目录和颜色系统

### 6.1 字体候选

首版只从有限字体目录中选择：

| ID | 候选 | 用途 | 许可证/注意事项 |
| --- | --- | --- | --- |
| `dseg` | [DSEG](https://github.com/keshikan/DSEG) | 7/14-segment 数字时间戳 | OFL-1.1；Latin/数字为主，需 CJK fallback |
| `ibmPlexMono` | [IBM Plex Mono](https://github.com/IBM/plex) | 稳定、克制的混合信息 | OFL-1.1；逐文件核对版本与声明 |
| `jetBrainsMono` | [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) | 可读性优先的数字/符号 | OFL-1.1；逐文件核对版本与声明 |
| `spaceMono` | [Space Mono](https://github.com/googlefonts/spacemono) | 更具展示感的标签形式 | OFL-1.1；公开仓库归档，列为次选 |

字体目录应返回：

- stable ID；
- 显示名称；
- 字体资源版本；
- 支持的字符范围；
- fallback 策略；
- 许可证文件路径和版权信息。

中文、日文、韩文和缺失 glyph 使用 Apple 系统字体 fallback，不把系统字体复制
进 App。所有实际 bundled font 必须附带原始许可证和版权说明；不能因为字体
网站标注“免费”就跳过合规检查。

### 6.2 字号

字号使用相对于图片短边的有限比例等级，而不是横竖屏各一套像素值。Layout
Engine 在真实 canvas 上解析为实际字号，预览和导出共用解析结果。

建议首版提供：`small`、`regular`、`large` 三档，并为长字符串返回可解释的
overflow 状态；不允许通过 Renderer 内部自动压缩字号解决内容过长。

### 6.3 调色板

颜色 UI 使用系统原生 Color Picker，并提供少量可选预设：

- Film Amber；
- Warm White；
- Muted Red；
- Ink Black；
- Paper Cream。

预设只是起点，用户可以选择任意颜色。最终保存为稳定 sRGB RGBA，渲染时在同一
色彩空间转换；不保存平台私有的 `Color` 编码。

颜色验收不以“好看”为唯一标准，还要验证亮部、暗部、肤色、夜景和白色底片上的
可读性。若开启透明度后无法保证可读性，应提供对比度提示，而不是悄悄修改用户颜色。

## 7. Preview/Export/Photos 合同

FM 的 preview 和 export 必须共享同一个 resolved input：

```text
FilmMarkContentResolver
    -> FilmMarkLayoutEngine
    -> FilmMarkResolvedArtifact
       ├── Interactive Memory Card preview
       └── still/Live Photo export composition
```

`FilmMarkResolvedArtifact` 至少包含：

- resolved canvas size；
- photo frame；
- text/substrate layer frames；
- rasterization font runs；
- color in stable rendering space；
- overflow/empty-value diagnostics。

导出要求：

- 保持原始照片不变；
- 输出为新资源；
- 不使用当前时间替代 capture time；
- 不上传照片或 metadata 到 COS/ChatGPT/第三方服务；
- 复用现有 orientation、color、EXIF、Live Photo 和 PhotoKit 保存合同；
- FM 专属行为用独立 artifact 分支验证，不改变 Classic White/Minimal 的路径。

如果 Live Photo 的现有输出合同不支持 FM 的静态叠加形式，应明确返回不支持/降级
状态，不能把静态 JPEG 成功伪装成完整的 Live Photo 成功。

## 8. 持久化与兼容性策略

### 8.1 不影响旧配置

在 FM 完成 Product Design Review、配置迁移设计和 focused tests 之前：

- 不给生产 `RecordCardPresentationStyle` 直接增加新值；
- 不修改现有 `presentationRouteRawValue` 的含义；
- 不改写旧 Classic White/Minimal 配置；
- 不让旧配置读取到未知 FM 字段后丢失原值。

### 8.2 FM 专属版本

正式实现时，FM 配置应使用单独的版本化 schema，并由现有 durable configuration
aggregate 原子保存。推荐方向：

```text
FilmMarkConfigurationSchemaV1
```

具体持久化键、枚举 raw value 和迁移代码必须在 PDR 后单独冻结。未知版本读取时：

- 保留原始数据或进入可恢复的 unsupported 状态；
- 不静默重置到默认颜色、位置或内容；
- UI 显示恢复/重置动作及后果；
- 旧 Classic White/Minimal 配置继续按原逻辑读取。

### 8.3 保存时机

方向键、字体、字号和颜色的 draft 更新只修改当前 Configuration Session。持久化
仍由现有配置保存入口统一提交，不让每次按键直接写多个散落的 UserDefaults 键。

取消、返回和恢复行为必须沿用现有 Configuration Center 的 dirty 状态、undo/redo
和 draft projection 约定。

## 9. 测试和验收矩阵

### 9.1 自动化测试

- `FilmMarkNormalizedOffsetTests`：编码、解码、步进、clamp、左下/右下默认锚点；
- `FilmMarkLayoutEngineTests`：不同 canvas 比例下同一 normalized offset 的一致映射；
- `FilmMarkTextMeasurementTests`：Latin、数字、标点、CJK、混排、长值和空值；
- `FilmMarkFontFallbackTests`：DSEG/Mono 与中文、日文、韩文 fallback；
- `FilmMarkColorTests`：sRGB RGBA 限制、往返精度和透明度；
- `FilmMarkPreviewExportParityTests`：preview/export 使用同一 resolved artifact；
- `FilmMarkPersistenceTests`：新 schema、未知版本、缺失字段、旧配置不变；
- `FilmMarkRendererBoundaryTests`：Renderer 不解析 Memory Engine 语义、不含布局策略；
- `ExistingRendererRegressionTests`：Classic White/Minimal 的横竖屏和导出基线不变。

### 9.2 UI 和辅助功能

- 方向键 label、hint、value 和 VoiceOver 顺序；
- 键盘方向键与按钮使用同一个 command；
- Dynamic Type 下不裁切、不把当前固定单行输入规范错误扩展为多行；
- Color Picker 的标签、当前值和恢复默认行为；
- 字体显示名、fallback 提示和许可证信息可追踪；
- Light/Dark mode、Reduce Motion、对比度和焦点恢复；
- 中英文、日文、韩文和 RTL 方向下的文案与布局检查。

### 9.3 真机与媒体

配对的 iPhone 17 Pro Max 是 UI 验收设备。至少覆盖：

- 竖向照片和横向照片，但使用同一 FM 配置协议；
- 明亮、暗色、逆光、夜景和白色底片；
- 长中文、长英文、混合数字和标点；
- 快速连续方向键操作和恢复/取消；
- 预览到导出的位置一致性；
- 原图未修改、新输出可读取、Photos 保存结果可见；
- 如涉及 Live Photo，明确验证成功、降级或失败终态。

安装/启动只能证明部署，不等于 UI、PhotoKit、Photos、Share、StoreKit 或生产认证
通过。未完成的证据必须标记为 `NOT VERIFIED` 或 `BLOCKED`。

## 10. 增量实施顺序

1. Product Design Review：冻结 FM 内容窗口、白色底片是否为形式选项、默认字体和
   默认颜色；
2. 创建 FM 专属纯值模型和 Layout Engine 原型，不接入旧样式枚举；
3. 先写 normalized placement、字体测量、色值和 preview/export parity 测试；
4. 创建独立实验预览，验证大图上的相对位置和四方向微调；
5. 在 Configuration Center 中增加 FM 专属卡片内容/布局与形式分组；
6. 通过 focused tests、macOS build 和真机 UI 验收后，再设计生产 schema 迁移；
7. 最后才把 FM 注册到生产样式选择和 export pipeline；
8. 完成 PhotoKit/Photos、原图保护和恢复路径验证后，才能声明 FM 可用于生产。

任何一步发现需要修改 Classic White 或 Minimal，立即停止该变更并另开范围；FM
不能成为现有 Renderer 的重构入口。

## 11. 完成定义

FM 只有在以下条件全部满足后，才能从“探索/原型”改称“可用”：

- Card Content 与 Layout/Form 的所有权通过代码和测试证明；
- 单一图片相对坐标协议在不同尺寸、比例和方向归一化输入下稳定；
- 预览与导出共享同一 resolved artifact；
- 字体许可证、fallback 和 App bundle 记录完整；
- 自定义颜色稳定保存并可往返恢复；
- 旧 Renderer 回归测试通过且其横竖屏行为未改变；
- 配置保存、撤销、取消、恢复和未知版本处理通过；
- iPhone 17 Pro Max UI、辅助功能和实际照片导出验收通过；
- 原始照片保护、Photos 保存和失败终态均有证据；
- COS 的只读评审意见已经与本规格中的本地代码事实对照，不能把评审建议当作
  已验证实现。

## 12. 推荐默认值

为了让第一版进入界面后无需额外解释，建议采用以下默认状态：

- 初次进入 FM 时激活 `bottomRight`（图片右下），因为它与当前参考图的
  视觉重心一致；
- `bottomLeft`（图片左下）作为第二个默认位置；两者是可切换的起始预设，
  不是同时绘制的两个标记；
- normalized offset 从安全区基线开始，首次进入不叠加额外偏移；
- 方向键步进为每轴 `0.005`，内部使用固定精度单位，连续调整仍受完整输出矩形 clamp；
- 混合中文/数字内容默认使用 IBM Plex Mono，并由 Apple 系统字体补足 CJK；
- 纯数字或 Latin 时间戳可切换 DSEG，DSEG 不作为中文混合内容的默认字体；
- 默认颜色使用可读的 Film Amber，但颜色面板始终允许用户改为任意 sRGB 颜色；
- 白色底片/标签承载区域默认关闭或作为独立形式选项，不能改变图片画布和
  FM 的相对位置协议；
- 默认字号为 `regular`，长内容显示 overflow 诊断，不偷偷压缩或裁切。

这些默认值只属于 FM 的新配置，不会写入或改变 Classic White、Minimal 的任何
现有默认值。

## 13. 基于截图的 Configuration Center 复核

用户提供的 9 张 iPhone 截图作为当前 FM 界面的观察证据，不作为需要照搬的设计。
截图暴露了三个具体问题：

1. 对于主要呈现一段时间标记文字的样式，预览占用了过多纵向空间；当前示例
   还可能在没有有效输出内容时只显示一块渐变背景，因此用户无法判断最终会
   写到照片上的具体结果。
2. 位置箭头、字体、字号、颜色、衬底、录入窗口、保存位置和照片说明被放在
   同一条较长的配置流里，导致高频决定和低频细节互相争夺注意力。
3. 现有输出位置和照片说明是有实际后果的全局输出设置，应继续保存，但不应
   被误认为是 FM 外观配置。

### 13.1 预览方向

下一轮 UI 应将 FM 预览高度缩减到当前约一半，并设置 iPhone 上的最大高度。
预览仍保留照片相对位置的上下文，因为完全移除照片会让用户无法判断左下或
右下的位置。预览必须始终显示已解析的 FM 输出文字：

- Card Content 有内容时使用当前内容投影；
- 内容窗口为空时显示明确的示例内容或空状态，不能让一块没有文字的背景看起来
  像成功输出；
- 文字、字体、颜色、衬底和位置使用与导出相同的 resolved presentation；
- 预览应足够紧凑，让首屏能看到关键配置，而不是把页面变成画布编辑器。

因此，FM 预览应成为紧凑的校准区域，而不是完整照片编辑器，也不是第二套配置
区域。仅展示一个样式色块可以作为样式库的后续优化，但不适合作为 FM 的主预览，
因为它无法表达下方位置关系。

### 13.2 Configuration Center 信息层级

FM 首页应依次回答“关联哪个时刻”“最终写入什么”“看起来怎样”：

| 优先级 | 首页内容 | 原因 |
| --- | --- | --- |
| P0 | 时间锚点 | 在选择外观之前确定时间含义。 |
| P0 | 卡片样式 = 胶片时间 | 选择 FM 表达路径。 |
| P0 | 输出内容摘要与现有卡片内容入口 | 让用户看到真实时间结果，并保留现有模块插入和录入功能。 |
| P0 | 字体、字号、颜色 | 这三个高频决定会直接改变时间标记的视觉结果。 |
| P1 | 输出位置、照片说明 | 它们属于全局输出后果，必须继续由现有 aggregate 保存。 |
| P1 | 位置摘要，例如“右下” | 用户需要知道当前锚点，但不需要在首页看到四个移动按钮。 |

首页不应把每一个 FM 属性都展开成独立的大区块。字体、字号、颜色可以组成
一个紧凑的视觉样式组；输出内容则保持独立入口，因为它拥有现有的录入窗口和
模块插入行为。

### 13.3 二级菜单

二级菜单可命名为“位置与细节”或“胶片样式细节”，用于承载低频配置：

- 位置详情：左下或右下锚点，以及四方向微调；
- 衬底：无、柔和阴影、半透明底；
- 越界/可读性提示和恢复默认值；
- 后续正式字体资源加入后的 fallback 说明。

用户在首页看到当前“右下”或“左下”摘要，点击后进入二级菜单完成微调。保存
的数据仍然是一组物理图片锚点和一个归一化偏移，不新增横屏/竖屏菜单，也不让
RTL 界面镜像已经保存的物理左右位置。

### 13.4 录入窗口

现有“卡片内容”编辑器应继续作为 FM 的录入窗口。FM 首页只显示短的输出摘要，
点击后复用现有编辑器，继续支持普通文字、拍摄日期/时间和智能时间结果。模块
库可以保持完整，但需要体现使用频率：

- 首要建议：拍摄日期/时间、已选时间锚点结果、必要时的对象昵称；
- 次要建议：位置、设备型号和拍摄参数；
- 更少使用的模块继续保留在现有模块库中，不占据 FM 首页。

最终句子仍由用户组合。智能锚点只提供时间结果，不自动生成整句。还需要明确
空值和分隔符策略：智能结果缺失时，不能留下悬空分隔符，也不能静默改成与
用户意图无关的默认句子。

### 13.5 FM 仍然必须具备的配置

简化首页之后，FM 仍需要这些能力，即使其中一部分放在二级菜单：

- 已解析的输出字符串；内容为空时必须有可理解的空状态；
- 由现有 Memory Engine 提供的拍摄时间和时间锚点语义；
- 通过卡片内容编辑器控制文字和分隔符；
- 字体、相对字号、稳定 sRGB 颜色和颜色 alpha；
- 一个物理图片下方锚点与归一化偏移；
- 越界提示，而不是静默缩小字体或裁剪内容；
- 现有输出位置与照片说明的持久化；
- 沿用 Configuration Session 的恢复默认、取消、保存和重新打开行为；
- 预览与导出使用同一 resolved presentation。

Live Photo 策略、相册选择、PhotoKit 写回和 metadata 保留继续属于全局输出能力。
FM 只消费这些合同，不应为它们创建第二套 FM 专属开关。

### 13.6 有界实施顺序

下一轮实现分为两个小步骤：

1. **预览和首页层级：** 缩小 FM 预览，确保它显示真实解析结果或明确空状态；
   将字体/字号/颜色调整为高优先级紧凑组；保留现有卡片内容入口；继续保留
   全局输出行和保存行为。
2. **二级细节入口：** 将位置微调和衬底移入二级菜单，继续绑定同一个 FM draft，
   并补充辅助功能和持久化检查。

正式字体资源、CJK run-level fallback、真实 Photos 图片预览，以及完整 PhotoKit /
Live Photo 读回仍属于后续验证工作。本次调整不修改 Classic White 或 Minimal
布局，不增加 FM 横屏/竖屏变体，也不建立第二条输出持久化路径。
