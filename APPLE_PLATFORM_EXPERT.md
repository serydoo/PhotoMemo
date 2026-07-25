# MemoMark Apple Platform Engineering Guidance

This document defines the Apple-platform review lens for AI agents and future
engineering sessions. It supplements `PROJECT_CONSTITUTION.md`, `AGENTS.md`,
accepted PDRs, RFCs, ADRs, contracts, and freeze documents. It does not override
them or authorize a new feature.

## Role

Think like a Principal Engineer responsible for a long-lived Apple ecosystem
application. Prefer architecture correctness, privacy, native lifecycle
integration, clarity, accessibility, and durable behavior over the shortest
implementation.

MemoMark is a local-first Memory Presentation Engine and a Memory Capability
inside Apple Photos workflows. It is not an image editor, photo manager,
contact database, cloud memory service, or replacement for Apple Photos.

The product pipeline remains:

```text
Photo
-> Metadata Engine
-> Memory Engine
-> Presentation Engine
-> Layout Engine
-> Renderer
-> Export
```

Apple frameworks may supply trusted platform facts and lifecycle operations.
MemoMark's accepted domain layers remain responsible for memory meaning,
configuration, expression, layout, rendering, and export policy.

## Apple-Native Evaluation

Before introducing a model, service, permission, custom interaction, or stored
identifier, evaluate whether Apple already provides the relevant capability.
Record the result in the task specification or boundary scan when the decision
is material.

Evaluate, as applicable:

- Photos: `PHAsset`, `PHPhotoLibrary`, resource identity, adjustment and save
  lifecycle, limited-library behavior, and non-destructive output
- Contacts: `CNContact`, stable identifiers, authorization scope, change and
  deletion behavior, and whether a reference is sufficient
- Time: `Calendar`, `DateComponents`, locale, calendar system, time zone, and
  capture-time semantics
- Location: Core Location values, geocoding availability, authorization,
  precision, locale, caching, and offline degradation
- Media: Image I/O, AVFoundation, Uniform Type Identifiers, orientation,
  paired resources, color space, metadata, and high-resolution cost
- Commerce: StoreKit entitlements, restoration, Family Sharing eligibility,
  transaction verification, and App Store policy
- UI: SwiftUI, system navigation and controls, Dynamic Type, VoiceOver,
  Reduce Motion, contrast, localization, and platform conventions
- Background work: extension limits, process suspension, cancellation,
  persistence, recovery, and system scheduling constraints

Native-first does not mean framework-first at any cost. Choose an Apple API
when it provides the correct capability and lifecycle. Do not add permissions,
cloud coupling, platform availability constraints, or opaque system ownership
without a demonstrated product benefit and explicit degradation path.

## Source Of Truth

Every important concept must have one identified canonical owner. Before adding
a model or cache, state why an existing canonical model cannot own the data.

Preserve these principles:

- Apple Photos owns the user's photo library and original assets.
- Objective media facts enter through the Metadata and media pipeline.
- Memory Engine owns Life Position and time-anchor meaning.
- The durable configuration aggregate defined by the current V3 contracts owns
  saved configuration truth; do not infer a generic snapshot as canonical.
- Layout Engine owns layout decisions and canonical geometry contracts.
- Renderer is stateless and consumes resolved presentation and layout input.
- Export preserves approved content and metadata behavior; it does not invent
  business meaning.
- UI projects state and intent; it does not bypass engine ownership.

Avoid parallel configuration systems, hidden mutable state, implicit
conversion chains, duplicate identities, and convenience caches without clear
invalidation and recovery semantics.

## Framework Boundaries

### Photos And Media

- Never modify the original asset. Generate and save a new output.
- Preserve quality, orientation, color, metadata, and paired-resource behavior
  according to the accepted export contracts.
- Do not assume JPEG, a fixed aspect ratio, upright pixels, or a small image.
- Geometry belongs to the media and Layout Engine contracts, not Renderer
  convenience calculations.
- Treat JPEG, HEIC, RAW, ProRAW/DNG, Live Photo, video-backed resources, and
  high-resolution media as distinct lifecycle and resource-cost cases.
- Validate behavior with real PhotoKit and signed-device evidence when the
  system boundary cannot be proven by unit tests or simulator builds.

### Share Extension

The Share Extension is an intake boundary. It may receive, validate, stage,
and durably hand off supported inputs. Heavy processing, rendering, complex
save-back work, and long-running orchestration belong outside the extension.

Design for extension memory pressure, time limits, cancellation, partial
provider failure, file representations, process termination, and idempotent
handoff. Never rely on the extension remaining alive after intake completes.

### People And Relationships

Before adding people or family capabilities, distinguish:

- Apple contact identity
- MemoMark Memory Subject identity
- a user-authored relationship or role
- a reference between those concepts

Do not build a replacement Contacts database. Do not assume a `CNContact`
exists for every Memory Subject or that contact access is always granted.
Contact linkage must be optional, permission-aware, locally stored, resilient
to identifier changes or deletion, and unable to overwrite MemoMark-authored
memory meaning without explicit user intent.

Family Sharing is a StoreKit distribution entitlement, not a family-memory
relationship model. Keep commerce ownership separate from Memory Subjects and
relationships.

### Time And Location

- Preserve the Capture-Time Principle: memory calculations use the photo's
  capture context, not merely the current clock.
- Smart anchor variables output time results, not complete prose.
- Define calendar, locale, time-zone, missing-value, and ambiguous-date
  behavior before implementation.
- Treat geocoded names as derived presentation, not objective metadata truth.
- Keep location behavior useful when permission, network, or geocoding is
  unavailable; do not upload media or memory context for convenience.

### Interface And Accessibility

Follow Apple Human Interface Guidelines through measurable product behavior:
clear hierarchy, native navigation, predictable controls, readable content,
and accessibility across supported devices and environments.

Prefer simple surfaces with deep capability underneath. Important cards should
be glanceable, have stable identity and hierarchy, and avoid unnecessary
controls. MemoMark's Configuration Center architecture remains `Library ->
Interactive Memory Card -> Object Inspector`; Apple-native polish must not
reopen it or introduce a Dashboard, Workspace, Task Center, or import-first
workflow.

Verify Dynamic Type, VoiceOver labels and traversal, Reduce Motion, contrast,
light and dark appearance, localization expansion, compact width, iPad layout,
keyboard behavior where applicable, and system permission states in proportion
to the change.

## Swift Engineering

Prefer modern Swift and Apple APIs when supported by the deployment targets and
current architecture. Use Swift Concurrency and structured cancellation where
they improve lifecycle correctness. Keep UI state on the correct isolation
boundary and keep expensive media work off the main actor.

Do not introduce UIKit, singletons, global mutable state, protocol layers,
manager types, or abstractions merely because they are common patterns. Each
type must have a clear owner, responsibility, lifecycle, dependency direction,
and verification seam. Preserve compatibility intentionally when modern API
adoption would raise the minimum platform or change established behavior.

## Review Protocol

For each non-trivial Apple-platform change, record before implementation:

1. conclusion and bounded objective
2. affected modules and dependency direction
3. canonical source of truth
4. Apple APIs evaluated and why they are or are not used
5. authorization, privacy, offline, cancellation, and recovery behavior
6. risk classification using the `AGENTS.md` P0/P1/P2 definitions
7. automated, simulator, signed-device, and manual evidence required

Reject or redesign a proposal when it:

- bypasses an accepted layer
- duplicates canonical state or identity
- makes Renderer own layout or business meaning
- moves heavy processing into the Share Extension
- treats Contacts, Family Sharing, or Photos as MemoMark domain models
- requires unnecessary access to user data
- modifies original media
- cannot explain cancellation, failure, recovery, and unavailable-service paths
- claims Apple-platform correctness without evidence at the relevant boundary

## Documentation Discipline

Documentation is part of the production system, but each artifact has a
specific purpose:

- PDR freezes product decisions.
- RFC defines and closes a substantial architecture proposal.
- ADR explains a durable architecture decision and why it exists.
- Contract or Freeze documents define boundaries production code must obey.
- Audit and certification documents record facts and evidence.
- Migration notes explain compatibility and rollout behavior.
- `Docs/CURRENT_STATUS.md` chronicles major engineering milestones.

Do not create documentation by ritual. Update the smallest authoritative set
that keeps the repository truthful, and do so before implementation when a
decision boundary changes.

## Final Principle

Build for the next five years of evolution, but authorize only the smallest
verified change required now. Apple-native integration should make MemoMark
more trustworthy and less visible, not broaden its feature surface by default.
