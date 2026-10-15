# Actual writer isolation

Engineering Loop, P1 bounded behavior-preserving isolation adjustment. Current stateless writer and pure cleanup/patcher helpers inherit MainActor from target settings. Scope: remove implicit UI actor dependency from these three owners; existing production callers stay synchronous with unchanged metadata policy and output behavior. Research worker constructs writer locally, receives immutable CGImage/metadata snapshot/URL/description/date. Caller owns destination exclusively; concurrent writes to the same URL are unsupported. No production scheduling, transaction, durable schema, PhotoKit or material-default changes.

Native reuse: existing ImageIO writer, Foundation dates and JPEG patcher. Risk: helper isolation, metadata retention, pairing cleanup, encoding cancellation cannot interrupt synchronous ImageIO. Verify actual PNG/JPEG/HEIC readback, off-main worker, pre-cancellation, original cleanup contract tests and generic iOS build.

## Actual controls

Initial full-comment assertion failed. Controlled mixed Chinese/numeric `相伴365天`: PNG and HEIC both read back `相伴3` plus four NUL characters; JPEG reads full text. Added synchronous actual-writer controls with identical image/properties/description/date: same comment values as worker in each format. This is retained as an existing writer limitation, not declared preservation PASS. The isolation test asserts behavior parity; Unicode correction needs a separate scoped regression/fix.

Enhanced macOS build/test result: 10 passed, 0 failed, 1 existing disabled case (`writesJPEGWithSourceMetadataAndRenderedDimensions`, source annotation cites historical test-runner log-finalization hang), no runtime warnings. Bundle `/tmp/MemoMarkGlassWriterIsolationControls.xcresult`. Three real formats verify off-main writing, sRGB decode, dimensions/orientation, capture string/exposure/GPS, modification date, inherited pairing/QuickTime absence and sync/async comment parity. Pre-cancelled worker creates no destination. No pixel-error/throughput/late-cancellation certification. Original failure bundle remains `/tmp/MemoMarkGlassWriterIsolation.xcresult`. Attachments `$HOME/Documents/Codex/2026-10-01/GlassCardSDRWriterIsolation/`. Temporary research test copies byte-checked and removed.

## Next bounded reliability issue

P1 metadata-description regression candidate: reproduce mixed Chinese/numeric strings across direct ImageIO and actual writer, compare ASCII/pure-Chinese/mixed/emoji strings and lengths in PNG/HEIC/JPEG. Inspect actual EXIF string encoding/count and other description fields before choosing a correction. Preserve capture fields and existing cleanup. Do not assert container limitations or Unicode root cause from a single string. No new writer, byte patching or production output policy should be introduced before that evidence.

Generic iOS Debug build passed with MemoMarkiOS scheme, iphoneos SDK, signing disabled (`/tmp/MemoMarkGlassWriterIsolationIOSFinal.log`). Initial MemoMark-scheme attempts failed destination selection because that scheme is macOS; no Simulator build performed. No physical install, launch or Photos certification. Production diff is precisely three nonisolated type annotations; production scheduling remains unchanged.
