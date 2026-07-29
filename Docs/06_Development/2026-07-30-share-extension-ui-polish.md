# Share Extension UI Polish Pass

Date: 2026-07-30

## Decision Gate

- Primary loop: Product Loop.
- Observed scenario: the supplied Share screenshot shows a stable dark
  half-sheet with the accepted outer-card / inner-card hierarchy. The remaining
  issues are secondary: the lower action area leaves avoidable empty rhythm,
  the processing assurances are rendered as one attributed paragraph, and the
  hero heading and action hit target are not mapped to the strongest native
  accessibility structure.
- Intended outcome: keep the existing Share confirmation and handoff shell,
  make its status assurances independently aligned and accessible, preserve the
  restrained Apple semantic-color treatment, remove the repeated photo count
  from the hero subtitle, and move Share-specific layout values into named
  design tokens.
- Affected modules: `PhotoMemoShareExtensionViewController` owns UIKit
  composition and localized static labels; `ShareExtensionViewStateRenderer`
  owns projected state and dynamic status text; `MemoMarkDesignTokens` owns
  Share-specific geometry; focused source contracts guard the accepted shape.
- Out of scope: intake, persistence, configuration snapshots, queue
  submission, automatic dismissal, PhotoKit, renderer/export, Live Photo, and
  the established outer-card / inner-card hierarchy.
- Risk: P2 presentation and accessibility polish, with a bounded P1 touch-target
  concern. The main failure modes are altered state layout, localization drift,
  Dynamic Type wrapping, or a primary action that loses its existing handoff
  semantics.

## Bounded Implementation

1. Add failing source contracts for the heading hierarchy, Share layout tokens,
   44-point action hit target, independent checklist stack, and revised hero
   subtitle.
2. Add Share-specific tokens without changing the shared main-app compact
   action metrics.
3. Replace the attributed checklist with four native UIKit rows while keeping
   the same facts and state transitions.
4. Mark the brand as static text, promote the hero title to a heading, give the
   primary button a 44-point target, and remove the duplicated count from the
   hero subtitle.

## Verification Plan

- Run `ShareExtensionControllerSplitContractTests` red before implementation
  and green after each implementation slice.
- Run related Share workflow and Apple-native product-surface contracts.
- Run `git diff --check` and the unsigned generic iOS Debug build.
- Inspect the signed Share Extension on both default and larger text sizes;
  manual Apple Photos Share acceptance remains separate evidence.
