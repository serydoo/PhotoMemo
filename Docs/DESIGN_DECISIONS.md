# Design Decisions

Last updated: 2026-06-23

## Decision 1

Decision:

PhotoMemo is a Local First Memory Capability inside the Apple ecosystem.

Reason:

The product should extend Apple Photos workflows rather than compete with them.

Impact:

PhotoMemo cannot grow into a standalone gallery, editor, or photo-management system.

Status:

Frozen

## Decision 2

Decision:

PhotoMemo does not manage photos. It only owns Memory Workflow.

Reason:

Apple Photos already provides a mature photo-management system.

Impact:

Product architecture and future features must stay inside the memory-workflow boundary.

Status:

Frozen

## Decision 3

Decision:

PhotoMemo's foreground product surface is a permanent Configuration Center.

Reason:

Long-term configuration should be separated from daily photo use.

Impact:

The Configuration Center is not the primary daily entry point.

Status:

Frozen

## Decision 4

Decision:

The primary entry path is `Apple Photos -> Share -> PhotoMemo -> Processing -> Notification -> Apple Photos`.

Reason:

The best PhotoMemo experience should begin where users already manage photos.

Impact:

Share-first architecture remains the product-primary path.

Status:

Frozen

## Decision 5

Decision:

The default happy path follows Zero Interaction.

Reason:

PhotoMemo should reduce decisions during the moment of remembering.

Impact:

The happy path should require waiting rather than repeated interaction.

Status:

Frozen

## Decision 6

Decision:

PhotoMemo follows Quiet Computing by default.

Reason:

The product should finish in the background and only interrupt when necessary.

Impact:

User-facing workflow should prefer background completion and calm notifications.

Status:

Frozen

## Decision 7

Decision:

After completion, PhotoMemo returns users to Apple Photos by default.

Reason:

PhotoMemo should support the photo flow rather than hijack it.

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

PhotoMemo should automatically recover tasks whenever possible.

Reason:

Users should only be interrupted when recovery truly fails.

Impact:

Behavior design should default to recovery before escalation.

Status:

Frozen

## Decision 10

Decision:

PhotoMemo should automatically follow Apple device constraints.

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

Generated photos should remain near their originals and also join the PhotoMemo output album.

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

PhotoMemo is a non-destructive memory workflow.

Impact:

All future output work must preserve the original image unchanged.

Status:

Frozen

## Decision 14

Decision:

Metadata remains preserved, with canvas size as the only allowed output-level change.

Reason:

PhotoMemo should preserve the photo's objective usefulness while generating a new memory result.

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

PhotoMemo always trusts Apple Photos.

Reason:

Apple Photos already owns the higher-order systems users depend on every day.

Impact:

PhotoMemo will not rebuild gallery, timeline, map, people, search, or sync systems.

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

PhotoMemo has explicit anti-goals against becoming its own gallery, timeline, map, people manager, search system, browser, editor, dashboard, workspace, or task center.

Reason:

The product must stay disciplined about what it is not.

Impact:

Future feature proposals should be rejected when they cross the Apple Photos boundary.

Status:

Frozen

## Decision 20

Decision:

Apple Photos and PhotoMemo have an explicit product-boundary split.

Reason:

The repository needs one stable statement of ownership for Apple Photos versus PhotoMemo.

Impact:

Future product work must check whether a capability belongs to Apple Photos or to PhotoMemo before entering implementation.

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

PhotoMemo should recommend the best experience without turning guidance into a rigid product restriction.

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

PhotoMemo exists to help people read their memories, not just store their photos.

Reason:

The repository needs one stable mission statement that explains why the product exists.

Impact:

Future product work should reinforce memory reading rather than drift toward generic photo storage or management.

Status:

Frozen
