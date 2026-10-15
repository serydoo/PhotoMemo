# GlassCard vertical capacity with horizontal compatibility

Product Loop, P2 research only. Prior proportional panel enlargement reduced accepted string capacity. Compare that baseline experiment with a research plan preserving original slot x/width, horizontal padding, badge size/center x and divider center/width. Increase panel and row heights under existing Layout geometry; center the original badge vertically and increase divider height. Preferred font follows taller rows, while absolute minimum font remains the baseline's. No production layout, minimum-scale policy or default changes.

Research constructs explicit resolved inputs using existing Layout frames and TextFit engine; Renderer merely consumes them. The research plan is not a second production layout owner. Compare 4:3/16:9, four height multipliers, Chinese/English/Japanese/Korean and three lengths. Assert baseline-equivalence at multiplier 1, unchanged horizontal frames, authored text identity, and no loss of baseline-fitting slots. Retain overflow and covered area, with locally bundled photo comparison. Native macOS build/test; no Simulator or external/private data.

## Result

768 fit records compare proportional and horizontally compatible research inputs across the same 384 cases per mode. Baseline geometry and fitted results at multiplier 1 are asserted equal. Every previously fitting slot remains fitting in the compatible mode. The analyzer also asserts the sampled per-position minimum fitted display font does not fall below the baseline minimum (0.001 rounding tolerance).

| Aspect | Multiplier | Proportional overflowing / 48 | Compatible overflowing / 48 | Compatible newly overflowing | Compatible previously fitting slots gaining >0.02 display units |
| --- | --- | --- | --- | --- | --- |
| 4:3 | 1.0 | 30 | 30 | 0 | 0 |
| 4:3 | 1.2 | 31 | 30 | 0 | 13 |
| 4:3 | 1.333 | 35 | 30 | 0 | 13 |
| 4:3 | 1.4 | 37 | 30 | 0 | 13 |
| 16:9 | 1.0 | 22 | 22 | 0 | 0 |
| 16:9 | 1.2 | 26 | 22 | 0 | 18 |
| 16:9 | 1.4 | 30 | 22 | 0 | 18 |
| 16:9 | 1.778 | 35 | 22 | 0 | 18 |

The font gain count is descriptive, not a perceptual threshold or improvement rate. Equal gain counts do not imply equal font sizes: short text can continue growing; width-constrained content has limited gains. No baseline-overflowing slot becomes fitting, since horizontal space and the absolute lower font bound remain unchanged. Research fixtures deliberately include long/repeated text and do not model a user failure rate.

Covered area is identical to the proportional candidate at the same panel height: 16:9 capsule area grows from 12.53% to 14.99%/17.43%/22.00%. The revised strategy removes the measured string-capacity regression; it does not remove the photo-coverage tradeoff. The 600-wide local calibration comparison shows clearer short text without the larger badge of the proportional variant. At the strongest multiplier, text dominates relative to the fixed badge and more foreground is covered. It is not automatically a better visual default.

## Current research decision

Retain 1.2 and 1.4 compatible candidates for further coverage/reading comparisons; use the width/short-edge candidate as an upper-bound comparator, not a default. Do not grow production geometry merely because this fixture matrix retains fit. A revised minimumScale relative to the taller panel is used only in the research plan, with the baseline absolute font floor unchanged; the accepted production text-fit policy is not modified. Before adoption, move any accepted rule into a scoped Layout specification and verify short/boundary/long strings, empty positions, portrait control, preview/export parity, UIKit fonts, real Photos and device appearance. Evidence is not sufficient to freeze a multiplier.

Next bounded research can compare the 1.2/1.4 candidates at actual 1x/3x output downsampling and a representative brighter source, with the typography and material candidates fixed separately. Background detail suppression remains an independent study; increased panel height does not solve high-frequency texture behind glyphs.

## Verification

One macOS probe actually executed and passed, zero failures/skips (`/tmp/MemoMarkGlassVertical.xcresult`), with app/test builds completed. Raw CSV, summary and native four-row comparison are local in `$HOME/Documents/Codex/2026-10-01/GlassCardVerticalCapacity/`. Analysis assertions passed. This slice changes research files only; no production source, persisted fields or defaults changed. No Simulator, network upload, private source or device certification. The temporary test copy was removed after byte equality with the retained source.
