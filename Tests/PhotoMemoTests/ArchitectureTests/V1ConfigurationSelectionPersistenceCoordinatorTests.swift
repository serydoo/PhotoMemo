#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration selection persistence coordinator")
struct V1ConfigurationSelectionPersistenceCoordinatorTests {

    @Test("durable receipt reconciles only the unchanged selection snapshot")
    func durableReceiptReconcilesOnlyUnchangedSelection() async throws {
        let aggregate = try Self.makeAggregate()
        let coordinator = V1ConfigurationSelectionPersistenceCoordinator {
            candidate in
            ConfigurationLibrarySaveReceipt(
                revision: candidate.revision + 1,
                subjectID: try #require(candidate.activeSubjectID),
                configurationID:
                    try #require(candidate.activeConfigurationID),
                configurationRevision: 3,
                compatibilityProjectionFailure: nil
            )
        }

        let result = await coordinator.persist(aggregate)
        guard case .saved(let patch) = result else {
            Issue.record("Expected a durable selection patch.")
            return
        }

        #expect(patch.reconcile(current: aggregate)?.revision == 12)

        var changedRevision = aggregate
        changedRevision.revision += 1
        #expect(patch.reconcile(current: changedRevision) == nil)

        var changedSelection = aggregate
        changedSelection.activeConfigurationID = UUID()
        #expect(patch.reconcile(current: changedSelection) == nil)
    }

    @Test("persistence failure returns the existing user-facing failure")
    func persistenceFailureReturnsFailurePatch() async throws {
        let aggregate = try Self.makeAggregate()
        let coordinator = V1ConfigurationSelectionPersistenceCoordinator {
            _ in throw TestFailure()
        }

        #expect(
            await coordinator.persist(aggregate)
            == .failed(message: "当前配置切换保存失败，请重试。")
        )
    }
}

private extension V1ConfigurationSelectionPersistenceCoordinatorTests {
    struct TestFailure: Error {}

    static func makeAggregate() throws -> ConfigurationLibraryRecord {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        let configuration = MemoryConfigurationRecord(
            id: UUID(uuidString: "81818181-8181-8181-8181-818181818181")!,
            title: "当前配置",
            revision: 3,
            savedAt: Date(timeIntervalSince1970: 300),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
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
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
        return ConfigurationLibraryRecord(
            revision: 11,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )
    }
}
#endif
