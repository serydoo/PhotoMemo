import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("RecordCardBuildService")
struct RecordCardBuildServiceTests {

    @Test("Suppresses export description when description writing is disabled")
    func suppressesExportDescriptionWhenWritingIsDisabled() {

        let service = RecordCardBuildService()

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            image: NSImage(size: NSSize(width: 10, height: 10)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )

        let configuration = BatchConfigurationSnapshot(
            template: .template1.normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "Should not be written",
            selectedAlbumIdentifier: ""
        )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        #expect(card.exportDescriptionOverride == "")
        #expect(CardVariableProvider.exportDescription(from: card) == "")
    }

    @Test("Uses explicit override when description writing is enabled")
    func usesExplicitOverrideWhenDescriptionWritingIsEnabled() {

        let service = RecordCardBuildService()

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            image: NSImage(size: NSSize(width: 10, height: 10)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )

        let configuration = BatchConfigurationSnapshot(
            template: .template1.normalizedForEditing,
            badge: nil,
            anchor: nil,
            shouldWritePhotoDescription: true,
            photoDescriptionOverride: "My export note",
            selectedAlbumIdentifier: ""
        )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        #expect(card.exportDescriptionOverride == "My export note")
        #expect(CardVariableProvider.exportDescription(from: card) == "My export note")
    }
}
