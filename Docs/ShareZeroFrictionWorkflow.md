# PhotoMemo Share Zero-Friction Workflow

Last updated: 2026-06-20

## Principle

The default share workflow must require as few decisions as possible.

Users should not re-configure PhotoMemo during normal sharing.

Configuration belongs to the Main App.

The Share Extension exists to finish work, not to open another setup flow.

## Default Workflow

The default path should be:

Apple Photos

-> Share

-> PhotoMemo

-> Automatically use the current configuration

-> Continue processing

-> Save back to Photos

This default path should not require:

- choosing a configuration every time
- opening the Main App first
- reading long explanations
- acknowledging a separate confirmation page

## Product Rule

The Share Extension should optimize for:

- speed
- confidence
- low reading cost
- low decision cost

It should not optimize for:

- full configuration management
- deep template editing
- teaching internal implementation concepts

## Responsibility Split

### Main App

The Main App is the configuration center.

It owns:

- template editing
- anchor management
- save defaults
- configuration naming
- future advanced settings

### Share Extension

The Share Extension is the execution surface.

It should:

- accept the shared photos
- use the current configuration by default
- communicate what will happen in plain user language
- avoid interrupting the user unless there is an error

## Zero-Friction UX Baseline

When the extension opens, the user should immediately understand three things:

1. PhotoMemo will use the current configuration automatically.
2. The result will continue toward save-back without more setup.
3. If they want to change settings, that belongs in the Main App, not in this moment.

That means the default share page should show:

- what PhotoMemo is about to use
- what kind of output path will happen
- one calm automatic-processing message

It should not default to:

- a configuration chooser
- a multi-step wizard
- a separate confirmation page
- developer language such as snapshot, workspace, or slot

## Advanced Settings Rule

Advanced settings may exist later, but they must be optional.

They should:

- stay collapsed by default
- never interrupt the happy path
- never block a fast share-save loop

If advanced settings are not yet strong enough to help more than they distract, they should remain in the Main App only.

## First Implementation Slice

The first Zero-Friction slice should not attempt a full preview-confirm-save flow yet.

Instead it should:

- keep the current intake-backed architecture
- replace handoff-style wording with automatic-processing wording
- passively surface the active configuration summary
- keep the extension tap-free on the happy path

This creates a better product surface now, without pretending that the extension already owns the full render-and-save loop.

## Later Evolution

Only after the automatic share path feels stable should PhotoMemo consider:

1. lightweight preview inside the Share Extension
2. optional configuration switching
3. optional advanced settings expansion
4. stronger completion feedback after save-back

These are important, but they must remain secondary to the Zero-Friction default.
