# G2b — Fixed material readability candidate screening

Product Loop, P2 bounded research. Actual Renderer output on uniform white measured primary/secondary peak pixel contrast 3.250/2.694 at 1080. Compare surface black alpha 0.42/0.50/0.56/0.62 and secondary foreground alpha 0.78/0.96; primary stays 0.96. All samples use one rule, fixed geometry, fonts and keyline; no scene classification, photo upload, schema, production default change, blur or refraction.

Add explicit internal Overlay research inputs with defaults equal to the existing production recipe and text opacities. Production planner, preview and media callers continue using defaults. Research harness renders the same Overlay and cropped PresentationArtifact through the real compositor on synthetic SDR backgrounds at 360×480 and 1080×1440. Extract sRGB row luminance extrema and attach images/CSV. This measures a controlled upper-bound diagnostic, not glyph-local contrast or photos/accessibility/HDR certification. Missing 4.5 peak contrast rejects a candidate; passing it merely admits further visual screening. Use existing CoreGraphics/ImageRenderer, keep Layout ownership unchanged.

Verification: existing production/preview regression must continue passing; research must reproduce baseline within rounding before candidate ranking; macOS tests and signed device build. No Simulator. Physical appearance remains a separate gate. Candidates are experimental; final dark-versus-translucent visual positioning needs owner acceptance if that product direction changes.

## Controlled SDR screening result

192 row measurements: 8 combinations × 2 output sizes × 3 backgrounds × 4 positions. Baseline reproduced within 0.02 contrast tolerance. Worst sampled peak contrast includes the compact 360 output's glyph coverage.

| Black surface alpha | Secondary opacity | White primary at 1080 | White secondary at 1080 | Minimum sampled peak contrast | Admits further screening |
| --- | --- | --- | --- | --- | --- |
| 0.42 | 0.78 | 3.250 | 2.694 | 2.620 | No |
| 0.42 | 0.96 | 3.250 | 3.250 | 3.139 | No |
| 0.50 | 0.78 | 4.230 | 3.376 | 3.282 | No |
| 0.50 | 0.96 | 4.230 | 4.230 | 4.085 | No |
| 0.56 | 0.78 | 5.214 | 4.081 | 3.965 | No |
| 0.56 | 0.96 | 5.214 | 5.214 | 5.035 | Yes |
| 0.62 | 0.78 | 6.551 | 4.981 | 4.792 | Yes |
| 0.62 | 0.96 | 6.551 | 6.551 | 6.271 | Yes |

The least opaque passing *sampled* surface is 0.56 with secondary text 0.96. This does not establish the mathematical minimum alpha; only four values were tested. Increasing text opacity alone is insufficient, and 0.56 with the existing secondary opacity remains insufficient. Stronger fixed opacity can meet this controlled screen at the cost of obscuring source detail; no blur/refraction benefit is established here. A peak bound above 4.5 does not prove local readability in complex backgrounds or small fonts.

First run: 33 tests / 36 executions, zero failures/skips, including one candidate measurement probe and the existing production/preview/Minimal suites (`/tmp/MemoMarkG2b-candidates.xcresult`). Generic iOS Debug compile passed with signing disabled (`/tmp/MemoMarkG2b-ios-build.log`); this is compilation evidence, not a signed deliverable or new device deployment. Paired iPhone 17 Pro Max still reports unavailable. Raw CSV, white-background PNGs and summary are local at `$HOME/Documents/Codex/2026-10-01/GlassCardMaterialCandidates/`.

## Calibration visual screening

A separate research test renders the locally bundled portrait and landscape photograph through the candidate Overlay and real artifact compositor, then produces three-column comparison sheets (baseline 0.42/0.78, 0.56/0.96, 0.62/0.78). Both are displayed at 360 pixels per photo width. One targeted method executed and passed (`/tmp/MemoMarkG2b-calibration.xcresult`); two PNGs are in the stable output directory. This sample is relatively dark under the rail and cannot certify the bright-background candidate.

Visual inspection: stronger backing gives modest benefit on this dark sample and hides more original detail; brighter secondary text improves visibility while reducing luminance hierarchy. The landscape rail at 360-wide is visibly very small: a 16:9 photo has only about 202 display pixels on the short edge. The existing short-edge font rule therefore produces smaller displayed text than a 360-wide portrait. This is a separate typography/display-scale research question, not grounds for another silent alpha or font-size tweak. No layout/typography changes were made.

Decision: prioritize 0.56/0.96 for subsequent bright-photo/texture comparisons; retain 0.62/0.78 as the hierarchy-preserving, heavier comparator. No final material was accepted or made default. Next bounded research should measure local glyph/background contrast over bright textures, include dark samples to assess backing cost, and specify display-size readability separately. A source-responsive material is justified only if one deterministic rule beats fixed backing without unstable Live Photo brightness or extra uncontrolled memory cost.

The temporary probe file was removed only after byte equality with the retained research source. No private data was added to Git, no external upload or simulator was used. Existing production callers retain the original default recipe and secondary alpha.

### Superseding texture evidence

The follow-up same-coordinate glyph-mask study in `GlassCard-Texture-Contrast-G2b-2026-10-01.md` narrows the previous peak screening: 0.62/0.78 has 12 of 32 texture/size/slot groups below 4.5 even at the 90% core threshold. It remains a heavier comparator, not a passing readability alternative. 0.56/0.96 remains leading at the 90% threshold (minimum 4.605), with weaker partially covered pixels at the 75% threshold (minimum 3.740). Neither result certifies perception or establishes a default.
