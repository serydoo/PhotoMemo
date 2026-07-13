# Production Configuration Identity And Render Health Contract

Date: 2026-07-13

Status: Implemented and dual-device signed validation complete

Primary engineering loop source: dual-device production evidence

## Objective

Make every MemoMark production entry point consume one explicitly identified,
durable configuration revision and prove that every enabled configuration item
reaches the real renderer input. Eliminate ambient-current-configuration guesses
and prevent a file lifecycle success from hiding missing smart-module meaning.

## Architecture Decision

```text
Production entry point
-> ProductionConfigurationReference(configurationID, revision, contractVersion)
-> exact durable ConfigurationLibraryRecord lookup
-> BatchConfigurationSnapshot projection
-> canonical ConfigurationSnapshot freeze
-> structural Contract validation
-> queue admission
-> RecordCardBuildService with real photo facts
-> semantic Render Health Check
-> CardTextBlockEngine -> Renderer -> Export
```

The Renderer remains a consumer. This change does not move configuration,
Memory Engine, or layout decisions into renderer implementations.

## Configuration Identity Semantics

- Configuration UUID is identity; title is display data.
- `保存为当前配置`, output changes, and rename update the same selected
  configuration UUID.
- A successful save increments `MemoryConfigurationRecord.revision`.
- `ConfigurationLibraryRecord.revision` remains the aggregate storage revision
  and must not be substituted for configuration revision.
- A new UUID is created only by an explicit new/copy/import-as-copy action.
- Production references use configuration revision, not aggregate revision.

## Durable Resolution Semantics

- Resolve by configuration UUID across subject-owned durable records.
- Store the durable aggregate under one stable App Group-backed root across
  launches; test-only random directories must never be used by
  `AppEnvironment.live` in production.
- Require the stored `MemoryConfigurationRecord.revision` to equal the request.
- Freeze subject, selected Time Anchor, Memory behavior, editor Template,
  presentation, location, logo, description, album, media mode, and Live Photo
  policy from that same durable record.
- Switching the active configuration after request creation cannot change the
  resolved request.
- If the referenced revision is no longer available, reject the new request.
  Do not combine the request template with another current subject/snapshot.

Version-history storage is not invented in this slice. A request for a no-longer
available revision fails explicitly. A later revision-history RFC may make old
revisions replayable without weakening this Contract.

## Contract Version And Compatibility

- Add an optional production contract version to the transport snapshot.
- Newly saved/published configurations use contract version `1`.
- Version `1` requires complete identity and exact durable resolution.
- Existing persisted requests with no version are historical compatibility
  requests. They may use the current controlled restoration behavior and must
  emit a compatibility-recovery diagnostic.
- New code must never create an unversioned production request after a durable
  configuration is available.

## Structural Snapshot Invariants

Before queue admission, contract version `1` requires:

- non-nil configuration UUID;
- positive configuration revision;
- canonical `ConfigurationSnapshot` present;
- top-level and canonical IDs/revisions equal;
- Memory Subject present and owned by the durable subject record;
- selected Primary Anchor present when enabled smart variables require it;
- projected Template and output settings come from the same durable record.

## Semantic Render Health Check

After importing a real photo and building `RecordCard`:

1. inspect enabled Template items for smart variables;
2. when `{{memory_summary}}` is enabled, require a non-empty resolved
   `memory_summary` value;
3. run `CardTextBlockEngine` and require the containing area to emit non-empty
   final text;
4. on failure, stop before export and record a typed diagnostic with
   configuration ID/revision, launch source, request/job/task identity where
   available, and the missing semantic token;
5. never log private photo content or the user's rendered sentence.

## Diagnostics

Add machine-readable stages for:

- configuration reference accepted;
- historical compatibility recovery;
- durable configuration not found;
- configuration revision mismatch;
- canonical Snapshot mismatch;
- queue admission rejected;
- render semantic Health Check passed/failed.

Messages include identifiers and reason codes, not private image or expression
content.

## Test Strategy

### Identity and save tests

- save-current preserves UUID and increments configuration revision;
- rename preserves UUID and increments configuration revision;
- output-only edit preserves UUID and increments configuration revision;
- receipt exposes both aggregate revision and configuration revision.

### Resolution and admission tests

- request A remains bound to A after active selection switches to B;
- matching ID/revision produces a canonical snapshot with matching identity;
- missing ID, missing revision, unknown ID, and mismatched revision fail;
- all `BatchJobLaunchSource` values use the same validator;
- unversioned historical transport uses only controlled recovery.

### Final user-result tests

- build a real card from the enqueued configuration;
- assert `memory_summary` is non-empty;
- assert `CardTextBlockEngine` emits the expected smart text;
- assert configured template, location, logo, output, album, and description
  survive projection into the production snapshot;
- enabled `memory_summary` with invalid Subject/Anchor or empty resolution
  produces a Health Check failure before export.

## Commands

Focused tests should run through the existing `PhotoMemoTests` scheme. The
required final build commands are:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

The existing unrelated macOS `.pickerStyle(.wheel)` availability failure is
recorded separately and does not weaken iOS verification.

## Boundaries

Always:

- preserve local-first behavior and original photos;
- derive production state from `ConfigurationLibraryRecord`;
- keep Renderer and Export as consumers;
- return typed failures and diagnostics for Contract violations;
- preserve unrelated user worktree changes.

Do not:

- use title/name as configuration identity;
- use aggregate revision as configuration revision;
- silently select the current active configuration for a versioned request;
- accept file existence as proof of configured semantic output;
- modify Live Photo filename policy in this slice;
- create speculative revision-history infrastructure without a separate RFC.

## Success Criteria

- Every new production request has contract version, configuration UUID, and
  configuration revision.
- The same durable configuration ID/revision resolves after process restart.
- Every admitted job contains a matching complete canonical snapshot.
- Save, rename, and output edits preserve configuration UUID.
- A changed active configuration cannot alter a pending request.
- Revision mismatches fail visibly and diagnostically.
- Enabled smart-module content is proven at the real renderer-input boundary.
- Focused tests and both iOS builds pass before signed-device testing begins.

## Closure Evidence

- iPhone 15 Pro final 20-photo evidence:
  `/tmp/PhotoMemoRuntimeEvidence/iphone5-production-contract-share20-20260713-113938`
- iPhone 17 Pro Max final 20-photo evidence:
  `/tmp/PhotoMemoRuntimeEvidence/iphone17promax-production-contract-share20-20260713-114037`
- both devices completed and saved `20/20` tasks with `7` Live Photos and `13`
  static images;
- every final task passed the semantic Render Health Check with its exact
  configuration ID and revision `1`;
- user inspection confirmed smart text, geometry/orientation, Live Photo
  playback, and final saved output;
- generic `PhotoMemoiOS` and `PhotoMemoShareExtension` iOS builds passed after
  device closure;
- the shared date editor now isolates the iOS wheel picker from the macOS test
  host without changing iPhone behavior;
- the final configuration lifecycle regression passed `110/110` tests;
- the combined production configuration, filename, and responsive contract
  group passed `30/30` tests.

True RAW/DNG provider intake is not claimed because Apple Photos supplied
high-resolution JPEG proxies. Live Photo output naming remains outside this
Contract and is closed independently by Reliability entry RE-003.
