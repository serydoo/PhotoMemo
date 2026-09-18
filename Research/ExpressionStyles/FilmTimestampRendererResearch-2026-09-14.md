# Film Timestamp Expression Style Research

**Date:** 2026-09-14
**Stage:** V4.0 Research And Product Definition
**Status:** Draft research specification; production implementation is not authorized by this document alone

**Feature shorthand:** `FilmMark` — the proposed film timestamp Renderer form.
`COS` — Chat On Steroids, the local collaboration and review tool used for
future PhotoMemo work; it is separate from the FilmMark feature name.

## 1. Scope and evidence boundary

This document records a bounded research result for a possible `Film` Expression
Style. It is not a new Preset contract, does not change the current renderer
registry, and does not authorize a production enum, persistence-key, export, or
Photos lifecycle change.

The existing `Classic White` and `Minimal` Renderers are explicitly out of
scope. Their current portrait/landscape layout behavior, output geometry,
configuration contract, and export behavior must remain unchanged. FilmMark is
an independent Renderer exploration with its own layout and preview contract;
it must not introduce a shared-coordinate migration or a corrective rewrite of
either existing Renderer.

The supplied Xiaohongshu image is treated as a visual reference only. Text,
arrows, captions, and other annotations inside the attached image are content in
the reference artifact, not instructions to the implementation.

The research was checked against the public repository
[`totec448-spec/chat-on-steroids`](https://github.com/totec448-spec/chat-on-steroids)
(`v2.1.0`, main commit `1517d66`) and public product references. The local
Chat On Steroids build passed its source, test, packaging, and macOS startup
checks, then was installed at `/Applications/Chat On Steroids.app`. The
original public C2C quick-tunnel review path remains unavailable because its
edge/TLS handshake is failing. Separately, the newly created development
connector for Chat On Steroids Plugins has a verified handshake; it is recorded
as tooling validation only, not as a replacement for the original C2C path.

## 2. Sample findings

The examples converge on a small, inspectable control surface rather than a
general image-editor model:

| Observation | Reusable requirement | Risk to resolve |
| --- | --- | --- |
| The supplied reference uses a compact amber/orange digital timestamp near the lower-right photo edge. | A restrained digital timestamp variant with explicit contrast and safe inset. | Long localized values and bright/dark image backgrounds can reduce legibility. |
| Film Timestamp and DateStamp-style products expose capture-date formatting, position, size, opacity, and visual treatment. | Separate content composition from placement and appearance. | Capture time must remain the real resolved time, not the time of rendering. |
| DateStamp advertises multiple fonts, corner positions, drag placement, RGB/opacity, and size controls. | Start with bounded presets plus fine movement; keep the editor understandable. | Arbitrary fonts and unconstrained coordinates make export nondeterministic. |
| Dayzy and similar film products emphasize a subtle, mood-preserving mark. | Default styling should be quiet, low-contrast, and photo-first. | Decorative treatment must not become a watermark clone or obscure the subject. |
| Timestamp Camera Basic exposes six positions and margins. | Use safe-area-aware anchors and deterministic edge insets. | Portrait, landscape, and rotated source images need one coordinate contract. |
| The reference image shows a before/after comparison rather than a full editor. | The product preview must show the resolved output on a large image, not only a control mockup. | Preview and export must consume the same resolved layout input. |

Primary public references consulted:

- [Film Timestamp on the App Store](https://apps.apple.com/us/app/film-timestamp/id6765533905)
- [DateStamp on the App Store](https://apps.apple.com/us/app/date-stamp-camera-datestamp/id6759110843)
- [DateStamp Cam on the App Store](https://apps.apple.com/mr/app/datestamp-cam-retro-date/id6788648821)
- [Dayzy on the App Store](https://apps.apple.com/gb/app/dayzy-film-date-stamp/id6749792640)
- [Timestamp Camera Basic on the App Store](https://apps.apple.com/us/app/timestamp-camera-basic/id840110184)
- [DateStamper on the App Store](https://apps.apple.com/us/app/datestamper/id916281570)
- [HUJI Cam on the App Store](https://apps.apple.com/us/app/huji-cam/id781383622)

## 3. Proposed product direction

The candidate is a new `Film` Expression Style inside the existing
Configuration Center mental model. It should not introduce a separate import,
workspace, batch, or image-editor workflow.

The user-facing sequence remains:

`Library -> Interactive Memory Card -> Object Inspector`

Within the Object Inspector, the style would eventually expose one output
window with a composable content expression. The user can combine literal text
with resolved variables such as capture time and a Memory Engine anchor result.
Smart anchor variables continue to output time results only; they do not produce
uncontrolled full-sentence copy. For example:

```text
{{capture_time}} · {{anchor_age_text}}
```

could resolve to:

```text
2026/08/16 21:29 · 1岁2个月18天
```

The exact date and wording remain controlled by the existing metadata and
Memory Engine contracts. The Film style owns expression presentation, not
memory meaning.

## 4. Draft content and configuration contract

This is a proposal for Product Design Review, not a source-code contract.

```swift
struct FilmTimestampDraft {
    var content: [MemoryBlock]
    var dateFormat: FilmDateFormat
    var fontID: FilmFontID
    var fontSize: FilmFontSize
    var color: FilmStampColor
    var opacity: Double
    var shadow: FilmShadowTreatment
    var placement: FilmPlacementDraft
}

struct FilmPlacementDraft {
    var anchor: FilmPlacementAnchor
    var offset: CGSize // normalized to the resolved photo canvas
}
```

The final persisted representation must follow the repository's existing
durable-configuration and compatibility rules. Names above are placeholders for
the review, not permission to add keys.

Recommended v1 control bounds:

- two default safe-area anchors: lower-left and lower-right. These are two
  starting presets, not two simultaneous output layers;
- four directional buttons for fine movement, with an accessible repeat action
  and a visible numerical position summary;
- an optional future direct-drag gesture only after the keyboard/accessibility
  and precision behavior is specified;
- a bounded set of deterministic, licensed font choices, including a digital
  monospaced option and a humanist/film option;
- a bounded size scale rather than an unconstrained text field;
- opacity and contrast controls only if they can preserve legibility over real
  photos;
- no user font import in the first implementation slice.

The arrow buttons are editor controls. They mutate a draft placement owned by
the Configuration Session. They must not be interpreted by the Renderer as
layout policy, and they must not be embedded into the output image.

## 5. Preview and visual language

The preview should be a large, real Memory Card preview with a white film-frame
substrate and enough breathing room to inspect the timestamp. The white frame is
an expression surface, not a second workflow. The preview and export must share
the same resolved `FilmLayoutSpecification` and the same text measurement
inputs.

Suggested initial visual variants for review:

1. **Digital Amber** — compact amber/orange monospaced timestamp, no panel,
   subtle shadow only when contrast requires it.
2. **Soft White** — warm white timestamp with a low-strength dark edge, for
   darker film frames.
3. **Printed Label** — restrained dark text on a small warm-white label, used
   only if the white substrate is part of the chosen variant rather than an
   always-on decoration.

The reference's amber lower-right treatment is a useful candidate default, not
a pixel-level design target. All final measurements should be derived from
readable ratios, font metrics, safe insets, and localized content tests.

## 6. Architecture and ownership proposal

The implementation, if approved, should follow the existing direction:

`Configuration Snapshot -> Memory Engine Results -> Memory Behavior -> Expression Style Specification -> Presentation Engine -> Layout Engine -> Renderer -> Export`

Proposed ownership:

- **Configuration Center / Configuration Session:** edits the composable content,
  font/size choice, variant, and normalized placement draft.
- **Memory Engine:** resolves capture-time and anchor values; owns Life Position
  and memory meaning.
- **Expression Style specification:** describes Film semantics and visual
  options without calculating device-specific geometry.
- **Layout Engine:** converts the resolved style plus measured content into a
  canvas-specific `FilmLayoutSpecification`, including safe insets, text bounds,
  frame geometry, and orientation handling.
- **Presentation Engine:** assembles a renderer-neutral `PresentationArtifact`
  from resolved content and layout output.
- **Film Renderer:** draws the already-resolved artifact. It must not choose
  anchors, invent offsets, resolve memory prose, or contain screenshot-derived
  constants.
- **Export / Photos lifecycle:** creates a new output image, preserves original
  photo protection, and keeps the existing metadata, orientation, color, Live
  Photo, and save-back contracts in scope for a dedicated verification plan.

The likely integration point is the existing
`RecordCardPresentationPlanner` registration path, but adding
`RecordCardPresentationStyle.film` or changing `TemplatePreset` compatibility
must wait for the Product Design Review and a bounded migration decision.

## 7. Geometry contract to validate

The editor and export path must use one coordinate model:

- placement is stored as a normalized offset relative to the resolved photo
  canvas, not as a fixed preview pixel value;
- safe insets are applied by Layout Engine after orientation and output size are
  known;
- text is measured with the selected export font before placement;
- the canonical line box and attachment geometry follow
  `2026-08-27-editor-input-geometry-standard.md`;
- ordinary text, token attachments, and caret geometry retain separate owners;
- no per-region baseline adjustment or Renderer-owned input geometry is allowed;
- the same layout result drives the large preview and final output;
- minimum and maximum placement bounds prevent text from leaving the visible
  output canvas, while allowing the user to reach each corner intentionally.

The preview should expose enough of the white substrate to make movement
observable. Position changes should be visible immediately and should not
require a new photo selection or a new Memory Engine evaluation.

## 8. Verification plan before production implementation

### Product Loop

- Product Design Review of the Film variant set and the single output-window
  mental model.
- Confirm whether the white film-frame substrate is always-on or a named
  variant.
- Confirm content examples in Chinese, English, Japanese, and Korean.
- Confirm that capture time and anchor results are separate selectable values.

### Engineering Loop

- Unit tests for normalized placement, safe insets, orientation, text bounds,
  clamping, and all four directional edits.
- Contract tests proving preview and export use the same resolved layout input.
- Tests for empty content, one token, mixed literal/token content, long values,
  CJK glyphs, and missing capture-time/anchor values.
- Renderer tests proving there are no layout-policy constants or memory-value
  resolution inside the renderer.
- Accessibility checks for arrow labels, repeat behavior, value summaries,
  font/size controls, and VoiceOver ordering.
- Physical iPhone 17 Pro Max visual acceptance for portrait/landscape photos,
  dark/light scenes, large text values, and keyboard/gesture interaction.
- PhotoKit/export acceptance proving the original remains unchanged and the new
  output retains the required orientation, color, EXIF policy, and Live Photo
  behavior.
- Build and signed-device evidence before any production capability claim.

No simulator-only visual result can close the UI acceptance gate for this
control. No ad-hoc package or desktop startup result can close the PhotoKit,
Share, accessibility, or physical-device gates.

## 9. Recommended next slice

1. Hold the Product Design Review using the three visual variants above and the
   supplied reference as a style reference, not a literal implementation.
2. Freeze the content-window semantics and the normalized placement contract.
3. Add a Layout Engine-only prototype and a renderer-neutral artifact test,
   without changing durable keys or the production style enum.
4. Add a large preview fixture using a non-private test asset and compare the
   preview/export raster result.
5. Reassess whether the current C2C connection can provide a second review. The
   locally installed Chat On Steroids application is a separate tool and does
   not by itself repair the existing public C2C tunnel.

## 10. Current code and tooling validation (2026-09-14)

The repository inspection confirms that this proposal has a bounded extension
seam, but is not yet a safe production implementation task:

- `RecordCardPresentationStyle` is a durable `Codable` style value. Adding a
  new case changes the persisted configuration contract and therefore needs an
  explicit compatibility/migration test rather than a local enum edit.
- `RecordCardPresentationPlanner` is the existing single registration point
  for style-specific content and artifact planning. It is the appropriate
  integration seam after the Film layout specification is accepted.
- The current configuration editor already keeps drafts by presentation style.
  This supports a Film-specific draft without making the Renderer own editing
  state, memory meaning, or layout policy.
- `CardRegion` and the existing content contract are compatibility carriers,
  not a reason to add global slot assumptions. The Film content window should
  use a style-specific semantic mapping and then hand resolved content to the
  Layout Engine.
- The current preview is built from the real configuration/session data. The
  Film preview must therefore consume the same resolved layout input as export;
  a screenshot-only mock would not validate the product contract.

Tooling validation is also complete for the local review path. The new
`Chat On Steroids Plugins` connector was created in development mode with no
authentication and its handshake was verified by the installed application.
For future work, this local Chat On Steroids path is referred to as `COS` and
is the preferred replacement for the unavailable public C2C review path.
The original public C2C quick-tunnel remains unavailable because its edge/TLS
handshake still fails. The optional Web Fetch plugin was attempted only after
user authorization, but the app did not complete installation: the installed
count remains zero, its local plugin directories are empty, and no installer
process or ready state appeared. It is not being treated as installed or as a
source of research evidence.

This means the morning concept is validated at the research/specification
level, with the repository architecture mapped, but the production Film
Renderer has intentionally not been added yet. The next authorized engineering
slice should begin with the Layout Engine prototype and compatibility tests in
section 9, followed by the smallest preview/export parity implementation.

## 11. User-confirmed v1 direction (2026-09-14)

The product decision for the next bounded slice is now more specific:

- `FilmMark` is the feature shorthand for the proposed film timestamp
  Renderer. `COS` means Chat On Steroids and is the local collaboration/review
  tool used to continue PhotoMemo work; the names must not be conflated.
- FilmMark uses one photo-relative coordinate model for every source image. It
  does not create separate portrait and landscape configuration modes. The
  source canvas may have any aspect ratio, but the stored placement, safe area,
  and preview mapping use the same normalized contract. This rule is local to
  FilmMark and must not be back-ported to Classic White or Minimal.
- Classic White and Minimal remain behaviorally frozen. No existing renderer
  layout constants, orientation branches, planner cases, persisted style keys,
  or export geometry may be edited as part of the FilmMark exploration.
- The Card surface owns the output window's meaning and composition: literal
  text, capture-time value, Memory Engine time-result value, ordering, and
  separators. The user can compose one expression such as
  `{{capture_time}} · {{anchor_age_text}}`.
- The Layout surface owns form and geometry: anchor, fine position, font,
  size, color, opacity, and optional film substrate treatment. It must not
  resolve memory meaning or duplicate Card content state.
- The preview is one large image calibration surface. It shows the resolved
  FilmMark result in its relative position on the image and updates immediately
  when a directional control, font, size, or color changes. It does not switch
  to a separate landscape/portrait mockup.
- First-version precision uses accessible up/down/left/right controls with a
  deterministic normalized step and a visible position summary. A free-drag
  gesture can be evaluated later, but is not required to validate the first
  contract.
- The color control should use the platform color picker plus a small set of
  restrained presets. Persist the chosen color as a stable sRGB RGBA value,
  not as an opaque platform `Color` representation.

### Free-font candidates

The first candidate set is limited to fonts whose public repositories identify
the font software as SIL Open Font License 1.1. This permits bundling with the
application when the license and required notices are retained, but each exact
font file and version still needs a final license audit before inclusion:

- [DSEG](https://github.com/keshikan/DSEG) — strongest digital 7/14-segment
  reference for the amber timestamp form. Its Latin/digit coverage means CJK
  text needs a deliberate fallback or a mixed-font run.
- [IBM Plex Mono](https://github.com/IBM/plex) — readable monospaced option for
  mixed metadata and a calmer, less literal film look.
- [JetBrains Mono](https://github.com/JetBrains/JetBrainsMono) — high-legibility
  mono alternative for dense values and punctuation.
- [Space Mono](https://github.com/googlefonts/spacemono) — display-oriented
  candidate for a more designed label treatment; it is a secondary candidate
  because the public repository is archived.

The implementation must include the exact license notices for any bundled font,
retain the original font names unless a license permits otherwise, and test
fallback behavior for Chinese, Japanese, Korean, Latin, numerals, punctuation,
and mixed expressions. System fonts such as PingFang may be used as platform
fallbacks, but they must not be copied into the application bundle.

## 12. Expanded product sample catalogue (2026-09-14)

This catalogue broadens the research beyond the attached reference image. It
is a product-pattern study, not a recommendation to copy any one application.
The evidence below comes from current App Store descriptions or public product
pages. App Store descriptions are marketing material and do not replace local
device testing; where a capability is only described by the publisher, it is
marked as publisher-described rather than independently verified.

### 12.1 Timestamp and date-stamp products

| Product | Observed output language | Controls or data described by the product | FM implication |
| --- | --- | --- | --- |
| [DateCam - 90s Film Date Stamp](https://apps.apple.com/ar/app/datecam-90s-film-date-stamp/id6790144937) | Warm glowing amber seven-segment readout in a corner; film grade and grain stay secondary to the date | Seven film looks, adjustable grain, custom date, live/imported photo, drag-to-reposition, on-device processing; publisher-described | Strong reference for a deliberately narrow FM Renderer: one recognisable stamp plus a restrained film treatment, rather than a full filter editor |
| [Dayzy - Film Date Stamp](https://apps.apple.com/ie/app/dayzy-film-date-stamp/id6749792640) | Soft, film-burned date that adapts to the image instead of looking like a sharp UI label | EXIF shooting date, manual date, multiple formats, film-like colour and softness, on-device processing; publisher-described | Supports an optional low-contrast/softness treatment, but FM should preserve a readable default and expose legibility intentionally |
| [Filmlike Date Stamp](https://apps.apple.com/jp/app/filmlike-date-stamp/id1509616702) | Small analog-camera date mark with a limited set of familiar date formats | Ten film-camera date stamps; shooting date/today/custom date; YY-MM-DD or MM-DD-YY; publisher-described | A small curated style set is more coherent with MemoMark than an unbounded template marketplace |
| [Date Stamp Camera - DateStamp](https://apps.apple.com/us/app/date-stamp-camera-datestamp/id6759110843) | 90s/Y2K, VHS, LCD, dot-matrix, monospace and typewriter variants | EXIF detection, manual date, 32 fonts, nine positions plus free drag, RGB colour, size, opacity, shadow/frame/background, batch and video; publisher-described | Confirms demand for independent font, colour, size and position controls; its large feature surface is intentionally out of FM v1 |
| [OldRoll - Vintage Film Camera](https://apps.apple.com/us/app/oldroll-vintage-film-camera/id1570093460) | Camera-specific film frame, grain, texture, light leaks and optional date-stamp watermark | Many simulated cameras and formats, square film frames, retro effects, custom date stamp; publisher-described | Shows that users recognise a camera identity through a coordinated frame/texture/stamp combination; FM should use only the smallest useful subset |
| [Timestamp Camera GPS Stamper](https://apps.apple.com/us/app/timestamp-camera-gps-stamper/id6779486601) | Practical WYSIWYG data stamp, configurable for different orientations and placements | Live preview, full-resolution export, EXIF preservation, stamp position/size/colour, retroactive stamping; publisher-described | Validates preview/export parity and metadata-aware input; FM should keep the data payload memory-centred rather than add GPS/weather dashboards |
| [Timestamp Camera GPS Photo](https://apps.apple.com/us/app/timestamp-camera-gps-photo/id6745490022) | Utility-oriented live overlay with visible date/time/location information | Overlay size, position, transparency, colours, text/images/location; publisher-described | Position and opacity are expected controls, but GPS/location belongs to a separately justified Memory/metadata decision, not the first FM payload |
| [Timestamp It - Proof Camera](https://apps.apple.com/us/app/timestamp-it-proof-camera/id327756085) | High-density evidence/proof label rather than a quiet memory caption | Date/time/GPS/address/weather/custom fields/logo; font, colour, size, opacity, placement; batch, cloud, projects, reports; publisher-described | Useful as a boundary sample: FM must not become a professional proof-camera or cloud project manager |
| [Collage Recipes Date Stamp](https://collage.recipes/tools/date-stamp/) | Compact amber, red, yellow or white digital mark, usually snapped to a corner | Seven-segment style, date formats, four corner positions, drag/free position and arrow nudging; local canvas/no upload; publisher-described | Directly supports FM's two default lower corners plus deterministic arrow nudging and a custom colour palette |
| [PhotoVoid Timestamp](https://photovoid.com/en/tools/photo-timestamp/) | Minimal date/time mark designed to remain legible on the image | EXIF DateTimeOriginal, nine positions, proportional sizing, outline/backdrop guidance; local processing; publisher-described | Supports normalized sizing and a legibility-safe area; FM must store geometry independently of the Renderer |
| [EXIF Styler](https://benrilab.com/en/app/exif-styler/) | White-border or image-overlay information card showing camera/lens/EXIF details | White borders, camera/lens/aperture/ISO/date, layouts, colours and fonts, client-side processing; publisher-described | Strong evidence for separating Card content from Layout/Form: a future FM card can combine time meaning with a consciously chosen substrate |

### 12.2 Analog-camera products

| Product | Primary promise | What is relevant to FM | Boundary for MemoMark |
| --- | --- | --- | --- |
| [Dazz Cam - Vintage Camera](https://apps.apple.com/us/app/dazz-cam-vintage-camera/id1422471180) | One-tap camera experiences sampled from real film stocks and retro formats | Film identity is expressed by a coordinated camera preset, colour response and texture | FM is a presentation Renderer for an existing memory photo, not a new camera capture system or a general film-stock catalogue |
| [FIMO - Analog Camera](https://apps.apple.com/us/app/fimo-analog-camera/id1454219307) | Skeuomorphic point-and-shoot cameras, film-roll interaction, dust, scratches, light leaks and grain | Physical-camera metaphors make the style memorable, but are not necessary for a post-capture memory Renderer | Avoid adding a camera body, roll simulation, shutter sounds or film development queue to the Configuration Center |
| [NOMO CAM - Point and Shoot](https://apps.apple.com/us/app/nomo-cam-point-and-shoot/id1362548649) | Minimal point-and-shoot experience focused on taking the photo rather than post-production | Reinforces that a constrained preset can be more legible than a large editor | FM should expose a small number of stable choices and a large, direct calibration preview |
| [Huji Cam](https://apps.apple.com/us/app/huji-cam/id781383622) | Disposable-camera nostalgia and the familiar small date impression | The date mark is part of the camera's identity, not the only visual effect | Use the date as the recognisable FM anchor while keeping MemoMark's time-result content user-composed |

### 12.3 White-border, instant-photo and caption-substrate products

| Product or pattern | Observed form | FM implication |
| --- | --- | --- |
| [No Crop Border & Frame Editor](https://apps.apple.com/us/app/no-crop-border-frame-editor/id6759188840) | Full photo preserved inside a solid, gradient, pattern or blur border; includes Film Frame and Polaroid presets, exact border width and film grain | A substrate can be a deliberate presentation choice, but border geometry should remain a Layout concern and must not alter the existing Classic White Renderer |
| [PixFrame: Frames & Collage](https://apps.apple.com/ca/app/pixframe-frames-collage/id6748721755) | White borders, Polaroid/film-strip/retro-paper/minimal whitespace templates, plus EXIF watermark cards | Confirms a spectrum from image-overlay to information-card output; FM v1 should choose one primary overlay form and keep substrate optional |
| [Polaroid photo-frame pattern](https://found-tools.com/en/polaroid-photo-frame-export/) | Image sits above a visibly larger lower caption area on a light instant-photo frame | Useful for a secondary FM treatment or future Preset; it is not a reason to modify the frozen Classic White/Minimal layouts |
| [Film strip / Polaroid layout pattern](https://shadcn.io/blocks/features-photo-booth-strip-layout) | Repeated image cells and film-strip framing create an album/contact-sheet reading | This is a different composition class from FM's single-image timestamp; keep it out of the first Renderer contract |

### 12.4 Hardware conventions

The date imprint conventions in compact-camera manuals remain a useful source
of visual evidence. [Fujifilm's XP140 manual](https://app.fujifilm-dsc.com/en/manual/xp140/xp140_omw_en_s_f.pdf)
documents date/date-time imprint options, while the [Kodak AZ526 manual](https://support.kodak.gtcie.com/wp-content/uploads/2022/10/az526-manual-en.pdf)
and [Casio EX-Z270 manual](https://support.casio.com/pdf/001/EXZ270_MF_FB_090410_E.pdf)
show the enduring convention of a small lower-right date or date-time mark.
This is evidence for a familiar visual grammar, not evidence that FM should
hard-code a lower-right-only placement.

### 12.5 Cross-sample findings

Across the sample set, five patterns are stable enough to inform the next
Product Design Review:

1. **The lower corner is the strongest recognition cue.** Digital-camera and
   film-date products repeatedly use a compact lower-corner mark. Dragging,
   corner presets and arrow nudging appear as different precision levels for
   the same underlying need: keep the mark close to the edge without covering
   the subject.
2. **Seven-segment is a date-specific signal, not a universal text font.** It
   works for numeric capture time, but mixed Chinese/English Memory Engine
   results need a readable mono or system fallback. FM should therefore model
   font choice per resolved text run or use a compatible mixed-font strategy;
   it must not silently render unsupported CJK glyphs as empty boxes.
3. **There are three distinct output forms.** (a) a burned-in digital mark,
   (b) a soft mark that visually belongs to the photograph, and (c) a white or
   paper-like information substrate. They should be selectable forms of FM,
   not three unrelated Renderer implementations. The first build should make
   (a) excellent, offer a restrained version of (b), and defer a full (c)
   treatment until its Card geometry is specified.
4. **Control breadth is wide in the market, but the high-value controls are
   narrow.** Position, size, colour, opacity, date source and preview recur;
   GPS, weather, logos, cloud projects, batch, video and markup belong to other
   product categories. FM's proposed scope remains intentionally small.
5. **Metadata truth is a differentiator.** Several products describe reading
   EXIF capture time and/or preserving EXIF. MemoMark should treat capture time
   as a resolved Metadata/Memory input, distinguish it from export time, and
   never make the Renderer infer memory meaning from the current clock.

### 12.6 Recommended FM decision set after the expanded scan

The sample scan strengthens, rather than changes, the current FilmMark
proposal:

- Default the active mark to **lower-right**, with **lower-left** as the second
  saved starting position. These are two mutually exclusive starting presets,
  not two simultaneous overlays.
- Keep the first preview as one large photo calibration surface. Directional
  buttons should move the resolved object by a deterministic normalized step;
  the visible position summary should make the result inspectable and
  accessible.
- Start with two typography roles: **DSEG** for numeric digital-camera
  expression and **IBM Plex Mono** for mixed, calmer metadata. Use a system
  CJK fallback where required. JetBrains Mono and Space Mono remain comparison
  candidates, not a reason to add a font marketplace.
- Use amber as a named reference swatch, but provide platform colour picking
  and stable sRGB RGBA persistence so the user can choose white, red, yellow,
  green, blue or a muted custom tone without creating separate Renderer cases.
- Make softness/opacity and a subtle backing treatment explicit, bounded form
  controls. Do not let them become hidden image-dependent behaviour that makes
  preview and export disagree.
- Keep white-border/paper substrate as an optional FM form only after its
  content window, safe area, and export geometry are specified. Never borrow or
  modify the existing Classic White layout to implement it.

These recommendations are sufficient to enter a Product Design Review, but
they do not by themselves authorize production source changes. The next
engineering slice remains the isolated FilmMark Layout Engine prototype,
contract tests, and a real-preview/export parity proof before adding a new
persisted presentation style to the production configuration enum.

## 13. COS review adjustments accepted (2026-09-14)

The read-only COS review of the first Layout Engine slice confirmed that the
prototype can proceed, while identifying three changes that are now part of
the contract before UI work:

- Persist physical image anchors as `bottomLeft` and `bottomRight`, not
  `bottomLeading` and `bottomTrailing`. The UI may localize the labels, but the
  stored meaning must not mirror under RTL.
- Represent normalized offsets with fixed precision (`10_000 units = 1.0`,
  `50 units = 0.005`) so repeated arrow-key nudges do not accumulate hidden
  floating-point drift.
- Add one `FilmMarkCoordinateBridge` from the top-left UI coordinate domain to
  the bottom-left Core Graphics/artifact domain. Preview, Renderer, still
  export, and Live Photo must not each perform their own Y conversion.

COS also confirmed that production registration remains deferred: adding a
`RecordCardPresentationStyle.filmMark` case would immediately expand the
existing `allCases`, Template, durable configuration, and production snapshot
contracts. The next accepted slice is still pure FM Layout Engine plus focused
tests; existing Classic White and Minimal remain untouched.
