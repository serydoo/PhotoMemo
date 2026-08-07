# UI-17PM-016 左上区域统一 TextKit 流试点规格

日期：2026-08-07
版本：2.0.3 (70)
目标设备：iPhone 17 Pro Max
主循环：Product Loop（来自卡片内容编辑的真机交互观察）
风险：P1（编辑光标、模块增删、实时预览与草稿一致性）

## Objective

只把卡片内容的左上区域 `.slotA` 迁移到一个统一的 TextKit 编辑流，验证文字、模块和系统光标能否在同一个 `UITextView` 中自然协作。

试点使用：

- `UITextView` 作为左上区域唯一输入控件；
- `NSTextStorage` 保存当前 attributed editing projection；
- `NSTextAttachment` 表示模块附件；
- `NSRange` 保存和恢复选区/光标；
- 系统键盘完成文字输入、长按空格移动光标和退格删除附件；
- 现有模块候选区把模块插入保存的 TextKit 光标范围；
- 每次有效编辑继续写回 `V1EditorDraft`，并沿用现有实时预览刷新链路。

左下 `.slotB`、右上 `.slotC`、右下 `.slotD` 继续使用现有 `V1RegionEditorCard`、`V1InlineTextField`、`activeTextItemID` 和分段输入结构。本试点不以局部实现为理由修改其行为。

成功不是“左上看起来像一个输入框”，而是以下闭环成立：

```text
V1EditorDraft
-> TextKit attributed projection
-> UITextView edit / selection / attachment mutation
-> V1EditorDraft
-> existing preview refresh
```

`V1EditorDraft / V1ContentItem` 始终是保存、应用和预览的数据源。TextKit 只是 iOS 编辑适配层，不成为 Memory Engine、Layout Engine、Renderer、Export、PhotoKit 或持久化的新数据源。

## Confirmed assumptions

1. 试点固定为 `.slotA`，不增加运行时开关，也不按设备型号分支。
2. 采用 UIKit 当前稳定的 `UITextView + NSTextStorage + NSTextAttachment` 编辑栈；不在试点中引入第三方富文本依赖。
3. 模块在 TextKit 中占一个 attachment character（`U+FFFC`），选区范围使用 UTF-16 `NSRange`，与 UIKit 文本系统保持一致。
4. 每个附件通过自定义 attributed-string metadata 保存对应的 `V1ContentItem.id`、`kind`、显示标题和既有模板信息所需的稳定身份；模板值和业务值仍取自既有 draft item，不从附件图像或 accessibility 文案反推。
5. 当 TextKit 编辑投影写回 draft 时，相邻普通文字可以合并为文字 item；附件顺序和附件对应的既有 item identity 必须保留。
6. 外部 draft 更新只有在内容确实不同且不会覆盖正在进行的 marked-text/输入法组合状态时才重建 `NSTextStorage`。
7. 左上区域仍使用现有候选模块面板、当前区域选择、Card Editor 容器、键盘避让和区域滚动结构。

## Ownership and dependency boundaries

### Source of truth

- 保存真相：`V1EditorDraft / V1ContentItem`。
- 编辑期视图投影：左上区域的 `NSTextStorage`。
- 左上当前光标真相：`UITextView.selectedRange`，由适配层保存为 `NSRange`。
- 另外三区当前光标兼容真相：现有 `activeTextItemIDs`。
- 预览真相：现有 `V1DraftRuntimeCoordinator` 与 `V1PreviewSyncCoordinator` 链路。

### Allowed dependency direction

```text
V1EditorDraft
    <-> V1TextKitDraftAdapter
        <-> V1SlotATextKitEditor (UIViewRepresentable)
            <-> UITextView / NSTextStorage / NSTextAttachment
```

模块候选选择只向左上 TextKit editor 发出“在保存的 selection 插入这个既有 `V1ContentItem`”的 UI 命令。适配层生成新的 draft 后，再通过既有 UI 草稿入口交给运行时协调器和预览链路。

### Forbidden dependency direction

- Renderer、Memory Engine 或持久化读取 `NSTextStorage`；
- `NSTextAttachment` 保存新的业务模型或独立模板真相；
- TextKit adapter 调用 PhotoKit、Export 或 Layout Engine；
- 为试点改写 `.slotB/.slotC/.slotD`；
- 用 `activeTextItemID` 作为 `.slotA` 的最终插入位置；
- 为模拟跨节点光标继续绘制自定义蓝色插入标记。

## Component design

### `V1TextKitDraftAdapter`

建议放在现有已编译的 iOS Views 目录中，保持纯转换职责：

```swift
struct V1TextKitDraftAdapter {
    struct Projection {
        var attributedString: NSAttributedString
        var itemRanges: [UUID: NSRange]
    }

    func projection(from draft: V1EditorDraft) -> Projection
    func draft(
        from attributedString: NSAttributedString,
        preservingItemsFrom previousDraft: V1EditorDraft
    ) -> V1EditorDraft
}
```

转换规则：

- `.text` -> 普通 attributed substring；
- `.token`、`.separator`、`.lineBreak` -> attachment-backed composed item；
- attachment metadata 只保存重建/匹配既有 `V1ContentItem` 所需的稳定标识；
- 写回时按 attributed string 的顺序重建 `items`；
- 连续文字合并，空文字只在既有 draft 规范要求尾部输入节点时保留；
- 不认识或元数据损坏的 attachment 不得静默生成错误业务模块：记录为可诊断的适配失败，并保留上一个有效 draft。

试点阶段 `.lineBreak` 仍按既有 `V1ContentItem.Kind` 语义投影，不借机改变单行卡片布局规则。

### `V1SlotATextKitEditor`

使用 `UIViewRepresentable` 包装 `UITextView`。职责限定为：

- 创建并持有 TextKit 编辑对象；
- 应用系统字体、Dynamic Type、语义颜色、文本容器 inset 与附件视觉；
- 通过 `UITextViewDelegate` 观察 selection 和内容变化；
- 保存 `selectedRange`；
- 把有效 attributed content 通过 adapter 转为 draft；
- 接收待插入模块命令，在保存的 selection 替换选中内容并把光标移动到附件之后；
- 防止 SwiftUI update 与 delegate 回调形成重复写回循环；
- 遇到 `markedTextRange != nil` 时不重建 storage，避免破坏中文输入法组合文本。

系统长按空格移动由 `UITextView` 原生支持，不添加自定义拖动手势。系统退格删除附件由 TextKit selection/delete 行为完成，不在附件内添加删除按钮。

### Slot routing

`V1RegionEditorCluster` 只在 `region == .slotA` 时渲染 TextKit editor；其他区域继续渲染现有 `V1RegionEditorCard`。为了避免一个公共 View 同时承担两套复杂状态，建议新增一个左上试点包装层，而不是在每个 `V1InlineTextField` 内加入 TextKit 条件。

`.slotA` 候选区展开时：

1. 保存 `UITextView.selectedRange`；
2. 可以按现有双模式入口收回键盘，但不能销毁 TextKit editor；
3. 点击候选模块后，在保存范围插入 attachment；
4. 转换并写回 `.slotA` draft；
5. 触发现有 `.slotA` preview refresh；
6. 候选区按现有规则收起；
7. 不强制重新弹出键盘。

## User-visible contract

- 左上区域视觉高度、圆角、背景、字体和现有 28pt 模块节奏与另外三区协调，不因技术试点变成独立富文本编辑器样式。
- 左上文字与模块处于一个系统文本流中，光标可出现在文字之间、模块前后及相邻模块之间。
- 长按键盘空格可使用系统 trackpad 行为移动光标。
- 在模块后按退格可删除该附件；继续退格只按系统文字编辑语义删除文字。
- 选中文字后插入模块时，模块替换选中范围；只有光标时在该位置插入。
- 插入或删除后 Renderer 预览实时刷新，不要求先点“完成”。
- 左上不显示旧的自定义插入位置标记；另外三区暂时保留现有标记与节点锚点行为。
- 候选区、Renderer、标题与 Card Editor 边界保持现有布局，不因 TextKit 试点扩大或新增模态层。

## Text and attachment fidelity

必须覆盖以下序列：

- 纯文字；
- 纯模块；
- 文字 + 模块 + 文字；
- 连续两个模块；
- 模块位于开头或末尾；
- 空内容；
- 中文输入法 marked text；
- emoji 和扩展字形；
- 中英文混合与 Dynamic Type。

所有 range 运算使用 `NSRange`/UTF-16 边界，不用 Swift `String.count` 推导 UIKit selection offset。

## Accessibility and Apple-native behavior

- `UITextView` 保持可编辑文本语义与系统光标行为；
- attachment 提供简洁、可本地化的 accessibility 描述，例如模块标题与当前显示值；
- VoiceOver 能按顺序遍历文字和模块，且删除后的焦点不跳出左上编辑器；
- 支持 Dynamic Type，不固定 UIKit 字号；
- 不禁用系统编辑菜单、选择、复制/粘贴或键盘 trackpad；
- 粘贴富文本时只接受 MemoMark 支持的纯文字与已识别内部附件，外部未知附件降级为安全文本或拒绝写回，不生成伪模块。

## Testing strategy

### RED contract and adapter tests before production code

新增聚焦测试，先证明当前实现不满足：

1. `.slotA` 路由到 `V1SlotATextKitEditor`，另外三区仍路由到现有分段 editor；
2. draft -> attributed projection 保持文字、模块顺序和 item identity；
3. attributed projection -> draft 保持模板值与附件 identity；
4. selection 中插入模块替换 selection，并返回附件后的新 caret range；
5. 模块后退格删除只删除附件；
6. emoji/中文的 selection 使用 UTF-16 range 正确往返；
7. marked text 存在时外部 update 不重建 storage；
8. `.slotA` 编辑回调触发既有 preview refresh；
9. `.slotB/.slotC/.slotD` 仍包含 `V1InlineTextField`、旧 `activeTextItemID` 路由和现有插入标记契约。

纯转换和 selection 逻辑应尽量放在可于 `PhotoMemoTests` 运行的无 UI adapter/helper 中。`UITextView` delegate、输入法、键盘 trackpad 和 VoiceOver 属于模拟器/真机验证边界，不能用源代码字符串契约冒充行为证明。

### Focused commands

测试：

```bash
xcodebuild test \
  -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoTests \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:PhotoMemoTests/V1TextKitDraftAdapterTests \
  -only-testing:PhotoMemoTests/IPhoneResponsiveLayoutContractTests \
  CODE_SIGNING_ALLOWED=NO
```

差异检查：

```bash
git diff --check
```

iOS Debug 构建：

```bash
xcodebuild \
  -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemoiOS \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/PhotoMemoTextKitPilotDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

签名构建与原地覆盖安装仅在聚焦测试、diff check 和无签名构建通过后进行；禁止卸载应用或清除设备数据。

## Incremental implementation tasks

- [ ] Task 1：补 RED adapter/selection tests 与 slot-routing contract。
  - Acceptance：当前分段实现明确失败；测试不依赖 Renderer、PhotoKit 或持久化。
  - Verify：确认失败原因只对应缺失的 TextKit 试点能力。
  - Files：新增 adapter 测试；调整 `IPhoneResponsiveLayoutContractTests.swift`。

- [ ] Task 2：实现纯 `V1TextKitDraftAdapter` 与 attachment metadata/range helper。
  - Acceptance：文字、附件、identity、模板值、emoji/中文 range 往返测试通过。
  - Verify：只运行 adapter tests。
  - Files：新增一个 iOS editor adapter 源文件和一个测试文件。

- [ ] Task 3：实现 `V1SlotATextKitEditor`，但仅接通 `.slotA` 的文字编辑与 selection 保存。
  - Acceptance：左上使用一个 `UITextView`；另外三区源码和行为保持现状；编辑写回现有 draft 并实时刷新。
  - Verify：adapter tests + routing contracts + iOS build。
  - Files：新增 editor wrapper；小幅调整 cluster/card routing 与 root callbacks。

- [ ] Task 4：接通 `.slotA` 模块插入和系统退格删除。
  - Acceptance：插入使用保存的 `NSRange`，不依赖 `.slotA activeTextItemID`；删除附件后 draft 与预览同步。
  - Verify：selection helper tests、focused coordinator tests、iOS build。
  - Files：TextKit editor/adapter 与最小 root module routing。

- [ ] Task 5：模拟器/目标真机验收并记录结果。
  - Acceptance：左上文字输入、模块前后/之间插入、选区替换、退格删除、长按空格、中文输入、键盘避让、实时预览均有明确结果；另外三区回归检查通过。
  - Verify：签名构建、签名校验、原地覆盖安装、人工路径；不清除数据。
  - Files：仅更新本规格、真机反馈文档和 `Docs/CURRENT_STATUS.md`。

## Boundaries

### Always

- 保持 `.slotA` TextKit projection 与 `V1EditorDraft` 可逆；
- 先写 RED tests，再写 adapter 和 UIKit wrapper；
- 每个增量后运行对应聚焦测试；
- 保持现有候选内嵌、四区独立、Renderer 实时刷新和右下照片说明映射；
- 明确区分自动验证、构建/安装和真机人工验收。

### Ask first

- 试点需要改变 `V1EditorDraft / V1ContentItem` 的持久化形状；
- 需要把 `.slotB/.slotC/.slotD` 一并迁移；
- 需要改变 Card Editor 容器、候选区或 Renderer 映射；
- 需要引入 TextKit 2 专属架构、第三方富文本依赖或新的最低系统版本。

### Never in this pilot

- 修改 Memory Engine、Layout Engine、Renderer、Export、PhotoKit 或持久化；
- 恢复半屏模块 sheet；
- 把 TextKit 作为新的业务数据源；
- 删除另外三区的 `V1InlineTextField` 或 `activeTextItemID`；
- 提交、暂存或推送 GitHub；
- 卸载应用或清除手机本地数据；
- 把测试/构建/启动描述为生产认证通过。

## Success criteria

1. 只有 `.slotA` 使用统一 `UITextView/NSTextStorage` 流。
2. 左上文字、模块和 selection 在同一 TextKit 文档中，模块以 attachment 表示。
3. 左上模块插入使用保存的 `NSRange`；系统退格可删除附件；长按空格沿用系统能力。
4. 每次有效变更写回既有 draft，并实时刷新现有 Renderer preview。
5. `.slotB/.slotC/.slotD` 的结构、插入和预览行为没有改变。
6. 不产生新的持久化格式或业务数据源。
7. 聚焦 tests、`git diff --check` 和 iOS Debug build 通过。
8. 真机验收明确覆盖 TextKit 交互；未验证项不被描述为已完成。
9. TX-001、BP-001 保持未关闭，生产认证保持 `FAIL (Conditional)`。

## Confirmed review decisions

以下行为已于 2026-08-07 由产品负责人确认：

1. 左上试点中，选中文字后插入模块按系统富文本习惯替换选区，不先折叠到选区末尾。
2. 只有 MemoMark 自己创建且带稳定 metadata 的附件可以成为模块；外部未知附件统一安全降级或拒绝，不生成伪模块。
