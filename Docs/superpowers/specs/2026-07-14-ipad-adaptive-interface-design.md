# MemoMark iPad Adaptive Interface Design

Date: 2026-07-14
Stage: V3 Production Quality And Delivery
Status: Approved design, pending implementation plan

## Objective

Adapt the complete iPhone product surface to iPad without changing product behavior, production rendering, configuration persistence, export, metadata, Share Extension, Photo Library, or Layout Engine contracts.

The iPad app presents Home, Configuration Center, Output, Tasks, and Settings as peer modules inside one adaptive shell. The design preserves the current user journey and uses additional width only where it improves comprehension.

## Product Boundary

The daily workflow remains:

`Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`

The foreground app remains the long-term Configuration Center, not a batch workbench. The iPad adaptation does not reopen IA-002. Within Configuration Center, the established object architecture remains:

`Library -> Interactive Memory Card -> Object Inspector`

This work changes navigation and responsive composition only. It does not add new editing capabilities, task-management behavior, output options, or renderer layout rules.

## Selected Approach

The selected direction is an equal-page adaptive shell:

- Home, Configuration Center, Output, Tasks, and Settings are peer destinations.
- iPhone retains the existing bottom tab navigation and settings presentation.
- iPad uses a persistent leading sidebar when horizontal space is regular.
- The selected destination occupies the main content area.
- Configuration Center may use an additional internal column because simultaneous Memory Card preview and object editing materially benefit from iPad width.
- Other destinations remain sidebar plus main content unless their existing content naturally supports a wider grid.

This approach is intentionally different from an all-modules dashboard. It preserves focus, follows familiar iPad navigation behavior, and avoids turning MemoMark into a dashboard or Task Center.

## Adaptive Navigation

### iPhone And Compact Width

- Preserve the current four bottom tabs: Home, Configuration Center, Output, and Tasks.
- Preserve the current Settings entry from Home and its sheet/navigation behavior.
- Preserve all existing quick-action transitions, including routes to Configuration Center and Tasks.
- Do not change tab ordering, labels, symbols, or state restoration as part of this slice.

### iPad Regular Width

- Replace the bottom tab bar with a leading sidebar.
- Sidebar order is Home, Configuration Center, Output, Tasks, and Settings.
- Use the same `V1EntryFlowState` selection source for both compact and regular navigation.
- Settings becomes a peer sidebar destination on iPad while retaining its compact presentation on iPhone.
- Programmatic transitions caused by quick actions or submitted processing update the same selection state and therefore work in both shells.
- The sidebar may collapse through standard iPad controls in constrained multitasking widths; when the horizontal size class becomes compact, the compact shell applies.

## Destination Layouts

### Home

Home remains the orientation surface for product identity, selected Memory Subject, current configuration, and next actions. On wider iPad content, existing cards may form a balanced two-column grid where reading order remains unambiguous. Home does not become a task dashboard.

### Configuration Center

Configuration Center receives the strongest iPad adaptation:

- The real Interactive Memory Card remains visually prominent.
- Library/navigation, Memory Card preview, and the active Object Inspector can coexist in regular-width landscape layouts.
- Existing selected panel, draft, focus, drag-sort, insertion, preset-switch, reset, rename, and save behavior remains owned by the existing session and view state.
- No layout constants are added to renderers. These are application-interface dimensions only.
- Configuration Preview continues to use the real preview/export contract rather than a substitute mock preview.

In portrait or narrower multitasking widths, the layout may reduce to two columns or the existing compact navigator pattern. Content must remain reachable without horizontal scrolling.

### Output

Output remains a focused configuration page. Wider width may group related output destination and format controls, but the underlying bindings, album loading, validation, and save action remain unchanged.

### Tasks

Tasks remains a focused status page. Current processing is shown before recent history. Wider width may place the overview and current task beside recent history when space permits, without changing task semantics, retries, Photo Library links, or diagnostics projection.

### Settings

Settings uses the existing `V1SettingsPageSurface` content. On iPad it renders as the selected main destination rather than a modal sheet. Welcome and workflow help may continue to present modally from Settings.

## State And Data Flow

The adaptive shell must not create a second product state tree.

1. `PhotoMemoiOSV1View` continues to own session, draft, output, diagnostics, and entry-flow state.
2. A width-aware root composition selects compact tabs or regular sidebar presentation.
3. Both presentations bind to the same selected destination state.
4. Existing page builders provide Home, Configuration Center, Output, Tasks, and Settings content.
5. Existing coordinators and services continue to perform persistence and side effects.

Switching orientation, entering Split View, or changing Stage Manager window width must preserve the selected destination and unsaved editor state.

## Accessibility And Interaction

- Sidebar destinations use existing labels and SF Symbols.
- Pointer, keyboard, and touch interactions use native SwiftUI controls.
- Selection remains visible with standard sidebar styling.
- Dynamic Type must not hide destinations or require horizontal scrolling.
- Minimum interactive target sizes remain at least 44 points where custom controls are involved.
- VoiceOver order follows sidebar first, then selected destination content.

## Failure And Edge Handling

- Compact multitasking widths fall back to the compact shell instead of squeezing columns below usable widths.
- Missing task, album, permission, or configuration data continues to use existing empty and error states.
- A width-class transition must not dismiss active editor state or overwrite draft content.
- Existing modal flows remain modal; presenting them from a sidebar destination must not create nested, conflicting navigation stacks.

## Verification Plan

### Automated

- Add focused tests for adaptive destination projection and entry-flow transitions where logic is extracted into testable presenters.
- Preserve existing entry-flow, configuration, output, task, preview, persistence, and production-contract tests.
- Build the `PhotoMemoiOS` scheme for a generic iOS Simulator destination.
- Build the Share Extension to prove the UI-only change does not disturb its target.

### Manual Simulator

Verify at minimum:

- iPhone portrait retains the current four-tab navigation and Settings entry.
- iPad portrait and landscape expose the sidebar destinations in the approved order.
- iPad Split View or resizable window transitions between regular and compact layouts without losing selection or draft edits.
- Configuration Center preview and inspector remain usable in portrait and landscape.
- Home quick actions route to the correct destination.
- Processing submission routes to Tasks.
- Settings help sheets open and dismiss correctly from both compact and regular shells.
- Dynamic Type and keyboard navigation remain usable on iPad.

### Explicitly Out Of Scope

- Renderer or export visual changes
- Metadata or Photo Library lifecycle changes
- Share Extension behavior changes
- New task-management features
- New output formats or destinations
- IA-002 architecture redesign
- Mac interface changes

## Acceptance Criteria

- iPhone behavior and navigation remain unchanged.
- iPad regular width uses a native sidebar with five peer destinations.
- Configuration Center uses iPad width to keep the real Memory Card and active editing context visible together where space permits.
- Compact multitasking remains fully usable through responsive fallback.
- Orientation and width changes preserve selection and unsaved state.
- Existing production, persistence, and workflow contracts continue to pass their relevant tests and builds.
