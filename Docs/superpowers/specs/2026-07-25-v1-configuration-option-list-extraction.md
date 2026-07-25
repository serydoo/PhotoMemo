# V1 Configuration Option List Extraction

**Date:** 2026-07-25
**Stage:** V3 Production Quality And Delivery
**Status:** Complete
**Primary loop:** Engineering Loop

## Observed Current Behavior

`PhotoMemoiOSV1View.swift` contains the runtime composition for the iOS
Configuration Center and the full implementation of its Configuration Option
List. The Option List is a self-contained SwiftUI surface of roughly one
thousand lines, including its private action and navigation button styles.

The root view already constructs this surface by passing explicit values,
bindings, and callbacks. It should continue to own `ConfigurationSession`,
draft synchronization, persistence, navigation, and all side-effect ordering.

## Intended Outcome

Move `V1ConfigurationOptionList`,
`V1ConfigurationActionButtonStyle`, and
`V1ConfigurationNavigationRowButtonStyle` into
`iOS/Views/V1ConfigurationOptionList.swift`.

The new surface remains module-local and keeps the same initializer inputs,
state, callbacks, user-visible strings, destructive-action
confirmations, accessibility labels, Dynamic Type behavior, and reduced-motion
behavior. `PhotoMemoiOSV1View` retains only the construction site and its
scroll-offset preference types.

## Scope

- Extract the Option List and the two styles it alone uses.
- Preserve the root view as the only state and side-effect owner.
- Add an architecture contract that records the ownership boundary.

## Out Of Scope

- No Configuration Center interaction redesign.
- No changes to `ConfigurationSession`, persistence, backup/restore, export,
  Photo Library, Renderer, Memory Engine, or Layout Engine behavior.
- No changes to configuration terminology, copy, navigation, or visual rules.
- No extraction of additional root-view domains in this slice.

## Verification Plan

1. The new architecture contract must fail before the extracted file exists.
2. Run the focused architecture contracts after extraction.
3. Run the complete `PhotoMemoTests` Debug suite on macOS.
4. Run the required Debug build with code signing disabled.
5. Review the diff to verify that only the extracted UI, its contract, and this
   record changed; existing Commerce and research work must remain untouched.
