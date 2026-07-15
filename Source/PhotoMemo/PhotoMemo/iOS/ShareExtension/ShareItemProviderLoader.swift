#if os(iOS) && PHOTOMEMO_SHARE_EXTENSION
import Foundation
import UniformTypeIdentifiers

struct ShareItemProviderLoader {

    func allItemProviders(
        in items: [NSExtensionItem]
    ) -> [NSItemProvider] {

        items.flatMap { item in
            item.attachments ?? []
        }
    }

    func supportedImageProviders(
        in items: [NSExtensionItem]
    ) -> [NSItemProvider] {

        allItemProviders(
            in: items
        )
        .filter {
            $0.hasItemConformingToTypeIdentifier(
                UTType.image.identifier
            )
            || PhotoMemoShareProviderTypeSelection
                .supportsLivePhoto(
                    $0.registeredTypeIdentifiers
                )
        }
    }

    func preferredFileExtension(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        let supportedType =
            registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { type in
                type.conforms(to: .image)
            }

        return supportedType?
            .preferredFilenameExtension
    }

    func preferredImageTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        PhotoMemoShareProviderTypeSelection
            .preferredImageTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    func preferredImportTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        PhotoMemoShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    func preferredLivePhotoTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        PhotoMemoShareProviderTypeSelection
            .preferredLivePhotoTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    func supportsLivePhoto(
        _ registeredTypeIdentifiers: [String]
    ) -> Bool {

        PhotoMemoShareProviderTypeSelection
            .supportsLivePhoto(
                registeredTypeIdentifiers
            )
    }
}
#endif
