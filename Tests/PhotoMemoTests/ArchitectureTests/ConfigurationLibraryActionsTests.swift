import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("Configuration library actions")
struct ConfigurationLibraryActionsTests {

    @Test("create reset rename save and activate return typed root decisions")
    func commonIntentsReturnTypedDecisions() {
        let preset = Self.makePreset(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "成长记录"
        )
        let actions = ConfigurationLibraryActions()

        #expect(actions.decide(.create) == .create)
        #expect(actions.decide(.reset) == .reset)
        #expect(
            actions.decide(.beginRename(title: preset.title))
            == .beginRename(title: "成长记录")
        )
        #expect(
            actions.decide(.commitRename(title: "新的成长记录"))
            == .commitRename(title: "新的成长记录")
        )
        #expect(actions.decide(.saveCurrent) == .saveCurrent)
        #expect(actions.decide(.activate(preset)) == .activate(preset))
    }

    @Test("begin rename can refresh its draft while already editing")
    func beginRenameCanBeRetiggeredWhileEditing() {
        let actions = ConfigurationLibraryActions()

        #expect(
            actions.decide(.beginRename(title: "当前配置"))
            == .beginRename(title: "当前配置")
        )
        #expect(
            actions.decide(.beginRename(title: "已保存配置"))
            == .beginRename(title: "已保存配置")
        )
    }

    @Test("save current remains a dispatcher decision")
    func saveCurrentReturnsDispatcherDecision() {
        #expect(
            ConfigurationLibraryActions().decide(.saveCurrent)
            == .saveCurrent
        )
    }

    @Test("dirty non-durable sibling is saved before deleting the last durable configuration")
    func dirtyNonDurableSiblingAppliesBeforeDelete() {
        let durableID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let dirtyID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let subject = Self.makeSubject()
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(id: durableID, title: "已保存")
            ],
            activeConfigurationID: durableID
        )
        let request = ConfigurationLibraryDeletionRequest(
            preset: Self.makePreset(id: durableID, title: "已保存"),
            aggregate: aggregate,
            subjectID: subject.id,
            selectedConfigurationID: dirtyID,
            isCurrentConfigurationDirty: true,
            visibleConfigurationIDs: [durableID, dirtyID]
        )

        let decision = ConfigurationLibraryActions().decide(.delete(request))

        #expect(decision == .applyCurrentThenDelete(request.preset))
    }

    @Test("deleting the last durable configuration remains unavailable")
    func lastDurableConfigurationIsProtected() {
        let configurationID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let subject = Self.makeSubject()
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(
                    id: configurationID,
                    title: "唯一配置"
                )
            ],
            activeConfigurationID: configurationID
        )
        let request = ConfigurationLibraryDeletionRequest(
            preset: Self.makePreset(
                id: configurationID,
                title: "唯一配置"
            ),
            aggregate: aggregate,
            subjectID: subject.id,
            selectedConfigurationID: configurationID,
            isCurrentConfigurationDirty: false,
            visibleConfigurationIDs: [configurationID]
        )

        let decision = ConfigurationLibraryActions().decide(.delete(request))

        #expect(
            decision
            == .unavailable(
                message: "请至少保留一条已保存配置；可以先保存当前新增配置。"
            )
        )
    }

    @Test("deleting the active configuration selects its durable sibling")
    func activeConfigurationDeletionSelectsSibling() throws {
        let firstID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let secondID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let subject = Self.makeSubject()
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(id: firstID, title: "第一套"),
                Self.makeConfiguration(id: secondID, title: "第二套")
            ],
            activeConfigurationID: firstID
        )
        let request = ConfigurationLibraryDeletionRequest(
            preset: Self.makePreset(id: firstID, title: "第一套"),
            aggregate: aggregate,
            subjectID: subject.id,
            selectedConfigurationID: firstID,
            isCurrentConfigurationDirty: false,
            visibleConfigurationIDs: [firstID, secondID]
        )

        let decision = ConfigurationLibraryActions().decide(.delete(request))
        let result = try #require(decision.deletionResult)

        #expect(result.deletedPreset == request.preset)
        #expect(
            result.candidate.subjects[0].configurations.map(\.id)
            == [secondID]
        )
        #expect(result.candidate.activeSubjectID == subject.id)
        #expect(result.candidate.activeConfigurationID == secondID)
    }

    @Test("save receipt revision is projected into the deletion candidate")
    func receiptRevisionIsProjectedIntoCandidate() throws {
        let firstID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let secondID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let subject = Self.makeSubject()
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(id: firstID, title: "第一套"),
                Self.makeConfiguration(id: secondID, title: "第二套")
            ],
            activeConfigurationID: firstID
        )
        let request = ConfigurationLibraryDeletionRequest(
            preset: Self.makePreset(id: firstID, title: "第一套"),
            aggregate: aggregate,
            subjectID: subject.id,
            selectedConfigurationID: firstID,
            isCurrentConfigurationDirty: false,
            visibleConfigurationIDs: [firstID, secondID]
        )
        let decision = ConfigurationLibraryActions().decide(.delete(request))
        let result = try #require(decision.deletionResult)

        let reconciled = result.reconcilingRevision(12)

        #expect(reconciled.candidate.revision == 12)
        #expect(reconciled.deletedPreset == request.preset)
    }
}

private extension ConfigurationLibraryActionDecision {

    var deletionResult: ConfigurationLibraryDeletionResult? {
        guard case .persistDeletion(let result) = self else {
            return nil
        }
        return result
    }
}

private extension ConfigurationLibraryActionsTests {

    static func makeSubject() -> MemorySubject {
        MemorySubject(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            identity: .init(displayName: "小宝", shortName: "小宝"),
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

    static func makePreset(id: UUID, title: String) -> MemoryPreset {
        MemoryPreset(
            id: id,
            title: title,
            summary: "当前区域组合",
            regionTemplateIDs: [:]
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

    static func makeAggregate(
        subject: MemorySubject,
        configurations: [MemoryConfigurationRecord],
        activeConfigurationID: UUID
    ) -> ConfigurationLibraryRecord {
        ConfigurationLibraryRecord(
            revision: 5,
            subjects: [
                .init(
                    subject: subject,
                    configurations: configurations,
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: activeConfigurationID
        )
    }
}
