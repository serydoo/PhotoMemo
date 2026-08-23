# V4 Minimal Expression Style PDR

Status: Approved for bounded implementation on 2026-08-19

> **Placement amendment:** The Minimal canvas and placement sections in this
> document were superseded on 2026-08-23 by
> `Docs/01_Product/V4_Minimal_Floating_Overlay_Amendment_2026-08-23.md`.
> Minimal is now a same-canvas floating overlay. Classic White remains the
> appended-area style described below.

## Decision

MemoMark adds a second expression style named `极简` beside the existing
`基础白`. The expression-style selection moves to the beginning of the card
editing flow and becomes a shared input to Configuration Preview, content
editing, rendering, and export sizing.

The user explicitly authorized this bounded implementation on 2026-08-19 and
asked that the earlier V4 display-implementation wait condition not block this
work. This exception does not close TX-001, BP-001, or any production
certification requirement, and it does not authorize unrelated V4 expansion.

## Product Loop decision gate

- Observed scenario: a photo needs one quiet line of memory information at its
  bottom edge, without the visual weight of the four-region Classic White card.
- Affected ownership: durable Presentation route, Configuration Center,
  Configuration Preview, Layout/Renderer routing, export dimensions, and the
  existing Logo resolver.
- Source of truth: `MemoryConfigurationRecord.Presentation.Route` remains the
  saved truth. The live Configuration Center projection is the editing truth.
  Batch configuration transports the selected route into `RecordCard`.
- Apple-native reuse: SwiftUI `Menu`, system typography, SF Symbols, existing
  PhotosPicker Logo flow, and the existing TextKit composition editor.
- Risk: P1. A wrong route or output size can create preview/export mismatch or
  clip the appended bar. Switching styles must not erase hidden Slot B/C/D or
  Logo data.
- Verification: route persistence and transport tests, layout geometry tests,
  renderer-routing tests, Configuration Center source contracts, targeted test
  execution, and an unsigned iOS build. Visual acceptance remains manual.

## Experience model

### Expression-style selection

The selector appears after `这一刻怎样表达` and before `卡片布局与内容`.
It uses a compact trailing menu and a short, style-specific explanation.

- `基础白`: four content regions for a fuller photographic record.
- `极简`: one composed output region for a quieter memory note.

The `卡片布局与内容` group retains `Logo 标识`, `卡片内容`, `时间与地点`,
and status. It no longer owns an independent border-style row.

### Editing

- Classic White edits Slot A/B/C/D exactly as before.
- Minimal edits Slot A only and labels it as the single output content.
- Slot B/C/D remain in the session and durable configuration while Minimal is
  selected. Switching back to Classic White restores them unchanged.
- Smart variables, EXIF-backed values, literal phrases, insertion behavior,
  and TextKit composition remain available in the single Minimal editor.
- Logo configuration is shared. Minimal does not create a second Logo setting.

### Compact Configuration Preview

- Minimal Preview is a calibration image slice rather than a complete
  photograph.
- It does not reserve a top or bottom blank border area. The preview shows one
  quiet code-generated landscape slice whose height is
  `0.20625 x preview width`.
- A warm-white capsule is anchored near the same bottom-right origin as the
  output renderer. This communicates that the final result floats over a photo
  surface instead of belonging to a separate appended card footer.
- The preview reuses the Minimal capsule/avatar silhouette rules: the object
  avatar sits inside the measured capsule area and must not overrun the stroke.
- This compact crop does not change the Renderer rule that preserves the whole
  source photo and renders the capsule inside the same canvas.

### Persistence compatibility

- New records encode the selected Presentation route explicitly.
- Records created before the route existed decode as `基础白`.
- Unknown future route values also decode as `基础白`, while malformed values
  of the wrong JSON type still fail rather than silently masking corruption.
- The fallback affects only the style route; Logo and location configuration
  continue to decode through their existing durable contracts.

## Measurable rendering specification

The source photo keeps its full pixel dimensions and aspect ratio. Minimal
adds an opaque bottom area; it never overlays or crops the source photo.

| Measurement | Landscape | Portrait |
| --- | ---: | ---: |
| Added bottom height | `0.075 × image width` | `0.095 × image width` |
| Added height for canonical 4:3 / 3:4 photo | `10.0% × image height` | `7.125% × image height` |
| Final height for canonical photo | `110.0%` | `107.125%` |
| Trailing anchor X | `0.95 × image width` | `0.94 × image width` |
| Maximum module width | `0.62 × image width` | `0.82 × image width` |
| Capsule side inset | `0.028 × image width` | `0.032 × image width` |
| Capsule height | `0.72 × bottom height` | `0.74 × bottom height` |
| Text line limit | 1 | 2 |
| Text size | `0.38 × bottom height` | `0.31 × bottom height` |
| Logo size | `0.32 × bottom height` | `0.34 × bottom height` |

The module is `[small Logo][composed Slot A content]`. Its trailing edge stays
fixed and the module grows leftward. The Logo remains the leading element of
the module rather than a symmetric opposite column.

For a 4032 × 3024 landscape source, the appended height is 302 px, the final
height is 3326 px, and the trailing anchor is 3830 px. For a 3024 × 4032
portrait source, the requested appended height is 287 px; the Layout Engine
rounds the final encoder-safe height up to 4320 px and the corresponding bar to
288 px. The trailing anchor is 2843 px (rounded to output pixels).

### Output and Live Photo parity

The appended-bottom geometry above is the single presentation contract for
preview, static export, Live Photo still, and paired motion. The Layout Engine
resolves the final canvas, photo frame, footer region, layer frames, and
encoder-safe even pixel dimensions once. Still-image and video composers
consume that immutable result; they do not infer layout from the selected
renderer or silently rewrite dimensions.

Live Photo preservation is fail-closed: a source Live Photo routed with
`preserveMotion` must produce both a still resource and a paired video resource
with one matching content identifier. It must never be saved as a static-only
photo. A static source remains a static output.

The renderer supplies visual layers only. It does not own video encoding,
audio handling, pairing identifiers, PhotoKit saving, or readback. Adding a
future renderer requires registering its presentation planner and layers; it
must not require a new media encoder path or a style branch in the export and
Live Photo services. Same-canvas floating overlays are not the formal Minimal
contract in this PDR.

## Visual tokens

- Outer appended surface: white, opaque.
- Inner capsule: warm white `#FAF8F3`, opaque.
- Hairline: `#E6E2DA`.
- Primary text and Logo tint: `#1D1D1F`.
- Typeface: Apple system font with automatic CJK fallback; medium weight;
  monospaced digits are retained for changing time and EXIF values.
- Minimum scale factor: 0.78. Truncation is the last fallback after tightening
  and scaling.
- Capsule corner radius: half the capsule height.

At a 390-point preview width, the specified ratios produce approximately
11.1-point landscape text and 11.5-point portrait text. Normal text must retain
at least WCAG 2.2 AA 4.5:1 contrast.

## Boundaries

- No glass blur, transparency, gradient, or photograph-dependent tint.
- No direct imitation of reference screenshots.
- No new content engine, Logo store, template marketplace, or renderer-owned
  configuration truth.
- Existing Classic White appearance and Slot A/B/C/D data remain unchanged.
- This PDR does not certify Apple Photos, Live Photo, Share, TX-001, BP-001, or
  production readiness.

## Research basis

The proportions synthesize the supplied Immers reference, external EXIF-border
products that use roughly 8% to 13% bottom space, and Apple/WCAG legibility
guidance. External examples are treated as measurement inputs, not assets or
screens to reproduce.
