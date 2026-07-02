#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration bootstrap presenter")
struct V1ConfigurationBootstrapPresenterTests {

    @Test("custom logo and existing album bootstrap project into local view state")
    func customLogoAndExistingAlbumBootstrapProjectIntoLocalViewState() {
        let badge =
            Badge(
                name: "自选标识",
                type: .customUpload,
                imagePath: "/tmp/custom-logo.png"
            )
        let state =
            V1ConfigurationBootstrapState(
                customLogoBadge: badge,
                logoMode: .customUpload,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier:
                    "album-existing",
                suggestedNewAlbumName:
                    "成长记录"
            )

        let projection =
            V1ConfigurationBootstrapPresenter
            .projection(from: state)

        #expect(
            projection.customLogoBadge
            == badge
        )
        #expect(
            projection.logoMode == .customUpload
        )
        #expect(
            projection.outputTarget
            == .existingAlbum
        )
        #expect(
            projection.selectedExistingAlbumIdentifier
            == "album-existing"
        )
        #expect(
            projection.suggestedNewAlbumName
            == "成长记录"
        )
    }

    @Test("automatic and system-library bootstrap preserve non-custom logo projection")
    func automaticAndSystemLibraryBootstrapPreserveNonCustomLogoProjection() {
        let systemState =
            V1ConfigurationBootstrapState(
                customLogoBadge: nil,
                logoMode: .appleMini,
                outputTarget: .applePhotos,
                selectedExistingAlbumIdentifier:
                    "",
                suggestedNewAlbumName: nil
            )
        let automaticState =
            V1ConfigurationBootstrapState(
                customLogoBadge: nil,
                logoMode: .appleMini,
                outputTarget: .automatic,
                selectedExistingAlbumIdentifier:
                    "",
                suggestedNewAlbumName: nil
            )

        let systemProjection =
            V1ConfigurationBootstrapPresenter
            .projection(from: systemState)
        let automaticProjection =
            V1ConfigurationBootstrapPresenter
            .projection(from: automaticState)

        #expect(
            systemProjection.logoMode == .appleMini
        )
        #expect(
            systemProjection.outputTarget
            == .applePhotos
        )
        #expect(
            systemProjection.selectedExistingAlbumIdentifier
            .isEmpty
        )
        #expect(
            systemProjection.suggestedNewAlbumName
            == nil
        )

        #expect(
            automaticProjection.logoMode == .appleMini
        )
        #expect(
            automaticProjection.outputTarget
            == .automatic
        )
        #expect(
            automaticProjection.selectedExistingAlbumIdentifier
            .isEmpty
        )
        #expect(
            automaticProjection.suggestedNewAlbumName
            == nil
        )
    }

    @Test("subject-avatar bootstrap preserves the third logo mode without requiring a custom badge payload")
    func subjectAvatarBootstrapProjectsThirdLogoMode() {
        let state =
            V1ConfigurationBootstrapState(
                customLogoBadge: nil,
                logoMode: .subjectAvatar,
                outputTarget: .automatic,
                selectedExistingAlbumIdentifier: "",
                suggestedNewAlbumName: nil
            )

        let projection =
            V1ConfigurationBootstrapPresenter
            .projection(from: state)

        #expect(projection.logoMode == .subjectAvatar)
        #expect(projection.customLogoBadge == nil)
    }
}
#endif
