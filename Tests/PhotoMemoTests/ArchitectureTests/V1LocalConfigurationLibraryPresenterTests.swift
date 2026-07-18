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
            name: "小宝"
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

        let action = ConfigurationLibraryActions().decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: Self.makePreset(id: currentID),
                    selectedConfigurationID: currentID,
                    isCurrentConfigurationDirty: true,
                    isSavingConfiguration: false,
                    durableConfigurationIDs: [currentID]
                )
            )
        )

        #expect(action == .applyCurrentThenSave(Self.makePreset(id: currentID)))
    }

    @Test("non-current configuration backs up its durable revision")
    func nonCurrentConfigurationUsesDurableRevision() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let otherID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!

        let action = ConfigurationLibraryActions().decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: Self.makePreset(id: otherID),
                    selectedConfigurationID: currentID,
                    isCurrentConfigurationDirty: true,
                    isSavingConfiguration: false,
                    durableConfigurationIDs: [currentID, otherID]
                )
            )
        )

        #expect(
            action == .saveDurableConfiguration(Self.makePreset(id: otherID))
        )
    }

    @Test("missing durable configuration cannot be backed up")
    func missingDurableConfigurationIsUnavailable() {
        let missingID = UUID(
            uuidString: "33333333-3333-3333-3333-333333333333"
        )!

        let action = ConfigurationLibraryActions().decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: Self.makePreset(id: missingID),
                    selectedConfigurationID: nil,
                    isCurrentConfigurationDirty: false,
                    isSavingConfiguration: false,
                    durableConfigurationIDs: []
                )
            )
        )

        #expect(
            action
            == .unavailable(message: "找不到这条配置的持久化版本。")
        )
    }

    @Test("new dirty current configuration applies before its first backup")
    func newDirtyCurrentConfigurationAppliesBeforeFirstBackup() {
        let currentID = UUID(
            uuidString: "33333333-3333-3333-3333-333333333333"
        )!

        let action = ConfigurationLibraryActions().decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: Self.makePreset(id: currentID),
                    selectedConfigurationID: currentID,
                    isCurrentConfigurationDirty: true,
                    isSavingConfiguration: false,
                    durableConfigurationIDs: []
                )
            )
        )

        #expect(action == .applyCurrentThenSave(Self.makePreset(id: currentID)))
    }

    @Test("dirty non-durable current configuration is inserted before apply")
    func dirtyNonDurableCurrentConfigurationIsPreparedForApply() throws {
        let subject = Self.makeSubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            name: "小宝"
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

    @Test("legacy current configuration bootstraps a durable aggregate before first apply")
    func legacyCurrentConfigurationBootstrapsAggregate() throws {
        let subject = Self.makeSubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            name: "小宝"
        )
        let configurationID = UUID(
            uuidString: "33333333-3333-3333-3333-333333333333"
        )!
        let seed = Self.makeConfiguration(
            id: configurationID,
            title: "成长记录 1"
        )

        let prepared = try #require(
            V1LocalConfigurationLibraryPresenter
                .preparingCurrentConfiguration(
                    configurationID,
                    subject: subject,
                    seedConfiguration: seed,
                    in: nil
                )
        )

        #expect(prepared.activeSubjectID == subject.id)
        #expect(prepared.activeConfigurationID == configurationID)
        #expect(prepared.subjects.count == 1)
        #expect(prepared.subjects[0].subject == subject)
        #expect(prepared.subjects[0].configurations == [seed])
    }

    @Test("subject-only save keeps the latest avatar without changing configurations")
    func subjectOnlySaveKeepsLatestAvatarAndConfigurations() throws {
        let subjectID = UUID(
            uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
        )!
        let configurationID = UUID(
            uuidString: "33333333-3333-3333-3333-333333333333"
        )!
        let storedSubject = Self.makeSubject(
            id: subjectID,
            name: "小宝"
        )
        let assetRootURL = PhotoMemoSharedContainer
            .baseDirectoryURL
        let subjectAssetDirectoryURL = assetRootURL
            .appendingPathComponent(
                "SubjectAssets",
                isDirectory: true
            )
        var editedSubject = storedSubject
        editedSubject.identity.avatarImagePath =
            subjectAssetDirectoryURL
            .appendingPathComponent("display.png")
            .path
        editedSubject.identity.avatarBadgeImagePath =
            subjectAssetDirectoryURL
            .appendingPathComponent("badge.png")
            .path
        editedSubject.identity.avatarPreviewImagePath =
            subjectAssetDirectoryURL
            .appendingPathComponent("preview.png")
            .path
        let configuration = Self.makeConfiguration(
            id: configurationID,
            title: "成长记录 1"
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 5,
            subjects: [
                .init(
                    subject: storedSubject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subjectID,
            activeConfigurationID: configurationID
        )

        let prepared = try #require(
            V1LocalConfigurationLibraryPresenter
                .updatingSubject(
                    subject: editedSubject,
                    in: aggregate
                )
        )

        #expect(prepared.validationResult == .valid)
        #expect(prepared.revision == aggregate.revision)
        #expect(prepared.activeConfigurationID == configurationID)
        #expect(
            prepared.subjects[0].configurations
            == aggregate.subjects[0].configurations
        )
        #expect(
            prepared.subjects[0].subject.identity.avatarImagePath
            == "SubjectAssets/display.png"
        )
        #expect(
            prepared.subjects[0].subject.identity.avatarBadgeImagePath
            == "SubjectAssets/badge.png"
        )
        #expect(
            Set(prepared.subjects[0].assetManifest.entries.map(\.role))
            == Set([
                .subjectAvatar,
                .subjectAvatarBadge,
                .subjectAvatarPreview
            ])
        )

        let session = ConfigurationSession()
        session.restoreConfigurationLibrary(aggregate)
        session.customMemoryWriteText = "尚未保存的卡片文案"
        session.updateSelectedSubject(editedSubject)
        session.updateConfigurationLibraryReference(prepared)

        #expect(session.state.configurationLibrary == prepared)
        #expect(
            session.state.selectedSubject?.identity.avatarBadgeImagePath
            == editedSubject.identity.avatarBadgeImagePath
        )
        #expect(session.customMemoryWriteText == "尚未保存的卡片文案")
    }

    @Test("backup is unavailable while configuration apply is running")
    func savingConfigurationCannotBeBackedUp() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!

        let action = ConfigurationLibraryActions().decide(
            .saveToLocalLibrary(
                ConfigurationLibrarySaveRequest(
                    preset: Self.makePreset(id: currentID),
                    selectedConfigurationID: currentID,
                    isCurrentConfigurationDirty: false,
                    isSavingConfiguration: true,
                    durableConfigurationIDs: [currentID]
                )
            )
        )

        #expect(
            action
            == .unavailable(message: "当前配置还没有可备份的持久化记录。")
        )
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

    static func makePreset(id: UUID) -> MemoryPreset {
        MemoryPreset(
            id: id,
            title: "配置",
            summary: "当前区域组合",
            regionTemplateIDs: [:]
        )
    }

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
