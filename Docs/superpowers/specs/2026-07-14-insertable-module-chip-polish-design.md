# Insertable Module Chip Polish Design

## Goal

Make the production iOS Configuration Center's inserted-module chips feel more
Apple-native without changing information architecture, module insertion,
editor state, configuration persistence, preview composition, or rendering.

## Scope

- Update only the module-chip remove control inside `V1RegionEditorCard`.
- Preserve the existing module title, SF Symbol, ordering, horizontal scrolling,
  and `onRemoveItem` callback.
- Keep the visual direction quiet and consistent with the current Configuration
  Center.

## Interaction

- Keep `Button` as the native remove interaction primitive.
- Provide immediate pressed-state feedback through a local `ButtonStyle`.
- Keep the animation restrained and remove scale motion when Reduce Motion is
  enabled.
- Increase the remove control to a stable 24-point frame without changing the
  surrounding editor structure.
- Give VoiceOver an action-specific label: `移除<模块名称>`.
- Use the native selection feedback generator only when a module is actually
  inserted or removed. Opening the module sheet, searching, scrolling, and
  editing literal text must remain silent.

## Visual Treatment

- Present the add command with the native `plus` SF Symbol.
- Use a semantic system fill and a continuous rounded rectangle for inserted
  module chips.
- Reserve the app accent color for the module symbol, keep the module title in
  the primary text hierarchy, and keep removal visually secondary.
- Use hierarchical SF Symbol rendering for the remove icon.
- Increase icon contrast only while pressed.
- In the module library, keep module symbols in the accent hierarchy, add a
  trailing native add symbol, and place the Done command in the confirmation
  toolbar position.
- Separate the resolved composition from its editing controls with a native
  divider, label it with a semantic SF Symbol, and present the resolved text in
  the primary body hierarchy.
- Present literal-text objects with a shared semantic system-background fill,
  continuous corner shape, and faint hairline so they remain visually distinct
  from inserted modules without changing text-field behavior.
- Give expanded Configuration Center objects a restrained selected background,
  accent icon and chevron hierarchy, explicit accessibility state, and a
  Reduce-Motion-safe disclosure transition.
- Avoid shadows, material effects, and global style changes in this pilot.

## Verification

- Build the iOS application and Share Extension with code signing disabled.
- Confirm the diff does not touch module insertion or editor-state code.
- Inspect the Configuration Center shell in the simulator at a compact iPhone
  size.
- Manually check normal, pressed, VoiceOver, and Reduce Motion behavior when a
  signed-device or interactive simulator pass is available.
