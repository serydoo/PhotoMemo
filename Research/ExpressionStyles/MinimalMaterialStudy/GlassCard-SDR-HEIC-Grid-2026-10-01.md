# Bounded HEIC local-grid support

Engineering Loop P1 research increment, driven by actual native synthetic 1024/2048/4096 HEIC outputs rejected at the all-item method0 guard. No production routing or default change. Preserve shared TIFF ownership and Exif method0/single-extent/mdat contract; native APIs own pixel decoding.

Plan: allow only unprotected grid item with method1/reference0/single extent/index0 in exactly one local meta/idat payload. Check base/offset/length against idat bounds and aliases of resolved local extents. Reject Exif method1, unknown method/type, external/protected data, missing/duplicate idat, malformed/out-of-range or aliased extents. Other file-backed items remain method0/mdat. Never relocate bytes; changes remain UserComment storage/count only.

Verification before implementation: native reserved-comment HEIC at three failing sizes must locate/repair with same length, byte whitelist, exact Unicode/capture/exposure and identical decoded original-versus-repaired pixels. Synthetic idat edge cases, existing method0 adversarial/11-output reference controls, PNG shared kernel and verified-encoder regression. Scope remains local controlled SDR research, not general HEIF or Photos/device certification.

## Implemented and verified
Implemented bounded method1 only for unprotected grid with local single idat, reference0/single extent/index0. Absolute resolved ranges checked inside idat and against prior extents; Exif remains method0/single extent/mdat. Also reject nonzero construction-method reserved bits (method17 control first reproduced acceptance, then passed rejection). Unknown/protected/external/fragmented/aliased forms remain rejected; opaque MakerNote policy unchanged. No byte relocation or pixel recoding.
Native three-size and synthetic positive tests first failed at old all-item method0 guard (`/tmp/MemoMarkHEICGridBehaviorRed.xcresult`); after implementation all three sizes pass exact scalar/capture/exposure readback, nonoptional decoded pixel equality, same length and byte whitelist.
Final combined macOS build/test `/tmp/MemoMarkHEICGridBackgroundFinal.xcresult`: 16 test items / 17 executions, 0 failures/skips; existing 11 PNG + 11 HEIC Python reference outputs and old malformed/private/endian/alias controls retained, plus verified encoder and metadata eligibility. Heavy native pixel test now @concurrent/nonisolated instead of UI actor. One runtime QoS warning persists (User-initiated waiting on Default, source GridProbe); this is an open observation, not a production scheduling fix.
Final standalone `/tmp/MemoMarkEncodingResourcesGridFinal.xcresult`: 1 passing observation test, 8/8 outputs verified, no runtime warnings in that run. Same low-entropy banded fixtures, one sample each, no performance budget assertion, no forced pixel traversal in timed worker. Process HWM is lifetime including harness and earlier calls; run-to-run changes do not prove memory optimization.
|Canvas|Format|Verified call ms|Encoded bytes|Process HWM MiB|
|---|---|---:|---:|---:|
|64x48|png|52.22|1596|229.4|
|64x48|heic|141.16|1639|229.4|
|1024x768|png|24.32|16980|229.6|
|1024x768|heic|31.33|3214|234.9|
|2048x1536|png|93.92|60405|241.3|
|2048x1536|heic|68.62|7000|241.3|
|4096x3072|png|309.51|230184|264.7|
|4096x3072|heic|95.81|23148|308.2|

Stable reports in `$HOME/Documents/Codex/2026-10-01/GlassCardEncodingEligibility/`; earlier rejected artifacts retained as before-fix evidence. Eleven temporary target files byte-compared/removed. Production route untouched; no generic HEIF/private metadata, fuzzing, HDR/P3, Live Photo, Photos or physical-device certification. Governance/diff checks pass; no commit/push.
