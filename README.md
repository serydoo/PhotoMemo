# PhotoMemo

## PhotoMemo Design Mission

Configure once. Remember forever.

一次设定，永久记录。

PhotoMemo is a memory generator built around Apple Photos, not a photo editor.

PhotoMemo 不是修图工具，而是围绕系统相册构建的记忆生成器。

它的目标不是修图、滤镜或云相册，而是让每一张照片都能带上时间、设备、拍摄信息，以及和人生节点有关的记忆语义。

这也是 PhotoMemo 目前最重要的产品承诺：

- 第一次打开，只做一次个人档案与默认风格准备
- 日常使用，尽量都从系统相册分享完成
- 用户不需要反复配置，只需要持续记录生活

对内，PhotoMemo 也遵循一条唯一主链路：

`Import -> Metadata -> Memory -> Renderer -> Export -> Share`

这意味着渲染器很重要，但它只是最终输出层；真正的产品核心，是一条稳定、可解释、可长期维护的记忆工作流。

## 项目定位

**PhotoMemo = 一款完全本地优先运行、围绕 Apple Photos 构建、基于 EXIF 和时间锚点生成记忆结果的本地产品。**

适合：

- 宝爸宝妈
- 成长记录用户
- 摄影爱好者
- Apple Photos 用户

不是：

- AI 修图软件
- 滤镜软件
- 云相册

而是：

- 照片信息纪念卡生成器
- 成长语义照片工具
- 本地照片回忆增强器

## 项目出发点

很多照片拍完以后，用户很快就失去了最重要的上下文：

- 什么时候拍的
- 用什么设备拍的
- 当时孩子多大
- 这是某个纪念日的第几天
- 发出去之后，原来的信息几乎都消失了

PhotoMemo 想解决的不是“参数展示”本身，而是“照片记忆解释”。

**照片记录的是瞬间，Memory Engine 记录的是时间。**

例如一张拍摄于 `2025-06-01 18:25` 的照片，如果孩子出生于 `2024-05-20`，用户最终看到的，不应该只有相机参数，还应该包括：

```text
宝宝 1岁12天
2025.06.01 18:25
iPhone 17 Pro Max
ISO100 F1.78 1/250 24mm
```

## 核心原则

### 1. Local First

- 核心流程完全本地运行
- 不依赖云端
- 不上传照片

### 2. Metadata Driven

- 以 EXIF 为核心输入
- 优先使用拍摄时间、设备型号、镜头、曝光参数、GPS 等真实元数据

### 3. Memory First

- 不是单纯堆参数
- 更重视“这张照片发生在人生哪个节点附近”

### 4. Non-Destructive

- 不修改原图像素
- 生成一张新的成品图
- 保持系统图库中的原图可继续独立管理

### 5. Apple Photos Friendly

- 面向 Apple Photos 使用习惯设计
- 目标是让处理后的图片仍然适合继续在系统图库中检索、归档、回看

## 当前产品形态

PhotoMemo 现在已经不是单纯的“给照片加边框”工具，而是三层产品模型：

### 1. Personal Profile

负责那些很少变化、但会长期影响结果的个人信息：

- 你是谁
- 宝宝昵称
- 生日
- 默认相册
- 默认风格

### 2. Style

负责一张记忆卡如何被生成：

- 布局
- 模块排列
- 底栏结构
- 变量显示
- Logo 标识

### 3. Workflow

负责日常真正发生的使用路径：

- Apple Photos
- Share
- PhotoMemo
- Generate
- Save back to Photos

也就是说，主界面不是未来的“批量作业台”，而是**工作流准备中心**；真正的一线入口会越来越偏向系统相册里的分享动作。

## 智能模块与应用场景

PhotoMemo 的时间锚点系统，是当前项目最重要的差异化能力之一。

它会把一张只有拍摄时间的照片，转换成“发生在某个重要人生节点前后多久”的记忆表达。

当前已落地或已设计的智能时间结果包括：

- `年岁`：`1岁2个月18天`
- `纪念时长`：`2年4个月18天`
- `已过天数`：`已过32天`
- `倒计时`：`还有86天`
- `第几天`：`第128天`
- `周数`：`24周3天`
- `月龄`：`38个月`
- `里程碑`：`100天`、`1周年`

典型场景：

- 孩子成长：出生第 386 天、今天 1 岁 2 个月 18 天
- 恋爱纪念：在一起 1000 天、领证第 200 天
- 家庭生活：搬家第 30 天、第一次出游第 7 天
- 倒计时：距离高考还有 86 天、距离毕业还有 40 天

这些模块只输出“时间结果本身”，前后文由用户自由组合，避免模板文案被写死。

## 当前界面与布局方向

当前版本的信息卡采用底部固定信息区的极简布局，整体视觉基调参考：

- Apple Human Interface
- MUJI
- 极简摄影册

关键词：

- 干净
- 克制
- 高级
- 不花哨

当前主信息区按四个可编辑区域组织：

- 左上：标题 / 主体信息
- 左下：时间 / 地点 / 记录语句
- 右上：EXIF 参数
- 右下：智能纪念信息

## 当前代码结构

核心模型与引擎：

- `Source/PhotoMemo/PhotoMemo/Models/PhotoMetadata.swift`
- `Source/PhotoMemo/PhotoMemo/Models/RecordCard.swift`
- `Source/PhotoMemo/PhotoMemo/Engines/AnchorEngine.swift`

核心服务：

- `Source/PhotoMemo/PhotoMemo/Services/PhotoMetadataReader.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoImportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/RecordCardBuildService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PhotoLibraryExportService.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchQueueStore.swift`
- `Source/PhotoMemo/PhotoMemo/Services/BatchProcessingCoordinator.swift`
- `Source/PhotoMemo/PhotoMemo/Services/PermissionCenter.swift`

核心渲染：

- `Source/PhotoMemo/PhotoMemo/Renderers/RecordCardRenderer.swift`
- `Source/PhotoMemo/PhotoMemo/Renderers/ClassicWhiteRenderer.swift`

App 入口与外部接单：

- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoApp.swift`
- `Source/PhotoMemo/PhotoMemo/App/ExternalPhotoIntakeCenter.swift`
- `Source/PhotoMemo/PhotoMemo/App/PhotoMemoAppDelegate.swift`

## 当前进度

### 已完成

- [x] macOS SwiftUI 应用基础架构
- [x] 单张预览链路：导入照片 -> 读取 EXIF -> 生成卡片 -> 预览
- [x] `PhotoMetadata` 数据模型
- [x] `PhotoMetadataReader` 读取拍摄时间、设备、镜头、ISO、光圈、快门、焦距、GPS
- [x] 时间锚点系统与智能模块结果计算
- [x] 四个自定义区域的模板编辑能力
- [x] 底部信息卡渲染与导出图片
- [x] 写入系统图库与指定相册
- [x] 默认 `PhotoMemo` 相册策略
- [x] 外部文件接入后台队列
- [x] 后台批量任务基础模型、状态机与通知
- [x] 主界面权限引导与系统相册 / 通知权限状态管理
- [x] 项目内 `.codex/skills` 基础 AI 协作体系

### 正在进行

- [ ] 权限流程、相册刷新与后台处理体验继续打磨
- [ ] 预览效果与最终导出的一致性继续校准
- [ ] 边框高度、字体、区域间距等视觉参数继续根据样例图精修
- [ ] 元数据保留策略继续增强
- [ ] 主界面交互继续为未来 iOS 迁移做简化

### 尚未完成但方向明确

- [ ] 将 GPS 数值稳定转成更友好的地点文案
- [ ] 更完整的模板体系
- [ ] 更自然的系统分享入口
- [ ] iOS 版本适配

## 关于“已完成”和“目标”之间的区别

下面这些方向已经成为项目原则，但其中有些还在持续增强，不应被误读为“百分之百已经最终实现”：

- 原图不被修改：**已成立**
- 本地运行：**已成立**
- 不上传照片：**已成立**
- 尽量保留元数据与图库可管理性：**已落地基础能力，仍在继续完善**
- Apple Photos 友好：**已开始落地，仍在继续增强**

## 下一阶段开发重点

当前最重要的不是继续扩功能，而是把已经成形的主链路做稳、做准、做顺手。

优先顺序：

### 第一优先级

- 权限与首次运行体验稳定
- 预览与导出一致性
- EXIF 与智能模块结果准确性
- 写回图库后的元数据可用性

### 第二优先级

- 模板系统细化
- 地点信息增强
- 后台处理可靠性与失败恢复

### 第三优先级

- 更完整的 Apple Photos / 分享入口
- iOS 迁移准备
- App Store 上线前整理

## 版本节奏

从 `v0.7.0` 开始，PhotoMemo 进入明确的版本化节奏，后续优先使用：

- `v0.7.x` Memory Engine 持续完善
- `v0.8.x` iOS Experience
- `v0.9.x` Template Ecosystem
- `v1.0.0` App Store readiness

旧的内部 `Sprint-*` 记录会继续保留在历史文档里，但新的对外交付、CHANGELOG 和 Release 应以版本号为主。

## 未来路线

### V1.0

完成一个可靠可用的本地版 PhotoMemo：

- 模板校准
- 智能时间模块
- 真实 EXIF
- 导出新图
- 保存图库

### V1.5

继续强化与 Apple Photos 的衔接体验：

- 更顺手的导入 / 分享入口
- 更稳定的图库索引与说明写入

### V2.0

扩展模板系统：

- 成长模板
- 旅行模板
- 摄影模板
- 纪念日模板

### V3.0

增强批量生产能力：

- 多张照片连续处理
- 后台任务状态管理
- 更完整的失败重试与恢复机制

## 一句话总结

**PhotoMemo 正在从“照片加信息边框的小工具”，进化成一款完全本地优先、基于 EXIF 与时间锚点、为家庭与成长记录场景生成高品质纪念照片卡的 macOS 原生应用。**
