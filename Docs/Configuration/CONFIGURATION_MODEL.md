# Configuration Model

Last updated: 2026-06-23

## Status

```text
Frozen
```

## Configuration Center Principle

PhotoMemo's foreground product surface is permanently the Configuration Center.

It owns long-term setup.

It is not the normal daily workflow entry.

It is not a workspace, dashboard, task center, or temporary session surface.

## Configuration Layer

All configuration belongs to one of these three layers:

```text
System Defaults
-> User Preferences
-> Advanced
```

## Layer Definitions

### System Defaults

The baseline defaults PhotoMemo can use automatically.

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
