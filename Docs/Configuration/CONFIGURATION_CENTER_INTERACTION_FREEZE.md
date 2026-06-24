# Configuration Center Interaction Freeze

Last updated: 2026-06-24

This document records the current frozen interaction baseline for the PhotoMemo Configuration Center.

It freezes the product-facing structure and interaction behavior that emerged from the latest UI review. It does not freeze visual polish details, mock values, or future runtime integration.

## Freeze Status

Status:

```text
Frozen Baseline
```

Scope:

- Library
- Memory Subject
- Time Anchor
- Memory Preset
- Interactive Memory Card
- Region Strip
- Object Inspector
- Configuration Component Dock
- Write Memory
- Output selection

This baseline remains mock-first. It does not connect real Renderer, Metadata Pipeline, Export, Share Extension, Photo Library behavior, Layout Engine, or Memory Engine runtime behavior.

## Core Principle

The Configuration Center is not a workspace.

It is the Memory Engine Configuration Center.

The frozen interaction principle is:

```text
Everything starts from the Memory Card.
```

The center surface previews the real Memory Card instead of an abstract layout.

## Frozen Layout

The Configuration Center uses three stable areas:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

### Library

The left side owns Memory Subject selection.

It explains that different memory objects can have different time anchors and different memory angles.

The Library is not a dashboard, task center, import area, or photo manager.

### Interactive Memory Card

The center owns:

- Memory Preset
- Time Anchor display
- Memory Card Preview
- Region Strip
- Configuration Component Dock

The Memory Card remains the central object. The card is both preview and navigation.

### Object Inspector

The right side owns object-specific editing.

It changes based on the selected `CardRegion`.

The Object Inspector should stay focused on definition and editing, not broad help, output routing, or shared module browsing.

## Memory Preset

User-facing term:

```text
记忆预设
```

Memory Preset controls which region configurations are active.

A Memory Preset is a combination of:

- Recorder configuration
- Timeline configuration
- Context configuration
- Memory configuration
- Time Anchor context

The current mock presets are:

- `成长记录`
- `第一次旅行`
- `自定义预设`

The center top bar shows the active Memory Preset and active Time Anchor together.

## Time Anchor

User-facing term:

```text
时间锚点
```

The center top bar displays the current selected Time Anchor description, such as:

```text
图图出生日期
```

The center bar must not mention photo capture time until real capture-time integration is connected.

## Memory Card Regions

Frozen CardRegion routing:

- `slotA` = Recorder
- `slotB` = Timeline
- `slotC` = Context
- `slotD` = Memory

The Region Strip mirrors these regions:

```text
记录
时间线
上下文
记忆
```

Clicking a card region and clicking its Region Strip item must select the same object and route to the same Object Inspector.

## Configuration Component Dock

The center lower dock owns shared configuration tools that do not belong to the right Object Inspector.

Frozen dock sections:

- `写入记忆`
- `可插入模块`
- `当前配置展示`
- `输出`
- `配置说明`

### Write Memory

User-facing term:

```text
写入记忆
```

Purpose:

Write a memory description into the processed image's library-facing description/caption layer, so Apple Photos can search and help users review it later.

Default behavior:

- Use the generated Memory region text.

Custom behavior:

- If `自定义写入内容` is enabled and the custom text is non-empty, use the custom text.
- If `自定义写入内容` is enabled but empty, fall back to the generated Memory region text.

This avoids writing an empty memory description.

Implementation note:

This is currently UI-only. Future implementation must verify whether Apple Photos visible captions can be written directly, or whether EXIF/IPTC/XMP description fields are required.

### Insertable Modules

User-facing term:

```text
可插入模块
```

The module list includes common Apple photo and EXIF-facing fields.

Examples:

- Object nickname
- Smart time result
- Capture date
- Capture time
- Camera maker
- Camera model
- Lens model
- Focal length
- Aperture
- Shutter speed
- ISO
- Exposure bias
- Metering mode
- Flash
- White balance
- Capture parameter summary
- Location
- Altitude
- Image size
- Orientation
- File format

Default display:

- Show common modules first.
- Allow expanding the full list.

Future ordering rule:

```text
Frequently used modules should move forward.
```

### Current Configuration Display

User-facing term:

```text
当前配置展示
```

This section shows the current selected region under the current Memory Preset.

It is not the final export result. It is a live configuration display.

### Output

User-facing output result:

```text
处理过的图片
```

The output must generate a new image and must not modify the original photo.

Storage options currently shown as UI state:

- `PhotoMemo 文件夹`
- `现有文件夹`
- `新建文件夹`
- `目标相册`

Default rule:

```text
If no storage destination is specified, use the PhotoMemo folder.
```

This is currently UI-only and does not call the export pipeline.

## Object Inspector Editing

Right-side custom content fields are immediate-editing surfaces.

Frozen behavior:

- Typing updates preview immediately.
- Inserted modules display inside the editing field area as Apple-style chips.
- Module deletion is per chip.
- Custom content deletion is a larger visible action beside the editing field.
- There is no per-field confirm button.

Save / confirmation responsibility belongs to the upper configuration level.

## Non-Goals

This frozen baseline does not implement:

- real Apple Photos caption writing
- real EXIF module resolution
- real output folder selection
- real Configuration Snapshot persistence
- real Renderer connection
- real Export connection
- real Photo Library behavior
- real Memory Engine runtime

## Next Approved Direction

The next development direction should be reviewed as interaction design or IA-003 integration, not as another UI architecture reset.

Recommended next steps:

1. Confirm final interaction wording.
2. Decide how Memory Preset should persist into Configuration Snapshot.
3. Verify Apple Photos caption / description write support.
4. Connect module chips to real metadata through the approved IA-003 sequence.

