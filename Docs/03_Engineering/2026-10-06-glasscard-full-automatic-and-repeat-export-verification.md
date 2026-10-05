# GlassCard 自动验证结果 — 2026-10-06

完整macOS MemoMarkTests套件：1981项通过、0失败、1项跳过；含参数共2024次成功执行。结果Passed。签名iOS Debug构建成功并覆盖安装到已授权iPhone17ProMax，保留数据；未修改外观与布局，未再次写入Photos。

## 完整回归发现和处理

第一轮完整套件1980项通过、1项失败、1项跳过。失败是HomeConfigurationActionContractTests限制saveCurrent出现次数为2，而既有原生底部操作栏新增了第三个入口。已逐处检查首页/编辑器/底部栏回调均调用同一个显式动作。

测试改为提取所有onSaveCurrentConfiguration/onSaveConfiguration闭包，逐一验证它们严格调用performConfigurationLibraryAction(.saveCurrent)，保留重命名、动作决策与反馈断言。没有删除第三个入口，没有调整产品行为，也没有单纯将总数2改成3。第二轮完整测试通过。

跳过项：StillImageMetadataWriterContractTests/writesJPEGWithSourceMetadataAndRenderedDimensions。已有.disabled说明是Xcode26.5 macOS runner对该ImageIO夹具日志finalize会挂起；本轮未解除禁用，未宣称这一项通过。

两条实际runtime warnings来自FixtureExportReadbackTests：User-interactive线程等待Default优先级线程。最终完整运行仍存在，未把它们写为零警告或已解决；需要独立的线程/编码等待分析。

## 真机六次连续导出

同一进程、三轮，每轮导出两个SDR视频验证副本。使用既有专用InputsSDRFixture，保留原始P3输入；测试没有启用Photos写入标志。每轮独立runIdentifier及manifest，状态completed，无异常退出。

| 轮次 | 24MP still对应配对生成 | 12MP still对应配对生成 | 每轮末当前物理内存 | 累计峰值RSS |
|---|---|---|---|---|
| 1 | 2.357秒 | 2.125秒 | 204.3MiB | 694.7MiB |
| 2 | 2.287秒 | 2.122秒 | 201.2MiB | 716.8MiB |
| 3 | 2.373秒 | 2.201秒 | 200.6MiB | 718.3MiB |

当前物理内存采用task_vm_info.phys_footprint，累计峰值采用getrusage.ru_maxrss，二者不可混用。每轮24MP导出后当前占用405.6–508.9MiB，随12MP导出完成回落。六次结果未显示每轮结束内存持续增长，不等于长期无泄漏认证；本轮没有旧版同设备A/B，不声称整体提速。所有测量后的thermalState均为nominal(0)，不是具体温度。

## 实际编码尺寸

DEBUG清单现在自动读取输出视频轨naturalSize，并记录encodedSizeMatchesCanvas、encodedAspectMatchesCanvas。六次结果均重复确认：

- 4284×5712 requested/still画布 → 2880×3840编码motion。
- 4032×3024 requested/still画布 → 3840×2880编码motion。
- 比例一致，像素尺寸不一致。布局人工验收维持前次用户确认，但不能声称motion原尺寸保真。后续需要明确输出尺寸契约、检查与降级记录，本轮仅验证和记录，不改变已接受渲染。

## 本轮改动

- DEBUG验证页：显式三轮模式、实际编码尺寸、当前物理内存采样，按轮保存结果。
- HomeConfigurationActionContractTests：以动作路由契约取代固定入口数量。
- 没有新的生产媒体/布局修改，没有提交或推送。

## 证据与后续

- 完整通过：`/tmp/GlassCardAutomaticFullFinal-20261006.xcresult`。
- 初次完整失败证据：`/tmp/GlassCardAutomaticFull-20261006.xcresult`。
- 签名构建：`/tmp/GlassCardRepeatDeviceBuild-20261006.log`。
- 真机三轮manifest和状态：`/tmp/GlassCardAutomaticDeviceReadback-20261006`。
- 本目录GlassCard六次连续导出数据.json包含逐次记录。

后续边界：约718MiB峰值仍偏高；视频尺寸降级需要显式策略；原始P3/HDR/gain-map不支持保真；完整套件中的两条优先级警告和一项禁用测试仍开放。前次两张Photos回读及用户人工视觉确认没有被本次无Photos写入测试替代或撤销。
