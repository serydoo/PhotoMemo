# UI-17PM-016 固定四区组合录入编辑器契约

日期：2026-08-07
目标设备：iPhone 17 Pro Max
版本：2.0.3 (70)

## 目标

将卡片内容编辑页收敛为一个固定四区的组合录入面：左上、左下、右上、右下始终显示，每个区域只有标题和一个预填当前配置的组合录入框。文字与内容模块在同一录入面内编辑，模块选择器在当前编辑上下文内短暂展开，选中后插入当前光标位置并立即收起。

编辑页不再显示区域右侧重复摘要、录入框下方的组合结果、重复说明文字或四个区域各自的复杂展开容器。编辑期间的完整结果只由现有 Renderer 实时刷新；点击“完成”时统一保存当前四个区域配置。

## 已确认假设

1. 四个区域顺序固定为 `CardRegion.memoryCardRegions` 的 `.slotA`、`.slotB`、`.slotC`、`.slotD`，分别对应左上、左下、右上、右下。
2. `V1EditorDraft`、`V1DraftMutationCoordinator` 和 `V1DraftRuntimeCoordinator` 继续作为编辑草稿、活动文字节点和预览同步的所有者，不引入新的持久化格式。
3. 右下区域 `.slotD` 仍然是卡片右下内容的唯一来源；当没有独立的照片说明覆盖文本时，现有生产路径会从右下内容生成图片说明。
4. 本阶段保留卡片内容的原生卡片视觉，但将布局空间的所有权放在 Card Editor 容器：
   外层不再使用系统 `.sheet` 管理键盘布局，而是在配置中心页面内挂载受控的底部 overlay。
   overlay 的最高点受 Renderer/记忆来源区域边界约束；键盘只改变编辑器内部可用视口，
   候选区和四区录入视口在编辑器内部独立管理。
5. “完成”继续使用当前配置应用/保存链路，不新增独立的区域保存动作。

## 用户可见契约

- 页面始终显示四个固定区域标题和四个组合录入框。
- 每个区域标题与组合录入框保持同一行：标题左置、输入面右置并占据剩余宽度，
  不额外增加纵向行高。
- 每个录入框预填当前配置中的文字和模块顺序。
- 录入框视觉上是一个连续的组合编辑面，不显示左右两个独立文字框。
- 点击任一组合录入面只进入文字编辑并唤起键盘；候选模块只通过 Card Editor 顶部的
  “＋模块”按钮进入，不再让光标、键盘和候选区在同一次点击中抢占布局。
- 点击“＋模块”时保存当前区域和活动文字节点，先收回键盘，再在编辑器内部展开候选区。
  选中后插入保存的上下文并自动收起候选区；点击其他录入区域或编辑区空白时也会收起
  候选区，用户再次点击录入框即可继续文字编辑。
- 模块候选在当前编辑页内以轻量、紧凑的悬浮面板出现：分类标题使用
  “EXIF”和“智能表达”，每个分类一行横向滑动；不显示候选面板标题和说明文字。
  候选面板以 Card Editor 内 overlay 形式挂载，不参与外层页面高度计算，不遮挡 Renderer
  区域。候选区锁定为 116pt 的固定高度：关闭按钮独立置于右上角，下面两行分别固定
  左侧分类标题，右侧候选胶囊横向滚动；候选项溢出时用轻微渐隐和短横线提示。
- 当某个分类的候选项发生横向溢出时，在该分类胶囊行底部显示一条低对比度的短横线
  作为横向滑动提示；不溢出时不显示，也不增加候选面板的整体高度。
- 键盘出现时不切换第二套键盘态 detent，也不让系统替 Card Editor 重新定位；Card Editor
  自己监听键盘 frame，将键盘占用从底部可用空间中扣除。候选区保持在编辑页内部顶部，
  下方超出键盘上沿的录入行自然裁切并可通过垂直滚动访问。外层 overlay 的最高点不得突破
  Renderer/记忆来源区域的边界。
- 编辑内容发生变化后，现有动态 Renderer 立即同步；编辑页不显示重复的区域摘要或完整组合结果。
- 右下区域编辑结果继续进入 Renderer 的右下位置，并通过现有生产输出路径作为默认照片说明内容。
- 点击“完成”统一提交当前四个区域配置并关闭编辑页。

## 代码边界

### 允许修改

- `V1RegionEditorCluster`
- `V1IOSViewSupportComponents` 中卡片内容编辑器组件
- `V1EditorPresentationModifier` 的编辑页容器和焦点滚动策略
- 必要的 `V1DraftRuntimeCoordinator` UI 适配回调
- 对应的架构/契约测试和本状态记录

### 不允许修改

- Memory Engine
- Layout Engine
- Renderer 核心实现
- Export、PhotoKit、Share Extension
- durable configuration、持久化格式和照片原文件
- TX-001、BP-001 的状态或生产认证结论

## 分步实施

### Slice 0：编辑上下文契约

- 将当前“区域 + 活动文字节点”明确视为最小插入上下文；模块插入必须继续沿用该
  上下文，不能退化为固定追加到区域末尾。
- 后续补充文字节点内的 caret offset/selected range 时，保持 `V1EditorDraft` 和
  `V1DraftMutationCoordinator` 的组合项模型，不引入新的持久化格式。

### Slice A：基础骨架

- 用固定四区列表替代可展开 disclosure row。
- 每个区域只显示标题和组合录入面。
- 移除编辑页内重复摘要、组合结果和说明文字。
- 保持现有 draft、Renderer 实时同步和“完成”保存链路。
- 确认 `.slotD` 到右下 Renderer/照片说明的映射没有改变。

### Slice B：编辑上下文

- 让四个组合录入面共享当前活动区域和光标锚点。
- 文字编辑与模块选择分为两个明确模式：录入面获得焦点时只显示键盘；顶部“＋模块”
  保存上下文后展开轻量模块选择器，选中后插入并收起；每个分类保持一行
  横向候选，压缩胶囊高度和内边距。
- 键盘出现时由 Card Editor 管理内部可见空间，只滚动内部内容；外层 overlay 的高度
  根据安全区计算，并以 `contentEditorTopBoundaryFraction` 约束最高点。

### Slice B1：受控编辑器容器（2026-08-07）

- 移除 `V1EditorPresentationModifier` 对系统 `.sheet` 和动态 detent 的依赖；键盘 frame
  监听由 `V1CardEditorOverlay` 自己持有，用于计算底部可用空间，不再让系统 sheet 接管整页位移。
- 新增 `V1CardEditorOverlay`：保留圆角卡片、拖拽指示条、标题和“完成”按钮的原生视觉，
  但由 Card Editor 自己计算 `maximumEditorHeight`，将底部安全区（包括键盘可用空间）
  纳入内部视口布局。最高边界同时使用比例和 148pt 绝对最小安全线，避免键盘缩小 GeometryReader
  可用高度后，比例边界跟着缩短并重新压进 Renderer。
- 保持候选层、四区编辑草稿、Renderer 实时刷新和完成保存链路不变；本 Slice 不涉及
  光标 offset/selected range 的模型扩展。
- 完全展开状态使用上边界到键盘/底部安全区之间的全部空间，不再以 0.58 内容高度作为
  编辑页最终上限；在 iPhone 17 Pro Max 上，Card Editor 的顶部保持在记忆来源/Renderer
  边界之下，Renderer 上方摘要和 Card Editor 的上边界保持独立。

### Slice C：视觉与命中细节

- 统一模块胶囊的淡蓝色视觉、紧凑高度和右上角删除按钮；补充卡片底部的简短
  组合与实时预览说明。
- 让录入框右侧空白区域可以落到尾部文字节点。
- 保留原生 TextField 的光标定位和键盘删除行为。
- 将记忆表达预览标题明确为“智能模块表达预览”，让首次使用者知道预览内容来自
  当前录入的内容模块。

## 验收标准

1. 进入“卡片内容”后可以直接看到四个固定区域，不需要逐行展开。
2. 四个录入框均显示当前已保存/当前草稿内容。
3. 任一区域文字或模块变化后，Renderer 的对应位置实时变化。
4. 右下区域变化不会被错误写入其他区域；默认照片说明仍取右下结果。
5. 编辑页没有区域标题右侧重复预览，也没有录入框下方的第二份组合结果。
6. 点击“完成”后四个区域一起保存，已有配置应用链路和状态提示继续有效。
7. 现有 Memory Engine、Layout Engine、Renderer、Export、PhotoKit、持久化和生产认证边界保持不变。

## 验证命令

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj \
  -scheme PhotoMemo \
  -configuration Debug \
  -derivedDataPath /tmp/PhotoMemoDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  -quiet build
```

聚焦测试、`git diff --check`、签名 iOS Debug 构建及 iPhone 17 Pro Max 覆盖安装在各 Slice 完成后执行；
本 Slice 的签名包已安装，但最后一次自动启动因设备处于锁屏被系统拒绝，仍需解锁后人工复测键盘态。

### 2026-08-07 双模式入口验证补充

- `PhotoMemoiOS` 无签名 iOS Debug 构建通过。
- `V1ModulePanelCoordinatorTests` 与 `IPhoneResponsiveLayoutContractTests` 聚焦测试通过，
  `git diff --check` 通过。
- 签名 iOS Debug 包以 `generic/platform=iOS` 构建通过；目标 UDID
  `863C2747-6742-5E93-B715-6F89DBF90B31` 当前由 `devicectl` 报告为 `unavailable`，
  因此本轮尚未覆盖安装，待设备恢复可用后继续原地安装与人工复测。

### 2026-08-07 目标设备覆盖安装完成

- 目标设备恢复为 `available (paired)` 后，签名包已原地覆盖安装并成功启动
  `com.serydoo.PhotoMemo.iOS`。
- 未卸载应用，未清除手机本地数据；真机快照保存为
  `/tmp/PhotoMemo-UI17PM016-double-mode-installed.png`。
- 快照确认 Card Editor、四区录入面、键盘和顶部“＋模块”入口已加载，Renderer/配置页面仍在
  编辑器后方保持可见；完整的逐区点按、候选插入、右侧光标和空白区收起仍由人工验收完成。

### 2026-08-07 胶囊退格删除与高度收敛

- 移除模块胶囊右上角删除按钮，胶囊统一压缩为 `34pt` 高度，和文字输入保持同一行高节奏。
- 新增键盘退格语义：当当前文字节点的光标位于起点、且左侧紧邻内容模块时，退格会移除该模块；
  没有相邻模块时不产生无意义的脏状态，普通文字退格行为不变。
- 退格删除复用 `V1DraftMutationCoordinator`，保留活动文字节点焦点、草稿顺序、Renderer 实时刷新
  与右下照片说明映射；没有改变持久化格式或任何引擎边界。
- `V1DraftMutationCoordinatorTests` 与 `IPhoneResponsiveLayoutContractTests` 通过，
  `git diff --check` 通过；无签名 iOS Debug 构建和签名 iOS Debug 构建均通过。
- 签名包已覆盖安装到目标 iPhone 17 Pro Max 并启动；设备随后停留在系统解锁界面，模块退格删除、
  光标连续输入和键盘态仍需解锁后的人工验收。

### 2026-08-07 胶囊轻量化与候选入口合并

- 模块胶囊进一步收敛为 `30pt` 高度，水平内边距和图标间距同步缩小；录入框行高降为约 `42pt`，
  但保留整行命中区域，避免为了视觉压缩而牺牲光标定位。
- 模块与文字节点间距收紧为 `1pt`。没有自定义前置文字时继续保持真正空白，不自动写入示例短语。
- 顶部“＋模块”改为候选区开关：输入模式点击后收回键盘并展开候选区，再点一次即可收起；候选区
  内移除独立关闭符号，减少与 Card Editor 标题/完成按钮的竞争。
- 候选分类的横向溢出提示线加长为 `34pt`，仍只在可横向滑动时显示，不改变候选项的滚动和插入语义。
- 当前活动文字节点在候选区收起、键盘暂时不可见时保留轻量蓝色插入位置提示。该提示表示活动文字节点，
  不是字符级 caret offset；跨多个胶囊的空格键长按拖动仍需要统一 TextKit 文本流，留作独立架构切片。
- `V1DraftMutationCoordinator`、Memory Engine、Layout Engine、Renderer、Export、PhotoKit、持久化边界不变。

验证：`V1DraftMutationCoordinatorTests` 与 `IPhoneResponsiveLayoutContractTests` 通过；`git diff --check`
通过；无签名和签名 iOS Debug 构建均通过。签名包已覆盖安装到目标设备，安装未卸载应用、未清除本地数据；
由于设备随后回到锁屏，新的胶囊高度、入口切换和键盘态仍待解锁后的人工复测。

### 2026-08-07 空节点原生化与键盘间隙修正

- 纯模块开头的区域不再自动渲染左侧前置输入节点；已有预设模块直接从录入框左侧开始，避免
  “短语”占位符把模块推离边界。需要继续输入文字时，仍由真实文字节点承载系统键盘输入。
- 所有空文字节点继续保留原生 `UITextField` 的点击和光标命中区域，但占位文案改为空字符串，
  不再显示“短语”、多个假输入块或蓝色占位底色；活动位置只保留细蓝色 caret 提示。
- 四个区域标题改为录入框上方左对齐，录入框获得完整横向宽度；四区内容仍由内部垂直 ScrollView
  管理，候选区、键盘和 Renderer 边界不变。
- Card Editor 的背景和圆角容器现在覆盖到底部键盘避让区域，避免键盘与编辑器之间露出配置页面的
  “保存当前配置”按钮；编辑内容本身仍在键盘上沿之上裁切和滚动。
- `V1DraftMutationCoordinator`、Memory Engine、Layout Engine、Renderer、Export、PhotoKit、持久化边界不变。

验证：`V1DraftMutationCoordinatorTests` 与 `IPhoneResponsiveLayoutContractTests` 通过；`git diff --check`
通过；无签名 iOS Debug 构建通过，签名包已覆盖安装到目标设备（数据库序列 `3168`）。设备当前锁屏，
纯模块左靠齐、空节点无占位文案、键盘间隙和四区滚动仍待解锁后的人工验收。

### 2026-08-07 原生光标收敛与键盘上方收起入口

- 四个区域继续保持独立编辑流；本 Slice 不合并区域，也不改动 `V1EditorDraft`、Memory Engine、
  Layout Engine、Renderer、Export、PhotoKit 或持久化边界。
- 移除分段输入层额外绘制的“当前插入位置”蓝色竖标，避免多个区域残留看似光标的蓝线；当前焦点和
  键盘光标由原生 `UITextField` 自己呈现。跨多个胶囊的连续拖动与字符级插入位置仍留给后续四区独立
  TextKit 流切片。
- 键盘出现时，在 Card Editor 可视编辑区域底部、键盘上方增加独立的系统键盘收起按钮，按钮只执行
  `resignFirstResponder`，不关闭编辑器、不清空当前区域、不改变模块候选上下文；原有键盘工具栏入口保留
  作为辅助路径。
- 聚焦测试 49 项通过；`git diff --check` 通过；无签名 iOS Debug 构建和签名 `PhotoMemoiOS` Debug
  构建均通过。签名包已原地覆盖安装到目标 iPhone 17 Pro Max，数据库序列为 `3176`，并成功启动
  `com.serydoo.PhotoMemo.iOS`。
- 本轮未卸载应用、未清除手机本地数据、未推送 GitHub；按钮位置、四区滚动、键盘收起后再次编辑和
  候选插入仍需用户在已启动的真机上完成最终人工验收。`TX-001`、`BP-001` 继续保持未关闭，生产认证
  仍为 `FAIL (Conditional)`。

### 2026-08-07 键盘边界贴合与候选前插入锚点

- 收起键盘按钮改用系统键盘真实顶部坐标，直接贴合键盘上沿；移除额外横线和空白带，避免把 Card
  Editor 行高或底部保存操作暴露在键盘与编辑器之间。
- 模块胶囊压缩为 `28pt`，文字改为 footnote 级别、内边距收紧；四区仍各自维护原生输入和退格删除。
- 候选区展开但尚未点选时，当前区域保留一个低对比度的插入锚点；点选后锚点跟随新插入胶囊，帮助用户
  看见当前插入上下文。它不是跨多个文本节点的字符级 caret；本轮不迁移 TextKit。
- 直接运行的编辑器契约与草稿变更测试通过，`git diff --check` 通过；无签名 iOS Debug 构建、签名
  generic iOS Debug 构建及签名校验通过，Bundle ID 为 `com.serydoo.PhotoMemo.iOS`。
- 目标 iPhone 17 Pro Max 已恢复 `available (paired)`；签名包已原地覆盖安装并启动，数据库序列为
  `3192`。未卸载应用、未清除本地数据、未推送 GitHub。
- `TX-001`、`BP-001` 仍未关闭，生产认证继续保持 `FAIL (Conditional)`。
