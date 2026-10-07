# 2.3.6 之后的大屏右侧导航：接受与交接

日期：2026-10-07。所有者明确接受本轮优化，并授权同步 GitHub。

## 接受范围

- 普通手机竖屏保留底部导航；手机横屏延续已接受的悬浮栏。
- regular-width 大屏横竖屏复用右侧悬浮导航，配置页预览、保存和更多作为同轴上下分组。
- 由同一个导航策略控制顶部、底部和页内操作，移除配置页重复保存/更多/预览开关。
- 控制区物理右侧布局与正文语义阅读方向分离；RTL 实际运行仍待验证。
- 保持 Configuration Session、输入几何、Memory Engine、Renderer、Export 和原图保护契约。

## 验证与证据

- 最终 MemoMarkiOS Debug 模拟器构建通过；iPad Pro13 M5 / iOS26.4 已安装启动。
- 四种宽高组合的独立编译导航策略检查通过。现有 Swift Testing 期望已更新，但未运行完整测试套件。
- iPad 首页横竖屏、配置横屏及进展横竖屏截图已记录。配置 AX 确认保存/更多/预览开关各一份；折叠后开关变为展开。
- 签名真机构建通过；配对 iPhone17ProMax 覆盖安装及启动成功，未清空数据。安装不等于完整真机人工验收。
- 所有者接受本轮视觉优化；不将该接受扩大为完整媒体、无障碍或 Duo 认证。
- 截图、AX、构建日志留在本地 `/tmp/MemoMark-iPadResearchEvidence` 等路径，不提交图片、视频或用户数据。

## 新阶段接续顺序

1. 键盘缩短可用高度时完整预览的比例适配；保持现有输入行框，不用裁切掩盖空间不足。
2. 大屏窄窗口、Dynamic Type、VoiceOver、RTL、编辑草稿/焦点/IME/undo 连续性矩阵。
3. 安装匹配 Duo 的运行时后，验证原生共享栏位、reserved regions 和各形态；避免与自定义栏重复。
4. GlassCard/Live Photo 视觉研究按既有材质与输出保真边界接续；玻璃质感切换单项仍暂放，不实现复杂观察窗口。

详细观察与规格：`2026-10-07-ipad-adaptive-observation.md`。
研究路线：`2026-10-07-post-2.3.6-research-execution-plan.md`。
GlassCard 材料：`2026-10-07-glasscard-live-photo-social-visual-research.md`。
暂存专题：`2026-10-07-glass-texture-switching-research.md`。

## 审查与交付边界

本轮审查覆盖正确性、可读性、架构、隐私与性能：复用现有容器与回调，无新增解码或媒体工作，无持久化变更。剩余运行矩阵作为显式接续项；当前提交是所有者接受的源码检查点，不是新版本商店发布。未升级版本或构建号，未上传 TestFlight/App Store。
