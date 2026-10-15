# Native ImageIO metadata route control

Engineering Loop P1 research only. Source: SDK CGImageMetadataSetValueMatchingImageProperty and CGImageDestinationAddImageAndMetadata API contracts. Compare matched properties and explicit exif UserComment tags to current writer for six strings × PNG/JPEG/HEIC. Read both image properties and embedded metadata; record missing/mismatched results explicitly. Include capture/exposure/GPS controls. The native metadata path can alter metadata representation; no production migration without preservation evidence. No private inputs, Photos, binary container surgery or material changes.

## Initial native routes

54 rows (6 strings × 3 formats × matched property/explicit String/explicit alternate-text tag). All UserComment sets returned true. Ordinary image property and embedded metadata UserComment exact equality both 1/6 in every format/route; non-ASCII results remain truncated/substituted. APIs accepting values is not preservation evidence. Initial NSNumber(0.01) ExposureTime maps to 0; this is a probe input-type problem candidate (SDK says XMP value types), not evidence of production-writer exposure loss. Second controlled run uses rational string 1/100 and GPS XMP-style latitude 22,30N. Keep initial and final artifacts separate.

## Final control outcome

Final rational-string input recovers ExposureTime=0.01 in all 54 rows; GPS latitude=22.5 and capture string retained in all rows. UserComment still matches only the ASCII sample: 1/6 for each of three routes in each of three formats, both property dictionary and embedded metadata readback. Final native route is not adopted; no production changes in this slice. Initial NSNumber control does not indict existing writer.

Two sequential macOS builds/probes each passed one observational test (initial `/tmp/MemoMarkNativeMetadata.xcresult`, final `/tmp/MemoMarkNativeMetadataControls.xcresult`), no runtime warnings. Analyzer validates final unique matrix, capture/exposure/GPS controls. Raw initial/final JSON in `$HOME/Documents/Codex/2026-10-01/GlassCardNativeMetadata/`. Temporary probe copied back byte-identically then removed from target. No iOS/Photos certification, private data, commit or push. Earlier JPEG correction remains intact; PNG/HEIC EXIF correction remains open. Native routes are research evidence, not preservation PASS.
