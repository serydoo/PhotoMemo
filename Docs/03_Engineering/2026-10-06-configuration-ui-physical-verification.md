# 配置中心真机 UI 验证 — 2026-10-06

设备：实体 iPhone 17 Pro Max，iOS 27.2；本地 Debug 2.3.5 (122)。首次 UI Automation 系统验证已由负责人完成。

## 已通过

- 配置中心可进入，滚动后布局入口可点击；卡片编辑打开、完成返回成功。
- 预览展开、收起、横竖图切换后恢复。
- 更多配置菜单可打开。首页及进展页不显示配置保存栏，回配置页恢复。
- 编辑页截图中保存附件隐藏，四处内容及预览可见；没有背后重复方向的卡片。
- 恢复后的签名 iOS 构建成功；差异格式检查通过。

## 未通过与边界

设置测试中，前三个信息页可以进入及返回，但点击「重看欢迎介绍」后未观察到「欢迎」导航栏；截图与层级仍显示设置页。增加滚动、检查可点击状态后仍复现。导航注册移动试验未解决，已完整撤回，未保留推测性产品修正。等待负责人手动点击确认，不能把它写成已关闭的产品缺陷或已通过。

大字体、VoiceOver 实际朗读、减少动态效果、键盘/输入、横屏与 iPad 尚未完成。这一轮未执行保存、删除、照片处理或 Photos 写入。测试会改变临时页位置和披露展开状态；新增预览测试恢复原方向与预览可见状态。

## 保留改动

只修改 `Tests/MemoMarkUITests/MemoMarkDeviceQAHarnessTests.swift`：布局入口点击前滚动避开底栏；完成按钮接受四語实际标签；新增预览和附件生命周期真机测试；欢迎失败添加截图与层级证据。产品代码无本轮最终改动。未提交或推送。

## 证据

- 配置编辑往返通过：`/tmp/MemoMarkUIPhysicalFinal-20261006.xcresult` 中 `testConfigurationCenterIsReachable`；同包设置测试失败，整体不是通过。
- 预览/底栏生命周期通过：`/tmp/MemoMarkUILifecycleRetry-20261006.xcresult` 中 `testConfigurationPreviewAndAccessoryLifecycle`；同包设置测试失败，整体不是通过。
- 欢迎定位：`/tmp/MemoMarkUISettingsDiagnosis-20261006.xcresult`；附件 `/tmp/MemoMarkUISettingsDiagnosticAttachments-20261006`。
- 导航试验失败：`/tmp/MemoMarkUISettingsFix-20261006.xcresult`；试验已撤回。
- 恢复构建：`/tmp/MemoMarkUIRestoredBuild-20261006.log`。
- 生命周期截图：`/tmp/MemoMarkUILifecycleEvidence-20261006`。

一次自动化启动报告无法确定 PID，正常启动可成功、重试可运行；该轮失败单独记录，不算测试通过。
