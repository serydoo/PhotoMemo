#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration apply runtime coordinator")
struct V1ConfigurationApplyRuntimeCoordinatorTests {

    @Test("success applies reconciliation side effects and reports saving state transitions")
    @MainActor
    func successAppliesReconciliationSideEffectsAndReportsSavingStateTransitions() async {
        let subject =
            ConfigurationCenterState.mock.selectedSubject
        let request =
            Self.makeRequest(subject: subject)
        let receipt =
            V1ConfigurationApplyReceipt(
                saveReceipt: V1ConfigurationSaveReceipt(
                    anchor: Anchor(
                        type: .birthday,
                        title: "生日",
                        date: Date(timeIntervalSince1970: 86_400)
                    )
                ),
                albumSelection: V1ResolvedAlbumSelection(
                    identifier: "album-1",
                    title: "成长记录",
                    pickerSelectionIdentifier:
                        "picker-album-1"
                )
            )

        var didReloadAlbums = false
        var restoredSubject: MemorySubject?
        var didApplySelectedPreset = false
        var selectedExistingAlbumIdentifier = ""
        var statuses: [V1ConfigurationApplyViewStatus] = []

        let coordinator =
            V1ConfigurationApplyRuntimeCoordinator(
                applyRequest: { receivedRequest in
                    #expect(receivedRequest == request)
                    return .success(receipt)
                },
                reloadAlbums: {
                    didReloadAlbums = true
                },
                setSelectedExistingAlbumIdentifier: {
                    selectedExistingAlbumIdentifier = $0
                },
                restoreSubject: {
                    restoredSubject = $0
                },
                applySelectedMemoryPreset: {
                    didApplySelectedPreset = true
                },
                updateStatus: {
                    statuses.append($0)
                }
            )

        let wasSuccessful =
            await coordinator.apply(
                request,
                outputTarget: .newAlbum
            )

        #expect(wasSuccessful == true)
        #expect(didReloadAlbums == true)
        #expect(
            selectedExistingAlbumIdentifier
            == "picker-album-1"
        )
        #expect(restoredSubject == subject)
        #expect(didApplySelectedPreset == true)
        #expect(
            statuses == [
                V1ConfigurationApplyViewStatus(
                    status: .saving
                ),
                V1ConfigurationApplyViewStatus(
                    status: .saved
                )
            ]
        )
    }

    @Test("failure skips success side effects and surfaces error state")
    @MainActor
    func failureSkipsSuccessSideEffectsAndSurfacesErrorState() async {
        let request =
            Self.makeRequest(subject: nil)
        let error =
            PhotoMemoError(
                code: .invalidInput,
                message: "保存失败"
            )

        var didReloadAlbums = false
        var didRestoreSubject = false
        var didApplySelectedPreset = false
        var statuses: [V1ConfigurationApplyViewStatus] = []

        let coordinator =
            V1ConfigurationApplyRuntimeCoordinator(
                applyRequest: { _ in
                    .failure(error)
                },
                reloadAlbums: {
                    didReloadAlbums = true
                },
                setSelectedExistingAlbumIdentifier: { _ in
                    Issue.record(
                        "Failure flow should not update album selection."
                    )
                },
                restoreSubject: { _ in
                    didRestoreSubject = true
                },
                applySelectedMemoryPreset: {
                    didApplySelectedPreset = true
                },
                updateStatus: {
                    statuses.append($0)
                }
            )

        let wasSuccessful =
            await coordinator.apply(
                request,
                outputTarget: .automatic
            )

        #expect(wasSuccessful == false)
        #expect(didReloadAlbums == false)
        #expect(didRestoreSubject == false)
        #expect(didApplySelectedPreset == false)
        #expect(
            statuses == [
                V1ConfigurationApplyViewStatus(
                    status: .saving
                ),
                V1ConfigurationApplyViewStatus(
                    status: .failure(message: "保存失败")
                )
            ]
        )
    }

    private static func makeRequest(
        subject: MemorySubject?
    ) -> V1ConfigurationApplyRequest {
        V1ConfigurationApplyRequest(
            subject: subject,
            subjects: subject.map { [$0] } ?? [],
            selectedSubjectID: subject?.id,
            shouldSaveSubjectLibrary: true,
            template: .immersWhite,
            badge: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            timeAnchorTitle: "生日",
            timeAnchorDate: Date(timeIntervalSince1970: 86_400),
            outputTarget: .automatic,
            availableAlbums: [],
            selectedExistingAlbumIdentifier: "",
            newAlbumName: "成长记录"
        )
    }
}
#endif
