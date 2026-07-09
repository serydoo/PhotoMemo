# Media Geometry Runtime Reports

Runtime Reports store MGF-2B evidence for iOS Photos runtime validation.

MGF-2B is a Quality Sprint. Each report should prove one runtime behavior or
classify one runtime failure. Do not use this folder to redesign Foundation.

## Policy

- One runtime failure, one root cause.
- Stop on the first failed runtime pipeline step.
- Classify every finding before changing code.
- Do not modify Geometry Foundation unless evidence proves `CanonicalGeometry`,
  resolver, or linter output is wrong.
- Do not commit private photos, private Live Photo assets, or family media.
- Store private `.heic`, `.mov`, screenshots, and screen recordings outside the
  repository; record only safe paths, hashes, dimensions, and conclusions.

## Report Template

```markdown
# MGF-2B Runtime Report YYYY-MM-DD

## Scope

- Scenario:
- Device:
- iOS:
- App build:
- Input orientation:
- Output mode:

## Runtime Pipeline

- [ ] Import Live Photo
- [ ] Export Live Photo
- [ ] Photos recognizes Live Photo
- [ ] Long press playback
- [ ] Still-to-video transition
- [ ] Footer geometry
- [ ] Portrait output
- [ ] Landscape output

## Runtime Report

- [ ] Live Photo Recognized
- [ ] Asset Identifier Match
- [ ] Long Press Playback
- [ ] Still-to-Video Transition
- [ ] Geometry Hash Match
- [ ] Footer Bounds Match
- [ ] Portrait OK
- [ ] Landscape OK

## Finding

- Issue:
- Classification: R / C / F
- Code:
- Layer: Runtime / Composition / Foundation
- Root cause:
- Decision:
- Foundation changed: No

## Evidence

- External evidence folder:
- Still resource hash:
- Video resource hash:
- Geometry JSON hash:
- Notes:
```

## Exit Gate

MGF-2B can close only when:

- Foundation was not modified for runtime-only failures.
- All findings are classified as Runtime, Composition, or Foundation.
- Regression matrix passes for the accepted runtime scope.
- Runtime behavior is stable on the connected iPhone Photos runtime.
