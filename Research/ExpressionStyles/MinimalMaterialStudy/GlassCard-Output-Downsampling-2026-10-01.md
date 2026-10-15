# GlassCard output downsampling and display geometry

Product Loop, P2 research. Small direct outputs in the texture probe are not downsampled full-size outputs. Resolve at production source dimensions, render the actual Overlay/artifact first, then resize its raster with CoreGraphics high interpolation. Compare 3:4, 4:3, 9:16 and 16:9 source canvases, display widths 320/360/600 points and 1x/3x raster densities. Use H glyphs and short Chinese text. Keep text, geometry and material fixed; no production change.

Measure scaled fitted font size in display coordinates, mask maximum relative to configured text opacity, and sampled mask counts at 75% and 90% coverage thresholds. Retain zero-core cases as observations, not probe failures. High-density pixel count is not a larger physical font size. A high-quality CG bitmap resize is one explicit research kernel, not a claim about SwiftUI/Photos/UIKit GPU sampling. Native macOS build/test; no Simulator, no external sources or private photos. This provides typography evidence before any Layout change.

## Measured result

192 rows: 4 source aspect ratios × 2 fixtures × 3 display widths × 2 raster densities × 4 positions. The H and short Chinese fixtures fit without shrinking; font figures below are fitted output sizes scaled to display coordinates. Each orientation/density summary has 8 groups (2 fixtures × 4 positions).

| Source ratio | Display width | Primary / secondary display font | 1x groups with no 90% samples | 3x groups with no 90% samples |
| --- | --- | --- | --- | --- |
| 3:4 portrait | 360 | 8.649 / 6.571 | 2/8 | 0/8 |
| 4:3 landscape | 360 | 6.486 / 4.928 | 5/8 | 0/8 |
| 9:16 portrait | 360 | 8.649 / 6.571 | 2/8 | 0/8 |
| 16:9 landscape | 360 | 4.865 / 3.696 | 6/8 | 0/8 |

Across all 32 orientation/fixture/slot groups, 1x loses 90% samples in 16 groups at width 320, 15 at 360 and 2 at 600. 3x retains samples in every group at all three widths. Positive samples do not establish legibility; zero samples do not establish missing text. Larger raster density preserves strokes without changing logical display font size. At width 360, the minimum secondary count at 3x is 351/164/351/60 for the four ratios above; these are density-dependent pixel counts, not normalized physical ink areas.

Native rail-crop inspection confirms the 16:9 crop is much shorter with substantially smaller lettering than the 3:4 crop at equal width. This is not merely a material contrast issue. The current short-edge proportional geometry deliberately makes the landscape rail shallower; increasing font ratios without increasing row height risks clipping, fit overflow and crowding around the fixed badge/divider.

## Sampling limitation found

The maximum mask alpha divided by configured ink opacity sometimes exceeds 1: approximately 1.0008 from byte rounding and up to 1.0417 with the high-quality resize. Thus `maxRelativeCoverage` is a normalized sampled-alpha diagnostic, not an exact geometric coverage estimate. The explicit CG high-quality kernel can overshoot; do not interpret larger counts as new glyph information. SwiftUI and Apple Photos may use different sampling/filter kernels. This harness does not reproduce UIKit screen drawing, physical phone appearance or Photos zoom behavior.

## Bounded typography research requirements

Keep four positions, authored content, badge/divider anchors and one source-derived Layout plan. Keep previews scaled from output plans; do not repair small previews by independently enlarging/re-fitting text. Compare at equal displayed width and density, with short/boundary/long authored text and Chinese/English/Japanese/Korean fixtures before accepting any layout change.

Candidate A retains present photo-relative output geometry and uses existing enlarged inspection to judge detail; it has least output compatibility risk but small fit previews remain limited. Candidate B makes landscape panel/font sizing less dependent on the short edge, with all geometry still owned by Layout; it increases coverage of the photograph and requires an explicit bounded product specification plus device acceptance. For scale of the tradeoff, using 0.13 × photo width instead of short edge would take a 16:9 rail from 13% to about 23.1% of photo height, before inset/shadow, while restoring portrait-reference font sizes at equal width. This is an illustrative arithmetic alternative, not an accepted constant or proposed silent default. Do not add a third renderer-specific font compensation path.

Next implementation experiment should compare the current layout with a bounded landscape sizing candidate inside research tooling, quantify content-fit and covered area, then show native outputs. Production acceptance needs the owner only if the established visual form changes; reversible research and verification can continue without another permission step.

## Verification and artifacts

One macOS probe executed and passed, zero failures/skips (`/tmp/MemoMarkGlassCardDownsample.xcresult`); application and test builds completed as part of that run. This slice changes research files only, so no production iOS source changed since the prior build. Raw CSV, summary and four 360-wide 1x rail crops are local in `$HOME/Documents/Codex/2026-10-01/GlassCardOutputDownsampling/`. Temporary test copy removed after byte equality with the retained source. No simulator, photo upload, private source, default recipe or Layout change.
