# MemoMark Task History Cover Specification

## Decision Gate

- Primary loop: Product Loop, based on the observed Progress-page history
  showing symbols after managed source cleanup.
- Risk: P1. The cover must never change task completion truth, Photo Library
  save behavior, original assets, retry semantics, or durable queue recovery.
- Ownership: Batch history owns cover identity and retention; media services
  create the derivative; the Progress UI only presents the resolved cover.
- Apple-native reuse: keep PhotoKit asset identifiers for opening Photos, but
  do not require broader Photo Library read access merely to draw history rows.

## Objective

Show a stable thumbnail of the generated result for completed jobs while
preserving MemoMark's local-first cleanup rules. A single-photo job shows its
result. A multi-photo job shows one deterministic representative result with a
subtle stack treatment and the total photo count.

## Product Contract

1. A cover is a disposable local derivative of the generated result, never a
   copy of the original photo.
2. A job owns at most one cover.
3. The first successfully saved task whose result can produce a cover becomes
   the representative. Selection is deterministic and never random.
4. A cover does not change after selection, including after relaunch.
5. Missing, corrupt, expired, or unreadable covers fall back to the existing
   state symbol without changing task status.
6. One-photo jobs show a normal result thumbnail.
7. Multi-photo jobs show the same representative thumbnail with a restrained
   stack treatment and a count badge; the compact row does not become a grid.
8. Existing jobs decode without a cover and continue to work.

## Durable Model

`BatchJob` gains an optional `historyCover` value containing:

- schema version
- source task identifier
- validated relative path under `TaskHistoryCovers/`
- creation date

The model stores no absolute App Group path. Runtime projection resolves the
relative path against `PhotoMemoSharedContainer.baseDirectoryURL`.

## File Contract

- Directory: `TaskHistoryCovers/`
- File identity: one deterministic filename per Job identifier
- Format: JPEG
- Maximum dimension: 360 px
- Orientation: normalized while generating the thumbnail
- Compression quality: 0.78
- Writes: temporary sibling followed by atomic replacement
- Input: final rendered result before its temporary file is removed

## Lifecycle

```text
rendered result
-> Photo Library save succeeds
-> create Job cover if the Job has none
-> persist task completion + cover reference together
-> remove rendered temporary file
-> Progress resolves cover relative path
```

Cover generation is best effort. If generation fails, the task still completes
and the Progress UI uses its symbol fallback. A cover is not created before the
Photo Library save succeeds.

## Retention

The cover store enforces all three limits after durable queue persistence:

- at most 60 retained Job covers
- at most 60 days old
- at most 30 MB total

Referenced covers within the limits are retained newest first. Unreferenced
files and references removed by retention are deleted safely. Active and
non-terminal Jobs never lose required processing resources; history covers are
not processing resources and remain optional.

## Privacy And Platform Boundaries

- no network access
- no new Photo Library permission
- no original-photo retention
- no Renderer, Layout Engine, EXIF, or output-quality change
- `savedAssetIdentifier` remains the Photos navigation identity, not the cover
  storage identity
- Live Photo history uses a static derivative of the rendered still result

## Verification

- model round-trip and legacy decode
- deterministic first-success selection
- single cover per Job across retries and relaunch
- relative-path validation and runtime resolution
- image downsampling and readable JPEG output
- count, age, byte-budget, and orphan cleanup
- cover failure does not fail a completed task
- presenter selects cover instead of cleaned source URL
- one-photo and multi-photo accessibility semantics
- full macOS tests, generic iOS builds, signed-device installation
- physical-device checks for one photo, multiple photos, relaunch, and fallback

## Commands

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -configuration Debug -derivedDataPath /tmp/MemoMarkHistoryCoverTests CODE_SIGNING_ALLOWED=NO -quiet test

xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath /tmp/MemoMarkHistoryCoverBuild CODE_SIGNING_ALLOWED=NO -quiet build
```

## Boundaries

- Always: preserve task truth, use deterministic selection, downsample off the
  main thread, and degrade to a symbol on any cover error.
- Do not expand: Photos permissions, network storage, gallery browsing, task
  detail UI, or final-output behavior.
- Never: retain originals for history, infer a random cover, or make queue
  completion depend on cover persistence.

## Implementation Status

Implemented locally on 2026-08-12 for `2.1.2 (79)`. Model, generation,
completion-transaction projection, history resolution, multi-photo treatment,
retention, legacy decoding, focused tests, generic iOS build, and signed-device
installation are complete. Git synchronization remains intentionally deferred
until explicit user instruction. Final physical-device interaction acceptance
requires producing one new single-photo Job and one new multi-photo Job, then
relaunching the app and confirming that the same representative cover remains.

Physical-device acceptance confirmed the single- and multi-photo presentation.
The follow-up stability pass also requires orphan detection to observe the same
unreferenced cover in two successful reconciliation passes before deletion and
to ignore hidden in-progress files. Missing cover files clear their stale model
reference, while a readable final-notification derivative remains an allowed
legacy display fallback. Per-task notification derivatives are released after
final notification handling whenever the Job owns a durable history cover.
