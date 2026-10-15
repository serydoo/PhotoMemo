# SDR encoding eligibility and resource observations

Engineering Loop / P1 bounded research. Source of truth: current actual MetadataPreservingImageWriter, ImageIOStillImageMetadataCleanup, research verified encoder and shared TIFF/container repair. Ownership remains frozen metadata → native writer → bounded repair → readback, with no Renderer/Layout/media scheduling migration.

Observed gap: Unicode verification alone cannot establish metadata preservation. Private MakerNote rejection may exclude ordinary camera outputs; native writer may itself omit unsupported keys. Plan: compare verified output against the actual writer's projected control for EXIF/GPS/TIFF/IPTC/PNG and pairing cleanup, record whether supplied MakerApple data reaches the container, reject an emitted MakerNote rather than strip it, and measure isolated synthetic encoding calls on macOS using wall time and process-lifetime resident high-water (getrusage). Native ImageIO is reused; no photos, cloud, production defaults or persisted schemas are touched.

Resource measurements are local observations, not stage-specific peaks, budgets or iPhone certification. Use deterministic synthetic 64x48, 1024x768, 2048x1536 and 4096x3072 sRGB sources, PNG/HEIC; serial execution avoids overlapping test calls. Keep scratch cleanup checks. Gate production adoption on a preservation policy and broader real-container/device evidence rather than relax the repair parser.

## Findings and implemented boundary

Baseline 64x48 PNG/HEIC outputs retain tested DateTimeOriginal, OffsetTimeOriginal (+08:00), ExposureTime, FNumber, LensModel, GPS lat/long/ref/altitude, TIFF Make/Model/Artist and IPTC Keywords. Native writer maps Artist to IPTC Byline. EXIF except intentionally replaced UserComment and complete GPS/TIFF/IPTC/PNG dictionaries equal same-projection native controls. Old QuickTime and MakerApple 17 pairing identifiers are absent. New description intentionally replaces existing capture UserComment, matching current writer semantics; this is not a claim to retain both comments.

Adding retained MakerApple key 1 causes both PNG/HEIC container repair to reject unsupported MakerNote. Added research preflight: decode frozen metadata, reuse actual ImageIOStillImageMetadataCleanup, then reject any retained MakerApple dictionary before creating scratch files. No private metadata is stripped to gain admission. Regression first reproduced a filesystem error for a missing scratch parent rather than early unsupported rejection; after preflight it correctly rejects before filesystem access. Other opaque private/container structures still fail later at the bounded parser; this is not a universal metadata validator.

Final `/tmp/MemoMarkEncodingEligibilityFinal.xcresult`: 4 passing tests, 0 failures/skips/runtime warnings, covering metadata controls, early private rejection and previous Unicode/ownership/dimension regressions. `/tmp/MemoMarkEncodingResourcesObserved.xcresult`: 1 passing observation test, not 8 successful outputs. Initial resource run failed on a larger native HEIC; preserved as `/tmp/MemoMarkEncodingResources.xcresult`.

## Resource observations and newly discovered HEIC limit

Single serial macOS process; deterministic horizontal colour-band fixtures, no warmup/repetition. Times include native write, repair, readback and cleanup, excluding fixture creation. Measurements taken before adding the private-metadata preflight; fixture metadata contains no MakerApple and is unaffected by that check. getrusage ru_maxrss is macOS process-lifetime high-water bytes (local getrusage(2) manual), including app/test harness, source image creation, previous calls and diagnostic encoding between failed HEIC observations. Deltas cannot establish stage peaks or allocations. ImageIO readback here is not a forced complete pixel traversal.

| Canvas | Format | Outcome | Call ms | Output bytes | Lifetime HWM after call MiB |
|---|---|---|---:|---:|---:|
|64x48|PNG|verified|40.95|1596|240.7|
|64x48|HEIC|verified|130.50|1639|243.8|
|1024x768|PNG|verified|24.87|16980|246.7|
|1024x768|HEIC|rejected|30.14|none returned|251.6|
|2048x1536|PNG|verified|78.06|60405|259.7|
|2048x1536|HEIC|rejected|41.80|none returned|276.2|
|4096x3072|PNG|verified|287.92|230184|309.4|
|4096x3072|HEIC|rejected|102.50|none returned|368.5|

All three rejected native HEIC controls contain method1 grid items in meta/idat, while Exif remains a single method0 file-backed mdat extent. 1024/2048/4096 fixtures contain 7/15/51 items respectively. Current Swift parser deliberately rejects method!=0 for every item before TIFF traversal (line104); current guard is therefore too restrictive for these actual native full-size outputs. Do not classify rejected durations as successful encoding performance. Kept guard intact. Next bounded repair increment needs explicit idat method1 range ownership, item bounds/alias checks and malformed controls, plus existing method0 regression evidence. Private MakerNote remains a separate unresolved preservation policy; do not couple admission relaxation to grid support.

Read-only `inspect_glasscard_heic_references.py` reports iloc method/ref/extent/type and idat ranges, no mutation or full HEIF-validity claim. Three Python tests pass (method1 report, invalid ID, truncation/missing tables). Stable synthetic artifacts/metadata/resource/reference reports: `$HOME/Documents/Codex/2026-10-01/GlassCardEncodingEligibility/`. Eight temporary target copies byte-checked/removed; governance and diff checks pass. Production routing unchanged; no iPhone/Photos/HDR/Live Photo acceptance, no commit/push.

## Superseding local-grid increment

Within this session, implemented bounded method1 grid/idat support (see GlassCard-SDR-HEIC-Grid-2026-10-01.md). The earlier larger-HEIC rejection matrix remains before-fix evidence; final standalone resource run verifies all 8 outputs, including three formerly rejected larger HEICs. Private MakerApple/MakerNote rejection remains unchanged. Final combined regression has one remaining User-initiated/Default QoS warning despite moving heavy test work off UI actor. Final single resource run has none. No production or device acceptance implied.
