# G2b texture contrast measurement

Product Loop, P2 research only. Previous row extrema can pair an unrelated dark background pixel with a bright glyph. This slice uses a text-only alpha mask rendered by the same Overlay, samples glyph core pixels (mask alpha >= 90% of that row's configured ink opacity), and compares the text composite with a no-text composite at identical source coordinates. Report count, minimum, 10th percentile and median; no WCAG or complex-photo certification.

Compare existing 0.42/0.78, priority 0.56/0.96 and heavier 0.62/0.78 at 360/1080 short edges on bright checker, full-range checker, fine stripes and grayscale gradient. Synthetic sources isolate texture scale; no private photos, production recipe, layout or media change. Textless plan keeps geometry and material constant. Alpha mask disables material/keyline/shadow while retaining the same text engine and glyph positions. Native CoreGraphics and ImageRenderer; retain CSV and representative crops. macOS probe build/test, no Simulator; no new production change requires a repeated iOS build from the prior verified source.

## Results and interpretation

Final matrix: 3 candidates × 2 output sizes × 4 textures × 4 slots × 2 mask thresholds = 192 rows. Masks select alpha >= 75% or 90% of the configured row ink opacity. All groups have positive sample counts; every sampled foreground/background comparison exceeds 1.0. These are same-coordinate diagnostics, not peak comparisons across different pixels.

| Surface / secondary opacity | Mask threshold | Worst minimum | Worst p10 | Worst median | Groups with minimum below 4.5, of 32 |
| --- | --- | --- | --- | --- | --- |
| 0.42 / 0.78 | 90% | 2.476 | 2.476 | 2.547 | 26 |
| 0.56 / 0.96 | 90% | 4.605 | 4.647 | 5.214 | 0 |
| 0.62 / 0.78 | 90% | 4.383 | 4.383 | 4.562 | 12 |
| 0.42 / 0.78 | 75% | 2.180 | 2.314 | 2.694 | 27 |
| 0.56 / 0.96 | 75% | 3.740 | 4.198 | 5.214 | 24 |
| 0.62 / 0.78 | 75% | 3.632 | 3.996 | 4.981 | 12 |

The worst minimum, p10 and median in each summary may come from different groups; this is not one pooled distribution. p10 uses the sorted sample at floor(0.10*(n-1)). The 90% priority-candidate minimum comes from 360 bright-checker right-bottom (15 core pixels). The 90% heavier-candidate minimum comes from 360 bright-checker left-bottom (10 core pixels). Sparse masks on small glyphs limit statistical and perceptual conclusions. The 75% priority-candidate minimum comes from 1080 bright-checker left-top; its group p10 is 5.080, so a few partially covered pixels dominate the minimum.

Decision update: 0.62/0.78 must no longer be described as a passing readability alternative; it only passed the previous peak diagnostic. 0.56/0.96 remains the leading research candidate for strongly covered glyph cores, but has limited margin and threshold-dependent minima. Partial glyph coverage normally lowers pixel contrast; demanding 4.5 at every antialiased edge would be an inappropriate acceptance rule. This measurement cannot itself select a default or certify perception. Bright detail remains visible through the fixed backing. Further work should independently measure output-downsample/display-scale glyph survival and consider bounded ROI detail suppression; more opaque backing alone is not a complete strategy.

Scope limits: monochrome synthetic textures, H glyphs, macOS rasterizer, 360×480 and 1080×1440 output canvases. Texture cells are 8 source pixels and stripes have a 4-pixel period at both sizes, intentionally testing two relative frequencies; there is no complex-photo or same-angular-frequency sample claim. The 360 output is not a simulation of a 1080 output downsampled into a 360 preview. No UIKit, HDR, motion stability, real Photos lifecycle or physical appearance acceptance was performed.

Verification: initial 90% probe and final sensitivity probe each executed one macOS research test and passed, zero failures/skips. Final result `/tmp/MemoMarkG2b-texture-sensitivity.xcresult`; raw CSV/summary/crops `$HOME/Documents/Codex/2026-10-01/GlassCardTextureContrast/`. No production code changed in this slice. Native macOS application/test builds ran as part of the probe; the previously verified iOS source remains unchanged. Temporary test copy removed after byte equality with retained research source.
