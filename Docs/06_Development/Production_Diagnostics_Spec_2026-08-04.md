# MemoMark Production Diagnostics Specification

**Status:** Accepted for bounded implementation
**Date:** 2026-08-04
**Primary loop:** Engineering Loop
**Risk:** P1 — production reliability, failure recovery, privacy, and primary configuration workflow

## Evidence

- Configuration persistence exposes typed validation, recovery, revision, encoding, read, and atomic-write failures, but multiple UI paths collapse them into a generic save failure.
- A canonical configuration save can succeed while its compatibility projection fails; the receipt preserves this fact but the current UI presents a full success.
- Existing share diagnostics retain useful processing evidence in `UserDefaults`, but they are not an actor-owned production event store and there is no user-controlled diagnostic export.
- Renderer region overflow is not a configuration-persistence failure condition. Long content can be compressed or truncated by presentation constraints; only extreme payload pressure can indirectly contribute to resource failures.
- Increased use across devices and OS versions makes verbal reports insufficient for reproducing storage, permission, lifecycle, render, export, and Photos-save failures.

## Ownership And Boundaries

- The durable configuration aggregate remains the only configuration source of truth.
- Diagnostics observe operations and never participate in configuration, rendering, or export decisions.
- Renderer does not validate configuration persistence or own content-fit decisions.
- Content-fit preflight remains future Layout Engine work and must not reject or discard user-authored content during save.
- No automatic remote transport is introduced. Export is initiated explicitly by the user through an Apple-native share surface.

## Privacy Contract

Diagnostic storage and exports must not include:

- photos, thumbnails, or rendered output;
- custom text, subject names, album names, or photo descriptions;
- GPS coordinates or location strings;
- original filenames, raw file paths, or sandbox/container paths;
- unfiltered localized error descriptions or stack traces.

Allowed fields are stable operation and error codes, timestamps and durations, app/build/OS/device family, anonymous operation/job/configuration identifiers, revisions, counts, media dimensions, and per-region character/newline counts.

## Architecture

`Operation -> structured event -> OSLog -> actor-owned bounded file store -> sanitized JSON export -> system share sheet`

The event store uses atomic file replacement, a last-known-good recovery copy, a bounded retention count, and deterministic JSON encoding. If both stored copies are corrupt, the next event resets the bounded diagnostic timeline and records a sanitized storage-recovery event so diagnostic export remains available. If diagnostic persistence itself fails for another reason, the failure is emitted to OSLog without recursively writing another event.

## User Failure Contract

Every newly instrumented terminal failure presents:

1. what operation failed;
2. a concrete, non-technical reason category;
3. a safe recovery action;
4. a short support identifier derived from the operation ID.

Partial success is explicit. When the canonical configuration is durable but compatibility projection fails, the UI says the configuration was saved while subsequent processing may still use the previous configuration, and provides the support identifier.

## Initial Instrumentation Scope

- Configuration candidate construction, album resolution, durable save, compatibility projection, and reconciliation.
- Batch processing terminal failures, including the phase and stable failure classification already owned by the processing pipeline.
- Diagnostic export generation and export failure.
- Existing share diagnostics contribute a sanitized timeline (stage and
  anonymous request/job identifiers). Free-form messages remain excluded,
  except for an explicit allowlist of structured Live Photo recovery/readback
  details that contain no filenames, paths, asset identifiers, or user text.

## Acceptance Criteria

- Distinct configuration validation, stale revision, corruption, encoding, read, write, unavailable-service, and unknown failures map to stable diagnostic codes and useful user messages.
- A failed operation records one terminal structured event with an operation ID matching the displayed support ID.
- Successful configuration saves and compatibility-projection degradation are distinguishable.
- The local store recovers from a corrupted primary file using last-known-good data, self-heals when both copies are corrupt, and retains only the configured maximum event count.
- Wrapped Cocoa and POSIX storage failures preserve safe domain/code metadata so permission and out-of-space failures remain actionable after crossing the persistence boundary.
- Export contains environment metadata and sanitized structured events, and tests prove prohibited sample content is absent.
- Exported Live Photo intake and readback details identify timeout, identity
  ambiguity, missing motion, and PhotoKit recognition failures without
  exposing private media identity.
- Settings exposes `导出诊断信息`; the user can share the generated file using the system share sheet.
- Focused tests and the required unsigned Debug build pass.

## Deferred Work

- MetricKit payload collection and App Store crash-symbol workflow.
- Optional user-consented remote support upload.
- Layout Engine content-fit preflight and visual-overflow warnings.
- Migration or replacement of the existing share-intake diagnostics store.
