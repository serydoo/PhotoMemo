# 卡片内容编辑：上滑照片，保留真实结果

2026-10-10 / Product Loop / P1 / 所有者明确授权四种卡片编辑页实施。

## 观察与目标

横屏compact-height当前预览在编辑ScrollView外，整张照片固定且挤压字段。已撤回的高度适配与无保留区域的整体滚动不作为实现基础。本片允许上方照片随页面滚出，滚动终点保留完整真实内容区域；不缩放卡片，不重复渲染一个独立结果条。正常配置列表、手机竖屏、大屏regular/regular并排维持现状。

## 所有权和范围

MemoryCardEditorPageSurface拥有外层滚动及检查区剩余高度；MemoryCardPreviewSection报告实际结果区域尾部高度；ConfigurationPreviewViewportSpec从既有Classic/GlassCard/Minimal/FilmMark布局计算区域，不更改Layout/Renderer规则。输入滚动、焦点、caret、IME、undo仍由原检查区/UIKit处理。配置与输出不变。所有状态临时，不进入Preset。既有横屏预览开关保留。

## 几何与交互

仅compact-height卡片编辑启用纵向外层ScrollView。完整预览高度P，保留尾部R，可用高度V；检查区固定显示高度max(0,V-R)，外层最大滚动距离P-R，故到达终点后真实卡片尾部占据顶部R，下方检查区占据剩余空间。R包含内容区域到卡片底部和少量背景及页面底部边距。Classic取完整白框，Glass取panelFrame，Minimal取现有bar布局，FilmMark取解析后的substrate/effect范围。横/竖预览画布在此模式均显示完整初始画布，不使用键盘2.4裁切策略，也不随键盘缩放。此模式关闭预览自有的优先拖动手势，让外层ScrollView处理上滑；其它页面的预览手势保持。

键盘出现时外层定位到检查区底部以让输入可见；之后用户可拖回完整照片。外层不随滑动收起键盘，键盘由原按钮管理。余高不足时字段仍按原尺寸在内层滚动，预览开关可释放空间；不伪称任意极端窗口能同时容纳全部区域。旋转跨布局分支的focus/IME/undo保持需物理验证。

## 验证

四种样式、横竖画布、Classic白框与Glass圆角不截断、FilmMark位置参数变动、键盘上下、收起预览、实时文本、所有字段可达、旋转、长文、四语言/RTL/Reduce Motion。先几何专项与签名物理构建安装；实际触摸与IME/VoiceOver待人工验收。模拟器不替代物理门禁。本片不涉及Photos导出或后台。

## 实施与验证结果

五个源码/测试文件，UI临时高度Preference传递，没有新增持久状态或第二张预览。外层最大偏移通过内容总高度自然限制，真实结果尾部留在顶部，内层继续滚动字段。FilmMark按原始校准画布解析后缩放保留范围，避免小视口重新解析字体造成偏差。

专项最终MemoMarkCardEditorRetainedFocused.xcresult：80通过、0失败、0跳过、无runtime warnings。新增四种样式×横竖画布的内容区域完整保留与边界测试。签名配对iPhone Debug构建退出0，覆盖安装成功；治理与git diff --check通过。编译存在既有测试未使用变量警告，未跨范围清理。未进行新的手机触摸/IME/VoiceOver人工验收，不声称该项已完成；无Git提交/推送或商店动作。

## 所有者物理验收反馈

2026-10-10，向所有者请求手机横屏进入卡片内容，从预览上滑并打开键盘，优先观察经典白/GlassCard完整结果与录入可操作性。所有者回复「可以，基本这样吧」。记录为本轮核心交互暂定接受，停止额外视觉微调；该回复不扩展为四样式逐项、FilmMark位置极值、旋转IME/undo、四语言/RTL或VoiceOver完整验收。剩余项目留待后续独立验证，不阻碍本轮范围收尾。未授权本轮GitHub同步，当前无提交/推送。

## 延伸片：横屏配置中心

所有者授权横屏配置中心也采用相同局部预览保留与下方滚动方式。Product Loop/P1。将compact-height共享滚动布局从卡片内容编辑扩展到配置列表；预览区域报告也覆盖普通配置状态，四种样式沿用同一布局区域。下方仍为原有editorScrollView，保留展开分组、FilmMark scroll request、保存与更多的右侧入口。卡片编辑实现保持。普通配置不因全局键盘通知触发编辑专用自动定位。非compact-height及持久配置/Renderer不变。验证共享几何与配置响应契约、签名iPhone构建安装；物理上下拖动/分组可达性待验。

延伸片实现：PageSurface compact-height共享外层滚动覆盖配置列表，预览状态按compact-height报告同样的真实结果区域；编辑专用键盘自动定位仅在editorContentOwnsScrolling下触发。签名iPhone Debug构建退出0；MemoMarkConfigurationScrollFocused.xcresult最终127通过、0失败、0跳过、无runtime warnings，包含配置选项、响应布局与四样式几何。diff检查通过；配置中心实际拖动/各分组展开可达性仍待物理确认，卡片编辑之前的暂定接受不扩展到本片。
