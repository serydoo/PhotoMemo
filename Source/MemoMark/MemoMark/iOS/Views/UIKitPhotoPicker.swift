#if !MEMOMARK_SHARE_EXTENSION
#if os(iOS)
import PhotosUI
import SwiftUI
import UIKit

/// Presents the UIKit picker and forwards its immutable selection result.
/// Media resolution remains outside this surface in `PhotoIntakeImporter`.
struct UIKitPhotoPicker:
    UIViewControllerRepresentable {

    let selectionLimit: Int
    let onCancel: () -> Void
    let onSelect: ([PHPickerResult]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(
        context: Context
    ) -> PHPickerViewController {
        var configuration =
            PHPickerConfiguration(
                photoLibrary:
                    .shared()
            )
        // Keep ordinary stills and complete Live Photos in the same
        // production picker. `.images` alone is not a stable declaration of
        // Live Photo support across PHPicker implementations; explicitly
        // including the Live Photo filter lets the provider return the paired
        // asset resources that the intake pipeline already understands.
        configuration.filter = .any(
            of: [
                .images,
                .livePhotos
            ]
        )
        configuration.selectionLimit =
            selectionLimit
        configuration
            .preferredAssetRepresentationMode =
            .current

        let picker =
            PHPickerViewController(
                configuration:
                    configuration
            )
        picker.delegate =
            context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController:
            PHPickerViewController,
        context: Context
    ) {}

    final class Coordinator:
        NSObject,
        PHPickerViewControllerDelegate {

        private let parent:
            UIKitPhotoPicker

        init(
            parent:
                UIKitPhotoPicker
        ) {
            self.parent = parent
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                parent.onCancel()
                return
            }

            parent.onSelect(results)
        }
    }
}
#endif
#endif
