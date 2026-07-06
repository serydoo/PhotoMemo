# Location Module Adoption Slice A - Product Freeze

Date: 2026-07-06
Status: Frozen

## Mission

Expose existing Location display capability through Object Inspector.

## Product Principle

Feature Adoption exposes existing capability; it does not create new
capability.

The user sees display capability, not implementation language.

## User Language

The user-facing capability name is:

```text
位置显示
```

Do not use these labels in UI:

```text
位置设置
位置配置
位置模块
Location Module
Provider
Presentation Mode
Expression
```

## Display Options

The Location display options are:

| User Label | Meaning |
| --- | --- |
| 自动兼容 | 根据照片中的位置数据自动选择最佳显示方式。 |
| 省份 · 城市 | Province + City |
| 城市 · 区县 | City + District |
| 省份 · 城市 · 区县 | Province + City + District |
| 经纬度 | Coordinate |

`自动兼容` is the default user-facing value.

## Disabled State

If the current editable region has no Location module, Object Inspector should
show:

```text
位置显示
位置模块未插入
```

Do not hide the capability row.

## Icon

Use SF Symbol:

```text
location
```

## Definition Of Done

- Selection ownership is clear.
- Configuration ownership is clear.
- Refresh ownership is clear.
- Presentation ownership is clear.
- No new capability is introduced.
- Inspector terminology matches user language rather than implementation
  language.
