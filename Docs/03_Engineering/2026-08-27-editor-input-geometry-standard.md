# MemoMark 编辑输入几何规范

日期：2026-08-27
状态：Accepted
适用范围：所有 MemoMark 用户可编辑的文字输入面，包括 Card Content Editor、未来
Renderer 配置界面中的文字/模块组合输入，以及任何同时显示普通文字、系统光标和
结构化模块的 SwiftUI/UIKit 编辑控件。

## 目的

输入控件必须让普通文字、模块和光标形成一个稳定的视觉中心。内容的改变不能成为
垂直位置的输入条件：在纯文字、模块前、模块后、模块夹中、模块删除、模块重插入和
中文输入法组合态之间，已有内容都不得上下跳动。

这是一条输入层规范，不是 Renderer 输出图片的布局规范。Renderer 继续只消费已经
解析完成的内容与 Layout Engine 结果；不得把输入控件的排印补偿或光标逻辑下沉到
RecordCardRenderer、ClassicWhiteRenderer 或其他输出 Renderer。

## 一、不可变的几何不变量

### 1. 三个视觉对象、三个明确所有者

| 对象 | 唯一几何所有者 | 规则 |
| --- | --- | --- |
| 普通文字 glyph | 输入编辑器的 ordinary-text attributes | 在 canonical line box 内按字体度量居中 |
| 模块 attachment/capsule | attachment 自身的 canvas bounds | 在同一个 line box 内独立居中，不继承文字 offset |
| 插入光标 | UIKit/TextKit 原生 caret | 横向跟随真实 insertion boundary，纵向相对控件中心固定 |

禁止用一个 offset 同时校正两个对象，也禁止让 attachment、字体 ascent/descent 或
当前内容顺序决定整行 baseline。

### 2. Canonical line box 是唯一垂直基准

单行输入面必须先确定内容无关的 canonical line box，再把它放进控件。当前默认值为：

```text
control height       = 40pt
module canvas height = 28pt
line height          = max(28pt, ceil(current font.lineHeight))
vertical inset       = max(0, floor((control height - line height) / 2))
```

默认字号下，40pt 控件的 28pt line box 由上下各 6pt 的对称 inset 放置，中心为控件
`bounds.midY`。不能用 `usedRect`、当前 attachment 数量或最后一个 glyph 的高度重新
计算 line box。

### 3. 普通文字必须使用字体度量推导的正向 half-leading

普通文字、`typingAttributes`、尾部 sentinel 和提交后的普通文字 normalization 必须
共享以下公式：

```swift
max(0, (lineHeight - font.lineHeight) / 2)
```

正值用于把自然字体盒从固定 line box 的下半部抬回中心。默认 `subheadline` 下约为
`+5pt`，但不得把 `5pt` 写成跨字号的硬编码。

当字体行高达到或超过 line box 时，offset 必须自然趋近于 `0`；不得为大字号继续
施加正或负的经验值。

### 4. Attachment 必须与普通文字属性隔离

Attachment 只允许继承：

- font（用于 TextKit 运行环境和 fallback）
- foreground color（如确有必要）
- canonical paragraph style / line height

Attachment 不得继承普通文字的 `.baselineOffset`。模块 canvas 的纵向位置必须由自身
bounds 公式决定：

```swift
attachmentOriginY =
    baseline(lineHeight: lineHeight, fontDescender: font.descender)
    - (lineHeight + attachmentHeight) / 2
```

当前 28pt capsule 在默认 line box 中的中心误差应保持在 0.5pt 内。调整普通文字时，
不能顺手移动 attachment bounds；调整 attachment 时，也不能改变普通文字 baseline。

### 5. 光标只能有一个可视所有者

优先使用 UIKit/TextKit 原生 caret。允许覆写 `caretRect(for:)` 统一纵向尺寸，但必须
保留 UIKit 提供的横向 insertion x 位置、选区、输入法、撤销、辅助功能和模块原子
编辑行为。

当前默认约束：

```text
caret height = 16pt
caret width  >= 2pt
caret center = input control bounds.midY
```

禁止在 SwiftUI 叠加第二根蓝色竖线、手工 blink view 或按内容类型切换 caret 高度。

## 二、输入生命周期规范

### 1. 所有入口必须回到同一套属性

以下路径必须使用同一 ordinary-text / attachment attribute factory：

- 初次 draft 投影；
- 普通键盘输入；
- 光标移动后的 `typingAttributes`；
- 模块插入；
- 模块删除；
- 结构化复制/粘贴；
- undo/redo 恢复；
- 外部 draft rebuild；
- trailing sentinel 创建/恢复；
- 中文 IME marked-text 提交后的普通文字归一化。

普通文字应使用完整 attribute replacement 清理历史 `.baselineOffset` 和其他富文本
排印残留；不得只 merge 新 font 或 paragraph style 而保留未知旧属性。

### 2. IME marked text 期间不得重写编辑内容

当 `markedTextRange != nil` 时，禁止执行普通文字 normalization、全文 draft rebuild、
attachment 重建或强制覆盖输入法 typing state。候选提交后再对正文普通文字做完整
canonicalization，并跳过 attachment 与私有 sentinel。

### 3. 内容顺序不得影响 baseline

以下状态必须共享同一普通文字 baseline 和同一 line box：

```text
纯文字
模块 + 文字
文字 + 模块
文字 + 模块 + 文字
删除最后一个模块后的剩余文字
重新插入模块后的原有文字
```

如果插入或删除模块导致普通文字上下移动，优先检查 attribute inheritance、TextKit
line fragment 和 `contentOffset.y`，不得先添加区域特例或改变外层 padding。

## 三、横向间距规范

行内间距必须只有一个明确所有者。当前 capsule contract 为：

```text
attachment leading advance  = 0pt
attachment trailing advance = 2pt
SwiftUI fallback spacing    = 2pt
text container inset         = 8pt horizontal
```

不得同时叠加 attachment bounds 的 x 偏移、字体 side bearing、HStack spacing 和额外
透明占位。模块前、模块后、模块夹中、连续模块及行尾 caret 的间距都必须从同一契约
推导。

## 四、实现边界与复用要求

新增输入框时必须：

1. 复用 `V1EditorInputMetrics` / `V1EditorLineBoxGeometry` 的等价共享抽象，不能在
   具体 Renderer 或 View 内复制数字；
2. 明确区分 `editingAttributes()` 与 `attachmentAttributes()`；
3. 让布局容器负责控件尺寸和 inset，让 TextKit 负责文本与模块排印，让 UIKit 负责
   caret、selection、IME 和 accessibility；
4. 将最终内容投影回既有 draft/domain model，不让输入控件直接修改照片、EXIF、
   Renderer 或 Layout Engine 的所有权；
5. 如果输入内容最终服务于某个 Renderer，先完成输入层的稳定几何，再由 Layout
   Engine 解析内容，不得把 UI 临时补偿带入输出图片布局。

如果未来需要多行输入、可增长控件或非 28pt 模块，必须先建立新的明确 line-box
specification 和验证矩阵，再扩展本规范；不得把当前单行 40/28 规则直接复制到多行
或 Dynamic Type 超大字号场景。

## 五、强制验证矩阵

每个新增或修改的输入控件，在合并前至少要验证：

- 空内容与空内容恢复；
- Latin、CJK、中文标点、数字和符号；
- 纯文字；
- 模块在文字前；
- 模块在文字后；
- 模块夹在文字中间；
- 连续模块；
- 删除最后一个模块但保留文字；
- 重新插入模块；
- 模块边界前后继续录入；
- 中文 IME 组合态、候选提交和取消；
- undo/redo 后在模块边界立即输入；
- 光标横向 insertion boundary 与纵向中心；
- 默认字号下的实体 iPhone 视觉验收。

自动化测试至少要证明：

1. plain/mixed 的普通文字 baseline 相同；
2. line-fragment height 不依赖 attachment 顺序；
3. 普通文字 typographic center 与 line-fragment center 的误差不超过 0.5pt；
4. attachment 不含 ordinary-text `.baselineOffset`；
5. attachment canvas center 与 line-fragment center 的误差不超过 0.5pt；
6. 所有普通文字入口使用同一属性 factory。

实体设备验收和自动化排印测试是两个独立门槛。AppKit/TextKit 测试不能替代 UIKit
真机上的字体 fallback、屏幕栅格化、IME 和真实光学观感验证。

## 六、禁止事项

以下做法视为违反本规范，必须在 code review 中退回：

- 为某个区域、某个字符或某个模块顺序增加 `+1/-1pt` 视觉常量；
- 通过移动整个 `textContainerInset.top` 修正普通 glyph；
- 让 attachment 直接复用含 `.baselineOffset` 的 ordinary-text attributes；
- 依据 `usedRect` 或当前内容数量动态改变 line height；
- 同时保留自绘 caret 与原生 caret；
- 在 Renderer 内部决定输入框 baseline 或 caret 位置；
- 只验证“看起来没有跳动”，却不验证文字与模块的共同中心；
- 以 Simulator 画面代替配对实体 iPhone 的最终 UI 验收；
- 在没有新的 specification 和风险评估的情况下，把固定单行控件扩展为 Dynamic Type
  超大字号或多行输入。

## 当前参考实现

当前已经在 iPhone 17 Pro Max 验收通过的参考实现为：

- [V1EditorLineBoxGeometry.swift](/Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark/iOS/Views/V1EditorLineBoxGeometry.swift)
- [V1TextKitEditorSession.swift](/Users/rui/Desktop/PhotoMemo/Source/MemoMark/MemoMark/iOS/Views/V1TextKitEditorSession.swift)
- [V1EditorLineBoxGeometryTests.swift](/Users/rui/Desktop/PhotoMemo/Tests/MemoMarkTests/ArchitectureTests/V1EditorLineBoxGeometryTests.swift)

参考实现是契约的当前落地样本，不意味着未来所有输入框必须复制类名；未来可以抽取
更通用的共享组件，但必须保留上述所有权、几何和验证不变量。
