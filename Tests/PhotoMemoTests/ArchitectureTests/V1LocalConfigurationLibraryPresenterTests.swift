#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 local configuration library presenter")
struct V1LocalConfigurationLibraryPresenterTests {

    @Test("rows only include durable configurations owned by the current subject")
    func rowsFilterByCurrentSubject() {
        let currentSubject = Self.makeSubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            name: "途途"
        )
        let otherSubject = Self.makeSubject(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            name: "旅行"
        )
        let currentConfiguration = Self.makeConfiguration(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "成长配置"
        )
        let otherConfiguration = Self.makeConfiguration(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "旅行配置"
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 3,
            subjects: [
                SubjectConfigurationRecord(
                    subject: currentSubject,
                    configurations: [currentConfiguration],
                    assetManifest: PortableAssetManifest(entries: [])
                ),
                SubjectConfigurationRecord(
                    subject: otherSubject,
                    configurations: [otherConfiguration],
                    assetManifest: PortableAssetManifest(entries: [])
                )
            ],
            activeSubjectID: currentSubject.id,
            activeConfigurationID: currentConfiguration.id
        )

        let rows = V1LocalConfigurationLibraryPresenter.rows(
            subjectID: currentSubject.id,
            aggregate: aggregate
        )

        #expect(rows.map(\.id) == [currentConfiguration.id])
        #expect(rows.first?.title == "成长配置")
        #expect(rows.first?.isCurrent == true)
    }

    @Test("dirty current configuration applies before backup")
    func dirtyCurrentConfigurationAppliesBeforeBackup() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!

        let action = V1LocalConfigurationLibraryPresenter.backupAction(
            configurationID: currentID,
            currentConfigurationID: currentID,
            isCurrentConfigurationDirty: true,
            durableConfigurationIDs: [currentID]
        )

        #expect(action == .applyCurrentThenBackup)
    }

    @Test("non-current configuration backs up its durable revision")
    func nonCurrentConfigurationUsesDurableRevision() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let otherID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!

        let action = V1LocalConfigurationLibraryPresenter.backupAction(
            configurationID: otherID,
            currentConfigurationID: currentID,
            isCurrentConfigurationDirty: true,
            durableConfigurationIDs: [currentID, otherID]
        )

        #expect(action == .backupDurableConfiguration)
    }

    @Test("missing durable configuration cannot be backed up")
    func missingDurableConfigurationIsUnavailable() {
        let missingID = UUID(
            uuidString: "33333333-3333-3333-3333-333333333333"
        )!

        let action = V1LocalConfigurationLibraryPresenter.backupAction(
            configurationID: missingID,
            currentConfigurationID: nil,
            isCurrentConfigurationDirty: false,
            durableConfigurationIDs: []
        )

        #expect(action == .unavailable)
    }

    @Test("new dirty current configuration applies before its first backup")
    func newDirtyCurrentConfigurationAppliesBeforeFirstBackup() {
        let currentID = UUID(
            uuidString: "33333333-3333-3333-3333-333333333333"
        )!

        let action = V1LocalConfigurationLibraryPresenter.backupAction(
            configurationID: currentID,
            currentConfigurationID: currentID,
            isCurrentConfigurationDirty: true,
            isSavingConfiguration: false,
            durableConfigurationIDs: []
        )

        #expect(action == .applyCurrentThenBackup)
    }

    @Test("dirty non-durable current configuration is inserted before apply")
    func dirtyNonDurableCurrentConfigurationIsPreparedForApply() throws {
        let subject = Self.makeSubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            name: "途途"
        )
        let durable = Self.makeConfiguration(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "最早配置"
        )
        let dirtyID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let aggregate = ConfigurationLibraryRecord(
            revision: 5,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [durable],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: durable.id
        )

        let prepared = try #require(
            V1LocalConfigurationLibraryPresenter
                .preparingCurrentConfiguration(
                    dirtyID,
                    subjectID: subject.id,
                    in: aggregate
                )
        )

        #expect(prepared.activeSubjectID == subject.id)
        #expect(prepared.activeConfigurationID == dirtyID)
        #expect(
            prepared.subjects[0].configurations.map(\.id)
            == [durable.id, dirtyID]
        )
        #expect(prepared.subjects[0].configurations[1].revision == 0)
    }

    @Test("backup is unavailable while configuration apply is running")
    func savingConfigurationCannotBeBackedUp() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!

        let action = V1LocalConfigurationLibraryPresenter.backupAction(
            configurationID: currentID,
            currentConfigurationID: currentID,
            isCurrentConfigurationDirty: false,
            isSavingConfiguration: true,
            durableConfigurationIDs: [currentID]
        )

        #expect(action == .unavailable)
    }

    @Test("deleting the active configuration selects a durable sibling")
    func deletingActiveConfigurationSelectsSibling() throws {
        let subject = Self.makeSubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            name: "途途"
        )
        let first = Self.makeConfiguration(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "第一套"
        )
        let second = Self.makeConfiguration(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "第二套"
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 5,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [first, second],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: first.id
        )

        let candidate = try #require(
            V1LocalConfigurationLibraryPresenter.deletingConfiguration(
                first.id,
                from: aggregate
            )
        )

        #expect(candidate.subjects[0].configurations.map(\.id) == [second.id])
        #expect(candidate.activeSubjectID == subject.id)
        #expect(candidate.activeConfigurationID == second.id)
    }

    @Test("deleting the only durable configuration applies a dirty visible sibling first")
    func deletingOnlyDurableConfigurationAppliesDirtySiblingFirst() {
        let durableID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let dirtyID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!

        let action = V1LocalConfigurationLibraryPresenter.deletionAction(
            configurationID: durableID,
            currentConfigurationID: dirtyID,
            isCurrentConfigurationDirty: true,
            durableConfigurationIDs: [durableID],
            visibleConfigurationIDs: [durableID, dirtyID]
        )

        #expect(action == .applyCurrentThenDelete)
    }

    @Test("backup receipt reports revision conflict instead of claiming a save")
    func backupReceiptReportsRevisionConflict() {
        let receipt = LocalConfigurationBackupReceipt(
            disposition: .noOpRevisionConflict(
                existingRevision: 8,
                attemptedRevision: 7
            ),
            subjectID: UUID(),
            configurationID: UUID(),
            revision: 8,
            savedAt: Date(timeIntervalSince1970: 100),
            checksum: "checksum",
            fileURL: URL(fileURLWithPath: "/tmp/test.memomarkconfig")
        )

        let feedback = V1LocalConfigurationLibraryPresenter
            .backupFeedback(title: "成长配置", receipt: receipt)

        #expect(feedback.contains("未覆盖"))
        #expect(feedback.contains("版本 8"))
    }
}

private extension V1LocalConfigurationLibraryPresenterTests {

    static func makeSubject(
        id: UUID,
        name: String
    ) -> MemorySubject {
        MemorySubject(
            id: id,
            identity: .init(displayName: name, shortName: name),
            relationship: .init(role: "family", label: "记忆对象"),
            referenceDate: Date(timeIntervalSince1970: 0),
            behavior: .init(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(title: "默认表达", blocks: [])
            ),
            decorations: []
        )
    }

    static func makeConfiguration(
        id: UUID,
        title: String
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: id,
            title: title,
            revision: 2,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: nil,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [:],
                memoryCopy: .init(usesCustomText: false, customText: "")
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(mode: .appleMini, badge: nil)
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
    }
}
#endif
