# MemoMark Iconography Reserve

Status: V3 visual-system research reserve

This catalog standardizes the small semantic icons used by the Configuration
Center and adjacent iOS surfaces. It does not authorize a broad UI rewrite.
Adoption should happen one bounded surface at a time with physical-device
verification.

## Visual Language

The Configuration Center is the reference language:

- Apple SF Symbols provide the source artwork.
- Icons sit inside a softly tinted rounded rectangle or circle.
- Color identifies meaning; it does not decorate whole rows.
- Text remains the primary source of meaning.
- The same concept always keeps the same symbol and tint.
- Filled symbols are preferred for identity, memory, and status.
- Outline symbols are preferred for navigation, configuration, and actions.

## Base Metrics

| Context | Container | Symbol | Corner radius | Tint opacity |
| --- | ---: | ---: | ---: | ---: |
| Primary configuration row | 44–48 pt | 18–20 pt | 12–14 pt | 10–12% |
| Compact information row | 32–36 pt | 14–16 pt | 9–11 pt | 9–11% |
| Navigation or action | No required tile | 16–18 pt | System button | System |
| Status badge | 22–28 pt | 11–13 pt | Capsule/circle | 10–14% |

Do not enlarge compact field icons to the same visual weight as Configuration
Center primary rows. The hierarchy must remain visible.

## Semantic Palette

| Token | Meaning | SwiftUI color |
| --- | --- | --- |
| Anchor Blue | time, configuration, navigation, system action | `.blue` |
| Location Cyan | place, direction, device context | `.cyan` |
| Identity Purple | nickname, personal identity, expression | `.purple` |
| Memory Pink | affection, memory expression, relationship notes | `.pink` |
| Milestone Orange | birthday, anniversary, border/style creativity | `.orange` |
| Success Green | saved, completed, preserved, available | `.green` |
| Neutral Gray | unavailable, secondary metadata, destructive pre-state | `.secondary` |

Red is reserved for destructive actions and failures. It must not be used as a
normal category color.

## Primary Navigation

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 首页 | `house.fill` | Neutral/primary |
| 配置中心 | `slider.horizontal.3` | Anchor Blue |
| 输出 | `square.and.arrow.down.fill` | Success Green |
| 任务 | `checklist` | Identity Purple |
| 设置 | `gearshape.fill` | Neutral Gray |
| 资料库 / 本地配置库 | `books.vertical.fill` | Identity Purple |
| 记忆卡片 | `rectangle.and.text.magnifyingglass` | Memory Pink |
| 对象检查器 | `sidebar.right` | Anchor Blue |

## Memory Source

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 记忆来源 | `sparkles` | Identity Purple |
| 记忆对象 | `person.crop.circle.fill` | Anchor Blue |
| 时间锚点 | `calendar.badge.clock` | Anchor Blue |
| 记忆显示 | `heart.text.square.fill` | Memory Pink |
| 表达称呼 | `person.text.rectangle` | Identity Purple |
| 当前生效配置 | `checkmark.seal.fill` | Success Green |
| 配置摘要 | `list.bullet.rectangle` | Anchor Blue |

## Subject Identity

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 对象头像 | `person.crop.circle.fill` | Anchor Blue |
| 对象名称 / 显示名称 | `person.fill` | Anchor Blue |
| 昵称 | `person.text.rectangle` | Identity Purple |
| 与我的关系 / 关系 | `person.2.fill` | Milestone Orange |
| 专属称呼 / 关系备注 | `heart.fill` | Memory Pink |
| 调整对象头像 | `crop` | Anchor Blue |
| 新增记忆对象 | `person.crop.circle.badge.plus` | Success Green |
| 切换对象 | `arrow.left.arrow.right` | Anchor Blue |
| 保存对象资料 | `checkmark` | Success Green |

## Time Anchors

| Title or type | SF Symbol | Tint |
| --- | --- | --- |
| 时间锚点配置 | `calendar.badge.clock` | Anchor Blue |
| 生日 / 出生 | `birthday.cake.fill` | Milestone Orange |
| 恋爱 / 关系纪念 | `heart.fill` | Memory Pink |
| 婚姻 / 周年 | `sparkles` | Identity Purple |
| 考试 / 目标节点 | `flag.checkered` | Success Green |
| 自定义重要日子 | `calendar` | Anchor Blue |
| 新增时间锚点 | `plus.circle.fill` | Anchor Blue |
| 锚点日期 | `calendar.day.timeline.left` | Anchor Blue |
| 锚点类型 | `square.grid.2x2` | Identity Purple |
| 配置锚点 | `slider.horizontal.3` | Anchor Blue |

Birthday cake icons must never use neutral gray in the normal state. Orange is
the durable default because it reads as warm and celebratory without competing
with destructive red or action blue.

## Card Layout And Content

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 卡片布局与内容 | `rectangle.split.2x2.fill` | Anchor Blue |
| Logo 标识 | `person.crop.circle.fill` or active asset | Anchor Blue |
| 边框样式 | `paintpalette.fill` | Milestone Orange |
| 位置显示 | `location.fill` | Location Cyan |
| 区域内容设置 | `square.grid.2x2.fill` | Anchor Blue |
| 模块与文字 | `text.badge.plus` | Identity Purple |
| 系统模块 | `cpu` | Anchor Blue |
| 自定义内容 | `text.cursor` | Identity Purple |
| 组合预览 | `rectangle.and.text.magnifyingglass` | Memory Pink |
| 记忆卡片预览 | `photo.on.rectangle.angled` | Memory Pink |

When the active Logo is a subject avatar, the real avatar replaces the generic
symbol. The colored tile remains optional and should not frame the same avatar
twice.

## Output And Retention

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 输出结果 | `photo.badge.checkmark` | Success Green |
| 保存去向 | `square.and.arrow.down.fill` | Success Green |
| Apple Photos / 系统相册 | `photo.on.rectangle` | Anchor Blue |
| 相册选择 | `rectangle.stack.fill` | Identity Purple |
| 元数据保留 | `doc.badge.gearshape` | Anchor Blue |
| 写入图片说明 | `text.document.fill` | Identity Purple |
| 写入与保留 | `archivebox.fill` | Success Green |
| 完整写入 | `checkmark.seal.fill` | Success Green |
| 本地处理 | `iphone` | Location Cyan |
| 保留原图 | `photo.stack.fill` | Success Green |

## Configuration Actions

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 保存当前配置 | `tray.and.arrow.down.fill` | Anchor Blue |
| 另存为新配置 | `plus.app.fill` | Success Green |
| 重命名 | `pencil` | Identity Purple |
| 重置 | `arrow.counterclockwise` | Milestone Orange |
| 删除 | `trash.fill` | Destructive Red |
| 导出配置 | `square.and.arrow.up` | Anchor Blue |
| 恢复配置 | `arrow.uturn.backward.circle` | Success Green |
| 刷新 | `arrow.clockwise` | Anchor Blue |
| 更多操作 | `ellipsis.circle` | Anchor Blue |

## Tasks And Processing

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 处理进度 | `hourglass` | Anchor Blue |
| 当前任务 | `circle.dotted.circle.fill` | Anchor Blue |
| 等待处理 | `clock.fill` | Milestone Orange |
| 正在处理 | `gearshape.2.fill` | Anchor Blue |
| 已完成 | `checkmark.circle.fill` | Success Green |
| 最近失败 | `exclamationmark.triangle.fill` | Destructive Red |
| 处理流程 | `point.3.connected.trianglepath.dotted` | Identity Purple |
| 查看相册 | `photo.on.rectangle` | Anchor Blue |

## Settings And Help

| Title | SF Symbol | Tint |
| --- | --- | --- |
| 使用与帮助 | `questionmark.circle.fill` | Anchor Blue |
| 表达公式说明 | `function` | Identity Purple |
| 版本信息 | `info.circle.fill` | Anchor Blue |
| 能力与边界 | `shield.lefthalf.filled` | Milestone Orange |
| 反馈渠道 | `bubble.left.and.bubble.right.fill` | Memory Pink |
| 隐私与数据 | `hand.raised.fill` | Success Green |
| 为什么是时光记 | `heart.text.square.fill` | Memory Pink |
| 欢迎 / 首次配置 | `sparkles` | Milestone Orange |

## Usage Boundaries

- Do not place a colored icon beside every paragraph or helper sentence.
- Use tiles for actionable rows, editable properties, and stable categories.
- Navigation titles remain text-only unless a dedicated hero treatment exists.
- Avoid multiple colors inside one icon tile.
- Do not use custom raster artwork where an SF Symbol communicates the same
  meaning more clearly.
- Keep icons decorative for accessibility when the adjacent text already names
  the concept; interactive icon-only controls require explicit labels.
- Dynamic Type layouts may move the icon above the text but must preserve the
  title-value relationship.

## Proposed Adoption Order

1. Memory Subject basic information and Time Anchor rows.
2. Output and retention rows.
3. Settings and help cards.
4. Task status surfaces.
5. Remaining inspector and library surfaces.

Each adoption pass should compare against the Configuration Center on a
physical iPhone and verify light/dark mode, Dynamic Type, truncation, and icon
availability on the minimum supported iOS version.
