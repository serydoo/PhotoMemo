import Foundation

enum PhotoImportError: LocalizedError {

    case imageLoadFailed

    case rawDisplayRenderFailed

    case temporaryImportPreparationFailed

    var errorDescription: String? {

        switch self {

        case .imageLoadFailed:
            return "Unable to load this image."

        case .rawDisplayRenderFailed:
            return "Unable to prepare a display image for this RAW photo."

        case .temporaryImportPreparationFailed:
            return "Unable to prepare the selected photo."
        }
    }
}
