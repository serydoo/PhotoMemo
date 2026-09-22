import Foundation
import Testing
@testable import MemoMark

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
            == .commitRenameAndSave(title: "新的成长记录")
        )
        #expect(actions.decide(.saveCurrent) == .saveCurrent)
        #expect(actions.decide(.activate(preset)) == .activate(preset))
    }

    @Test("dirty configuration requires an explicit activation confirmation")
    func dirtyConfigurationRequiresAnExplicitActivationConfirmation() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let destination = Self.makePreset(
            id: UUID(
                uuidString: "22222222-2222-2222-2222-222222222222"
            )!,
            title: "另一条配置"
        )
        let request = ConfigurationLibraryActivationRequest(
            preset: destination,
            selectedConfigurationID: currentID,
            isCurrentConfigurationDirty: true
        )

        #expect(
            ConfigurationLibraryActions().decide(
                .requestActivation(request)
            )
            == .requiresActivationConfirmation(destination)
        )
    }

    @Test("clean configuration activates immediately while dirty configuration still requires confirmation")
    func cleanConfigurationActivatesImmediatelyWhileDirtyConfigurationStillRequiresConfirmation() {
        let destination = Self.makePreset(
            id: UUID(
                uuidString: "22222222-2222-2222-2222-222222222222"
            )!,
            title: "另一条配置"
        )
        let actions = ConfigurationLibraryActions()

        #expect(
            actions.decide(
                .requestActivation(
                    ConfigurationLibraryActivationRequest(
                        preset: destination,
                        selectedConfigurationID: UUID(),
                        isCurrentConfigurationDirty: false
                    )
                )
            )
            == .activate(destination)
        )
        #expect(
            actions.decide(
                .requestActivation(
                    ConfigurationLibraryActivationRequest(
                        preset: destination,
                        selectedConfigurationID: destination.id,
                        isCurrentConfigurationDirty: true
                    )
                )
            )
            == .requiresActivationConfirmation(destination)
        )
    }

    @Test("activation transaction changes only the durable active configuration")
    func activationTransactionChangesOnlyTheDurableActiveConfiguration() async throws {
        let subject = Self.makeSubject()
        let activeID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let destinationID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(id: activeID, title: "当前"),
                Self.makeConfiguration(id: destinationID, title: "目标")
            ],
            activeConfigurationID: activeID
        )
        var savedAggregate: ConfigurationLibraryRecord?
        let transaction = ActivateConfigurationTransaction(
            saveConfigurationLibrary: { candidate in
                savedAggregate = candidate
                return ConfigurationLibrarySaveReceipt(
                    revision: 9,
                    subjectID: subject.id,
                    configurationID: destinationID,
                    configurationRevision: 2,
                    compatibilityProjectionFailure: nil
                )
            }
        )

        let receipt = try await transaction.apply(
            ActivateConfigurationCommand(
                subjectID: subject.id,
                configurationID: destinationID
            ),
            in: aggregate
        )

        #expect(savedAggregate?.activeSubjectID == subject.id)
        #expect(savedAggregate?.activeConfigurationID == destinationID)
        #expect(receipt.candidate.revision == 9)
        #expect(
            receipt.candidate.subjects
                == aggregate.subjects
        )
    }

    @Test("activation preflight failure does not save or change the active configuration")
    func activationPreflightFailureDoesNotSave() async throws {
        let subject = Self.makeSubject()
        let activeID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let destinationID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(id: activeID, title: "当前"),
                Self.makeConfiguration(id: destinationID, title: "目标")
            ],
            activeConfigurationID: activeID
        )
        var saveCalled = false
        let transaction = ActivateConfigurationTransaction(
            saveConfigurationLibrary: { _ in
                saveCalled = true
                return ConfigurationLibrarySaveReceipt(
                    revision: 9,
                    subjectID: subject.id,
                    configurationID: destinationID,
                    configurationRevision: 2,
                    compatibilityProjectionFailure: nil
                )
            },
            validateActivation: { _ in
                throw ConfigurationActivationCommandError
                    .activationProjectionUnavailable
            }
        )

        do {
            try await transaction.apply(
                ActivateConfigurationCommand(
                    subjectID: subject.id,
                    configurationID: destinationID
                ),
                in: aggregate
            )
            Issue.record("Activation should fail during projection preflight.")
        } catch ConfigurationActivationCommandError
            .activationProjectionUnavailable {
            // Expected: the application command must not reach persistence.
        } catch {
            Issue.record("Unexpected activation error: \(error)")
        }
        #expect(!saveCalled)
        #expect(aggregate.activeConfigurationID == activeID)
    }

    @Test("activation receipt with a projection warning is not reported as active")
    func activationReceiptWarningIsNotReportedAsActive() async throws {
        let subject = Self.makeSubject()
        let activeID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let destinationID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!
        let aggregate = Self.makeAggregate(
            subject: subject,
            configurations: [
                Self.makeConfiguration(id: activeID, title: "当前"),
                Self.makeConfiguration(id: destinationID, title: "目标")
            ],
            activeConfigurationID: activeID
        )
        let transaction = ActivateConfigurationTransaction(
            saveConfigurationLibrary: { _ in
                ConfigurationLibrarySaveReceipt(
                    revision: 9,
                    subjectID: subject.id,
                    configurationID: destinationID,
                    configurationRevision: 2,
                    compatibilityProjectionFailure:
                        .init(underlyingDescription: "projection failed")
                )
            }
        )

        do {
            try await transaction.apply(
                ActivateConfigurationCommand(
                    subjectID: subject.id,
                    configurationID: destinationID
                ),
                in: aggregate
            )
            Issue.record("Activation should reject a projection warning.")
        } catch ConfigurationActivationCommandError
            .activationProjectionUnavailable {
            // Expected: a warning is not an activation receipt.
        } catch {
            Issue.record("Unexpected activation error: \(error)")
        }
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

    @Test("deleting the active processing default atomically selects its durable sibling")
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
            visibleConfigurationIDs: [firstID, secondID],
            isProcessingDefault: true
        )

        let decision = ConfigurationLibraryActions().decide(.delete(request))
        let result = try #require(decision.deletionResult)
        #expect(result.candidate.activeConfigurationID == secondID)
        #expect(
            result.candidate.subjects[0].configurations.map(\.id)
            == [secondID]
        )
    }

    @Test("save receipt revision is projected into a non-default deletion candidate")
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
            activeConfigurationID: secondID
        )
        let request = ConfigurationLibraryDeletionRequest(
            preset: Self.makePreset(id: firstID, title: "第一套"),
            aggregate: aggregate,
            subjectID: subject.id,
            selectedConfigurationID: firstID,
            isCurrentConfigurationDirty: false,
            visibleConfigurationIDs: [firstID, secondID],
            isProcessingDefault: false
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
