# GlassCard bounded landscape sizing experiment

Product Loop, P2 research; internal default-preserving Layout seam. Current 360-wide 16:9 output has fitted short-text fonts about 4.865/3.696. Compare panel height multipliers 1.0, 1.2, 1.4 and width/shortEdge (portrait-reference sizing) only for landscape. Preserve bottom/horizontal insets and normalized position anchors; badge/divider/row geometry scales with panel height under the existing Layout owner. No persisted configuration or production multiplier change.

Add a default-1 panel-height multiplier to Layout resolution and resolved presentation. Use it only in the research harness. Existing callers retain identical calculations. Verify default equality, bounded geometry, badge/divider spacing, content-fit across Chinese/English/Japanese/Korean short and repeated fixtures, and actual bundled landscape output comparison. Record capsule area, height fraction, fitted display font at width 360 and overflow rather than selecting by apparent font size. Renderers consume resolved frames, never make new layout choices. Regression tests/build and generic iOS compile; physical acceptance remains open. A final enlarged visual form needs explicit owner acceptance after concrete comparison.

## Result

384 fit rows: 2 aspect ratios × 4 multipliers × 4 languages × 3 authored lengths × 4 positions. Long/repeated fixtures deliberately exercise boundaries; these counts are not user failure rates. All sampled badge/divider/column separation assertions passed.

| Aspect | Height multiplier | Panel height/photo height | Capsule area/photo area | Overflowing slots / 48 | Newly overflowing vs baseline |
| --- | --- | --- | --- | --- | --- |
| 4:3 | 1.0 | 13.0% | 12.38% | 30 | 0 |
| 4:3 | 1.2 | 15.6% | 14.79% | 31 | 1 |
| 4:3 | 1.333 | 17.33% | 16.38% | 35 | 5 |
| 4:3 | 1.4 | 18.2% | 17.18% | 37 | 7 |
| 16:9 | 1.0 | 13.0% | 12.53% | 22 | 0 |
| 16:9 | 1.2 | 15.6% | 14.99% | 26 | 4 |
| 16:9 | 1.4 | 18.2% | 17.43% | 30 | 8 |
| 16:9 | 1.778 | 23.11% | 22.00% | 35 | 13 |

No sampled previously overflowing slot became fitting. At 16:9/1.2, newly overflowing cases are Chinese 42 characters right-bottom, English 90 characters right-bottom, Japanese 42 characters right-bottom, Korean 46 characters right-top. These are authored fixture lengths, not proposed character limits. Raising the panel also raises preferred/minimum fonts and height-derived horizontal padding, so more height does not imply more string capacity.

At 360 display width, unshrunk 16:9 primary/secondary fonts rise from 4.865/3.696 to 5.838/4.435 at 1.2, 6.811/5.174 at 1.4 and 8.649/6.571 at width/short-edge sizing. Actual fitted long-string sizes remain lower and may overflow. Capsule area excludes shadow and says nothing about subject occlusion or perceptual weight.

A four-row native-output comparison uses the bundled landscape sample and fixed candidate material 0.56/0.96 at 600 display width. The actual calibration source uses encoder-safe 1672×942 geometry, so its reference factor is about 1.775 rather than the exact 16:9 matrix's 1.778. Visual inspection confirms clearer short text with a taller, heavier foreground rail. Native PNG at `$HOME/Documents/Codex/2026-10-01/GlassCardLandscapeSizing/landscape-sizing-comparison.png`.

## Decision and next bounded experiment

Reject mechanical proportional enlargement as a replacement default: even 1.2 loses previously accepted content and provides only limited display-size improvement. Production remains multiplier 1. Future research should preserve existing horizontal slot space and source-normalized anchors, decouple badge/padding sizing from extra vertical capacity, and retain a compatible absolute minimum-font floor while comparing larger preferred fonts for short text. This is a research proposal, not an accepted lower fitting-scale policy; prove previously fitting content remains fitting before considering it. Keep all geometry in Layout and the same resolved plan in preview/export; do not add preview-only typography compensation or silently alter durable content.

## Verification

New geometry regression first failed to compile without the sizing seam, then passed after implementation. Final focused macOS run: 34 tests / 37 executions, zero failures/skips (`/tmp/MemoMarkGlassSizing-green.xcresult`), including existing export/preview/Minimal coverage and research probe. Generic iOS Debug build with signing disabled passed (`/tmp/MemoMarkGlassSizing-ios.log`). Paired iPhone 17 Pro Max still unavailable; no signed deployment or physical visual acceptance in this slice. No Simulator was used. Default production calls retain multiplier 1; the parameter is not persisted or exposed in user controls. Temporary probe removed after byte comparison with retained research source. Working tree remains uncommitted; unrelated user changes preserved.
