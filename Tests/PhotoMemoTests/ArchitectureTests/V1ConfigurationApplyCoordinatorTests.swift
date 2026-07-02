#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@MainActor
@Suite("V1 configuration apply coordinator")
struct V1ConfigurationApplyCoordinatorTests {

    @Test("apply resolves album selection before saving the V1 configuration aggregate")
    func applyResolvesAlbumSelectionBeforeSavingTheV1ConfigurationAggregate() async {
        let expectedAlbumSelection =
            V1ResolvedAlbumSelection(
                identifier: "album-1",
                title: "成长记录",
                pickerSelectionIdentifier:
                    "picker-album-1"
            )
        let expectedReceipt =
            V1ConfigurationSaveReceipt(
                anchor: Anchor(
                    type: .birthday,
                    title: "途途",
                    date: Date(
                        timeIntervalSince1970:
                            1_725_206_400
                    )
                )
            )
        let request =
            V1ConfigurationApplyRequest(
                subject:
                    ConfigurationCenterState
                    .mock
                    .selectedSubject,
                template:
                    Template.immersWhite,
                badge: .family,
                shouldWritePhotoDescription:
                    true,
                photoDescriptionOverride:
                    "第一次一起看海",
                timeAnchorTitle: "途途",
                timeAnchorDate:
                    Date(
                        timeIntervalSince1970:
                            1_725_206_400
                    ),
                outputTarget: .newAlbum,
                availableAlbums: [],
                selectedExistingAlbumIdentifier:
                    "",
                newAlbumName: "成长记录"
            )

        var receivedAlbumRequest:
            V1OutputAlbumSelectionRequest?
        var receivedSaveRequest:
            V1ConfigurationSaveRequest?

        let coordinator =
            V1ConfigurationApplyCoordinator(
                resolveAlbumSelection: {
                    albumRequest in
                    receivedAlbumRequest =
                        albumRequest
                    return .success(
                        expectedAlbumSelection
                    )
                },
                saveConfiguration: {
                    saveRequest in
                    receivedSaveRequest =
                        saveRequest
                    return .success(
                        expectedReceipt
                    )
                }
            )

        let result =
            await coordinator
            .apply(request)

        switch result {
        case .success(let receipt):
            #expect(
                receipt.albumSelection
                == expectedAlbumSelection
            )
            #expect(
                receipt.saveReceipt
                == expectedReceipt
            )
        case .failure(let error):
            Issue.record(
                "Expected V1 apply to succeed. Failure code: \(String(describing: error.code.rawValue))"
            )
        }

        #expect(
            receivedAlbumRequest
            == V1OutputAlbumSelectionRequest(
                outputTarget: .newAlbum,
                availableAlbums: [],
                selectedExistingAlbumIdentifier:
                    "",
                newAlbumName: "成长记录"
            )
        )
        #expect(
            receivedSaveRequest?.albumSelection
            == .init(
                identifier: "album-1",
                title: "成长记录"
            )
        )
        #expect(
            receivedSaveRequest?.timeAnchor
            == .init(
                title: "途途",
                date: Date(
                    timeIntervalSince1970:
                        1_725_206_400
                )
            )
        )
        #expect(
            receivedSaveRequest?.template
            == request.template
        )
    }

    @Test("apply with no configuration coordinator fails instead of falling back to direct settings writes")
    func applyWithNoConfigurationCoordinatorFailsInsteadOfFallingBackToDirectSettingsWrites() async {
        let coordinator =
            V1ConfigurationApplyCoordinator(
                configurationCoordinator:
                    nil,
                exportCoordinator:
                    nil
            )

        let result =
            await coordinator
            .apply(
                V1ConfigurationApplyRequest(
                    subject: nil,
                    template:
                        Template.immersWhite,
                    badge: nil,
                    shouldWritePhotoDescription:
                        false,
                    photoDescriptionOverride:
                        "",
                    timeAnchorTitle:
                        "记忆对象",
                    timeAnchorDate:
                        Date(
                            timeIntervalSince1970:
                                1_704_067_200
                        ),
                    outputTarget:
                        .automatic,
                    availableAlbums: [],
                    selectedExistingAlbumIdentifier:
                        "",
                    newAlbumName:
                        PhotoMemoAlbumSelection
                        .defaultAlbumTitle
                )
            )

        switch result {
        case .success:
            Issue.record(
                "Expected V1 apply to fail without a configuration coordinator."
            )
        case .failure(let error):
            #expect(
                error.code
                == .configurationUnavailable
            )
        }
    }
}
#endif
