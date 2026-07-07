# Design Decisions

Last updated: 2026-06-24

## Decision 1

Decision:

MemoMark is a Local First Memory Capability inside the Apple ecosystem.

Reason:

The product should extend Apple Photos workflows rather than compete with them.

Impact:

MemoMark cannot grow into a standalone gallery, editor, or photo-management system.

Status:

Frozen

## Decision 2

Decision:

MemoMark does not manage photos. It only owns Memory Workflow.

Reason:

Apple Photos already provides a mature photo-management system.

Impact:

Product architecture and future features must stay inside the memory-workflow boundary.

Status:

Frozen

## Decision 3

Decision:

MemoMark's foreground product surface is a permanent Configuration Center.

Reason:

Long-term configuration should be separated from daily photo use.

Impact:

The Configuration Center is not the primary daily entry point.

Status:

Frozen

## Decision 4

Decision:

The primary entry path is `Apple Photos -> Share -> MemoMark -> Processing -> Notification -> Apple Photos`.

Reason:

The best MemoMark experience should begin where users already manage photos.

Impact:

Share-first architecture remains the product-primary path.

Status:

Frozen

## Decision 5

Decision:

The default happy path follows Zero Interaction.

Reason:

MemoMark should reduce decisions during the moment of remembering.

Impact:

The happy path should require waiting rather than repeated interaction.

Status:

Frozen

## Decision 6

Decision:

MemoMark follows Quiet Computing by default.

Reason:

The product should finish in the background and only interrupt when necessary.

Impact:

User-facing workflow should prefer background completion and calm notifications.

Status:

Frozen

## Decision 7

Decision:

After completion, MemoMark returns users to Apple Photos by default.

Reason:

MemoMark should support the photo flow rather than hijack it.

Impact:

Completion surfaces should avoid turning the Configuration Center into the final destination.

Status:

Frozen

## Decision 8

Decision:

Progress language must be human, gentle, calm, and confident.

Reason:

Memory processing should not expose technical vocabulary or operational anxiety.

Impact:

Percentages and developer terms are prohibited in user-facing progress.

Status:

Frozen

## Decision 9

Decision:

MemoMark should automatically recover tasks whenever possible.

Reason:

Users should only be interrupted when recovery truly fails.

Impact:

Behavior design should default to recovery before escalation.

Status:

Frozen

## Decision 10

Decision:

MemoMark should automatically follow Apple device constraints.

Reason:

Device state should remain authoritative for background and processing behavior.

Impact:

No separate performance mode should be introduced.

Status:

Frozen

## Decision 11

Decision:

Storage should be estimated before processing begins.

Reason:

The user should be warned before a preventable failure, not after it.

Impact:

Future processing UX should include preflight storage verification.

Status:

Frozen

## Decision 12

Decision:

Generated photos should remain near their originals and also join the MemoMark output album.

Reason:

The output should feel consistent inside Apple Photos without losing the dedicated output surface.

Impact:

Library consistency becomes a product requirement, not an incidental export detail.

Status:

Frozen

## Decision 13

Decision:

The original photo never changes.

Reason:

MemoMark is a non-destructive memory workflow.

Impact:

All future output work must preserve the original image unchanged.

Status:

Frozen

## Decision 14

Decision:

Metadata remains preserved, with canvas size as the only allowed output-level change.

Reason:

MemoMark should preserve the photo's objective usefulness while generating a new memory result.

Impact:

Metadata preservation remains a hard product boundary.

Status:

Frozen

## Decision 15

Decision:

Output naming should follow Apple naming conventions.

Reason:

Naming consistency should feel native and unsurprising inside Apple Photos.

Impact:

Names such as `IMG_1234 (1)` become the product-standard expectation.

Status:

Frozen

## Decision 16

Decision:

MemoMark always trusts Apple Photos.

Reason:

Apple Photos already owns the higher-order systems users depend on every day.

Impact:

MemoMark will not rebuild gallery, timeline, map, people, search, or sync systems.

Status:

Frozen

## Decision 17

Decision:

The product personality is calm, quiet, respectful, invisible, and trustworthy.

Reason:

Memory products should earn trust through tone and restraint.

Impact:

Future UI, messaging, and workflow design must reflect these traits.

Status:

Frozen

## Decision 18

Decision:

All configuration belongs to `System Defaults -> User Preferences -> Advanced`.

Reason:

Configuration complexity needs one stable hierarchy before new settings are added.

Impact:

Every future option must declare its layer before entering the product.

Status:

Frozen

## Decision 19

Decision:

MemoMark has explicit anti-goals against becoming its own gallery, timeline, map, people manager, search system, browser, editor, dashboard, workspace, or task center.

Reason:

The product must stay disciplined about what it is not.

Impact:

Future feature proposals should be rejected when they cross the Apple Photos boundary.

Status:

Frozen

## Decision 20

Decision:

Apple Photos and MemoMark have an explicit product-boundary split.

Reason:

The repository needs one stable statement of ownership for Apple Photos versus MemoMark.

Impact:

Future product work must check whether a capability belongs to Apple Photos or to MemoMark before entering implementation.

Status:

Frozen

## Decision 21

Decision:

Every Memory Workflow freezes a Configuration Snapshot at start, and the running task becomes read-only.

Reason:

Users need predictable behavior during processing, even if preferences change afterward.

Impact:

Configuration changes made during a task may only affect the next task.

Status:

Frozen

## Decision 22

Decision:

Behavior is documented through a state machine, not through UI flow definitions.

Reason:

Interaction architecture should preserve product behavior independently from any one interface implementation.

Impact:

Future reviews should discuss `Idle -> Share -> Preparing -> Processing -> Completed -> Reading` and recovery/preparation branches as behavior architecture.

Status:

Frozen

## Decision 23

Decision:

Smart Batch Recommendation replaces fixed maximum, limit, or threshold language.

Reason:

MemoMark should recommend the best experience without turning guidance into a rigid product restriction.

Impact:

Batch guidance must be phrased as recommendation based on device performance, photo count, and runtime conditions.

Status:

Frozen

## Decision 24

Decision:

Every future feature must pass the Apple review checklist before implementation.

Reason:

The product needs one repeatable pre-implementation filter for native fit, complexity, and duplication risk.

Impact:

New work should not proceed unless it passes the page, button, learning-cost, Apple-Photos, duplication, and Apple-likeness checks.

Status:

Frozen

## Decision 25

Decision:

The Never Break List is a permanent top-level review gate.

Reason:

Some principles are too fundamental to be rediscovered separately in each feature review.

Impact:

Every implementation and every review must check `Docs/NEVER_BREAK.md` first.

Status:

Frozen

## Decision 26

Decision:

MemoMark exists to help people read their memories, not just store their photos.

Reason:

The repository needs one stable mission statement that explains why the product exists.

Impact:

Future product work should reinforce memory reading rather than drift toward generic photo storage or management.

Status:

Frozen

## Decision 27

Decision:

The Configuration Center edits Objects, not Data.

Reason:

MemoMark users should understand the foreground app as a place for shaping durable memory objects, not as a form for changing isolated strings, dates, or configuration fields.

Impact:

Future Configuration Center work must treat strings, dates, tokens, presets, and decorations as properties of objects such as Memory Subject, Memory Card, Decoration, and Preset.

Status:

Frozen

## Decision 28

Decision:

Everything starts from the Memory Card.

Reason:

The Memory Card is the primary object of the Configuration Center and should unify preview, navigation, and selection.

Impact:

Future Configuration Center interaction should begin from Memory Card regions rather than separate form-first or settings-first panels.

Status:

Frozen

## Decision 29

Decision:

The Configuration Center uses `Library -> Interactive Memory Card -> Object Inspector`.

Reason:

The three-column structure makes object selection, primary object interaction, and object inspection explicit.

Impact:

Future UI work must not restore top-bottom layout, Workspace layout, dashboard layout, or task-center layout.

Status:

Frozen

## Decision 30

Decision:

Object Inspector replaces generic editor language for Configuration Center object inspection.

Reason:

MemoMark needs one consistent object-inspection model for Memory Subject, Memory Card, Decoration, Preset, and future objects.

Impact:

Inspector layouts should follow a consistent structure: Overview, Properties, Behavior, Resources, and Preview.

Status:

Frozen

## Decision 31

Decision:

Configuration Center routing should flow from `CardRegion` to `InspectorProvider` to Object Inspector.

Reason:

String matching and growing region switches make future interaction architecture brittle.

Impact:

Future card hover, selection, Inspector routing, and accessibility must be based on `CardRegion`.

Status:

Frozen

## Decision 32

Decision:

Memory Tokens use capture time, not export time.

Reason:

MemoMark records the moment when a photo was captured, not when a generated output was exported.

Impact:

Re-exporting a photo must not change the Memory Expression when the Photo Capture Date and Reference Date are unchanged.

Status:

Frozen

## Decision 33

Decision:

MemoMark must establish and reuse a Configuration UI Design System.

Reason:

Memory Card, Object Inspector, Library, Apple Token, Section, Property, Button, and Empty State should behave consistently across the Configuration Center.

Impact:

Future Configuration UI should reuse shared design-system components rather than repeatedly implementing isolated page-specific patterns.

Status:

Frozen

## Decision 34

Decision:

Configuration Center previews the real Memory Card, not an abstract layout.

Reason:

The center surface should show the same Bottom Card structure that future rendered outputs will use, instead of showing a schematic set of editable boxes.

Impact:

Interactive Memory Card should preserve the real Bottom Card structure: Decoration, Slot A, Slot B, and Slot C plus Slot D. Region Strip may provide a secondary slot-selection path, but it must select the same `CardRegion` objects as the card itself.

Status:

Frozen

## Decision 35

Decision:

IA-002 Configuration Center Architecture is complete and frozen. MemoMark now enters Product Realization through IA-003 Memory Engine Integration.

Reason:

The repository now has stable positions for Library, Memory Subject, Interactive Memory Card, Object Inspector, Configuration Snapshot, Memory Engine, Renderer, and Export. The next question is no longer what the product should be, but how each frozen concept becomes a real running pipeline.

Impact:

Future UI work is polish, not architecture redesign. IA-003 begins with `MemorySubject Adapter`, then proceeds through Configuration Snapshot, Memory Block Resolver, CaptureTimeResolver, Memory Card real-data connection, and Renderer. IA-003A must not modify Renderer, Metadata, Export, Share Extension, Photo Library behavior, or Layout Engine work.

Status:

Frozen

## Decision 36

Decision:

Preview is the Renderer before Rendering.

Reason:

Configuration Center should preview the real Memory Card that MemoMark will generate, not a photo placeholder, an abstract editor layout, or a separate configuration-only composition. Photos belong to Apple Photos; MemoMark owns the Memory Card.

Impact:

The center surface is Memory Card Preview. It should default to looking like an already-generated Memory Card, with editability revealed only through hover, selection, and Region Strip navigation. Renderer layout changes and Memory Card Preview layout must stay aligned so configuration and final output do not drift into separate systems.

Status:

Frozen

## Decision 37

Decision:

MemoryBlock is a field-based content asset, not a layout slot.

Reason:

MemoMark needs a Memory Language Layer that can express growth records, anniversaries, travel records, device records, family memories, and future dynamic memory types without forcing every block into the current four-slot layout or into a fixed Subject + Action + Result structure.

Impact:

The long-term MemoryBlock model is `templateID + fields`. `Subject + Action + Result` is frozen as Preset Schema #001, not as the core model. BlockField values may come from fixed text, token bindings, smart module bindings, or custom field bindings. IA-003A should remain MemorySubject Adapter work; the first implementation point for this decision is IA-003C Memory Block Resolver.

Status:

Frozen
