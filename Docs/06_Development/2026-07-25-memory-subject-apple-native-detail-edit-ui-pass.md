# Memory Subject Apple-Native Detail And Edit UI Pass

Date: 2026-07-25
Primary loop: Product Loop
Risk: P1

## Observed Scenario

The current iPhone Memory Subject surface combines subject switching, saving,
identity editing, anchor summaries, and anchor navigation in one sheet. The
result does not provide a stable read-only subject detail state, and the full
time-anchor content remains behind a second page.

The accepted product reference is the Apple Contacts distinction between a
quiet object-detail surface and a separate editing surface. MemoMark adopts the
information hierarchy and interaction discipline, not the Contacts data model,
communication actions, contact poster, or private screenshots.

## Intended Outcome

- Split Memory Subject into a read-only detail surface and a draft-based basic
  information editor.
- Keep the existing centered avatar size and local avatar pipeline.
- Show only persisted subject facts: object name, dedicated form of address,
  and relationship to the recorder.
- Present every available Time Anchor on the detail surface in insertion order.
- Keep active-anchor selection owned by Configuration Center Memory Source.
- Make Time Anchor management compact, category-first, and automatically
  persisted through the existing configuration boundary.

## Frozen Detail Surface

- Fixed subject switching control on the upper leading side.
- Fixed `编辑` control on the upper trailing side.
- No save control and no current-subject badge.
- Centered read-only avatar using the existing MemoMark avatar specification.
- Subject name as the primary identity text.
- One basic-information module containing only nonempty persisted fields.
- Each Time Anchor is an independent rounded module in insertion order:
  generated or customized name on the first line, date on the second line,
  and category vertically centered on the trailing side.
- No active-anchor emphasis; Configuration Center owns that selection.
- `添加锚点` is the final anchor module and disappears at the five-anchor cap.

## Frozen Basic Information Editor

- Separate modal editing transaction with cancel and completion actions.
- Avatar selection, cropping, replacement, and removal are available only in
  this editor.
- Existing fields remain `对象名称`, `专属称呼`, and `与我关系` with unchanged
  model and expression mappings.
- Empty fields use contact-style input guidance that disappears after entry and
  returns after clearing.
- The object name is required. Optional empty fields do not appear on the
  detail surface.
- A standalone destructive `删除记忆对象` action appears at the bottom and
  requires confirmation.

## Frozen Time Anchor Management

- Both configuration and deletion begin from a long press on an anchor module.
- The context menu offers configuration and deletion, with equivalent
  accessibility actions.
- Deletion requires confirmation. The final anchor cannot be deleted.
- Configuration is category-first, followed by time and a compact horizontal
  custom-name field below the date control.
- Existing categories and Memory Engine behavior remain unchanged.
- Changing category updates the generated name only while the user has not
  supplied a custom name.
- Changes update the detail projection immediately. Dismissing by tapping
  outside commits through the durable configuration boundary; persistence
  failure restores the original anchor snapshot and reports the failure.
- Removing an anchor invalidates configurations that reference it. New Share
  or quick-entry work must reject invalid configuration before enqueue or
  processing. Already frozen queue tasks remain unchanged.

## First-Run Boundary

- First-run completion requires an object name and at least one valid Time
  Anchor.
- Avatar, dedicated form of address, and relationship remain optional and are
  available through later editing.
- No synthetic user facts are persisted to satisfy first-run validation.

## Ownership And Dependency Flow

```text
Memory Subject Detail/Edit
-> ConfigurationSession
-> Configuration aggregate persistence
-> Configuration Center Memory Source selects active anchor
-> Frozen processing configuration
-> Share / Quick Entry admission
```

Memory Engine continues to own time semantics. Configuration Center continues
to own the active Time Anchor. Renderer, Layout, Metadata, Export, PhotoKit,
commerce, and original-photo behavior are out of scope.

## Apple-Native Capabilities Evaluated

- SwiftUI navigation, sheets, context menus, confirmation dialogs, focus, and
  accessibility actions.
- System semantic grouped backgrounds and materials with Reduce Transparency,
  Reduce Motion, Dynamic Type, Dark Mode, and high-contrast fallbacks.
- System date controls without clipping or shrinking their required touch area.
- ContactsUI is intentionally not used because Memory Subject is not a
  `CNContact` and must remain local MemoMark domain data.

## Failure Modes

- Draft identity edits leaking into the live session before completion.
- Anchor edits appearing successful without durable persistence.
- Deleted anchors leaving selectable or processable invalid configurations.
- Long-press-only management becoming inaccessible to VoiceOver users.
- Fixed overlay controls obscuring content at large text sizes.
- Existing Brand Mark research files being accidentally included in this pass.

## Implementation Plan

1. Add source and presenter contracts for the frozen hierarchy and validation.
2. Extract a read-only Memory Subject detail projection and surface.
3. Reuse the existing draft session for basic-information editing.
4. Replace the anchor page and action button with detail modules and context
   management.
5. Audit and harden anchor persistence and invalid-configuration admission.
6. Run focused tests, the full test suite, unsigned macOS and generic iOS
   builds, `git diff --check`, and simulator or device acceptance when the
   runtime is healthy.

## Manual Acceptance

- The subject is recognizable from avatar and name without entering edit mode.
- Optional facts disappear cleanly when empty.
- All anchors are visible on one page and preserve insertion order.
- Anchor management is discoverable with long press and accessible without it.
- Switching subjects restores the subject-owned configuration list.
- Invalid anchor references are blocked before processing begins.
- No private reference screenshot is added to the repository.
