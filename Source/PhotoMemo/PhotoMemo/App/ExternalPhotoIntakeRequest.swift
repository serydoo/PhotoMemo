import Foundation
import UniformTypeIdentifiers

struct LivePhotoStaticFallbackRecoveryHint:
    Hashable,
    Codable {

    let originalFileName: String?

    let advertisedLivePhotoTypeIdentifier: String

    let staticContentTypeIdentifier: String?

    let captureDate: Date?

    let pixelWidth: Int?

    let pixelHeight: Int?

    init(
        originalFileName: String? = nil,
        advertisedLivePhotoTypeIdentifier: String,
        staticContentTypeIdentifier: String? = nil,
        captureDate: Date? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil
    ) {
        self.originalFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                originalFileName
            )
        self.advertisedLivePhotoTypeIdentifier =
            advertisedLivePhotoTypeIdentifier
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.staticContentTypeIdentifier =
            staticContentTypeIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.captureDate = captureDate
        self.pixelWidth =
            pixelWidth.map {
                max($0, 1)
            }
        self.pixelHeight =
            pixelHeight.map {
                max($0, 1)
            }
    }
}

enum LivePhotoStaticFallbackDateParser {

    static func parse(
        _ dateString: String,
        timeZone: TimeZone = .current
    ) -> Date? {

        let timezoneLessFormats = [
            "yyyy:MM:dd HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]
        let timezoneAwareFormats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]

        for format in timezoneLessFormats {
            if let date =
                formattedDate(
                    dateString,
                    format: format,
                    timeZone: timeZone
                ) {
                return date
            }
        }

        for format in timezoneAwareFormats {
            if let date =
                formattedDate(
                    dateString,
                    format: format,
                    timeZone: nil
                ) {
                return date
            }
        }

        return nil
    }

    private static func formattedDate(
        _ dateString: String,
        format: String,
        timeZone: TimeZone?
    ) -> Date? {

        let formatter =
            DateFormatter()
        formatter.locale =
            Locale(identifier: "en_US_POSIX")
        formatter.dateFormat =
            format
        if let timeZone {
            formatter.timeZone =
                timeZone
        }

        return formatter.date(
            from: dateString
        )
    }
}

struct ExternalPhotoImportSummary:
    Hashable,
    Codable {

    let importedCount: Int

    let skippedCount: Int

    let failedCount: Int

    var selectedCount: Int {
        importedCount + skippedCount + failedCount
    }

    var hasWarnings: Bool {
        skippedCount > 0 || failedCount > 0
    }
}

struct ExternalPhotoIntakeItem:
    Identifiable,
    Hashable,
    Codable {

    let managedURL: URL

    let originalFileName: String

    let sourceIdentifier: String?

    let contentTypeIdentifier: String?

    let livePhotoRecoveryHint:
        LivePhotoStaticFallbackRecoveryHint?

    var id: String {
        managedURL.standardizedFileURL.path
    }

    init(
        managedURL: URL,
        originalFileName: String? = nil,
        sourceIdentifier: String? = nil,
        contentTypeIdentifier: String? = nil,
        livePhotoRecoveryHint:
            LivePhotoStaticFallbackRecoveryHint? = nil
    ) {
        let normalizedManagedURL =
            managedURL.standardizedFileURL
        let trimmedOriginalFileName =
            originalFileName?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        self.managedURL = normalizedManagedURL
        self.originalFileName =
            PhotoFileNameResolver
            .sanitizedOriginalFileName(
                trimmedOriginalFileName
            )
            ?? PhotoFileNameResolver
            .sanitizedOriginalFileName(
                normalizedManagedURL
                .lastPathComponent
            )
            ?? normalizedManagedURL
            .lastPathComponent
        self.sourceIdentifier =
            sourceIdentifier?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        self.contentTypeIdentifier =
            ExternalPhotoIntakeItem
            .resolvedContentTypeIdentifier(
                explicitValue:
                    contentTypeIdentifier,
                managedURL:
                    normalizedManagedURL
            )
        self.livePhotoRecoveryHint =
            livePhotoRecoveryHint
    }

    var payload: BatchTaskIntakePayload {
        BatchTaskIntakePayload(
            sourceURL: managedURL,
            sourceIdentifier: sourceIdentifier,
            fileName: originalFileName,
            contentTypeIdentifier:
                contentTypeIdentifier
        )
    }

    private static func resolvedContentTypeIdentifier(
        explicitValue: String?,
        managedURL: URL
    ) -> String? {

        let trimmedValue =
            explicitValue?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let trimmedValue,
           !trimmedValue.isEmpty {
            return trimmedValue
        }

        return UTType(
            filenameExtension:
                managedURL.pathExtension
                .lowercased()
        )?.identifier
    }
}

struct ExternalPhotoIntakeRequest:
    Identifiable,
    Hashable,
    Codable {

    let id: UUID

    let launchSource: BatchJobLaunchSource

    let urls: [URL]

    let items: [ExternalPhotoIntakeItem]?

    let configurationSnapshot:
        BatchConfigurationSnapshot

    let importSummary:
        ExternalPhotoImportSummary?

    let receivedAt: Date

    init(
        id: UUID = UUID(),
        launchSource: BatchJobLaunchSource,
        urls: [URL],
        items: [ExternalPhotoIntakeItem]? = nil,
        configurationSnapshot: BatchConfigurationSnapshot,
        importSummary:
            ExternalPhotoImportSummary? = nil,
        receivedAt: Date = Date()
    ) {
        self.id = id
        self.launchSource = launchSource
        self.urls = urls
        self.items =
            items?.isEmpty == true
            ? nil
            : items
        self.configurationSnapshot =
            configurationSnapshot
        self.importSummary =
            importSummary
        self.receivedAt = receivedAt
    }

    var intakePayloads:
        [BatchTaskIntakePayload] {

        if let items,
           !items.isEmpty {
            return items.map(\.payload)
        }

        return urls.map {
            BatchTaskIntakePayload(
                sourceURL: $0,
                fileName:
                    $0.lastPathComponent
            )
        }
    }
}
