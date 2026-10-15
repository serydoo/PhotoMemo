# MemoMark V5 当前进度与后续 — 2026-10-15

基线 main d17bf849，2.3.7(132)，当前候选仍在既有未提交工作树。此表依据本地 scoped specs / 结果回执整理；“已实现”不代表所有设备验证完成，历史结果不挪作本轮最终候选认证。

| 阶段 | 已实现内容 | 当前证据与缺口 |
|---|---|---|
| V5.1 | Navigation Presentation / Content Arrangement 与几何布局解耦，capability foundation | 既有主机/构建与 phone 真机阶段证据保留；后续宽屏候选有新增代码 |
| V5.2 | iPad Overview；横向双栏，纵向底部操作 | 原生13寸本地截图已留档；无实体iPad验收 |
| V5.3 | iPad Configuration；纵向顶部预览+单栏，横向双栏 | 图图/生日/2025-05-26场景，后续时间表达上下布局和顶部短说明已修正 |
| V5.4 | Mac Overview / Configuration region policy 与页面接入 | native Mac 构建已有；本轮重建通过；Finder截图成功，但MemoMark窗口仍SCStream-3811，实际窗口验收未完成 |
| V5.5 | Duo native reserved region / vertical toolbar capability 与页面接入 | 代码与合同证据存在；已安装27.1 profile 的旧 migration失败，尚无新的成功 boot/真实姿态验收 |
| V5.6 | 小窗口、标题栏避让、语言标题、中文组合输入、编辑列宽与大字号修复 | 多轮本地原生证据已归档；本轮进一步完成 Undo/Redo 与字体历史回归，phone旋转与signedRelease补齐 |

## 本轮新增闭环

1. 原生 UndoManager 运行时诊断，保留临时诊断源码/日志，最终源码不残留诊断。
2. 修复历史 attributed snapshot 携带旧字号：恢复后按当前 traits 原位刷新，生产增量3行。
3. 最终 iPad 文字/日期模块/拼音提交 Undo+Redo；最大字号撤销不缩回；QA四区草稿恢复。
4. 最终 iPhone17e 普通字号40pt、文字 Undo+Redo、横竖屏内容及焦点保持；草稿恢复。
5. 最终 Simulator Debug、signed iOS Release / strict signature 已通过；新增 readonly AX/像素断言10项通过，不称为 XCTest10项。

## 接下来可继续做的本地工作

优先处理大字号模块胶囊与模块库分类可读性，以“不缩字掩盖截断、不改语义/持久化”为边界；先验证最窄窗口和普通 phone，明确可读性与可操作性合同，再做小步实现。之后是 VoiceOver 顺序/标签、RTL与语言长度、Inspector/Popover/焦点、多窗口切换的实际矩阵。Mac复核仅Finder截图成功，MemoMark候选仍SCStream-3811；实际窗口矩阵仍受阻。Duo需先获得成功启动的本地运行时，再谈Book/Tabletop/外屏验收，不能以普通iPad横竖屏代替。

## 仍须单列的验收

- 最大字号下胶囊自身仍28pt、模块库分类有省略现象，尚未解决。
- 本轮未全量重跑 host/XCTest；之前中断/失败记录保留。已有146/86/2145数字对应不同候选且有重叠，不能相加。
- 真机整体验收、Photos / Share / Live Photo / EXIF 真实生产媒体及跨OS生命周期按用户安排后置。本轮没有因此改动业务所有权，也不声称媒体发布认证完成。
- 未做Git提交/推送、云端上传、Cloud/TestFlight/AppStore操作。

最新材料：桌面 MemoMark-V5.6-撤销重做-2026-10-15；详见2026-10-15-editor-undo-redo-results.md。旧大字号报告中的 Undo/Redo 与最终signedRelease缺口由本回执的限定场景覆盖；旧失败记录保留。
