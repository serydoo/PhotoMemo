# G2a — GlassCard calibration preview text-fit parity

Engineering Loop; P1 preview fidelity. Measurement found seven scale-dependent fit decisions among 192 cross-scale groups. Configuration preview currently resolves at viewport size; export resolves at source pixel size. This slice resolves at the bundled, orientation-matched calibration photograph's encoder-safe pixel size and scales the complete overlay for display. A preview predicts that calibration photograph, not every possible source photograph.

Scope: ConfigurationPreviewBackground owns calibration asset dimensions; MemoryCardPreviewSurface consumes the canonical plan and scales its view. Layout and production export remain unchanged. Use native UIImage/NSImage asset decoding and SwiftUI scaleEffect; no persistent setting or new material. Missing sample dimensions must not silently invent a successful fit. Default orientation is landscape, consistently for photograph and plan. Minimal retains its existing behavior.

Verification: regression tests compare canonical output fits across viewport widths and validate both bundled photograph dimensions. macOS focused tests, generic iOS build and signed paired-device build/install/launch; device appearance remains a separate manual gate. Scaling a SwiftUI layer establishes measurement parity, not a claim of pixel-identical raster resampling or HDR certification.

## Implementation evidence

Bundled landscape/portrait PNGs are 1672×941 and 941×1672; encoder-safe geometry is read through native asset decoding, cached once per orientation. The preview resolves in those pixel coordinates and scales the overlay, including overflow feedback based on that canonical plan. The asset check failed to compile before the implementation and passed afterwards. Focused macOS verification: 31 tests / 34 executions, zero failures or skips (`/tmp/MemoMarkG2a-green.xcresult`). No Simulator was used.

Review finding: `GlassCardCardRenderer`, used by the generic card-view facade, also resolved from its GeometryReader viewport. This was included in the bounded follow-up below. Export artifacts already resolve from output geometry. Neither this slice nor its tests certify UIKit optical appearance, arbitrary-photo fit, VoiceOver, Photos round-trip, or motion/HDR fidelity.

## Follow-up within G2a

Review also found the generic card-view facade resolves at viewport size. Extend the same bounded correction to GlassCardCardRenderer: resolve from card metadata using the existing encoder-safe output-size owner, scale the resulting layer uniformly, and preserve the existing fallback when source dimensions are missing. Add a real renderer raster test at compact viewport dimensions. Production artifact generation and metadata remain unchanged.

## Final automated verification

Generic card preview now resolves from metadata-derived output pixel geometry and scales the whole overlay. The compact raster regression uses a 45-character English fixture whose 360×480 and 1080×1440 fits disagree, and compares the actual facade bitmap against an independently supplied output plan at the same viewport: exact bitmap data equality on macOS. Final focused run: 32 tests / 35 executions, zero failures or skips (`/tmp/MemoMarkG2a-final.xcresult`). Signed iPhone 17 Pro Max Debug build passed (`/tmp/MemoMarkG2a-device-final.log`), signature verification passed and overwrite-install succeeded. No simulator or external upload was used. Device appearance, accessibility and real Photos/Live Photo acceptance remain open.

Device launch was not confirmed: first attempt failed with CoreDevice error 3 / Mercury 1001 (connection invalidated); a fresh discovery then reported the same paired iPhone unavailable, and a single retry failed with CoreDevice 4016. Installation success must not be interpreted as launch success. Reconnect the paired phone to finish launch and manual appearance acceptance; no alternate phone, uninstall, or data reset was attempted.
