# High-entropy SDR encoding and size rejection

Engineering Loop / P1 bounded research. Current verified encoder limits source dimensions to4096px and completed encoded file size to16MiB before loading bytes, repair or readback. Previous colour-band measurements do not exercise entropy, output limit or larger intermediate byte buffers. No production contract/route/default changes.

Plan: deterministic seeded opaque sRGB8bit pseudorandom fixtures at1024x768,2048x1536,4096x3072; invoke actual verified worker serially for PNG/HEIC. Assert smaller PNG and all HEIC outputs verify;12MP PNG must exceed16MiB and reject, with scratch root empty. Confirm actual writer's control file length for rejected case, preserving only JSON observations rather than large generated image files. Record elapsed call time and macOS process-lifetime RSS high-water, never stage/device budget. Existing pre-cancel test only proves before-start cancellation; mid-encoding cancellation requires synchronization evidence and must not be claimed from timing guesses.

Native ImageIO reuse, immutable bytes and internal scratch ownership remain. No user assets, upload, simulator or physical acceptance. Code change only if experiment identifies a concrete gap.

## Completed evidence and revised priority

`/tmp/MemoMarkHighEntropy.xcresult`: one passing native macOS test, six serial attempts; five verified outputs,12MP PNG rejected after native encoding and scratch cleaned. Native size control43,811,884 bytes confirms rejection. No runtime warnings; this is not performance/device certification. Six temporary target copies byte-compared/removed.

|Canvas|Format|Outcome|Call seconds|Returned bytes|Lifetime HWM MiB|
|---|---|---|---:|---:|---:|
|1024x768|png|verified|2.567|2770966|238.3|
|1024x768|heic|verified|0.110|419708|245.4|
|2048x1536|png|verified|9.975|11013334|276.2|
|2048x1536|heic|verified|0.049|1690950|283.3|
|4096x3072|png|rejected encoded size|1.207|0|326.4|
|4096x3072|heic|verified|0.096|6762265|364.7|

Noise test is seeded xorshift opaque sRGB8bit; no source/media retention. Encoding cap acts after native writer has already completed encoding: it bounds subsequent file loading/repair/readback, not native encoding memory or disk use. 2048PNG call~9.975s versus prior banded93.9ms highlights debug research CRC/byte-array processing cost; no isolated-stage attribution. Native size-control encoding between rejected PNG and final HEIC affects cumulative HWM. Mid-encoding cancellation not verified; only previous pre-start cancellation remains proven.

Owner asks whether visual research has become unnecessarily complex. Preserve these observations, defer new cancellation instrumentation/encoder expansions, and prioritize native Liquid Glass same-source visual and saved-output comparison. Metadata container repair is not a prerequisite to establish the visual recipe. Current16MiB/4096px bounded research API is not a general production route.
