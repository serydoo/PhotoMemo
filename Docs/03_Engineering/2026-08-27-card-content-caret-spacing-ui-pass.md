# Card Content Editor 光标与行内间距 UI Pass

日期：2026-08-27
范围：iPhone 17 Pro Max 真机截图反馈（IMG_4054–IMG_4059）与微信输入框截图（IMG_4060）
类型：Product Loop / P1 UI interaction polish

## 观察到的现象

昨天的编辑器多轮修复已经闭合了区域路由、混排退格、模块插入位置恢复、统一
TextKit 行盒和四区编辑结构。本次真机截图仍显示两个集中问题：

1. 当前 caret 由 `UITextView` 隐藏后的自绘 `UIView` 呈现，外形是方头、固定 2pt
   宽度和 16pt 高度；它与系统输入控件的原生光标视觉不完全一致。
2. TextKit attachment 为每个模块追加透明尾部 advance，SwiftUI 混排预览又使用另一组
   `HStack` 间距和插入锚点 padding，导致文字—模块、模块—光标、模块—模块之间的节奏
   在不同编辑状态下不完全一致。空白输入框的 leading inset 也应与非空内容共享同一
   起始基准。

微信截图仅用于提取原生输入的可见规律：光标细、端点柔和、位于真实插入边界，且与
   前一字符保持自然的最小间距；不作为产品界面或颜色的模仿目标。

## 目标结果

- 保留 UIKit/TextKit 作为输入、选区、听写、撤销、辅助功能和模块原子编辑的唯一行为源。
- caret 使用系统 accent 色、细窄且端点柔和的单一可视实现；不能在多个区域残留伪光标，
  也不能因空白、文字、模块而改变横向插入位置。
- 统一 attachment 与 SwiftUI fallback 的行内间距契约；透明 advance 只用于真实必要的
  光标邻接呼吸，不再叠加第二套不透明间距。
- 空白、普通文字、模块、文字+模块和连续模块状态共享相同的 leading/trailing 规则，
  文本输入起点和模块后继续输入的光标都落在自然插入边界。
- 不改变四区焦点状态、模块插入/删除、结构化复制粘贴、undo、实时预览、照片说明来源、
  renderer、持久化或 Apple Photos 流程。

## 代码边界与验证

预计只涉及：

- `V1TextKitEditorSession.swift`：caret 实现和统一输入度量；
- `V1IOSViewSupportComponents.swift`：TextKit attachment 与 SwiftUI fallback 的共享
  行内间距；
- 相关 iOS UI/source-contract 测试：锁定 caret 形态和 spacing 契约。

验证顺序：

1. 先运行新增/更新的编辑器 focused tests 与源解析检查；
2. 执行 `git diff --check`；
3. 构建通用 iOS 与签名实体设备包，覆盖安装到配对 iPhone 17 Pro Max；
4. 真机人工检查空白、文字、模块、文字+模块、连续模块、删除后和键盘态；
5. 更新 `Docs/CURRENT_STATUS.md`，明确已验证与仍未手工验证的边界。

本 pass 不使用 iOS Simulator，不改变昨天已经确认的编辑器架构，不恢复退役的旧编辑路径。

## 后续真机反馈：纯文字基线补正

后续 iPhone 17 Pro Max 截图显示，空白输入面的 caret 已经居中，但纯自定义文字在
共享 28pt TextKit 行盒中仍有轻微上浮。该差异来自普通文字的 UIKit 默认 baseline，
不是 caret 宽度、颜色、选区或左/右区域路由。

实现通过 `editingAttributes()` 根据当前 preferred font 和共享 line height 计算
负向半 leading `baselineOffset`，让普通文字与模块胶囊及中心 caret 使用同一 optical
center；不为左侧或右侧增加特例，也不改变 TextKit attachment 或内容模型。

## 后续真机反馈：文字与模块混排边界

最新 `IMG_4066`–`IMG_4070` 状态显示，纯自定义文字和单独 caret 已经默契，剩余差异
集中在文字—模块—文字的横向相对位置：不同插入顺序可能让一侧使用 attachment 的
透明尾部 advance，另一侧又依赖文字自身的 side bearing，视觉上出现前后不等距。

本轮将边界间距收敛为 attachment 的固定单侧占位契约。每个模块在透明 canvas 内
固定保留 0pt leading 与 2pt trailing advance；模块插入与结构化粘贴使用同一构造路径，
并在投影后立即重排整行，使相邻旧模块同步使用同一几何。行首模块不增加 leading，
模块—模块、模块—文字和文字—模块边界都由模块的单侧 trailing advance 提供，从而
不会出现两侧重复占位或依赖字体 side bearing 的状态差异。

## 后续真机反馈：混排垂直 optical center

后续真机截图进一步确认，纯文字和 caret 本身已经垂直居中，但文字与模块组合后，
模块胶囊沿用了独立的 `capHeight` baseline 估算，和普通文字的共享 28pt line-box
存在上下偏移。这不是新的区域路由或内容状态问题，而是两套基线公式没有统一。

本轮将 `lineHeight`、普通文字的 `textBaselineOffset` 和模块的
`attachmentBaselineOffset` 收敛到 `V1EditorInputMetrics`。模块 bounds y 对文字
偏移做反向补偿，保持空白、纯文字、模块、文字—模块—文字和 caret 的 optical center
一致；同时保留 attachment canvas 内的横向透明 advance，避免用 bounds origin 叠加
字体 side bearing。

## 后续真机纠正：attachment baseline 方向

`IMG_4074 2`–`IMG_4077` 证明上一段“反向补偿”的方向判断错误：纯文字和 caret
保持正确，但 attachment 的 bounds y 从更负变为较不负后，模块胶囊反而进一步上移。
因此 `NSTextAttachment.bounds` 必须按照文字 baseline 坐标系与普通文字做同方向补偿。

最终公式将模块自身的视觉中心偏移与 `textBaselineOffset` 相加，不再相减。此变更只
纠正 attachment 的纵向方向，不改文字 baseline、caret、line-box、输入框、模块尺寸
和横向间距。回归契约先在旧公式下失败，再在修正后通过。

## 后续真机反馈：模块边界实时输入属性归一化

`IMG_4078`–`IMG_4082` 及真机操作序列进一步证明，最终剩余差异不是静态 baseline
公式：模块后输入正常；光标移动到模块前后，刚录入的普通文字可能暂时上下偏移；删除
或重新插入模块后，因为 `applyDraft` 重建完整 attributed string，同一文字又恢复正常。
这说明 attachment 与已重建文字的几何已经一致，缺口位于 UIKit 的 typing-attributes
生命周期。

`UITextView` 会从插入点邻近 run 推导后续输入属性。当邻近字符是 TextKit attachment
时，新建普通文字 run 可能缺少 MemoMark 的统一 paragraph style 与 `baselineOffset`。
本轮因此在 selection 移动后刷新 canonical typing attributes，并在 marked text 完成
提交后归一化正文普通文字 run。归一化明确跳过 attachment 与私有尾部 sentinel，且
不打断中文输入法组合态；它不改变文字内容、模块身份、结构化投影、undo、copy/paste
或任何视觉常量。

回归矩阵锁定为：纯文字；模块前输入；模块后输入；保留文字删除模块；重新插入模块；
文字—模块—文字混排。所有状态必须保持同一垂直位置，不得再因触发 draft 重建而跳动。

## 最终真机定性：baseline 必须与内容类型无关

用户在更新包上执行的完整矩阵推翻了“只缺 typing attributes”的单一解释：模块后输入
正常；删除最后一个模块后，已存在文字整体向下；重新插入模块后同一文字恢复；纯文字
加入标点、数字或 `+` 仍然向下；只要行内存在模块，前后文字都正常。旧文字没有发生
新的键盘输入却随 attachment 有无移动，证明变化发生在共享 line-fragment baseline。

独立 TextKit 1 探针进一步验证：paragraph 的 28pt min/max line height 只固定 fragment
高度，不固定内部 baseline。普通文字的负 `baselineOffset` 使纯文字下降；attachment
约 `-14pt` 的 bounds origin 又参与 ascent/descent，使含模块行的 baseline 上移并偶然
抵消文字下降。两态 `usedRect.height` 都是 28pt，因此调整外层 inset 或继续按 usedRect
居中无法解决。

最终模型取消普通文字的 run-level baseline 补偿。`V1EditorLineBoxGeometry` 将 baseline
定义为 canonical line height 与字体 descender 的函数，并用
`font.descender + (lineHeight - attachmentHeight) / 2` 将 attachment canvas 放进同一个
line box。模块有无不再是 baseline 的输入；attachment 字符还显式继承同一 paragraph
style，避免模块位于第一个字符时产生另一套段落几何。输入法提交后的普通文字属性
归一化仍保留，但只负责 font、foreground color 与 paragraph style，不再承担视觉位移。

普通文字 run 的归一化采用完整 canonical attribute replacement；只合并 font、颜色
与 paragraph style 会保留旧 `baselineOffset`，并造成删除最后一个模块后才暴露偏移、
重新插入模块并完整重建后又恢复的时序差异。replacement 只覆盖非 attachment、非
sentinel 且不处于 IME marked-text 状态的普通文字。

验证读取 TextKit 实际 glyph baseline 和 line-fragment height，而不是只验证 helper
公式的代数关系；矩阵包含纯文字、中文、标点、混合符号及模块前/后/夹中。本 pass
不宣称解决运行中切换 Dynamic Type 后已存在 attributed runs 和 attachment 的重建
生命周期；该 accessibility P1 独立跟踪，避免把默认字号基线修复扩大成未经真机辅助
功能验证的变更。

## `IMG_4094`–`IMG_4100` 纠正：稳定 baseline 不等于文字居中

上述 content-independent baseline 方案成功消除了模块前后顺序造成的文字跳动，但
新一轮真机截图显示，取消 ordinary-text offset 后，所有普通文字都稳定落在输入框
下半部。此前测试只比较 plain/mixed 的 glyph baseline 和 line-fragment height，因而
证明了“状态切换不再改变 baseline”，却遗漏了“普通字体的 typographic center 必须
落在 28pt line box 中心”这一验收条件。

最终属性模型分为三层，不再让一项补偿同时影响文字与模块：

1. paragraph min/max line height 固定 canonical 28pt line box；
2. ordinary text、typing attributes 与 trailing sentinel 使用正向 half-leading
   `max(0, (lineHeight - font.lineHeight) / 2)`，只在 line box 内上移字体盒；
3. attachment 字符只继承 canonical paragraph attributes，不继承 text
   `baselineOffset`，其 28pt canvas 继续由 descender-based bounds origin 居中。

40pt 控件仍用 6pt 对称垂直 inset 放置 28pt line box，caret 仍以控件 `bounds.midY`
为中心。不能再通过移动 text container 修正普通文字，否则已经居中的模块会被一起
移动；也不加入针对某个 CJK glyph 的额外 `±1pt` 常量，因为 glyph ink center 会随
字体 fallback、标点、数字和字号变化。

回归测试新增普通文字 typographic center 与 line-fragment center 的比较，并保留
纯文字、模块在前/后/夹中、CJK/Latin/标点/符号和八组字号矩阵。自动化只能证明
TextKit 排印几何不变量；最终 UIKit 光学观感仍由已安装到 iPhone 17 Pro Max 的最新
签名包验证。默认字号 hotfix 的接受不代表 Dynamic Type 实时切换与辅助功能大字号
生命周期已经关闭。
