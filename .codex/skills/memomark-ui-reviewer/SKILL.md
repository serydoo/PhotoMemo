---
name: memomark-ui-reviewer
description: Audit MemoMark SwiftUI and UIKit/TextKit UI behavior, state flow, accessibility, and device fit. Use when a task needs Configuration Center, Memory Card editing, permission, navigation, preview, or Apple-native UI review; audit before proposing implementation.
---

# MemoMark UI Reviewer

## Overview

Use this skill to review MemoMark's current Configuration Center and iOS
surfaces with emphasis on state ownership, native interaction, accessibility,
and evidence-backed visual quality. The current product is MemoMark (the
repository may retain historical legacy symbols and folder names).

Default mode is **audit-only**. Do not modify source, add a dependency, or
redesign the frozen UI architecture merely because a finding is visible. If
the user asks for implementation, turn accepted findings into a bounded slice
with an explicit verification plan first.

## Current Entry Points

Start from these files when applicable:

- `Source/MemoMark/MemoMark/ConfigurationCenter/ConfigurationCenterView.swift`
- `Source/MemoMark/MemoMark/ConfigurationCenter/Editors/MemorySubjectEditorView.swift`
- `Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSV1View.swift`

Resolve paths against the current checkout. Do not recreate the retired
`Views/Main/MainView*` or Workspace editor path.

## Review Order

Check in this order:

1. state ownership, durable configuration boundaries, and duplicate sources of truth
2. Memory Card → Object Inspector routing and real-pipeline preview behavior
3. focus, caret, IME, module attachment, undo, and accessibility semantics
4. compact/wide layout, localization, Dynamic Type, contrast, and Reduce Motion
5. performance risks such as invalidation, image decoding, and unnecessary preview work
6. physical-device behavior and the exact build used for acceptance

When the finding is visual or interaction-heavy, complete one bounded pass
before proposing individual property tweaks. Record the observed current
behavior, intended outcome, surfaces/files, ownership boundary, and the
acceptance matrix together. This prevents a spacing observation from turning
into an unbounded view rewrite.

## MemoMark Boundaries

- Configuration Center remains `Library -> Interactive Memory Card -> Object Inspector`.
- Configuration Center edits Objects, not Data; the preview uses the real Memory Card.
- The preview is a calibration surface, not an abstract or batch-first workbench.
- Module insertion follows the active region; it must not silently fall back to a hard-coded slot.
- UIKit/TextKit owns the single visible caret, selection, IME, undo, and module-atomic editing.
- All editable inputs follow the shared canonical line-box specification; no local vertical compensation.
- UI changes must preserve the real Memory Engine → Layout Engine → Renderer → Export path.
- Permission prompts and album/save actions must state consequence and recovery clearly.
- The paired physical iPhone 17 Pro Max is the UI acceptance device. Simulator output is not a substitute.
- Liquid Glass is conditional polish only. Consider it for transient controls,
  navigation chrome, or over-photo actions after hierarchy and contrast are
  correct; do not apply it to Settings rows, Subject, Anchor, or ordinary
  Configuration sections merely because the SDK supports it.
- Use native SwiftUI/UIKit semantics before custom drawing. A custom control
  needs an explicit reason, accessibility model, focus behavior, hit target,
  and Dynamic Type outcome.

## Review Output

Lead with findings and separate evidence from inference. Use this compact form:

| Severity | Surface | Evidence | Apple/product principle | Fix direction | Business impact |
|---|---|---|---|---|---|

For each finding, include the file or runtime path and whether it is verified.
Use `P0` only for architecture, memory truth, privacy, data durability, or
irreversible impact; `P1` for production workflow, lifecycle,
accessibility, or compatibility risk; `P2` for bounded quality or
maintainability issues. If no serious finding exists, say so and list only
remaining verified gaps.

Do not report `PASS` without evidence. Use `NOT VERIFIED`, `BLOCKED`, or `N/A`
with a reason when applicable.

For a UI pass, include these cross-cutting checks when relevant:

- VoiceOver label/value/traits and traversal order;
- Dynamic Type expansion and clipping at the supported accessibility sizes;
- Reduce Motion, light/dark contrast, sheet focus restoration, and keyboard/IME focus;
- localization expansion, product-language semantics, and right-to-left behavior;
- state invalidation and preview work bounded to the changed object;
- exact signed build and physical iPhone acceptance status.

## Implementation Guidance

When implementation is explicitly authorized:

- prefer simplifying state instead of layering flags
- preserve the existing Apple-native, restrained surface language
- keep macOS-specific code isolated and do not reopen IA-002
- state source of truth, affected owner, risk level, and required evidence
- run focused tests/builds, then install the exact signed build on the paired device when UI behavior is in scope
- if implementation crosses UIKit/TextKit, read the shared input-geometry
  standard and keep the single visible caret, selection, IME, undo, and module
  atomicity in UIKit/TextKit ownership.
