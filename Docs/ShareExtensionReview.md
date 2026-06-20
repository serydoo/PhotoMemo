# PhotoMemo Share Extension Review

Last updated: 2026-06-20

## Purpose

This is a user-centered review of the current Share Extension.

The goal is not to review code quality.

The goal is to answer one question:

If the Share Extension is the primary product entry, does it already feel natural enough for first-time users?

Short answer:

Not yet.

The current extension is functional as an intake bridge, but it still behaves more like a background handoff screen than a real product surface.

## Current State

Today the Share Extension does this:

- accepts shared photos
- persists them into PhotoMemo intake
- shows a loading indicator
- returns a simple success or failure sentence

What it does not do yet:

- show a real preview
- show the currently active configuration in user language
- allow configuration switching
- allow generate-and-save directly inside the extension
- provide clear save feedback back into Photos

## First-time User Review

### Will a first-time user get lost?

Yes, mildly.

The current extension does not explain what will happen next in user terms.

The message "正在交给 PhotoMemo 处理..." is technically true, but it does not answer the user questions that matter:

- Which result will I get?
- Where is it being saved?
- Do I need to open PhotoMemo afterward?
- Is this already finished or only queued?

For experienced users this may be acceptable.

For first-time users it creates uncertainty.

### Can one page be removed?

Yes.

The current extension is effectively an intermediate handoff screen.

In the long-term target workflow, this screen should evolve into the actual working surface:

Share

-> Preview

-> Confirm configuration

-> Generate

-> Save

That means the "queued into PhotoMemo inbox" state should become a fallback path, not the default primary path.

### Can one click be removed?

Yes.

The best first reduction is:

- keep one default active configuration
- surface it immediately
- let the user generate without first opening another chooser unless they want to switch

In other words:

Configuration choice should be optional on the happy path.

### Can more be completed by default?

Yes.

The extension should increasingly assume:

- use the current active configuration
- generate immediately
- save back to Photos
- return the user to their photo browsing flow

The user should only intervene when they want a different configuration or need to resolve an error.

## Primary UX Findings

### Finding 1

The extension currently behaves like infrastructure, not product.

It is optimized for intake persistence rather than for user completion.

### Finding 2

There is no preview truth inside the extension yet.

That means the user cannot confirm whether the result is worth saving before leaving the share flow.

### Finding 3

The current success state confirms transfer, not completion.

This is appropriate for a queue system, but it does not yet satisfy the share-first product promise.

### Finding 4

There is not enough visible defaulting.

If PhotoMemo wants to feel light, the extension should make more decisions on behalf of the user:

- active configuration
- output destination
- normal success path

### Finding 5

The extension still assumes the Main App is where understanding happens.

That is the opposite of the new product direction.

## Recommended Direction

### Phase 1

Keep the current intake path, but improve wording and certainty.

The user should understand:

- what configuration is being used
- whether this is queued or finished
- where the result will appear

### Phase 2

Turn the extension into a lightweight preview-and-confirm flow.

Minimum viable extension surface:

- preview
- active configuration label
- switch configuration
- generate
- save

### Phase 3

Make the happy path nearly one-tap after share.

Ideal default:

- open extension
- preview is ready
- current configuration already selected
- user taps save

### Phase 4

Support multi-photo share with predictable batch behavior.

Only after single-photo flow feels excellent.

### Phase 5

Explore zero-configuration intelligent mode.

This should stay an assessment topic until configuration reliability and preview trust are already strong.

## Smart Mode Assessment

Can PhotoMemo eventually choose a configuration automatically?

Probably yes, but not yet as a product default.

Why:

- the concept fits the share-first direction well
- it reduces decisions
- it matches the "Photos first, configuration second" principle

Why not yet:

- wrong automatic choices will damage trust quickly
- configuration semantics are still user-defined and personal
- the extension must first become strong at preview, switching, and save feedback

Recommendation:

Treat automatic configuration choice as a later optimization, not a current Alpha requirement.

## Terminology Review

The extension should prefer:

- Photo
- Memory
- Configuration
- Time Point
- Save
- Output

It should avoid:

- Workspace
- Configuration Slot
- Batch Snapshot
- Metadata Context
- Template Skeleton

## Summary

The Share Extension is already a valid technical bridge.

It is not yet a complete primary product experience.

The next UX goal is clear:

Move from "handoff to PhotoMemo" toward "complete the memory result inside the share flow."
