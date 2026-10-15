# 设置页：评分、更新与反馈整理结果

2026-10-15，main d17bf849，本地2.3.7(132)，未提交/未发布。

## 已实现的范围

关于：版本 → 检查更新 → 更新日志 → 给时光记打个分。评分文案“去 App Store，聊聊你的使用感受。”；更新说明“在 App Store 查看是否有可用更新。”。使用公开已核对的MemoMark ID6788331801；review URL附action=write-review，更新URL为无地区限定的产品页。所有用户都能主动点击，不预筛满意度、不提示五星、不奖励。Apple管理下载/兼容/地区与评论提交；不自行声称已最新版，不对TestFlight与公开版作误导比较。

反馈：邮箱serydoo@gmail.com、小红书搜索MemoMark并直接私信；没有已确认的profileURL，因此保留可选择文字的明确说明，不编造一键直达。诊断导出与条件TestFlight说明后置保留。整个社区（QQ/抖音）及GitHub反馈行/回调已删除。历史communityExpanded defaults不清空或迁移，仅不再读取。四语言相关文案同改，专用无用键移除。

原生最大辅助字号截图发现共享图标按caption增大，固定24pt占位没跟随，挤到版本文字。SettingsRowIcon新增ScaledMetric同步占位：普通large仍24pt，大字号留足空间。原始RED图ipad/09-max-about.png，GREEN图ipad/16-final-max-about.png保留；前者dark后者light，不作跨主题像素一致性结论。

## 验证

- 首个RED构建因缺失AppStore destination类型失败，证明新目标合同尚未实现；RED.xcresult/log保留。范围改变时中间GREEN/Release主动取消exit75，不计为通过。
- 最终focused host74passed/0failed/0skip：destination、settings、expression guide、locale parity、active localization、native product surface。字号显示跟进后复用相同host测试二进制再跑74/0，源码合同读取当前文件；这是同组重跑，不相加为148。二进制URL逻辑未再修改；iOS图标由native screenshot验证。
- 最终Simulator Debug、签名iOS Release构建均exit0；最终strict codesign再次exit0。日志及命令/退出码保留。
- 独立iPad13/iOS26.4：普通字号light/dark、landscape、最大字号，反馈/关于实际截图；最终图标跟进重装后normal/max原图。最新原生iPhone17e/iOS26.5：反馈/关于、light/dark、portrait/landscape/portrait截图；普通字号两个新按钮都位于屏幕内且文案完整。
- native-assertions.json：最终纵向按钮frame包含在screen内，邮箱/小红书存在，社区/GitHub/QQ缺失。横向原图按原始面板方向导出，未编辑图片像素。
- 原13inch M5/iOS26.5 C244…图图场景保留并装入最后候选；owner-review记录原Home和最终Settings。只改变设置页的披露展开状态，不保存/编辑配置；独立QA恢复字号/外观并shutdown。
- 原生AppStore按钮曾点击，模拟器仍留在MemoMark，没有可核对的商店页或error alert，所以商店视觉跳转及失败alert分支NOT VERIFIED；URL精确性已有单元合同。未写/提交评论，不下载/购买/更新应用。真机按用户安排后置。
- iOS启动后一次过早AX只有状态栏导致打开设置目标缺失；保留final-accessible.py失败，fresh AX准备后恢复执行，未修改产品来迎合查询。
- 四语言plist lint和git diff --check通过；完整host/app全量矩阵、VoiceOver/RTL、旧系统与实际商店流转不因focused74通过而被认证。

## 结构复审与创意机制

“时间锚点决定智能表述”的创意方向另见设置结构复审.md与结构提案HTML。已读SettingsPageSurface / GettingStartedSupportContent / SettingsExpressionGuide / InterfacePreferencesContent / PhotoProcessingSupportContent / DataSafetySupportContent。

发现：相近折叠样式混合偏好、教程、能力说明与联系信息，默认大段开始使用淹没表达机制入口；界面摘要“跟随系统 · 跟随系统”缺少维度提示。现有表达讲解代码已有5类锚点、25组风格公式及3阶段，不需新造表达引擎。

提案：MemoMark+ → 一个简短的时间表达特色入口 → 界面偏好 → 使用与数据 → 反馈与评分 → 版本与故事。长说明子页化，保留系统控件、原有内容与返回设置上下文。真实输出继续由既有配置/记忆与表达投影负责；HTML只展示从现有讲解源码提取的公式/占位符，不计算或伪造当前照片结果。本次没有将完整提案布局写入App，避免把结构研究报告成已完成的实装。

## 审查与边界

正确性：精确商店URL、地区中立、失败接受结果提示，无自动请求/不可靠版本判断。可读性/架构：About仅委托动作，Settings拥有openURL与临时alert，不新增服务/状态存储/运行时依赖；共享图标采用系统缩放。安全：未读登录凭据、未发邮件/私信、未上传用户图片；参考截图仅本地保存。性能：没有启动网络、循环版本轮询或后台任务。删除的社区内容及资源有before副本，可逆审查；其他已有文件指纹核对单列。

ConfigurationSession、Memory/Presentation语义、Layout/Renderer、Photos/LivePhoto/Share、持久配置/Commerce职责不改。主页和配置页未因设置改动重排。无stage/commit/push/云上传或发布。

## 材料

桌面独立目录MemoMark-设置评分与更新-2026-10-15：参考截图7张、研究与范围、原生PNG/AX、结果bundle/退出码、源代码增量、结构复审和提案HTML。内置浏览器拒绝file协议原型预览；原型仅完成JS语法检查，未验证浏览器渲染/交互，未尝试绕过策略。真实13寸模拟器独立本地服务已恢复并前台展示。
