# Default Memory Subject Privacy Design

## Goal

Remove family-specific names and dates from user-visible defaults and examples.

## Scope

- Use `小宝` as the default user-visible memory-subject nickname.
- Use `小宝、宝宝、小朋友` where the UI presents multiple nickname examples.
- Use `2024-01-01` as the synthetic default birthday and
  `2026-06-01 12:00:00` as the synthetic preview capture time.
- Use `示例省 / 示例市 / 示例区` for preview location data.
- Remove family-specific names from test fixtures, generated guides, snapshots,
  and current repository documentation.

## Implementation

Update runtime source strings and synthetic defaults without changing Memory
Engine, Layout Engine, Renderer, Export, Metadata, Share Extension, or Photo
Library behavior. Synchronize test assertions and remove generated artifacts
that embed private values.

## Verification

- Search the tracked repository for former family-specific values, exact
  private coordinates, device identifiers, and signed artifacts.
- Run focused tests covering changed defaults and preview composition.
- Run the preferred unsigned Debug build.
