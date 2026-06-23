# Behavior Specification

Last updated: 2026-06-23

## Status

```text
Frozen
```

## Task Recovery Principle

All tasks should recover automatically by default.

Users should only be interrupted when recovery is truly not possible.

## Device Adaptive Principle

PhotoMemo automatically follows:

- Low Power Mode
- Thermal State
- Memory Pressure
- Background Policy

PhotoMemo should fully follow Apple device constraints.

PhotoMemo should not offer a separate performance mode.

## Storage Verification Principle

Before processing starts, PhotoMemo should estimate output storage requirements.

If storage is insufficient, the user should be informed before processing fails.

## Library Consistency Principle

After metadata is preserved and output is generated:

- the new photo should naturally appear near the original photo
- the new photo should also join the `PhotoMemo` output album

## Data Constitution

### Original Never Changes Principle

The original photo never changes.

### Metadata Preservation Principle

Metadata should remain preserved as fully as possible.

The only allowed output-level change is:

```text
Canvas Size
```

### Apple Naming Principle

Output naming should follow Apple conventions such as:

- `IMG_1234 (1)`
- `IMG_1234 (2)`
- `IMG_1234 (3)`
