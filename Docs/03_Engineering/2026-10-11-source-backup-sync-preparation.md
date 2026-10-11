# MemoMark 2.3.6 (124) source-backup checkpoint preparation — 2026-10-11

**State: Source backup checkpoint; release evidence remains open.** This is an
internal GitHub source backup checkpoint for the existing
2.3.6 (124) source, not a new binary or an App Store/TestFlight release. The
app version and build remain unchanged.

## Baseline and scope

- Base: `main` at `008e3d6e3866f99e1a5cbd7bd268ef991f407670`.
- Remote readback: `origin/main` currently resolves to the same commit.
- At initial inspection the full worktree contained 713 changed paths (66
  tracked, 647 untracked). Creating the three preparation records and updating
  one stale test contract brought the current count to 717 (67 tracked, 650
  untracked). This candidate narrows that mixed state to all 59 changed
  `Source/` and `Tests/` paths plus 16
  engineering/source-of-truth records listed in
  `2026-10-11-source-backup-candidate-files.txt`.
- The included work covers the 2026-10-11 bounded Configuration Center and
  rotation refinements, commerce extension-environment correction, processing
  and notification contract remediation, and the Share foreground-handoff
  regression repair. The exact file list is authoritative; the entire working
  tree is not in scope.

## Local retention and exclusions

Keep local and out of this candidate: all of `Research/`, `work/`, `config/`,
`Docs/Outreach/`, unreviewed release/marketing drafts, device captures and
  diagnostics, private photo/video attachments, GlassCard research probes and
  fixtures, local Codex configuration, signing material, build products, and
other unrelated or unclassified material. Also excluded are the modified
  historical 2.3.4/2.3.5 release-copy files and the full
  `Docs/CURRENT_STATUS.md` chronicle, which contains personal contact details,
  device identifiers, and machine-local paths in its historical entries. Its
  applicable checkpoint summary is provided in
  `2026-10-11-source-backup-status.md` instead.

No files were moved or deleted. No broad Git add, staging, commit, or push was
performed. The 2.3.6 release notes, README, and changelog remain unchanged
because this checkpoint does not claim a new user-facing release.

## Validation

- Exact allowlisted candidate full suite: 2,105 passed, 1 existing skipped, 0
  failed. Two existing fixture-export QoS runtime warnings remain. The first
  candidate run exposed four stale source-contract expectations for the
  already-refined navigation spacing, shared scroll helper, and injected
  configuration dependency; those assertions were updated to test the current
  contracts, and the full suite then passed.
- Focused Share/background contract tests: 3 passed, 0 failed. Focused
  architecture/layout suites also passed after updating those expectations.
- Formal Xcode 27.0 generic iOS Release build: passed with existing Apple API
  deprecation warnings.
- Signed Release install and normal launch on the paired iPhone 17 Pro Max:
  passed for 2.3.6 (124).
- Physical Share UI acceptance: not verified. The XCUITest runner exited with
  code 74 before connecting, so no Share action ran; this remains a lifecycle
  risk and is documented in
  `2026-10-11-share-foreground-handoff-regression.md`.
- Candidate contains no binaries, credential-like values, personal email
  addresses, or machine-home paths. Seven UUID-shaped values in one test file
  are test fixtures; no hardware UDID is included.
- Four-language localization contract tests passed within the full suite;
  candidate whitespace check passed. The complete local worktree may still
  contain unrelated whitespace in excluded paths.

## Authorization and stop point

The owner explicitly authorized staging, commit, and push for this bounded
source-backup candidate on 2026-10-11. The authorization applies only to the
75 paths in the allowlist. TestFlight and App Store actions remain outside
this checkpoint.
