# GlassCard bounded ROI blur experiment

Product Loop, P2 research only. Fix the compatible 16:9 1.4 layout and 0.56/0.96 material. Compare Gaussian radius 0/2.5%/5%/10% of panel height on white, bright checker, full checker, fine stripes and gradient. Process a source crop expanded by ceil(4*radius+2), clamped to the original image bounds; this is an experimental halo heuristic, not an Apple kernel-support guarantee. Clamp the crop before filtering, use explicit sRGB working/output profiles, clip the result to the original rounded panel and copy onto a new image. No source files or production compositor change.

Verify sRGB synthetic source pixels with zero panel-mask coverage remain byte-identical, white-control output stays within one byte, and compare ROI blur against full-input blur inside panel bounds (one-byte tolerance). Record row background horizontal luminance difference, standard deviation, and same-coordinate glyph-core contrast using the existing clear-material text mask. Gaussian blur cannot change uniform white into a darker substrate. Retain halo crop byte arithmetic, not a peak-memory or timing claim. Native macOS probe/build, no Simulator/upload/private photos. Live Photo per-frame stability and wide-color/HDR remain separate.

## Measured result

80 rows: five synthetic sources × four blur radii × four text positions. The panel is 196.56 source pixels tall; radii are 0, 4.914, 9.828, 19.656. The texture measure is mean horizontal adjacent-pixel linear-luminance difference in textless backing row crops, averaged over four positions. It is a directional synthetic-texture diagnostic, not general visual quality or glyph-local structure segmentation.

| Source | Radius | Adjacent difference relative to no blur | Lowest core contrast | Lowest row p10 |
| --- | --- | --- | --- | --- |
| Uniform white | 0 | undefined (both zero) | 4.647 | 5.214 |
| Uniform white | 4.914/9.828/19.656 | undefined (both zero) | 4.647 | 5.214 |
| Bright 8-pixel checker | 0 | 100% | 4.647 | 5.214 |
| Bright 8-pixel checker | 4.914 | 3.22% | 5.733 | 6.494 |
| Bright 8-pixel checker | 9.828/19.656 | 0% at 8-bit measurement | 5.823 | 6.596 |
| Full-range 8-pixel checker | 4.914 | 2.44% | 9.593 | 11.280 |
| Bright 4-pixel stripes | 4.914 | 0% at 8-bit measurement | 5.823 | 6.596 |
| Gradient | every radius | 100% | 7.465 | 8.612 |

No measured zero texture difference implies complete detail removal in arbitrary photographs. Larger-radius differences below quantization cannot establish equivalence on other scales. Blur leaves white control unchanged and improves high-frequency synthetic texture; luminance and texture responsibilities must remain separate. The smallest tested positive radius is preferred for continued research, not a universal optimum.

## Boundary and halo controls

For all synthetic cases, processed source pixels with zero rounded-panel-mask alpha are byte-identical to their sRGB source. White control differs by at most one byte under the assertion. Full-input Gaussian reference and halo-cropped Gaussian differ by zero bytes inside the panel bounding rectangle in the sampled cases (assertion allows one). The same bounds were checked on the local calibration image after explicit sRGB encoder-canvas normalization. This is not a guarantee for other kernels, radii, dimensions, P3 or HDR input. Antialiased boundary pixels with nonzero mask coverage legitimately blend the patch.

For 1920×1080, the three positive-radius halo RGBA crops are 1,812,480 / 1,966,080 / 2,265,600 bytes (1.729 / 1.875 / 2.161 MiB), compared with 8,294,400 bytes (7.910 MiB) for a full frame. These are bare crop buffer sizes only. The verification harness intentionally creates full source copies, masks, byte arrays and a full-input filter reference; it is not an optimized production path or BP-001/performance certification. CIContext cache settings are explicit but no peak/timing benchmark was performed.

## Calibration inspection

The locally bundled landscape image is normalized to encoder-safe 1672×942 sRGB before the experiment; its existing PNG is not modified. The same 1.4 typography and material are used with radius 0 and 4.2861. Both boundary/halo controls pass with zero differences; the positive-radius crop is 1,384,416 bytes. At 600-wide comparison, the dark foreground benefit is subtle. Blur should suppress distracting detail, not add a conspicuous decorative effect or claim true Liquid Glass.

## Disposition and next implementation boundary

Retain bounded ROI blur at 2.5% of panel height for further static-source study; do not integrate it into production or Live Photo yet. A source-aware material requires source pixels and working/output color policy, whereas the current production artifact is a source-independent fixed overlay. Adoption therefore belongs at an explicitly specified composition boundary with Layout-owned ROI geometry, not as a hidden background effect in the Renderer. Motion would require the same function on every properly oriented frame, temporal stability, original timestamps/identity, format and memory validation.

Next isolate a deterministic luminance constraint from detail suppression: compare the fixed black-alpha candidate with a bounded SDR luminance-compression research function, keeping blur and typography fixed. The function must be identical for every source, retain source outside the mask, preserve hue under the selected sRGB model, include white/dark/gradient controls and quantify midtone/detail cost. No scene preset, per-frame global-statistic tuning, HDR assumption or durable schema is authorized by this research note. Any accepted function needs its own material/color specification and preview/still/motion verification before production.

## Verification

Synthetic ROI probe: one macOS test executed and passed (`/tmp/MemoMarkGlassROIBlur.xcresult`). Calibration probe: one targeted method executed and passed (`/tmp/MemoMarkGlassROICalibration.xcresult`). Zero failures/skips; app/test builds completed. Source-boundary and halo assertions passed. CSV/summary, four synthetic rails, photo comparison and JSON controls are local in `$HOME/Documents/Codex/2026-10-01/GlassCardROIBlur/`. Temporary copy removed after byte equality with retained research source. Production source/defaults unchanged; no Simulator, private input, network upload, new iOS build/device acceptance or Photos/HDR/Live Photo certification.
