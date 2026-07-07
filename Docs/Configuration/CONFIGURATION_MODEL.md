# Configuration Model

Last updated: 2026-06-24

## Status

```text
Frozen
```

## Configuration Center Principle

MemoMark's foreground product surface is permanently the Configuration Center.

It owns long-term setup.

It is the Memory Engine Configuration Center.

It is not the normal daily workflow entry.

It is not a workspace, dashboard, task center, or temporary session surface.

It is not a generic Settings page.

Its responsibility is to define long-term objects.

```text
Configuration Once.
Benefit Forever.
```

## Object Editing Principle

The Configuration Center edits Objects, not Data.

Users are not primarily editing isolated strings, dates, or configuration fields.

Users are editing durable objects:

- Memory Subject
- Memory Card
- Memory Block Template
- Decoration
- Preset

All data is only an object's properties.

## Memory Language Layer

The Configuration Center will eventually edit Memory Block Templates.

Memory Block Templates define content field schemas, not visual slot positions.

The long-term content model is field-based:

```text
MemoryBlock
-> BlockField
-> Value Source
```

`Subject + Action + Result` is a Preset Schema, not the core model.

This principle is frozen in:

- `Docs/PDR/PDR-005_Memory_Language_Layer.md`

## Configuration Center Layout

The Configuration Center uses:

```text
Library
-> Interactive Memory Card
-> Object Inspector
```

The Library owns long-term Memory Object selection.

The Interactive Memory Card is the primary object.

The Object Inspector shows and edits the currently selected object.

## Configuration Layer

All configuration belongs to one of these three layers:

```text
System Defaults
-> User Preferences
-> Advanced
```

## Layer Definitions

### System Defaults

The baseline defaults MemoMark can use automatically.

### User Preferences

Long-term user choices that shape repeated memory workflows.

### Advanced

Optional deep controls that should never interrupt the normal happy path.

## Rule

Any new configuration must clearly belong to one layer before it is added to the product.

## Configuration Domains

The Configuration Center only owns long-term configuration:

- Memory Profile
- Life Anchor
- Preset
- Output
- Album
- Automation
- Advanced

During processing, each task uses a frozen Configuration Snapshot.

Any later edit in the Configuration Center affects the next task only.
