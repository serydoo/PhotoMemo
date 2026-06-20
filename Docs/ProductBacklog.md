# PhotoMemo Product Backlog

Last updated: 2026-06-20

This backlog exists to protect development rhythm.

New ideas should be sorted here instead of interrupting the current most important work.

## Now

These are the current must-do items.

- Introduce `Personal Profile` as the new owner of relationship, baby nickname, birthday, default album, and default style.
- Design and implement a one-time First Run Experience instead of exposing all setup fields immediately.
- Redefine `Style` as style-only data, separate from identity and album defaults.
- Continue replacing developer-facing terms with user language such as `风格`, `生日`, and `记忆日期`.
- Make the Main App converge toward four sections:
  - Personal Profile
  - Styles
  - Settings
  - About
- Keep the Share Extension on a zero-friction path that reads Personal Profile + default Style automatically.
- Preserve preview-to-render-to-export trust while setup flows become simpler.
- Keep metadata retention and save-back reliability stable while product structure evolves.

## Next

These are the next-stage items after the current UX baseline feels stable.

- Migrate current anchor terminology toward birthday / memory-date language across the app.
- Backfill Personal Profile from existing settings without breaking current users.
- Introduce a lightweight Share Extension preview-and-confirm flow only after setup is stable.
- Improve save feedback so users clearly know where results appear in Photos.
- Consolidate the UI into the documented design system.
- Prepare a more compact iPhone setup and style-management experience.

## Later

These are important, but not immediate.

- Batch share support from Apple Photos.
- Quick actions and faster repeat-use flows.
- More intelligent defaulting around style selection and album behavior.
- Better progress visibility through Live Activities and iPhone-native feedback surfaces.
- A stronger visual snapshot / renderer regression layer.
- More complete fixture coverage for additional real-world photo types.
- Family profiles or multiple child profiles if the single-profile model proves too narrow.

## Icebox

These are valid ideas, but not planned for active development now.

- Zero-configuration intelligent mode that chooses a style automatically.
- Automatic scene or memory-type classification.
- Style recommendation based on photo content or usage history.
- Additional template ecosystems or broader style families.
- More advanced memory storytelling layers beyond the current deterministic pipeline.

## Backlog Rules

1. "Now" items should stay small and concrete.

2. New ideas should default to "Later" or "Icebox" unless they unblock the core workflow.

3. Anything that weakens preview trust, metadata integrity, or save reliability should not outrank current workflow simplicity.

4. Share-first product work should outrank decorative expansion.

5. The most important question remains:

How do we let users configure PhotoMemo once, stay inside Apple Photos, and receive a result worth keeping with as little friction as possible?
