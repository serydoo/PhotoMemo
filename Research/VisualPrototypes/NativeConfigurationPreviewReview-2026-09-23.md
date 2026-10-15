# Native Configuration Preview Review

Date: 2026-09-23
Status: bounded DEBUG-only visual review harness; not a production UI change.

## Observation and intended outcome

The current browser mock manually redraws MemoMark's interface. Production
SwiftUI already owns the Classic White information preview, Minimal capsule
composition, and FilmMark content/calibration views, but it does not yet expose
the new complete-photo orientation review as one selectable surface.

Add an opt-in DEBUG launch route (`--configuration-preview-review`) that
renders the existing production preview components with fixed, local sample
content. On iPhone it should let the reviewer switch Classic White, Minimal,
and FilmMark; swipe left/right to compare landscape/portrait in all three
styles; and expand FilmMark to a full-canvas position/size review. Every style
uses the same owner-provided landscape/portrait Mid-Autumn background pair.
Classic White's complete information bar is composed over that image in this
review route. The selected style, direction, and review mode are transient view
state only.

## Ownership and boundaries

- Primary loop: Product Loop, V4.0 research and product definition.
- Source of truth: existing `MemoryCardPreviewSurface`,
  `FilmMarkPresentationResolver`, Layout Engine specifications, and the
  accepted 2026-09-23 preview-direction amendments.
- Affected owners: Configuration Center preview presentation only.
- Apple-native capability: SwiftUI controls/state and the existing iOS app
  composition root. Do not attempt to execute SwiftUI from HTML or introduce a
  WebKit bridge for this visual review.
- Fixtures use app-bundled sample photos and authored demo strings; they do not
  read the user's photo library/configuration or write preferences, exports,
  or durable configuration.
- The Mid-Autumn pair is copied byte-for-byte from the product owner's local
  source files:
  - landscape SHA-256: `c532b9c078cebe2eac0a0531ecd3efe90065d02b3f50119407384814c22251d6`;
  - portrait SHA-256: `2b5c084c6846ab7f70ac6aca602a1e4f15220ad5a29dc3942c7518b103a42798`.
- The normal app entry and production preview behavior remain unchanged unless
  the explicit DEBUG launch argument is present.
- Risk: P2, bounded to a DEBUG-only inspection route and preview-only geometry.

## Bounded change set

1. Add explicit orientation-aware, full-photo sizing for the review route while
   keeping existing Configuration Center callers on their current defaults.
2. Add a FilmMark full-canvas review mode that resolves the same content and
   configuration through the existing resolver and text/placement layers.
3. Add an opt-in DEBUG iOS review screen and launch argument; provide an exit
   action back to the ordinary app.
4. Keep the HTML mock as a separately labeled conceptual reference; it is not
   a runtime dependency or a second source of configuration truth.

## Acceptance and evidence

- Existing call sites retain their prior default preview modes.
- The DEBUG review screen visibly renders all three styles over the exact same
  landscape and portrait sample canvases; Classic White retains its complete
  information bar.
- Minimal placement uses the matching existing orientation layout specification.
- FilmMark full-canvas and fine-review states use resolver output and do not
  change durable configuration, renderer, export, or PhotoKit behavior.
- Orientation has no visible switch button: horizontal swipes work for all
  three styles, with an accessible VoiceOver action as the non-visual path.
- State resets with the temporary review session.
- Run focused tests for review geometry/asset selection and an iOS Debug build.
- Install/launch the exact signed DEBUG build on the paired iPhone 17 Pro Max
  without clearing its container, then manually inspect all four states.
- No simulator is used as a substitute for physical-device UI acceptance.
