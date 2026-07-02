import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("RecordCardBuildService", .serialized)
struct RecordCardBuildServiceTests {

    @Test("Builds template1 with profile relationship and baby-age phrasing")
    func buildsTemplate1WithProfileRelationshipAndBabyAgePhrasing() throws {

        let defaults = UserDefaults(
            suiteName: "RecordCardBuildServiceTests.ProfileDefaults"
        )!
        defaults.removePersistentDomain(
            forName: "RecordCardBuildServiceTests.ProfileDefaults"
        )

        defer {
            defaults.removePersistentDomain(
                forName: "RecordCardBuildServiceTests.ProfileDefaults"
            )
        }

        let profile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "他爹"
        )

        let profileData =
            try #require(
                try? JSONEncoder().encode(profile)
            )

        defaults.set(
            profileData,
            forKey: "photomemo.personalProfile"
        )

        let service = RecordCardBuildService(
            defaults: defaults
        )

        let captureDate =
            Calendar(identifier: .gregorian)
            .date(
                from: DateComponents(
                    year: 2026,
                    month: 4,
                    day: 11,
                    hour: 10,
                    minute: 13,
                    second: 5
                )
            )!

        let birthday =
            Calendar(identifier: .gregorian)
            .date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 28
                )
            )!

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_5668.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                iso: "125",
                aperture: "1.78",
                shutterSpeed: "1/98",
                focalLength35mm: "24",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )

        let configuration = BatchConfigurationSnapshot(
            template: .template1.normalizedForEditing,
            badge: nil,
            anchor: Anchor(
                type: .birthday,
                title: "途途",
                date: birthday,
                isCountdown: false
            ),
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )

        let card = service.buildCard(
            from: photo,
            configuration: configuration
        )

        let blocks =
            CardTextBlockEngine().build(from: card)

        #expect(
            blocks.first(where: { $0.area == CardTextArea.leftTop })?.value
            == "他爹手持iPhone 15 Pro记录"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.leftBottom })?.value
            == "记录于2026.04.11 10:13:05"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.rightTop })?.value
            == "24mm f/1.78 1/98s ISO125"
        )
        #expect(
            blocks.first(where: { $0.area == CardTextArea.rightBottom })?.value
            == "途途今天9个月14天啦"
        )
    }

    @Test("Falls back to right-bottom content when custom description is disabled")
    func fallsBackToRightBottomContentWhenCustomDescriptionIsDisabled() {

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

        let template = Template(
            preset: .template1,
            name: "模板 1",
            leftTopArea: .leftTop,
            leftBottomArea: .leftBottom,
            rightTopArea: TemplateArea(
                name: "Right Top",
                items: [.cameraSummary]
            ),
            rightBottomArea: TemplateArea(
                name: "Right Bottom",
                items: [
                    TemplateItem(
                        type: .text,
                        name: "补充说明",
                        value: "右下默认说明"
                    )
                ]
            ),
            badgeArea: .badge
        ).normalizedForEditing

        let configuration = BatchConfigurationSnapshot(
            template: template,
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

        #expect(card.exportDescriptionOverride == "右下默认说明")
        #expect(CardVariableProvider.exportDescription(from: card) == "右下默认说明")
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

    @Test("Build chain keeps raw anchor expression-style payloads available to downstream output")
    func buildChainKeepsRawAnchorExpressionStylePayloadsAvailableToDownstreamOutput() throws {

        let service = RecordCardBuildService()
        let calendar =
            Calendar(identifier: .gregorian)
        let birthday =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 5,
                        day: 26
                    )
                )
            )
        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2025,
                        month: 6,
                        day: 13,
                        hour: 10,
                        minute: 13,
                        second: 5
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/IMG_5668.JPEG"),
            image: NSImage(size: NSSize(width: 1920, height: 1080)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 15 Pro",
                iso: "125",
                aperture: "1.78",
                shutterSpeed: "1/98",
                focalLength35mm: "24",
                imageWidth: 4032,
                imageHeight: 2268
            )
        )

        let snapshot =
            try injectedExpressionStyleSnapshot(
                base:
                    BatchConfigurationSnapshot(
                        template:
                            .template1
                            .normalizedForEditing,
                        badge: nil,
                        anchor: Anchor(
                            type: .birthday,
                            title: "途途",
                            date: birthday,
                            isCountdown: false
                        ),
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    ),
                expressionStyle:
                    "birthdayAgeToday"
            )

        let card = service.buildCard(
            from: photo,
            configuration: snapshot
        )
        let context =
            CardVariableProvider.build(
                from: card
            )

        #expect(
            context[MetadataContext.Key.memorySummary]
            == "途途今天18天啦！"
        )
        #expect(
            try encodedExpressionStyle(
                from: card.anchor
            ) == "birthdayNatural"
        )
    }

    @MainActor
    @Test("Keeps original base filename and appends copy suffixes for repeated exports")
    func keepsOriginalBaseFilenameAndAppendsCopySuffixesForRepeatedExports() throws {

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/PhotoMemoNamingFixture.HEIC"),
            image: NSImage(size: NSSize(width: 32, height: 32)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 32,
                imageHeight: 32
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        )

        let exportFolder =
            temporaryExportFolder()

        let firstURL =
            exportFolder.appendingPathComponent(
                "PhotoMemoNamingFixture(1).jpg"
            )
        let secondURL =
            exportFolder.appendingPathComponent(
                "PhotoMemoNamingFixture(2).jpg"
            )

        clearTemporaryExportFolder()

        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }

        let exportService = RecordCardExportService()

        let exportedFirstURL =
            try exportService.exportToTemporaryFile(
                photo: photo,
                card: card
            )
        let exportedSecondURL =
            try exportService.exportToTemporaryFile(
                photo: photo,
                card: card
            )

        #expect(
            exportedFirstURL.lastPathComponent
            == "PhotoMemoNamingFixture(1).jpg"
        )
        #expect(
            exportedSecondURL.lastPathComponent
            == "PhotoMemoNamingFixture(2).jpg"
        )
    }

    @MainActor
    @Test("Export naming prefers the imported original file name over the temporary source URL")
    func exportNamingPrefersImportedOriginalFileName() throws {

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/ManagedShareCopy.jpg"),
            image: NSImage(size: NSSize(width: 32, height: 32)),
            metadata: PhotoMetadata(
                captureDate: Date(),
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 32,
                imageHeight: 32
            ),
            sourceInfo: PhotoSourceInfo(
                originalFileName: "IMG_7581.HEIC",
                assetLocalIdentifier: "asset-7581",
                contentTypeIdentifier: "public.heic"
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        )

        let exportFolder =
            temporaryExportFolder()

        let expectedURL =
            exportFolder.appendingPathComponent(
                "IMG_7581(1).jpg"
            )

        clearTemporaryExportFolder()

        defer {
            try? FileManager.default.removeItem(at: expectedURL)
        }

        let exportedURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: photo,
                card: card
            )

        #expect(
            exportedURL.lastPathComponent
            == "IMG_7581(1).jpg"
        )
    }

    @MainActor
    @Test("Export naming falls back from placeholder names to a capture-date filename")
    func exportNamingFallsBackFromPlaceholderNamesToCaptureDateFilename() throws {

        var calendar =
            Calendar(identifier: .gregorian)
        calendar.timeZone =
            try #require(
                TimeZone(
                    secondsFromGMT:
                        8 * 60 * 60
                )
            )

        let captureDate =
            try #require(
                calendar.date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 20,
                        hour: 9,
                        minute: 8,
                        second: 19
                    )
                )
            )

        let photo = SelectedPhoto(
            sourceURL: URL(fileURLWithPath: "/tmp/PhotoMemo Import.JPG"),
            image: NSImage(size: NSSize(width: 32, height: 32)),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                captureTimezoneOffsetSeconds:
                    8 * 60 * 60,
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 32,
                imageHeight: 32
            ),
            sourceInfo: PhotoSourceInfo(
                originalFileName:
                    "PhotoMemo Import.JPG"
            )
        )

        let card = RecordCardBuildService().buildCard(
            from: photo,
            configuration: BatchConfigurationSnapshot(
                template: .template1.normalizedForEditing,
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription: false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )
        )

        let exportFolder =
            temporaryExportFolder()

        let expectedURL =
            exportFolder.appendingPathComponent(
                "IMG_20260620_090819(1).jpg"
            )

        clearTemporaryExportFolder()

        defer {
            try? FileManager.default.removeItem(
                at: expectedURL
            )
        }

        let exportedURL =
            try RecordCardExportService()
            .exportToTemporaryFile(
                photo: photo,
                card: card
            )

        #expect(
            exportedURL.lastPathComponent
            == "IMG_20260620_090819(1).jpg"
        )
    }

    @MainActor
    @Test("Uses exported file name as the photo-library original filename")
    func usesExportedFileNameAsPhotoLibraryOriginalFilename() {

        let service =
            PhotoLibraryExportService()

        #expect(
            service.assetOriginalFilename(
                for: URL(fileURLWithPath: "/tmp/IMG_1234.jpg")
            ) == "IMG_1234.jpg"
        )

        #expect(
            service.assetOriginalFilename(
                for: URL(fileURLWithPath: "/tmp/IMG_1234 (1).jpg")
            ) == "IMG_1234 (1).jpg"
        )

        #expect(
            service.assetOriginalFilename(
                for: URL(fileURLWithPath: "/tmp/ ")
            ) == "PhotoMemo.jpg"
        )
    }
}

private extension RecordCardBuildServiceTests {

    func temporaryExportFolder() -> URL {

        FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "PhotoMemoExports",
                isDirectory: true
            )
    }

    func clearTemporaryExportFolder() {

        try? FileManager.default.removeItem(
            at:
                temporaryExportFolder()
        )
    }

    func injectedExpressionStyleSnapshot(
        base: BatchConfigurationSnapshot,
        expressionStyle: String
    ) throws -> BatchConfigurationSnapshot {

        let data =
            try JSONEncoder().encode(base)
        guard
            var payload =
                try JSONSerialization
                .jsonObject(with: data)
                as? [String: Any],
            var anchorPayload =
                payload["anchor"]
                as? [String: Any]
        else {
            throw CocoaError(.coderInvalidValue)
        }

        anchorPayload["expressionStyle"] =
            expressionStyle
        payload["anchor"] =
            anchorPayload

        let mutatedData =
            try JSONSerialization.data(
                withJSONObject: payload
            )

        return try JSONDecoder().decode(
            BatchConfigurationSnapshot.self,
            from: mutatedData
        )
    }

    func encodedExpressionStyle(
        from anchor: Anchor?
    ) throws -> String? {

        guard let anchor else {
            return nil
        }

        let data =
            try JSONEncoder().encode(anchor)

        return (
            try JSONSerialization
            .jsonObject(with: data)
            as? [String: Any]
        )?["expressionStyle"] as? String
    }
}
