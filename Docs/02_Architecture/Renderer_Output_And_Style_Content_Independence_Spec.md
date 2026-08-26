# Renderer 输出与样式内容隔离规范

## 背景

2026-08-26 真机检查发现两个相互关联但责任不同的问题：

1. 经典白 / 基础白在 Live Photo 动态资源输出时，底部边框出现黑色空区，且没有
     正常显示底栏内容。
2. 极简样式的导出只读取智能输出结果，用户在卡片内容编辑区域组合的内容无法展示。
3. 卡片样式之间共用一份编辑模板；切换样式会让两种样式互相覆盖内容。

## 产品契约

- 每个 Renderer 必须同时定义静态图和 Live Photo 使用的同一份
  `PresentationArtifact`，不能让媒体层从另一种 Renderer 的最终图片反向裁剪布局。
- Classic White / 基础白是追加底栏的完整画布输出：照片区域和底栏区域由该样式的
  Layout Engine 一起定义，底栏背景必须是不透明的样式背景色，底栏内容必须来自
  Classic White 当前模板的四个内容区域。
- Minimal / 极简是原照片同画布输出：只显示该样式自己的单一组合内容，当前产品
  内容编辑区域中的组合顺序、文字和变量解析结果就是唯一内容来源；不能被 Classic
  White 的智能结果覆盖。Minimal 的照片说明也只取 slot A，不再从 slot D 借用内容。
- 每种卡片样式拥有独立的内容模板。用户切换样式时，编辑器切换到该样式保存的内容，
  切回原样式时内容完整恢复。
- 已有只有一份模板的配置不应丢失。首次读取时，旧模板作为缺失样式的兼容回退；下一次
  保存时写入两套样式模板。
- 版本化配置的生产快照必须按当前 presentation route 选择对应样式模板。

## 样式内容契约

`RecordCardPresentationStyle.contentContract` 是样式内容的唯一映射入口，至少声明：

| 样式 | 可编辑区域 | 实际渲染区域 | Apple Photos 照片说明来源 |
| --- | --- | --- | --- |
| Classic White / 基础白 | slot A、B、C、D | slot A、B、C、D | slot D |
| Minimal / 极简 | slot A | slot A | slot A |

这里的“区域”是样式自己的内容投影，不是全局共享的编辑缓冲。编辑器、预览、静态图、
Live Photo overlay 和 EXIF/IPTC/PNG description 写入都必须沿用同一份契约。未来 Renderer
若拥有 2 个或 3 个自定义区域，只需在该 Renderer 的样式契约中登记对应区域和照片说明
来源；不得在渲染器或导出服务中重新猜测 slot A-D。

## 工程边界

- Renderer 负责把自身的 Layout Engine 结果转成 `PresentationArtifact`。
- `RecordCardPresentationPlanner` 是样式到 Artifact 的唯一注册点。
- Live Photo still/video composer 只消费 Artifact，不判断具体样式。
- `MemoryConfigurationRecord.Editor` 负责持久化样式模板集合，并保留旧 `template`
  字段作为兼容入口。
- Configuration Center 负责当前样式编辑草稿与样式草稿集合之间的切换，不改变
  Memory Engine、PhotoKit、原图保护和保存事务的所有权。

## 迁移与验证

- 旧配置解码：`template` 可作为尚未建立样式模板的兼容回退，但只在配置投影阶段
  物化为各样式自己的值；运行时不能让一个样式读取另一个样式的区域。
- 新配置保存：写入 Classic White 与 Minimal 两个独立模板，并让兼容 `template`
  指向当前选中样式。
- 验证必须覆盖：
  - Classic White Artifact 的照片区 / 底栏区、白色背景和内容层；
  - Minimal Artifact 的同画布透明背景和用户组合内容；
- Live Photo still/video 共用同一 Artifact 几何；
- 样式切换、保存、重新加载后的内容互不覆盖；
- 旧配置单模板解码与再次保存后的迁移。

## 本轮实现落点

- `RecordCardPresentationPlanner.artifact(for:canvasSize:)` 现在是静态图和
  Live Photo 的共同输出入口。Classic White 的完整白色底栏由 Renderer 自己生成，
  Live Photo 不再从最终静态图反向裁剪底栏。
- `RecordCardPresentationStyle.contentContract` 统一声明可编辑区域、实际渲染区域和
  Apple Photos 照片说明来源。Minimal 的 `informationText(for:)` 与照片说明解析均只读取
  slot A；不再以 slot D 作为运行时回退。
- `MemoryConfigurationRecord.Editor` 新增按
  `RecordCardPresentationStyle` 保存的模板集合；旧 `template` 字段继续保留，
  读取旧配置时回退，保存时写入两套模板。
- Configuration Center 在样式切换时先提交当前草稿，再恢复目标样式草稿，并在保存
  时合并当前样式的最新编辑缓冲，避免切换过程中产生覆盖窗口。
- `RecordCardBuildService` 将当前样式契约声明的区域投影为导出说明，静态图和 Live
  Photo 通过同一个 `RecordCard.exportDescriptionOverride` 进入元数据写入，确保
  Apple Photos 照片说明与卡片实际内容一致。

## 验证状态

- Renderer、样式持久化、配置生命周期 focused tests 已通过。
- macOS `MemoMark` Debug build 和通用 iOS `MemoMarkiOS` Debug build 已通过。
- 实体 iPhone 17 Pro Max 的签名安装、启动和版本核对将在本轮候选构建完成后更新到
  `Docs/CURRENT_STATUS.md` 与 `HANDOFF.md`；Live Photo 真实相册回读仍需产品负责人
  在设备上人工验收。
