# MemoMark V5 工作进度与下一步

核对日期：2026-10-14。当前本地 main 基线 d17bf849，候选版本 2.3.7 (132)。V5 改动仍在未提交工作树中；本报告不是 GitHub、TestFlight 或正式发布状态。

## 阶段状态

| 阶段 | 已完成的实现 | 验证与未闭环项 |
|---|---|---|
| V5.1 Adaptive Presentation Foundation | Navigation Presentation 与 Content Arrangement 解耦；能力决定呈现；AdaptivePageLayout 保留几何职责 | 单元/合同与构建已有证据；此前 iPhone 双横屏导航与动作有真机记录；完整辅助功能/键盘矩阵未完成 |
| V5.2 iPad Overview | Home 与 Progress 同时呈现但保留各自业务所有权；竖屏上下布局、主要按钮底部；横屏双栏 | 13 英寸 iPad 本地模拟器与截图已有证据；实体 iPad 留待用户统一验收 |
| V5.3 iPad Configuration | 竖屏顶部预览、下方编辑；横屏预览与编辑双栏；窗口与键盘几何分离 | 本地焦点/旋转测试及截图已有证据；时间表达统一上下排列，撤销底部重复说明、恢复既定顶部短说明；窄窗口/Stage Manager/硬件键盘矩阵尚未完整 |
| V5.4 macOS | Overview/Configuration 入口与独立区域滚动布局；窄窗口回退 | 原生构建与策略测试通过；实际 AppKit 窗口、焦点、Inspector、Undo、Popover 交互验收待补，SCStream-3811 阻断当前捕获 |
| V5.5 Duo | 系统保留区域几何接入现有布局；外屏固定右侧导航与上下动作候选实现；Book/Tabletop 探针 | 曾有 Book 导航通过与 Tabletop Overview 几何截图；Tabletop 配置 XCTest 查询超时；当前 Duo 运行时 Data Migration 失败；外屏实际按钮点击和状态连续性尚未闭环 |
| V5.6 跨界面验证 | 本轮推进第一批：完整主机测试、签名 Release、iPad 深色/最大辅助功能字号/界面语言取证 | 当前只覆盖明确记录的配置；不等于全平台、全字号或全部语言页面验收 |

## 本轮已获得证据

- 当前源码候选完整主机测试：2145 个测试通过、0 失败、1 个既有跳过。参数化执行计数与唯一测试计数不同，采用 xcresult 顶层统计。记录有既有 FixtureExportReadback QoS 运行警告，未改动该媒体路径。
- 当前源码候选签名 Release 构建成功，严格签名校验成功。该构建在本轮后续界面资源修复之前；修复后验证单列。
- iPad 13 英寸：深色正常字号 Overview/Configuration；最大辅助功能字号 Overview/Configuration 与滚动后时间表达。配置保持上下布局，保存入口可到达，表达方式使用菜单回退。
- 英文、日文、韩文进程级语言覆盖下实际入口标签已读回；恢复正常启动后中文入口已读回。未更改持久化语言偏好。
- 语言检查发现 FilmMark 样式标签缺失四语言资源条目，导致非中文界面回退到“胶片时间”；本轮补齐界面标签资源。用户名称、锚点标题、输出文字保持原样。

## 仍需继续的本地工作

1. 修复/获得可用 Duo 本地运行时，再完成外屏右侧栏动作、Tabletop 配置和姿态切换编辑连续性。当前环境故障与产品行为不能混为一谈；不能把所有未完成项目归为真机验证。
2. macOS 原生交互验证：窗口缩放、焦点、Inspector、Undo 与 Popover。构建成功不代表这些已验收。
3. iPad 窄窗口、Stage Manager、硬件键盘，以及完整 VoiceOver/RTL/字号/界面语言矩阵。当前取证不覆盖所有这些组合。
4. Native ArrangementView 编辑器包装仍暂缓，直到姿态切换连续性有证据；当前布局已经消费原生能力和保留区域，不为 API 迁移而承担编辑状态重建风险。

## 用户后续统一进行的真机项目

普通 iPhone 最终候选竖横屏回归；实体 iPad 预览/编辑/键盘与旋转；Duo 外屏与姿态切换；真实照片、Live Photo、Share 与权限生命周期抽验。全部按当前冻结的业务合同验收。模拟器/构建并不替代这些证明。

## 改动边界

本轮产品修复仅允许四语言 Localizable.strings 的 FilmMark 样式标签。治理与取证文档增量写入；不修改业务架构、渲染、输出、PhotoKit、Share、持久化或 Commerce 所有权。无上传、提交、推送或发布动作。所有已有未提交内容保留。

## 修复后验证

四资源既有字节前缀全部保持，只追加 `胶片时间` 翻译条目。22 项既有本地化测试通过（0 失败/0 跳过），四文件 plutil lint 通过。修复后 iOS Simulator Debug 构建、签名 iOS Release 增量构建与 codesign 严格校验均成功。完整 2145 测试结果为修复前源码候选；资源修复采用上述聚焦验证，不混称为修复后完整重跑。

### 界面读回范围与安装现场

修复后英文、日文配置页原生 AX 已读回 FilmMark，截图另存。韩文初次读回仅有两个可见样式，未把资源检查通过当作该选项实际显示通过；保留等待/失败记录，未改 Commerce。首次重新安装后出现处理状态提示及默认配置中间现场，关闭提示并回到此前未签名模拟器构建路径后，图图的表达再次可见；没有卸载、擦除或直接改写容器。安装/初始化现场差异仍需在更完整启动验证中排查。四语言页面审查仅覆盖记录的场景，不代表所有标签或生产输出语言都已验收。

最终正常启动已恢复中文入口与图图表达，界面 light/text-size large 读回保留；13 英寸 iPad 本地观察页继续保留。最终中文 PNG 和带模拟器边框 JPEG 已保存。韩文 FilmMark 原生选项等待后仍未展示，保持未验证。


## 2026-10-15 — V5.6 window/keyboard increment completed

See `2026-10-15-v5.6-window-keyboard-results.md` (under 03_Engineering). Actual iPad375×892 window fit/menu/titlebar fix, JA/KO UI tone labels and Korean FilmMark visibility verified. Final focused host146/0; tone suite86/0 (overlapping); final phone choice1/0, landscape rail1/0; signed Release and strict signature passed. iPad26.4 software keyboard/rotation focus1/0 before final UI fixes. IME, full Stage Manager/Mac/Duo matrix and physical acceptance remain open; native window automated coordinate limitations retained with failures. Desktop evidence: MemoMark-V5.6-窗口与键盘-2026-10-14. No Git/release operation; business ownership frozen.


### 2026-10-15 V5.6 Chinese pinyin follow-up

Independent iPad13/iOS26.4 native keyboard: nihao→你好 candidate commit, committed text rotation, active zaijian composition across portrait/landscape/portrait and 再见 commit verified by PNG/AX equality/focus assertions. Production/test source unchanged. Reused focus UI test failed at TextView discovery before rotation; kept as a separate automation reliability gap, not counted passed. Native Mac capture stillSCStream-3811; no new Duo runtime. See `2026-10-15-v5.6-chinese-input-results.md` in03_Engineering; desktop MemoMark-V5.6-中文输入验证-2026-10-15.
