# V4 Output Photo Description Card Refinement

Date: 2026-08-06

Status: Implemented And Delivered For Physical-Device Acceptance

Primary loop: Product Loop

Risk: P1 - the output page is part of the primary configuration workflow, and
copy that overstates Apple Photos support could mislead users about whether a
saved description is visible or searchable on their current system version.

## Observation

The Output page currently places photo format, retained capture information,
Live Photo behavior, and Photo Description inside one `New Photo` card. On the
physical iPhone 15 Pro this makes two distinct decisions read as one long card:

- what kind of new photo MemoMark saves;
- what text MemoMark writes with that new photo.

The existing Photo Description behavior is already complete. When custom text
is off, the complete resolved right-bottom Memory Expression is used. When
custom text is on, the trimmed custom text follows that complete expression on
a separate line. The custom text does not replace the expression.

## Accepted UI Decision

Move the complete existing Photo Description block into its own titled card,
between `New Photo` and `Where It Goes`.

The new card must reuse `V1TitledSectionCard` and the established Output-page
spacing, typography, semantic colors, corner radius, Dynamic Type behavior,
and dark-mode behavior. It must not introduce a nested card or a new local
visual system.

The hierarchy is:

```text
Photo Description
-> section subtitle
-> content preview
-> existing custom-content toggle
-> existing conditional input
-> Apple Photos system-support note
```

`New Photo` continues to own only:

- photo format;
- retained capture information;
- Live Photo retention.

## Behavior Boundary

The UI extraction preserves these exact inputs without introducing view-owned
composition or state:

- `usesCustomMemoryWriteText`;
- `customMemoryWriteText`;
- `resolvedMemoryWriteText`.

The post-extraction stability audit found two pre-existing composition sources:
the iOS/production path appended with a newline, while `ConfigurationSession`
replaced the resolved expression. One non-UI `MemoryWriteTextComposer` now owns
the accepted two-line rule for Configuration Session, preview, and production.
Renderer, Layout Engine, metadata writing, PhotoKit save
transactions, original photos, and Live Photo resource behavior remain
unchanged.

## Apple Photos And iOS Support Range

MemoMark currently deploys to iOS 18 and writes the resolved Photo Description
into the established output-file compatibility metadata, including applicable
IPTC Caption/Abstract, TIFF ImageDescription, EXIF UserComment, and PNG
Description fields. Apple Photos owns how imported metadata is surfaced and
indexed.

| System range | Apple platform capability | MemoMark support statement |
| --- | --- | --- |
| iOS 18-26 | No public `PHAssetChangeRequest.caption` setter is available. | MemoMark preserves the description in compatible output metadata. Visibility and search behavior in Apple Photos may vary by system version and asset type and must not be described as guaranteed. |
| iOS 27+ | PhotoKit introduces `PHAssetChangeRequest.caption`. | The system capability exists, but MemoMark does not adopt it in this UI pass. Direct caption integration requires a separate scoped PhotoKit lifecycle change and signed-device evidence. |

The user-facing card therefore states that Apple Photos display and search
support may differ by iOS version. It must not promise universal search support
on iOS 18-26 or imply that the current release already uses the iOS 27 API.

## Apple-Native Evaluation

The iOS 27 SDK exposes `PHAssetChangeRequest.caption` with
`API_AVAILABLE(ios(27), ...)`. Adopting it now would change the photo-library
save lifecycle and require an availability path, asset-identity handoff,
failure and recovery behavior, static/Live Photo parity, and physical-device
round-trip validation. Those concerns are outside this bounded visual pass.

No new permission, entitlement, framework dependency, media access, network
behavior, or original-asset mutation is introduced.

## Verification Plan

1. Add a failing source contract requiring a standalone Photo Description
   section and the existing bindings.
2. Extract the existing SwiftUI block without changing configuration state or
   the PhotoKit lifecycle.
3. Verify the focused design and narrative contracts.
4. Verify Simplified Chinese and English localization validity and key
   symmetry.
5. Run `git diff --check` and the required unsigned Debug build.
6. Build, overwrite-install, and launch on the paired iPhone 15 Pro without
   uninstalling or clearing local data. The product owner performs final visual
   acceptance; no simulator visual acceptance is required.

## Acceptance Criteria

- `New Photo`, `Photo Description`, and `Where It Goes` are three sibling
  cards using the same card primitive and vertical rhythm.
- Photo Description has a title, subtitle, preview, existing toggle, existing
  conditional input, and a restrained iOS support note.
- Preview and final saved content both use the complete right-bottom expression,
  followed by optional custom text on a separate line; no replacement semantics
  remain.
- The UI remains readable in light and dark appearance, compact width, Dynamic
  Type, and VoiceOver.
- Repository documentation does not overstate Apple Photos caption or search
  support on earlier iOS versions.

## Completion Evidence

- `New Photo`, `Photo Description`, and `Where It Goes` are now three
  sibling `V1TitledSectionCard` surfaces with the existing Output-page spacing,
  semantic colors, typography, corner radius, Dynamic Type behavior, and dark
  appearance behavior.
- The complete preview, custom-content toggle, and conditional input moved into
  `V1OutputPhotoDescriptionSection`. The original three bindings remain the only
  inputs. Its expansion now honors Reduce Motion, and supporting toggle text can
  wrap at accessibility Dynamic Type sizes.
- `MemoryWriteTextComposer` moved from an iOS view file to the shared model
  layer. Configuration Session, iOS preview, production Memory Module,
  expression context, and final Photo Description now share the same trimmed,
  newline-separated composition contract.
- The card includes one localized, secondary system-support note. The exact
  iOS 18-26 and iOS 27+ capability boundary remains documented here and in the
  internal and TestFlight release drafts.
- The focused design, Apple-native, responsive-layout, narrative-language,
  Memory Write presenter, and release-note suites passed. The complete
  `PhotoMemoTests` result contains 1,303 tests: 1,302 passed, 1 existing skip,
  and 0 failures.
- Simplified Chinese and English localization files pass `plutil -lint`, each
  contains the same 618 keys, and `git diff --check` passes. The required
  unsigned Debug build and signed iPhone Debug build pass; strict signature
  verification succeeds for `2.0.2 (69)`.
- The signed app was overwrite-installed and launched on the paired `IPhone5`
  iPhone 15 Pro without uninstalling the app or clearing local data. No
  simulator was started or used. Final card spacing, copy fit, toggle/input
  behavior, light/dark appearance, and VoiceOver acceptance remain with the
  product owner on that physical device.

## Out Of Scope

- adopting `PHAssetChangeRequest.caption`;
- changing metadata fields or export composition;
- changing Memory Engine calculation results or the user-selected region
  structure;
- rewriting user punctuation or adding sentence punctuation automatically;
- changing persistence, PhotoKit authorization, albums, or original assets.
