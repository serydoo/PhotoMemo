# GitHub 参考项目与 MemoMark 下一阶段投入审查

日期：2026-10-10。源码基线：008e3d6e；本轮为只读代码/外部资料审查与研究记录，不修改生产代码、不安装 Skills、不同步远端。产品阶段仍遵循 V4；后台材料中的 V5 是工作范围标签，不自动改变产品阶段。

## 输入与证据范围

已读取 ChatGPT「MemoMark学习GitHub汇总」（6ac7748b-67f8-83ec-9898-03cba3aaf008）、大屏接受交接、10月9日后台准入/Release边界及10月10日源码同步清单。Chat On Steroids Core 实际成功读取当前工程记录；没有仅凭连接器列表声称可用。

当前源码检查点完整测试摘要为2088通过、1跳过、0失败；正式工具链Release编译通过。历史15源素材真实配置、Live Photo配对及重叠Share证据限定对应Beta/DEBUG候选。Release Share Continued Processing仍未启用。这里引用已有证据，本轮不声称重跑构建、测试或真机。

GitHub匿名API遭遇403限流，改用公开页面和raw文件；因此不是十库逐提交增量审计，也不声称所有仓库无新提交。重点读取SwiftUI resizability、FWC Duo具体规则和HIG Duo入口；其它按README/目录定位评估。

## 参考项目的采纳程度

| 项目 | 采纳方向 | 限度 |
|---|---|---|
| twostraws/SwiftUI-Agent-Skill | 高：窗口变化、状态身份、辅助功能、测量驱动性能审查 | 规则作为问题筛查；API以SDK和Apple原文为准 |
| justinwetch/HIGAgentSkills | 高：规范路由、Duo分阶段审查与可复核证据 | 第三方HIG快照，非Apple认证；不执行其安装或多代理命令 |
| FloWritesCode/fwc-swiftui-skills | 高：Duo原生栏、reserved regions、ArrangementView、空间驱动布局 | SDK27.1+分支与实际runtime验证；不把UI玻璃直接用于导出 |
| emilkowalski/skills | 中：交互反馈、可中断动画、减少无意义运动 | Web经验转译为SwiftUI原生；不抄CSS数值 |
| Appllama/appllama-skills | 中：研究真实用户流程与整段录屏验收 | 主要Expo/React Native；不迁移技术栈或照搬高收入App付费墙 |
| expo/skills | 低：跨尺寸、资源与流程验证的方法 | Expo/EAS不是现有Swift工程的实施依据 |
| vercel-labs/agent-skills | 低：组件责任、性能测量、审查方法 | React/Next/RN规则不直接替换SwiftUI架构 |
| twostraws/Swift-Agent-Skills | 中：查找有针对性的并发/测试/可访问性资料 | 社区目录不是实现库；按单项需求选择，避免重复安装 |
| totec448-spec/chat-on-steroids | 工具：连续任务、权限与连接可靠性 | 不进入MemoMark生产依赖；PR1250公开页面仍Open |
| XiaoDuoYa/codex-with-chatgpt | 工具：准确版本绑定与可恢复交接 | PR464公开页面Closed，未呈现Merged；不按未合并提案改流程 |

## 已发现的具体投入入口

### A1 产品循环：预览/编辑/右侧动作的一致空间策略（P1，优先）

源码事实：MemoryCardEditorPageSurface的分栏由regular宽高决定，尚未直接评估键盘后的实际高度和两栏最低容量；之前iPad键盘证据已记录预览顶部裁切。ConfigurationPreviewVisibilityState在regular-height卡片编辑时强制预览可见；Pages仍给右侧toggle，toggle只修改isCollapsed。因此大屏卡片编辑的折叠动作可能没有可见效果：源逻辑确认，当前真机未复测。

 bounded方案：不重写Configuration Center；把容器可用空间、预览观看模式、编辑区域和操作可用性合成一份显示策略。宽度充足使用并排；不足退回可滚动配置；高度不足按比例完整适配预览并保持检查/放大入口。大屏完整预览的既有要求保留：若禁止折叠，应隐藏/禁用对应动作并解释语义，不直接开放折叠改变接受行为。字段行框与UIKit/TextKit所有权不变。

验证：普通手机竖屏/左右横屏、iPad横竖屏及窄窗口、键盘、大文字、预览开关、焦点/草稿/token/IME/undo连续性。成功标准为输出完整、所有编辑项可达、可点击动作有一致效果，而非截图单点好看。

### A2 产品循环：Duo系统容器适配（P1，依赖A1规格）

共享页面导航与动作语义；在支持的系统分支评估原生NavigationStack/TabView工具栏、ArrangementView及reserved-region接口。保持现有右侧设计作为普通大屏/手机横屏路径。Apple原生Duo内屏竖屏会回到横向栏，不把“产品偏好固定右侧”误称系统规则；原生栏与自定义栏不能重复。物理侧、RTL、多任务外缘和折叠区域需要实际验证。布局依据可用空间/保留区；hinge角度只用于交互。

当前只保留SDK探针证据；本轮未重新盘点Duo runtime，不能承诺已可模拟。

### A3 产品循环：真实配置预览/导出语义回归（P1，与A1并行记录，按薄片验证）

后台审计已发现并修正GlassCard补充说明两行契约。下一步优先复用真实持久配置的回归：四种既有样式，空/长/中英日韩内容、Logo来源、预览/静态/Live输出语义一致。不使用metadata-only测试替代真实作者配置；不将每种样式所有媒体能力一概认证。玻璃质感切换单项继续暂放。

### B1 工程循环：后台恢复与生产准入（P0，最高发布优先级）

已有hold、租约、去重、回执、中断恢复实现，不能重复宣称尚未实现。进一步投入事务间终止注入、取消持久化写失败、权限Full/Limited/Add-only/撤销、相册消失、磁盘压力、PhotoKit提交后终止的重建和不重复保存；生产运行策略与DEBUG探针拆分。稳定iOS26/旧系统资源与运行证据单列，没有设备时用模型/故障测试前进，门槛仍开放。继续保留原图及冻结配置；不得为赶进度开启Release实验入口。

### B2 工程循环：测量后改善响应与资源（P1/P2，依赖建立基线）

当前PreviewCoordinator是MainActor同步构建入口，但仅凭此不能断言卡顿。测量文本编辑到预览延迟、重复构建次数、旋转/键盘时刷新、Live处理峰值内存和主线程占用。先确定重算原因，再窄化Observation依赖、取消过期预览或做有界缓存；不凭外部Skill建议全局actor迁移或无界并行。

### A4 产品循环：动态字体、语言、无障碍与克制动效（P1/P2）

四语言键/格式通过不是不同宽度视觉通过。系统字体、VoiceOver动作顺序、selected/disabled状态、44pt目标、RTL物理侧、Reduce Motion、键盘手势优先纳入A1验收。动效只用于确认展开/折叠/状态改变，不改变后台真相，不叠加装饰动画。

## 建议执行顺序

1. 下一UI薄片先写A1共享显示策略规格与失败用例，解决大屏折叠动作语义和键盘容量；保留已接受外观。
2. 后台B1继续沿既有准入材料补故障恢复，独立于UI循环记录，不让UI改动顺带重写执行者。
3. A1稳定后做A2独立SDK原型与运行矩阵；具体Duo环境先刷新确认。
4. A3真实配置回归提供两条主线共用证据；B2取得测量再优化。
5. A4随每轮验收；Appllama/Emil只用于选定用户流程，暂停大范围视觉重做。

本次明确不投入：第五种renderer、模板市场/云相册、任务dashboard、全局替换Skills、技术栈迁移、后台永不终止承诺、复杂玻璃质感展示器。

## 可复核来源

- https://github.com/twostraws/SwiftUI-Agent-Skill/blob/main/swiftui-pro/references/resizability.md
- https://github.com/justinwetch/HIGAgentSkills
- https://github.com/FloWritesCode/fwc-swiftui-skills/blob/main/skills/swiftui-iphone-duo/SKILL.md
- https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
- https://developer.apple.com/videos/play/tech-talks/111462/
- https://github.com/emilkowalski/skills
- https://github.com/Appllama/appllama-skills
- https://github.com/expo/skills
- https://github.com/vercel-labs/agent-skills
- https://github.com/twostraws/Swift-Agent-Skills
- https://github.com/totec448-spec/chat-on-steroids/pull/1250
- https://github.com/XiaoDuoYa/codex-with-chatgpt/pull/464

完成范围：当前源码与工程证据审查、重点外部规则读取、投入建议记录；没有全仓逐行审计或新运行认证。agent-reach更新查询同样因API限流失败，未改工具版本。


## 所有者补充决策

大屏编辑实时预览与简洁模式都需保留，同一按钮满足两种偏好。撤回隐藏/禁用按钮的候选；实现应让rail模式下的isCollapsed实际生效，保持编辑状态与预览节点。见 `2026-10-10-adaptive-preview-visibility-implementation.md`。
