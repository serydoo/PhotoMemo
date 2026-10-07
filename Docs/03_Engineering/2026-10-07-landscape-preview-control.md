# Landscape preview recovery control

> Current checkpoint (2026-10-07): the owner provisionally accepts the small-phone landscape UI and authorizes source synchronization. The current implementation reserves the rail region, supports contextual preview collapse, unifies panel/header alignment and uses icon-only navigation selection. Earlier observations below are chronological evidence. Small-phone two-pane exploration is superseded; native Duo integration and the comprehensive keyboard/accessibility matrix remain open. See [source checkpoint](2026-10-07-landscape-source-checkpoint.md).

Product Loop / P1. Owner observes that expanded landscape preview consumes the
page and its header toggle becomes difficult or impossible to reach; collapsing
restores scrolling. Owner requests a reachable control near the floating rail.

Cause: preview is outside the editor ScrollView and sized by width; card editing
also forces preview visible and hides the normal configuration header. A toggle
alone cannot work during editing unless the compact-height visibility rule is
updated explicitly.

Bounded decision: in compact-height configuration, show a separate contextual
preview action below the existing three-destination navigation capsule. Reuse
the same root-owned transient visibility and localized show/hide labels, with a
minimum44pt target and accessible current-state value. Never add a fourth EntryTab.
Allow the existing collapsed choice to take effect during compact-height card
editing; portrait retains its automatic preview restoration. Toggling dismisses
the keyboard through the existing callback. Preserve the single editor scroll
owner and TextKit session. Do not make the image itself vertically scrollable or
change output, renderer, export, photos, preset or configuration semantics.

Duo follow-up maps this contextual action to the native toolbar/overflow system,
not to a custom imitation of its navigation bar. This increment targets the
ordinary-phone fallback rail; full native Duo integration remains separate.

Files: AdaptiveNavigationShell, MemoMarkConfigurationCenterView+Pages,
ConfigurationPreviewVisibilityState, existing visibility tests. Verify collapsed
editing/show-again/portrait restoration transitions, architecture contracts,
signed physical iPhone build/install/launch and expanded/collapsed landscape
readback. Both rotations, keyboard, VoiceOver and larger fonts require manual
acceptance; host tests alone do not certify them.

Owner follow-up: time-expression expansion is too empty. Include a bounded
layout-only change in ConfigurationOptionList: regular-width, compact-height
and ordinary type sizes group the explanation/options on the leading side and
the resolved example on the trailing side using AnyLayout. Compact width,
portrait, accessibility sizes and macOS retain vertical composition. Existing
picker already falls back to a native menu when segments cannot fit; retain
all translated helper copy, entitlement checks and sample computation. No new
input controls, typography scaling or persisted preferences.

Owner also requests Save and More below the rail. Reuse ConfigurationActionFooter
with a rail presentation and the same callbacks/disabled states/destructive
confirmations, supplied by the root; hide the bottom footer only in compact
height. Keep save/more out of primary navigation. During card-content inspection
keep its existing transactional Done action and show only preview viewing control.
The rail footer uses vertical ViewThatFits: separate save/more when height permits,
otherwise one native More menu containing Save. Check physical height fit.
As a final short-height fallback, the side controls have their own bounded
vertical scrolling region; native alignment keeps them centered when they fit.
This is independent of the existing editor scroll owner. Verify keyboard fit on
device before claiming its interaction accepted.

Physical follow-up: owner opened expression section; inspected
`/tmp/MemoMark-expression-current.png`. The example occupies almost half the
panel width, touches its top edge and competes with the choices; the final
segment is visually crowded. Owner requests a smaller, lower example. Bounded
P2 adjustment: cap the horizontal example region at240pt (including its outer
padding), center it vertically against the explanation/options group, use
symmetrical vertical padding, preserve fonts/wrapping and the existing vertical
portrait/accessibility layout. This is UI presentation geometry only. Verify
signed physical build and readback; do not alter input or output geometry.

Owner acceptance boundary: ordinary small-phone landscape card-content editing
keeps the current surface and side preview toggle; stop further two-pane changes
there. On Duo, pursue simultaneous complete preview/editor presentation when
space permits, with native geometry and navigation integration. This supersedes
the ordinary-phone two-pane candidate in the earlier observation proposal.

Owner authorizes continuing the consolidated alignment/weight pass. Live
comparison `/tmp/MemoMark-expression-alignment-comparison.png` confirms different
12pt vs16pt inset and shorter expression panel. Horizontal expression container
now owns page-content horizontal and card vertical padding; children drop their
duplicate outer padding, share a content edge, and keep a12pt inter-region gap.
Expand panel to available width before its background. Preserve vertical layout.
Reduce only rail Save's visible circle to36pt/icon17pt while retaining46pt touch
area, states and callbacks. Hide header preview toggle in compact-height where
the rail provides it, retaining portrait header behavior. Verify signed iPhone
and shared macOS builds, focused contracts and physical screenshot readback.

Owner broadens the pass to overall harmony and consistency. Extend the shared
landscape16pt panel content edge across anchor/content/logo rows, dividers,
destination/Photos-description panels and FilmMark configuration controls,
rather than altering only two sections. Add an optional inset parameter to the
existing responsibility-owned row and FilmMark position components; default
values preserve other hosts, portrait, macOS and history surfaces. Keep component
roles (navigation, primary save, example feedback) distinct while sharing edge,
spacing and interaction-target rules. No global compact-metrics change, no input
geometry or business behavior change. Inspect native sheet layouts separately;
this pass does not certify every secondary sheet from a single screenshot.

Owner's IMG_6493/6494/6495 comparison adds Home/Progress header consistency.
Home compact-height uses centered native title plus brand introduction; Progress
uses a leading ConfigurationPageHeader and hides its native navigation bar.
Adopt the same page-header component,10pt top inset and12pt section spacing on
landscape Home. Move its existing localized tagline to the page-header subtitle
and avoid repeating it in brand identity there. Keep brand, badge, facts and
settings. Hide Home's native navigation bar only in compact height; preserve
portrait. This also aligns Home/Progress navigation-host safe geometry. No queue,
processing, permission, commerce or photo-picking behavior changes.

Owner requests icon-only floating-navigation selection because the blue tiles
approach the capsule edges at its ends. Remove selected tile background, keep
accent-colored selected icon,46pt target, explicit rectangular hit shape and
isSelected accessibility trait. Capsule material, navigation behavior and save
action appearance are unchanged. Verify signed iPhone build and device readback.
