# Render Specification

## Classic White

Classic White now uses a fixed render design system.

The renderer is no longer allowed to derive bottom-bar height,
font size,
or spacing from image ratio.

### Theme

- Bottom height: `260pt`
- Background: `#F4F3F3`
- Grid: `40 / 20 / 40`
- Primary text: `28pt` medium
- Secondary text: `18pt` regular
- Horizontal padding: `80pt`
- Top padding: `54pt`
- Bottom padding: `42pt`
- Divider: `#D8D8D8`, `2pt x 110pt`
- Center symbol size: `48pt`

### Layout Rules

- Photo remains the emotional surface.
- Bottom bar remains the information surface.
- Photo area and bottom bar are vertically stacked.
- The image is preserved and a new bottom bar is appended.
- Classic White export height is:
  - `imageHeight + 260`
- Text does not auto-scale.
- Text truncates instead of changing layout.
- Left, center, and right modules keep stable widths.

### Module Roles

- Left module: primary and secondary text
- Center module: symbol plus divider slot
- Right module: primary and secondary text

### Architecture

- `RenderTheme.swift` owns theme tokens
- `ClassicWhiteRenderer.swift` owns fixed-size export math
- `ClassicWhiteCardRenderer.swift` owns module-based layout
- `RecordCardRenderer.swift` only routes to the active renderer
