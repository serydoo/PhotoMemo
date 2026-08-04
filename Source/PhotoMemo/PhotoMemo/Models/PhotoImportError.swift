import Foundation

enum PhotoImportError: LocalizedError {

    case imageLoadFailed

    case sourceMissing

    case sourceUnreadable

    case cloudDownloadTimedOut

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

    var diagnosticCode: String {
        switch self {
        case .imageLoadFailed:
            return "imageLoadFailed"
        case .sourceMissing:
            return "sourceMissing"
        case .sourceUnreadable:
            return "sourceUnreadable"
        case .cloudDownloadTimedOut:
            return "cloudDownloadTimedOut"
        case .unsupportedInput(let verdict):
            return verdict.reason?.rawValue
                ?? "unsupportedInput"
        case .rawDisplayRenderFailed:
            return "rawDisplayRenderFailed"
        case .temporaryImportPreparationFailed:
            return "temporaryImportPreparationFailed"
        }
    }

    var errorDescription: String? {

        switch self {

        case .imageLoadFailed:
            return "Unable to load this image."

        case .sourceMissing:
            return "The received image file is no longer available."

        case .sourceUnreadable:
            return "The received image file cannot be read."

        case .cloudDownloadTimedOut:
            return "The image did not finish downloading from iCloud."

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

        case .sourceMissing:
            return "Please share the photo again from Apple Photos."

        case .sourceUnreadable:
            return "Please confirm the photo opens in Apple Photos and share it again."

        case .cloudDownloadTimedOut:
            return "Open the original photo in Apple Photos, wait for it to download, and try again."

        default:
            return nil
        }
    }
}
