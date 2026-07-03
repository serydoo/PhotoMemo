#if !PHOTOMEMO_SHARE_EXTENSION
import AppKit
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Production memory resolver", .serialized)
struct ProductionMemoryResolverTests {

    @Test("resolves memory payload from production inputs using capture time")
    func resolvesMemoryPayloadFromProductionInputsUsingCaptureTime() throws {
        let suite =
            suiteName("resolvesMemoryPayload")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let profile = PersonalProfile(
            relationshipRole: .custom,
            customRelationshipLabel: "妈妈",
            babyNickname: "途途"
        )
        let profileData =
            try #require(
                try? JSONEncoder().encode(profile)
            )
        defaults.set(
            profileData,
            forKey: "photomemo.personalProfile"
        )

        let birthday =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let captureDate =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 6,
                    day: 13
                )
            ) ?? Date()

        let payload =
            ProductionMemoryResolver(
                defaults: defaults
            )
            .resolve(
                photo: selectedPhoto(
                    captureDate: captureDate
                ),
                configuration:
                    BatchConfigurationSnapshot(
                        template:
                            .template1
                            .normalizedForEditing,
                        badge: nil,
                        anchor: Anchor(
                            type: .birthday,
                            title: "生日",
                            date: birthday
                        ),
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
            )

        #expect(
            payload.subject.identity.displayName
            == "途途"
        )
        #expect(
            payload.snapshot.subjectID
            == payload.subject.id
        )
        #expect(
            payload.module.sourceAnchor?.title
            == "生日"
        )
        #expect(
            payload.module.renderedText
            == "途途今天18天啦！"
        )
    }

    @Test("falls back to default profile without preview state")
    func fallsBackToDefaultProfileWithoutPreviewState() {
        let suite =
            suiteName("defaultProfileFallback")
        let defaults = UserDefaults(
            suiteName: suite
        )!
        defaults.removePersistentDomain(
            forName: suite
        )

        defer {
            defaults.removePersistentDomain(
                forName: suite
            )
        }

        let payload =
            ProductionMemoryResolver(
                defaults: defaults
            )
            .resolve(
                photo: selectedPhoto(
                    captureDate: nil
                ),
                configuration:
                    BatchConfigurationSnapshot(
                        template:
                            .template1
                            .normalizedForEditing,
                        badge: nil,
                        anchor: nil,
                        shouldWritePhotoDescription:
                            false,
                        photoDescriptionOverride: "",
                        selectedAlbumIdentifier: ""
                    )
            )

        #expect(
            payload.subject.identity.displayName
            == "家人"
        )
        #expect(
            payload.module.renderedText
            == "家人"
        )
        #expect(
            payload.module.sourceAnchor == nil
        )
    }
}

private extension ProductionMemoryResolverTests {

    func selectedPhoto(
        captureDate: Date?
    ) -> SelectedPhoto {
        SelectedPhoto(
            sourceURL: URL(
                fileURLWithPath: "/tmp/test.jpg"
            ),
            image: NSImage(
                size: NSSize(
                    width: 32,
                    height: 32
                )
            ),
            metadata: PhotoMetadata(
                captureDate: captureDate,
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro",
                imageWidth: 4032,
                imageHeight: 3024
            )
        )
    }

    func suiteName(
        _ suffix: String
    ) -> String {
        "ProductionMemoryResolverTests.\(suffix).\(UUID().uuidString)"
    }
}
#endif
