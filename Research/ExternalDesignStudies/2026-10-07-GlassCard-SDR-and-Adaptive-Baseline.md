# GlassCard SDR 与横屏适配首轮落实回执

> Current checkpoint (2026-10-07): the owner provisionally accepts the small-phone landscape UI and authorizes source synchronization. The current implementation reserves the rail region, supports contextual preview collapse, unifies panel/header alignment and uses icon-only navigation selection. Earlier observations below are chronological evidence. Small-phone two-pane exploration is superseded; native Duo integration and the comprehensive keyboard/accessibility matrix remain open. See [source checkpoint](../../Docs/03_Engineering/2026-10-07-landscape-source-checkpoint.md).

日期：2026-10-07。基线：正式源码 2.3.6（124）/06eebcd2 加当前既有未提交横屏研究改动。

## 执行范围与决策

本切片不修改产品 Swift。A1 采用 memomark-ui-reviewer 先审计状态/空间/可达性，再构建精确研究包；G1 复用已有 nativeBackdropLargeOutputStudy 等测试与实际 xcresult 附件，增加一个本地报告工具，防止把进程历史 RSS 当作单任务峰值。P2 研究工具只读取明确提供的测量 JSON；媒体源和输出留在 /tmp、不上传、不进入 Git。

代码审计没有提供足够证据支持立即修改 rail 间距或重构导航。selection、Session、disclosure 等仍由 root 持有，但 NavigationStack/TabView 分支切换可能影响视图局部状态，必须用真机旋转和键盘/草稿/预览操作判定。不能以“shell 无 @State”证明所有焦点和导航栈连续性。

## 自动验证

- governance validator：通过。
- macOS host focused suite：89 tests /90 parameterized executions，0 failed，0 skipped。覆盖 AdaptivePageLayoutTests、IPhoneResponsiveLayoutContractTests、LivePhotoVideoCompositionServiceTests、PresentationBackdropMaterialTests。
- xcresult：`/tmp/MemoMarkResearch236Focused.xcresult`。附件和 manifest：`/tmp/MemoMarkResearch236Attachments/`。
- 签名 generic iPhoneOS Debug build：exit0，`/tmp/MemoMarkAdaptive236Signed/Build/Products/Debug-iphoneos/MemoMarkiOS.app`；严格签名校验通过，Info.plist 为2.3.6/124。它包含未提交 rail，不是124正式 Release 包的验收替代。
- 设备目标构建 exit70：设备被锁定，等待 development services 超时；不是 Swift 源码编译失败。generic 签名构建随后成功。
- 截图及设备 app 枚举均返回 CoreDevice12040，底层10003 device locked。异步请求所有者解锁；本轮安装/启动/横屏截图未完成。不清空 app 容器。
- 既有 actor-isolation/弃用警告仍存在。测试构建日志中有“command failed with exit code0”中间信息，但最终 xcodebuild exit0、有效 xcresult 为 Passed；不能单凭中间文字宣称测试失败。

## G1 首轮实际测量

测试原始输入为纯红/纯绿切换的4帧、4fps合成 SDR 视频，时长1秒；不是用户素材，也不是高纹理30/60fps真实 Live Photo。完整测试运行期间数据如下：

| 输出像素 | 导出秒数 | 静态材质/视频内区最大通道差 | 进程历史 RSS 峰值 MiB | 历史高水位增加 MiB |
| --- | --- | --- | --- | --- |
| 1920×1080 | 2.46545 | 4 | 187.77 | 0 |
| 4032×3024 | 3.28099 | 3 | 405.63 | 217.86 |

原始附件：`9CF7E559-3022-47B5-B3C9-063B2CB4E65B.json`。报告：`/tmp/MemoMarkResearch236-motion-summary.json`。颜色差满足现有测试阈值≤8，动态材质随背景变化、旋转/前景/metadata identity与仍帧时间标记测试通过；这些是主机自动证据，不是 Photos 真机验收。

`ru_maxrss` 是当前测试进程生命周期高水位。增加为0不表示本次导出不占内存；也不能将217.86MiB称为单次导出峰值。另一个附件的1000次前景图构建为原路径0.05438秒/预构建0.01386秒，仅代表 CI graph preparation，不能推断端到端导出提升倍数。

为减少并行测试对成本测量的影响，额外用 test-without-building、parallel-testing-enabled NO、only nativeBackdropLargeOutputStudy 在新测试进程执行。独立结果下方记录；不重复整套测试。

独立回执：第一次 only-testing 使用未带`()`的标识，exit0但匹配0测试/unknown，已明确排除。按实际 xcresult 的 `nativeBackdropLargeOutputStudy()` 标识重跑：1 passed /0 failed，结果`/tmp/MemoMarkResearch236IsolatedCostCorrected.xcresult`。

| 输出像素 | 独立导出秒数 | 最大通道差 | 进程历史 RSS 峰值 MiB | 历史高水位增加 MiB |
| --- | --- | --- | --- | --- |
| 1920×1080 | 0.36210 | 4 | 347.72 | 80.31 |
| 4032×3024 | 0.50431 | 3 | 714.38 | 332.78 |

独立测量附件`/tmp/MemoMarkResearch236IsolatedAttachments/0E15223B-1D15-4335-95D9-28E83A3627AD.json`；解析报告`/tmp/MemoMarkResearch236-isolated-motion-summary.json`。时间比整组运行明显降低，RSS高水位反而较高；说明单次主机测试过程和并行/框架负载可显著改变读数。两组都保留，不选择性报告较好的数据，不推断内存泄漏，也不将上述RSS当作export专属峰值。

## 本地报告工具

`analyze_glasscard_motion_measurements.py` 读取现有测量附件，输出带来源和限制的 JSON。调用：

```sh
python3 Research/ExternalDesignStudies/analyze_glasscard_motion_measurements.py /tmp/MemoMarkResearch236Attachments/9CF7E559-3022-47B5-B3C9-063B2CB4E65B.json
```

先写失败的测试，再补报告实现；4个单元测试通过，覆盖源时长、RSS口径、零高水位增加、缺字段及无效数值。实际 xcresult JSON 已成功处理。工具不将任何门槛自动标为 PASS，也不写入原始附件。

## 开放门槛

### 手机解锁后的新回执

所有者回复已解锁后，覆盖安装当前签名Debug研究包成功，bundleID
`com.serydoo.PhotoMemo.iOS`；terminate-existing后启动成功。
设备app枚举读回2.3.6/124，进程PID2142。未清空容器。
当前竖屏首页截图`/tmp/MemoMarkAdaptive236-unlocked.png`，1320×2868，已实际查看；
现有对象/预设可见，底部Home/Configuration/Progress显示。
这是竖屏启动画面证据，不证明横屏、焦点、草稿或Photos媒体回读。
已请求所有者打开配置并横屏，下一画面采集及状态连续性验收等待该操作。
此前锁定阻断已解除，不能继续把安装/启动标为未完成。

随后截图`/tmp/MemoMarkAdaptive236-current.png`仍为竖屏配置中心，已查看：
玻璃卡片当前选择、收起预览、展开的卡片布局内容、保存/菜单/底部导航可见，
页面显示有未保存的修改。未执行保存、重置或自动改写草稿。
此截图证明配置页可打开，不证明横屏导航或旋转前后草稿等价。

- A1：物理手机解锁后的覆盖安装/启动；横竖切换、三入口、尾部控件、草稿/焦点/预览连续性；四语言、VoiceOver、Dynamic Type、Reduce Motion人工验收。
- G1：30/60fps纹理/明暗/运动输入、真实授权 Live Photo、orientation、音频/时长/identity/EXIF/Photos回读；真机任务峰值与逐帧 MainActor耗时。
- HDR/P3：当前明确拒绝/恢复边界不变，不从此实验扩张支持范围。
- A2/iPad/macOS/Duo产品集成等待A1退出；Clear/Soft材质候选等待G1测量与产品评审。
