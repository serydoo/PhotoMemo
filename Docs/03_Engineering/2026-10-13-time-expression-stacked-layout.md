# 时间表达：上下布局、宽度适配与既定文案恢复

Product Loop / P2，iOS Presentation。用户明确要求选择栏与表达示例统一上下排列，撤掉选择栏下方说明；随后再次要求遵守已批准的iPhone文案修正。

## 决策与边界

顶部恢复2026-10-12已批准的“围绕设定的时间锚点，选择不同语气的时间表达。”，四语言既有tone_guidance资源保持；不拼接权益长句。下方重复说明与权益说明区取消，表达示例保留。权益仍通过pendingMemoryDisplayStyle及既有保存动作校验，本轮不改Commerce职责与行为。

这明确修订该组件原先紧凑横向排列及下方权益说明，其他普通iPhone合同保持。所有尺寸选择栏在上、示例在下；regular区域在文字最小宽度判断后展开显示宽度，compact保留原固有宽度与滚动/menu回退，辅助功能大字体仍使用menu。尺寸判断来自局部呈现能力，不识别机型名。删除该组件已失效的横向Layout与240pt示例宽度限制。

ConfigurationSession、Memory/Presentation语义、Layout Engine、Renderer、PhotoKit、Live Photo、Share、持久化和Commerce业务代码均不改。无新增运行时依赖。

## 完成与证据

- iOS Simulator Debug最终源码构建通过；新包覆盖安装至现有iPad13和iPhone17Pro模拟器，未卸载/清除数据。
- 最终重新构建的ConfigurationOptionList、Commerce UI、Narrative Language、Release UI定向合同测试：66 passed / 0 failed / 0 skipped。只调整既有Commerce UI合同中已被用户修订的下方提示断言，保留pending和保存权益路由检查。
- iPad13 / iOS26.5：选择栏AX宽692pt，示例宽693pt（边框差）；恢复短文案；选择成长后下方示例更新；实际横屏保留上下关系。图图/生日既有数据保持，未保存新配置。
- 普通iPhone17Pro / iOS26.5：402pt内容窗口，顶部短说明AX高度13.33pt、宽235.67pt，实际截图完整单行；下方直接显示选择与示例，保留窄屏适配；纵横原始PNG和AX已保存。为观察配置暂时折叠预览，结束前恢复。
- Baguette输入遮蔽通过本机工具heal处理，恢复实际页面切换；命令成功码不替代AX/截图结果。
- 源码与测试差异复核：只在展示层调整布局/说明。保存权益路由未变；四语言资源未改。未stage/commit/push。

材料：$HOME/Desktop/MemoMark-时间表达上下布局-2026-10-13，含task-only.patch、日志、AX、完成版原始截图。首次长文案候选不属于最终版本，相关证据在superseded-long-copy。

## 未验证

实体设备按用户安排延期；Duo/iOS27.1环境仍在系统启动阶段失败，不能报告Duo已视觉通过。最大字体、VoiceOver、四语扩展、macOS视觉与媒体/Share/Commerce端到端不在本轮截图验收范围。相关现有合同测试通过不等于这些手动验收。
