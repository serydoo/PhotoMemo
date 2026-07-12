# MemoMark Product Version History

Last updated: 2026-07-11

This document is the canonical source for MemoMark product-stage boundaries.
It distinguishes product stages from App Store versions, audit-report versions,
and legacy implementation identifiers.

## Version Systems

MemoMark uses four different kinds of version labels:

1. **Product stage**: V1, V2, and V3 describe the evolution of the product and
   repository architecture.
2. **App release version**: versions such as `1.5` and `1.6` identify builds
   distributed through TestFlight or App Store Connect.
3. **Audit report version**: names such as `Production Audit v1.0` and
   `Production Audit v2.0` identify revisions of an audit package. They are not
   product-stage declarations.
4. **Implementation identifier**: source symbols and files prefixed with `V1`
   identify the current legacy-compatible iOS implementation layer. They do not
   mean that the current product stage is V1.

These systems must not be treated as interchangeable.

## V1: MVP Foundation And Testing

Period: 2026-06-16 through 2026-06-22.

V1 established and tested the first usable local-first product foundation:

- local EXIF and capture-time reading
- Life Anchor and time-expression foundations
- memory-card rendering and non-destructive export
- metadata-preservation work
- Apple Photos sharing, processing, and save-back foundations
- initial macOS and iPhone product experiments

Representative checkpoints:

- `eae49bf9` — initial project commit on 2026-06-16
- `97bcf327` — `PhotoMemo MVP update` on 2026-06-17
- `4e5a0e2e` — final pre-reset renderer refinement on 2026-06-22

V1 ended when the repository entered the explicit V2 reset and product
redefinition phase.

## V2: Product Definition And Realization

Period: 2026-06-23 through 2026-07-10.

V2 repositioned MemoMark from an MVP memory-card generator into a local-first
Memory Presentation Engine and then carried that definition into the live iOS
product line.

V2 includes:

- Repository V2 Reset and product constitution
- IA-001 interaction architecture
- IA-002 Configuration Center architecture
- PM-003 content and semantic-slot system
- IA-003 Memory Engine integration and expression-platform convergence
- Configuration Center and Memory Card product realization
- iPhone product stabilization and TestFlight preparation
- media, Live Photo, Share Extension, export, and persistence hardening
- Production Audit v1.0 and v2.0

Representative boundaries:

- `fa41a732` — V2 reset, PM-003, and IA-001 documentation on 2026-06-23
- `9430598a` — Production Audit v2.0 reports on 2026-07-10

Documents whose titles contain `V1`, `V2`, IA-series identifiers, or historical
release labels remain valid records of the work performed during V2. They do
not override the current V3 stage.

## V3: Production Quality And Delivery

Start: 2026-07-10 after completion of the Production Audit v2.0 baseline.

Canonical starting checkpoint:

- `9eede616` — `Prepare V3 validation checkpoint for 1.6` on 2026-07-10

V3 focuses on turning the V2 product and architecture into a production-ready,
evidence-backed delivery system:

- canonical configuration aggregate and durable identity
- configuration persistence, local backup, restore, and conflict handling
- complete Apple Photos Share-to-save lifecycle validation
- Live Photo, orientation, location, RAW/ProRAW/DNG, and high-resolution media
  evidence
- performance, memory, concurrency, and resource-release validation
- product-consistency and regression quality gates
- TestFlight and App Store readiness

V3 preserves the product principles and frozen architecture established during
V2. Entering V3 does not reopen IA-002 or discard the Memory Engine,
Configuration Center, or local-first boundaries.

## Naming Policy

- Current project-facing documentation must identify V3 as the active product
  stage.
- Historical documents should remain historically accurate rather than being
  rewritten as if they were created during V3.
- New release-facing documents should use App release versions explicitly,
  such as `MemoMark 1.6`, when discussing TestFlight or App Store builds.
- Audit packages must use the phrase `audit report version` when ambiguity is
  possible.
- Existing `V1*` code symbols, persistence keys, target names, and test names
  remain unchanged until a separately approved engineering migration proves
  that renaming them has sufficient value and no compatibility risk.

## Current Truth

MemoMark is currently in V3 Production Quality And Delivery.

The V1 MVP stage and V2 Product Definition And Realization stage are complete.
V2 documents remain architectural and historical inputs; they are no longer
the active-stage instruction set.
