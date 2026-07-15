import Foundation
import OSLog

struct PhotoMemoMediaIntakeRejectionReport:
    Codable,
    Hashable {

    let reason:
        PhotoProcessingInputPolicy.RejectionReason?

    let reasonRawValue: String?

    let title: String

    let message: String

    let fileName: String?

    let contentTypeIdentifier: String?

    let pixelSize: MediaPixelSize?

    init(
        verdict:
            PhotoProcessingInputPolicy.Verdict,
        fileName: String?,
        contentTypeIdentifier: String?,
        pixelSize: MediaPixelSize?
    ) {
        self.reason =
            verdict.reason
        self.reasonRawValue =
            verdict.reason?.rawValue
        self.title =
            verdict.title
        self.message =
            verdict.message
        self.fileName =
            fileName
        self.contentTypeIdentifier =
            contentTypeIdentifier
        self.pixelSize =
            pixelSize
    }

    var debugDescription: String {

        debugLines.joined(
            separator: "\n"
        )
    }

    var debugLines: [String] {

        var lines = [
            "rejectionReason: \(reasonRawValue ?? "unknown")",
            "title: \(title)",
            "message: \(message)"
        ]

        if let fileName {
            lines.append(
                "fileName: \(fileName)"
            )
        }

        if let contentTypeIdentifier {
            lines.append(
                "contentTypeIdentifier: \(contentTypeIdentifier)"
            )
        }

        if let pixelSize {
            lines.append(
                "pixelSize: \(pixelSize.width)x\(pixelSize.height)"
            )
        }

        return lines
    }
}

enum PhotoMemoShareIntakeFailureStage:
    String,
    Codable,
    Hashable {

    case load

    case copy

    case persist

    case serialization

    case completion

    var title: String {

        switch self {

        case .load:
            return "load"

        case .copy:
            return "copy"

        case .persist:
            return "persist"

        case .serialization:
            return "serialization"

        case .completion:
            return "completion"
        }
    }
}

enum PhotoMemoShareIntakeDiagnosticError {

    static let domain =
        "PhotoMemoShareIntake"

    static func make(
        description: String,
        code: Int,
        underlyingError: Error? = nil
    ) -> NSError {

        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey:
                description
        ]

        if let underlyingError {
            userInfo[NSUnderlyingErrorKey] =
                underlyingError
        }

        return NSError(
            domain: domain,
            code: code,
            userInfo: userInfo
        )
    }
}

struct PhotoMemoShareIntakeNSErrorSummary:
    Codable,
    Hashable {

    let localizedDescription: String

    let domain: String

    let code: Int

    let underlyingChain:
        [PhotoMemoShareIntakeNSErrorSummary]

    init(error: Error) {
        self.init(nsError: error as NSError)
    }

    init(nsError: NSError) {
        localizedDescription =
            nsError.localizedDescription
        domain = nsError.domain
        code = nsError.code

        underlyingChain =
            Self.makeUnderlyingChain(
                from: nsError
            )
    }

    var underlyingError:
        PhotoMemoShareIntakeNSErrorSummary? {

        underlyingChain.first
    }

    var debugDescription: String {

        var lines = [
            "localizedDescription: \(localizedDescription)",
            "domain: \(domain)",
            "code: \(code)"
        ]

        if let underlyingError {
            lines.append(
                "underlyingError: {\(underlyingError.debugDescription)}"
            )
        }

        return lines.joined(
            separator: ", "
        )
    }

    private static func makeUnderlyingChain(
        from nsError: NSError
    ) -> [PhotoMemoShareIntakeNSErrorSummary] {

        if let underlyingError =
            (
                nsError.userInfo[NSUnderlyingErrorKey]
                ?? nsError.userInfo["NSUnderlyingError"]
            ) as? NSError {
            return [
                PhotoMemoShareIntakeNSErrorSummary(
                    nsError: underlyingError
                )
            ]
        }

        if let underlyingError =
            (
                nsError.userInfo[NSUnderlyingErrorKey]
                ?? nsError.userInfo["NSUnderlyingError"]
            ) as? Error {
            return [
                PhotoMemoShareIntakeNSErrorSummary(
                    error: underlyingError
                )
            ]
        }

        return []
    }
}

struct PhotoMemoShareIntakeFailureContext:
    Codable,
    Hashable {

    let stage:
        PhotoMemoShareIntakeFailureStage

    let operation: String

    let itemProviderCount: Int

    let supportedProviderCount: Int

    let providerIndex: Int?

    let requestedTypeIdentifier: String?

    let preferredRegisteredTypeIdentifier:
        String?

    let returnedURL: String?

    let temporaryCopyResult: String?

    let sharedContainerDestination: String?

    let persistedRequestID: String?

    let importSummary:
        ExternalPhotoImportSummary?

    let errorSummary:
        PhotoMemoShareIntakeNSErrorSummary?

    var debugDescription: String {

        debugLines.joined(
            separator: "\n"
        )
    }

    var debugLines: [String] {

        var lines = [
            "failureStage: \(stage.title)",
            "operation: \(operation)",
            "itemProviderCount: \(itemProviderCount)",
            "supportedProviderCount: \(supportedProviderCount)"
        ]

        if let providerIndex {
            lines.append(
                "providerIndex: \(providerIndex)"
            )
        }

        if let requestedTypeIdentifier {
            lines.append(
                "requestedTypeIdentifier: \(requestedTypeIdentifier)"
            )
        }

        if let preferredRegisteredTypeIdentifier {
            lines.append(
                "preferredRegisteredTypeIdentifier: \(preferredRegisteredTypeIdentifier)"
            )
        }

        if let returnedURL {
            lines.append(
                "returnedURL: \(returnedURL)"
            )
        }

        if let temporaryCopyResult {
            lines.append(
                "temporaryCopyResult: \(temporaryCopyResult)"
            )
        }

        if let sharedContainerDestination {
            lines.append(
                "sharedContainerDestination: \(sharedContainerDestination)"
            )
        }

        if let persistedRequestID {
            lines.append(
                "persistedRequestID: \(persistedRequestID)"
            )
        }

        if let importSummary {
            lines.append(
                "importSummary: imported=\(importSummary.importedCount), skipped=\(importSummary.skippedCount), failed=\(importSummary.failedCount)"
            )
        }

        if let errorSummary {
            lines.append(
                "error: \(errorSummary.debugDescription)"
            )
        }

        return lines
    }
}

struct PhotoMemoShareIntakeOperationSeed:
    Codable,
    Hashable {

    let itemProviderCount: Int

    let supportedProviderCount: Int

    let providerIndex: Int?

    let requestedTypeIdentifier: String?

    let preferredRegisteredTypeIdentifier:
        String?

    init(
        itemProviderCount: Int = 0,
        supportedProviderCount: Int = 0,
        providerIndex: Int? = nil,
        requestedTypeIdentifier: String? = nil,
        preferredRegisteredTypeIdentifier: String? = nil
    ) {
        self.itemProviderCount =
            itemProviderCount
        self.supportedProviderCount =
            supportedProviderCount
        self.providerIndex =
            providerIndex
        self.requestedTypeIdentifier =
            requestedTypeIdentifier
        self.preferredRegisteredTypeIdentifier =
            preferredRegisteredTypeIdentifier
    }

    func failureContext(
        stage:
            PhotoMemoShareIntakeFailureStage,
        operation: String,
        returnedURL: URL? = nil,
        temporaryCopyResult: String? = nil,
        sharedContainerDestination:
            URL? = nil,
        persistedRequestID: UUID? = nil,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        error: Error? = nil
    ) -> PhotoMemoShareIntakeFailureContext {

        PhotoMemoShareIntakeFailureContext(
            stage: stage,
            operation: operation,
            itemProviderCount:
                itemProviderCount,
            supportedProviderCount:
                supportedProviderCount,
            providerIndex:
                providerIndex,
            requestedTypeIdentifier:
                requestedTypeIdentifier,
            preferredRegisteredTypeIdentifier:
                preferredRegisteredTypeIdentifier,
            returnedURL:
                returnedURL?
                .standardizedFileURL
                .path,
            temporaryCopyResult:
                temporaryCopyResult,
            sharedContainerDestination:
                sharedContainerDestination?
                .standardizedFileURL
                .path,
            persistedRequestID:
                persistedRequestID?
                .uuidString,
            importSummary:
                importSummary,
            errorSummary:
                error.map { error in
                    PhotoMemoShareIntakeNSErrorSummary(
                        error: error
                    )
                }
        )
    }
}

struct PhotoMemoShareIntakeManagedCopyResult {

    let managedURL: URL?

    let temporaryCopyResult: String?

    let sharedContainerDestination: URL?

    let failureContext:
        PhotoMemoShareIntakeFailureContext?
}

struct PhotoMemoShareIntakePersistResult {

    let request:
        ExternalPhotoIntakeRequest?

    let failureContext:
        PhotoMemoShareIntakeFailureContext?
}

enum PhotoMemoShareIntakeLog {

    nonisolated private static let logger =
        Logger(
            subsystem:
                "com.serydoo.PhotoMemo",
            category: "ShareIntake"
        )

    nonisolated static func notice(
        _ message: String
    ) {
        logger.notice(
            "\(message, privacy: .public)"
        )
    }

    nonisolated static func error(
        _ message: String
    ) {
        logger.error(
            "\(message, privacy: .public)"
        )
    }
}
