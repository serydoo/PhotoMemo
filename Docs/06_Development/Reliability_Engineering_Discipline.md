# MemoMark Reliability Engineering Discipline

Status: Active V3 Engineering Loop discipline

Date: 2026-07-14

## Purpose

MemoMark reliability work converts observed failures into durable rules. A bug
is not closed when one code path starts working again. It is closed when the
repository can point to:

1. the observed fact and evidence;
2. the violated Contract or Invariant;
3. the code boundary that now prevents recurrence;
4. an automated regression entry;
5. the required runtime or signed-device evidence.

This document is intentionally the first and only Reliability record container.
Create a separate record only when a real defect has enough evidence to justify
one. Do not pre-create empty category files.

## V3 Production Readiness Engineering Loop

Production Readiness is an Engineering Loop inside `V3 Production Quality And
Delivery`. It is not a new product stage and does not replace the V1/V2/V3
product-version history.

The governing principle is:

> Production readiness is demonstrated by evidence, not confidence.

In Chinese:

> 生产级不是靠信心证明，而是靠证据证明。

The reusable system loop is:

```text
System
-> Boundary Audit
-> Reliability Audit
-> Apple Native Audit
-> Production Certification
-> Freeze
```

This loop may be reused by future product stages. Its purpose is to raise an
accepted system to production quality, not to expand its feature surface.

### Audit Order

The current V3 production-readiness order is:

1. Share Workflow;
2. Batch Queue System;
3. Media Pipeline;
4. Export System;
5. Diagnostics.

The order follows production dependency and risk. Share admits work; Queue
persists and coordinates it; Media Pipeline interprets source capability;
Export creates and saves the new artifact; Diagnostics proves what happened.

Renderer is not a separate audit target in this sequence. It remains a frozen
consumer boundary unless evidence identifies a renderer-owned defect.

## Fixed Audit Questions

### Boundary Audit

Ask whether the system owns only its accepted responsibility.

Examples:

- Share must not become a second Configuration Center, queue, or renderer.
- Queue and Worker must not own UI or Memory semantics.
- Renderer must not own media geometry, domain resolution, or persistence.
- Export must not reconstruct configuration or silently repair upstream truth.

Every finding must identify the owning boundary and the direction of the
violation. Code elegance alone is not a production boundary finding.

### Reliability Audit

Every system must answer four fixed failure questions:

| Failure class | Required question |
|---|---|
| **Loss** | Can accepted user work, media identity, configuration, metadata, or output disappear? |
| **Duplicate** | Can one accepted input produce unintended duplicate jobs, processing, saves, or history? |
| **Recovery** | Can interruption, restart, corruption, or handoff failure leave work unrecoverable or ownership ambiguous? |
| **Silent Wrong Output** | Can the system report success while producing semantically, visually, or structurally incorrect output? |

Silent Wrong Output is a production failure even when the file renders, saves,
and the queue reaches a terminal success state. RE-001 is the canonical
example: Share completed while enabled Memory content was empty.

Each reliability conclusion must define how the system rejects, recovers, or
diagnoses the failure. “The happy path passed” is not sufficient.

### Apple Native Audit

Ask whether implementation and evidence respect the actual Apple lifecycle and
platform contracts relevant to the system, including:

- Share Extension lifecycle and resource limits;
- App Group entitlement and persistence boundaries;
- background execution and process termination;
- PhotoKit asset identity, authorization, save, and readback;
- Live Photo pairing, playback, and resource semantics;
- notification, Live Activity, and foreground handoff behavior where used.

Host tests and simulator builds cannot close behavior owned by signed-device
Apple frameworks.

### Production Certification

Ask whether the conclusion has real evidence rather than architectural
confidence.

Each capability should use an evidence matrix:

| Capability | Code | Automated Test | Signed Device | Runtime Evidence | Status |
|---|---|---|---|---|---|
| Example capability | present / absent | pass / missing | pass / missing / not applicable | complete / partial / missing | `PASS`, `PARTIAL`, `REVIEW`, or `FAIL` |

An evidence column must not be inferred from another column. Code does not
prove device behavior. A device screenshot does not prove persistence or
recovery. Runtime events do not prove the final user-visible output unless the
acceptance gate observes that output.

Certification verdicts are:

#### `PASS`

- Boundary Audit passes;
- Reliability Audit passes all four fixed failure classes;
- Apple Native Audit passes for every claimed platform capability;
- no Level A finding remains open;
- no unexplained Silent Wrong Output remains;
- required evidence matrix cells are complete.

#### `CONDITIONAL PASS`

- no Level A finding remains open;
- the supported production claim is safe and explicit;
- only bounded Level B findings or evidence limitations remain;
- every limitation has an owner, evidence requirement, and release-facing
  consequence;
- no unexplained Silent Wrong Output remains.

#### `FAIL`

- any Level A finding remains open;
- an unexplained Silent Wrong Output exists;
- a required Apple lifecycle claim lacks decisive evidence;
- the system can silently lose, duplicate, misconfigure, or strand accepted
  work.

### Freeze

Certification does not make a system untouchable. It freezes the certified
boundary and evidence baseline.

After freeze:

- changes require a scoped production or architecture reason;
- affected certification evidence must be identified before implementation;
- capability expansion must not silently widen the certified claim;
- regression or device gates invalidated by the change must be rerun;
- a new failure may reopen only its owning boundary unless evidence proves a
  broader contract is wrong.

## Finding Priority

All production-readiness findings use three levels:

### Level A — Production Blocker

Must be fixed or explicitly removed from the supported production claim before
certification.

Examples include:

- possible data or accepted-task loss;
- unintended duplicate processing or save-back;
- unrecoverable or unobservable ownership failure;
- Silent Wrong Output;
- privacy, original-photo mutation, or Local First violation;
- false success reported across a required Apple lifecycle.

### Level B — Reliability Improvement

Should be fixed or bounded with explicit evidence and release consequences.

Examples include incomplete recovery coverage, weak diagnostics, lifecycle
hardening, bounded performance risk, or missing non-critical evidence where the
supported claim remains safe and accurate.

### Level C — Architecture Improvement

May be deferred when it does not threaten correctness, recovery, Apple
lifecycle behavior, or supported production claims.

Examples include cleaner decomposition, naming, reduced complexity, and more
elegant internal structure. Level C work must not displace Level A or Level B
closure merely because it improves code aesthetics.

## Governing Principle

> Every bug fix must make the system less able to produce the same class of bug.

Reliability is designed by reducing ambiguous state and invalid transitions.
Tests, assertions, diagnostics, and device evidence prove that the design is
working; they do not replace the design.

## Required Record Shape

Every reliability entry must contain:

- **Observed Fact**: exact user-visible failure and affected production route.
- **Evidence**: test fixture, diagnostic event, runtime evidence directory, or
  reproducible signed-device steps. Never commit private photos.
- **Root Cause**: the first ownership boundary that violated a frozen rule.
- **Contract**: the rule production code must obey.
- **Invariants**: executable preconditions and postconditions.
- **Failure Policy**: whether work is rejected, recovered, or allowed to
  continue, including the diagnostic event.
- **Regression Entry**: focused automated test plus the final user-result test.
- **Runtime Gate**: build, export read-back, or signed-device scenario required
  before closure.
- **Follow-up Boundary**: adjacent issues explicitly excluded from the fix.

## Enforcement Levels

1. **Model validation** rejects structurally invalid durable data.
2. **Boundary validation** rejects identity, revision, or ownership mismatch
   before a job enters the queue.
3. **Semantic Health Check** verifies enabled production meaning resolves to a
   non-empty renderer input after real photo facts are available.
4. **Diagnostics** records privacy-safe, machine-readable failure evidence.
5. **Regression tests** cover the narrow defect and the final rendered result.
6. **Signed-device evidence** closes Apple Photos lifecycle behavior that host
   tests cannot prove.

Assertions may additionally expose programmer errors in Debug builds, but a
production Contract must also return a typed failure and diagnostic event.

## Entry RE-001: Production Configuration Identity And Smart Output

### Observed Fact

On both an iPhone 15 Pro and iPhone 17 Pro Max, Configuration Preview displayed
`{{memory_summary}}` correctly while real Apple Photos Share output left the
smart module empty. Import, render, save, and queue completion still appeared
successful.

### Evidence

- Failing evidence:
  `/tmp/PhotoMemoRuntimeEvidence/iphone5-jpeg-reconfigured-20260713-074716`
- Failing evidence:
  `/tmp/PhotoMemoRuntimeEvidence/iphone17promax-memory-empty-20260713-075348`
- Emergency-fix pass:
  `/tmp/PhotoMemoRuntimeEvidence/iphone5-smart-module-fixed-pass-20260713-082345`
- Emergency-fix pass:
  `/tmp/PhotoMemoRuntimeEvidence/iphone17promax-smart-module-fixed-pass-20260713-082345`
- Final production-Contract pass, iPhone 15 Pro:
  `/tmp/PhotoMemoRuntimeEvidence/iphone5-production-contract-share20-20260713-113938`
- Final production-Contract pass, iPhone 17 Pro Max:
  `/tmp/PhotoMemoRuntimeEvidence/iphone17promax-production-contract-share20-20260713-114037`

### Root Cause

The production intake transport preserved template-shaped data but lost durable
configuration identity and the canonical Memory `ConfigurationSnapshot`. The
main app guessed from ambient current settings and could enqueue a semantically
incomplete configuration. Existing evidence gates verified file lifecycle, not
enabled smart-module meaning.

### Contract

```text
Production request from any source
-> configurationID + configuration revision
-> exact durable configuration resolution
-> complete canonical Production Snapshot freeze
-> Snapshot Contract validation
-> queue admission
-> real RecordCard build
-> semantic Renderer-input Health Check
-> Renderer -> Export
```

`shareExtension`, `fileOpen`, `quickAction`, `automation`, and `inAppPreview`
must converge on the same admission and semantic-output rules.

### Invariants

1. A new production request carries a non-nil `configurationID` and positive
   configuration revision.
2. Save-current, output edits, and rename preserve the same configuration UUID
   unless the user explicitly creates a copy or switches configuration.
3. Save-current increments that configuration's revision and publishes the
   same ID/revision to all production entry points.
4. The enqueued `BatchConfigurationSnapshot` contains a canonical
   `ConfigurationSnapshot` whose ID/revision exactly match the request.
5. The durable subject owns the selected configuration and selected Time
   Anchor used to freeze the snapshot.
6. If an enabled Template item references `{{memory_summary}}`, the production
   card has a valid Memory Subject, Primary Anchor, non-empty resolved memory
   value, and non-empty `CardTextBlockEngine` output.
7. Renderer and Export consume the validated card and do not reconstruct
   configuration identity or semantic text.

### Failure Policy

- New contract-version requests never silently fall back to the active or
  current configuration.
- Missing ID, missing revision, missing durable record, revision mismatch,
  Snapshot mismatch, and empty enabled smart output are Contract violations.
- A Contract violation prevents queue admission or production export and emits
  a machine-readable diagnostic event with request/job identity.
- Historical requests without a contract version may use the documented
  compatibility recovery path. Recovery must be explicit in diagnostics and
  must never be used for new requests.

### Regression Entry

Required automated proof:

- save and rename preserve configuration UUID while revision advances;
- switching configuration after request creation does not change request
  identity;
- ID present with revision mismatch is rejected;
- exact durable configuration freezes a complete canonical snapshot;
- a real `RecordCardBuildService` build resolves `memory_summary` non-empty;
- `CardTextBlockEngine` emits the final smart text;
- enabled smart output resolving empty records a Health Check failure;
- every production launch source passes through the same admission validator.

### Runtime Gate

- focused contract and renderer-output tests pass;
- generic iOS app and Share Extension builds pass;
- the same signed build is installed on both designated devices;
- JPEG, Live Photo, and mixed Share runs retain configured output and non-empty
  smart-module content;
- diagnostics prove the enqueued ID/revision and frozen Snapshot agree;
- no generated file is accepted as a pass solely because it exists and saved.

Runtime gate result: passed on both designated devices using the same signed
build. Each final mixed request completed and saved `20/20` outputs, routed
`7` Live Photos and `13` static images, and produced `20/20` semantic Health
Check passes with the exact durable configuration ID/revision. User inspection
confirmed smart text, layout/orientation, Live Photo playback, and saved output.
The iPhone 15 Pro completed in `50.204s`; the iPhone 17 Pro Max completed in
`32.880s`. No new crash or Contract violation was observed.

### Follow-up Boundary

The Live Photo `FullSizeRender` filename defect is owned and closed separately
by RE-003. It is not part of RE-001.

## Entry RE-002: iPhone Viewport Containment And Adaptive UI

### Observed Fact

The same Home UI looked complete on an iPhone 17 Pro Max but lost the visible
left and right card corners on an iPhone 15 Pro. The affected values were not
different corner-radius tokens. A child row had a larger intrinsic width than
the compact viewport and enlarged the vertical `ScrollView` content beyond the
visible screen.

### Evidence

- user-provided comparison screenshots remain local and are not committed;
- 375 pt containment evidence:
  `/tmp/PhotoMemoResponsiveLayoutQA/iphone-se3-375-home.png`;
- 393 pt containment evidence:
  `/tmp/PhotoMemoResponsiveLayoutQA/iphone15pro-393-home-final4.png`;
- 440 pt containment evidence:
  `/tmp/PhotoMemoResponsiveLayoutQA/iphone17promax-440-home-final.png`;
- implementation Contract:
  `Docs/superpowers/specs/2026-07-13-iphone-responsive-layout-contract.md`.

### Root Cause

Several vertical page roots padded flexible child content but did not bind the
scroll content back to the actual viewport. SwiftUI therefore accepted the
widest intrinsic child as the page width. Fixed horizontal groups, including
the Home subject card and user-controlled identity/configuration values, could
move the outer card bounds outside a 375 or 393 pt screen.

### Contract

```text
iPhone safe viewport
-> viewport-bound vertical content
-> shared readable-width cap
-> adaptive horizontal group
-> visible card chrome and operable controls
```

Native `List` and `Form` keep their own width ownership. Other vertical page
roots use `v1AdaptiveScrollContent`; fixed non-scrolling surfaces use
`v1AdaptivePageContent`. No device-name or physical-screen branching is
allowed.

### Invariants

1. A vertical scroll child cannot make its page wider than the current
   container.
2. Top-level card corners, strokes, and shadows remain inside the safe visible
   width at 375, 390/393, 402, and 430/440 pt portrait classes.
3. A multi-control horizontal group uses compression, truncation, or a
   `ViewThatFits` compact fallback before it can enlarge the page.
4. User-controlled configuration names, object names, and backup actions do
   not own page width.
5. Short screens and larger content sizes can scroll to every required action.
6. UI adaptation cannot change Configuration, Renderer, Export, Share, or
   media-pipeline semantics.

### Failure Policy

Responsive failures are release-blocking when a required control is clipped,
an outer card boundary leaves the viewport, or content becomes unreachable.
The fix must occur at the owning page or adaptive group. Renderer output and
device-specific constants must not compensate for an application UI failure.

### Regression Entry

`IPhoneResponsiveLayoutContractTests.swift` verifies the shared viewport
modifier, production page adoption, compact Home behavior, responsive local
backup actions, user-controlled identity width safety, and the prohibition on
`UIScreen.main.bounds` or device-model branching.

### Runtime Gate

- `PhotoMemoiOS` generic iOS Simulator build passes;
- `PhotoMemoShareExtension` generic iOS Simulator build passes;
- signed `1.7 (7)` build is installed and launched on the designated iPhone
  15 Pro and iPhone 17 Pro Max;
- 375, 393, and 440 pt Home evidence shows complete outer card bounds;
- final page-by-page dual-device acceptance remains required for Home,
  Configuration Center, Output, Task, Settings, object sheets, and local
  configuration actions.

### Follow-up Boundary

The known macOS-only wheel-picker availability error is recorded separately
and does not affect either iOS target. iPad-specific redesign is outside this
entry; shared readable-width behavior is preserved without claiming an iPad
interaction review.

## Entry RE-003: Live Photo Output Filename Identity And Sequence

### Observed Fact

Repeated Live Photo outputs on both designated devices rendered and saved
correctly but exposed PhotoKit adjustment-resource names such as
`FullSizeRender.jpeg` and `FullSizeRender.mov`. Multiple outputs retained the
same base instead of following MemoMark's source-derived parenthesized sequence.

### Evidence

- deterministic failing device evidence:
  `/tmp/PhotoMemoRuntimeEvidence/iphone17promax-livephoto-filename-repeat-20260713-083532`;
- the same failure was confirmed independently on the iPhone 15 Pro;
- subsequent signed-device single and mixed runs confirmed source-derived
  numbered names on both the iPhone 15 Pro and iPhone 17 Pro Max;
- focused filename and Live Photo test result: `31/31` passed.

### Root Cause

`LivePhotoBatchTaskProcessor` forwarded the prepared PhotoKit resource names
directly into `LivePhotoSaveRequest`. For adjusted Live Photos, those names are
implementation details rather than source identity. The still and paired-video
resources therefore bypassed the normal output naming rule and collision
sequence.

### Contract

```text
source task filename
-> reject PhotoKit internal FullSizeRender identity
-> resolve canonical source root
-> allocate durable parenthesized sequence
-> still and paired video receive the same base
-> writer verifies base-name equality
-> PhotoKit save
```

### Invariants

1. `FullSizeRender` may identify an imported PhotoKit resource but can never be
   the preferred production output base when source identity is available.
2. The still image and paired video always share one case-insensitive output
   base and differ only by extension.
3. Repeated outputs use `source(1)`, `source(2)`, `source(3)` without nested
   suffixes or spaces.
4. The sequence is durable across process restart and serialized on the main
   actor.
5. Corrupt sequence state fails explicitly and does not silently reuse an
   earlier name.
6. Filename resolution failure or pair-base mismatch prevents PhotoKit save and
   emits a diagnostic event.

### Failure Policy

Production must not fall back to an internal PhotoKit resource name after the
source name has been resolved. A missing source may use the stable capture-time
fallback. Sequence read/write corruption and pair-base mismatch are typed
failures; no output is saved under an ambiguous name.

### Regression Entry

- `PhotoFileNameResolverTests` covers internal-name detection, stable roots,
  durable sequence allocation, restart, nested-suffix prevention, and corrupt
  sequence rejection;
- `LivePhotoBatchQueueExecutionTests` covers adjusted `FullSizeRender`
  resources and verifies the real processor emits matching numbered still and
  movie names;
- `LivePhotoAssetWriterContractTests` rejects mismatched pair bases before
  PhotoKit;
- `LivePhotoAssetLoaderContractTests` preserves real resource extensions while
  keeping resource identity separate from output identity.

### Runtime Gate

- focused filename and Live Photo suites pass `31/31`;
- `PhotoMemoiOS` and `PhotoMemoShareExtension` builds must pass;
- the same signed build is distributed to all designated devices;
- final device acceptance verifies single and repeated Live Photo output names,
  playback, smart text, and paired-resource completeness.

### Follow-up Boundary

Apple Photos may still provide high-resolution JPEG proxies for RAW-library
selections. That provider behavior is separate from Live Photo output naming
and must not weaken this Contract.

## Adding The Next Entry

Add the next numbered entry to this document while the Reliability system is
small. Split entries into a `Reliability/` index and individual files only when
real records become difficult to navigate. Any split must preserve stable entry
IDs and links to code, tests, diagnostics, and runtime evidence.
