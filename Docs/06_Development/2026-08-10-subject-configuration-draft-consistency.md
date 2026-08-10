# Subject Configuration Draft Consistency

Date: 2026-08-10

Primary loop: Engineering Loop

Risk: P1

## Objective

Prevent Subject creation or switching from leaving Configuration Center with
no usable current configuration. When the selected Subject has no durable
Configuration, create a stable in-memory draft that can be edited and saved for
the first time without writing an invalid active selection to the durable
Configuration Library.

## Observed Evidence

Production diagnostics from an iPhone recorded repeated
`configuration.candidate.invalid` failures while one Subject and three
Configurations still existed, but no active Configuration could be resolved.
The current switching contract explicitly clears `selectedMemoryPresetID`,
`draftMemoryConfiguration`, and `activeConfigurationID` for a Subject without
Configurations, while the save candidate builder requires a valid active
Subject and Configuration.

## Ownership And Boundaries

- `ConfigurationSession` and `ConfigurationEditingState` own the in-memory
  selection and draft lifecycle.
- `ConfigurationLibraryRecord` remains the durable configuration source of
  truth and must remain valid at every persistence boundary.
- A new draft is not durable until a successful repository receipt reconciles
  it into the Configuration Library.
- Renderer, Layout Engine, Export, Share Extension, PhotoKit, EXIF, Live Photo,
  and original-photo behavior are out of scope.
- Subject count and MemoMark+ commerce policy are out of scope.

## Accepted Behavior

1. Switching to a Subject with a durable Configuration restores a durable
   selection.
2. Switching to a Subject without one creates one stable in-memory preset/draft
   bound to that Subject.
3. The draft does not inherit another Subject's title, region bindings, anchor,
   output settings, or custom memory text.
4. Creating the draft does not persist a dangling active Configuration ID.
5. First save inserts the draft Configuration into the selected Subject,
   assigns it as the aggregate's active Configuration, validates the complete
   aggregate, and preserves the draft ID.
6. Save failure preserves the draft and user edits for retry.
7. Re-selecting the same Subject reuses the stable draft rather than creating
   duplicates.
8. Preview drafts rebuild once from the resolved Subject/configuration context;
   manual device acceptance remains separate from automated evidence.

## Failure Modes

- A draft ID is written as the durable active Configuration before insertion.
- A new Subject inherits another Subject's configuration content.
- Repeated selection creates multiple drafts.
- An asynchronous selection receipt overwrites a newer Subject selection.
- First-save failure clears or replaces the draft.

## Verification

- Focused Swift Testing contracts for Subject switching and apply payload
  construction.
- Existing configuration lifecycle, persistence, apply-runtime, and Subject
  library suites.
- Full `PhotoMemoTests` where practical.
- Generic iOS Debug build.
- Signed overwrite install and launch on the connected iPhone 17 Pro Max,
  preserving existing app data.
- Manual device check for existing-configuration switching, no-configuration
  switching/new Subject, first save, and return switching.
