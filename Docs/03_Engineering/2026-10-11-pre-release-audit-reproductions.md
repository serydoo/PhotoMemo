# 2026-10-11 发布前审查隔离复现断言

以下仅追加到 `/tmp/MemoMarkAuditSnapshot20261011` 对应既有测试文件；未更改项目生产源码或 Tests。复现命令按 suite 筛选，方法名筛选曾匹配零测试，不作为证据。复用既有 private fixture/helper，需放在同一文件中。

## 保存后恢复对账

追加位置：`Tests/MemoMarkTests/BatchTests/BatchQueueCommerceAccountingTests.swift`。

```swift
extension BatchQueueCommerceAccountingTests {
    @Test("AUDIT: startup reconciliation must preserve identity accounting count")
    @MainActor func auditIdentityReconciliationCountsOnce() throws {
        let suite = "MemoMark.AuditAccounting." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let accounting = BatchQueueCommerceAccounting(persistence: MemoMarkCommercePersistence(defaults: defaults))
        var task = completedTask()
        task.processingIdentity = ProcessingIdentity(sourceDigest: "audit-source", semanticsDigest: "audit-output")
        let first = try #require(accounting.recordSuccessfulSave(for: task, current: freeSnapshot()).updatedSnapshot)
        #expect(first.successfulRecordCount == 1)
        let job = BatchJob(title: "Audit", launchSource: .shareExtension,
            configuration: BatchConfigurationSnapshot(template: .classicWhite, badge: nil, anchor: nil,
                shouldWritePhotoDescription: false, photoDescriptionOverride: "", selectedAlbumIdentifier: ""),
            tasks: [task])
        let reconciled = accounting.reconcile(completedJobs: [job], current: first)
        #expect(!reconciled.requiresRecovery)
        let count = reconciled.updatedSnapshot?.successfulRecordCount ?? first.successfulRecordCount
        #expect(count == 1)
    }
}
```

## 四样式 Share 发布完整性

追加位置：`Tests/MemoMarkTests/ArchitectureTests/ProductionConfigurationContractTests.swift`。

```swift
#if !MEMOMARK_SHARE_EXTENSION
extension ProductionConfigurationContractTests {
    @Test("AUDIT: every active style must publish a complete Share snapshot", arguments: [RecordCardPresentationStyle.classicWhite, .minimal])
    @MainActor func auditCompleteSharePublication(style: RecordCardPresentationStyle) throws {
        let fixture = try Self.makeFixture()
        var aggregate = fixture.aggregate
        aggregate.subjects[0].configurations[0].presentation.route = style
        let suite = "MemoMark.AuditSnapshot." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let service = ConfigurationProjectionService(legacyStore: LegacySettingsStore(defaults: defaults),
            snapshotProvider: BatchConfigurationSnapshotProvider(defaults: defaults))
        let projection = try service.projectAndPersist(aggregate)
        #expect(BatchConfigurationSnapshotProvider(defaults: defaults).loadConfigurationReadiness().isReady)
        #expect(projection.frozenShareSnapshot != nil)
        #expect(defaults.data(forKey: BatchConfigurationSnapshotProvider.frozenShareSnapshotStorageKey) != nil)
    }
}
#endif
```

## 无关 held intake 与完成提示

追加位置：`Tests/MemoMarkTests/BatchTests/ExecutionSessionCompletionNotificationTests.swift`。

```swift
extension ExecutionSessionCompletionNotificationTests {
    @Test("AUDIT: a suspended intake from another session must not suppress current completion")
    @MainActor func auditUnrelatedSuspendedIntakeDoesNotBlockCompletion() throws {
        let suite = "MemoMark.AuditNotification." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = ExternalIntakeRequestStore(defaults: defaults)
        var completed = job(phase: .completed, asset: "saved-current")
        completed.executionSessionID = UUID()
        completed.intakeRequestID = UUID()
        var older = ExternalPhotoIntakeRequest(launchSource: .shareExtension,
            urls: [URL(fileURLWithPath: "/tmp/held-older-audit.jpg")], configurationSnapshot: completed.configuration)
        older.continuedExecutionSessionID = UUID()
        older.executionSuspendedAt = Date()
        #expect(store.persistRequest(older, diagnosticsSeed: .init()) == nil)
        let pending = store.loadRequestsForProcessing()
        #expect(pending.count == 1)
        #expect(pending[0].continuedExecutionSessionID != completed.executionSessionID)
        let message = ExecutionSessionCompletionNotification.make(id: try #require(completed.executionSessionID),
            jobs: [completed], language: .english, pendingIntakeRequestIDs: Set(pending.map(\.id)))
        #expect(message != nil)
    }
}
```

最终证据和适用边界见 `2026-10-11-pre-release-audit.md` 与 `2026-10-11-pre-release-audit-evidence.json`。这些失败断言验证期待的发布契约，不是对 iOS Release 真实运行的替代。
