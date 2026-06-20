# CI Readiness

Last updated: 2026-06-20

## Goal

Evaluate PhotoMemo's readiness for future CI without creating GitHub Actions yet.

## Current Build Commands

Current verified build commands:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemo -configuration Debug -derivedDataPath /tmp/PhotoMemoDerivedData CODE_SIGNING_ALLOWED=NO -quiet build

xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoiOS -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoIOSDerivedData CODE_SIGNING_ALLOWED=NO -quiet build

xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoShareExtension -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/PhotoMemoShareExtensionDerivedData CODE_SIGNING_ALLOWED=NO -quiet build
```

Sprint-009 adds the expectation that `PhotoMemoTests` should also be runnable from `xcodebuild`.

## Required Schemes

Future CI should minimally cover:

- `PhotoMemo`
- `PhotoMemoiOS`
- `PhotoMemoShareExtension`
- `PhotoMemoTests`

## Test Execution Direction

Recommended first CI test command shape:

```bash
xcodebuild -project /Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo.xcodeproj -scheme PhotoMemoTests -configuration Debug -derivedDataPath /tmp/PhotoMemoTestsDerivedData CODE_SIGNING_ALLOWED=NO test
```

If scheme-level test execution is unstable, a fallback is:

- keep build verification on app schemes
- run the test target from the app scheme using `-only-testing`

## DerivedData Handling

Current local pattern is already CI-friendly:

- each build path uses an explicit `-derivedDataPath`
- that reduces cross-target contamination
- it also makes cleanup predictable

Recommended CI rule:

- keep one derived-data folder per scheme or per job

## Current Strengths

- deterministic build commands already exist
- app, iOS app, share extension, and widget extension are already separated into explicit schemes
- the codebase is now beginning to gain pure logic tests, which are the easiest CI starting point

## Current Risks

1. Repository worktree is often intentionally dirty during long-running local product sprints.
2. Photo Library and share-extension behavior are harder to verify in headless CI.
3. Some future iOS/runtime checks will need simulator orchestration rather than plain unit tests.
4. Renderer snapshot and binary-level export diff coverage are still not in place.

## Recommended CI Phases

### Phase 1

- run macOS build
- run iOS build
- run share extension build
- run `PhotoMemoTests`, including fixture-backed export read-back verification

### Phase 2

- add simulator-assisted checks where deterministic
- add renderer snapshot verification once the snapshot surface is defined

### Phase 3

- add longer integration jobs only if they stay stable

## CI Decision

PhotoMemo is not ready for deep end-to-end CI yet, but it is ready for the first CI layer:

- compile verification
- deterministic logic regression tests
- fixture-backed export read-back coverage
