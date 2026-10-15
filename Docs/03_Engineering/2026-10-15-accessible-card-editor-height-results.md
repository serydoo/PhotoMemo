# 大字号输入文字裁切修复结果

日期2026-10-15；V5.6局部显示修复，生产改动限MemoryCardTextKitEditorSession.swift。独立iPad13/iOS26.4实际取证；原图图/iOS26.5仅安装正常字号查看候选，没有编辑、保存或修改其文字。

## 两层根因与最终修复

1. SwiftUI输入框高度仅分普通40pt、辅助52pt，最大subheadline字体的行盒已超过52pt。现在按系统DynamicTypeSize→UIContentSizeCategory→UIFont真实行高计算下限，并保留原有上下6pt留白。该环境最大实测高度71pt；普通字号仍为40pt。
2. UIKit字号自动放大后，既有富文本段落行高和信息块基线仍保留旧值。因此只增高输入框的中间候选截图03仍裁切，不能算修复成功。最终在原有TextKit/session中原位更新字体、段落行高、文字基线及信息块bounds.origin.y；不替换字符，不重建session/UITextView，不重置draft或触发onDraftChange。精确保留selectedRange，刷新期间平衡关闭/恢复undo registration；缓存已用字体点大小避免每次layout重复改属性。

活动markedTextRange存在时不更新属性；完成组合输入后再刷新。因此输入中途切字号的拼音和焦点保持，不宣称组合中途的视觉样式即时全部切换。原有信息块图像/尺寸保持；这轮没有把小信息块重画为大字体。

## 实际验证

- Debug Simulator最终编译通过（typography-build.log，exit0）。没有将旧签名Release结果冒充本文件修复后的构建；本候选尚未重跑签名Release、完整主机或自动UI套件。
- 04正常→05最大→06恢复正常：四个字段文字逐字相等，字段高度40→71→40；05和11实际截图中普通文字完整居中显示。native-assertions.json记录实际AX断言。
- 07拼音nihao组合→08最大→09普通：组合文本逐字相等、focused=true；选择真实“你好”候选后正确上屏，随后切最大字号文字与焦点保持。没有用粘贴冒充组合输入。
- 12去除测试文字，14插入测试日期模块，18–21补验焦点/快捷键；22最终移除测试模块。四字段恢复比较通过（忽略私有零宽哨兵重复），恢复large字号并终止/关闭QA，未点击保存或操作Photos/导出/Share/Commerce。
- 初次点击未切页，确认Baguette输入被Device Hub占用；一次heal恢复输入服务，日志明确SpringBoard restarted，未擦除容器。失败AX/截图及脚本失败保留，不当作产品通过证据。

## 仍未通过的验证与界限

- 撤销/重做：IME候选提交后系统撤销按钮不可用；模块插入后的focused Command-Z/Shift-Command-Z也未观察到内容变化。本轮不计通过，未取得旧候选对照，不能断言是既有缺陷或此次变化导致。历史保留策略已在源代码审查，但实际撤销/重做仍需单独排查；完整编辑器验收未完成。
- 最大辅助字号的信息块图像仍使用原有固定胶囊规格，模块库类别标签仍可能省略；本轮关闭的是普通文字的纵向裁切，不是完整辅助功能矩阵。
- 普通iPhone最终视觉、Duo/macOS、真机、所有语言/字号/输入法组合仍不在本轮通过范围。前一轮自动测试取消记录继续保留。

## 审查与边界

显示刷新留在原有TextKit显示属性所有者；字段高度采用系统字体事实，不增加设备型号判断或业务状态。isApplyingExternalState与marked-text guard阻止中间属性刷新向业务草稿发事件；所有文本及模块身份不变、原始选择范围不变、无removeAllActions。未改业务架构、Memory/语义真值、Layout Engine、Renderer、PhotoKit、Live Photo、Share、持久化或Commerce职责。没有Git提交/推送/发布。当前代码是具有上述验证边界的本地候选。

材料：00修复前；03仅增高但未彻底修复；05最终最大字号；06普通恢复；07–11真实拼音；14–21未通过的撤销尝试；22恢复。owner-review为原图图正常字号查看现场。
