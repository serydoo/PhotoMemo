# V4 System Appearance Refinement

Date: 2026-08-06

Status: Implemented And Delivered For Physical-Device Acceptance

Primary loop: Product Loop

Risk: P1 - removing the global light appearance before fixed-light application
surfaces are migrated can produce white-on-white text, invisible controls, and
inconsistent sheet hierarchy in the primary iOS workflow.

## Observation

At intake, the iOS root scene applied `.preferredColorScheme(.light)` to the
complete main application. The active Apple-native surface contract required
that override, and the 2026-07-29 status record explains that it was restored
because fixed white application surfaces remained after an earlier partial
semantic-color pass.

The current design system already provides system grouped, secondary grouped,
and tertiary grouped semantic surfaces. Most active pages use them, but a
bounded set of Home, Welcome, Memory Subject, Time Anchor, and avatar-editing
surfaces still use fixed white application chrome.

Some fixed white and black colors are intentional and must not be migrated:

- the real Classic White Memory Card and output preview;
- Logo preview canvases that represent the generated white border;
- fixed text and information-bar colors owned by the renderer contract;
- white foreground on accent-colored primary actions;
- black/white crop masks and avatar edit overlays over user media;
- brand artwork whose white/black geometry is part of the mark.

## Accepted Product Decision

Settings combines appearance and interface language into one `界面` section.
The section presents two controls with the same visual and adaptive behavior:

1. `外观`: `跟随系统 / 浅色 / 深色`
2. `界面语言`: the existing system / Simplified Chinese / English choices

At ordinary Dynamic Type sizes both controls use the native segmented picker.
At accessibility Dynamic Type sizes both use the native menu picker so labels
remain complete and touch targets remain usable. The collapsed section summary
shows the current appearance and language values without introducing a new
navigation level.

The default appearance is `跟随系统`. A stored explicit light or dark choice
overrides the system only for the MemoMark main application. The Share
Extension and system-owned controllers continue to follow their Apple-owned
appearance environments.

## Intended Outcome

- The iOS main application follows system appearance by default.
- Users can explicitly select light or dark appearance from Settings.
- The choice is local, durable, and applied immediately without restarting.
- Home, Configuration Center, Processing, Output, Settings, Welcome, Memory
  Subject, Time Anchor, More Information, and Card Content remain readable in
  both appearances.
- Application cards and editor rows use semantic surfaces rather than fixed
  white backgrounds.
- Real white output and calibration previews remain white and use an explicit
  local light environment or fixed output colors where their content relies on
  semantic label colors.
- Dynamic Type, VoiceOver, Increase Contrast, localization, configuration
  persistence, and the primary photo workflow remain unchanged.

## Ownership And Source Of Truth

- `MemoMarkAppearancePreference` owns the three persisted user choices and the
  shared UserDefaults key.
- `PhotoMemoRootSceneView` is the only main-application boundary that projects
  the stored preference into SwiftUI `preferredColorScheme`.
- `V1SettingsPageSurface` edits the preference; it does not own a parallel
  appearance state.
- `ConfigurationUI` and `MemoMarkDesignTokens` remain the source of semantic
  application surfaces, elevation, control foreground, and fixed-output color
  roles.
- Renderer, Layout Engine, Memory Engine, configuration persistence, Export,
  PhotoKit, Share intake, commerce, and original-photo behavior are unchanged.

## Apple-Native Reuse

- SwiftUI `preferredColorScheme(_:)` applies an optional explicit override;
  `nil` preserves the current system environment.
- `@AppStorage` backed by the existing shared local defaults container provides
  immediate durable preference propagation.
- Native segmented `Picker` and menu fallback match the existing interface
  language control and Apple accessibility behavior.
- UIKit system grouped backgrounds and label/separator colors continue to
  provide light, dark, and increased-contrast variants.

No new framework, permission, entitlement, network behavior, media access, or
custom theme engine is introduced.

## Bounded Color Inventory

Application surfaces to migrate:

- Welcome feature rows and hero container;
- Home Memory Subject card and non-output identity surfaces;
- Memory Subject identity fields, summary chips, readiness chips, and Time
  Anchor row containers;
- Memory Subject overview Time Anchor list;
- avatar crop canvas surround and statistic pills;
- shared application elevation values that disappear or become too heavy in
  dark appearance.

Fixed-output or overlay surfaces to retain explicitly:

- Configuration Center region strip on the real card preview;
- Logo preview canvas and compact preset Logo badge;
- Classic White / Immers white output content and renderer-owned black text;
- primary-action white foreground;
- photo crop mask, crop boundary, and avatar edit affordance;
- fixed brand mark artwork.

## Failure Modes And Controls

- White-on-white content after the root override is removed: migrate every
  application surface before enabling system appearance and guard with source
  contracts.
- Darkening the actual generated white card: give output/calibration previews
  a local light environment rather than replacing their white surface.
- A dark selection that does not update until relaunch: root and Settings read
  the same `@AppStorage` key and tests require one canonical key.
- Segment labels truncate at accessibility sizes: both controls use the same
  accessibility-size menu fallback.
- Existing users unexpectedly remain forced light: missing preference resolves
  to `system`, while users may explicitly restore `light` in Settings.
- Share Extension appearance changes unintentionally: no global UIKit override
  or extension preference injection is added.

## Incremental Implementation

1. Add failing source contracts for the three-state preference, Settings
   placement, matching adaptive picker styles, absence of global forced light,
   and explicit fixed-output preview isolation.
2. Add the canonical preference and Settings UI while keeping the current root
   light boundary until the application surfaces are migrated.
3. Migrate fixed-light application surfaces to semantic tokens and define
   explicit fixed-output/on-accent roles.
4. Remove the root forced-light contract and apply the stored optional color
   scheme.
5. Run focused contracts after each slice, then complete tests, localization
   lint and key symmetry, `git diff --check`, the required unsigned build, and
   a signed iPhone build.
6. Overwrite-install on the paired iPhone 15 Pro without uninstalling or
   clearing local data. No simulator visual acceptance is required; final
   light/dark visual acceptance remains on the physical device.

## Acceptance Criteria

- Settings contains one `界面` section with matching Appearance and Interface
  Language controls.
- Appearance choices are System, Light, and Dark in Simplified Chinese and
  English, with System as the default.
- Changing appearance updates the complete main application immediately and
  survives relaunch.
- The root no longer contains `.preferredColorScheme(.light)` or a UIKit
  `overrideUserInterfaceStyle` override.
- Active application surfaces do not use fixed white as their container fill.
- Fixed white output and Logo previews remain stable and readable in dark mode.
- Focused and complete tests pass, localization resources remain symmetric and
  valid, required builds pass, and the signed app is installed on the iPhone
  15 Pro for product-owner verification.

## Completion Evidence

- Added one persisted `MemoMarkAppearancePreference` with `system`, `light`,
  and `dark` choices. `PhotoMemoRootSceneView` is the only boundary that
  projects this preference into `preferredColorScheme`; the former global
  `.preferredColorScheme(.light)` override is removed.
- Combined Appearance and Interface Language under one collapsible `界面`
  Settings section. Both controls use segmented pickers at ordinary Dynamic
  Type sizes and menu pickers at accessibility sizes, and the collapsed value
  summarizes both current choices.
- Migrated remaining active application-card white fills and shadows to
  semantic system surfaces. Renderer-owned text, real white Memory Card
  previews, Logo canvases, crop overlays, brand geometry, and primary-action
  foregrounds retain explicit fixed-light or overlay semantics.
- Simplified Chinese and English localization files pass `plutil -lint` and
  contain the same 603 keys. `git diff --check` passes.
- Focused appearance, Settings, commerce, and iPhone-responsive contracts pass.
  The complete `PhotoMemoTests` result contains 1,302 tests: 1,301 passed,
  1 existing skip, and 0 failures.
- The required unsigned Debug build and signed `PhotoMemoiOS` iPhone Debug
  build pass. Strict signature verification passes for version `2.0.2 (69)`.
- The signed app was overwrite-installed and launched on the paired `IPhone5`
  iPhone 15 Pro without uninstalling the app or clearing its local data. No
  simulator was started or used. Final light, dark, and automatic appearance
  acceptance remains with the product owner on that physical device.

## Out Of Scope

- a custom palette or theme marketplace;
- per-preset application themes;
- changing generated photo colors or Renderer output;
- forcing an appearance in the Share Extension, Photo picker, share sheet, or
  other system-owned controller;
- IA-002, navigation, configuration, persistence, Memory Engine, Layout Engine,
  Renderer, Export, PhotoKit, and Apple Photos workflow changes.
