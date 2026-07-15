# Default Memory Subject Privacy Design

## Goal

Remove the family-specific `途途` name from user-visible defaults and examples.

## Scope

- Use `小宝` as the default user-visible memory-subject nickname.
- Use `小宝、宝贝儿、安安` where the UI presents multiple nickname examples.
- Set the default birthday to `2025-12-20`.
- Keep camera parameters, device models, author headers, historical documentation, and test-only scenario names unchanged.

## Implementation

Update only runtime source strings and default dates that can appear in the app. Synchronize focused assertions when they directly encode those defaults. Do not change Memory Engine, Layout Engine, Renderer, Export, Metadata, Share Extension, or Photo Library behavior.

## Verification

- Search runtime source for remaining user-visible `途途` occurrences.
- Run focused tests covering changed defaults and preview composition.
- Run the preferred unsigned Debug build.
