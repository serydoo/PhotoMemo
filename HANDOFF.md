# PhotoMemo Handoff

## 2026-06-29 MVP Queue Naming Refinement

- 用户确认：
  - 每一个队列代表一次 Share 任务。
  - 队列名称用开始时间 + 照片数量更直观。
  - 期望示例：
    - `18:42（3张） · 1/3 · 约 2 分钟`
    - `18:42（3张） · 1 张需要处理`
    - `18:42（3张） · 已保存 3 张`
- 已实现：
  - 新增 `PhotoMemoQueueDisplayFormatter`，统一生成用户可读队列名称：
    - 当天：`18:42（3张）`
    - 昨天：`昨天 18:42（3张）`
    - 今年更早：`6月29日 18:42（3张）`
    - 跨年：`2025年12月31日 18:42（3张）`
  - `PhotoMemoAppRuntime.resolvedRequestTitle(...)` 不再生成
    `外部图片处理 yyyy.MM.dd HH:mm · X张`。
  - `BatchQueueExecution` 的默认后台任务标题不再生成
    `PhotoMemo 后台任务 ...`。
  - 新建 `BatchJob.createdAt` 改为跟随最早的 intake payload request time，
    更贴近真实 Share 开始时间。
  - `PhotoMemoBackgroundStatusService` 在 snapshot / queue line 展示层统一
    使用 compact queue title，因此旧持久化任务也不会继续露出旧标题。
  - 队列行文案收口为结果优先：
    - 完成：`已保存 X 张`
    - 失败：`X 张需要处理`
    - 部分完成：`已保存 X 张 · Y 张需要处理`
- 已验证：
  - `git diff --check` 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7
    `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需人工复测：
  - 分享单张照片，确认通知/锁屏/状态 sheet 使用 compact 队列名。
  - 连续分享 2-3 批，确认每行代表一次 Share 任务。
  - 连续分享 4 批以上，确认聚合模式仍然克制。

## 2026-06-29 MVP Share Handoff URL Scheme Fix

- 用户反馈：
  - RAW 和 JPEG 从 Apple Photos 分享到 MVP 后，确认页能出现，但下拉通知栏没有进度，也没有看到输出结果。
  - 希望确认后有一个更接近系统感的“收起到通知/灵动岛方向”的过渡动画。
- 根因定位：
  - Share Extension 已能展示确认页并执行接单流程。
  - MVP 主 App target 虽然嵌入了 Share Extension 和 Widget Extension，也有 `NSSupportsLiveActivities`，但构建产物 `Info.plist` 没有真实生成 `CFBundleURLTypes`。
  - Share Extension 通过 `photomemo://share` 唤起主 App；MVP App 未注册 URL scheme 时，`extensionContext.open(...)` 会失败，主 App 不会被唤起 drain `ExternalPhotoIntakeStore`，因此队列、通知进度、输出都会缺席。
- 已修复：
  - 新增 `Source/PhotoMemo/PhotoMemoiOSMVP-Info.plist`，为 MVP App 明确注册：
    - `CFBundleURLTypes -> photomemo`
    - `NSSupportsLiveActivities`
    - 相册读写权限文案
  - `PhotoMemoiOSMVP` Debug / Release 改为使用这份专用 Info.plist。
  - Share Extension 的完成流程不再静默忽略唤起失败：
    - `requestMainAppRefresh()` 现在返回 Bool。
    - 如果系统没有打开主 App，确认页会停留在“照片已经接收 / 需要重新交给 PhotoMemo”的可见状态。
  - 持久化成功后增加轻量 UIKit 过渡：
    - 确认界面向顶部缩小并淡出。
    - 保留轻触感反馈。
    - 该动画只在接单成功后触发，不掩盖失败。
- 已验证：
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - 构建产物 `Info.plist` 已包含 `CFBundleURLTypes -> photomemo`。
  - 构建产物仍包含 `NSSupportsLiveActivities = true`。
  - 构建产物仍嵌入：
    - `PhotoMemoShareExtension.appex`
    - `PhotoMemoWidgetExtension.appex`
  - `PhotoMemoiOSMVP` 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `PhotoMemoiOSMVP` iOS Simulator Debug build 通过。
  - `PhotoMemo` macOS Debug build 通过。
  - `git diff --check` 通过。
- 未验证：
  - 设备当前锁定，无法通过 devicectl 远程启动 App。
  - 仍需要用户从 Apple Photos 手动分享 1 张 JPEG 和 1 张 RAW，确认：
    - 完成动画出现。
    - 主 App 被打开或后台接单。
    - 通知/锁屏 Live Activity 出现进度。
    - 成品写入 Apple Photos / `photomemo` 相册。

## 2026-06-29 Share Confirmation RAW Preview Refinement

- 用户反馈：
  - 竖图完整显示正常。
  - 2 张横图 / 竖图混合正常。
  - RAW 场景下确认页缩略图不能正常显示。
  - 预览图片不需要边框，只要能显示缩略图，选中时轻微放大即可。
- 根因定位：
  - Share 确认页此前只用 `loadItem(UTType.image)` 后尝试 `UIImage(data:)`。
  - RAW / ProRAW 分享时，系统可能不给可直接 `UIImage` 解码的数据；更稳定的方式是先请求系统预览图，再对文件表示用 ImageIO 生成小缩略图。
- 已修复：
  - Share 确认页预览加载顺序改为：
    1. `NSItemProvider.loadPreviewImage`
    2. `loadFileRepresentation` + `CGImageSourceCreateThumbnailAtIndex`
    3. 原有 `UIImage` / `Data` fallback
  - 预览缩略图限制为 `640px` 级别，避免 RAW 在 Share Extension 内造成内存压力。
  - 预览 provider 判断扩展为 PhotoMemo 当前支持的图片类型集合，覆盖 RAW / DNG 类型。
  - 预览卡片去掉容器边框和边框选中态。
  - 选中态只保留：
    - `1.06x` 轻微放大
    - 前景层级提高
    - 非选中项轻微降透明
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 仍需人工验证：
  - 从 Apple Photos 分享 RAW / ProRAW 到 MVP，确认缩略图能出现。
  - 确认无边框预览在横图、竖图、多图下视觉足够克制。

## 2026-06-29 Share Confirmation Single Photo Simplification

- 用户反馈：
  - 单张分享不需要缩略图。
  - 用户刚看到之前图片的处理结果，说明后台处理耗时可能长短不一，需要重新梳理通知栏和主 App 进度表达。
- 已修复：
  - Share 确认页现在只有 `2 张及以上` 时显示多图缩略图卡片。
  - 单张分享隐藏整个预览 section，只保留：
    - 照片数量
    - 默认风格
    - 结果去向
    - 当前处理说明
    - 开始生成按钮
  - 目的：
    - 避免单张确认页像“结果预览”。
    - 降低 RAW 单张场景下的预览解码压力。
    - 保持 Apple Photos Share 的轻量确认感。
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
- 后续交互方向：
  - 通知栏/Live Activity 应区分单任务、2-3 个任务、4+ 聚合、完成、失败。
  - 主 App 后台状态页应从“后台状态”继续收敛为“处理进度/最近结果”，单任务显示完整 Pipeline，多任务显示可展开队列。

## 2026-06-29 Single Task Pipeline Progress

- 用户确认继续推进后台进度交互。
- 本轮目标：
  - 单张照片不再用“批处理队列感”的表达。
  - 单张任务展示完整 Pipeline。
  - 2-3 个任务继续每队列一行。
  - 4 个及以上任务聚合成摘要。
  - 完成/失败通知文案更短，更接近系统通知。
- 已实现：
  - `PhotoMemoBackgroundJobSnapshot` 新增展示层字段：
    - `displayMode`
    - `pipelineSteps`
    - `activePipelineStepIndex`
  - 单张 Pipeline 固定为：
    1. 接收照片
    2. 读取信息
    3. 生成卡片
    4. 写入图库
    5. 完成
  - RAW 相关阶段继续通过状态文案表达：
    - `正在准备 RAW 照片`
    - `已生成 RAW 显示版本`
  - Live Activity / Lock Screen：
    - 单张显示当前状态 + 细进度 + Pipeline dots。
    - 多张继续显示 queue lines。
    - Dynamic Island expanded bottom 跟随单张/多张模式切换。
  - 主 App 后台 sheet：
    - 标题从 `后台状态` 改为 `处理进度`。
    - 单张显示 `处理流程` Pipeline。
    - 多张仍显示队列摘要和最近记录。
  - 本地最终通知文案收短：
    - 成功：`PhotoMemo 已保存 X 张照片`
    - 失败：`X 张照片需要处理`
    - 部分完成：`已保存 X 张，Y 张需要处理`
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `PhotoMemo` macOS Debug build 通过。
- 人工复测建议：
  - 分享 1 张 JPEG，观察 Lock Screen / Notification Center 是否显示 Pipeline。
  - 分享 1 张 RAW，确认 RAW 阶段文案能解释等待。
  - 分享 2-3 张，确认每队列一行。
  - 连续分享 4 组以上，确认聚合摘要出现。
  - 制造失败项，确认通知和主 App sheet 都显示“需要处理”。

## 2026-06-29 Share Confirmation Preview Card Stack

- 用户反馈：
  - Share 到 MVP 后的确认窗口体验不错，但下方待处理图片预览里，竖图显示不完整。
  - 希望保持当前窗口大小，适当缩小示意图或拉高一点，确保图片完整。
  - 多张图片时希望接近“扑克牌”式左右滑动，点击某张时轻微放大凸显。
- 根因：
  - Share Extension 确认页此前只有一个 `UIImageView`。
  - 固定高度 `180pt`，`contentMode = .scaleAspectFill`，竖图会被裁切。
  - 多张分享只预览第一张，无法感知待处理队列内容。
- 已修复：
  - 将单图 `UIImageView` 改为横向 `UIScrollView + UIStackView` 预览卡片组。
  - 图片预览卡片统一使用 `.scaleAspectFit`，竖图完整显示，不再裁切。
  - 预览区域高度收为 `168pt`，卡片高度 `158pt`，保持确认窗口整体克制。
  - 多张时最多加载前 10 张轻量预览，避免 Share Extension 内存压力。
  - 卡片采用轻微重叠的横向排列，形成低调的“扑克牌”感。
  - 点击某张卡片会：
    - 轻微放大到 `1.06x`
    - 加深边框
    - 自动滑动到可见区域
  - 文案改为：`左右滑动查看待处理照片，所有照片会使用相同风格处理。`
- 未改：
  - Share Extension 接单逻辑
  - 后台队列
  - Renderer
  - 输出格式
  - RAW 处理策略
- 验证：
  - `PhotoMemoShareExtension` Debug iOS Simulator build 通过。
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 已覆盖安装到 iPhone7 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 人工复测建议：
  - 分享 1 张竖图，确认完整显示。
  - 分享 3-5 张横竖混合照片，左右滑动检查每张预览。
  - 点击不同卡片，确认轻微放大和滚动定位自然。

## 2026-06-29 MVP Live Activity Packaging Fix

- 用户反馈：从 Apple Photos 分享后，下拉通知栏看不到队列/进度，感觉没有进入队列。
- 根因定位：
  - `PhotoMemoiOSMVP.app` 的产物里只有 `PhotoMemoShareExtension.appex`。
  - MVP target 没有嵌入 `PhotoMemoWidgetExtension.appex`。
  - MVP target 生成的 Info.plist 里也没有 `NSSupportsLiveActivities = YES`。
  - 因此 ActivityKit 即使收到后台状态 payload，也没有可展示的 Live Activity widget 承载；驱动层此前 catch 后静默禁用请求，用户侧表现为通知栏没有持续进度。
- 已修复：
  - `PhotoMemoiOSMVP` target 增加 `PhotoMemoWidgetExtension` target dependency。
  - `PhotoMemoiOSMVP` target 的 `Embed App Extensions` 同时嵌入：
    - `PhotoMemoShareExtension.appex`
    - `PhotoMemoWidgetExtension.appex`
  - `PhotoMemoiOSMVP` Debug / Release build settings 增加：
    - `INFOPLIST_KEY_NSSupportsLiveActivities = YES`
- 已验证：
  - `PhotoMemoiOSMVP` connected-device Debug build 通过。
  - 构建产物 `PhotoMemoiOSMVP.app/PlugIns` 已包含 `PhotoMemoWidgetExtension.appex`。
  - 构建产物 Info.plist 已包含 `NSSupportsLiveActivities = true`。
  - 已覆盖安装到设备 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 复测建议：
  - 优先用 RAW 或多张照片测试，因为单张普通图片处理太快，Live Activity 可能还没形成持续可见状态就结束。
  - 如果仍看不到，下一步检查系统设置里的 PhotoMemo 通知权限与 Live Activities 开关。

## 2026-06-29 MVP RAW / ProRAW Priority Support

- 本轮按“RAW 优先处理，但不冒险”的原则补齐 MVP 后台链路：
  - RAW / DNG 不再在 Share Extension 前置校验中被跳过。
  - 原始 RAW 文件仍不被修改，只作为元数据与显示版本来源。
  - PhotoMemo 会生成一张普通输出图片：系统生成的 RAW 显示版本 + 当前底部边框。
  - 原 RAW 的 `sourceProperties` / EXIF 仍作为卡片内容和输出元数据来源。
- 输入策略更新：
  - 支持：`JPEG/JPG`、`HEIC/HEIF`、`PNG`、`TIFF`、`RAW/DNG`
  - 仍不支持：Live Photo、GIF、WebP、视频、超长比例图片。
  - RAW 仍遵守当前 iPhone 标准照片包络：
    - 单边最大 `8064 px`
    - 总像素最大 `8064 x 6048`
    - 最大长宽比 `3:1`
- RAW 导入策略：
  - 普通照片继续走原有 `Data -> PlatformImage` 稳定路径。
  - RAW 照片先尝试平台文件显示版本。
  - 失败后用 ImageIO 生成最大边长受控的显示版本。
  - 最后才回退 CoreImage 渲染，避免一开始就走重型路径。
- 进度感知更新：
  - RAW 任务开始显示 `正在准备 RAW 照片`。
  - RAW 导入完成显示 `已生成 RAW 显示版本`。
  - 单张队列摘要会显示 `准备 RAW` / `RAW 显示版本`，避免用户误以为卡住。
  - RAW 估时按更保守的 `75 秒/张` 计算；普通照片仍按 `14 秒/张`。
  - 本地通知新增 `raw` 阶段文案：`正在准备 RAW 照片`。
- 验证：
  - `PhotoProcessingInputPolicyTests` 通过。
  - `PhotoImportServiceTests` 通过。
  - `BatchFixtureCoverageTests` 通过。
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - `PhotoMemoShareExtension` Debug iOS Simulator build 通过。
  - `git diff --check` 通过。
- 已覆盖安装到设备：
  - `iPhone7`
  - device id `863C2747-6742-5E93-B715-6F89DBF90B31`
  - bundle id `com.serydoo.PhotoMemo.iOS`
- 未完成 / 需要人工验证：
  - 从 Apple Photos 分享真实 ProRAW / DNG 到 PhotoMemo。
  - 检查输出图片视觉、EXIF token、相册写入是否符合预期。
  - 在 iPhone7 上观察 RAW 大图处理时是否发生内存压力；如有，下一步应把 RAW 显示版本上限进一步下调到设备自适应。

## 2026-06-29 MVP Queue Summary Live Activity

- 本轮把“近期多个处理队列，每行仅展示一个队列进度”的 MVP 状态模型落地到真机版本。
- 新增后台状态摘要规则：
  - `PhotoMemoBackgroundJobSnapshot` 现在包含 `queueLines` 和 `overflowQueueCount`。
  - 最多展示 3 行，每行代表一个外部队列。
  - 排序优先级：当前处理 -> 失败/需处理 -> 等待/处理中 -> 最近完成。
  - 超过 3 个队列时显示 `另有 X 个队列`，避免通知区域变成任务列表。
- 队列行文案规则：
  - 单张：`正在处理 · 写入图库 · 约 14 秒`
  - 多张处理中：`正在处理 · 10/20 · 约 3 分钟`
  - 等待：`等待中 · 3 张`
  - 完成：`已完成 · 20 张已保存`
  - 失败：`需要处理 · 18/20 · 2 张需要查看`
- Live Activity 已接入：
  - `PhotoMemoBackgroundActivityAttributes.ContentState` 新增 `queueLines` / `overflowQueueCount`。
  - 锁屏主视图和 Dynamic Island expanded bottom 复用同一套三行摘要。
  - Dynamic Island compact 仍保持克制，只显示图标和进度百分比。
- App 内后台状态页已接入：
  - 右上角后台状态 sheet 展示同一组三行摘要。
- 当前剩余时间为保守估算：
  - 按剩余图片数粗略计算，先用于 MVP 体感验证。
  - 后续可改为最近 3 张平均耗时。
- 验证：
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - 已重新安装到设备 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 下一步人工测试建议：
  - 分享 1 张，观察单张阶段/剩余时间。
  - 连续分享多组照片，观察最多 3 行队列摘要。
  - 分享 10+ 张，观察 `10/20` 风格展示。
  - 制造失败项，确认失败队列优先显示且不被完成队列挤掉。

## 2026-06-29 MVP Share Output Runtime Fix

- 用户确认 Apple Photos Share Sheet 已能看到并进入 `PhotoMemo MVP`，确认动作也能完成，但之后没有生成/保存输出。
- 根因定位：
  - `PhotoMemoShareExtension` 已能把分享图片持久化为 `ExternalPhotoIntakeRequest`。
  - 正式 iOS App 入口会创建 `PhotoMemoAppRuntime`，并通过 `PhotoMemoRootSceneView` 在 `task/onAppear/onOpenURL/scenePhase` 中调用 `refreshExternalIntakeState()` / `flushExternalRequests()`。
  - `PhotoMemoiOSMVPApp` 之前直接打开 `PhotoMemoiOSTemporaryEntryView`，绕过了 `PhotoMemoiOSHomeView` 和 `PhotoMemoAppRuntime`，所以 Share Extension 确认后写入了请求，但 MVP App 没有 drain 请求，也没有启动 `BatchQueueStore` 输出链路。
- 已修复：
  - `PhotoMemoiOSMVPApp` 现在创建 `PhotoMemoAppRuntime` 并进入 `PhotoMemoiOSHomeView`。
  - `PhotoMemoiOSHomeView` 和 `PhotoMemoRootSceneView` 增加临时入口参数传递。
  - MVP 仍默认显示 `mvpTest` 页面，但外层保留正式 iOS runtime、deeplink flush、后台状态入口和 batch processing。
- 验证：
  - `PhotoMemoiOSMVP` 真机 Debug build 通过。
  - 已重新安装并启动到设备 `863C2747-6742-5E93-B715-6F89DBF90B31`。
  - `git diff --check` 通过。
- 下一步人工验证：
  - 从 Apple Photos 分享一张普通静态照片到 `PhotoMemo Share`。
  - 确认后允许相册权限。
  - 观察是否保存到系统图库 / `photomemo` 相册。
  - 如果失败，打开右上角后台状态按钮查看任务阶段与错误信息。

Compact AI summary for this round:

- `Docs/AI_HANDOFF_2026-06-21.md`
- `Docs/AI_HANDOFF_2026-06-22.md`

## 2026-06-29 Background Pipeline Input Policy

- 本轮围绕“快一点，但不冒险”的后台处理原则，补齐处理输入边界，并接入 Share Extension 前置校验；不改现有 UI、Renderer、Export 输出形式。
- 新增 `PhotoProcessingInputPolicy`：
  - 支持格式：`JPEG/JPG`、`HEIC/HEIF`、`PNG`、`TIFF`
  - 暂不支持：Live Photo、RAW/DNG、GIF、WebP、视频
  - 标准照片尺寸上限按当前 iPhone 48MP 静态照片包络确定：
    - 单边最大 `8064 px`
    - 总像素最大 `8064 x 6048`
    - 最大长宽比 `3:1`
  - 超大图、超高像素图、全景图、长截图、极端细长图片会得到明确拒绝原因和 Apple-native 风格反馈文案。
- `PhotoImportService.supportedTypes()` 已改为引用 `PhotoProcessingInputPolicy.supportedImageTypes`，避免支持格式出现第二套定义。
- 已继续接入 Share Extension intake 前置校验：
  - 复制到共享容器后读取文件类型与像素尺寸。
  - 不支持的图片立即清理临时副本。
  - 不支持项计入 `skippedCount`，不会进入 Batch Queue。
  - `skippedCount` 文案从“重复跳过”改为通用“已跳过”，因为跳过原因可能是重复，也可能是不支持。
- `3:1` 阈值按长边 / 短边计算，不区分横图和竖图：
  - `6048 x 8064` 竖图支持。
  - `3024 x 5376` 这类 9:16 竖图支持。
  - 超过 `3:1` 的长截图、全景图、特别细长图片暂不支持。
- 推荐后台处理策略继续保持：
  - Share Extension 只复制与持久化，不渲染。
  - Import / EXIF 可有限并发。
  - Render / Photo Library Save 保持串行。
  - 每张完成后立即清理临时文件。
- 验证通过：
  - `PhotoProcessingInputPolicyTests`
  - `PhotoImportServiceTests`
  - `PhotoFileNameResolverTests`
  - `PhotoMemoAlbumSelectionTests`
  - `PhotoMemoShareExtension` Debug iOS Simulator build
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `git diff --check`
- 已确认：
  - `PhotoMemo` scheme 没有配置 test action。
  - 定向测试应使用 `PhotoMemoTests` scheme。
- 后续接入建议：
  - 真机验证 Share Extension 部分成功、部分跳过反馈。
  - 进一步区分跳过原因的内部统计，但不要在 Share UI 里制造诊断噪音。

## 2026-06-28 MVP Album And Logo Output Completion

- 本轮补齐 MVP 输出设置的两个真实缺口：
  - 生成图片继续作为新图片进入 Apple Photos 系统图库。
  - 用户未选择相册时，自动创建/复用小写 `photomemo` 相册。
- `PhotoLibraryExportService` 新增 `ensureAlbum(named:)`：
  - 可按名称复用已有相册。
  - 不存在时创建新相册。
  - 默认相册名统一为 `photomemo`。
- iOS MVP 输出区现在支持：
  - 自动存入 `photomemo`
  - 仅保存到系统图库
  - 从现有相册下拉选择
  - 输入名称并在保存配置时新建/复用相册
- 保存配置时会把真实相册 localIdentifier 和 title 写入共享设置，Share 后的 snapshot 继续读取同一路径。
- 自选 Logo 已从占位补为真实上传：
  - 使用原生 `PhotosPicker`
  - 用户选择图片后异步优化
  - 优化文件写入共享容器 `LogoAssets`
  - 保存为 `.customUpload` Badge，并通过 `imagePath` 供渲染读取
- Logo 上传/优化规格：
  - 推荐上传 `2048 x 2048` 透明 PNG
  - 最低建议 `1024 x 1024`
  - 后台统一优化为 `2048 x 2048` 方形透明 PNG
  - 内容保留 `12%` 安全留白
- 推荐依据：
  - 当前 4032px 横向输出中 Logo 约显示 `209px`
  - 12000px 竖向未来输出中 Logo 约显示 `817px`
  - 2048px master 对大图输出和打印检查有足够余量
- 新增测试：
  - `PhotoMemoAlbumSelectionTests`
  - `LogoAssetOptimizationServiceTests`
- 验证通过：
  - 新增两组测试
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoShareExtension` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `git diff --check`
- 未手动验证：
  - 真机 Apple Photos 相册创建
  - 真机 Logo 上传后的最终渲染效果
  - Share 后使用新建相册 + 自选 Logo 的完整实机链路

## 2026-06-28 MVP Share Pipeline Gap Closure

- 本轮继续收敛 MVP 到：
  - Apple Photos -> Share -> PhotoMemo -> Processing -> Notification -> Apple Photos
  - 原图不被修改
  - 输出为原图 + 底部边框的新图片
  - 元数据尽量继承原图，只有输出分辨率跟随新画布更新
- 已补齐输出命名规则：
  - `IMG_1234` 首次输出为 `IMG_1234(1).jpg`
  - 再次输出为 `IMG_1234(2).jpg`
  - 继续处理 `IMG_1234(1)` 不会生成 `IMG_1234(1)(1)`
- 已补齐 iOS MVP `设为生效` 的真实落盘：
  - 当前四个自定义区的单行 Content Builder 内容会写入共享 `Template`
  - Share Extension 读取 `SharedBatchConfigurationSnapshotService` 时可以拿到这份 active configuration
  - 编辑器中 token 仍展示示例值，但保存时写入真实渲染 token，例如 `{{model}}` / `{{capture_date_short}}` / `{{camera_summary}}`
- UI 反馈补齐：
  - 编辑区域或时间锚点后状态显示 `有未生效修改`
  - 点击 `设为生效` 后显示 `已生效`
- Profile 控制形态已调整：
  - 右侧只保留 `保存` 和小号重置图标按钮
  - 从 Preset 下拉切换到不同配置后，会弹出原生确认对话
  - 用户可选择 `保存为生效配置` 或 `仅切换查看`
- 时间锚点已纳入 MVP 保存范围：
  - 保存时会创建或更新 `.birthday` Anchor
  - 该 Anchor 会写入共享 `selectedAnchorID`
  - Share 后真实渲染中的 `{{anchor_age_text}}` 会走保存后的 Anchor，而不是 MVP 页面里的 mock 预览日期
- Logo / 输出目标也已跟随 `保存` 写入共享设置：
  - Apple 标识保存为 Apple badge
  - 输出目标写入共享相册选择状态
- 模块插入交互已从自绘遮罩改为原生 sheet：
  - 使用 medium / large detent
  - 列表行点选后直接加入当前区域
  - 去掉“先选模块再点插入”的工具感
- MVP 可见语言继续收口：
  - 移除 mock / UI-only / 测试说明类文案
  - `Token` 改为 `插入信息`
  - 输出说明改为面向用户的保存行为说明
- iOS 模块 token 映射收口：
  - 新增 `IOSInsertableModule.rendererToken`
  - MVP 页面不再维护第二套 renderer token switch
- 当前仍未完成：
  - 真机 Apple Photos share-sheet 手动回归
  - 多张照片分享后的真实输出视觉检查
  - 自选 Logo 上传后的真机视觉检查
  - 新建/指定相册后的真机 Apple Photos 写入检查
- 验证通过：
  - `PhotoMemoTests/PhotoFileNameResolverTests`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOSMVP` Profile 保存/重置交互修订后再次构建通过
  - `PhotoMemoiOSMVP` Time Anchor 持久化与原生模块 sheet 修订后再次构建通过
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoiOS` Time Anchor 持久化与原生模块 sheet 修订后再次构建通过
  - `PhotoMemoShareExtension` Debug iOS Simulator build
  - `PhotoMemoShareExtension` Time Anchor 持久化修订后再次构建通过
  - `PhotoMemo` Debug macOS build
  - `git diff --check`

## 2026-06-28 Apple First-Party UI Polish

- 本轮根据 Apple Photos / Journal / Health 的方向，只做 Configuration Center 表层 UI polish，不改功能与架构。
- 视觉方向：
  - Preview 继续作为第一视觉锚点。
  - 控制区降低视觉重量，避免工具软件感。
  - 使用 system colors / native typography / SF Symbols。
  - 扩大留白，统一圆角，减少边框、阴影和强调色。
- 已同步修改：
  - `ConfigurationUI` 统一系统背景、圆角、间距、hairline、shadow token。
  - macOS `InteractiveMemoryCard` 放大呼吸感，弱化顶部配置条与预览外框。
  - iOS `ConfigurationCenteriOSView` 放松 sidebar / detail spacing，降低按钮和面板的装饰性。
  - iOS MVP 测试页将 Preview 前置，并把 Profile / Preview / Output 等命名收敛到更接近产品语义的中文。
- 明确未改：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoShareExtension` Debug iOS Simulator build

## 2026-06-28 MVP Single-Line Content Builder Refinement

- 本轮根据最新 MVP 边界修正：
  - MVP 页面继续保留 `记忆档案 / 时间锚点 / 智能模块 / 写入记忆` 这条线。
  - 四个自定义区域从两段式输入改为单行 Content Builder。
  - Content Builder 内部统一为 item 模型：
    - Text
    - Token
    - Separator
    - Line Break（模型预留，当前单行显示不暴露为换行操作）
  - Token 与分隔符作为同一行 chip 追加，预览仍只展示底部边框。
  - `应用` 按钮语义收敛为 `设为生效`，用于后续 Share 自动处理读取当前生效配置。
- 本轮仍未接入：
  - Share 后前后台自动处理配置读取改造
  - 真实 EXIF token 替换当前 MVP mock 值
  - Preset 持久化重建
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`

## 2026-06-28 Compact Border-Only Preview Correction

- 本轮根据真机检查反馈，进一步修正 preview 展示区域：
  - preview 现在只展示 Compact White Information Bar 底部边框。
  - 上方 photo placeholder / photo area 已从预览中移除。
  - 边框本身仍保持 `width * barHeightToWidth` 的原始比例，不拉伸、不重排。
- 已同步修改：
  - macOS `InteractiveMemoryCard`
  - iOS `ConfigurationCenteriOSView`
  - iOS MVP `PhotoMemoiOSMVPTestView`
- 验证通过：
  - `git diff --check`
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug connected-device build，destination `iPhone7`
- 已覆盖安装并启动到连接设备：
  - device: `iPhone7`
  - bundle id: `com.serydoo.PhotoMemo.iOS.MVP`
- 后续编译与文件整理补充：
  - 清理了 iOS compact preview 中已经不再使用的旧 PM-004/footer/slot helper。
  - 保留当前 compact 信息栏路径，减少后续维护噪音。
  - `PhotoMemo` Debug macOS build 通过。
  - `PhotoMemoiOS` Debug iOS Simulator build 通过。
  - `PhotoMemoiOSMVP` Debug iOS Simulator build 通过。
  - `PhotoMemoShareExtension` Debug iOS Simulator build 通过。
  - `RendererConstantsTests` 通过。
  - `CaptureTimeResolverTests` 通过。
  - 全量 `PhotoMemoTests` 首次运行时仅 `ClassicWhiteSnapshotTests.landscapeStandardSnapshotStaysStable()` 出现 93 像素快照差异；该单测随后单独重跑通过。
  - 第二次全量测试启动即被系统杀掉（exit 137），更像当前机器负载/内存压力，不作为代码断言失败处理。

## 2026-06-28 Compact White Information Bar Correction

- 本轮根据用户提供的原图/效果图成对样本，修正底部边框方向：
  - 当前参考图目标不是 PM-004 的 A/B/C/D 大 Memory Document 布局。
  - 当前参考图目标是 Compact White Information Bar：照片区 + 紧凑双列白色信息栏。
- `RendererConstants` 新增 `CompactInformationBar` 参数：
  - 竖图底栏高度：`W * 0.1660`
  - 横图底栏高度：`W * 0.1266`
  - 左列 / 右列 / Logo / Divider 坐标
  - Primary / Secondary 字号比例
  - Capture Summary 四项单行输出
- macOS `InteractiveMemoryCard` 已改为按比例缩小的 Compact 输出预览：
  - 左列：Slot A + Slot B
  - 中心：Logo 标识 + Divider
  - 右列：Slot C + Slot D
  - 四行内容仍保持各自 CardRegion 可点击选择。
- 本轮继续补齐精准映射：
  - Slot A / 记录 -> left primary -> `CardTextArea.leftTop`
  - Slot B / 时间线 -> left secondary -> `CardTextArea.leftBottom`
  - Slot C / 拍摄参数 -> right primary -> `CardTextArea.rightTop`
  - Slot D / 记忆 -> right secondary -> `CardTextArea.rightBottom`
- Slot C 已从宽泛的“上下文”收窄为“拍摄参数”，右上角始终服务于四项 Capture Summary。
- iOS MVP Preview 已同步为同一套 Compact 输出预览。
- iOS Configuration Center Preview 已同步为同一套 Compact 输出预览。
- `ImmersWhiteRenderer` 的颜色 token 已指向 Compact 信息栏常量；现有真实输出几何比例本来已接近样本，因此未重写真实 export layout。
- 验证通过：
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build，destination `iPhone 17 Pro, iOS 26.4`
  - `PhotoMemoTests/RendererConstantsTests`
  - `git diff --check`
- 未手动验证：
  - macOS 运行时视觉截图
  - iOS Simulator 视觉截图
  - reference image golden export comparison

## 2026-06-28 PM-004 Border Preview Foundation

- 本轮根据 Atlas 中整理出的边框规范，先落地 PM-004 的 preview 基础，不直接迁移真实 export renderer。
- 新增：
  - `Source/PhotoMemo/PhotoMemo/Renderers/RendererConstants.swift`
  - `Tests/PhotoMemoTests/RendererTests/RendererConstantsTests.swift`
- `RendererConstants` 目前冻结：
  - 8pt Grid token
  - PM-004 Typography token
  - Memory Document / Information Bar 颜色
  - Photo Area / Information Bar 几何比例
  - Information Bar 内 0-100% Anchor Coordinates
  - Slot A Recorder: X=6%, Y=18%
  - Slot B Timeline: X=42%, Y=18%
  - Slot C Capture Summary: X=74%, Y=18%
  - Slot D Memory Block: X=6%, Y=60%，最大权重
  - Badge: 右下预留装饰区域
  - Capture Summary 只允许四项：焦距 / 光圈 / ISO / 快门
- macOS `InteractiveMemoryCard` 已从旧左右两列结构改为：
  - Photo Area
  - Information Bar
  - A/B/C 上排
  - D 左下最大 Memory Block
  - Badge 右下
  - Icon region 仍保留可点击路由
- iOS MVP Preview 已从五列等分白底栏改为同一套 PM-004 坐标系统。
- 本轮仍未迁移真实输出 renderer：
  - `ImmersWhiteRenderer`
  - `ClassicWhiteCardRenderer`
  - `ClassicWhiteRenderer`
  - `RecordCardExportService`
- 验证通过：
  - `PhotoMemoTests/RendererConstantsTests`
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `git diff --check`
- 未手动验证：
  - iOS 真机/模拟器视觉截图
  - macOS 运行时 hover/click 路由
  - 真实 export 输出像素级一致性

## 2026-06-26 iOS MVP Test Module Scaffold

- 本轮新增 iOS-only MVP 测试入口，不改 macOS 主流程，也不改正式 iOS Configuration Center 架构。
- 后续已补成独立 iPhone 测试 App：
  - target: `PhotoMemoiOSMVP`
  - scheme: `PhotoMemoiOSMVP`
  - bundle id: `com.serydoo.PhotoMemo.iOS.MVP`
- 新增临时入口切换：
  - `当前配置中心`
  - `MVP 测试页`
- iOS Root 通过临时入口进入 MVP 测试页，便于在手机上直接验证交互方向。
- 独立 MVP App 默认进入：
  - `MVP 测试页`
- 同时保留独立存储的临时入口切换，不影响现有 `PhotoMemoiOS` 的入口状态。
- 新增 iOS MVP 测试页，复用：
  - `ConfigurationSession`
  - 当前 mock preview 文本
  - 当前模块枚举
- 新增共享 iOS 模块目录，避免旧 iOS 页面和 MVP 测试页各自维护一套模块定义。
- MVP 测试页当前包含：
  - Profile 区：
    - 当前 Preset 选择
    - 应用 / 默认 / 重置
    - 当前记忆对象摘要
  - Sticky Preview 区：
    - 白色底栏记忆卡结构
    - 左侧：记录者 / 记录时间
    - 中间：Logo 标识
    - 右侧：拍摄参数 / 智能时间结果
  - 自定义功能区：
    - `记录`
    - `时间线`
    - `上下文`
    - `记忆`
    - 输入后实时刷新 Preview
  - 模块插入交互：
    - 编辑区聚焦后弹出约 70% 屏宽模块窗
    - 选中模块后插入到当前输入区域
  - Logo 标识：
    - 默认 Apple mini-logo
    - 可切换到自选上传占位
  - `途途生日` 日期输入
  - 输出区域 UI-only 测试项
  - 写入记忆 UI-only 状态和预览
- 页面行为目前为：
  - Profile 在滚动层内，向上滚动后被带走
  - Preview 固定优先显示
  - 自定义功能区在 Preview 下方随滚动淡入
- 新增智能时间格式化能力：
  - 基于 mock 拍摄时间与 `途途生日` 的差值输出
  - 默认格式 `X年X个月X天`
  - 若差值小于 1 年则不显示 `X年`
  - 兜底可输出 `X天`
- 新增测试覆盖：
  - `CaptureTimeResolverTests`
- 本轮仍然严格保持：
  - iOS-only
  - mock-first
  - UI-only
  - 不接 Renderer
  - 不接 Metadata pipeline
  - 不接 Export
  - 不接真实 Photo Library 写入
  - 不改 Layout Engine
- 验证通过：
  - `PhotoMemoTests/CaptureTimeResolverTests`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug connected-device build
  - 安装到连接 iPhone
  - 启动 `com.serydoo.PhotoMemo.iOS`
- 独立 MVP App 验证通过：
  - `PhotoMemoiOSMVP` target / scheme 已被 Xcode 识别
  - `PhotoMemoiOSMVP` Debug iOS Simulator build
  - `PhotoMemoiOSMVP` Debug connected-device build
  - 已为 `com.serydoo.PhotoMemo.iOS.MVP` 自动生成 Development provisioning profile
  - 已安装到连接 iPhone
  - 自动启动被设备锁屏阻止，需要设备解锁后手动打开或再次触发 launch

## 2026-06-25 iOS Compact Profile And Module Library Refinement

- 本轮继续 iOS Configuration Center 局部打磨。
- iOS 顶部导航标题从 `PhotoMemo` 改为：
  - `PhotoMemo 配置中心`
- 顶部 `总体配置` 区进一步压缩为两行：
  - 第一行：记忆预设下拉、编辑、重置、保存并生效 / 已生效
  - 第二行：自动输出摘要
- 区域配置编辑器调整：
  - 上方状态文案从重复的 `已保存` 改为 `已生效`
  - 保存按钮保留 `保存配置 / 已保存`
  - 配置选择、编辑按钮和状态保持横向排列
- 自定义输入窗口调整：
  - 用户文字、已插入模块和继续输入区处于同一个编辑容器
  - 已插入模块改为横向 token strip
  - 点击多个模块会继续追加到当前区域配置
- `可插入模块` 调整：
  - 默认展示当前区域常用的 6 个模块
  - 新增 `更多模块` 下拉，展示其余可用模块
  - 目前未接真实 EXIF 的扩展字段插入后输出为空，不生成假值
- 左侧 Library 调整：
  - `人物` 分组下方新增 `+ 新增人物` 入口
  - `旅行` 分组改为 `事件`
  - `事件` 分组下方新增 `+ 新增事件` 入口
- 本轮仍然是 iOS-only / UI-only / mock-first，没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - real Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemoiOS` Debug connected-device build
- 已安装并启动到连接的 iPhone：
  - bundle id: `com.serydoo.PhotoMemo.iOS`

## 2026-06-25 iOS Two-Column Configuration Center Polish

- 本轮继续 iOS Configuration Center 打磨。
- iOS 主界面已切到两段式：
  - 左侧为 Apple Mail 风格资料库目录
  - 右侧为 Profile / Subject / Memory Card / Object Inspector / Output / Guidance 详情区
- 左侧包含：
  - 资料库
  - 人物
  - 旅行
  - 卡片区域
  - 记忆模块
  - 输出内容
  - 时间锚点说明
  - 记忆对象资料库说明
- 点击 Subject 后，右侧 Profile 区下方展示 `MemorySubjectEditorView`，不再直接占满右侧或改成 sheet。
- 点击卡片区域后，右侧展示：
  - 与 macOS 对齐的四区域 + 图标 Memory Card Preview
  - Region Strip
  - 同一套 `InspectorProvider` 对象检查器
  - 可插入模块库
- iOS 顶部 `总体配置` 支持：
  - 下拉选择记忆预设
  - 重命名
  - 重置
  - 保存并生效状态
- macOS 中间顶部同步补齐：
  - `总体配置`
  - 重置
  - 保存并生效
- `ConfigurationSession` 新增轻量 UI 状态：
  - `appliedMemoryPresetID`
  - `selectedMemoryPresetIsApplied`
  - `applySelectedMemoryPreset()`
  - `resetSelectedMemoryPreset()`
- 本轮仍然是 UI-only / mock-first，没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - real Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug connected-device build
- 已安装到连接的 iPhone：
  - bundle id: `com.serydoo.PhotoMemo.iOS`
- 自动启动被设备锁屏阻止：
  - `Unable to launch ... because the device was not, or could not be, unlocked`

## 2026-06-25 iOS Preview-First Configuration Refinement

- 本轮只修改 iOS 端 Configuration Center。
- macOS Configuration Center 保持现有结构。
- 本轮继续压缩 iOS 信息层级，让 Preview 成为第一视觉：
  - `总体配置` 从大卡片压缩为顶部薄工具条
  - `当前配置预览` 放大，优先占据右侧上方空间
  - 左侧资料库整体下移
  - 左侧目录行高压缩
- iOS 左侧移除：
  - `当前配置展示`
- iOS 左侧调整：
  - `配置说明` 单独进入低优先级 `说明` 分组
  - 不再和 `输出` 同级
- 卡片区域右侧不再直接复用 macOS 完整 Object Inspector。
- 新增 iOS 专用轻量区域编辑器：
  - 自由输入当前区域内容
  - 插入模块以浅色小方块展示
  - 每个插入模块可删除
  - 输入和模块变化实时刷新 Preview
- 非文字区域（例如图标）不再显示可插入模块。
- 文字区域显示底部模块插入区：
  - 记录 / 时间线 / 上下文：简化为配置窗口
  - 记忆：保留紧凑系统模块提示
- 本轮仍然是 mock-only / UI-only，没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - real Memory Engine runtime
- 验证通过：
  - `git diff --check`
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build
  - `PhotoMemoiOS` Debug connected-device build
- 已安装并启动到连接的 iPhone。

## 2026-06-25 iOS Configuration Center Polish Shell

- 本轮开始 iOS 版本打磨准备。
- 新增 iOS-only：
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/ConfigurationCenteriOSView.swift`
- `PhotoMemoRootSceneView` 现在按平台选择：
  - iOS -> `ConfigurationCenteriOSView`
  - macOS -> `ConfigurationCenterView`
- iOS 第一版布局：
  - 左侧控制列：
    - Subject
    - Block Configuration
    - Content Library
    - Output
    - 写入记忆
  - 右侧预览列：
    - Profile
    - 保存并生效
    - 当前配置预览
- Subject 点击后进入档案管理 Sheet。
- Sheet 当前支持 mock 编辑：
  - 对象定义
  - 姓名 / 昵称
  - 记忆显示名称
  - 人生节点 / 时间锚点
- 本轮仍然是 UI-only / mock-first。
- 没有修改：
  - Renderer
  - Metadata
  - Export
  - Share Extension behavior
  - Photo Library behavior
  - Layout Engine
  - Memory Engine runtime
- 验证通过：
  - `PhotoMemoiOS` Debug iOS Simulator build
  - `PhotoMemo` Debug macOS build

## 2026-06-24 PDR-005 Memory Language Layer

- 本轮是 Repository Amendment。
- 没有修改：
  - Swift
  - Renderer
  - Metadata
  - Export
  - Share Extension
  - Photo Library behavior
  - Layout Engine
  - Memory Engine runtime
- 新增：
  - `Docs/PDR/PDR-005_Memory_Language_Layer.md`
- PDR-005 冻结：
  - MemoryBlock 是内容资产，不是布局资产
  - Subject + Action + Result 是 `Preset Schema #001`，不是底层 Core Model
  - 底层长期模型是 Field-Based MemoryBlock
  - 概念形态：

```text
MemoryBlock
-> BlockField
-> Value Source
```

- Value Source 包括：
  - Fixed Text
  - Token Binding
  - Smart Module Binding
  - Custom Field Binding
- Block Template 定义 field schema，不定义 slot position。
- Module 负责计算 field value，不定义整个 MemoryBlock。
- IA-003A 仍然是 MemorySubject Adapter。
- PDR-005 的首个实现落点是：

```text
IA-003C Memory Block Resolver
```

## 2026-06-24 IA-002 Freeze / IA-003 Product Realization

- 用户正式确认：

```text
IA-002 can end.
Product Definition -> Product Realization.
```

- IA-002 Architecture 冻结：
  - Configuration Center
  - Library
  - Interactive Memory Card
  - Object Inspector
  - CardRegion
  - InspectorProvider
  - TokenLibrary
  - MemoryBlock
  - DecorationAsset
  - Configuration Snapshot
  - Region Strip
- 以后 UI 可以 Polish，但不能推翻 IA-002 架构。
- 五条 V3 设计基石登记为当前事实：
  - Configuration Center edits Objects, not Data.
  - Everything starts from the Memory Card.
  - Configuration Center previews the real Memory Card, not an abstract layout.
  - Capture-Time Principle.
  - Memory Subject = Identity + MemoryBehavior.
- 下一阶段：

```text
IA-003 Memory Engine Integration
```

- 目标：

```text
Photo
-> EXIF
-> Memory Subject
-> Configuration Snapshot
-> Memory Engine
-> Memory Card
-> Renderer
```

- 开发顺序：

```text
IA-003A MemorySubject Adapter
-> IA-003B Configuration Snapshot
-> IA-003C Memory Block Resolver
-> IA-003D CaptureTimeResolver
-> IA-003E Interactive Memory Card connects real data
-> IA-003F Renderer
```

- 下一轮如果开始写代码，应从 IA-003A 开始。
- IA-003A 只做 `PersonalProfile` / 现有身份配置到 `MemorySubject` 的 adapter 边界。
- IA-003A 不应修改：
  - Renderer
  - Metadata
  - Export
  - Share Extension
  - Photo Library behavior
  - Layout Engine

## 2026-06-24 Memory Card Preview Polish Amendment

- 新冻结原则：

```text
Preview is the Renderer before Rendering.
```

- 中文理解：
  - Configuration Center 里的 Preview，本质上就是 Renderer 的实时映射。
- 中间区域正式定义为：
  - Memory Card Preview
- 中间区域不再承载：
  - Photo
  - placeholder photo
  - abstract editor layout
  - visible configuration grid
- 产品边界：
  - Photos belong to Apple Photos.
  - PhotoMemo owns the Memory Card.
- Preview 默认应该像已经生成好的 Memory Card。
- 只有 hover / selected / Region Strip 暗示可编辑性。
- 本轮 UI polish：
  - 去掉 `InteractiveMemoryCard` 的灰色背景
  - 弱化卡片边框和阴影
  - 去掉 slot 区域灰底
  - 降低默认分隔线可见度
  - 保留 Region Strip 与 Object Inspector 路由

## 2026-06-24 IA-002C Real Bottom Card Preview Amendment

- 本轮从 tag 回滚点继续：

```text
ia-002c-ui-polish-checkpoint
0176b29 Checkpoint Configuration Center UI polish
```

- 本轮只重设计中间 `InteractiveMemoryCard`。
- 保留现有：
  - Library
  - Object Inspector
  - Inspector sections
  - Token UI
  - mock-only 边界
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Photo Library
  - Memory Engine runtime
  - `PersonalProfile` adapter
- 新冻结原则：

```text
Configuration Center previews the real Memory Card, not an abstract layout.
```

- 中间卡片改为真实 Bottom Card 结构：

```text
Decoration
-> Slot A
-> Slot B
-> Slot C + Slot D
```

- Decoration 包含：
  - Icon
  - Badge
- 四个可编辑 Slot：
  - Slot A = Recorder
  - Slot B = Timeline
  - Slot C = Location
  - Slot D = Memory Expression
- Region Strip 已加入卡片下方：
  - Recorder
  - Timeline
  - Location
  - Memory
- Region Strip 与真实卡片区域选择同一组 `CardRegion`。
- 同步更新：
  - `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/CURRENT_STATUS.md`

## 2026-06-24 IA-002C UI Polish Foundation

- 本轮回应第一次 PhotoMemo V3 可视化 review。
- 仍然是 mock-only Configuration Center UI polish。
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Photo Library
  - Memory Engine runtime
  - `PersonalProfile` adapter
- 中间 Memory Card 已从六宫格改为真实 Bottom Card 构图。
- 所有 Memory Card 点击仍然通过 `CardRegion`。
- 当前视觉层级开始转向：
  - Icon
  - Slot D
  - Slot A
  - Slot B
  - Slot C
- 左侧 Sidebar 已升级为 Library 分组：
  - People
  - Travel
  - New Subject
- 新增 Configuration UI design-system primitives：
  - `InspectorSectionView`
  - `InspectorPropertyRow`
- Object Inspector 改为更清晰的 section 节奏和更大的 section 间距。
- Memory Subject Inspector 改为：
  - Overview
  - Behavior
- Memory Expression Inspector 改为：
  - Memory Expression
  - Properties
  - Token Library
- Token 从 bordered button 转向 inline Apple Token / capsule token。
- Mock decoration symbols 已统一为更 Apple 的 SF Symbols：
  - `person.fill`
  - `camera.fill`
  - `location.fill`
  - `flag.fill`
  - `apple.logo`
- 验证已通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`
- 手动查看注意：
  - `/tmp/PhotoMemoDerivedData` 的新构建可以直接运行
  - 但 Computer Use 仍把 `PhotoMemo` app 名称解析到旧 bundle 路径
  - 后续如果要稳定截图，应先清理旧 DerivedData / LaunchServices 缓存或用唯一 bundle id 运行

## 2026-06-24 Repository Amendment: Configuration Center Architecture Revision A

- 本轮是 Repository Amendment，不是开发指令。
- 严格没有修改：
  - Swift
  - SwiftUI
  - Renderer
  - Metadata
  - Export
  - Share Extension
  - Photo Library
  - Memory Engine runtime
  - adapter implementation
- 新增：
  - `Docs/PDR/PDR-004_Configuration_Center_Architecture.md`
- PDR-004 冻结：

```text
Configuration Center edits Objects, not Data.
```

```text
Everything starts from the Memory Card.
```

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

- Configuration Center 正式定义为：
  - Memory Engine Configuration Center
  - 长期对象定义中心
  - 不是 Settings
  - 不是 Workspace
- Library 正式定义为：
  - Memory Object Library
- Interactive Memory Card 正式定义为：
  - Primary Object
  - Preview + Navigation + Selection
  - 不显示照片、示例图、背景图、Renderer Preview
- Object Inspector 正式替代 generic Editor 语言。
- Object Inspector 统一结构：
  - Overview
  - Properties
  - Behavior
  - Resources
  - Preview
- `CardRegion` 冻结：
  - `subject`
  - `icon`
  - `badge`
  - `slotA`
  - `slotB`
  - `slotC`
  - `slotD`
- `CardRegion -> InspectorProvider -> Object Inspector` 成为正式路由。
- `MemorySubject -> Identity + MemoryBehavior` 成为正式模型边界。
- `MemoryExpression -> MemoryTextBlock + MemoryTokenBlock` 成为正式表达结构。
- `TokenCategory` 冻结为：
  - Memory
  - Photo
  - System
- `DecorationAsset` 统一 Icon / Badge / Future Decoration。
- `Logo` 不再作为独立配置对象。
- `ConfigurationSession` 保持轻量，只负责 Selection / Hover / Editing / Future Undo / Future Redo。
- Capture-Time Principle 冻结：
  - Memory Token 基于 Photo Capture Date + Reference Date
  - 重新导出不得改变 Memory Expression
- PhotoMemo Design System 正式进入 Repository 事实层。
- 同步更新：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `README.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/PDR/PDR_INDEX.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/Configuration/CONFIGURATION_MODEL.md`
  - `Docs/REPOSITORY_VOCABULARY.md`
  - `Docs/NEVER_BREAK.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/CURRENT_STATUS.md`
- 下一轮顺序已修订：
  1. IA-002C Object Inspector
  2. IA-002D MemorySubject Adapter
- 验证：
  - `git diff --check` 通过
  - 未运行 build，因为本轮是 documentation-only repository amendment

## 2026-06-24 Sprint IA-002B Interactive Memory Card

- 本轮继续 IA-002 Configuration Center UI Architecture。
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Photo Library
  - Memory Engine runtime
  - `PersonalProfile` adapter
- 本轮核心原则：

```text
Everything starts from the Memory Card.
```

- `CardRegion` 已正式作为交互坐标冻结：
  - `subject`
  - `icon`
  - `badge`
  - `slotA`
  - `slotB`
  - `slotC`
  - `slotD`
- 新增：
  - `CardRegionBehavior`
  - `InspectorProvider`
  - `TokenCategory`
  - `MemoryBehavior`
- `CardSelection` 现在包含：
  - selected region
  - hovered region
- `InteractiveMemoryCard` 现在支持：
  - 点击 Subject / Icon / Badge / SlotA / SlotB / SlotC / SlotD
  - 当前 region selection
  - hover highlight
  - 轻量 Apple-native animation
  - region accessibility identifier / label
- `InspectorView` 不再直接膨胀 `switch(region)`，改为：

```text
CardRegion
-> CardRegionBehavior
-> InspectorProvider
-> Inspector View
```

- `MemoryBlock` 拆分为：
  - `MemoryTextBlock`
  - `MemoryTokenBlock`
  - `MemoryBlock`
- `TokenLibrary` 现在使用 `TokenCategory` 管理 Memory / Photo / System。
- `MemorySubject` 不再直接持有 behavior 字段，改为：

```text
MemorySubject
-> MemoryBehavior
```

- `MemoryBehavior` 当前包含：
  - Primary Anchor
  - Icon Strategy
  - Badge Strategy
  - Memory Expression

验证已通过：

- `PhotoMemo`
- `PhotoMemoiOS`
- `PhotoMemoShareExtension`
- `git diff --check`

未手动验证：

- 运行中点击每个 Memory Card region 的真实视觉反馈
- 指针设备 hover 体验
- VoiceOver 读出顺序

下一轮建议：

1. 进入 IA-002C `Object Inspector`
2. 建立 Object Inspector Design System
3. 继续使用 Mock Data
4. 不接入 Renderer / Metadata / Export / Memory Engine Runtime / PersonalProfile Adapter
5. 等 Object Inspector 稳定后，再进入 IA-002D `MemorySubject Adapter`

## 2026-06-24 Sprint IA-002A Configuration Center Skeleton

- 本轮正式进入 V3 Configuration Center UI skeleton。
- 严格没有接入：
  - Renderer
  - Metadata
  - Export
  - Share Extension intake
  - Memory Engine runtime behavior
- 新增 `Source/PhotoMemo/PhotoMemo/ConfigurationCenter/`，包含：
  - `Sidebar`
  - `MemoryCard`
  - `Inspector`
  - `Editors`
  - `Components`
  - `Models`
- 新增 skeleton 类型：
  - `MemorySubject`
  - `MemoryBlock`
  - `MemoryBlockType`
  - `MemoryBlockLibrary`
  - `MemoryExpression`
  - `TokenLibrary`
  - `DecorationAsset`
  - `DecorationKind`
  - `ConfigurationSnapshot`
  - `CaptureTimeResolver`
  - `CardRegion`
  - `CardSelection`
  - `InteractiveMemoryCardSelection`
  - `ConfigurationCenterState`
  - `ConfigurationSession`
- 新增三栏 UI：
  - 左侧 `MemorySubjectListView`
  - 中间 `InteractiveMemoryCard`
  - 右侧 `InspectorView`
- 新增 Inspector skeleton：
  - `MemorySubjectEditorView`
  - `ExpressionEditor`
  - `TokenPicker`
  - `IconLibraryView`
  - `BadgeLibraryView`
- `PhotoMemoRootSceneView` 现在直接打开 `ConfigurationCenterView`。
- 旧 `MainView`、真实导入/渲染/导出链路仍保留，未接入本轮 UI skeleton。
- 验证已通过：
  - `PhotoMemo`
  - `PhotoMemoiOS`
  - `PhotoMemoShareExtension`

下一轮建议：

1. 对 IA-002A 进行 Architecture Review，确认 `MemorySubject / DecorationAsset / MemoryBlock / TokenLibrary` 边界
2. 再开始 IA-002B，把 mock `MemorySubject` 与旧 `PersonalProfile` 做 adapter，而不是直接替换真实业务
3. 继续保持 Renderer / Metadata / Export 不动，直到 Configuration Experience 骨架冻结

## 2026-06-24 RSR-001 Repository Simplification Review

- 本轮严格保持文档切片，没有改：
  - Swift
  - SwiftUI
  - Renderer
  - Engine
  - Metadata
  - Export
  - Database
  - Xcode project
  - Pipeline

- 本轮目标从 Repository Refactor 切换为 Repository Simplification：
  - 删除或降级不再符合 PhotoMemo Product Philosophy 的工作台、导入、仪表盘、任务中心、工作区、大批量优先叙事
  - 把当前仓库语言统一到 Configuration Center / Preset / Configuration Preview / Apple Photos Lifecycle

- 本轮新增：
  - `Docs/REPOSITORY_VOCABULARY.md`
  - `Docs/REPOSITORY_SIMPLIFICATION_REPORT.md`

- 本轮重写：
  - `README.md`
    - 保留 Repository Mission：
      - `PhotoMemo exists to help people read their memories, not just store their photos.`
      - `PhotoMemo 存在的意义，不是帮助人们保存照片，而是帮助人们阅读回忆。`
      - `Photos preserve moments. PhotoMemo reveals their meaning.`
      - `照片记录瞬间。PhotoMemo 赋予意义。`
    - 删除旧的 import-first 首页主链、旧路线图和旧 batch-first 暗示
    - 新增 Apple Photos Lifecycle / Behavior State Machine / Configuration Snapshot / batch scale

- 本轮同步：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `RepositoryAudit.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/Interaction/IA-001_Interaction_Architecture.md`
  - `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
  - `Docs/Configuration/CONFIGURATION_MODEL.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/CURRENT_STATUS.md`

- RSR-001 冻结：
  - Configuration Center
  - Preset
  - Configuration Preview
  - Apple Photos Lifecycle
  - Behavior State Machine
  - Configuration Snapshot
  - batch scale:
    - Primary: 1-20
    - Secondary: 20-50
    - Advanced: 50+

- 当前 Daily Workflow：

```text
Apple Photos
-> Share
-> PhotoMemo
-> Processing
-> Notification
-> Apple Photos
```

- 当前 Design Review 结束语：

```text
Every review should leave the repository simpler than before.
```

```text
每一次设计评审，都应该让 PhotoMemo 比昨天更简单一点。
```

- 后续建议：
  1. 研究规格稳定后，再决定旧 Workspace 文档归档/改名/迁移
  2. 不要马上改 Swift 中的 `Workspace*` / `Template` / `Preview` 标识，除非单独做 code-safe terminology refactor
  3. 下一次 runtime 恢复后再审查用户可见字符串里的 template / preview / import

## 2026-06-23 IA-001A Behavior / Boundary / Mission 补齐

- 本轮继续保持文档切片，没有改：
  - Swift
  - SwiftUI
  - Renderer
  - Engine
  - Metadata
  - Export
  - Database
  - Pipeline

- 本轮补齐的核心不是新设计，而是把第一轮 IA-001 冻结结果继续补成完整 repository product definition。

- 本轮新增：
  - `Docs/NEVER_BREAK.md`
  - `Docs/PDR/PDR_INDEX.md`

- 本轮完善：
  - `PROJECT_PHILOSOPHY.md`
    - 新增 Product Boundary 表格
    - 明确 Apple Photos / PhotoMemo 责任边界
  - `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
    - 新增 Behavior State Machine
    - 新增 Configuration Snapshot Principle
  - `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`
    - 新增 Apple Review Checklist
  - `Docs/Guidelines/LANGUAGE_SYSTEM.md`
    - 正式明确 Soft Limit Language 是语言而不是限制
    - 新增 Smart Batch Recommendation
  - `Docs/Interaction/IA-001_Interaction_Architecture.md`
    - 新增 Smart Batch Recommendation
  - `PROJECT_CONSTITUTION.md`
    - 补齐 Apple Trust Design Rationale
    - 明确来自长期管理超过 11 万张生活照片的真实使用经验
  - `README.md`
    - 新增 Repository Mission：
      - `PhotoMemo exists to help people read their memories, not just store their photos.`
      - `PhotoMemo 存在的意义，不是帮助人们保存照片，而是帮助人们阅读回忆。`
  - `Docs/FROZEN_REGISTRY.md`
    - 登记本轮新增冻结项
  - `Docs/DESIGN_DECISIONS.md`
    - 补登记 Product Boundary / Configuration Snapshot / State Machine / Smart Batch / Apple Review / Never Break / Repository Mission
  - `Docs/DOCUMENT_INDEX.md`
    - 收录 `NEVER_BREAK` 与 `PDR_INDEX`

- 本轮 IA-001A 冻结补齐项：
  - Product Boundary
  - Behavior State Machine
  - Configuration Snapshot
  - Apple Review Checklist
  - Smart Batch Recommendation
  - Soft Limit Language clarification
  - Apple Trust Design Rationale
  - Never Break List
  - PDR Index
  - Repository Mission

- 验证：
  - 已确认仍然没有实现层文件改动
  - 本轮输出适合继续作为文档冻结的一部分进入后续 Product Design Review 之前的仓库事实层

## 2026-06-23 PM-003 冻结 + IA-001 Interaction Architecture 文档归档

- 本轮严格只做 repository documentation refactor，没有改：
  - Swift
  - SwiftUI
  - Renderer
  - Engine
  - Metadata
  - Export
  - Database
  - Pipeline

- 本轮先完成了 PM-003 第一阶段冻结同步：
  - 新增 `Docs/PM-003_Content_Layout_System.md`
  - 冻结：
    - Semantic Slot Principle
    - Slot A = Recorder
    - Slot B = Capture Summary
    - Slot C = Timeline
    - Slot D = Time Anchor
    - Life Anchor = Life Event
    - Slot D Grammar
    - Expression / Engine 解耦
    - Variable 分类
    - Typography Strategy（语义层）

- 本轮随后进入 IA-001 Interaction Architecture：
  - `PhotoMemo` 正式定义为：
    - Apple 生态内的 `Local First Memory Capability`
  - 同步北极星：
    - 不改变用户管理照片的方式
    - 只改变用户理解照片的方式

- 本轮新增 IA-001 文档群：
  - `Docs/Interaction/IA-001_Interaction_Architecture.md`
  - `Docs/Behavior/BEHAVIOR_SPECIFICATION.md`
  - `Docs/Guidelines/LANGUAGE_SYSTEM.md`
  - `Docs/Guidelines/PRODUCT_PERSONALITY.md`
  - `Docs/Guidelines/APPLE_NATIVE_GUIDELINES.md`
  - `Docs/Configuration/CONFIGURATION_MODEL.md`
  - `Docs/Product/ANTI_GOALS.md`
  - `Docs/DESIGN_DECISIONS.md`
  - `Docs/FROZEN_REGISTRY.md`
  - `Docs/PDR/PDR-003_Interaction_Architecture.md`

- 本轮新增永久理念文档：
  - `LIFE_TIMELINE_PHILOSOPHY.md`
    - 记录“PhotoMemo 不只是帮助用户回忆过去，更帮助用户连接过去、现在与未来……”

- 本轮同步更新顶层事实文档：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `PROJECT_PHILOSOPHY.md`
  - `AI_CONTEXT.md`
  - `Docs/CURRENT_STATUS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `CHANGELOG.md`

- IA-001 当前冻结内容：
  - Main App = Configuration Center
  - Primary Entry = `Apple Photos -> Share -> PhotoMemo -> Memory Workflow -> Done`
  - Zero Interaction
  - Quiet Computing
  - Back To Photos
  - Task Recovery
  - Device Adaptive
  - Storage Verification
  - Library Consistency
  - Original Never Changes
  - Metadata Preservation
  - Apple Naming
  - Apple Trust
  - Product Personality
  - Language System
  - Configuration Layer
  - Product Boundary
  - Anti Goals

- 本轮还新增长期规则到 `Docs/MASTER_PLAN.md`：
  - 以后任何新功能必须经过：
    1. `PDR`
    2. `Repository Refactor`
    3. `Architecture Review`
    4. `Implementation`
    5. `Review & Freeze`

- 验证：
  - 已确认本轮无 `.swift`、`.plist`、`project.pbxproj` 实现层文件改动
  - 本轮适合直接作为文档归档同步到 GitHub

## 2026-06-22 Memory Presentation Engine 哲学升级

- 用户明确最高产品定义再次升级：
  - 不再只叫 `Photo Presentation Engine`
  - 更准确是 `Memory Presentation Engine`
  - 因为 PhotoMemo 不只是 present photographs，而是 present memories

- 本轮新增：
  - `PROJECT_PHILOSOPHY.md`
  - `PROJECT_DIRECTION.md`
  - `Docs/03_Research/MemoryPhilosophy.md`
  - `Docs/ARCHITECTURE.md`

- 核心哲学：
  - Photos have timestamps.
  - Memories have positions.
  - EXIF answers when / where / how.
  - Memory Engine answers what this moment means.
  - PhotoMemo preserves both objective metadata and emotional Life Position.

- 新增概念：
  - Life Position
  - Memory Timeline
  - one photo may belong to multiple timelines simultaneously

- 职责边界：
  - Memory Engine only calculates relationships
  - Presentation Engine expresses relationships
  - Layout Engine decides how meaning is presented
  - Renderer simply draws

- 本轮同步：
  - `PROJECT_CONSTITUTION.md`
  - `Docs/MASTER_PLAN.md`
  - `README.md`
  - `PROJECT_RESET.md`
  - `RepositoryAudit.md`
  - `AI.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/CURRENT_STATUS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/02_Architecture/README.md`
  - `Docs/03_Research/README.md`

- 未做：
  - 没有改 runtime code
  - 没有改 Renderer
  - 没有改 UI

## 2026-06-22 Project Constitution + Research Methodology

- 用户提供第二份 V2 宪章指令，明确：
  - V2 Reset 已完成
  - 当前阶段是 Research Phase，不是 Development Phase
  - 不继续功能开发
  - 不继续 Renderer 打磨
  - 不继续 UI 调整
  - 当前工作只做 Reverse Engineering / Research
  - 旧文档暂时不要立即迁移，等 Research Specification 稳定后再迁移，避免重复移动

- 本轮新增最高优先级入口：
  - `PROJECT_CONSTITUTION.md`
    - 现在优先级高于 `Docs/MASTER_PLAN.md`
    - 明确项目 mission、first principles、philosophy、immediate task、documentation strategy、research system、measurement rules

- 本轮补齐 Research 体系缺口：
  - `Research/ReverseEngineeringRoadmap.md`
  - `Research/CanvasSpecification.md`
  - `Research/PanelSpecification.md`
  - `Research/AdaptiveRules.md`
  - `Research/MeasurementMethodology.md`

- 本轮同步更新：
  - `Docs/MASTER_PLAN.md`
  - `PROJECT_RESET.md`
  - `RepositoryAudit.md`
  - `Research/README.md`
  - `Research/ResearchHistory.md`
  - `README.md`
  - `AI.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/CURRENT_STATUS.md`

- `RepositoryAudit.md` 现在记录了：
  - product direction 文档重叠组
  - MainView refactor 文档重叠组
  - metadata/export 文档重叠组
  - session history 文档重叠组
  - V1 文档与 V2 宪章之间的关键冲突

- 重要边界：
  - 没有移动旧 `Docs/` 文件
  - 没有修改 runtime code
  - 没有改 Renderer / UI / Export / Metadata

下一轮最值得做：

1. 根据 `Research/MeasurementMethodology.md` 开始第一份真实 reverse-engineering 记录模板
2. 扩写 `Research/LayoutSpecification.md`，但仍不要写 LayoutEngine 代码
3. 等 Layout / Canvas / Panel 规格稳定后，再考虑旧 Docs 迁移

## 2026-06-22 PhotoMemo V2 Project Reset 落地

- 用户提供了新的最高优先级重置指令：
  - 停止功能开发
  - 停止 Renderer 继续打磨
  - 停止 UI 扩展
  - PhotoMemo 进入 Research Phase
  - 项目目标从 Photo Watermark App 转向 local-first Photo Presentation Engine

- 新的 V2 主链路：
  - `Photo -> Metadata Engine -> Presentation Engine -> Layout Engine -> Renderer -> Export`

- 本轮落地的永久入口：
  - `Docs/MASTER_PLAN.md`
    - V2 单一入口
    - 记录 vision、phase、roadmap、architecture、next step、forbidden actions
  - `PROJECT_RESET.md`
    - 记录为什么暂停开发、为什么开始 reverse engineering、为什么引入 Layout Engine、为什么进入 Repository V2
  - `RepositoryAudit.md`
    - 输出仓库审计：
      - Architecture
      - Documentation
      - Renderer
      - Workflow
      - Repository Health
      - Open Source Readiness
  - `Research/`
    - 建立研究骨架：
      - `ReverseEngineering.md`
      - `LayoutSpecification.md`
      - `TypographySpecification.md`
      - `ColorSpecification.md`
      - `BrandAnchorSpecification.md`
      - `MetadataSlotSpecification.md`
      - `AdaptiveLayout.md`
      - `OpticalLayout.md`
      - `ResearchHistory.md`

- 本轮同步的入口文件：
  - `README.md`
  - `AI.md`
  - `AI_CONTEXT.md`
  - `AGENTS.md`
  - `Docs/CURRENT_STATUS.md`
  - `Docs/DOCUMENT_INDEX.md`
  - `Docs/PROJECT_STRUCTURE.md`

- 本轮建立的非破坏性目标结构骨架：
  - `App/`
  - `DesignSystem/`
  - `LayoutEngine/`
  - `Renderer/`
  - `Examples/`
  - `Screenshots/`
  - `Docs/01_Product/`
  - `Docs/02_Architecture/`
  - `Docs/03_Research/`
  - `Docs/04_DesignSystem/`
  - `Docs/05_Renderer/`
  - `Docs/06_Development/`
  - `Docs/07_Releases/`

- 重要边界：
  - 本轮没有移动旧源码
  - 本轮没有删除旧文档
  - 本轮没有继续改 Renderer / UI / Export / Metadata 逻辑
  - 大规模文档迁移与源码结构迁移留给后续单独切片

- 验证：
  - `git diff --check` 通过
  - 未运行 Xcode build，因为本轮是文档与目录骨架重置，不改运行时代码

下一轮最值得做：

1. 先把旧 `Docs/` 文档迁移到 `Docs/01_Product` 到 `Docs/07_Releases`，每次迁移一组，并维护 redirect/index
2. 起草第一版 `Research/LayoutSpecification.md`
3. 起草 Layout Engine 数据契约，暂时不要改 renderer

## 2026-06-22 Immers White 双行文字簇收口

- 这一轮继续只收渲染层，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Share Intake
  - Export 命名
- 目标很明确：
  - 不再让白栏里的上下两层文字被 `Spacer` 撑成上下分离
  - 改成更接近目标样图的“垂直居中双行簇”

- 本轮代码收口：
  - `Source/PhotoMemo/PhotoMemo/Renderers/ImmersWhiteRenderer.swift`
    - `pinnedColumn(...)`
      - 去掉上下分离式 `Spacer`
      - 改为固定间距 + 整组居中
    - landscape 参数调整：
      - `title / metadata font ratio: 0.235 -> 0.218`
      - `bottom font ratio: 0.138 -> 0.132`
      - `group spacing ratio: 0.078 -> 0.112`
    - portrait 参数调整：
      - `title / metadata font ratio: 0.24 -> 0.225`
      - `bottom font ratio: 0.15 -> 0.142`
      - `group spacing ratio: 0.08 -> 0.098`
    - divider 强化：
      - `width: 1 -> 2`
      - 颜色改成更接近 `#D8D8D8`
    - 新增显式缩放阈值：
      - `primaryMinimumScaleFactor = 0.94`
      - `secondaryMinimumScaleFactor = 0.88`
    - 顶层主文字不再使用旧的 `0.72` 激进缩放
  - `Tests/PhotoMemoTests/RendererTests/ImmersWhiteRendererLayoutTests.swift`
    - 新增对 landscape / portrait 紧凑文字簇的参数回归保护
    - 新增对 divider width 与 minimumScaleFactor 的回归保护

- 本轮验证结果：
  - 通过了语法级 Swift parse：
    - `ImmersWhiteRenderer.swift`
    - `ImmersWhiteRendererLayoutTests.swift`
  - 后续进一步确认到机器上存在可用完整工具链：
    - `/Users/rui/Downloads/Xcode-beta.app/Contents/Developer`
  - `PhotoMemoiOS` 真机构建通过：
    - `xcodebuild -scheme PhotoMemoiOS -destination 'generic/platform=iOS' -allowProvisioningUpdates build`
  - 成品已安装到设备：
    - `iPhone7`
    - `00008150-000A043136A1401C`
  - 已成功拉起：
    - `com.serydoo.PhotoMemo.iOS`

- 当前真实状态更新为：
  - 代码改动已落地
  - 语法检查通过
  - iPhone 包已完成签名构建、安装、启动

- 本轮仍未完全收口的验证：
  1. `PhotoMemoTests` 还没有在当前 beta/macOS 路径下完成
  2. `PhotoMemo` macOS target 在当前 Xcode beta 下暴露出已有 `MainView` / `MainView+WorkspaceControls` 编译问题：
     - SwiftUI macro plugin response error
     - `isExpanded.toggle()` 的 immutable self 报错
  3. 这些问题不是这轮 `ImmersWhiteRenderer` 调整引入的，但会影响后续完整桌面编译链验证

## 2026-06-21 Classic White 人工视觉对照 + snapshot 回归链闭环

- 这一轮继续只收 `Classic White`，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Batch / Share 业务逻辑
- 目标不是继续调样式，而是把 `Classic White` 的视觉结果正式纳入可重复验证。

- 本轮新增内容：
  - `Tests/Fixtures/RendererSnapshots/ClassicWhite/full-card/`
    - 已提交 4 张人工视觉基准图：
      - `landscape_standard`
      - `landscape_long_exif`
      - `portrait_standard`
      - `portrait_long_memory`
  - `Tests/PhotoMemoTests/Support/ClassicWhiteSnapshotSupport.swift`
    - 提供 deterministic synthetic scenario
    - 支持：
      - record mode
      - reference compare
      - mismatch artifact 输出
      - test attachment 导出
  - `Tests/PhotoMemoTests/RendererTests/ClassicWhiteSnapshotTests.swift`
    - 为四个 full-card 场景提供 snapshot 级回归保护
  - `Docs/ClassicWhiteVisualQA.md`
    - 记录人工目视检查项
    - 记录基准图刷新流程

- 这轮里一个关键结论：
  - Xcode 测试附件导出的 PNG 与渲染原图之间，会存在极轻微色差
  - 当前观测值是：
    - `maxChannelDelta = 1`
    - 差异像素占比远低于 `0.05%`
  - 因此 snapshot compare 现在采用：
    - 先严格比较
    - 若只有极小 attachment-refresh 色差，则允许通过
  - 这不会放过真正的布局回归，因为：
    - divider
    - padding
    - font tier
    - truncation
    - module width
    这些变化都会远超这个容差

- 本轮验证：
  - `ClassicWhiteSnapshotTests` 正常模式通过
  - 录制模式也已验证可工作：
    - `.record-mode`
    - `xcresulttool export attachments`
    - 替换 reference PNG
    - 再回到正常模式复验
  - `PhotoMemoTests` 全量通过
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
  - 真机安装并启动通过：
    - 设备：`iPhone7`
    - 型号：`iPhone 17 Pro Max`
    - bundle id：`com.serydoo.PhotoMemo.iOS`

- 当前意义：
  - Classic White 现在同时具备：
    - theme 常量保护
    - grid 数学保护
    - renderer 路由保护
    - full-card snapshot 保护
  - 后续再做字体、间距、分隔符等微调时，已经不是“靠眼睛记”，而是有稳定回归链可依赖

## 2026-06-21 Classic White 第二层回归保护

- 这一轮继续只收 `Classic White`，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Batch / Share 业务逻辑
- 目标不是继续改视觉，而是把已经落地的设计系统再锁紧一层，减少后续 refactor 误伤。

- 本轮新增两个可测试支点：
  - `RecordCardRenderer.destination(for:)`
    - 让 preset -> renderer 的路由成为显式边界
    - 不再只靠 `body` 内部 switch 隐式表达
  - `ClassicWhiteCardRenderer.layoutMetrics(forTotalWidth:)`
    - 把固定底栏布局里的几何结果抽成可测试度量
    - 当前锁定的是：
      - content width
      - left / center / right module width
      - fixed content height

- 本轮新增回归保护：
  - `Tests/PhotoMemoTests/RendererTests/RecordCardRendererRoutingTests.swift`
    - 锁定：
      - `template2 / template3 -> classicWhite`
      - `template1 / immersWhite -> immersWhite`
  - `Tests/PhotoMemoTests/RendererTests/ClassicWhiteCardRendererLayoutTests.swift`
    - 锁定：
      - `960pt` 总宽时，固定 `40 / 20 / 40` 会得到：
        - `320 / 160 / 320`
      - 当容器比水平 padding 更窄时，不会出现负宽度

- 这一轮的意义：
  - 之前已有：
    - 主题常量保护
    - 导出尺寸保护
  - 现在又补上：
    - renderer 路由保护
    - 固定 grid 宽度计算保护
  - Classic White 设计系统已经不只是“值固定”，而是“值如何落到真实布局里”也能被回归测试覆盖。

- 本轮验证：
  - 定向测试通过：
    - `RecordCardRendererRoutingTests`
    - `ClassicWhiteCardRendererLayoutTests`
  - `PhotoMemoTests` 全量通过
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`

- 当前仍保留的边界：
  - 还没有做真实视觉 snapshot / pixel comparison
  - 还没有把 line-box / baseline 对齐进一步抽成单独可测模型
  - 但 preset 路由和固定 grid 已经有第二层保护，后续继续整理 render theme 时会更安全

## 2026-06-21 Classic White Render Design System

- 这一轮严格只动 `Classic White` 渲染层，没有碰：
  - Metadata Pipeline
  - Memory Engine
  - Batch / Share 业务逻辑
- 目标是把旧的比例驱动白边实现，收成一套固定主题的 Information Card Renderer。

- 本轮新增主题层：
  - `Source/PhotoMemo/PhotoMemo/Renderers/RenderTheme.swift`
  - 当前已落地：
    - bottom height: `260`
    - background: `#F4F3F3`
    - grid: `40 / 20 / 40`
    - primary text: `28pt`
    - secondary text: `18pt`
    - horizontal padding: `80`
    - top padding: `54`
    - bottom padding: `42`
    - divider: `2 x 110`

- 本轮结构收口：
  - `ClassicWhiteRenderer`
    - 不再保留旧的 orientation ratio layout 结构
    - 现在只负责：
      - `theme`
      - `outputPixelSize(...)`
  - `ClassicWhiteCardRenderer`
    - 新增独立文件
    - 按：
      - left module
      - center module
      - right module
      的方式排列
    - 固定字号，不再 `minimumScaleFactor`
    - 长内容改为 truncation，优先保布局稳定
  - `RecordCardRenderer`
    - 现在只保留 preset -> renderer 路由
  - `RecordCardExportService`
    - Classic White 导出尺寸现在是固定规则：
      - `imageHeight + 260`

- 本轮新增回归保护：
  - `Tests/PhotoMemoTests/RendererTests/ClassicWhiteRendererThemeTests.swift`
  - 锁定：
    - 主题常量
    - 固定底栏高度
    - 固定导出尺寸
    - fallback size 行为

- 本轮还额外修了一处 target 边界问题：
  - `PhotoMemoiOS` 构建时会顺带编译 `PhotoMemoShareExtension`
  - share extension 当前不携带完整 renderer 依赖
  - 因此给：
    - `ClassicWhiteRenderer.swift`
    - `ClassicWhiteCardRenderer.swift`
    加了 `#if !PHOTOMEMO_SHARE_EXTENSION`
  - 这样新渲染文件不会误泄漏到轻量 share target

- 文档同步：
  - `Docs/RENDER_SPEC.md`
    - 已更新为新的 Classic White 设计系统规范
  - `Docs/CURRENT_STATUS.md`
    - 已增加这一轮状态记录

- 本轮验证：
  - `PhotoMemoTests` 全量通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前已知边界：
  - 这一轮没有做真实视觉截图回归
  - 还没有为 Classic White 建立 snapshot / pixel comparison
  - 但结构、主题常量和导出尺寸已经进入可测试状态

## 2026-06-21 Immers 右侧列收紧、占位命名兜底、真机重装

- 这一轮继续只做小切片，没有扩功能，也没有改架构边界。
- 当前聚焦的是两个用户直接能看到的问题：
  - `ImmersWhiteRenderer` 右侧上下两块内容要更明确地左对齐，并更贴近 logo / 分隔线
  - 导出命名不应继续把 `PhotoMemo Import` 当成真实原始文件名

- 本轮视觉收口：
  - `ImmersWhiteRenderer`
    - 右侧列继续保持 `leading` 对齐
    - 新增独立的：
      - `logoToDividerSpacingRatio`
      - `dividerToTextSpacingRatio`
    - 当前规则变成：
      - logo 到分隔线略保留呼吸
      - 分隔线到右侧文字更紧
    - portrait / landscape 都给右侧列增加了可用宽度
    - `styledText` 开启 `allowsTightening(true)`，减轻右上参数行被动缩小

- 本轮命名收口：
  - `PhotoFileNameResolver`
    - 现在会把以下都视为占位名，而不再当成真实原图名：
      - `Photo Library`
      - `Photo Library 2`
      - `PhotoMemo Import`
      - `PhotoMemo Import (1)`
    - 新增：
      - `outputBaseName(...)`
      - `timestampFallbackBaseName(...)`
  - `RecordCardExportService`
    - 导出文件名现在优先级变成：
      1. 已知真实原图名
      2. 通过 `assetLocalIdentifier` 再向系统相册回查原图名
      3. 如果仍然只有占位名，则退到稳定的拍摄时间命名：
         - `IMG_yyyyMMdd_HHmmss`
    - 复制后缀规则继续保留：
      - `xxx.jpg`
      - `xxx (1).jpg`
      - `xxx (2).jpg`

- 本轮新增回归保护：
  - `PhotoFileNameResolverTests`
    - 锁定 `PhotoMemo Import` 占位名不会被当成真实原图名
    - 锁定拍摄时间回退命名
  - `RecordCardBuildServiceTests`
    - 锁定 placeholder source name 会导出成 `IMG_yyyyMMdd_HHmmss.jpg`
  - `ImmersWhiteRendererLayoutTests`
    - 锁定右侧列继续左对齐
    - 锁定分隔线到右文案的间距小于 logo 到分隔线

- 本轮验证：
  - 定向测试通过：
    - `PhotoFileNameResolverTests`
    - `RecordCardBuildServiceTests`
    - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - `ImmersWhiteRendererLayoutTests`
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
  - 真机安装：
    - 已重新安装到设备 `00008150-000A043136A1401C`
  - 真机启动：
    - 安装成功
    - 自动启动被系统拒绝，原因是设备当时处于锁定状态

## 2026-06-21 First Run 向导按系统 Form 风格收口

- 这一轮根据 HIG 方向做了一个小范围 UI 提升，没有扩功能，也没有改架构边界。
- 本轮只把首次启动向导从自定义卡片堆叠，收回到更接近系统设置流程的 SwiftUI 结构：
  - `NavigationStack`
  - `Form`
  - `Section`
  - `Picker`
  - `TextField`
  - `DatePicker`
  - `LabeledContent`
- 首启流程仍然保持原来的 5 步：
  - 欢迎
  - 身份
  - 宝宝昵称
  - 出生日期
  - 保存位置
- UI 规则同步：
  - 使用标准字体层级，例如 `.title`、`.headline`、`.body`、`.footnote`
  - 使用 `.accentColor`、`.primary`、`.secondary` 等系统语义样式
  - 去掉首启向导里的固定宽度和自定义白卡片依赖
  - 步骤切换保留系统默认动画
- 编译收口：
  - 修复了前一轮未完成命名收口中残留的重复语法片段
  - `PhotoFileNameResolver` 标记为 `nonisolated static`，方便 Share / Batch 等非 UI 回调安全复用
  - Share intake 的原始文件名解析改为静态纯函数调用，避免隐式捕获 `self`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoFileNameResolverTests` 通过
- 尚未做：
  - 没有继续重构 Main App 全部页面
  - 没有改 Renderer / Export / Metadata / Memory
  - 没有重新安装到真机

## 2026-06-21 Share 成功反馈回退为纯计数文案

- 这一轮没有扩 intake 能力，也没有继续增加新反馈元素。
- 只把刚加上的“成功后显示文件名”撤回，改回更安静的产品表达。

- 当前用户可见变化：
  - 单张成功：
    - 不再显示具体文件名
    - 统一回到计数型提示
  - 多张成功：
    - 仍然只显示接收数量
    - 如果有部分跳过/失败，继续显示计数，不暴露某一个文件名示例

- 这样处理的原因：
  - 对多图分享来说，显示一个文件名并不能帮助用户定位到底哪张后续没保存成功
  - 用户真正判断成功与否的方式，仍然是系统相册里原图旁边是否出现了新的生成结果
  - Share 完成页应该尽量安静，只确认“PhotoMemo 已经接住了多少张”

- 本轮代码收口：
  - `PhotoMemoShareExtensionViewController`
    - 成功文案恢复为纯计数
  - `PhotoMemoShareExtensionImportResult`
    - 不再承载成功反馈用的 file name 列表
  - `PhotoMemoShareExtensionIntakeService`
    - 去掉只服务于成功提示的 file name 回传
  - `PhotoMemoShareWorkflowSummaryTests`
    - 去掉文件名成功文案 formatter 回归测试

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

## 2026-06-21 Share 成功反馈开始显示原始文件名

- 这条尝试后来已被上面的“纯计数文案”收回，保留这里只作为当天迭代历史。

- 这一轮继续保持“小而完整”的节奏，没有继续扩 provenance 模型本身，而是把已经打通的来源信息真正用到用户可见反馈里。

- 本轮新增：
  - `PhotoMemoShareProcessingFeedbackFormatter`

- 本轮实现范围：
  - `PhotoMemoShareExtensionImportResult`
    - 新增 `importedFileNames`
  - `PhotoMemoShareExtensionIntakeService`
    - 返回结果时，把 imported original file names 一起带回
  - `PhotoMemoShareExtensionViewController`
    - 成功状态文案不再只显示张数
    - 现在会优先显示原始文件名
  - `PhotoMemoShareWorkflowSummaryTests`
    - 新增 share success feedback formatter 回归测试

- 当前用户可见变化：
  - 单张成功时：
    - `已接收《IMG_9558.HEIC》。处理完成后会写回系统相册。`
  - 部分成功时：
    - 仍保留总数表达
    - 但会补一个具体文件名示例

- 这一轮的产品价值：
  - provenance 不再只是埋在模型里
  - 用户更容易确认“刚刚分享的那张照片”确实已经被 PhotoMemo 接住了
  - 反馈仍然保持安静，没有暴露技术词

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前仍保留的下一步：
  1. 是否把 file name 也用于 share 失败反馈
  2. 是否在确认页单张预览文案里显示具体文件名
  3. 是否把 provenance 进一步接入后续 save-back 成功提示或历史记录摘要

## 2026-06-21 share/request/task provenance 继续收口

- 这一轮是在上一刀 `PhotoSourceInfo` 的基础上继续往前推，但仍然保持小切片：
  - 不扩功能
  - 不改 renderer
  - 不改 memory
  - 只把 provenance 从 `SelectedPhoto` 继续接到 intake / request / task

- 本轮新增：
  - `ExternalPhotoIntakeItem`

- 本轮核心变化：
  - `ExternalPhotoIntakeRequest`
    - 现在除了 `urls` 之外，还可以持久化结构化 `items`
    - 新增 `intakePayloads`
  - `BatchTaskIntakePayload`
    - 现在会带：
      - `fileName`
      - `sourceIdentifier`
      - `contentTypeIdentifier`
  - `BatchTask`
    - 现在也继续保留这些字段
  - `PhotoMemoAppRuntime`
    - flush external requests 时，不再只用 URL 重建 payload
    - 现在会优先消费结构化 intake payload
  - `BatchProcessingCoordinator`
    - 批量导入时会把 task provenance 重新组装成 `PhotoSourceInfo`
  - `PhotoMemoShareExtensionIntakeService`
    - share intake 成功后，不再只持久化 managed URLs
    - 现在会一起持久化对应的结构化 intake items

- 这一轮真正解决的问题：
  - share 进来的文件名，不会在 request / task 这层又退化成 managed copy 名称推断
  - batch 状态、后续导入、导出命名，现在可以沿着同一条 provenance 线继续往下传
  - `share -> intake request -> batch task -> import -> export`
    这条链现在已经有了连续的结构化来源信息

- 新增回归保护：
  - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - 锁定 structured intake item 持久化
  - `BatchFixtureCoverageTests`
    - 锁定 payload provenance 会覆盖 temporary URL naming
    - 锁定 batch import 后 `SelectedPhoto.sourceInfo` 仍然保留这些字段

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前仍保留的下一步：
  1. 是否把 provenance 进一步用于 share 失败反馈或调试 UI
  2. 是否给 non-share external intake 也补更完整的 source identifier 策略
  3. 是否继续把最终 save-back 的读回验证也接入这条 provenance 线

## 2026-06-21 导入来源信息切片落地

- 本轮沿着 `MainWorkflowChecklist` 继续往下做了一刀真正有代码价值的收口：
  - 不做大重构
  - 先把“导入来源事实”从零散 URL 语义里抽成一份轻量结构

- 本轮新增：
  - `PhotoSourceInfo`

- 当前挂载位置：
  - `SelectedPhoto.sourceInfo`

- 当前已经保留的来源字段：
  - `originalFileName`
  - `assetLocalIdentifier`
  - `contentTypeIdentifier`

- 本轮实现范围：
  - `SelectedPhoto`
    - 增加 `sourceInfo`
  - `PhotoImportService`
    - 数据导入时写入来源信息
    - URL 导入时补全基础来源信息
  - `PhotoImporterView`
    - 从 `PhotosPickerItem.itemIdentifier` 继续传递 asset identifier
  - `RecordCardExportService`
    - 导出文件命名优先使用 `sourceInfo.originalFileName`
    - 不再只依赖 `sourceURL.lastPathComponent`

- 这一轮解决的核心问题：
  - 原始文件名、资源标识、类型标识不再只是“散落在线索里”
  - 至少在 `SelectedPhoto` 生命周期内，来源事实现在有一份明确、可测试、可继续扩展的结构化承载点
  - 导出命名不再直接绑定临时源路径语义

- 这一轮刻意没有做的事情：
  - 不把 import provenance 强行塞进 `PhotoMetadata`
  - 不动 share intake 存储模型
  - 不做跨系统的大范围 rename

- 新增回归保护：
  - `PhotoImportServiceTests`
    - 锁定 `sourceInfo.originalFileName`
    - 锁定 `sourceInfo.contentTypeIdentifier`
    - 锁定 `sourceInfo.assetLocalIdentifier`
  - `RecordCardBuildServiceTests`
    - 锁定导出命名优先使用 imported original file name

- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

- 当前仍保留的下一步：
  1. share intake / external intake request 是否也需要带结构化 provenance
  2. batch task 层是否要显式消费 `originalFileName` 而不只是 `sourceURL`
  3. 是否要把 provenance 的展示和诊断进一步接到用户可见反馈里

## 2026-06-21 主链路收口标准与开发清单落地

- 本轮没有扩功能，也没有做新的架构抽象。
- 重点是把 `PhotoMemo v0.4 Main Workflow Consolidation` 里真正值得吸收的部分，落成项目内部标准与执行清单。

- 本轮新增文档：
  - `Docs/MainWorkflowConsolidation.md`
  - `Docs/MainWorkflowChecklist.md`

- 当前明确吸收的方向：
  - 建立唯一内部主链路：
    - `Import -> Metadata -> Memory -> Renderer -> Export -> Share`
  - 明确六个阶段的职责边界：
    - Import 负责接入与保留来源事实
    - Metadata 负责规范化后的照片事实
    - Memory 负责时间与记忆语义
    - Renderer 负责最终视觉输出
    - Export 负责结果写出与保存
    - Share 负责轻量分享流程
  - 明确：
    - Renderer 很重要，但不再被当作产品中心
    - Template / Style 与 Renderer 继续解耦
    - Share-first 继续推进，但不做高风险的“一步到位重写”

- 当前明确不做的内容：
  - 不新增抽象 `PhotoWorkflow` 框架
  - 不做大规模目录重组
  - 不做全仓库 rename sweep
  - 不强行要求当前所有执行立即迁移到 Share Extension 内

- 这一轮最关键的工程判断：
  - 当前代码里，真正还需要继续收口的，不是再加一层架构，而是：
    1. import 来源事实的一致性
       - original filename
       - asset identifier
       - source type / UTI
    2. share happy path 的稳定性
    3. renderer 不再承载业务语义漂移

- 文档同步：
  - `README.md`
  - `Docs/ProductDirection.md`
  - `Docs/CURRENT_STATUS.md`
  - `HANDOFF.md`
  - 现在已经统一到同一套说法：
    - `Import -> Metadata -> Memory -> Renderer -> Export -> Share`

Build verification for this slice:

- `PhotoMemo` build passed
- `PhotoMemoiOS` build passed
- `PhotoMemoShareExtension` build passed

本轮没有改 Swift 源码，所以没有重复跑 `PhotoMemoTests`。

## 2026-06-21 Share 唤起闭环、原名导入收口、默认渲染切到 Immers White

- 本轮先把“文件名被临时导入路径污染”这条链彻底收口：
  - `PhotoImportService`
    - `PhotosPicker` 的临时导入现在改成：
      - 共享根目录
      - 每次导入一个独立 UUID 子目录
      - 子目录内保留原始文件名
    - 这样连续两次导入同名照片时，不会再把 `SelectedPhoto.sourceURL` 变成：
      - `IMG_7065 (1).JPEG`
  - 同时保留了你要的扩展名观感：
    - 显式给定 `IMG_9558.HEIC`
    - 现在会继续保留 `.HEIC`
  - `Photo Library` 这个占位名仍会回退到：
    - `PhotoMemo Import.jpg`
- 本轮补充了主程序导入命名的回归保护：
  - `Tests/PhotoMemoTests/ExportTests/PhotoImportServiceTests.swift`
  - 新增覆盖：
    - 显式文件名保留
    - `Photo Library` 占位名回退
    - 重复导入同名照片时，文件名仍保持原样

- Share Extension 这一轮不做大流程改造，只补最小闭环：
  - 新增：
    - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoDeepLink.swift`
  - `PhotoMemoiOS` 新增 URL scheme：
    - `photomemo://share`
  - `PhotoMemoRootSceneView`
    - 现在会识别 `photomemo://share`
    - 收到后直接执行：
      - `runtime.refreshExternalIntakeState()`
  - `PhotoMemoShareExtensionViewController`
    - share intake 成功后会先尝试：
      - `extensionContext.open(photomemo://share)`
    - 再关闭分享页
  - 这样当前行为从：
    - “写进共享收件箱后直接关闭，主 App 不一定立刻处理”
    变成：
    - “写进共享收件箱后主动唤起主 App 刷新 intake，并继续生成/保存”
  - 这一轮仍然不是“完全在扩展里渲染保存”，但已经把当前真实断点补上了

- 默认渲染路径也收了一刀：
  - 之前当前主链默认还是：
    - `template1 -> ClassicWhiteRenderer`
  - 这正是你说“成片和目标样图差距很大”的核心原因之一
  - 现在新增统一渲染布局判定：
    - `TemplatePreset.renderLayout`
  - 当前映射：
    - `template1` -> `immersWhite`
    - `immersWhite` -> `immersWhite`
    - `template2 / template3` -> `classicWhite`
  - `RecordCardRenderer`
    - 预览已改用这套统一映射
  - `RecordCardExportService.outputPixelSize(...)`
    - 导出尺寸也改用同一映射
  - 这样至少保证：
    - 预览路径
    - 导出路径
    - 白栏比例
    - Immers 风格几何
    已经走到同一个分支

- Immers 风格本轮只做了一处非常保守的样图贴近：
  - `ImmersWhiteRenderer.infoBarColor`
    - 从纯白改成偏暖白：
      - `#F4F4F2`
  - 这一轮没有继续大动：
    - 字号
    - 分隔线宽度
    - 徽标几何
  - 因为先把“走错 renderer”这个更大的问题纠正掉更重要

- 本轮新增测试：
  - `Tests/PhotoMemoTests/RendererTests/TemplatePresetRenderLayoutTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/PhotoMemoDeepLinkTests.swift`

- 本轮验证结果：
  - 定向测试通过：
    - `PhotoImportServiceTests`
    - `ExternalPhotoIntakeStoreDiagnosticsTests`
    - `TemplatePresetRenderLayoutTests`
    - `PhotoMemoDeepLinkTests`
  - 全量测试通过：
    - `PhotoMemoTests`
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`

- 本轮仍需你真机继续确认的重点：
  1. 系统相册分享后，是否会真正自动切回 PhotoMemo 并开始处理
  2. 处理完成后，是否已经不再出现：
     - `Photo Library.JPG`
     - `Photo Library (1).JPG`
  3. 当前默认成片在横图 / 竖图下，是否已经明显更接近你持续提供的 Immers 样图
  4. Share 页在某些来源 App 中，`extensionContext.open(...)` 是否会被系统限制；如果被限制，下一轮需要进一步决定是：
     - 做更明确的“返回 PhotoMemo 完成保存”反馈
     - 还是继续推进扩展内单张 happy-path 处理

## 2026-06-21 Photo Library 原名回写修复、白栏颜色与分隔线微调

- 本轮确认并修复了一个真实的 Photo Library 命名问题：
  - 本地导出文件名原本已经符合系统复制规则：
    - `原文件名.jpg`
    - `原文件名 (1).jpg`
    - `原文件名 (2).jpg`
  - 但写回系统相册后，资产原始文件名没有沿用导出文件名，导致测试结果出现：
    - `Photo Library.JPG`
    - `Photo Library 2.JPG`
- 当前修复位置：
  - `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
  - 在 `saveImageResult(...)` 里补充：
    - `PHAssetResourceCreationOptions.originalFilename`
  - 新增：
    - `assetOriginalFilename(for:)`
  - 当前逻辑：
    - 默认使用导出文件的 `lastPathComponent`
    - 自动保留 ` (1)` / ` (2)` 这种系统复制后缀
    - 仅在文件名为空时回退到 `PhotoMemo.jpg`
- 本轮测试补强：
  - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - 新增覆盖：
    - `usesExportedFileNameAsPhotoLibraryOriginalFilename()`
- 本轮渲染微调：
  - `ClassicWhiteRenderer.swift`
  - 继续按你提供的样图靠拢，只做小幅视觉回收：
    - 白栏底色改成偏暖的 `#F4F4F2`
    - 顶部主文字改深
    - 参数与次级文字颜色重新贴近样图层次
    - 分隔线改成更浅的显式灰色，并从 `1px` 提到 `2px`
    - `badge -> divider -> right text` 间距再收一轮
    - badge 与 divider 高度做了轻微缩短
- 本轮验证：
  - 定向测试通过：
    - `PhotoMemoTests/RecordCardBuildServiceTests`
  - 构建通过：
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
- 当前仍需人工核查：
  1. 真机系统相册写回后，文件名是否已经稳定沿用原图名与复制后缀
  2. 当前白栏暖灰底与分隔线粗细，是否已经更接近你提供的成品样图
  3. 顶层文字与次级文字的层级是否还需要继续按样图做最后一轮微调

## 2026-06-21 导出命名规则确认、Immers 样图校准一轮、徽标资源补充

- 本轮确认：
  - 导出图片命名规则当前已经是系统复制文件风格：
    - `原文件名.jpg`
    - `原文件名 (1).jpg`
    - `原文件名 (2).jpg`
  - 当前实现位置：
    - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
  - 当前命名测试也已锁住：
    - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - 本轮没有再改命名逻辑，因为代码与测试已经符合要求，不再追加 `_PhotoMemo`

- 本轮补充：
  - 新增 4 个内置喜庆徽标资源：
    - `喜爱`
    - `囍`
    - `新生`
    - `福`
  - 相关文件：
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-love.imageset`
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-wedding.imageset`
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-birth.imageset`
    - `Source/PhotoMemo/PhotoMemo/Assets.xcassets/badge-fu.imageset`
  - 徽标库与选择器已同步接入：
    - `BadgeLibrary.swift`
    - `BadgeRenderer.swift`
    - `BadgePickerView.swift`
    - `MainView+LayoutSections.swift`

- 本轮渲染校准：
  - 已结合你提供的成品样图和 Immers `areas_light` 官方公开样片，对 `ClassicWhiteRenderer` 做了一轮更接近样图的参数回收
  - 重点只动：
    - 白栏高度比例
    - 左右区宽度
    - 上下两层字号比例
    - `badge -> divider -> right text` 间距关系
  - 当前改动文件：
    - `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift`
    - `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
  - 这一轮还不是最终锁死版本，后续仍需要继续按真机成片对着样图微调

- Share intake：
  - `PhotoMemoShareExtensionIntakeService.swift` 继续保留并补强了 intake 诊断与失败阶段暴露
  - `ExternalPhotoIntakeStoreDiagnosticsTests.swift` 已同步覆盖相关诊断路径

- 本轮验证：
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoTests` 定向 `RecordCardBuildServiceTests` 通过
    - 已明确验证命名规则测试：
      - `keepsOriginalBaseFilenameAndAppendsCopySuffixesForRepeatedExports()`

- 当前仍需继续人工核查：
  1. 真机导出结果与参考样图的底栏节奏是否已经足够接近
  2. Share Extension 真机分享失败是否已因前一轮 intake 修复而消失
  3. 新增徽标在横图、竖图和不同白栏高度下的视觉平衡

## 2026-06-20 Product Convergence 一轮完整收口

- 本轮目标：
  - 按 `North Star` 和 `Product Convergence` 规范，把主界面、Share 文案和 `Personal Profile / Style` 边界继续收紧
  - 不扩能力
  - 不动渲染、导出、Memory Engine、Metadata Pipeline
- 本轮主界面变化：
  - iPhone 顶层信息架构现在收成：
    - `我的记录`
    - `默认风格`
    - `输出设置`
    - `设置`
    - `关于`
  - `预览` 不再在 iPhone 顶层单独占一块
  - 预览现在回到 `默认风格` 内作为校准内容的一部分
  - macOS 仍保留右侧预览 detail，继续承担单张校准面
- 本轮术语收口：
  - `识别数据` -> `照片信息`
  - `智能数据` -> `记忆信息`
  - 多处 `时间点` -> `记忆日期`
  - Share 确认页 `当前设置` -> `这次会如何处理`
  - Share 确认页 `当前风格` -> `默认风格`
  - Share / intake 错误提示里的 `当前风格` 也统一改成 `默认风格`
- 本轮 Share 变化：
  - 确认页继续保持单页
  - 核心表达现在更接近：
    - 分享了几张
    - 默认风格
    - 结果去向
    - 接下来会发生什么
  - 单张预览说明改成：
    - `将按当前默认风格处理这张照片`
  - 处理中和失败后的反馈文案继续弱化技术感
- 本轮 `Personal Profile / Style` 边界变化：
  - `PersonalProfileStore` 新增：
    - `updateDefaultStyleIdentifier(_:)`
    - `updateSaveDestination(...)`
  - 切换默认风格时，会同步回写 `Personal Profile`
  - 切换保存相册时，也会同步回写 `Personal Profile`
  - 这样 Share 和 Main App 现在更明确地共用同一份长期资料来源
- 本轮风格保存边界：
  - `saveCurrentConfiguration()` 不再先把当前相册 / 记忆日期直接当成风格持久化来源
  - `applyWorkspaceConfigurationSnapshot(...)` 现在只回放风格相关内容：
    - template
    - badge
    - description-writing settings
  - 不再在切换风格时顺手改掉当前选中的记忆日期和相册去向
  - 这让 `Style = presentation-first` 又向前走了一步
- 本轮新增/更新测试：
  - `PhotoMemoShareWorkflowSummaryTests`
    - 从 `anchorTitle` 迁到 `memoryDateTitle`
    - 校验新的 Share 文案输出
  - `PersonalProfileStoreTests`
    - 覆盖默认风格回写
    - 覆盖保存位置回写
- 本轮验证：
  - 定向测试通过：
    - `PersonalProfileStoreTests`
    - `PhotoMemoShareWorkflowSummaryTests`
  - 全量测试通过：
    - `PhotoMemoTests`
  - 本轮我明确拿到：
    - `PhotoMemoTests` `TEST SUCCEEDED`
  - `PhotoMemo` / `PhotoMemoiOS` / `PhotoMemoShareExtension`
    - 构建命令已真实执行
    - 当前会话里没有完整保留三个命令各自的干净尾行
    - 但本轮修改涉及的主 app / share 文件已经被测试编译链真实覆盖
- 本轮仍保留的产品债务：
  1. `默认风格` 内部虽然已经更像设置，但 `进一步调整` 里仍有不少低频项，后续还值得继续往二级层级下沉。
  2. First Run 目前仍是 5 步，和最新 North Star 的“显式完成页”不完全一致；这是一次 deliberate simplification，但之后要不要补回安静的完成态，还需要产品判断。
  3. Share 已经更像用户确认页，但距离真正的 `Share -> Generate -> Save -> Done` 无感体验还有最后一段手感打磨。

## 2026-06-20 Main App 继续减法，First Run 再缩一轮

- 本轮目标：
  - 不加新能力
  - 继续遵守 `Main App is not the primary workflow`
  - 把主 App 再往“安静的配置中心”收
  - 把首次引导再往“一次性系统设置”收
- 本轮主界面变化：
  - macOS 右侧详情区不再重复显示一份 `默认风格`
  - 右侧重新只承担：
    - 选图
    - 预览
  - iPhone 顶层继续减法，默认主链现在更接近：
    - 我的记录
    - 默认风格
    - 输出
    - 预览
  - `设置` 只有在权限尚未就绪时才出现
  - `关于` 不再占首页顶层主块
- 本轮风格区变化：
  - `默认风格` 仍保留当前风格位切换、重命名、保存和恢复
  - 时间点 / 个性化区域 / 补充信息 / Logo 标识 被后置到：
    - `进一步调整`
  - 这意味着默认进入时先看到高频主项，低频调节不再一开始全部铺开
- 本轮首次引导变化：
  - 去掉独立 `完成页`
  - 最后一步 `保存位置` 直接完成并进入主界面
  - 当前 First Run 收成：
    1. 欢迎
    2. 记录身份
    3. 宝宝昵称
    4. 出生日期
    5. 保存位置
- 当前判断：
  - 这轮是实打实的复杂度下降，不是换地方加内容
  - 但 `默认风格` 内部仍然偏重，只是已经先后置了一批低频项
  - 下一轮如果继续这条线，最值得优先做的是：
    1. 决定哪些 `进一步调整` 项应继续留在主界面，哪些应真正迁往设置层
    2. 对 Share Extension 做同样级别的“默认更安静”减法
    3. 做真机手感核查，看这一轮首页是否已经更像 Apple Settings
- 本轮验证结果：
  - `PhotoMemoiOS` build 通过
    - 该次编译已真实覆盖 `PhotoMemoShareExtension`
  - `PhotoMemoTests` 通过
  - `PhotoMemo` 本轮单独补跑时遇到本机 `CoreSimulatorService` 异常噪音，未拿到干净尾行
  - `PhotoMemoShareExtension` 本轮单独补跑时同样遇到本机 `CoreSimulatorService` 异常噪音，未单独保留 `BUILD SUCCEEDED`
  - 但这两者本轮改动都已被 `PhotoMemoiOS` 全量编译链覆盖

## 2026-06-20 Share Extension intake diagnostics 已接通

- 本轮目标：
  - 不修分享失败根因
  - 只把 Share confirmation -> intake 这一段的诊断能力补齐
  - 下次真机失败时直接知道卡在哪一层
- 本轮核心新增：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareIntakeDiagnostics.swift`
  - Share intake 统一失败阶段：
    - `load`
    - `copy`
    - `persist`
    - `serialization`
    - `completion`
  - 统一 `NSError` 摘要：
    - `localizedDescription`
    - `domain`
    - `code`
    - `underlyingError`
- 本轮主要代码变化：
  - `ExternalPhotoIntakeStore`
    - 新增 detailed copy / persist 结果
    - 不再只返回 `nil`
    - 现在能给出 shared container 目标路径和失败上下文
  - `PhotoMemoShareExtensionImportResult`
    - 新增 provider 总数 / supported 数 / failure stage / failure context
  - `PhotoMemoShareExtensionIntakeService`
    - 现在会记录：
      - extension 收到的 item providers 数量
      - supported provider 数量
      - 选中的 `UTType.image` 与 provider 的首选图片类型
      - `loadFileRepresentation` 起止与返回 URL
      - `loadItem` fallback 起止与返回 URL/Data
      - temporary copy 结果
      - shared container destination
      - persist request 结果
      - final import result 值
  - `PhotoMemoShareExtensionViewController`
    - 失败页现在会带上简短诊断摘要：
      - `失败阶段`
      - `NSError domain / code`
- 本轮新增测试：
  - `Tests/PhotoMemoTests/BatchTests/PhotoMemoShareIntakeDiagnosticsTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/ExternalPhotoIntakeStoreDiagnosticsTests.swift`
- 本轮验证：
  - 定向 `PhotoMemoShareIntakeDiagnosticsTests` 通过
  - 定向 `ExternalPhotoIntakeStoreDiagnosticsTests` 通过
  - `PhotoMemoiOS` build 通过
    - 编译链已经覆盖 `PhotoMemoShareExtension`
- 当前对你提供的两张截图的判断：
  - 分享确认页本身是正常的
  - 旧问题还没算解决，因为失败页仍然还是泛化高层文案
  - 本轮完成后，下一次同样失败时，理论上应该能直接看到：
    - `失败阶段：copy`
    - 或 `失败阶段：persist`
    - 并带 `NSError domain / code`
- 下一轮最值得继续：
  1. 让你在真机上重新走一遍：
     - 系统相册 -> 分享 -> PhotoMemo -> 按当前风格继续
  2. 拿新的失败截图或系统日志
  3. 按已经暴露出来的具体阶段直接修根因，不再泛查
  4. 如果卡在 shared container copy，再重点核对 security-scoped URL / provider payload 类型
  5. 如果卡在 persist，再重点核对 request 序列化和共享容器写入
  6. 如果已经成功进入 `persist`，再看是不是后续 render/save 才失败

## 2026-06-20 默认个性化文案、关系称呼注入与原名导出已落地

- 本轮目标：
  - 继续顺着 `Personal Profile + 默认风格` 收口模板 1 的默认语言
  - 让记录者身份真正进入最终成片文案
  - 导出文件名恢复原图命名，不再追加 `_PhotoMemo`
- 本轮实际改动：
  - 新增 `MetadataContext.Key.relationshipLabel`
  - 新增公开模板变量：
    - `记录者称呼`
  - 公开变量里原 `时间点名称` 已收口成：
    - `主角称呼`
  - 模板默认值更新为：
    - 左上：`{{relationship_label}}手持{{model}}记录`
    - 左下：`拍摄于{{capture_date_display}}`
    - 右下：`{{anchor_title}}今天{{anchor_age_text}}啦`
  - `Template.normalizedForEditing` 现在会兼容迁移旧默认文案：
    - `{{title}}` -> 新左上默认句式
    - `记录于...` -> `拍摄于...`
    - `今天{{anchor_age_text}}` -> `{{anchor_title}}今天{{anchor_age_text}}啦`
- 本轮运行时补充：
  - `RecordCardBuildService` 现在会从共享 `UserDefaults` 中读取 `photomemo.personalProfile`
  - 若存在有效 `PersonalProfile`，会把 `resolvedRelationshipLabel` 注入 `MetadataContext`
  - 这样默认左上角已经可以直接得到：
    - `他爹手持iPhone 15 Pro记录`
    - `爸爸手持Canon记录`
- 本轮导出命名变化：
  - 默认导出名改为沿用原图名
  - 重名时按复制规则递增：
    - `IMG_1234.jpg`
    - `IMG_1234 (1).jpg`
    - `IMG_1234 (2).jpg`
- 本轮新增测试：
  - `Tests/PhotoMemoTests/VariableTests/EditorProjectionEngineTests.swift`
    - 覆盖文字 + 模块 chip 的 round-trip
    - 覆盖前置文字删除后，后续 chip 不应损坏
  - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
    - 覆盖 Personal Profile 记录者称呼注入
    - 覆盖默认成片语义与原名导出递增规则
- 本轮验证结果：
  - 定向 `RecordCardBuildServiceTests` 通过
  - 定向 `EditorProjectionEngineTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
    - 此次成功编译已包含 Share Extension / Widget Extension 依赖
- 本轮需要诚实保留的边界：
  - 独立 `PhotoMemoShareExtension` scheme 单跑时，当前工程仍会拉起完整 iOS 依赖图
  - 那条命令为了节省时间被中断，没有单独保留 `BUILD SUCCEEDED`
  - 但共享文件已经在 `PhotoMemoiOS` 全量编译里真实通过
- 本轮还没完全收口的问题：
  - EXIF 参数摘要模块重新插入和删除边界，仍要继续盯
  - 用户提到的异常拼接：
    - `途途1岁24天）〕啦`
    - 还没有拿到稳定复现场景
  - 分享失败提示图还没收到，本轮未分析
  - `/Users/rui/Downloads/IMG_9565.HEIC` 本轮读取时本地未找到，需要你后续再补
- 下一轮最值得继续：
  1. 先复现并修正右下区域异常拼接
  2. 把 EXIF 参数摘要模块做成更稳定的可重插入 chip
  3. 拿到分享失败提示图后，直接排查 Share 保存失败链路

## 2026-06-20 First Run Wizard 与 Personal Profile 基础切片已落地

- 本轮目标：
  - 不做大规模架构迁移
  - 直接落一个真实可用的 `Personal Profile + First Run Wizard` 最小代码切片
  - 保持现有渲染、导出、Share 主链不变
- 本轮新增代码：
  - `Source/PhotoMemo/PhotoMemo/Models/PersonalProfile.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/PersonalProfileStore.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/FirstRun/FirstRunWizardView.swift`
  - `Tests/PhotoMemoTests/MetadataTests/PersonalProfileStoreTests.swift`
- 本轮接入方式：
  - `PhotoMemoRootSceneView` 现在会先判断 `requiresFirstRun`
  - 未完成首次初始化时，先进入 5 步向导
  - 完成后再进入现有 `MainView`
- 向导当前 5 步：
  1. 这是为谁记录
  2. 宝宝叫什么
  3. 出生日期
  4. 默认风格
  5. 保存位置
- 本轮在 UI 表达上又进一步收紧了一次：
  - 欢迎语改成更像系统首次设置的语气
  - 步骤标签收口成 `1 / 5` 这种更轻的表达
  - 完成页保留，但不再像信息面板，更接近安静的收尾确认
- 本轮兼容策略：
  - `PersonalProfileStore` 会从现有 `SettingsService` 回填：
    - 生日 anchor
    - 当前样式槽位
    - 当前默认相册
  - 完成向导后，再把结果写回现有 settings 路径
  - 这样旧的 `UserDefaults`、Share、导出、Batch 都不用迁移
- 本轮顺手补齐：
  - 默认保存位置现在支持明确区分：
    - `系统相册`
    - `photomemo 相册`
  - Share 摘要、主界面输出摘要、保存反馈文案都已同步识别 `系统相册`
- 本轮 target 边界修正：
  - 由于工程会把新文件自动带进 extension target
  - `PersonalProfileStore.swift`
  - `FirstRunWizardView.swift`
  - 已用 `#if !PHOTOMEMO_SHARE_EXTENSION` 收口，避免污染 Share Extension 编译边界
- 本轮验证：
  - `PhotoMemoTests` 通过
  - 定向 `PersonalProfileStoreTests` / `PhotoMemoShareWorkflowSummaryTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮还没做：
  - `Personal Profile` 的独立编辑入口
  - Main App IA 真正改成：
    - Personal Profile
    - Styles
    - Settings
    - About
  - 首次完成后的“设置完成页”之外的后续信息架构收口
  - 真机手感验证
- 下一轮最值得继续：
  1. 给 `Personal Profile` 一个正式入口，而不是只存在于 First Run
  2. 开始把主界面上属于“人”的设置从 style/configuration 里继续剥离
  3. 让 Share 更明确读取 `Profile + Default Style`，继续向真正的 share-first 靠拢

## 2026-06-20 v1.0 产品模型基线已定义

- 本轮目标：
  - 不做大 UI 改造
  - 先定义 PhotoMemo 的长期产品模型
  - 把未来所有功能都收敛到 `Personal Profile -> Style -> Workflow`
- 本轮新增文档：
  - `Docs/ProductModel.md`
- 本轮同步更新：
  - `Docs/ProductDirection.md`
  - `Docs/ProductBacklog.md`
  - `Docs/CURRENT_STATUS.md`
  - `README.md`
- 本轮核心结论：
  - Main App 不是日常处理面，而是工作流准备面
  - Share Extension 不是技术交接面，而是未来主执行面
  - `Personal Profile` 负责：
    - relationship
    - baby nickname
    - birthday
    - default album
    - default style
  - `Style` 负责：
    - layout
    - variables
    - visual arrangement
    - bottom-card composition
    - renderer-facing behavior
  - `Workflow` 负责：
    - Apple Photos -> Share -> Generate -> Save
    - 运行时处理状态
    - 结果写回
- 本轮对当前仓库边界的判断：
  - `selectedTemplate` / `selectedBadge` / `configurationSlots` 已经接近 Style
  - `selectedAlbumIdentifier` / `selectedAlbumTitle` 应迁到 Personal Profile
  - 当前 `anchors` / `selectedAnchorID` 仍混合了身份信息与执行语义，后续应拆成：
    - profile-owned birthday / memory dates
    - style or workflow-owned reference choice
  - Share Extension 后续应只读取：
    - Personal Profile
    - default Style
- 本轮产品术语方向：
  - `Configuration` -> `Style`
  - `Configuration Slot` -> `Saved Style`
  - `Anchor` -> `Birthday` / `Memory Date`
  - 继续减少 `workspace / snapshot / batch` 这类实现词汇的外显
- 推荐实现顺序：
  1. 新增 `PersonalProfile` 数据模型
  2. 从现有 settings 做兼容性回填
  3. 上一次性 First Run
  4. 主界面 IA 收口到：
     - Personal Profile
     - Styles
     - Settings
     - About
  5. Share 默认直接执行 `Profile + Style -> Generate -> Save`
- 兼容性结论：
  - 本轮不需要破坏现有 `UserDefaults`
  - 不需要迁移 renderer / export / metadata pipeline
  - 不需要更新 ADR，因为还没有进入已实现的架构边界调整
- 本轮验证：
  - 文档改动，无需构建
- 下一轮最值得继续：
  - 开始设计 `PersonalProfile` 的最小可落地数据结构
  - 评估如何从当前 `SettingsService` 无损回填
  - 再进入 First Run 的最小实现切片

## 2026-06-20 首次权限窗与预览/补充信息收口

- 本轮目标：
  - 优化首次权限引导弹窗的视觉表现
  - 继续收紧 iPhone 预览/编辑页里的低价值入口
  - 恢复补充信息勾选逻辑
  - 修正补充信息中文导出时的 EXIF `UserComment` 稳定性
- 本轮主界面与 iPhone 变化：
  - `MainPermissionSetupSheet` 改成更接近系统卡片式的居中权限引导，不再左右拉满
  - iOS 预览导入区移除了 `从文件导入`，只保留系统照片选择
  - 预览侧 `Live Context` 模块已移除，页面更紧凑
  - 输出区改成更直接的 `保存至` + 相册选择表达，并补充：
    - 未指定时默认保存到 `PhotoMemo` 相册
  - 原先的 `写入位置 ...` 说明块已删除
  - 编辑页移除了 `风格` 分组，继续把主界面收敛成配置中心
  - 四个个性化区域输入高度继续压缩，和模块插入态更接近
  - `补充信息` 恢复为：
    - 勾选时输入自定义补充内容
    - 不勾选时自动回退到右下区域最终生成内容
  - 自定义补充输入框聚焦时会主动清掉其他编辑焦点，减少光标跳去别的窗口的问题
- 本轮导出稳定性修正：
  - `RecordCardBuildService` 已按最新产品语义保留：
    - 自定义补充关闭时，导出说明回退到右下区域完整结果
    - 自定义补充开启且有内容时，优先写入用户自定义内容
  - `RecordCardExportService` 新增 JPEG EXIF `UserComment` 的 Unicode patch：
    - 修正 `ImageIO` 直接写中文时出现截断/空字符异常的问题
    - 现在 fixture 回归里的中文说明写入已经恢复稳定
- 涉及文件：
  - `Source/PhotoMemo/PhotoMemo/Views/Main/PhotoImporterView.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+PreviewPanels.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Permissions.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+TemplatePanels.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerEditor.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
  - `Tests/PhotoMemoTests/ExportTests/RecordCardBuildServiceTests.swift`
  - `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮仍未人工验证：
  - 真机上首次权限弹窗的新视觉比例和手感
  - iPhone 上补充信息勾选开关切换时，输入焦点是否已经完全稳定
  - 真实保存到系统相册后，外部查看工具对中文 `UserComment` 的兼容表现
  - 预览页新的 `保存至` 文案在 17 Pro Max 上的排版读感

## 2026-06-20 相册入口去重与 Share 相册去向同步修正

- 本轮目标：
  - iPhone 主界面只保留预览页里的相册写入入口
  - 修正 Share 确认页没有读取到最新目标相册的问题
- 本轮修正：
  - iPhone 紧凑布局下，`编辑` 页不再重复显示 `输出` 卡片
  - 主 App 现在会把当前选中的相册标识和相册名称一起立即写入共享 `UserDefaults`
  - Share 确认页的 `结果去向` 会优先显示真实相册名，例如 `存入“家庭相册”`
  - 相册列表刷新后，也会把当前选中相册的最新标题重新同步回共享配置
- 新增测试：
  - `PhotoMemoShareWorkflowSummaryTests`
    - 覆盖自定义相册名称展示与 generic fallback
  - `SettingsServiceTests`
    - 覆盖相册标识与相册名称的持久化
- 涉及文件：
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+WorkspaceConfigurationState.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+DerivedState.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`
  - `Source/PhotoMemo/PhotoMemo/Services/SettingsService.swift`
  - `Source/PhotoMemo/PhotoMemo/App/BatchConfigurationSnapshotProvider.swift`
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
  - `Tests/PhotoMemoTests/MetadataTests/SettingsServiceTests.swift`
  - `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮仍未人工验证：
  - 真机上重新选择目标相册后，立即从系统相册分享，确认页是否稳定显示最新相册名
  - 真实分享链路里写回目标相册是否已完全消除之前那次报错

## 2026-06-20 iPhone 全屏与时间点 sheet 修正

- 本轮目标：
  - 检查 iPhone 17 Pro Max 上主界面上下黑边
  - 核对时间锚点界面的时间设定入口
- 本轮修正：
  - `PhotoMemoiOS` target 已补齐：
    - `LaunchScreen`
    - iPhone / iPad 支持方向键
  - 已确认 `PhotoMemoiOS.app` 包内存在：
    - `LaunchScreen.storyboardc`
  - 时间点管理和时间点编辑 sheet 现在在 iPhone 上不再沿用 macOS 的固定最小尺寸
  - 时间选择文案从 `锚点时间` 调整为更明确的 `设定时间`
  - iPhone 上时间选择器改为更接近按钮入口的 compact 样式
- 涉及文件：
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`
  - `Source/PhotoMemo/PhotoMemo/iOS/App/LaunchScreen.storyboard`
  - `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Anchor/AnchorListView.swift`
  - `Source/PhotoMemo/PhotoMemo/Views/Anchor/AnchorEditorView.swift`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoTests` 通过
- 本轮仍未完成：
  - 还没有直接看到你真机 17 Pro Max 上修正后的实际画面
  - 如果你重装后仍有黑边，就需要继续排查是否是设备安装态或系统兼容模式缓存问题

## 2026-06-20 Alpha 0.8 产品减法切片已落地

- 本轮目标：
  - 不加新功能
  - 不改架构
  - 只做默认流程减法、术语收口和界面降噪
- 本轮新增：
  - `Docs/ProductScore.md`
- 本轮主界面变化：
  - 去掉了默认编辑流里的多张说明卡片：
    - 个性化区域说明
    - 补充信息说明
    - 输出说明
    - 智能模块说明
  - Anchor 列表移除了重复的 `设为当前`
  - Anchor 编辑页只保留核心输入，不再堆长段教学文字
  - 权限区文案改成更短的“为什么需要权限”
  - 默认主界面不再强调顶部 hero pills
- 本轮术语收口：
  - `配置工作区` -> `默认风格`
  - `当前配置` -> `当前风格`
  - 多处 `模板` 可见文案 -> `风格`
  - 多处 `EXIF` 可见文案 -> `照片信息 / 拍摄时间`
- iPhone / Share 变化：
  - 后台状态页只保留：
    - 当前处理
    - 失败重试
    - 最近失败
  - Share 页与相关失败提示改成 `当前风格` 语言，不再强调技术配置感
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoTests` 通过
- 本轮还没手动验证：
  - 真机上主界面减掉说明卡后，第一次使用是否仍足够敢点
  - 真机 share sheet 中 `当前风格` 的读感
  - 精简后的后台状态页是否覆盖了最关键异常场景
- 下一轮最值得继续：
  - 继续沿 Share-first 主链推进
  - 优先补单张预览 / 生成保存反馈闭环
  - 继续把低频说明和管理动作从默认路径拿走

## 2026-06-20 Product audit completed

- 本轮目标：
  - 不改代码
  - 只做产品审查
  - 回答每个可见页面里的 UI 元素是否真的有必要继续留在主流程里
- 本轮新增：
  - `Docs/ProductAudit.md`
- 本轮同步更新：
  - `Docs/ProductDirection.md`
- 新写入的核心产品原则：
  - `The best PhotoMemo experience is the one users barely notice.`
  - `PhotoMemo 最好的体验，是用户几乎感觉不到它的存在。`
- 这轮审查后的高确定性结论：
  - 主 App 仍然有过多解释性 UI
  - Share Extension 还应继续朝“几乎无感”的执行流收缩
  - 帮助中心、重命名、Logo、自定义说明、后台状态等低频内容应继续下沉
  - 时间点编辑页和后台状态页里仍有一批可以直接删减的说明与次级动作
- 本轮验证：
  - 文档改动，无需构建
- 下一轮最适合承接：
  - 按 `Docs/ProductAudit.md` 的高确定性结论，挑一个最小 UI 切片继续减法
  - 优先从主界面解释性卡片、Anchor list 重复动作、Share 页过长说明做起

## 2026-06-20 Alpha 0.7 Share Alpha-01 单页确认面已落地

- 本轮目标：
  - 只做 Share Alpha-01
  - 解决“看得懂、敢点、知道结果”
  - 不进入完整生成保存
- 本轮核心变化：
  - `PhotoMemoShareExtensionViewController` 不再一打开就自动继续
  - 现在会先展示：
    - 分享了几张图
    - 当前配置名称
    - 结果去向
  - 主按钮改成明确确认动作：
    - `按当前配置继续`
  - 成功文案不再是“已加入收件箱”
  - 失败态现在会给出更可执行的重试建议
- 这轮刻意没做：
  - 单张预览
  - 生成 -> 保存闭环
  - 批量 share
  - 自动配置识别
  - 多页面 wizard
- 当前真实边界：
  - 这还是 share -> intake -> app-side continue 的链路
  - 只是入口产品表达已经从“技术交接面”变成“单页确认面”
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemo` build 通过
- 本轮文档同步：
  - `Docs/Alpha/BugList.md`
  - `Docs/Alpha/UXNotes.md`
  - `Docs/CURRENT_STATUS.md`
- 下一轮最值得继续：
  - Share 单张预览
  - 然后才进入单张图 happy path 的最短主链雏形
  - 继续避免过早扩到批量/智能识别/复杂恢复

## 2026-06-20 Alpha 0.7 zero-friction share baseline landed

- 本轮目标：
  - 先重设计 Share-first 主链
  - 不直接做“大确认页”
  - 让默认分享路径尽量零摩擦
- 本轮新增：
  - `Docs/ShareZeroFrictionWorkflow.md`
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoShareWorkflowSummary.swift`
  - `Tests/PhotoMemoTests/VariableTests/PhotoMemoShareWorkflowSummaryTests.swift`
- 产品层共识已进一步收口：
  - 默认路径是：
    - `Share -> PhotoMemo -> 使用当前配置 -> 继续处理 -> 写回系统相册`
  - 配置属于主 App，不属于日常分享时刻
  - 高级设置以后可以有，但不能打断默认路径
- Share Extension 本轮已做的最小实现切片：
  - 从“正在交给 PhotoMemo 处理”改成更接近自动处理入口的表达
  - 被动展示：
    - 当前配置
    - 当前时间点
    - 当前输出方式
  - 成功文案不再只强调“进入收件箱”，而是强调：
    - 已接收
    - 会按当前配置继续处理
- 这轮刻意没做：
  - 预览页
  - 配置切换
  - 高级设置展开
  - 真正的 extension 内生成并保存
- 当前真实边界：
  - 这还是 intake-backed 的分享主链，不是假装已经完成了全部处理
  - 但产品表述和默认心智已经从“技术交接面”转向“自动处理入口”
- 本轮验证：
  - `PhotoMemoTests` 通过
  - `PhotoMemoShareExtension` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemo` build 通过
- 下一轮最值得继续：
  - 真机检查 share sheet 的实际停留时长和读感
  - 决定下一步是先做轻量预览，还是先增强完成反馈
  - 继续坚持“高级设置不打断默认路径”

## 2026-06-20 Alpha 0.7 validation rhythm established

- 本轮目标：
  - 不继续扩展功能
  - 把 PhotoMemo 正式切到“真实产品验证”节奏
- 本轮新增文档：
  - `Docs/Alpha/Alpha01.md`
  - `Docs/Alpha/BugList.md`
  - `Docs/Alpha/UXNotes.md`
  - `Docs/Alpha/KnownIssues.md`
- 本轮统一后的开发模式：
  - 发现一个体验问题
  - 判断是不是产品问题
  - 修一个小点
  - Build
  - 真机验证
  - Commit
- 当前建议的验证重点：
  - Share Extension：宝宝照 / 风景 / 夜景 / HEIC / JPEG / Live Photo
  - Main App：配置保存、配置切换、时间锚点、Memory、模板编辑
  - Export：连续导出 20-50 张，观察文件名、EXIF、保存与相册显示
- 当前明确暂停的方向：
  - 大规模 UI 重构
  - 新 Memory 功能
  - 新 Renderer
  - 新 Batch
  - 新 Metadata
- 版本语言：
  - 当前阶段建议叫 `Alpha 0.7`
  - 目标只有一句话：
    - 每天都愿意用，而不是每天都在开发
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.4 Product polishing docs established

- 本轮目标：
  - 不改代码
  - 把 PhotoMemo 正式推进到“产品打磨期”的文档基线
- 本轮新增文档：
  - `Docs/ShareExtensionReview.md`
  - `Docs/DesignSystem.md`
  - `Docs/ProductBacklog.md`
- 本轮关键结论：
  - Share Extension 目前还是“技术交接面”，还不是完整的主产品体验
  - Main App 继续朝配置中心收敛
  - 之后所有 UI 需要开始遵守统一设计系统
  - 新想法以后先进入 backlog，不直接打断当前开发节奏
- Share Extension review 的核心判断：
  - 第一次使用的人仍然会有一点迷路
  - 当前成功态更像“已加入收件箱”，还不是“已完成生成并保存”
  - 最值得推进的是：预览、当前配置、生成、保存这条最短主链
- 本轮 backlog 分层：
  - `Now`：Share-first 主链、Alpha 可用性、真实设备体验、预览/导出信任
  - `Next`：Share Extension 内配置切换、保存反馈、术语统一、Design System 收敛
  - `Later`：批量分享、Quick Actions、更多默认智能化
  - `Icebox`：零配置智能模式、自动分类、模板生态扩张
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.3 Product direction docs aligned

- 本轮目标：
  - 不改代码行为
  - 只把产品方向正式写进仓库文档
- 本轮新增文档：
  - `Docs/ProductDirection.md`
  - `Docs/UX_PRINCIPLES.md`
- 本轮统一后的核心口径：
  - PhotoMemo is a memory generator built around Apple Photos, not a photo editor.
  - PhotoMemo 不是修图工具，而是围绕系统相册构建的记忆生成器。
  - Share Extension 是主工作流
  - Main App 是配置中心
  - 未来 UX 以更少决策、更少滚动、更少阅读为优先
- 本轮同步调整：
  - `README.md` 首页定义已按新口径更新
  - `Docs/CURRENT_STATUS.md` 已补充这次方向对齐记录
- 本轮验证：
  - 文档改动，无代码构建需求

## 2026-06-20 v0.7.2 Alpha 可用性迭代（第一轮）已落地

- 本轮目标：
  - 不加新功能
  - 不动架构边界
  - 只围绕 Alpha 阶段的真实上手体验收敛主界面
- 本轮主界面改动：
  - 照片导入区已前移到工作区更靠上的位置
  - `PhotoImporterView` 现在优先提供系统 `PhotosPicker`
  - 文件导入改为次级入口，保留给桌面素材与外部图片
  - iPhone 预览流里原先重复出现的工作区配置卡片已移除
  - 空照片态在滚动容器里不再强占整块高度，减少无意义留白
- 本轮配置与模板交互收敛：
  - 工作区配置区不再显示“当前配置”独立摘要卡
  - 三个配置槽位改成更直接的模块列表样式
  - 点选槽位会立即切换并刷新预览
  - 每个槽位都提供内联“编辑”菜单，用于重命名、保存当前内容、恢复默认
  - 模板区去掉更偏开发期的“预设骨架 / 默认右下”等表述
  - 模板区现在更强调“当前名称 + 直接编辑下方内容”
- 本轮可用性修正：
  - iOS 自定义区域编辑器对 CJK 输入法改为优先走系统原生合成流程，降低中文输入被编辑投影层打断的概率
  - 时间点管理按钮改为更明确的“管理与编辑”
  - 时间点列表中的“编辑”入口已放大为明确按钮，并补充“设为当前”
  - 手动导出文件如果遇到同名目标，现在会自动生成：
    - `filename (1)`
    - `filename (2)`
    - `filename (3)`
    避免直接覆盖
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
  - iOS 构建仍有既存警告：
    - interface orientations
    - launch configuration / launch storyboard
- 本轮尚未手动验证：
  - 真机上 `PhotosPicker` 导入一张系统照片后的完整 EXIF 读取体验
  - 中文输入法在长段连续编辑、删除 chip、跨 chip 插入时的最终手感
  - 时间点编辑页在 iPhone 上的最终触感
- 下一轮最值得继续：
  - 真机逐项复核 `PhotosPicker`、中文输入、时间点编辑
  - 继续检查预览页纵向节奏和各卡片间距是否还能更紧凑
  - 如果这轮手感稳定，再进入更细的 iPhone 主流程 polish

## 2026-06-20 v0.7.1 Fixture-backed Export Read-back 已落地

- 本轮目标：
  - 不改架构
  - 不改 renderer / workspace / batch 行为语义
  - 让 Sprint-009 的 smoke foundation 真正进入 fixture-backed correctness 验证
- 本轮新增测试与资产：
  - `Tests/Fixtures/GenerateSyntheticFixtures.swift`
  - `Tests/Fixtures/Synthetic/`
  - `Tests/PhotoMemoTests/Support/SyntheticFixtureLibrary.swift`
  - `Tests/PhotoMemoTests/ExportTests/FixtureExportReadbackTests.swift`
  - `Tests/PhotoMemoTests/BatchTests/BatchFixtureCoverageTests.swift`
- 当前已提交的 synthetic fixture 覆盖：
  - `01_iPhone_JPEG.jpg`
  - `02_iPhone_HEIC.heic`
  - `05_GPS.jpg`
  - `06_NoGPS.jpg`
  - `07_Portrait.jpg`
  - `08_Landscape.jpg`
  - `10_LowMetadata.jpg`
- 仍保留为 reserved-only：
  - `03_Canon.CR3`
  - `04_Nikon.JPG`
  - `09_LivePhotoStill.heic`
- 本轮自动化覆盖新增：
  - JPEG fixture export -> read-back
  - HEIC fixture import + export read-back
  - EXIF / TIFF / GPS / orientation / dimensions / description families 的显式断言
  - batch fixture enqueue / cancel / retry eligibility
- 本轮修到的真实 correctness 问题：
  - `RecordCardExportService` 之前用目标 render size 回写 metadata
  - 在实际渲染位图尺寸与目标尺寸出现 1px 差异时，可能导致：
    - 顶层 `PixelHeight`
    - EXIF `PixelYDimension`
    不一致
  - 现在已改为以最终 `CGImage` 实际尺寸回写 metadata
- 本轮当前验证状态：
  - `PhotoMemoTests` 已通过，共 19 个 tests
  - `PhotoMemo` build 已通过
  - `PhotoMemoiOS` build 已通过
  - `PhotoMemoShareExtension` build 已通过
- 下一轮最值得做：
  - renderer snapshot prep 继续往正式 snapshot 基线推进
  - 再评估是否要加入 Photos save-back read automation
  - 对 reserved 的 Nikon / Live Photo still fixtures 再补第二批 synthetic 或 licensed sample

## 2026-06-20 v0.7.0 Memory Engine Foundation 已落地

- 本轮目标：
  - 不改 renderer / export / batch / UI 行为
  - 引入真正的 Memory domain foundation
  - 让记忆语义从“零散逻辑”进入可测试、可扩展的独立边界
- 本轮新增架构文档：
  - `Docs/ADR/ADR-006-MemoryEngineFoundation.md`
  - `Docs/MemoryEngine.md`
- 本轮新增实现：
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryContext.swift`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryCalculationResult.swift`
  - `Source/PhotoMemo/PhotoMemo/MemoryEngine/MemoryVariableProvider.swift`
- 本轮接入点：
  - `CardVariableProvider` 现在通过 Memory Engine 供给记忆变量
  - `TemplateVariable` 现在公开：
    - `{{days_since}}`
    - `{{years_since}}`
    - `{{months_since}}`
    - `{{weeks_since}}`
    - `{{baby_age}}`
- 当前刻意保持不变：
  - `AnchorEngine`
  - Renderer
  - Export
  - Batch
  - Share Extension 流程
  - 现有 `memory_summary` 的 story-first / anchor-summary-first 语义
- 本轮测试：
  - 新增 `MemoryEngineTests` suite（当前放在 `PhotoMemoTests` target 内）
  - 覆盖：
    - 不满 1 岁年龄文案
    - 闰年生日
    - 时区边界
    - 未来时间点 clamp
    - `CardVariableProvider` 集成
    - public variable catalog 暴露
- 版本节奏：
  - 从这一轮开始，面向 release / changelog / 外部总结时，优先使用版本号
  - 当前版本基线记作：
    - `v0.7.0`
  - 旧的 `Sprint-*` 记录继续保留为内部开发历史，不要求回写改名
- 本轮验证状态：
  - `PhotoMemoTests` 已通过
  - `PhotoMemo` build 已通过
  - `PhotoMemoiOS` build 已通过
  - `PhotoMemoShareExtension` build 已通过

## 2026-06-20 Sprint-009 回归验证基础已落地

- 本轮目标：
  - 不改架构
  - 不改 renderer / editor / workspace / batch 设计
  - 建立可长期复用的 fixture / regression / test foundation
- 本轮新增文档：
  - `Docs/FixtureSpecification.md`
  - `Docs/RegressionMatrix.md`
  - `Docs/AcceptanceCriteria.md`
  - `Docs/CIReadiness.md`
- 本轮新增目录与基础资产：
  - `Tests/Fixtures/README.md`
  - `Tests/Fixtures/FixtureManifest.json`
  - `Tests/PhotoMemoTests/`
- fixture 侧当前共识：
  - 现在先不提交真实照片二进制
  - 先把保留文件名、元数据要求、命名规范、后续引入规则固定下来
  - 预留的第一批 fixture 名称已覆盖：
    - iPhone JPEG / HEIC
    - 非 Apple 相机 JPEG
    - GPS / No GPS
    - Portrait / Landscape
    - Live Photo still 边界样本
    - Low metadata 样本
- 本轮工程变化：
  - `PhotoMemo.xcodeproj` 新增 `PhotoMemoTests` target
  - 新增 shared scheme：
    - `PhotoMemo.xcscheme`
    - `PhotoMemoTests.xcscheme`
  - 当前 `PhotoMemoTests` 依赖主 macOS app target，采用最小 unit-test bundle 形态
- 本轮新增 smoke tests：
  - `PhotoMetadataReaderTests`
    - EXIF timezone 解析
    - GPS ref 正负号归一化
  - `PhotoMetadataNormalizationTests`
    - aspect ratio / megapixels / location display
    - 坐标回退文案
  - `MetadataContextTests`
    - capture timezone 驱动的日期组件生成
  - `TemplateVariableEngineTests`
    - token 替换与缺失 token 清空
  - `RecordCardBuildServiceTests`
    - 说明写入开关关闭时不再导出说明
    - 开启时显式 override 生效
- 本轮实际验证结果：
  - `PhotoMemoTests` 测试通过，共 8 个 smoke tests
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 本轮过程中修掉的工程问题：
  - 空目录占位文件最初都叫 `.gitkeep`，Xcode 会把它们当成资源复制进 test bundle，导致输出冲突
  - 已改为唯一占位名：
    - `.batch-tests.keep`
    - `.export-tests.keep`
    - `.renderer-tests.keep`
  - 另外补了 `PhotoMemo.xcscheme`，避免新增 shared test scheme 后主 app scheme 在 `xcodebuild -list` 中消失
- 当前真实边界：
  - 已经有了第一层可持续回归验证能力
  - 但还没有真实 fixture 二进制，所以这轮更偏“模型/服务逻辑 correctness 锁定”
  - 还没有进入：
    - renderer snapshot
    - export binary diff
    - Photos integration automation
    - batch fixture E2E
- 下一轮最值得做：
  - 引入可合法提交的真实或合成 fixture 二进制
  - 建立 `PhotoMetadataReader -> export -> read-back` 的 fixture 驱动测试
  - 再评估是否要补 renderer snapshot 与导出文件 metadata 细粒度断言

## 2026-06-20 Sprint-008 输出完整性核对已完成

- 本轮目标：
  - 不做架构重构
  - 不改渲染设计
  - 不改 editor / workspace
  - 优先核对导出完整性、回读能力、批处理可靠性、Live Photo 边界
- 本轮新增文档：
  - `Docs/ExportMetadataAudit.md`
  - `Docs/ExportReadbackVerification.md`
  - `Docs/JPEG_HEIC_Compatibility.md`
  - `Docs/BatchExportReliability.md`
  - `Docs/LivePhotoAssessment.md`
  - `Docs/OutputIntegrityReport.md`
- 本轮确认的关键事实：
  - `RecordCardExportService` 当前采用的是“原始 metadata 字典透传 + 少量显式修补”的导出策略
  - 显式修改的主要字段包括：
    - 输出宽高
    - EXIF 像素尺寸
    - 顶层 orientation = `1`
    - `TIFF Software = PhotoMemo`
    - 说明类字段（开启时）
  - `PhotoLibraryExportService` 会把 `metadata.captureDate` 写到 `PHAssetCreationRequest.creationDate`
  - 但 `PhotoMetadataReader` 当前只回读：
    - width / height
    - TIFF
    - EXIF
    - GPS
    不会把 description/comment 再读回 `PhotoMetadata`
  - batch 路径仍然是单一主链：
    - import -> build -> render/export -> save to Photos
    没有第二套批量专用导出器
- 本轮确认并修掉的 correctness 问题：
  - `shouldWritePhotoDescription` 之前没有真正阻止导出 metadata 写入说明文本
  - 现在 `RecordCardBuildService` 已在该开关关闭时返回空的 export description
  - `MainView+TemplatePanels.swift` 的说明写入预览文案也已同步修正
- 本轮结论：
  - 当前 PhotoMemo 对“静态照片、JPEG-first、写回系统图库”的可靠性已经比较不错
  - 但以下边界仍应如实对待：
    - ICC / 色彩配置文件目前没有显式校验
    - HEIC 目前是可导出/可手动选择，但不是 batch 主验证路径
    - Live Photo 目前只能按 still-image 心智理解，不能宣称支持成对资源保留
    - 说明字段虽然现在能正确写入/关闭，但 app 自己还不能完整回读这些字段
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 下一轮最值得做：
  - 建立小型导出 fixture 集，做真正的导出前后 metadata 对照
  - 评估是否把 description/comment 纳入 `PhotoMetadataReader` 的回读范围
  - 再决定是否要进入更细的 EXIF 保真验证或 Photos 写回回归测试

## 2026-06-20 Sprint-007 元数据归一化与变量目录对齐已落地

- 本轮目标：
  - 不改架构
  - 不改渲染/导出/批处理主链
  - 只在现有 metadata pipeline 内提升 correctness、consistency、catalog alignment
- 现在的关键事实：
  - `PhotoMetadataReader` 仍然是唯一 EXIF/GPS 读取入口
  - `PhotoMetadata.normalized()` 现在是 raw model 的统一归一化出口
  - `MetadataContext.Key` 现在是 runtime key 的统一定义
  - `PhotoMetadata.canonicalInventory` 现在是 metadata field inventory 的统一代码定义
- 本轮新增/改善：
  - 解析 capture-date 字符串中的 timezone suffix，保存到 `captureTimezoneOffsetSeconds`
  - `MetadataContext.build(from:)` 在渲染日期组件时，若 metadata 自带 timezone，则按 capture timezone 计算年/月/日/时/分/秒/weekday
  - GPS 现在会根据 `LatitudeRef` / `LongitudeRef` / `AltitudeRef` 处理正负号
  - 新增并公开的 metadata-facing variables：
    - `{{lens_brand}}`
    - `{{location}}`
    - `{{location_display}}`
    - `{{country}}`
    - `{{province}}`
    - `{{city}}`
    - `{{district}}`
    - `{{latitude}}`
    - `{{longitude}}`
    - `{{altitude}}`
    - `{{weekday}}`
    - `{{capture_date_short}}`
    - `{{capture_time_short}}`
    - `{{capture_timezone}}`
    - `{{orientation}}`
    - `{{aspect_ratio}}`
    - `{{megapixels}}`
    - `{{memory_summary}}`
  - `TemplateVariableLibrary.recognized` 的优先级也已按当前 PhotoMemo 使用价值重新排序
  - `TemplateVariableEngine` 的 token regex 现在缓存，不再每次 render 重新编译
- 有意保留为 internal-only 的 runtime keys：
  - `badge_name`
  - `anchor_hours`
  - `anchor_minutes`
  - `anchor_seconds`
- 本轮文档：
  - `Docs/MetadataInventory.md`
  - `Docs/VariableCatalogAlignment.md`
  - `Docs/MetadataNormalizationPlan.md`
  - `Docs/CURRENT_STATUS.md`
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 没做的事：
  - 没新建 test target
  - 没做 reverse geocoding / location enrichment
  - 没改 share extension 的 metadata ownership
- 下一轮最值得做：
  - 为 `PhotoMetadataReader -> MetadataContext -> TemplateVariableEngine` 补回归测试
  - 再评估是否进入 `Sprint-008` 的 location enrichment / high-value variables

## 2026-06-20 Composer projection 已抽成独立 EditorProjectionEngine

- 已完成 `Sprint-005` 的保行为抽取：
  - 新增 `Source/PhotoMemo/PhotoMemo/Views/Main/EditorProjectionEngine.swift`
  - 删除旧的 `MainView+ComposerDisplayEngine.swift`
- 当前共识：
  - `String` 仍然是唯一真实来源
  - 没有引入 `ComposerDocument`
  - 没有引入 node tree / rich text / renderer-side projection
- 新引擎当前承接的责任：
  - raw template string -> display text
  - module span 生成与清洗
  - selection clamp
  - caret / selection 调整
  - chip 删除时 replacement range 调整
  - projection state 同步
- 已切换调用点：
  - `MainView+ComposerSession.swift`
  - `MainView+TemplateEditingActions.swift`
  - `MainView+ComposerEditor.swift`
  - `MainView+LayoutSections.swift`
- 明确保持不变：
  - `Template` 持久化格式
  - `RecordCardBuildService`
  - `TemplateVariableEngine`
  - Renderer / Export / Batch / Workspace / Settings
- 这轮目标不是改编辑模型，只是把 editor-specific projection 从 `MainView` 语义下抽离成独立引擎，方便后续继续做 composer 侧治理。

## 2026-06-20 WorkspaceSession Phase A 已铺架构壳层

- 已新增 4 个 workspace session 预备类型：
  - `WorkspaceSessionController`
  - `WorkspaceState`
  - `WorkspaceAction`
  - `WorkspaceEnvironment`
- `MainView` 只做了最小接线：
  - 新增 `workspaceSession` 持有者
  - `onAppear` 时把当前 `MainView` 状态与依赖 seed 进 session
- 这轮明确**没有**迁移：
  - 导出逻辑
  - 权限逻辑
  - 生命周期逻辑
  - 模板编辑逻辑
  - batch / queue 逻辑
- 当前真实状态：
  - `WorkspaceSessionController.send(action:)` 只承接基础状态更新壳层
  - 现有业务仍然全部走原来的 `MainView+*.swift` 实现
  - 这是为下一轮“分阶段把现有 workflow 移进 session”做准备，不代表迁移已开始
- 编译边界：
  - 这些新类型同样通过 `#if !PHOTOMEMO_SHARE_EXTENSION` 避免被 Share Extension target 编译
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过

## 2026-06-20 BatchQueueStore 已拆为 4 个聚焦组件

- 已完成 `Review-002`：
  - `BatchQueueStore` 保留为公开 façade 与 `ObservableObject` 状态拥有者
  - 内部职责已拆到：
    - `BatchQueueExecution`
    - `BatchQueuePersistence`
    - `BatchQueueHistory`
    - `BatchQueueNotifications`
- 本轮明确保持不变：
  - UI / 渲染 / 导出行为
  - 队列执行顺序
  - 重试与取消语义
  - `UserDefaults` key 与持久化格式
  - 启动恢复语义
  - 通知发送与 sentAt / stage 回写时机
- 这次没有引入额外 `QueueState` 层，也没有为了行数再继续拆更多人工抽象层。
- `PhotoMemoShareExtension` 当前通过 `#if !PHOTOMEMO_SHARE_EXTENSION` 编译边界避免把 app-side queue façade / notification wiring 拉进 extension target；后续不要误把这些 guard 删除。
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 仍未做的验证：
  - 真机/手动回归 `retry`
  - 真机/手动回归 `cancel`
  - 真机/手动回归启动恢复后的继续处理
- 下一步更适合做：
  - 对 `BatchQueueStore` 子系统补最小可行的回归测试
  - 再考虑更高层的架构工作，不要在这轮拆分后立刻继续改 batch 语义

## 2026-06-20 BatchConfigurationSnapshot 单一来源已收口

- 已新增 `BatchConfigurationSnapshotProvider`，作为批处理默认快照与共享配置装配的单一来源。
- `SettingsService.buildBatchConfigurationSnapshot()` 已改为委托给该 provider，不再自己重复拼装默认模板 / 徽标 / 锚点 / 相册标识。
- `SharedBatchConfigurationSnapshotService.loadSnapshot()` 已改为直接复用同一 provider，Share Extension 与主 app 不再各自维护一套装配逻辑。
- 保持不变：
  - `UserDefaults` keys
  - 序列化格式
  - 默认值
  - UI、渲染、导出、通知与队列行为
- 本轮验证：
  - `PhotoMemo` build 通过
  - `PhotoMemoiOS` build 通过
  - `PhotoMemoShareExtension` build 通过
- 后续合适的下一步：
  - 继续拆 `BatchQueueStore`
  - 再收束 `MainView` 的 workspace/export 协调逻辑
  - 暂时不要回退这次 provider 收口，避免再次出现快照装配漂移

这份文件用于帮助新的 Codex 会话快速接手当前项目，避免只依赖历史聊天上下文。

现在仓库根目录还新增了一份更偏“持续接力开发手册”的文档：

- `AI.md`

建议新的 AI 会话把它也作为第一批必读文件之一。

## 2026-06-19 分享摘要已进一步贯穿到桌面端与主 app drain 校正

这一轮继续围绕 share-intake 主链收口，但重点不再是 iPhone sheet 本身，而是让同一份“分享时发生了什么”的摘要在更多真实入口里保持一致。

新增/调整：

- `ExternalPhotoImportSummary` 现在除了会跟着 share extension 请求一起进入 `BatchJob`
- 也会继续挂进：
  - `ExternalIntakeSummary`
  - macOS 主界面的 `记忆进度` 面板

用户现在能看到的变化：

- macOS 左侧 `记忆进度` 里，最近一次外部导入不再只写“来了几张”
- 如果是分享入口，并且分享时有：
  - 重复跳过
  - 导入失败
  - 选中数和真正入队数不一致
  现在文案会直接说清楚
- 也就是说，桌面端现在也能看到更像“处理回执”的信息，而不是只在 iPhone 后台状态里知道异常

这一轮还顺手补了一个主 app 侧的摘要口径修正：

- `PhotoMemoAppRuntime.flushExternalRequests()` 在 drain 共享请求时，会先重新检查真正仍然有效的文件 URL
- 如果 share extension 当时写进收件箱的部分文件，到了主 app 真正接单时已经失效：
  - 现在会把 `importSummary` 重新修正到真实可入队数量
  - 避免后续通知 / 记忆进度把“已经失效、其实没入队”的图片继续算成成功入队

注意：

- 这里修过一次 double-count 细节，最终保留的口径是：
  - 只把“原本标记为 imported，但主 app drain 时已经失效”的数量补进 `failedCount`
  - 不会重复累计

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 分享接收摘要已贯穿到通知与 iPhone 后台状态

这一轮继续沿着 iPhone / share-intake / background queue 主链做，但重点不是再扩 ActivityKit，而是把“分享时已经发生的部分成功、跳过、失败”真正带进后续反馈链路。

完成内容：

- 新增共享摘要模型：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
  - `ExternalPhotoImportSummary`
- `ExternalPhotoIntakeRequest` 现在可携带：
  - 成功入队数
  - 重复跳过数
  - 导入失败数
- `PhotoMemoShareExtensionIntakeService` 在 share extension 侧会把这份摘要一起持久化进共享收件请求
- `PhotoMemoAppRuntime` / `BatchQueueStore` 会继续把这份摘要挂到最终 `BatchJob`

这带来的直接效果：

- 后台任务的开始通知现在不再只说“接收了多少张”
- 如果本次分享里有重复项被跳过、或有图片根本没能导入，现在通知里会明确说出来
- iPhone 后台状态页新增了“本次接收结果”卡片，能看到：
  - 分享选中
  - 成功入队
  - 重复跳过
  - 导入失败

这一轮还补了一刀取消保护：

- `BatchQueueStore.swift` 在真正调用 `saveRenderedPhoto` 前又加了一次终态检查
- 这样如果用户在“将要写入系统相册”前一刻取消，就不会再误把后续保存继续跑下去

补充说明：

- share extension 的 Data fallback 去重现在已经是基于内容 `SHA256`，不是旧的“大小 + 名称”近似判断
- 这一轮没有做模拟器启动回归，因为当前机器上的 `CoreSimulatorService` 仍然不可用；但三条构建命令都重新通过了

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 队列取消与分享去重再硬化

这一小轮没有继续扩界面，而是优先补了三个更容易变成“偶发失灵”的边界。

1. `BatchQueueStore` 取消边界补强

- 文件：
  - `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- 修正点：
  - 如果用户在任务处理中途取消，当前活跃 task 不再继续把后续流程一路跑到底
  - 现在在 `importPhoto` 返回后、`exportCard` 返回后，都会重新检查 task 是否已经进入终态
  - 如果取消导致处理中抛错，也不再把已取消任务错误地改写成 `failed`
- 结果：
  - 降低“明明取消了，结果还继续保存进系统相册”这类错误行为的风险

2. 失败项重试语义更准确

- 同样在 `BatchQueueStore.swift`
- 修正点：
  - managed intake 源文件如果仍然存在，失败项现在保留重试资格
  - 只有真正找不到受管源文件时，才把 `canRetry` 压成 `false`
- 结果：
  - 更符合之前已经确定的方向：
    - PhotoMemo 自己复制进 `ExternalIntake` 的文件可以临时保留
    - 单张失败不应该轻易丢掉重试机会

3. Share Extension 的 Data fallback 去重更稳

- 文件：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- 修正点：
  - 之前 Data fallback 的去重 key 近似于 `data.count + suggestedName`
  - 这会让“不同图片刚好大小相同、名字也接近”的情况有误判概率
  - 现在改成基于 `SHA256` 的内容哈希去重
- 结果：
  - 多图分享时，误把不同图片当成重复项跳过的风险更低

顺手补的一点：

- `PhotoMemoiOSLiveActivityDriverService.swift` 现在会在 activity 被结束/失效后更完整地同步 `lastAppliedPayloads`
- 这属于小型状态收口，主要是避免重复应用同一终态 payload

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过

## 2026-06-19 Live Activity widget extension 已接通

这一小轮把上一轮还没收口的 ActivityKit / widget 侧工程接线真正补完了。

完成内容：

- 新增真实 widget extension 入口：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension/PhotoMemoWidgetExtensionBundle.swift`
- 新增 extension plist：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`
- `PhotoMemoLiveActivityPresentation.swift` 继续作为共享的 Live Activity 展示定义，被 widget extension 直接编译使用
- `PhotoMemoiOS` 现在会同时嵌入：
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

这轮顺手解决的关键工程坑：

- 之前 share extension 嵌入失败的核心原因，基本确认是 `ShareExtension-Info.plist` 缺少基础 bundle 键，导致嵌入校验时 bundle identifier 被视为 `(null)`
- widget extension 第一版又踩到 `Info.plist` 同时被“处理”和“Copy Bundle Resources”双重产出
- 处理方式是把 widget extension 的 plist 挪到同步组目录外，改成：
  - `Source/PhotoMemo/PhotoMemoWidgetExtension-Info.plist`

本轮验证：

- `PhotoMemoiOS` 构建通过
- `PhotoMemoShareExtension` 构建通过
- `PhotoMemo` 构建通过
- 额外验证了 `PhotoMemoiOS.app/PlugIns` 里已经存在：
  - `PhotoMemoShareExtension.appex`
  - `PhotoMemoWidgetExtension.appex`

当前真实结论：

- iPhone 线不再只是“app 可编译 + 分享扩展可编译”
- 现在已经进入“app + share extension + Live Activity widget extension 可一起构建并嵌入”的阶段
- 后续更值得优先做运行时与设备侧验证，而不是继续卡在 `xcodeproj` 嵌入层

## 项目根路径

- 实际项目路径：`/Users/rui/Desktop/PhotoMemo`
- 当前 Codex 工作区里通常会通过 `desktop_project -> /Users/rui/Desktop/PhotoMemo` 映射访问真实项目

## 产品一句话

PhotoMemo 是一个 **local-first 的 macOS 原生照片信息纪念卡生成器**。  
它不是修图软件，也不是云相册，而是一个基于 EXIF 和时间锚点，把照片转成“带记忆语义的信息卡”的工具。

## 核心原则

- 完全本地运行
- 不上传照片
- 不修改原图，生成新图
- 主界面是“模板校准中心”，不是未来的批量工作台
- 日常处理流程要逐步转向外部接入 + 后台处理 + 写回系统图库
- 不能为了 UI 漂亮而脱离真实渲染/导出链路

## 当前主链路

1. 设置模板
2. 设置时间锚点
3. 导入一张预览照片
4. 读取真实 EXIF
5. 生成真实预览内容
6. 实时预览底部信息卡
7. 保存配置
8. 后续通过外部导入/分享进入后台任务
9. 生成新图并存回系统图库/目标相册

## 已经成形的能力

- SwiftUI macOS 主应用
- EXIF 读取
- 时间锚点引擎
- 四个自定义区域
- 模板预设
- 图标/徽章区域
- 预览渲染
- 导出成新图
- 写回系统图库
- 默认 photomemo 相册策略
- 后台队列、通知、权限引导

## 时间锚点系统共识

智能模块只输出“时间结果本身”，不直接生成整句文案。

例如：

- `{{anchor_age_text}}` -> `1岁2个月18天`
- `{{anchor_duration_text}}` -> `2年4个月18天`
- `{{anchor_elapsed_text}}` -> `已过32天`
- `{{anchor_countdown_text}}` -> `还有86天`
- `{{anchor_day_index_text}}` -> `第128天`

最终表达由用户自己在前后补文字，例如：

- `途途今天` + `{{anchor_age_text}}`
- `距离高考` + `{{anchor_countdown_text}}`

这条原则很重要，不要回退到“模块直接输出整句文案”。

## 当前界面共识

- 整体风格走白色、极简、系统级方向
- 主预览区只保留一张校准照片
- 下面四个区域都必须能独立编辑
- 插入 EXIF/智能模块时，必须进入“当前选中的区域”
- 深色模式下也要可用，但主视觉优先保证浅色系统风格
- Immers 风格只借鉴底部白边语言，内容仍以 PhotoMemo 的记忆语义与智能模块为主
- 当前“徽章/badge”语义已经统一往“Logo 标识”方向收束
- `immersWhite` 在未自定义标识时，保留经典 Apple 小 logo 作为默认回退

## 最近已经处理过的重要问题

最近对 `MainView.swift` 做过一轮关键修正，新的会话不要把这些修回去：

1. 去掉了“没有明确选区时默认插到右下角”的隐式兜底
2. 模块插入前必须先明确选中左上/右上/左下/右下某一区域
3. 开始把四个区域的模块编辑态从“字符串即时反解析”往“更稳定的本地状态”方向收
4. 修正了拖拽重排的目标索引逻辑
5. 模板切换、恢复默认、模板改名后，需要同步刷新模块编辑态

如果后续继续重构 `MainView.swift`，优先保留这些行为。

## 当前最大技术债

`Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift` 已经明显瘦身，目前约 `72` 行，基本就是 coordinator state shell。

- 模板编辑
- 焦点/插入路由
- 拖拽与模块整理
- 权限状态
- 相册选择
- 导出动作
- 批量任务状态展示

最近已经抽出的 `MainView` 子文件包括：

- `MainView+MemoryProgress.swift`
- `MainView+OutputSection.swift`
- `MainView+Permissions.swift`
- `MainView+ComposerEditor.swift`
- `MainView+ComposerPanels.swift`
- `MainView+ComposerSession.swift`
- `MainView+TemplatePanels.swift`
- `MainView+SetupPanels.swift`
- `MainView+PreviewPanels.swift`
- `MainView+PermissionLifecycle.swift`
- `MainView+WorkspaceConfigurationState.swift`
- `MainView+ExportActions.swift`
- `MainView+DerivedState.swift`
- `MainView+CoordinatorSupport.swift`
- `MainView+TemplateEditingActions.swift`
- `MainView+PresentationState.swift`
- `MainView+StateModels.swift`
- `MainView+LayoutSections.swift`
- `MainView+UIPrimitives.swift`
- `MainView+ModalAndLifecycle.swift`
- `MainView+Feedback.swift`

这轮已经把 preview/detail 的显示壳层，以及 editor session / workspace configuration / export-save / permission lifecycle / derived state / template editing actions 都抽出去了。随后又把剩余 editor session 状态做了轻量分组，当前下一阶段更适合继续清理访问级别、少量 panel binding，以及补一轮手动回归，而不是为了拆而拆。

最近还补了三项当前体验修正：

- 相册权限被拒绝后，不再假装还能重新弹系统授权框，而是明确引导去系统设置恢复权限
- 年龄类智能模块在未满 1 岁时不再输出 `0岁...`
- `补充信息` 区已改成单卡片，勾选时使用单独批量说明，不勾选时回退到右下区域最终内容

随后单独起了一轮，把下面两条一起推进：

- 三个固定本地配置槽位，默认对应 `模板 1 / 模板 2 / 模板 3`
- 右侧负责“当前哪套配置生效”、保存到当前配置、恢复当前默认、打开操作指南
- 左侧复杂说明优先改成可关闭提示卡，完整说明收进右侧操作指南 sheet

这条线已经继续向前推进了一步，当前又补上了两项：

- 三个配置槽位现在支持单独自定义命名，用来区分“宝宝成长”“旅行纪念”“高考倒计时”等不同方案
- 右侧操作指南已升级为更像正式帮助中心的分组导航，入口菜单和帮助 sheet 都按主题分组

当前额外共识：

- 槽位命名只改配置槽位标签，不改模板名称
- 恢复槽位默认骨架时，只清除该槽位保存的配置快照，不会顺手清掉自定义槽位名称
- 左侧说明卡即使被用户关闭，完整说明仍可通过右侧帮助中心查看
- 当相册和通知都已授权时，侧边栏里的权限区不再继续占位
- 输出区优先保持“选相册 + 保存新图”主链，不再把元数据验证按钮留在主界面

最近又顺手做了一轮界面收口：

- `个性化区域` 的说明不再是写死文本，而是可关闭提示卡
- `补充信息` 已真正收成单卡，不再上下两块
- 帮助中心不再单独保留权限主题，改成只保留与当前主流程更相关的主题
- `MainView` 里原来那条已经没有界面入口的元数据验证调试支线也已经删掉

随后又完成了一轮更实质的 coordinator 收口：

- `MainView+ComposerSession.swift` 现在承接四个区域编辑器的 display text / selection / module span 会话态
- `MainView+WorkspaceConfigurationState.swift` 承接三个配置槽位的保存、切换、恢复默认和快照应用
- `MainView+ExportActions.swift` 承接相册权限申请、相册刷新、导出并写入系统图库
- `MainView+PermissionLifecycle.swift` 又继续承接了权限首启、scene active 刷新和通知权限反馈
- `MainView+DerivedState.swift` 承接预览、锚点、模板摘要等派生展示态
- `MainView+CoordinatorSupport.swift` 承接 anchor / preview 尺寸这类轻量 coordinator helper
- `MainView+TemplateEditingActions.swift` 承接模板值更新、模块插入和当前编辑区域路由
- `MainView+PresentationState.swift` 承接 rename / guide 相关 sheet 与本地 draft 状态
- `MainView+LayoutSections.swift` 承接 sidebar / detail 与各 section 的视图拼装
- `MainView+UIPrimitives.swift` 承接 `MainFieldSlot` 与主界面共用样式基元
- `MainView+ModalAndLifecycle.swift` 承接 body 外层 sheet / alert / 生命周期接线
- `MainView+Feedback.swift` 承接 alert helper 与 preview stub
- 同时已经把旧的 block-style composer widget / scrubber / literal-composer sheet 遗留清掉
- `MainView.swift` 当前大约回落到 `72` 行
- 这一轮 refactor 收口后，本地 `xcodebuild` 已重新通过

随后又补了一刀轻量 state grouping：

- `MainView+StateModels.swift` 现在统一承接 `MainAlertState`、`MainPresentationState`、`MainEditorSessionState`
- `MainEditorSessionState` 收起了 `focusedField`
- `MainEditorSessionState` 收起了四个区域的 display text / selection / module spans 会话态
- 这一步没有改插入逻辑、光标路由、模板同步或导出行为，只是把剩余 coordinator 状态按语义重新归位

这条线又继续推进了一小步，当前最新共识是：

- `个性化区域` 左侧不再保留顶部“额外控制/说明块”，界面只保留四个真实区域和插入按钮
- 自定义文字不再走原来的 raw token / inline editor 路径，而是作为和 EXIF、智能模块并列的单独文字 chip 进入区域内容流
- 再次点击已选中的文字 chip，可以直接回到文字编辑 sheet 修改当前这段文字
- `识别数据`、`智能数据` 继续保持按钮式插入，不把 `{{anchor_duration_text}}` 这类 token 直接暴露给普通编辑流程
- `补充信息` 和 `输出` 顶部说明都已经改成可关闭提示卡，完整说明继续放在右侧帮助中心
- 模板区里给用户看的“默认右下”文案已经改成更口语化的人类可读摘要，而不是 raw token

不过这条线又被用户继续纠偏了，当前最新真实方向应以这版为准：

- 四个自定义区域优先走“直接点进去输入”的内联编辑，而不是把用户短语拆成单独文字模块
- 点击上方 EXIF / 智能模块按钮时，要按当前光标位置插入到对应区域
- 正常编辑时不再把 raw `{{token}}` 暴露出来，而是显示成更人类可读的内联标签文本
- 如果后续继续打磨这一块，优先验证“光标位置是否准确保留”和“模块插入后前后继续输入是否顺手”，而不是先回到块状拖拽编辑

这条线随后又补了一步，当前最新交互目标还包括：

- 虽然底层已经回到光标式内联编辑，但模块在编辑区里的视觉表现要尽量接近“独立小方块”
- 光标贴着模块时，按删除应优先整块删除，而不是拆字符
- 编辑器显示映射不能只覆盖基础 token，像 `camera_summary` 这类模板里常用的组合 token 也必须转成可读标签，避免出现“半中文标签、半 raw token”的混合显示

如果后续继续这条线，优先检查：

- 切换配置后左侧字段和右侧预览是否同步刷新
- 未保存槽位是否正确回退到默认模板骨架
- 当前活动配置是否始终和 batch queue 默认配置快照保持一致
- 光标停在模块前后时，连续插入/删除是否仍然保持预期

## 建议优先阅读的文件

### 产品与文档

- `README.md`
- `AI_CONTEXT.md`
- `AGENTS.md`
- `Docs/CURRENT_STATUS.md`
- `Docs/PRODUCT_SPEC.md`
- `Docs/MVP.md`
- `Docs/DEVELOPMENT_PLAN.md`
- `Docs/ANCHOR_SYSTEM_DESIGN.md`
- `Docs/BATCH_TASK_SYSTEM_DESIGN.md`

### 核心代码

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`
- `Source/PhotoMemo/PhotoMemo/Models/CardVariableProvider.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`

## 新会话接手时建议先做什么

1. 确认当前工作目录是否直接是 `/Users/rui/Desktop/PhotoMemo`
2. 读取 `README.md`、`AI_CONTEXT.md`、`HANDOFF.md`、`AGENTS.md`
3. 读取 `Docs/CURRENT_STATUS.md`
4. 看 `git status`
5. 检查 `MainView.swift` 与最新的 `MainView+*.swift`
6. 如需编译，用既有命令：

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

## 当前工作流共识

本地已经安装适合后续开发的 skills：

- `spec-driven-development`
- `planning-and-task-breakdown`
- `incremental-implementation`
- `test-driven-development`
- `code-review-and-quality`
- `frontend-ui-engineering`

后续处理非小改动时，优先按这个顺序推进：

1. `/spec`
2. `/plan`
3. `/build`
4. `/test`
5. `/review`

## 当前最值得继续推进的方向

- 继续拆分 `MainView.swift`
- 优先收口访问级别与 ownership 表达
- 继续整理 badge / output / workspace 这类局部 binding
- 保证预览与最终导出一致
- 继续增强元数据保留策略
- 为未来 iOS 迁移减少 macOS 特有耦合

## 当前验证状态

最近几轮 `MainView` 拆分后，本地构建已通过。

已知情况：

- 编译通过
- 只存在 Xcode destination 选择 warning
- 当前 Xcode project 仍没有单独 test target，这一轮验证以 build 和结构 review 为主
- 仍建议补做手动 UI 回归检查：
  - 模板切换
  - 模板改名
  - 时间锚点选择
  - 照片导入
  - Live Context 与实时预览是否仍按当前模板刷新
  - `immersWhite` 默认 logo 回退
  - 预览与导出一致性
  - workspace slot 切换时的 caret 保留
  - 连续插入 EXIF / 智能模块时的光标路由

## Git 与同步说明

- 远程仓库：`origin git@github.com:serydoo/PhotoMemo.git`
- 当前主分支：`main`
- 已经建立了项目内 `.codex/skills`
- 发布/同步时，优先先检查构建、再看 `git status`、`git diff --stat`、最后 commit/push

## 给下一位 Codex 的一句话

不要把 PhotoMemo 当成“加边框工具”继续堆功能。  
它现在的真正方向是：**以模板、EXIF、时间锚点和后台处理为核心的本地照片记忆生成系统。**

## 2026-06-19 本轮补充

这一轮又继续往“稳住四个自定义区域的编辑模型”推进了一步，新增了：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ComposerDisplayEngine.swift`

这次的关键调整不是视觉，而是编辑语义：

- 不再把所有长得像 `〔...〕` 的可见文字都当成真实模块
- 只把真正插入或从模板同步出来的模块，记录为带范围信息的 module spans
- macOS 与 UIKit 两条编辑路径都改为共享这一套范围语义
- 删除或替换跨过模块时，不再只误伤模块本体而丢掉外围普通文本

这意味着后续如果继续打磨这块，优先方向不该再回到 raw token 暴露，而是继续围绕：

- caret 是否稳定
- 选择替换是否自然
- 模块插入与整块删除是否顺手

本轮额外记录文件：

- `Docs/OPTIMIZATION_LOG_2026-06-19.md`
- `Docs/COMPETITOR_NOTES_2026-06-19.md`
- `Docs/IOS_READINESS_2026-06-19.md`
- `Docs/MANUAL_REGRESSION_CHECKLIST_2026-06-19.md`

其中第一份记录了：

- 这次真正改了什么
- 为什么值得
- `MainView.swift` 下一轮最值得继续拆的三个区块

如果下一位 Codex 继续往下做，当前最值得继续清理的 3 块已经更新为：

- 访问级别收口
- badge / output / workspace 相关 binding
- 手动回归光标 / 槽位切换 / 保存反馈这三条高风险交互

第二份记录了：

- 2026-06-19 基于官网信息整理的相邻竞品/参考产品
- 各自最值得借鉴的亮点
- 对 PhotoMemo 后续产品提升最有价值的方向判断

第三份记录了：

- 当前仓库距离 iOS 开发的真实准备度
- 已具备的跨平台基础
- 当前主要 blockers 和最短启动路径

第四份记录了：

- 当前重构阶段最值得优先手动回归的链路
- 光标 / 模块插入 / 时间点 / 配置槽位 / 相册保存的检查步骤
- 每一步的预期结果与高风险回归信号

## 2026-06-19 晚些时候补充

这一小轮继续做了主界面收口，没有改导入、渲染、导出行为，主要是把用户能看到的主流程表述统一到当前固定模板 1 + 配置槽位方向：

- 右侧帮助中心不再混用“批量说明”“切换模板”等旧说法，统一改成当前的补充信息输入、配置槽位切换与保存语义
- 模板摘要不再展示 raw token 风格描述，`模板 1` 默认右下改为人类可读的“今天 + 年岁”
- 预览区、后台通知、补充信息预览等文案统一从“当前模板”进一步收口到更贴合现状的“当前配置”语义

本轮验证：

- 已再次通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 仍只有既有的 Xcode destination warning

这轮没有做新的手动 UI 操作验证，后续最值得继续盯的仍是：

- 参数摘要模块在模块左侧普通文本被删除后的显示/删除边界
- 配置槽位切换时四个自定义区域的光标与编辑态刷新
- 补充信息留空回退到右下内容时，预览与最终写回说明是否始终一致

## 2026-06-19 iOS 起步骨架

这一轮开始正式为 iOS 版本铺文件库与入口基础，但还没有在 `xcodeproj` 里新增 iOS target。

已经落地的结构：

- 新增共享 app runtime：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppRuntime.swift`
- 新增共享 root scene：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoRootSceneView.swift`
- 新增 iOS 专属目录骨架：
  - `Source/PhotoMemo/PhotoMemo/iOS/App/PhotoMemoiOSApp.swift`
  - `Source/PhotoMemo/PhotoMemo/iOS/Views/PhotoMemoiOSHomeView.swift`

这一步的意义：

- macOS `PhotoMemoApp` 不再自己背外部图片接单与队列注入逻辑，入口层开始可复用
- 后续新增 iOS target 时，可以直接复用 `PhotoMemoAppRuntime` 和 `PhotoMemoRootSceneView`
- 现在的 iOS 文件库已经有了明确落点，后面继续加 iOS 专属 import/export/navigation 代码时不会再混回 macOS 入口

这轮特别注意：

- 还没有修改真实导入、渲染、导出链路
- 还没有真正把 iOS target 写进 `PhotoMemo.xcodeproj`
- `PhotoMemoiOSApp.swift` 与 `PhotoMemoiOSHomeView.swift` 目前是受 `#if os(iOS)` 保护的起步壳层，先为后续 target 接入做准备

本轮验证：

- 已通过：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 中途遇到一次新的 `MainActor` 初始化编译错误，已在 `PhotoMemoAppRuntime` 中改为 runtime 内部构造默认对象后解决

下一轮如果继续 iOS 线，最合理的顺序是：

- 给 `PhotoMemo.xcodeproj` 真正新增 iOS app target
- 把共享源纳入 iOS target，先追求可编译
- 再拆 app entry / intake / export 的 iOS 专属实现

## 2026-06-19 iOS target 已接入

这一轮已经把真正的 iOS app target 接进工程：

- 新 target / scheme：
  - `PhotoMemoiOS`
- 工程文件：
  - `Source/PhotoMemo/PhotoMemo.xcodeproj/project.pbxproj`

同时顺手补了两类基础兼容工作：

- 给现有 `AppIcon.appiconset` 补齐了 iPhone / iPad / marketing icon 描述与实际 PNG 文件，继续与 macOS target 共用同一套 asset catalog
- 帮助中心 `MainOperationGuideSheetView` 改成双平台导航实现：
  - macOS 继续 `NavigationSplitView`
  - iOS 改为 `NavigationStack + 分组列表 + NavigationLink`

这意味着当前仓库已经从“只有 iOS 文件库骨架”推进到“工程里真实存在一个可编译的 iOS target”。

本轮验证：

- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 iOS Simulator 泛目标：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

这轮真实踩到并解决的 iOS 阻塞：

- iOS target 最开始缺少可用 AppIcon
- 帮助中心的 `List(selection:)` / `NavigationSplitView` 用法不适合 iOS

下一轮如果继续 iOS 线，最值得优先推进的是：

- 让 `MainView` 在 iPad 竖屏/横屏下都更像正式可用界面，而不是仅仅“能编译”
- 开始拆 iOS 专属导出路径，例如 Photos-only / share sheet
- 开始整理 iOS 下不该继续暴露的 macOS 语义和交互细节

## 2026-06-19 iPhone 首轮适配

用户已经明确表示暂时不单独考虑 iPad，所以这一轮开始把 iOS 重点改成 iPhone 紧凑宽度体验。

这轮的核心不是“自动适配所有机型”，而是先把主界面改成更像手机产品的结构：

- iOS 首页不再是“预览 + 全量编辑”的超长单页
- 改成顶层 `预览 / 编辑` 分段切换
- 预览页优先展示：
  - 当前配置面板
  - 实时预览
- 编辑页优先展示：
  - 当前配置面板
  - 权限、照片、模板、时间点、四区编辑、补充信息、Logo、输出

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`

这一步的意义：

- iPhone 17 Pro Max / 15 Pro 这类设备现在虽然还是同一套 SwiftUI 代码，但已经不再单纯依赖系统“自动缩放”
- 现在主信息架构开始主动面向紧凑宽度编排，用户进入时先看预览，再切到编辑，心智更清楚

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- 输出区在 iPhone 上改成更明确的单主动作流程
- 导入/导出做更像 iOS 的路径，而不是继续沿用桌面心智
- 继续收紧手机端顶部信息密度和部分 section 的默认展开顺序

## 2026-06-19 iPhone 主链路第二轮

这一轮继续只做 iPhone 紧凑宽度体验，不碰底层渲染和相册写回实现。

重点推进了两件事：

- iPhone 的“预览”页现在不再只有预览本体，已经前置了：
  - 当前配置面板
  - 照片导入区
  - 输出区主动作
- 输出区在紧凑布局下改成更明确的单主动作表达：
  - 按钮文案直接带当前相册去向
  - 补了一条更贴近手机流程的说明，强调“先看预览，再保存”

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`

这意味着当前 iPhone 页面里，用户已经可以更顺地走完整个主链路：

- 导入照片
- 看预览
- 直接保存到当前相册

而不用一上来先掉进超长编辑页里找入口。

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- iOS 下导出后的分享路径或系统相册完成反馈，做得更像原生手机 app
- 继续把“编辑”页里次要内容往后放，减少第一次进入时的认知负担

## 2026-06-19 iPhone 反馈与降噪

这一轮继续沿着 iPhone 体验收口，但仍然没有改底层导出/保存实现。

主要补了两件事：

- iPhone 紧凑布局下，保存成功后不再只有系统 alert
  - 额外补了一张短时出现的轻量成功反馈卡片
  - 文案会直接告诉用户已经写入哪个相册，并提示可以继续下一张
- 编辑页继续降噪
  - 首次进入编辑页时，主视觉更集中在模板、时间点、四区编辑和输出

## 2026-06-19 主界面职责再收口

用户已再次明确：

- 主界面永远只负责设定参数、自定义信息和实时预览
- 后台处理进度不应继续占用主界面区域

因此这一轮又补了一次职责收口：

- macOS 主界面移除了 `记忆进度` 可见面板
- iPhone 编辑页也移除了 `记忆进度` 展示入口
- 帮助中心 overview 中不再把 `记忆进度` 当成主界面组成部分描述

这意味着当前仓库的真实共识已经变成：

- 主界面 = 校准中心
- 后台自动处理 / 通知 / 后续灵动岛 = 独立的后台能力
- 两者可以共用同一套配置，但不应在一个界面里混着表达

相关文件：

- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+StateModels.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+Feedback.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ModalAndLifecycle.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+OutputSection.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+LayoutSections.swift`
- `Source/PhotoMemo/PhotoMemo/Views/Main/MainView+ExportActions.swift`

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续 iPhone 线，最值得优先推进的是：

- 把保存完成后的下一步动作做得更像 iOS，例如分享或继续处理的轻动作
- 继续梳理编辑页里哪些 section 适合默认折叠/后置，进一步降低第一次使用压力

## 2026-06-19 后台自动处理感知层

用户已经进一步明确真实使用模式应当是：

- 在系统相册或其他位置选中图片
- 通过分享发送到 PhotoMemo
- 后台自动处理
- 按预设配置直接写入指定相册
- 用户不需要逐张盯着保存

这一轮先没有直接上分享扩展或灵动岛，而是先把现有后台队列的“进度感知层”补强，作为下一步的基础。

已落地：

- 后台批次不再只有“开始接收”和“最终完成”两次通知
- 新增了三个批次级阶段进度通知：
  - `imported`
  - `rendering`
  - `saving`
- 每个批次会记住自己上一次已发送的阶段，避免同一阶段重复刷通知

相关文件：

- `Source/PhotoMemo/PhotoMemo/Models/BatchProcessing.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchNotificationService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`

这一步的实际意义：

- iPhone / Mac 端现在更接近“设好相册后不用继续操心”
- 通知栏里能看到后台任务不是卡死，而是在读取、生成、写入中的哪一段
- 后续如果继续接灵动岛 / Live Activity，这一套 stage 摘要可以直接复用，不用重新发明一遍后台进度模型

本轮验证：

- 通过 iOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`
- 通过 macOS：
  - `xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build`

下一轮如果继续按用户这条“后台自动处理”路线推进，最值得优先做的是：

- 真正接入 iOS share extension，让系统分享可以把图片送进当前后台队列
- 再做 `Live Activity / 灵动岛` 方向的进度展示，而不是继续只依赖本地通知

## 2026-06-19 外部接单持久化基础

这一轮没有把进度放回主界面，而是继续沿着“分享进入后台自动处理”的真实方向补底层：

- 新增共享容器与 App Group 基础：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoSharedContainer.swift`
- 新增持久化外部收件箱：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeStore.swift`
- `ExternalPhotoIntakeCenter` 现在不再只靠内存暂存请求：
  - 外部 URL 进入时会优先复制到共享收件箱目录
  - 请求描述会持久化到共享 `UserDefaults`
  - App 下次激活时仍可继续自动消费
- `SettingsService`、`BatchQueueStore`、`PermissionCenter` 已切到共享 `UserDefaults` 入口，给未来 iOS Share Extension 复用默认配置和基础状态留好接口
- `PhotoMemoAppRuntime` / `PhotoMemoRootSceneView` 现在会在激活与初次进入时主动刷新外部接单状态并消费持久化请求

这一步的意义：

- 后面即使分享扩展与主 App 不是同一进程，也已经有可复用的收件箱和配置来源
- 主界面依旧保持“参数设定 + 自定义信息 + 预览”职责，没有重新引入后台进度面板

下一轮如果继续这条线，最合理顺序是：

- 正式新增 iOS Share Extension target
- 让扩展端把共享图片/URL 写入当前收件箱
- 主 App 继续沿现有 runtime 自动入队，不改主界面信息架构

## 2026-06-19 外部收件箱清理补充

这一小轮继续只补后台接单基础，不动主界面信息架构。

新增收口：

- `ExternalPhotoIntakeStore` 现在除了持久化请求，还负责清理自己复制进共享收件箱的源文件
- `BatchQueueStore` 在两条安全终态路径上接入了回收：
  - 单张任务处理完成后
  - 整个 job 被用户取消时

这次特意没有在失败态就删文件，因为失败任务还需要保留源图用于后续重试。

当前共识：

- 只清理 `ExternalIntake` 目录内、由 PhotoMemo 自己复制进去的托管文件
- 不碰用户原始文件路径
- 不影响现有导入、渲染、导出、写回图库行为

## 2026-06-19 外部收件箱孤儿目录整理

这一小轮继续补后台接单地基，目标是覆盖“上次处理中途退出”之后的残留目录。

新增收口：

- `BatchQueueStore` 现在会暴露当前任务仍在引用的托管源图 URL 集合
- `PhotoMemoAppRuntime.refreshExternalIntakeState()` 在每次启动/激活刷新外部接单状态前，会先让 `ExternalPhotoIntakeStore` 扫描 `ExternalIntake` 目录
- 没有任何请求或任务继续引用的孤儿文件/目录，会被自动整理掉

当前共识：

- 正在排队、处理中、失败待重试的托管源图不会被误删
- 只清理共享收件箱里的孤儿内容，不扫描用户原始目录

## 2026-06-19 iOS Share Extension 最小骨架

这一轮开始把真正的 iOS 分享入口接进工程，但仍然坚持“小切片、先求可编译”的节奏。

已落地：

- 新增分享扩展接单服务：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionIntakeService.swift`
- 新增极简分享扩展入口控制器：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtensionViewController.swift`
- 新增扩展专用 `Info.plist` 与 entitlement：
  - `Source/PhotoMemo/PhotoMemo/iOS/ShareExtension/PhotoMemoShareExtension-Info.plist`
  - `Source/PhotoMemo/PhotoMemo/PhotoMemoShareExtension.entitlements`
- `ExternalPhotoIntakeStore` 现在支持：
  - 扩展端先把分享进来的图片复制到共享收件箱
  - 再直接写入持久化请求，而不依赖主 App 进程内状态
- `PhotoMemoiOSApp.swift` 已加编译条件，避免 share extension target 编译时与 app 的 `@main` 入口冲突
- `PhotoMemo.xcodeproj` 已新增：
  - `PhotoMemoShareExtension` target

当前结果：

- iOS 主 app 仍可编译
- 新的 `PhotoMemoShareExtension` target 已可编译
- 当前还有一个非阻塞告警：
  - 扩展 target 的 Copy Bundle Resources 里包含了它自己的 `Info.plist`
  - 不影响当前构建通过，后续可以继续做工程级清理

这一步的真实意义：

- PhotoMemo 已经不再只是“未来可能支持分享扩展”
- 现在仓库里已经有了一个真实、可编译、能把分享图片送进共享收件箱的最小扩展骨架

下一轮如果继续这条线，最值得优先做的是：

- 用真实 `NSExtensionContext` 手动回归分享一张/多张图片的行为
- 继续清理 extension target 当前仍不必要编进来的主 app UI/服务文件范围
- 再决定是否要做“分享成功后自动唤起主 App”这类体验层动作

## 2026-06-19 ExternalIntake 纯临时策略收紧

这一轮根据最新共识，把共享收件箱里的托管源图进一步明确为“纯临时文件”，不再走失败后长期保留路线。

已落地：

- `ExternalIntake` 托管副本在三类终态都会清理：
  - 成功完成
  - 用户取消
  - 处理失败
- 对于这类失败任务，`BatchTaskFailure` 现在会显式标记：
  - `canRetry = false`
- `BatchQueueStore.retryFailedTasks` 只会真正重排那些仍可重试的失败项
- 批量任务持久化前会对终态历史做数量裁剪，避免队列记录无限增长

当前共识：

- `ExternalIntake` 里的托管文件不是长期缓存，也不是恢复仓库
- 真正边界仍然不变：
  - 只能清 PhotoMemo 自己复制进 `ExternalIntake` 的文件
  - 不碰用户原始路径
  - 写回系统相册的成品不当缓存处理

## 2026-06-19 少量失败作为例外处理

这一轮继续沿后台自动处理路线，把“很多照片里只失败 1 张”的表达方式收得更符合真实使用体验。

已落地：

- 当一批任务大多数已成功完成时，不再把整批语义简单打成“失败”
- `BatchJob` 现在会区分：
  - 整批失败
  - 部分完成
  - 大部分完成，仅少量例外
- 通知文案、失败摘要文案都已同步收口：
  - 例如更接近“已完成 99 张，另有 1 张作为例外未处理”
- 对于已经按纯临时策略清掉托管源图的失败项，会明确标记不可重试，不再给出误导性的重试入口

这样处理的原因：

- 用户真正关心的是“成功的大多数已经进相册了没有”
- 少量失败项应该作为例外单独提示，而不是把整批结果整体抹黑

当前共识：

- 成功结果先算成功写回
- 少量失败单独列出
- 失败原因保留可查
- 只有仍具备真实重试条件的失败项，才继续提供重试动作

## 2026-06-19 Share Extension 工程告警收口

这一小轮还顺手把 share extension 的 `Info.plist` 资源告警收掉了：

- 扩展专用 `Info.plist` 已挪到同步组外层：
  - `Source/PhotoMemo/ShareExtension-Info.plist`
- `PhotoMemoShareExtension` target 改为引用这份 plist

当前结果：

- macOS app 可编译
- iOS app 可编译
- `PhotoMemoShareExtension` 可编译
- share extension 原来的 `Info.plist` Copy Bundle Resources 告警已消失

## 2026-06-19 Share Extension 首轮瘦身

这一轮没有改主界面，也没有改真实导入/渲染/导出链路，主要是把分享扩展对主 app 设置系统的依赖先拆薄一层。

已落地：

- 新增轻量共享快照读取器：
  - `Source/PhotoMemo/PhotoMemo/App/SharedBatchConfigurationSnapshotService.swift`
- `PhotoMemoShareExtensionIntakeService` 不再直接依赖完整的 `SettingsService`
- 扩展端现在只通过共享 `UserDefaults` 读取：
  - 模板
  - 徽标
  - 时间点
  - 说明写入开关
  - 相册标识
  然后组装 `BatchConfigurationSnapshot`

这一步的意义：

- share extension 不再为了拿默认配置而拖进整套设置观察/保存语义
- 后续继续瘦 target 时，有了更清晰的共享边界

当前结果：

- macOS app 可编译
- iOS app 可编译
- `PhotoMemoShareExtension` 可编译

下一轮如果继续这条线，最值得优先做的是：

- 继续把 extension target 当前仍然会编进来的主 app 视图/权限/照片库写回相关文件尽量剥离
- 为真实系统分享手动回归做准备

## 2026-06-19 Share Intake 稳定性补强（二次）

这一轮继续沿着 iOS 分享入口做，但重点不是扩功能，而是先把“看不见的坏情况”压下去。

本轮已落地：

- 新增共享相册选择语义：
  - `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAlbumSelection.swift`
- `SharedBatchConfigurationSnapshotService` 不再为了“自动相册”标识去依赖 `PhotoAlbumOption`
- `SettingsService` 也已切到同一套共享相册标识规范化逻辑
- `ExternalPhotoIntakeStore.persistManagedRequest(...)` 在请求列表写入失败时，会立即清理已经复制进去的托管临时文件
- `ExternalPhotoIntakeStore.persistRequest(...)` / `ExternalPhotoIntakeCenter.submit(...)` 都会先做重复 URL 去重
- `PhotoMemoAppRuntime.flushExternalRequests()` 现在会先过滤掉已经不存在的源文件：
  - 全部失效：直接跳过，并清理 PhotoMemo 自己管理的临时副本
  - 部分失效：只把仍然存在的那部分照片入队
- `PhotoMemoShareExtensionIntakeService` 现在返回一个结构化导入结果：
  - `importedCount`
  - `skippedCount`
  - `failedCount`
- share extension 侧的真实行为现在变成：
  - 单个 provider 失败，不再把整次分享直接判死
  - 只要至少有一张成功写进共享收件箱，就算接单成功
  - UI 文案会区分“全部成功”和“部分成功、附带跳过/失败计数”
- 分享 fallback 目前只保留两类：
  - `file URL`
  - `raw Data`
- 已明确**不**使用：
  - `UIImage -> JPEG` 重编码 fallback

这一条很重要，不要为了“更多来源都能进”把它再加回去，因为那样会有两个真实风险：

- 可能丢 EXIF
- 可能在进入 PhotoMemo 之前就已经改变图片二进制内容

当前这一轮的真实意义：

- Main App and Share Extension just completed another Alpha product-refinement slice focused on reduction rather than expansion.
- The biggest visible change is that the app is now closer to a `configuration center`:
  - `MainView` now receives `PersonalProfileStore`
  - a new `我的记录` section is live
  - long-term identity / baby / birthday information can now be edited directly from the main app
- iPhone main UI is no longer centered around the old `preview vs editor` split:
  - it now behaves more like one vertical settings-style flow
  - the preview remains, but it is demoted behind the configuration stack instead of acting like a separate mode
- default style presentation was softened:
  - visible slot titles now read `模块 1 / 模块 2 / 模块 3`
  - the style area is now collapsible and more settings-like
  - “current configuration summary” style repetition has been reduced
- first run was updated toward the newer product model:
  - welcome
  - relationship
  - nickname
  - birthday
  - default anchor explanation
  - destination
  - completion
- Share confirmation also moved one step closer to an Apple-like single-page experience:
  - first-photo preview is now attempted
  - multi-photo shares only preview the first item
  - the page explains that the remaining photos will use the same style
  - button copy now says `开始生成`
  - workflow summary wording was simplified from configuration terminology toward style / album terminology

- Compatibility work landed alongside the UI changes:
  - `PersonalProfileStore.updateProfile(_:)` now exists
  - main-app profile edits still backfill the old settings layer:
    - birthday anchor
    - active slot
    - album selection

- Verification completed for this slice:
  - passed:
    - `PhotoMemo`
    - `PhotoMemoiOS`
    - `PhotoMemoShareExtension`
    - `PhotoMemoTests`

- Important remaining product debt after this slice:
  1. the main app is still not yet fully reduced to the final `Profile / Default Style / Output Settings / Settings / About` structure
  2. anchor / personalized fields / supplemental content / badge are still visible on the main stage rather than pushed deeper into settings hierarchy
  3. Share is now easier to understand, but it still is not yet the final invisible `share -> generate -> save` experience
  4. `MainView+PersonalProfile.swift` is excluded from share behavior with `#if !PHOTOMEMO_SHARE_EXTENSION`; later target-boundary cleanup may still be worthwhile

- Recommended next slice:
  1. continue shrinking the main app surface
  2. make the share confirmation page even more automatic
  3. run real-device UX review specifically against the latest “Apple Settings + Apple Photos share” standard

- 共享收件箱更接近“可靠的临时接单层”，而不是“偶尔会留下垃圾和坏单子的黑盒”
- 失败和部分成功的语义更贴近真实用户感受
- 元数据保留优先级继续压过“表面兼容更多输入”

本轮构建验证：

- 已通过：
  - `PhotoMemoShareExtension`
  - `PhotoMemoiOS`
  - `PhotoMemo`
- 告警情况：
  - macOS 仍只有原来的 destination-selection warning

下一轮最值得优先做的事：

1. 真实设备/模拟器手动回归系统分享一张、多张、部分失效的情况
2. 继续观察 share extension target 当前仍被同步组编进去的主 app 文件范围，评估是否还值得再拆共享边界
3. 如果系统分享来源出现只给 `UIImage` 不给原始文件/数据的 App，再单独设计“拒收并解释原因”策略，而不是偷偷重编码接入

## 2026-06-19 Share Extension 编译面收口

这一轮继续做 share extension，但不是继续加功能，而是把 target 真正压回“共享接单核心”。

本轮已落地：

- 在 `PhotoMemo.xcodeproj/project.pbxproj` 里，为 `PhotoMemoShareExtension` 新增了同步组例外配置：
  - `PBXFileSystemSynchronizedBuildFileExceptionSet`
- 这套例外配置已经把一大批与分享接单无关的文件排出扩展 target：
  - `Views/*`
  - `PhotoMemoApp.swift`
  - `PhotoMemoAppDelegate.swift`
  - `PhotoMemoRootSceneView.swift`
  - `PhotoMemoiOSApp.swift`
  - 大部分 renderers / export / permission / queue / engine 文件
- 这条路已经被证明可行，不需要靠更多 `#if` 去硬隔离主 app UI

这一轮还顺手抽出了一份真正该共享的模型：

- 新增：
  - `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeRequest.swift`
- 原因：
  - 之前 `ExternalPhotoIntakeRequest` 还定义在 `ExternalPhotoIntakeCenter.swift`
  - 一旦扩展 target 把 `ExternalPhotoIntakeCenter.swift` 排掉，`ExternalPhotoIntakeStore` 就失去请求模型定义
- 现在共享边界更干净了：
  - `ExternalPhotoIntakeStore` 依赖共享请求模型
  - `ExternalPhotoIntakeCenter` 只负责主 app 侧的提交与 drain 协调

当前最直观结果：

- `PhotoMemoShareExtension.SwiftFileList` 目前约 `19` 行
- 也就是 share extension 现在主要只编：
  - 共享收件箱持久化
  - 共享默认配置快照读取
  - share extension 自己的 intake / view controller
  - 少量必要模型

这一步的意义很实在：

- 真正把“主 app 校准中心”和“iOS 分享接单入口”拆成了两个更清楚的责任面
- 后续如果分享入口出 bug，不需要再怀疑 `MainView`、预览、模板视图是否拖进 target 造成噪音
- 后续继续做 iPhone 分享流、后台接单、失败例外处理时，工程复杂度会低很多

本轮还补了一个小体验修正：

- share extension 的成功提示现在只会展示非零的 `跳过 / 失败` 计数
- 不会再出现“失败 0 张”这种不自然提示

本轮构建验证：

- 已通过：
  - `PhotoMemoShareExtension`
  - `PhotoMemoiOS`
  - `PhotoMemo`

下一轮最值得继续的方向：

1. 真机/模拟器手动验证分享 1 张、多张、部分失效、重复来源
2. 视情况继续把扩展 target 资源面也收一轮，例如是否还需要把共享 asset/catalog 继续缩小
3. 如果真实分享来源暴露出新的 provider 形态，再决定是否补更明确的拒收提示或来源兼容策略
