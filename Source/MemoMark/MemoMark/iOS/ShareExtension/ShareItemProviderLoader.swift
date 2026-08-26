#if os(iOS) && MEMOMARK_SHARE_EXTENSION
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
            || MemoMarkShareProviderTypeSelection
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

        MemoMarkShareProviderTypeSelection
            .preferredImageTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    func preferredImportTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        MemoMarkShareProviderTypeSelection
            .preferredImportTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    func preferredLivePhotoTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        MemoMarkShareProviderTypeSelection
            .preferredLivePhotoTypeIdentifier(
                from: registeredTypeIdentifiers
            )
    }

    func supportsLivePhoto(
        _ registeredTypeIdentifiers: [String]
    ) -> Bool {

        MemoMarkShareProviderTypeSelection
            .supportsLivePhoto(
                registeredTypeIdentifiers
            )
    }
}
#endif
