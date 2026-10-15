# GlassCard vertical candidate display validation

Product Loop, P2 research only. Validate compatible 1/1.2/1.4 resolved inputs after native output composition and explicit high-quality CG resampling. Compare 4:3/16:9, H/short Chinese, 320/360/600 logical widths, 1x/3x raster density, white/bright checker backgrounds and four slots (576 rows). Fix material at candidate 0.56/0.96. Render textless backing at the same candidate geometry and a clear-surface glyph mask through the same Overlay; compare same-coordinate foreground/backing pixels only where resampled mask alpha reaches 90% of configured ink opacity.

Record absent-core groups explicitly, not as passed contrast. Sampling alpha may overshoot; the mask is a kernel-dependent diagnostic rather than geometric coverage or a UIKit claim. Preserve input strings and baseline absolute font floor via the retained research helper. Production source/config/defaults unchanged. Native macOS probe/build, no Simulator, private photos or uploads. Pair this evidence with prior content-fit and coverage costs before choosing a candidate.

## Final measured matrix

576 rows: 2 aspects × 3 multipliers × 2 fixtures × 3 display widths × 2 densities × 2 backgrounds × 4 slots. Every absent 90%-mask group records NA contrast rather than a passed result. Sampled ink mass is the sum of resampled mask alpha divided by configured opacity and density squared, averaged over the summary groups. It describes sampled alpha quantity, not physical ink area or reading performance; kernel overshoot and byte rounding remain present.

At logical display width 360, each aspect/multiplier/density summary has 16 groups (2 fixtures × 2 backgrounds × 4 slots). Background duplicates of the same mask are intentional because paired contrast uses different composites; zero-mask counts therefore double the corresponding 8-group glyph-only count.

| Aspect | Multiplier | Primary/secondary display font | Absent 90% groups at 1x, /16 | Mean sampled alpha mass at 3x | Minimum sampled contrast at 3x | Lowest group p10 at 3x |
| --- | --- | --- | --- | --- | --- | --- |
| 4:3 | 1.0 | 6.486/4.928 | 10 | 58.773 | 4.563 | 4.732 |
| 4:3 | 1.2 | 7.784/5.914 | 4 | 81.240 | 4.563 | 4.689 |
| 4:3 | 1.4 | 9.081/6.899 | 2 | 107.695 | 4.563 | 4.689 |
| 16:9 | 1.0 | 4.865/3.696 | 12 | 33.144 | 4.526 | 4.605 |
| 16:9 | 1.2 | 5.838/4.435 | 14 | 45.823 | 4.470 | 4.647 |
| 16:9 | 1.4 | 6.811/5.174 | 10 | 60.796 | 4.470 | 4.689 |

All 3x groups have mask samples. In 16:9, 1.2 and 1.4 each have two of 16 sampled groups with minimum below 4.5. They occur on bright checker, with minima 4.470/4.485 and group p10 values 4.774–5.062. These tail pixels must remain visible in evidence; they do not establish whole-text failure. At 4:3/1.2/1x one raw minimum is 4.499948, which should be treated as a numerical borderline rather than a meaningful binary distinction. Sampling/quantization sensitivity forbids using minimum alone to select a material.

The 16:9 1.2 candidate has fewer 90%-mask groups at 1x despite more sampled alpha mass and larger fonts. Thus a high-threshold count is not monotonic in readability; font metrics, subpixel alignment and the specified resize kernel affect it. At 1x/3x, mean mass for the three 16:9 candidates is 33.311/33.144, 46.224/45.823, 61.607/60.796. Cross-density closeness supports the broad stroke-quantity trend, not proof of physical legibility.

## Candidate disposition

Retain compatible 1.2/1.4 as research candidates with the previously proven fixture-fit compatibility. 4:3/1.2 offers a moderate size increase; 16:9/1.4 offers a more substantial increase while remaining below the rejected ~1.778 upper-bound area. This suggests an aspect-aware bounded rule may be worth a specification, but no interpolation function or production multiplier is accepted here. Candidates still have photo-covering cost and some texture contrast tail pixels. Native cropped inspection shows bigger Chinese characters at 1.4, with fine background texture still visible. Do not simultaneously raise material opacity to hide the remaining texture without a separate comparison.

Next work should isolate bounded source ROI detail suppression at fixed typography, with unchanged source outside the panel, documented blur halo/working color space, uniform-white control, texture reduction and buffer costs. Prove benefit before adding any moving-photo compositor or refraction. Physical UIKit/Photos/device evaluation remains mandatory for acceptance.

## Verification

Initial probe and final alpha-mass probe each actually executed one macOS test and passed, zero failures/skips; final `/tmp/MemoMarkGlassVerticalDisplay-mass.xcresult`. App/test builds completed. CSV validation asserts 576 records and NA handling for absent-mask groups. Final raw CSV, summary and six 360-wide 1x crops are local at `$HOME/Documents/Codex/2026-10-01/GlassCardVerticalDisplay/`. This slice changes research files only, not iOS source/defaults. No repeated iOS build or device deployment is claimed. Temporary probe removed after byte equality with retained source. No Simulator, upload or private photo input.
