# Configuration landscape rail: stable primary navigation

## Decision gate

Product Loop / P2, observed owner feedback: the configuration-only preview/save/more controls share a centered scrolling stack with the three primary destinations. Their added height shifts Home/Configuration/Progress navigation relative to the other pages and visually crowds the capsule.

Owner authorizes preview above the capsule, save/more below it, with identical primary-navigation positions across all three destinations in landscape. This is shell chrome polish; selection binding, TabView identity, preview state, footer commands, durable configuration, Apple Photos, media, lifecycle and rendering ownership stay intact. Portrait/sidebar behavior is unchanged. Current release131 on Cloud remains immutable; this local refinement does not authorize another push or new release.

## Bounded implementation

AdaptiveNavigationShell is the sole rail geometry owner. Reuse native SwiftUI VStack and independent vertical ScrollViews in equal flexible upper/lower regions around a fixed intrinsic-height primary capsule. Empty contextual regions retain their layout share on Home/Progress. Preview aligns toward the capsule from above; save/more align toward it below. Short-height contextual regions scroll independently rather than moving/clipping primary navigation. Existing46pt targets, labels, material and action ownership remain. No screen/model checks or alternate selection state.

## Verification

First physical regression reproduces page-dependent rail positions and preview-after-navigation ordering. Then verify fixed x/y/size of all three destinations across Home, Configuration (preview expanded and collapsed), Progress, and both landscape directions; preview above, save/more below, with no hit-target overlap. Check preview round trip, native more menu, actual screenshots and signed build/install/normal launch. Focused responsive/source contracts and relevant host suite. No Simulator. Preserve user configuration and preview choice; no Photos changes. Keyboard-reduced-height/accessibility and other devices are separately reported if not exercised. Final manual comfort acceptance stays with owner.

## Rotation follow-up within the same pass

Paired measurement exposes stale horizontal shell inset after opposite landscape rotation: reference x883 then configuration x833, with identical y137/187/237. Window geometry was captured during UIKit layout and only publication deferred; scene orientation could still be the previous pose. Read and publish live window geometry together after the layout pass, preserving the existing scene/safe-area owner and unobstructed-edge contract. This is part of the requested cross-destination stability, not a device-model branch.

Opposite landscape poses may leave bounds and safe insets identical, so deferring the read alone did not close the regression. Observe the existing orientation notification only as an invalidation signal while attached to a window, then read hosting-window scene geometry asynchronously. No physical device pose is read. Remove observation on detachment/deinitialization. This supplies the missing refresh without polling or fixed delays.

## UI pass closure

Owner accepts the visual result. Verified physical regression1PASS/0fail covers both landscape directions, fixed primary x/y/size across Home/Configuration/Progress, preview round trip and contextual ordering/hit sizes, native More menu open/dismiss. Upper/lower contextual slots preserve the original three46pt targets. Full host2124PASS/1existing skip/0fail; final responsive contracts61PASS. iOS signed Release build passes. Earlier probe failures exposed stale scene refresh and a test attempting to dismiss a native popover through an obscured rail button; final test dismisses outside the popover. Earlier screenshot clipping/orientation limitations persist, and source geometry/owner visual acceptance are distinct. Keyboard/accessibility-height and other-device manual acceptance remain open. User subsequently authorizes replacement132 delivery under its own release manifest.
