#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum ConfigurationImportWarning: Hashable {

    case missingAnchor(UUID)
    case missingAlbum(identifier: String, title: String)
    case missingAsset(
        role: PortableAssetManifest.Role,
        path: String
    )
    case configurationRestoredAsCopy(
        originalID: UUID,
        restoredID: UUID
    )
}

enum ConfigurationImportError: Error, Equatable {

    case unsupportedOlderSchema(
        found: Int,
        earliestSupported: Int
    )
    case unsupportedFutureSchema(
        found: Int,
        latestSupported: Int
    )
    case corruptDocument(String)
    case checksumMismatch(expected: String, actual: String)
    case invalidDocument(
        [ConfigurationRecordValidationIssue]
    )
    case aggregateApplyUnavailable
}

struct ConfigurationImportResolution: Hashable {

    let subject: MemorySubject
    let configuration: MemoryConfigurationRecord
    let assetManifest: PortableAssetManifest
    let warnings: [ConfigurationImportWarning]
}

struct ConfigurationImportRestoreReceipt {

    let aggregate: ConfigurationLibraryRecord
    let restoredSubjectID: UUID
    let restoredConfigurationID: UUID
    let warnings: [ConfigurationImportWarning]
}

struct ConfigurationImportApplyReceipt {

    let restoreReceipt: ConfigurationImportRestoreReceipt
    let saveReceipt: ConfigurationLibrarySaveReceipt

    var aggregate: ConfigurationLibraryRecord {
        restoreReceipt.aggregate
    }
}
#endif
