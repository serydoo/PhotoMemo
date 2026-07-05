import Foundation

enum PhotoImportError: LocalizedError {

    case imageLoadFailed

    case unsupportedInput(PhotoProcessingInputPolicy.Verdict)

    case rawDisplayRenderFailed

    case temporaryImportPreparationFailed

    var inputPolicyReason:
        PhotoProcessingInputPolicy.RejectionReason? {

        guard case let .unsupportedInput(verdict) = self else {
            return nil
        }

        return verdict.reason
    }

    var errorDescription: String? {

        switch self {

        case .imageLoadFailed:
            return "Unable to load this image."

        case let .unsupportedInput(verdict):
            return verdict.title

        case .rawDisplayRenderFailed:
            return "Unable to prepare a display image for this RAW photo."

        case .temporaryImportPreparationFailed:
            return "Unable to prepare the selected photo."
        }
    }

    var failureReason: String? {

        switch self {

        case let .unsupportedInput(verdict):
            return verdict.message

        default:
            return nil
        }
    }
}
