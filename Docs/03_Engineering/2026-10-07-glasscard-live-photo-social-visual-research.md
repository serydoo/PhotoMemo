# GlassCard / Live Photo：社交实际画面研究与下一步方案

日期：2026-10-07。源码检查点：`e83c7e70`，版本 2.3.6（124）。状态：公开产品资料、既有小红书素材及用户提供的已登录浏览器原帖已复核；新增三篇相关原帖的实际画面与可见评论；生产实现未开始。

## 研究范围与决策门槛

主线为 Product Loop：以 iOS 27 原生 Liquid Glass 为首要参考，从实际照片和运动样本提炼可复用材质特征，重现参考视觉质感。用户于本轮明确：全场景共用材质，可读性取舍交给用户，不建立场景专用方案或自动保护模式。媒体配对、编码尺寸、性能和色彩属于独立 Engineering Loop。当前阶段允许研究规格和本地诊断，不用竞品宣传授权生产管线重写。

保持已接受的 GlassCard 布局、四类表达、Memory Engine 语义、Layout Engine 几何归属、配置快照、原片保护与 Apple Photos 工作流。没有新增 Live Photo 专用 Renderer，也不将 Minimal 合并到 GlassCard。材质候选先研究，接受后再讨论持久化兼容；不添加第五种表达。

## 来源及可证范围

### 本地已有小红书画面

来源目录：`/Users/rui/Desktop/苹果液态玻璃效果素材`。文件名保留作者及题目，但没有完整原帖 URL/访问令牌；不推断发布日期、工具版本或同名产品身份。

- 44 张 JPG，全量缩略检查；SHA256 去重后 43 张。
- 40 段 MP4，全量通过 AVFoundation 读取轨道属性；去重后 39 段。
- 9 段代表视频，各取 5 个时间点（片长约 5%、25%、50%、75%、95%），实际解码 45 帧并查看全幅与玻璃区域。不是逐帧无闪烁认证。
- 所有 40 段 MP4 均没有音轨；时长 1.587–3 秒。名义帧率按整数归并为 20fps×1、25fps×1、28fps×2、29fps×19、30fps×17。不能反推源 Live Photo 的帧率或音频能力。
- MP4 尺寸为 1440×1080（8）、1080×1440（26）、1080×1080（1）、980×1744（1）、1080×1442（1）、1920×1080（1）、1902×1068（1）、952×714（1）。平台下载、转码与采集路径可能影响尺寸；不称其为原始 pairedVideo。
- 分离的 JPG/MP4 不是已验证的原始 Live Photo 对，不能证明 content identifier、still-image-time、EXIF、HDR、音频或 Photos 可用性。

索引和证据仅保留本地：`/tmp/MemoMarkGlassSocialResearch/inventory.json`、`videos.json`、`contact-1.jpg` 至 `contact-4.jpg`、`motion-{index}.jpg`、`glass-bars.jpg`。解码脚本 `extract.swift` 也在该目录，不加入产品 target。原素材、截图和抽帧均不进入 Git。

### 本轮在线复核

- [照片液态玻璃水印，中国区 App Store](https://apps.apple.com/cn/app/id6807027325)：浏览器实际打开并查看截图及版本 1.2 更新说明。公开声明清透/柔和、胶囊/圆角矩形、多个物理效果参数及 App 内 Live Photo 全画面/音频处理。新增自定义 Logo、分隔线和右侧信息排版；这与 MemoMark 已有能力重叠，不能当成尚未实现的差距。
- [开发者支持页](https://iyaway.github.io/PhotoLiquidGlass/support/)将快捷指令描述为普通照片批处理，将 App 内编辑描述为支持 Live Photo 画面/音频。VU storefront 文案另外宣称 V2 快捷指令 Live Photo；来源存在口径差异，暂不宣布其所有入口具有相同能力。
- [PhotoDateStamp](https://apps.apple.com/tm/app/photodatestamp-exif-frame/id6760278393)宣称 Live Photo、Photos 扩展和批处理；没有本轮同源导出或资源回读证据。
- 小红书 MCP 登录失效；随后通过用户提供的已登录 in-app browser 正常阅读搜索结果和原帖，无需重新扫码。页面的点点 AI 汇总不是原帖证据，其自动化、系统版本和实况支持描述未作为事实采纳。
- Exa 检索了小红书和 B 站线索。结果多数是 UI 玻璃实现或水印移除，不纳入照片输出视觉结论。B 站平台后端不可用，本轮未观看新的 B 站照片水印演示。

## 实际画面观察

编号对应本地 inventory；所有描述为画面观察，机制推断单列。

| 样本 | 画面观察 | 对 MemoMark 的价值 |
|---|---|---|
| 1，MetroTooCold 山雾 | 玻璃内部较柔和，文字与边缘清晰；5 帧的文字结构保持固定 | 柔和材质作为对照；清透与阅读性的取舍由用户决定 |
| 2，MetroTooCold 鸽子/树干 | 底层树干线条在玻璃内出现明显弯曲和延伸；鸟运动时背景表现更新 | 可观察到透镜感；没有未经处理的同帧，不能证明精确折射函数或强度 |
| 10，一碗鸡蛋耿 椰树 | 亮天空与黑树干在玻璃内强烈穿透，右侧白字部分被亮区域淹没 | 记录清透效果在高反差背景的阅读取舍，不自动加深底板 |
| 19，xx每天都想瘦 岩石/海浪 | 玻璃内岩石纹理弯曲，随画面运动变化；信息位置在抽帧中保持固定 | 背景响应与前景稳定可同时成立，不必给文字附加运动 |
| 20，忧郁的脚皮 水面 | 玻璃色调融入绿色水面，边缘仍可辨认 | 色彩融入比强白色描边更自然；应检查饱和背景下的白字 |
| 24，忧郁的脚皮 浪花 | 亮浪花经过文字区域，不同抽帧的文字可辨性变化明显 | 必须验收全段的困难画面，不能只验封面 |
| 30/31，Song哥 天空/湖面 | 底层更柔和，纹理干扰较少，二级字保持较清楚 | 已有排版接近这类结构；下一步更适合优化材质与播放一致性 |
| 37，小蚁手机万达坊店 白云 | 透过玻璃能看到亮云和建筑，白字与亮云重叠时较弱 | 晴天建筑、白衣、室内窗边要进入困难样本矩阵 |

多张图来自相似胶囊/两列/标识结构，可能使用同一类快捷指令或工具；不能将 44 个文件当作 44 个独立竞品，也不能以这些精选风景图推断全体用户偏好。家庭/人物主体证据不足，新增研究应补齐白衣孩子、玩具、室内逆光和人脸邻近底栏的画面。

## 当前 GlassCard 的源码事实

- `NativeBackdropMaterialRenderer.swift` 当前使用 `.glassEffect(.regular)`、显式 dark colorScheme、opacity 0.88；原生材质限 iOS/macOS 26+。这不是简单固定 alpha 黑矩形，但当前没有向用户提供清透/柔和两个已接受选项。
- `NativeBackdropVideoCompositor.swift` 对当前源帧进行变换后重新生成玻璃 patch；文字/Logo 的不可变前景在 instruction 初始化时准备。逐帧动态背景已经存在，不应再次作为“新增能力”立项。
- 当前 native raster 路径先将完整画布转为 CGImage，然后在 MainActor 上使用 SwiftUI ImageRenderer 生成完整画布，最后裁剪玻璃区域。存在可测量的优化机会；未完成同设备旧/新对比，不宣称已定位唯一瓶颈。
- native compositor 使用 8-bit SDR/sRGB 边界，拒绝无法保真的 HDR/P3/宽色/未知等输入。不能照竞品泛称 Live Photo 就扩大色彩支持。
- `LivePhotoVideoCompositionInput.swift` 会插入源音轨。源码有音轨路径不等于每种来源和 Photos 回读都已验证。
- Layout Engine 已持有 panel、文字、标识和分隔线几何，`GlassCardResolvedPresentation` 是共享 resolved plan。保持已接受的排版，本轮不再次调整尺寸或位置。
- 配置 `MemoryCardPreviewSurface` 的当前校准画面为静态呈现；本轮未发现 PHLivePhotoView 播放入口。完整 Live Photo 播放检查有系统组件可复用，但新增 UI/缓存应有单独规格。

性能/输出尺寸来源为 2026-10-06 的既有真机记录，不是本轮新测量：三轮六次 SDR 副本导出约 2.12–2.37 秒，累计进程 RSS 峰值约 718MiB；实际 motion 4284×5712→2880×3840、4032×3024→3840×2880。累计 RSS 不等于单任务独占峰值，still 和 video 也不必像素尺寸相同；必须明确实际输出和缩放契约，而不是强制把视频升采样到 still。

## 下一步落实顺序

### 1. 建立全场景共用材质与静动切换基线

只使用明确授权且未经水印处理的本地原片/真实 Live Photo；不把社交水印输出当成“原图”重新叠一层。覆盖柔和天空、白云/白衣、密集树叶/玩具、浪花/快速运动、夜景、室内窗边，横竖比例与长中文/英文。

同源三阶段查看：配置静态预览、处理后 still、Photos 中开始/中间/结束及关键帧前后。归一化坐标检查文字/Logo/圆角，检查播放前后亮度/玻璃质感是否突变。输入方向、motion 尺寸、音轨、时长、配对 ID、still-image-time 和 capture date 另有回读证据。不能用社交 MP4 没声音给竞品判音频失败。

### 2. 先关闭输出尺寸与资源成本的工程问题

先只增加研究测量：源/请求/实际尺寸、实际帧率/时长、玻璃 raster 的 MainActor 时耗分布、整体导出时间、任务期间 physical footprint 和并发在途帧。高水位记录与任务采样分别报告。

明确视频编码缩放的允许范围、归一化排版映射、失败/告知边界；不改 capture time 或画面意义。随后再考虑带采样边界余量的局部材质绘制（ROI + halo），同时保留 full-canvas 对照。裁剪可能改变 blur/refraction/阴影，须证明 patch/边缘/still-motion parity 后才替换。禁止为了提速缓存首帧玻璃或跳过某些帧的水印。

### 3. 两个有限材质候选，先比较再接受

- 柔和：以当前 regular 为比较基线，研究原生完整呈现及轻/深色外观的材质差异。
- 清透：研究 Apple 原生 `.clear` 的完整透光、边缘折射和厚度，不自动添加压暗/阅读保护层；降低整个合成结果的 opacity 不能当成同等实现。

Apple 官方 [Glass.clear](https://developer.apple.com/documentation/swiftui/glass/clear) 明确建议在 clear 玻璃下提供压暗层或其他处理以保持阅读性。官方例子里的数值不是 MemoMark 默认值，不直接复制进生产。

两个候选共享同一几何、文字、Logo、颜色边界和 snapshot。首次研究不自动逐帧切换 clear/soft、不逐帧翻转白字/黑字，避免人为引入“呼吸”和闪烁。材质随背景更新，但选定材质和前景排版保持稳定。接受门槛是参考材质特征、边缘自然、静动一致和资源成本；阅读性只记录取舍，由用户选择，不成为暗化清透候选的自动门槛。

### 4. 增加真实结果的播放检查，保持流程简洁

评估在现有完整结果检查中按需使用 [PHLivePhotoView](https://developer.apple.com/documentation/photosui/phlivephotoview)：原生长按播放、Live 标识和声音。播放明确对应冻结快照生成的真实结果；草稿变化需失效，避免静态显示新配置、动态播放旧配置。默认按需生成/复用单个检查结果，不为每次击键重新导出完整视频，也不新增相册管理页。

[PHLivePhotoEditingContext](https://developer.apple.com/documentation/photos/phlivephotoeditingcontext)提供 still/video frameProcessor 和预览能力，可以作为隔离技术探针；不能因此把当前创建新资产改成回写原片的编辑流程，也不能推断其替 MemoMark 保证 HDR/EXIF。

## 接受标准与延后项目

研究结果以同源基线比较、真实 iPhone、Photos 配对回读和所有者观看为准。工具链/host 自动化不能替代最终播放接受。没有“比竞品更无损/更快”的对外结论。

现阶段延后：六个材质滑杆、自由拖动布局、额外滤镜、Logo/文字随播放变形、第五 Renderer、凭效果名称开放 HDR/P3、重做 Share/Shortcuts。MemoMark 的优先价值仍是原拍摄时间与人的时间答案在静态和动态照片中都清楚、安静地保留下来。

本轮只新增本研究记录与本地证据；没有修改产品 Swift、配置 schema、Photos 资产或商店状态，没有提交/推送本研究文件。今日新增三篇小红书原帖的实际画面和可见评论已补齐；网页 LIVE 标识不能替代原始 Live Photo 配对、声音和颜色验证。

## 用户提供搜索页后的新增原帖核对

2026-10-07，经用户已登录浏览器读取，未发送私信、评论、关注或点赞。记录公开 canonical URL，不保存访问令牌到 Git。

1. [太阳暖心：苹果液态玻璃水印照片](https://www.xiaohongshu.com/explore/6a8d3e04000000002b024400)。查看 1/2 海面、2/2 山景，两张均带 LIVE 标识。海面玻璃区域呈现明显纹理拉伸；第二张浅色水面上的玻璃整体更亮，白字局部更难辨认。没有干净原始帧，不能反推出具体折射算法。可见评论请求地点名称代替坐标，作者回复可以改文字。大量求教程评论和作者邀请私信，说明教程获取存在门槛，不能把全部评论数量当成视觉好评。
2. [极影相机：这个液态玻璃水印给到夯](https://www.xiaohongshu.com/explore/6a9e6f8e000000001103326e)。查看 1/9 雨滴和 2/9 树叶逆光照片，均带 LIVE 标识，浅色玻璃透出水滴/树叶，中心品牌 Logo 较大，参数小且密。文案宣称 Live 图与 iOS18+，这是产品宣传，不等于系统原生 Glass API 支持版本。可见用户报告字小、上下错位、机型不符、Logo 找不到，作者针对错位追问 4800 万像素及复现频率。此处属于用户反馈，未独立复现；可转为 MemoMark 验证场景，不宣称竞品已确认缺陷。
3. [豆米豆米：iPhone液态玻璃水印，好看！无需设置指令](https://www.xiaohongshu.com/explore/6ac474330000000018006363)。页面标记昨天 12:08；查看 1/4 夜间灯光，深色柔和胶囊使白字更清楚。介绍 Photohub、四种处理模式、拖动/捏合/吸附、坐标或地名、Live 导出等待、iOS26+液态玻璃。功能只按作者声明记录，未安装或同源导出测试。文案中的 Duo 机型名称是水印自定义选项，不能证明 Duo 自适应界面能力。

新增决策：阅读性验证必须覆盖浅色水面、白衣、窗边、雨滴、树叶逆光；同时覆盖长中文地名、真实 EXIF 设备信息、24/48MP 和用户 Logo。固定玻璃布局，保留原生材质背景响应；不依据场景自动加深/切换用户材质，避免逐帧改变文字/Logo位置、字号或颜色。展示产品差异时突出人的时间答案及可直接使用的原生流程，不能仅凭搜索热度或 LIVE 标签推断保真能力。

## 2026-10-07 所有者方向修订：iOS 27 原生材质优先

本节覆盖此前把“阅读保护”作为清透接受门槛的建议。研究场景只用于观察同一套材质，不派生海面/人像/室内专用方案。清透与柔和由用户选择；不依据场景或逐帧亮度主动改深底板。

### 本轮新增事实

- 用户 ZIP 共 44 JPG、40 MP4；排除 __MACOSX 条目后，84 个媒体条目的 SHA256 全部匹配此前已分析本地目录。无需重复解压/重复观看或要求重发。核对报告 `/tmp/MemoMarkGlass27Research/archive-check.json`。
- 当前 Xcode 为 `/Applications/Xcode-beta.app/Contents/Developer`，iPhoneOS SDK 27.2。SDK SwiftUICore 的 Glass 定义仍为 regular/clear/identity、tint 与 interactive，availability iOS26+；此定义未暴露折射、厚度或系统透明度滑杆参数。不能把系统设置滑杆等同于 app 可调用的导出参数。
- [WWDC26 What’s new in SwiftUI，2:12](https://developer.apple.com/videos/play/wwdc2026/269/)介绍更新的 Liquid Glass 外观及系统采用路径；运行时系统材质与导出位图结果仍需分开验证。较新 SDK 编译不等于旧系统自动拥有新系统材质。
- [Apple HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)区分 regular/clear，clear 用于视觉丰富的媒体背景，系统外观/辅助功能可能影响材质。HIG 的压暗建议属于 UI 可读性指导，并非 MemoMark 照片输出的强制规则；记录这种使用边界，不宣称导出底栏是 Apple 官方规定。
- 当前 production 强制 dark + opacity0.88 是既有实现事实，不宣布其本身是缺陷；需同源 A/B 测量才能决定是否改变。opacity 降低作用于合成 patch，不能等同于增加玻璃本身的透光率。

### 研究候选与接受方式

同一 resolved geometry、背景、内容和前景下比较五个候选：current regular/dark/0.88；regular/dark/1；regular/light/1；clear/dark/1；clear/light/1。候选不是五个用户选项，不持久化，不加入产品 target，不重复水印处理参考输出。固定材质和外观贯穿同一次 still/motion 结果，避免静态与动态由不同设备设置或绘制环境意外分歧。

按维度比较：背景纹理传递、边缘区域纹理偏移、边缘高光与过渡宽度、内部色调/柔和程度、轮廓连续性、播放时背景响应及前景稳定。使用同源干净背景才能测量纹理位移；社交处理图只提炼特征，不能拟合出精确折射参数。读字难度附记，所有者决定取舍。

已执行隔离 API 探针：`/tmp/MemoMarkGlass27Research/NativeGlassCandidates.swift`，使用选定 iPhoneOS27.2 SDK，arm64-apple-ios26.0 typecheck，exit0。证明两个原生变体与外观/合成透明度候选可编译；不证明 iOS27真机外观、ImageRenderer光学保真、视频性能或 Photos 配对。没有运行模拟器，没有修改/安装产品。

下一实现增量：先在独立研究路径为既有 renderer 提供候选输入，不改变配置 schema 或已保存预设；取得 iOS27 真机同源 static/逐帧动态样本与 Photos 回读，再确定两种用户材质和兼容默认值。性能与编码尺寸作为独立工程门槛记录，不能用修性能静默改变视觉效果。

## iOS27 系统外观滑杆：官方确认

用户录屏来源由所有者确认为 iOS27 测试版本的设置 → 外观 → Liquid Glass。18.235秒、16个时间点观察可见动态背景预览和连续滑杆；只记录外观，不由视频反推公开 API。

[WWDC26 Platforms State of the Union](https://developer.apple.com/videos/play/wwdc2026/102/)的设计段明确说明：改善复杂背景的扩散表现、加入更暗的边缘和更亮的镜面高光；设置中新滑杆从 ultra clear 到 fully tinted；已使用 Liquid Glass 的应用在新系统运行时自动获得改进，无需重新编译。系统辅助功能设置仍影响材质。

[Apple Support About iOS27 Updates](https://support.apple.com/en-gb/149076)也确认新版 Liquid Glass 和设置滑杆。此来源说明系统功能，不提供 app 自定义等效滑杆、折射/厚度参数或照片导出规范。

[HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials)继续规定 UI 中的内容/控制层分离、克制使用、regular/clear 用途和系统偏好响应；页面 change log 最后列出2025-09-09，因此不称其为专门为iOS27滑杆新增的HIG章节。系统 clear/tinted外观偏好与Glass.clear/regular API变体不作一对一映射；Glass.tint(Color)不是这个系统透明度滑杆的替代接口。

应用到本研究：光学目标加入暗边缘、明亮镜面高光与连续材质变化；UI遵守系统偏好与辅助功能，照片输出材质由用户保存的配置决定。系统偏好是否会影响ImageRenderer及跨设备静态/动态输出需要实测；不宣称已经可完全冻结系统滑杆效果，不根据HIG自动改深用户的清透照片。


## 最新范围收敛：预览形式暂存

所有者要求先将系统式观察窗口/背景移动/材质切换纳入单项研究材料，保持简单，回头再研究。见 [玻璃质感切换单项研究](2026-10-07-glass-texture-switching-research.md)。此前候选和下一实现步骤不构成当前执行承诺；现阶段只保留材料，不推进复杂预览或配置实现。
