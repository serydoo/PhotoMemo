# Share Extension Stable-State UI Pass

Date: 2026-07-26

## Decision Gate

- Primary loop: Product Loop.
- Observed scenario: physical-device screenshots `IMG_6540.PNG`,
  `IMG_6541.PNG`, and `IMG_6542.PNG` show the Share Extension before the
  primary action, while receiving the shared photo, and immediately before its
  existing automatic dismissal.
- Product evidence: the Configuration Center and Output surfaces already use a
  stable page header followed by titled outer cards and responsibility-specific
  inner cards. Share now uses the same general nesting, but its hero copy,
  status-card header, status-card body, and disabled primary action all change
  between stages, producing visible layout and hierarchy shifts during a flow
  that lasts only a few seconds.
- Intended outcome: preserve one Share page structure from confirmation through
  successful handoff. Keep `本次分享` and `处理状态` in fixed positions; update
  only the status indicator, status copy, and primary-action completion state.
  Align the Share card rhythm with the current Configuration Center and Output
  surfaces while retaining a compact extension-specific UIKit implementation.
- Affected modules: `PhotoMemoShareExtensionViewController` owns UIKit
  composition and bindings; `ShareExtensionViewStateRenderer` owns the
  projected visual state; focused architecture contracts guard the accepted
  surface. No dependency direction changes.
- Source of truth: the durable configuration snapshot remains the source of
  photo-count, Memory Subject/configuration, and album summary values. Intake,
  persistence, handoff, queue, and automatic dismissal remain authoritative for
  workflow state. The UI only projects those facts.
- Apple-native capabilities evaluated: retain UIKit semantic colors,
  `UIActivityIndicatorView`, `UIButton.Configuration`, SF Symbols, Dynamic Type,
  VoiceOver announcements, and `NSExtensionContext` completion. No new Apple
  API, permission, background capability, or custom lifecycle mechanism is
  required.
- Privacy, offline, cancellation, and recovery: unchanged. Photos remain local,
  originals remain untouched, intake stays file-first, cancellation and partial
  failure paths retain their current behavior, and failed handoff remains
  retryable.
- Risk: P2 presentation-only. Failure modes are layout shift, clipped localized
  copy, inaccessible state changes, a completed action that still appears
  tappable, and accidental changes to failure/retry behavior.

## Bounded Implementation

1. Add focused source contracts that fail against the current changing-shell
   presentation.
2. Keep the page title and subtitle stable for the normal confirmation,
   receiving, and received states.
3. Keep `处理状态` as the stable outer-card title and move the dynamic state into
   one inner status row above the unchanged processing assurances.
4. Align outer-card geometry and surface treatment with the current iOS card
   system without importing main-app-only SwiftUI types into the extension.
5. Present the successful primary action as a disabled completion receipt while
   preserving the existing 700 ms automatic dismissal.
6. Preserve configuration-required, unsupported-input, admission-limit,
   failure, and handoff-retry states.

## Verification Plan

- Run the focused `ShareExtensionControllerSplitContractTests` red before the
  implementation and green after it.
- Run related Share intake and Apple-native product-surface contracts.
- Run `git diff --check`.
- Build `PhotoMemoShareExtension` and the required unsigned `PhotoMemo` Debug
  configuration.
- Manual signed-device acceptance: capture all three normal states at the same
  Dynamic Type size and verify no card, quote, or bottom-action position shifts;
  verify successful automatic dismissal and at least one retry/error path.
