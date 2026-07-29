# Settings Product Center Information Hierarchy Pass

Date: 2026-07-29

## Decision Gate

- Primary loop: Product Loop
- Risk: P2 - bounded product-quality and information-hierarchy improvement
- Observed scenario: the iOS Settings surface uses consistent cards and spacing,
  but product introduction, daily-use guidance, privacy facts, feedback
  channels, language, and build information are presented with equal weight.
  A first-time user cannot quickly distinguish what helps them begin from what
  they need only for reference or support.
- Intended outcome: retain the `设置` navigation title while making the page a
  quieter MemoMark product center. The reading order is `MemoMark+`, `开始使用`,
  `照片处理`, `数据安全`, `反馈`, `社区`, `应用语言`, and `关于`.

## Scope And Ownership

In scope:

- `V1SettingsPageSurface` only, as the iOS projection of product information.
- Localized Chinese and English labels, source-contract tests, and the
  existing `CURRENT_STATUS` chronicle.
- A persisted disclosure preference for each Settings section.

Out of scope:

- IA-002 Configuration Center architecture and navigation ownership.
- Configuration persistence, Memory Engine calculations, Renderer, Layout
  Engine, Export, Share Extension, PhotoKit, permissions, and commerce policy.
- Renaming the Settings destination or adding a separate product-center route.

The canonical source of truth remains the existing Configuration aggregate and
the Apple Photos lifecycle. This pass only changes how read-only product
information and its locally chosen disclosure state are projected.

## Product Design

- `开始使用` combines the existing product introduction with Welcome, daily
  workflow, and Memory Expression entry points. It defaults to expanded for a
  new installation.
- All other sections default to collapsed. Once a person expands or collapses
  a section, their choice is retained for later visits.
- `照片处理` keeps the existing capability facts, including the dynamic
  entitlement-based sharing limit.
- `数据安全` keeps direct, factual local-processing and deletion information.
- Formal feedback keeps TestFlight, email, and GitHub Issues. Community keeps
  QQ and public social accounts, so the purpose of each channel is clear.
- `关于` presents product name, version, build, copyright, and a functional
  update-log link.
- Visual hierarchy is intentionally subtle: existing card chrome is retained;
  section spacing and semantic system backgrounds distinguish primary,
  secondary, and system-reference material without adding visible category
  labels or nested cards. Disclosure headers stay text-only; individual rows
  may use restrained SF Symbols to improve scanning.
- `MemoMark+` becomes a compact membership Hero: the current entitlement or
  remaining free-record state is visible before navigation, followed by one
  clear `查看权益` action. Values continue to come from the commerce snapshot;
  no fixed allowance is introduced in UI copy.
- The long About story moves behind an `了解更多` sheet. The expanded
  `开始使用` section keeps one headline and one supporting sentence before its
  guide actions.
- Photo-processing rows use one concise capability statement each. Icons are
  semantic SF Symbols and do not replace labels or become the only carrier of
  meaning.
- Email is the first formal feedback route. TestFlight guidance is visible
  only while the current commerce snapshot identifies a TestFlight
  experience; GitHub Issues remains last for public reproducible defects.
- `关于` presents version and build on one compact value row, followed by the
  update-log action. Reading/disclosure chevrons are neutral; only genuine
  action links retain the accent color.
- The page closes with one quiet localized sentence rather than an emoji or
  marketing signature.

## Apple-Native Evaluation

SwiftUI `DisclosureGroup` was not adopted because the existing custom section
preserves the project’s card chrome, dynamic-type header layout, VoiceOver
value/hint, and Reduce Motion behavior. SwiftUI `@AppStorage`, backed by the
existing App Group `PhotoMemoSharedContainer.sharedUserDefaults`, is the
smallest native persistence mechanism for a user-interface preference. It has
no photo, identity, privacy-permission, or lifecycle impact.

The existing SwiftUI navigation-bar scroll-edge transition remains the owner
of header material. A custom scroll-offset blur was rejected because it would
duplicate native navigation behavior. Expanded content receives one bounded
opacity/offset transition rather than per-row delayed animation; this retains
the intended softness without introducing timing state or weakening Reduce
Motion behavior.

## Risks And Verification

Risks:

1. A fresh install could lose the intended default expansion.
2. A chosen disclosure state could fail to persist between visits.
3. Longer Chinese or English copy could overflow at accessibility text sizes.
4. The new hierarchy could weaken VoiceOver, Reduce Motion, or localization
   behavior.

Verification:

1. Add and run source contracts for section order, persistent `@AppStorage`,
   new default values, grouped content, update-log action, localization keys,
   and preserved accessibility/motion support.
2. Run both localization files through `plutil -lint` and validate key parity.
3. Build the required macOS Debug target and the generic iOS Debug target.
4. Inspect the diff, then review correctness, architecture, accessibility,
   security, and performance.
5. Build, install, and launch the signed iOS app on the paired physical iPhone
   17 Pro Max
   without clearing existing user data. Manual visual acceptance at normal and
   Accessibility text sizes remains an explicit device check.
