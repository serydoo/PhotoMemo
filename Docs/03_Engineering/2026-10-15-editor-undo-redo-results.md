# V5.6 编辑器 Undo / Redo 与字体历史修复

2026-10-15，main d17bf849，本地候选2.3.7(132)，未提交。

## 结论与范围

前轮大字号修复的 Undo/Redo 未验证项现已完成一组明确的原生回归。运行时确认 UITextView 已有有效 UndoManager，无须新增 manager 或重建 session。最终生产增量仅 MemoryCardTextKitEditorSession.swift 的3行（含1行注释），相对本轮 before 副本：恢复历史 attributedString 后清除 typographyPointSize 缓存并调用现有 refreshTypographyIfNeeded。完整 git diff 还含前轮大字号改动，请用桌面“本轮源码增量.patch”区分。

真实根因：历史 attributedString 带有当时的字体/段落度量；在大字号下撤销模块时，小字号快照覆盖了当前外观，而字号缓存仍认为当前大字号已应用。内容历史应恢复内容和选择，显示字体由当前 view traits 决定。复用现有原位刷新，继续保留 marked-text guard、选择范围、平衡的 undo registration 暂停/恢复和 session 身份。未引入生产依赖，未修改业务职责或持久化路径。临时 DEBUG 诊断已从源码移除，其副本留在桌面诊断材料中。

## 原生证据

独立 iPad13 / iOS26.4，最终 Debug：
- 原生输入7 → Command-Z → Shift-Command-Z，值正确回退与恢复。
- 插入日期模块 → 聚焦 → Undo → Redo，U+FFFC 模块计数及其余内容正确。
- 插入后切换最大辅助字号 → Undo → Redo，四个输入框71pt，文本保持当前大字号。
- 硬件输入 nihao：AX 记录 ni+U+2006+hao 的实际组合态；Space 提交你好；Undo/Redo 正确。
- 最后恢复 large 字号与原始四区内容；独立 QA 关闭。未保存配置。

RED/GREEN 原始截图15-max-undo.png：相同71pt框、相同位置“手持”黑色字形像素高度13.5pt→41.5pt。verify_evidence.py 只读 PNG/AX，不编辑截图。内容比较仅去除既有私有 U+200B，保留模块与输入法组合标记。

独立 iPhone17e / iOS26.5，最终 Debug：输入7、Undo、Redo、横屏、返回竖屏，原文/插入值及焦点断言通过；常规框40pt。最后撤销恢复原始草稿、关闭 QA。实际光标在“记录”之前，并非末尾；最终断言按真实插入位置验证。导航定位失败和错误末尾假设均保留在 phone/，不计通过。

最终原生证据10个聚合断言通过，含四区恢复、字号 RED/GREEN、phone 旋转内容与焦点；这是原生操作与证据断言，不是10个 XCTest。普通 iPhone 全导航/所有键盘矩阵未在本轮全量重跑。

## 构建与审查

最终 Simulator Debug 构建退出0；最终签名 iOS Release generic build 退出0；严格 codesign --verify --deep --strict 再次退出0。此前“大字号修复最终签名 Release 未验证”在本候选上已补齐。quiet 构建日志为空属于成功时无输出；原始工具执行退出码及签名结果分别保留。

检查最终增量仅缓存失效及既有显示刷新调用，历史 inverse 注册/草稿投影/外部回调顺序保持；刷新只处理显示属性，遵守 markedText 和 undo registration guard。没有新增业务 owner、媒体操作、配置/权益路由或生产依赖。git diff --check 在最终整理时执行。完整 host/XCTest 未在本轮重跑；历史146/86/2145等数字属于先前候选且存在重叠，不合计为本版结果。

## 证据目录与限制

桌面：$HOME/Desktop/MemoMark-V5.6-撤销重做-2026-10-15。
final/ 是最终 iPad；根目录是诊断/RED；phone/confirmed 是最终 phone；owner-review 是提供给用户的原13寸图图场景。截图浏览.html 索引原始文件。

仍待后续：最大字号胶囊/模块库分类的可读性、完整 VoiceOver/RTL/多窗口矩阵、Duo runtime/姿态验证；真机及 Photos/Share/LivePhoto 生命周期验收按用户安排后置。构建与这些编辑回归不能代替媒体发布认证。没有 stage、commit、push、云上传或发布。

## Mac 环境实时复核

本轮当前源码 native Mac Debug 构建退出0，候选进程路径核对为 /private/tmp/MemoMarkV56Mac20261015/Build/Products/Debug/MemoMark.app/Contents/MacOS/MemoMark。Finder 的 CUA AX/原生截图成功，但选择此 MemoMark 候选窗口时仍报 ScreenCaptureKit SCStreamErrorDomain -3811。仅 Finder 通道可用，MemoMark 窗口/缩放验收仍未完成；不能据 Finder 成功宣称 Mac 环境阻塞已消除。mac/ 中记录构建、进程及失败，未循环尝试或调整系统权限。

## 用户可查看场景

原 iPad Pro13 M5 / iOS26.5 C244… 已保留图图场景，装入最终 Debug；owner-review/ 保存概览、配置、编辑纵横与返回竖屏原始 PNG/AX。编辑区四个字段40pt，内容未编辑/保存。Baguette127.0.0.1:8421 服务曾停止，已按原端口恢复并在前台打开对应13寸设备实时画面。
