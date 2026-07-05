import Foundation
import Testing
@testable import PhotoMemo

@Suite("Batch queue history")
struct BatchQueueHistoryTests {

    @Test("Does not trim terminal history within the retention limit")
    func doesNotTrimTerminalHistoryWithinTheRetentionLimit() {

        let history =
            BatchQueueHistory()
        var jobs =
            (0..<120).map {
                makeTerminalJob(
                    title: "Job \($0)"
                )
            }
        let originalJobs = jobs

        history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        #expect(jobs == originalJobs)
    }

    @Test("Trims only the oldest terminal jobs beyond the retention limit")
    func trimsOnlyTheOldestTerminalJobsBeyondTheRetentionLimit() {

        let history =
            BatchQueueHistory()
        var jobs =
            (0..<121).map {
                makeTerminalJob(
                    title: "Job \($0)"
                )
            }

        history.trimTerminalJobHistoryIfNeeded(
            &jobs
        )

        #expect(jobs.count == 120)
        #expect(jobs.map(\.title).first == "Job 0")
        #expect(jobs.map(\.title).last == "Job 119")
    }

    @Test("Usage snapshot prefers frozen configuration anchor over legacy batch anchor")
    func usageSnapshotPrefersFrozenConfigurationAnchorOverLegacyBatchAnchor() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "Frozen anchor job",
                configuration:
                    try frozenAnchorConfiguration()
            )

        let snapshot =
            history.usageSnapshot(
                for: [
                    job
                ]
            )

        #expect(
            snapshot.anchorChampion?.title
            == "冻结生日"
        )
        #expect(
            snapshot.anchorChampion?.count
            == 1
        )
    }

    @Test("External intake summary prefers frozen configuration anchor over legacy batch anchor")
    func externalIntakeSummaryPrefersFrozenConfigurationAnchorOverLegacyBatchAnchor() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "External frozen anchor job",
                launchSource: .shareExtension,
                configuration:
                    try frozenAnchorConfiguration()
            )

        let summary =
            try #require(
                history.latestExternalIntakeSummary(
                    for: [
                        job
                    ]
                )
            )

        #expect(
            summary.anchorTitle
            == "冻结生日"
        )
    }

    @Test("Usage snapshot treats frozen missing anchor as authoritative")
    func usageSnapshotTreatsFrozenMissingAnchorAsAuthoritative() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "Frozen no anchor job",
                configuration:
                    try frozenNoAnchorConfiguration()
            )

        let snapshot =
            history.usageSnapshot(
                for: [
                    job
                ]
            )

        #expect(
            snapshot.anchorChampion
            == nil
        )
    }

    @Test("External intake summary treats frozen missing anchor as authoritative")
    func externalIntakeSummaryTreatsFrozenMissingAnchorAsAuthoritative() throws {
        let history =
            BatchQueueHistory()
        let job =
            makeTerminalJob(
                title: "External frozen no anchor job",
                launchSource: .shareExtension,
                configuration:
                    try frozenNoAnchorConfiguration()
            )

        let summary =
            try #require(
                history.latestExternalIntakeSummary(
                    for: [
                        job
                    ]
                )
            )

        #expect(
            summary.anchorTitle
            == nil
        )
    }

    @Test("Completed frozen configuration snapshot embeds paired frozen subject")
    func completedFrozenConfigurationSnapshotEmbedsPairedFrozenSubject() throws {
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withLegacyPairedFrozenMemoryConfiguration(
                subject: subject,
                snapshot: frozenSnapshot
            )

        let completedSnapshot =
            try #require(
                configuration
                    .completedFrozenConfigurationSnapshot
            )

        #expect(
            completedSnapshot.memorySubject
            == subject
        )
    }

    @Test("Completed frozen configuration snapshot requires embedded subject")
    func completedFrozenConfigurationSnapshotRequiresEmbeddedSubject() throws {
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )

        #expect(
            configuration
                .completedFrozenConfigurationSnapshot
            == nil
        )
    }

    @Test("Production anchor title ignores incomplete frozen snapshot")
    func productionAnchorTitleIgnoresIncompleteFrozenSnapshot() throws {
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.memorySubject = nil
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "Legacy Birthday",
                date: Date(),
                isCountdown: false
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )

        #expect(
            configuration.resolvedProductionAnchorTitle
            == "Legacy Birthday"
        )
    }
}

private extension BatchQueueHistoryTests {

    func makeTerminalJob(
        title: String,
        launchSource: BatchJobLaunchSource =
            .inAppPreview,
        configuration:
            BatchConfigurationSnapshot? = nil
    ) -> BatchJob {

        BatchJob(
            title: title,
            state: .completed,
            launchSource:
                launchSource,
            configuration:
                configuration
                ?? BatchConfigurationSnapshot(
                    template: .template1,
                    badge: nil,
                    anchor: nil,
                    shouldWritePhotoDescription: true,
                    photoDescriptionOverride: "",
                    selectedAlbumIdentifier: ""
                ),
            tasks: [
                BatchTask(
                    sourceURL:
                        URL(
                            fileURLWithPath:
                                "/tmp/\(title).jpg"
                        ),
                    phase: .completed
                )
            ]
        )
    }

    func frozenAnchorConfiguration() throws
    -> BatchConfigurationSnapshot {
        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date: anchorDate
            )
        let frozenAnchor =
            MemoryAnchor(
                title: "冻结生日",
                date: anchorDate,
                anchorType: .birthday
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.primaryAnchor =
            frozenAnchor
        return configuration
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )
    }

    func frozenNoAnchorConfiguration() throws
    -> BatchConfigurationSnapshot {
        let anchorDate =
            Date(
                timeIntervalSince1970:
                    1_725_206_400
            )
        let legacyAnchor =
            Anchor(
                type: .birthday,
                title: "旧生日",
                date: anchorDate
            )
        let configuration =
            BatchConfigurationSnapshot(
                template: .template1,
                badge: nil,
                anchor: legacyAnchor,
                shouldWritePhotoDescription: true,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        let subject =
            try #require(
                ConfigurationCenterState
                    .mock
                    .selectedSubject
            )
        var frozenSnapshot =
            ConfigurationSnapshotBuilder.build(
                from: subject
            )
        frozenSnapshot.primaryAnchor = nil
        return configuration
            .withCanonicalProductionSnapshot(
                frozenSnapshot
            )
    }
}
