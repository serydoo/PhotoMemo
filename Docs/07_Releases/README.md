# 07 Releases

Release notes, changelog extracts, alpha notes, handoff summaries, and historical changeset drafts belong here.

每次版本同步必须先阅读 [`RELEASE_SYNC_STANDARD.md`](RELEASE_SYNC_STANDARD.md)，并按固定整理包生成版本总表、应用内说明、App Store 文案、TestFlight 说明和同步清单。版本完成同步后，还要回写 `CHANGELOG.md`、`README.md` 与 `Docs/CURRENT_STATUS.md`。

商店截图与 App Preview 按当前阶段规范执行：[`2026-08-11-v4-app-store-presentation-spec.md`](2026-08-11-v4-app-store-presentation-spec.md)。该规范冻结展示方向，但不冻结具体截图；界面或产品能力变化后必须从当前候选版本重新取证。

Canonical repository-line guidance for current release history:

- `REPOSITORY_LINE_STRATEGY.md`

Release events:

## Current Candidate Materials

The current local source-checkpoint package is `2.2.2 (95)`, prepared on
2026-08-27 from the actual last GitHub push at `03a49f1`. The comparison range
is `03a49f1..current working tree`. The source package is authorized for the
GitHub `main` sync in this task, but it is not a TestFlight upload, App Store
submission, production certification, or public release.

- [`2026-08-27-2.2.2-release-notes.md`](2026-08-27-2.2.2-release-notes.md)
- [`2026-08-27-2.2.2-app-store-whats-new.md`](2026-08-27-2.2.2-app-store-whats-new.md)
- [`2026-08-27-2.2.2-testflight-notes.md`](2026-08-27-2.2.2-testflight-notes.md)
- [`2026-08-27-2.2.2-sync-manifest.md`](2026-08-27-2.2.2-sync-manifest.md)
- [`2026-08-27-2.2.2-app-review-materials.md`](2026-08-27-2.2.2-app-review-materials.md)
- [`../Outreach/2026-08-26-MemoMark-2.2.2-XHS.md`](../Outreach/2026-08-26-MemoMark-2.2.2-XHS.md)

The previous `2.2.2 (90)` package is retained as historical candidate evidence:

- [`2026-08-26-2.2.2-release-notes.md`](2026-08-26-2.2.2-release-notes.md)
- [`2026-08-26-2.2.2-app-store-whats-new.md`](2026-08-26-2.2.2-app-store-whats-new.md)
- [`2026-08-26-2.2.2-testflight-notes.md`](2026-08-26-2.2.2-testflight-notes.md)
- [`2026-08-26-2.2.2-sync-manifest.md`](2026-08-26-2.2.2-sync-manifest.md)
- [`2026-08-26-2.2.2-app-review-materials.md`](2026-08-26-2.2.2-app-review-materials.md)

The superseded untracked `2026-08-25-2.2.1-*` and
`2026-08-22-2.1.4-*` draft packages were removed during the 2026-08-26
repository cleanup. Their accepted release history remains represented by the
tracked 2026-08-24 package and `CHANGELOG.md`.

The 2026-08-24 package below is retained as cumulative candidate history. It
starts from `a438e55` and must not be used as the current post-push source-sync
baseline.

- [`2026-08-24-2.2.1-版本更新说明.md`](2026-08-24-2.2.1-版本更新说明.md)
- [`2026-08-24-2.2.1-AppStore更新说明.md`](2026-08-24-2.2.1-AppStore更新说明.md)
- [`2026-08-24-2.2.1-TestFlight测试说明.md`](2026-08-24-2.2.1-TestFlight测试说明.md)
- [`2026-08-24-2.2.1-同步清单.md`](2026-08-24-2.2.1-同步清单.md)

- `2026-08-19-2.1.3-release-notes.md`
- `2026-08-19-2.1.3-app-store-whats-new.md`
- `2026-08-19-2.1.3-testflight-notes.md`
- `2026-08-19-2.1.3-sync-manifest.md`

- `2026-08-18-2.1.2-release-notes.md`
- `2026-08-18-2.1.2-app-store-whats-new.md`
- `2026-08-18-2.1.2-testflight-notes.md`
- `2026-08-18-2.1.2-sync-manifest.md`

- `2026-08-14-2.1.2-release-notes.md`
- `2026-08-14-2.1.2-app-store-whats-new.md`
- `2026-08-14-2.1.2-testflight-notes.md`
- `2026-08-14-2.1.2-sync-manifest.md`

- `2026-08-13-2.1.1-release-notes.md`
- `2026-08-13-2.1.1-app-store-whats-new.md`
- `2026-08-13-2.1.1-testflight-notes.md`
- `2026-08-13-2.1.1-sync-manifest.md`

- `2026-08-12-2.1.2-release-notes.md`
- `2026-08-12-2.1.2-app-store-whats-new.md`
- `2026-08-12-2.1.2-testflight-notes.md`
- `2026-08-12-2.1.2-sync-manifest.md`

- `2026-08-11-2.1.1-release-notes.md`
- `2026-08-11-2.1.1-app-store-whats-new.md`
- `2026-08-11-2.1.1-testflight-notes.md`
- `2026-08-11-2.1.1-sync-manifest.md`

- `2026-08-04-2.0.2-production-reliability.md`
- `2026-07-29-2.0.1-v3-production-quality-update.md`

- `2026-07-21-1.7-build-7-configuration-continuity-and-ui-closure.md`
- `2026-07-19-1.7-build-7-post-sync-optimizations.md`
- `2026-07-18-1.7-build-7-home-subject-anchor-and-location.md`
- `2026-07-17-1.7-build-7-expression-guide-and-crash-fix.md`
- `Expression_Platform_Main_Merge_2026-07-06.md`
- `Location_Module_Product_Acceptance_Gate_2026-07-06.md`
