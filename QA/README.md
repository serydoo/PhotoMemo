# MemoMark Device QA Harness

This directory defines the non-destructive contract for MemoMark's future
physical-device automation.

The harness is intentionally prepared before the full QA-01 through QA-08
certification contract. The current UI test target contains host launch,
Configuration Center reachability, exact-album inventory, end-to-end JPEG,
Live Photo, and highest-quality RAW processing checks, plus controlled
post-commit termination/relaunch checks for static and Live Photo outputs. It
still does not claim that the Share Extension, delayed-visibility and
permission-change TX-001 matrix, BP-001 Instruments evidence, or the final
product UI acceptance has passed.

The target has two local build gates before any physical-device run:

```bash
xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkDeviceQA -configuration Debug -sdk iphoneos \
  -derivedDataPath /tmp/MemoMarkDeviceQABuild \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build

xcodebuild -project Source/MemoMark/MemoMark.xcodeproj \
  -scheme MemoMarkDeviceQA -configuration Debug -sdk iphoneos \
  -derivedDataPath /tmp/MemoMarkDeviceQATestBuild \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build-for-testing
```

The first gate proves that the iOS host target and its extensions compile. The
second gate is stronger: it must also produce
`MemoMarkDeviceQA-Runner.app/PlugIns/MemoMarkDeviceQA.xctest`. Both commands
are unsigned structural checks only; neither proves provisioning, installation,
physical-device execution, Photos permissions, PhotoKit readback, or QA-01
through QA-08. The unattended runner still requires the signed `test` path and
the verifier's physical-device, result-bundle, and passed-summary gates.

## Input and output boundary

The eventual device run uses a user-prepared `MemoMark QA Inputs` album and a
dedicated `MemoMark QA Outputs` album. Test inputs are addressed by explicit
`PHAsset.localIdentifier` values or a future manifest entry. The harness must
not scan the personal library, mutate original assets, or delete personal
photos automatically.

The runner also has a read-only inventory test for the exact `MemoMark QA
Inputs` album. It records the album authorization state, asset local
identifiers, media subtype, dimensions, dates, and `PHAssetResource` type,
filename, and UTI. Image classification uses the primary `.photo` resource:
JPEG and HEIC stills are not inferred merely because Photos exposes a JPEG or
HEIC `fullSizePhoto` rendition. A RAW/DNG primary resource with a JPEG
rendition is reported separately as `rawWithJPEGRepresentation`. A Live Photo
is reported as valid only when the asset has the `photoLive` subtype and a
`.pairedVideo` resource.

For QA-05, the product label `48MP` maps to the connected iPhone 17 Pro Max's
highest-quality RAW/ProRAW capture path. The runner therefore requires a
`rawWithJPEGRepresentation` asset with a high-resolution PhotoKit descriptor;
it does not reject that input when the device reports a cropped pixel area such
as `8064x4536` instead of an exact mathematical 48,000,000-pixel rectangle.
The evidence records the RAW dimensions, pixel area, and whether an exact
45,000,000-pixel threshold is also present as separate technical facts. A
RAW asset is still an input source, not a MemoMark output merely because Photos
exposes its JPEG rendition.

If inputs and MemoMark outputs are deliberately placed in the same album, the
inventory remains a mixed-album observation. Album membership alone cannot
prove which asset came from the MemoMark save pipeline. Formal unattended
scenario runs should use separate `MemoMark QA Inputs` and `MemoMark QA
Outputs` albums, or bind each expected output to the save receipt and local
identifier recorded by the run. Inventory JSON is kept in the local
`.xcresult` export only; media bytes are never copied into the repository.

The output inventory preflight is stricter than an album-exists check: it
requires at least one JPEG still or valid Live Photo candidate. An empty output
album, or an album containing only a RAW/DNG primary resource with a Photos
`FullSizeRender.jpeg` rendition, is a data-readiness failure and must not be
reported as a MemoMark output pass. This format gate still does not replace
save-receipt and local-identifier binding for final output provenance.

The production picker route is fixed for unattended QA: open `App 内选择照片`
from MemoMark's main page, select `精选集`, then use the prepared album list
below the system's fixed albums to choose `MemoMark QA Inputs`. The
`MemoMark QA Outputs` album is read back only for result verification and must
not be used as a test-input source.

The current QA-04 readback assertion pairs a valid output Live Photo with an
input Live Photo using normalized still-resource stem and capture date. It
then verifies that the local identifiers differ, the original input remains a
complete Live Photo, the output exposes both a still resource and a paired
video resource, and the capture date is retained. This is safe readback
evidence for a user-confirmed MemoMark output; it is not yet an independent
invocation of the full Apple Photos -> Share -> MemoMark trigger, nor does it
prove exact save-receipt binding, forced-termination recovery, or retry
idempotency.

The current physical-device processing scenarios add those boundaries in a
bounded form. QA-02 selects an independent JPEG still, QA-04 selects a Live
Photo, and QA-05 selects the highest-quality RAW/ProRAW input through the
production picker route; each requires exactly one new output and original
input preservation. QA-07 and QA-08 enable a Debug-only test seam after the
PhotoKit transaction is accepted and before local commit acknowledgement, then
terminate and relaunch the host. After that first recovery, each scenario makes
two additional cold launches and requires the output count to remain unchanged.
These are direct device evidence slices, not a declaration that
the full TX-001 D1-D5 matrix is closed. In particular, they do not replace
delayed-visibility, permission-change, cancellation, or receipt-persistence
failure evidence. The QA-07/08 UI-test termination is recorded separately from
CoreDevice `SIGKILL` orchestration so the evidence remains auditable.

## Result boundary

Each run is expected to produce:

- an `.xcresult` bundle;
- the captured `xcodebuild` log;
- run metadata with device and build identity;
- a best-effort device screenshot;
- future sanitized PhotoKit, receipt, queue, and output readback evidence.

Private media bytes are never copied into the repository. The local
`.xcresult` may contain the bounded PhotoKit descriptors needed to verify the
run (for example, local identifiers, dates, dimensions, resource types,
filenames, and UTIs); these descriptors remain local evidence and are not
promoted to repository fixtures or public release material.

## Planned scenario status

QA-01 through QA-08 remain recorded in `MemoMarkDeviceQA.json` as planned.
The physical-device evidence now covers the bounded processing and controlled
restart slices described above, but the manifest remains `planned` until the
full scenario contract—not only one successful save or one restart—has been
closed, including TX-001 D3/D5 and related failure boundaries, BP-001, Share
Extension acceptance, and the production processing contract.

## Running the harness

After the test target is available to Xcode, the Mac runner can be invoked
without touching the personal Photos library:

```bash
scripts/memomark-device-qa.sh validate --device iPhone7
scripts/memomark-device-qa.sh build-check --derived-data /tmp/MemoMarkDeviceQABuild
scripts/memomark-device-qa.sh readiness --device iPhone7 \
  --results /tmp/MemoMarkDeviceQA \
  --derived-data /tmp/MemoMarkDeviceQABuild
scripts/memomark-device-qa.sh preflight --device iPhone7
scripts/memomark-device-qa.sh signing-status --json
python3 -m unittest discover -s scripts/tests -p 'test_*.py'
scripts/memomark-device-qa.sh run --device iPhone7
scripts/memomark-device-qa.sh run --device iPhone7 --allow-provisioning-updates
scripts/memomark-device-qa.sh verify --run-dir /tmp/MemoMarkDeviceQA/<run-id>
scripts/memomark-device-qa.sh verify-readiness --run-dir /tmp/MemoMarkDeviceQA/<run-id>
scripts/memomark-device-qa.sh processes --device iPhone7
scripts/memomark-device-qa.sh memory-warning --device iPhone7
scripts/memomark-device-qa.sh terminate --device iPhone7
```

`validate` checks the committed QA manifest before any device interaction.
`build-check` runs an unsigned iPhoneOS `build-for-testing` in an isolated
DerivedData directory and verifies the resulting host App, `.xctrunner`, and
embedded `.xctest` Bundle IDs against the manifest. It is a local structural
gate: it does not contact CoreDevice, use an Apple account, alter the keychain,
install an app, access Photos, or count as physical-device evidence.
On success it also writes `build-check.json` beside the DerivedData products;
the readiness runner copies that receipt into its run directory and binds the
host product (`qaHostProduct`), runner, and test-bundle Bundle IDs back to the
QA manifest during offline replay. The receipt also records the originating
`runID`; `verify-readiness` requires it to match the readiness report, so a
receipt left over from another run cannot be reused as structural evidence.
`readiness` is the unattended preflight command. It writes one
`readiness.json` report containing four independent gates: manifest, unsigned
structural build, read-only signing, and physical-device preflight. It runs
them in that order and only contacts CoreDevice when the first three gates are
ready. A missing provisioning profile therefore produces a non-zero
`overallResult: "blocked"` report with `physicalDevice.result: "skipped"` and
`reason: "signing-blocked"`; it is not misreported as a device failure or a QA
pass. The report contains only build/device identifiers and gate state; the
verbose build and preflight output remains in the same local run directory.
For safety, both `readiness` and the default `run` refuse to reuse a directory
containing any prior readiness report, diagnostic, device evidence, or other
artifact; an explicit `--run-id` must identify a fresh directory, and the
runner never deletes stale files to make reuse possible.
`readiness` is a readiness artifact, not a completed physical QA run, so it is
not passed to the regular `verify --run-dir` command.
`verify-readiness --run-dir` replays the complete readiness directory offline.
It enforces the top-level artifact allowlist, binds the copied manifest to the
report's scheme and target, recomputes the overall result from the four gate
states, and rejects altered gate names, identities, symlinks, private-media
files, physical-device evidence, or overall status. It does not invoke Xcode,
CoreDevice, signing tools, or Photos. It prints a structurally valid blocked
report but returns exit status 1 for `overallResult: "blocked"` or
`"failed"`; only a verified `"ready"` report returns 0. Malformed or
inconsistent evidence returns exit status 2.
The manifest is also the source of truth for the QA UI test target and runner
Bundle ID; early signing evidence must match both values during offline
verification. Older schema v1 artifacts created before these fields existed
remain replayable as legacy-unbound evidence, while new artifacts are bound to
the manifest identities. The verifier also requires the diagnostic's scheme to
match `defaultScheme` and its project path to resolve to the current
`Source/MemoMark/MemoMark.xcodeproj`, preventing a valid-looking diagnostic
from another scheme or checkout from being reused as MemoMark evidence.
`verify` rechecks an existing run directory offline. It only reads the copied
manifest, run metadata, test summary, xcodebuild log, and result-bundle
structure; it does not contact CoreDevice, invoke xcodebuild, or write to the
run directory. A blocked or failed run returns a non-zero exit status, even
when the classification is useful for automation.
If an optional JSON evidence file exists, it must contain valid JSON; the
verifier distinguishes a genuinely absent artifact from a present but
corrupted artifact and rejects the latter.
The `--write-metadata` path is limited to a validated regular run and updates
only its existing regular `run-metadata.json` through an atomic replacement.
Early signing artifacts remain read-only and are never upgraded with regular
metadata; symlinked write targets are rejected before replacement.
For regular physical runs, the verifier binds `run-metadata.scheme` to the
manifest's `defaultScheme`, binds a present `run-metadata.target` to
`qaTarget`, and compares `run-metadata.deviceIdentifier` with
`device-details.result.identifier` when both are present. A foreign scheme,
present target, or device identifier is rejected. Metadata created before
target recording remains replayable as legacy-unbound target evidence; new
runs record the target explicitly.
Regular-run shape is checked before JSON parsing: the run directory and the
required manifest and metadata files must be real filesystem objects, and
known optional evidence files may not be symlinks or directory-shaped
replacements. If an `.xcresult` bundle is present, it must be a directory with
a regular `Info.plist`. Unknown future artifacts are not silently interpreted
as identity evidence: an undeclared top-level file or directory is rejected.
The regular metadata `project` field must also remain `MemoMark`, while the
current runner's known logs, screenshot, and process evidence remain
supported.
Regular metadata generated by the current runner must use schema version 1
and include non-empty `runID`, device, device identifier, scheme,
configuration, and project fields. A legacy regular artifact may omit only the
later-added `target` field; it is replayed as legacy-unbound target evidence.
The summary result may be `Passed`, `Failed`, or lowercase `unknown`; the last
form represents an interrupted or signing-blocked run with no completed test
count and cannot produce a QA pass. Summary counts must still be non-negative
integers. Device evidence, when present, must identify a physical device and
carry a CoreDevice identifier.
The stored `xcodebuildExitStatus` is required to be a strict integer when a
run is replayed without an override; boolean JSON values are rejected even
though Python represents them as integers.
The current shell runner emits all regular metadata fields required by this
schema, including schema version, run/device identity, scheme, configuration,
target, and the `MemoMark` project marker; the Swift runner contract tests
guard this generator/verifier alignment.
Regular physical runs may also retain the read-only `signing-status.json`
diagnostic generated before the test starts; it is an allowed optional artifact
alongside the run logs and result bundle.
An early signing-blocked run is also verifiable with only the copied manifest
and `signing-status.json`. The verifier requires the diagnostic to be
read-only, blocked, and one of the known signing failure classes, and rejects
the artifact if any device or xcodebuild evidence is present. Its top-level
allowlist contains only `MemoMarkDeviceQA.json` and `signing-status.json`; an
unexpected file or directory is rejected so private media, stale logs, and
undeclared evidence cannot ride along in an unattended artifact. Both allowed
entries must be regular files located directly in the run directory; symlinks
and directory-shaped replacements are rejected before JSON parsing. The run
directory path itself must also be a real directory rather than a symlink
alias.
`run` now requires all three pieces of evidence: a zero exit status from
`xcodebuild`, a present `.xcresult` bundle, and a `Passed` test summary with
zero failures and at least one executed test. A missing or incomplete result
bundle makes the run fail even if `xcodebuild` itself exits successfully. The
run metadata also distinguishes `result: "blocked"` with
`failureClass: "signing-blocked"` from an actual test or runner failure. The
blocked classification is still a non-zero process exit and can never be
treated as a QA pass.

`signing-status` is a read-only local diagnostic. It reports the QA runner
target and derived runner bundle identifier, Xcode signing mode/team, available
Apple Development identities, and matching provisioning profiles. A missing
local profile is
reported as `provisioning-profile-missing` with a recommendation to allow
Xcode provisioning updates; the command never logs in, creates a profile,
changes the keychain, or changes the project. A profile counts as matching
only when both its explicit application identifier and its team-identifier
entitlement match the selected scheme's `DEVELOPMENT_TEAM`; another team's
profile with the same bundle suffix cannot produce a false-ready result. The
diagnostic reads the target's own build settings, rather than the host app's
settings, and derives the runner identifier from that target's
`PRODUCT_BUNDLE_IDENTIFIER` unless an explicit override is supplied. The
offline `unittest` command covers this matching rule without reading a device,
account, keychain, or personal photo library.

The default output root is `/tmp/MemoMarkDeviceQA`. Use `--results` to select a
different local results directory. The runner requires a paired, unlocked
physical device and an existing signing configuration. Preflight also checks
the CoreDevice hardware `reality` field and rejects simulator targets before
testing. It does not uninstall the app, erase the device, reset Photos
permissions, or clear the App Group container. A device name is resolved to
its current CoreDevice UDID before invoking `xcodebuild`, so the human-readable
default (`iPhone7`) remains usable in unattended runs.

`--allow-provisioning-updates` is opt-in. It lets Xcode use the configured Apple
developer account to create or refresh the development profile for the QA
runner bundle. Without an Xcode account, the runner stops at the signing
boundary and records the missing-profile evidence; it does not silently fall
back to an unsigned or simulator run.

For the default `run` command, the read-only signing diagnostic runs before
physical-device preflight. A known missing-profile condition therefore exits
without contacting CoreDevice. When `--allow-provisioning-updates` is supplied,
this early read-only gate is skipped intentionally so Xcode can attempt the
explicitly authorized provisioning update during the real test command; the
physical-device and result-evidence gates remain active.
For the default path, the JSON diagnostic is also retained as
`signing-status.json` inside the run directory, so an early blocked run keeps a
machine-readable reason even though no device artifact exists.

The process commands discover the main `MemoMarkiOS` process by its executable
path when `--pid` is omitted. They are intended for later BP-001 and TX-001
orchestration. `terminate` is an explicit test action and is never called by
`preflight` or by an ordinary smoke run.
