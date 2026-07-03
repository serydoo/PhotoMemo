#if !PHOTOMEMO_SHARE_EXTENSION
import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Architecture migration foundation", .serialized)
struct ArchitectureMigrationFoundationTests {

    @Test("PhotoMemoResult maps success values and preserves failures")
    func photoMemoResultMapsSuccessValuesAndPreservesFailures() {

        let success =
            PhotoMemoResult<Int>
            .success(3)
            .map { $0 * 2 }
        let failure =
            PhotoMemoResult<Int>
            .failure(
                PhotoMemoError(
                    code: .invalidInput,
                    message: "bad input"
                )
            )
            .map { $0 * 2 }

        switch success {
        case .success(let value):
            #expect(value == 6)
        case .failure:
            Issue.record(
                "Expected success result to stay successful."
            )
        }

        switch failure {
        case .success:
            Issue.record(
                "Expected failure result to stay failed."
            )
        case .failure(let error):
            #expect(error.code == .invalidInput)
            #expect(error.message == "bad input")
        }
    }

    @MainActor
    @Test("BuildPreviewIntent executes through AppEnvironment without changing card output")
    func buildPreviewIntentExecutesThroughAppEnvironment() async throws {

        let suiteName =
            "PhotoMemo.ArchitectureMigrationFoundationTests.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        let intakeDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "ArchitectureMigrationFoundationTests-\(UUID().uuidString)",
                isDirectory: true
            )

        let environment =
            AppEnvironment.live(
                defaults: defaults,
                intakeDirectoryURL:
                    intakeDirectoryURL
            )

        let captureDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 6,
                        day: 30,
                        hour: 9,
                        minute: 12,
                        second: 0
                    )
                )
            )
        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(
                        fileURLWithPath:
                            "/tmp/ArchitecturePreview.jpg"
                    ),
                image:
                    NSImage(
                        size: NSSize(
                            width: 1200,
                            height: 900
                        )
                    ),
                metadata:
                    PhotoMetadata(
                        captureDate:
                            captureDate,
                        deviceBrand:
                            "Apple",
                        deviceModel:
                            "iPhone 15 Pro",
                        imageWidth: 4032,
                        imageHeight: 3024
                    )
            )
        let configuration =
            environment.repositories.configuration
            .loadDefaultBatchConfigurationSnapshot()

        let expectedCard =
            RecordCardBuildService(
                defaults: defaults
            )
            .buildCard(
                from: photo,
                configuration:
                    configuration
            )
        let intent =
            BuildPreviewIntent(
                photo: photo,
                configuration:
                    configuration,
                coordinator:
                    environment.coordinators.preview
            )

        let result =
            await intent.execute()

        switch result {
        case .success(let card):
            #expect(card.template == expectedCard.template)
            #expect(card.metadata == expectedCard.metadata)
            #expect(
                card.exportDescriptionOverride
                == expectedCard.exportDescriptionOverride
            )
            #expect(
                card.memoryModule?.title
                == expectedCard.memoryModule?.title
            )
            #expect(
                card.memoryModule?.renderedText
                == expectedCard.memoryModule?.renderedText
            )
            #expect(
                card.memoryModule?.sourceAnchor
                == expectedCard.memoryModule?.sourceAnchor
            )
            #expect(
                card.memoryModule?.preferredRegion
                == expectedCard.memoryModule?.preferredRegion
            )
        case .failure(let error):
            Issue.record(
                "Expected preview intent to succeed, got \(error.message)"
            )
        }

        try? FileManager.default.removeItem(
            at: intakeDirectoryURL
        )
        defaults.removePersistentDomain(
            forName: suiteName
        )
    }

    @MainActor
    @Test("BuildPreviewIntent keeps the existing route while templates consume projected Memory values")
    func buildPreviewIntentAllowsTemplatesToConsumeProjectedMemoryValues() async throws {

        let suiteName =
            "PhotoMemo.ArchitectureProjectedMemory.\(UUID().uuidString)"
        let defaults =
            try #require(
                UserDefaults(
                    suiteName: suiteName
                )
            )
        defaults.removePersistentDomain(
            forName: suiteName
        )

        defer {
            defaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let profile =
            PersonalProfile(
                relationshipRole: .custom,
                customRelationshipLabel: "妈妈",
                babyNickname: "乐乐"
            )
        defaults.set(
            try #require(
                try? JSONEncoder().encode(profile)
            ),
            forKey: "photomemo.personalProfile"
        )

        let intakeDirectoryURL =
            FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "ArchitectureProjectedMemory-\(UUID().uuidString)",
                isDirectory: true
            )

        defer {
            try? FileManager.default.removeItem(
                at: intakeDirectoryURL
            )
        }

        let environment =
            AppEnvironment.live(
                defaults: defaults,
                intakeDirectoryURL:
                    intakeDirectoryURL
            )
        let captureDate =
            try #require(
                Calendar(identifier: .gregorian)
                .date(
                    from: DateComponents(
                        year: 2026,
                        month: 7,
                        day: 2,
                        hour: 8,
                        minute: 30
                    )
                )
            )
        let photo =
            SelectedPhoto(
                sourceURL:
                    URL(
                        fileURLWithPath:
                            "/tmp/ArchitectureProjectedMemory.jpg"
                    ),
                image:
                    NSImage(
                        size: NSSize(
                            width: 1200,
                            height: 900
                        )
                    ),
                metadata:
                    PhotoMetadata(
                        captureDate:
                            captureDate,
                        deviceBrand:
                            "Apple",
                        deviceModel:
                            "iPhone 15 Pro",
                        imageWidth: 4032,
                        imageHeight: 3024
                    )
            )
        let configuration =
            BatchConfigurationSnapshot(
                template:
                    memorySummaryTemplate(),
                badge: nil,
                anchor: nil,
                shouldWritePhotoDescription:
                    false,
                photoDescriptionOverride: "",
                selectedAlbumIdentifier: ""
            )

        let result =
            await BuildPreviewIntent(
                photo: photo,
                configuration:
                    configuration,
                coordinator:
                    environment.coordinators.preview
            )
            .execute()

        switch result {
        case .success(let card):
            let renderedText =
                try #require(
                    card.memoryModule?.renderedText
                )
            let rightBottom =
                CardTextBlockEngine()
                .build(from: card)
                .first(where: {
                    $0.area == .rightBottom
                })?
                .value

            #expect(rightBottom == renderedText)
            #expect(renderedText == "乐乐")
        case .failure(let error):
            Issue.record(
                "Expected projected-memory preview intent to succeed, got \(error.message)"
            )
        }
    }
}

private extension ArchitectureMigrationFoundationTests {

    func memorySummaryTemplate() -> Template {

        Template(
            preset: .template1,
            name: "Memory Summary",
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
                        name: "Memory Summary",
                        value: "{{memory_summary}}"
                    )
                ]
            ),
            badgeArea: .badge
        ).normalizedForEditing
    }
}
#endif
