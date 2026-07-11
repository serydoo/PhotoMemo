#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 configuration bootstrap presenter")
struct V1ConfigurationBootstrapPresenterTests {

    @Test("complete records project independent V1 UI drafts")
    func completeRecordsProjectIndependentV1UIDrafts() throws {
        let firstAnchorID = UUID(
            uuidString: "11111111-AAAA-AAAA-AAAA-111111111111"
        )!
        let secondAnchorID = UUID(
            uuidString: "22222222-BBBB-BBBB-BBBB-222222222222"
        )!
        let first = Self.makeConfiguration(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            title: "海边",
            templateText: "第一次看海",
            locationStyle: "city",
            logoMode: .appleMini,
            badge: .family,
            memoryText: "海边记忆",
            descriptionEnabled: false,
            descriptionText: "海边说明",
            albumDestination: .existingAlbum,
            albumID: "album-sea",
            albumTitle: "海边",
            mediaMode: .staticImage,
            anchorID: firstAnchorID
        )
        let second = Self.makeConfiguration(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            title: "生日",
            templateText: "两岁生日",
            locationStyle: "provinceCity",
            logoMode: .customUpload,
            badge: .travel,
            memoryText: "生日记忆",
            descriptionEnabled: true,
            descriptionText: "生日说明",
            albumDestination: .newAlbum,
            albumID: "",
            albumTitle: "生日新相册",
            mediaMode: .originalFormat,
            anchorID: secondAnchorID
        )

        let firstProjection =
            V1ConfigurationDraftProjection(
                configuration: first
            )
        let secondProjection =
            V1ConfigurationDraftProjection(
                configuration: second
            )

        #expect(firstProjection.configurationID == first.id)
        #expect(firstProjection.template.leftTopArea.items[0].value == "第一次看海")
        #expect(firstProjection.regionTemplateIDs[.slotA] == "海边.recorder")
        #expect(firstProjection.locationConfiguration?.options["displayStyle"] == "city")
        #expect(firstProjection.logoMode == .appleMini)
        #expect(firstProjection.badge?.id == Badge.family.id)
        #expect(firstProjection.usesCustomMemoryWriteText)
        #expect(firstProjection.customMemoryWriteText == "海边记忆")
        #expect(firstProjection.shouldWritePhotosDescription == false)
        #expect(firstProjection.photosDescriptionOverride == "海边说明")
        #expect(firstProjection.outputTarget == .existingAlbum)
        #expect(firstProjection.selectedAlbumIdentifier == "album-sea")
        #expect(firstProjection.albumTitle == "海边")
        #expect(firstProjection.mediaOutputMode == .staticImage)
        #expect(firstProjection.route == .classicWhite)
        #expect(firstProjection.selectedTimeAnchorID == firstAnchorID)

        #expect(secondProjection.configurationID == second.id)
        #expect(secondProjection.template.leftTopArea.items[0].value == "两岁生日")
        #expect(secondProjection.regionTemplateIDs[.slotA] == "生日.recorder")
        #expect(secondProjection.locationConfiguration?.options["displayStyle"] == "provinceCity")
        #expect(secondProjection.logoMode == .customUpload)
        #expect(secondProjection.badge?.id == Badge.travel.id)
        #expect(secondProjection.customMemoryWriteText == "生日记忆")
        #expect(secondProjection.shouldWritePhotosDescription)
        #expect(secondProjection.photosDescriptionOverride == "生日说明")
        #expect(secondProjection.outputTarget == .newAlbum)
        #expect(secondProjection.selectedAlbumIdentifier.isEmpty)
        #expect(secondProjection.albumTitle == "生日新相册")
        #expect(secondProjection.mediaOutputMode == .originalFormat)
        #expect(secondProjection.selectedTimeAnchorID == secondAnchorID)
        #expect(firstProjection != secondProjection)
    }

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
                    "成长记录",
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "cityDistrict"
                    )
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
        #expect(
            projection.locationDisplayConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(
                    for: "cityDistrict"
                )
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

private extension V1ConfigurationBootstrapPresenterTests {

    static func makeConfiguration(
        id: UUID,
        title: String,
        templateText: String,
        locationStyle: String,
        logoMode: V1LogoMode,
        badge: Badge,
        memoryText: String,
        descriptionEnabled: Bool,
        descriptionText: String,
        albumDestination:
            MemoryConfigurationRecord.Output.AlbumDescriptor.Destination,
        albumID: String,
        albumTitle: String,
        mediaMode: V1MediaOutputMode,
        anchorID: UUID
    ) -> MemoryConfigurationRecord {
        var template = Template.classicWhite
        template.name = title
        template.leftTopArea.items[0].value = templateText

        return MemoryConfigurationRecord(
            id: id,
            title: title,
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 400),
            selectedTimeAnchorID: anchorID,
            editor: .init(
                template: template,
                regionTemplateIDs: [.slotA: "\(title).recorder"],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: memoryText
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: .init(
                    token: "{{location}}",
                    options: ["displayStyle": locationStyle]
                ),
                logo: .init(
                    mode: logoMode,
                    badge: .init(
                        id: badge.id,
                        name: badge.name,
                        type: badge.type,
                        imageName: badge.imageName,
                        systemSymbol: badge.systemSymbol,
                        isSystemDefault: badge.isSystemDefault
                    )
                )
            ),
            output: .init(
                mediaMode: mediaMode,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: descriptionEnabled,
                    overrideText: descriptionText
                ),
                album: .init(
                    destination: albumDestination,
                    identifier: albumID,
                    title: albumTitle
                )
            )
        )
    }
}
#endif
