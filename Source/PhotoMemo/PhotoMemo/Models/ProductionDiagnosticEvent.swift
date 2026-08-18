import Foundation
#if canImport(Darwin)
import Darwin
#endif

nonisolated enum ProductionDiagnosticCategory:
    String,
    Codable,
    Hashable,
    Sendable {

    case configuration
    case processing
    case rendering
    case export
    case photoLibrary
    case diagnostics
}

nonisolated enum ProductionDiagnosticOutcome:
    String,
    Codable,
    Hashable,
    Sendable {

    case started
    case succeeded
    case failed
    case degraded
    case cancelled
}

nonisolated enum ProductionDiagnosticErrorCode:
    String,
    Codable,
    Hashable,
    Sendable {

    case configurationCandidateInvalid =
        "configuration.candidate.invalid"
    case configurationSelectionMissing =
        "configuration.selection.missing"
    case configurationValidationFailed =
        "configuration.validation.failed"
    case configurationEncodingFailed =
        "configuration.encoding.failed"
    case configurationReadFailed =
        "configuration.read.failed"
    case configurationWriteFailed =
        "configuration.write.failed"
    case configurationWritePermissionDenied =
        "configuration.write.permissionDenied"
    case configurationWriteNoSpace =
        "configuration.write.noSpace"
    case configurationRevisionConflict =
        "configuration.revision.conflict"
    case configurationRevisionOverflow =
        "configuration.revision.overflow"
    case configurationCorrupted =
        "configuration.storage.corrupted"
    case configurationUnavailable =
        "configuration.service.unavailable"
    case configurationCompatibilityProjectionFailed =
        "configuration.compatibilityProjection.failed"
    case configurationReconciliationDeferred =
        "configuration.reconciliation.deferred"
    case processingImportFailed =
        "processing.import.failed"
    case processingSourceMissing =
        "processing.source.missing"
    case processingSourceUnreadable =
        "processing.source.unreadable"
    case processingCloudDownloadTimedOut =
        "processing.cloudDownload.timedOut"
    case processingDecodeFailed =
        "processing.decode.failed"
    case processingUnsupportedFormat =
        "processing.input.unsupportedFormat"
    case processingUnsupportedLivePhoto =
        "processing.input.unsupportedLivePhoto"
    case processingMissingPixelSize =
        "processing.input.missingPixelSize"
    case processingOversizedDimension =
        "processing.input.oversizedDimension"
    case processingOversizedPixelCount =
        "processing.input.oversizedPixelCount"
    case processingExtremeAspectRatio =
        "processing.input.extremeAspectRatio"
    case processingBackgroundExpired =
        "processing.background.expired"
    case processingBuildFailed =
        "processing.build.failed"
    case processingContentValidationFailed =
        "processing.contentValidation.failed"
    case processingRenderFailed =
        "processing.render.failed"
    case processingExportFailed =
        "processing.export.failed"
    case processingLivePhotoPreparationFailed =
        "processing.livePhoto.preparation.failed"
    case photoLibrarySaveFailed =
        "photoLibrary.save.failed"
    case photoLibraryUnauthorized =
        "photoLibrary.permission.denied"
    case photoLibraryAlbumNotFound =
        "photoLibrary.album.notFound"
    case photoLibraryAlbumCreateFailed =
        "photoLibrary.album.createFailed"
    case photoLibraryAssetSaveFailed =
        "photoLibrary.asset.saveFailed"
    case photoLibraryAssetReadbackPending =
        "photoLibrary.asset.readbackPending"
    case photoLibraryLivePhotoVerificationFailed =
        "photoLibrary.livePhoto.verificationFailed"
    case processingFailed =
        "processing.failed"
    case diagnosticsReadFailed =
        "diagnostics.read.failed"
    case diagnosticsWriteFailed =
        "diagnostics.write.failed"
    case diagnosticsExportFailed =
        "diagnostics.export.failed"
    case unexpected = "unexpected"
}

nonisolated struct ProductionDiagnosticSystemError:
    Codable,
    Hashable,
    Sendable {

    let domain: String
    let code: Int
}

nonisolated struct ProductionDiagnosticRegionMetric:
    Codable,
    Hashable,
    Sendable {

    let region: String
    let characterCount: Int
    let newlineCount: Int
}

nonisolated struct ProductionDiagnosticContext:
    Codable,
    Hashable,
    Sendable {

    let jobID: UUID?
    let taskID: UUID?
    let configurationID: UUID?
    let aggregateRevision: Int?
    let configurationRevision: Int?
    let subjectCount: Int?
    let configurationCount: Int?
    let itemCount: Int?
    let mediaContentTypeIdentifier: String?
    let mediaPixelWidth: Int?
    let mediaPixelHeight: Int?
    let processingPhase: String?
    let regionMetrics:
        [ProductionDiagnosticRegionMetric]

    init(
        jobID: UUID? = nil,
        taskID: UUID? = nil,
        configurationID: UUID? = nil,
        aggregateRevision: Int? = nil,
        configurationRevision: Int? = nil,
        subjectCount: Int? = nil,
        configurationCount: Int? = nil,
        itemCount: Int? = nil,
        mediaContentTypeIdentifier: String? = nil,
        mediaPixelWidth: Int? = nil,
        mediaPixelHeight: Int? = nil,
        processingPhase: String? = nil,
        regionMetrics:
            [ProductionDiagnosticRegionMetric] = []
    ) {
        self.jobID = jobID
        self.taskID = taskID
        self.configurationID = configurationID
        self.aggregateRevision = aggregateRevision
        self.configurationRevision = configurationRevision
        self.subjectCount = subjectCount
        self.configurationCount = configurationCount
        self.itemCount = itemCount
        self.mediaContentTypeIdentifier =
            mediaContentTypeIdentifier
        self.mediaPixelWidth = mediaPixelWidth
        self.mediaPixelHeight = mediaPixelHeight
        self.processingPhase = processingPhase
        self.regionMetrics = regionMetrics
    }
}

#if !PHOTOMEMO_SHARE_EXTENSION
nonisolated extension ProductionDiagnosticContext {

    static func configurationLibrary(
        _ aggregate: ConfigurationLibraryRecord
    ) -> Self {
        let activeConfiguration = aggregate.subjects
            .lazy
            .flatMap(\.configurations)
            .first {
                $0.id == aggregate.activeConfigurationID
            }
        return Self(
            configurationID: activeConfiguration?.id,
            aggregateRevision: aggregate.revision,
            configurationRevision:
                activeConfiguration?.revision,
            subjectCount: aggregate.subjects.count,
            configurationCount:
                aggregate.subjects.reduce(0) {
                    $0 + $1.configurations.count
                },
            regionMetrics:
                activeConfiguration.map {
                    regionMetrics(
                        for: $0.editor.template
                    )
                } ?? []
        )
    }

    private static func regionMetrics(
        for template: Template
    ) -> [ProductionDiagnosticRegionMetric] {
        [
            ("slotA", template.leftTopArea),
            ("slotB", template.leftBottomArea),
            ("slotC", template.rightTopArea),
            ("slotD", template.rightBottomArea)
        ]
        .map { region, area in
            let values = area.items
                .filter(\.isEnabled)
                .map(\.value)
            return ProductionDiagnosticRegionMetric(
                region: region,
                characterCount:
                    values.reduce(0) {
                        $0 + $1.count
                    },
                newlineCount:
                    values.reduce(0) { count, value in
                        count + value.filter {
                            $0.isNewline
                        }.count
                    }
            )
        }
    }
}
#endif

nonisolated struct ProductionDiagnosticEvent:
    Identifiable,
    Codable,
    Hashable,
    Sendable {

    let id: UUID
    let timestamp: Date
    let operationID: UUID
    let category: ProductionDiagnosticCategory
    let stage: String
    let outcome: ProductionDiagnosticOutcome
    let errorCode: ProductionDiagnosticErrorCode?
    let supportID: String?
    let systemError: ProductionDiagnosticSystemError?
    let durationMilliseconds: Int?
    let context: ProductionDiagnosticContext

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        operationID: UUID,
        category: ProductionDiagnosticCategory,
        stage: String,
        outcome: ProductionDiagnosticOutcome,
        errorCode: ProductionDiagnosticErrorCode? = nil,
        supportID: String? = nil,
        systemError: ProductionDiagnosticSystemError? = nil,
        durationMilliseconds: Int? = nil,
        context: ProductionDiagnosticContext = .init()
    ) {
        self.id = id
        self.timestamp = timestamp
        self.operationID = operationID
        self.category = category
        self.stage = stage
        self.outcome = outcome
        self.errorCode = errorCode
        self.supportID =
            supportID
            ?? errorCode.map { _ in
                ProductionDiagnosticSupportID.make(
                    prefix:
                        Self.supportPrefix(
                            for: category
                        ),
                    operationID: operationID
                )
            }
        self.systemError = systemError
        self.durationMilliseconds = durationMilliseconds
        self.context = context
    }

    private static func supportPrefix(
        for category:
            ProductionDiagnosticCategory
    ) -> String {
        switch category {
        case .configuration:
            return "CFG"
        case .processing,
             .rendering,
             .export,
             .photoLibrary:
            return "JOB"
        case .diagnostics:
            return "DIA"
        }
    }
}

nonisolated struct ProductionDiagnosticEnvironment:
    Codable,
    Hashable,
    Sendable {

    let appVersion: String
    let buildNumber: String
    let operatingSystem: String
    let deviceFamily: String

    static func current(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> Self {
        Self(
            appVersion:
                bundle.object(
                    forInfoDictionaryKey:
                        "CFBundleShortVersionString"
                ) as? String ?? "unknown",
            buildNumber:
                bundle.object(
                    forInfoDictionaryKey:
                        "CFBundleVersion"
                ) as? String ?? "unknown",
            operatingSystem:
                processInfo.operatingSystemVersionString,
            deviceFamily: currentDeviceFamily
        )
    }

    private static var currentDeviceFamily: String {
#if os(iOS)
        let identifier = hardwareIdentifier
        if identifier.hasPrefix("iPhone") {
            return "iPhone"
        }
        if identifier.hasPrefix("iPad") {
            return "iPad"
        }
        if identifier.hasPrefix("iPod") {
            return "iPod touch"
        }
        if identifier == "arm64"
            || identifier == "x86_64" {
            return "iOS Simulator"
        }
        return "iOS Device"
#elseif os(macOS)
        "Mac"
#else
        "Apple"
#endif
    }

#if canImport(Darwin)
    private static var hardwareIdentifier: String {
        var systemInfo = utsname()
        guard uname(&systemInfo) == 0 else {
            return "unknown"
        }
        return withUnsafePointer(
            to: &systemInfo.machine
        ) { pointer in
            pointer.withMemoryRebound(
                to: CChar.self,
                capacity: 1
            ) {
                String(cString: $0)
            }
        }
    }
#endif
}

nonisolated struct ProductionDiagnosticLegacyEventSummary:
    Codable,
    Hashable,
    Sendable {

    let timestamp: Date
    let stage: String
    let detail: String?
    let requestID: UUID?
    let jobID: UUID?
}

nonisolated struct ProductionDiagnosticReport:
    Codable,
    Hashable,
    Sendable {

    let schemaVersion: Int
    let generatedAt: Date
    let environment: ProductionDiagnosticEnvironment
    let events: [ProductionDiagnosticEvent]
    let legacyTimeline:
        [ProductionDiagnosticLegacyEventSummary]
}

nonisolated enum ProductionDiagnosticSupportID {

    static func make(
        prefix: String,
        operationID: UUID
    ) -> String {
        let compactID = operationID.uuidString
            .replacingOccurrences(of: "-", with: "")
            .prefix(12)
            .uppercased()
        return "\(prefix)-\(compactID)"
    }
}

nonisolated struct ProductionDiagnosticFailure:
    Hashable,
    Sendable {

    let code: ProductionDiagnosticErrorCode
    let supportID: String
    let userMessage: String
    let systemError: ProductionDiagnosticSystemError?
}

nonisolated enum ProductionDiagnosticFailureClassifier {

#if !PHOTOMEMO_SHARE_EXTENSION
    static func configurationSave(
        _ error: Error,
        operationID: UUID,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> ProductionDiagnosticFailure {
        let code: ProductionDiagnosticErrorCode

        if let persistenceError = error as?
            ConfigurationLibraryPersistenceError {
            switch persistenceError {
            case .validationFailed:
                code = .configurationValidationFailed
            case .missingActiveSelection:
                code = .configurationSelectionMissing
            case .encodingFailed:
                code = .configurationEncodingFailed
            case .readFailed:
                code = .configurationReadFailed
            case .writeFailed(let description):
                code = writeCode(
                    for: systemError(
                        fromPersistenceDescription:
                            description
                    )
                ) ?? .configurationWriteFailed
            case .staleAggregate:
                code = .configurationRevisionConflict
            case .revisionOverflow:
                code = .configurationRevisionOverflow
            case .noStoredAggregate,
                 .corruptedPrimaryAndLastKnownGood:
                code = .configurationCorrupted
            }
        } else if let photoMemoError = error as? PhotoMemoError {
            switch photoMemoError.code {
            case .configurationUnavailable:
                code = .configurationUnavailable
            case .persistenceReadFailed:
                code = .configurationReadFailed
            case .persistenceWriteFailed:
                code = .configurationWriteFailed
            default:
                code = .unexpected
            }
        } else {
            code = writeCode(
                for: systemError(for: error)
            )
                ?? .unexpected
        }

        return failure(
            code: code,
            prefix: "CFG",
            operationID: operationID,
            language: language,
            systemError:
                configurationSystemError(for: error)
        )
    }
#endif

    static func processing(
        phase: String,
        classification: String?,
        operationID: UUID,
        error: Error,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> ProductionDiagnosticFailure {
        let normalizedPhase = phase.lowercased()
        let normalizedClassification =
            classification?.lowercased() ?? ""
        let code: ProductionDiagnosticErrorCode

#if !PHOTOMEMO_SHARE_EXTENSION
        let contentValidationCode:
            ProductionDiagnosticErrorCode? =
            (error as? ProductionConfigurationContractError)
                == .emptyResolvedContent
            ? .processingContentValidationFailed
            : nil
#else
        let contentValidationCode:
            ProductionDiagnosticErrorCode? = nil
#endif

        if let contentValidationCode {
            code = contentValidationCode
        } else if let photoLibraryCode = photoLibraryCode(for: error) {
            code = photoLibraryCode
        } else if let mediaInputCode = mediaInputCode(
            for: error
        ) {
            code = mediaInputCode
        } else if normalizedPhase.contains("import")
            || normalizedPhase.contains("queued") {
            code = .processingImportFailed
        } else if normalizedPhase.contains("build")
                    || normalizedPhase.contains("prepar")
                    || normalizedPhase.contains("metadata")
                    || normalizedPhase.contains("preview") {
            code = .processingBuildFailed
        } else if normalizedPhase.contains("render") {
            code = .processingRenderFailed
        } else if normalizedPhase.contains("export")
                    || normalizedPhase.contains("waiting") {
            code = .processingExportFailed
        } else if normalizedPhase.contains("photo")
                    || normalizedClassification.contains("photo")
                    || normalizedClassification.contains("library") {
            code = .photoLibrarySaveFailed
        } else {
            code = .processingFailed
        }

        return failure(
            code: code,
            prefix: "JOB",
            operationID: operationID,
            language: language,
            systemError: systemError(for: error)
        )
    }

    private static func mediaInputCode(
        for error: Error
    ) -> ProductionDiagnosticErrorCode? {
        let diagnosticCode: String?
#if !PHOTOMEMO_SHARE_EXTENSION
        if let photoMemoError = error as? PhotoMemoError {
            diagnosticCode = photoMemoError.diagnosticCode
        } else if let importError = error as? PhotoImportError {
            diagnosticCode = importError.diagnosticCode
        } else {
            diagnosticCode = nil
        }
#else
        if let importError = error as? PhotoImportError {
            diagnosticCode = importError.diagnosticCode
        } else {
            diagnosticCode = nil
        }
#endif

        switch diagnosticCode {
        case "sourceMissing":
            return .processingSourceMissing
        case "sourceUnreadable":
            return .processingSourceUnreadable
        case "cloudDownloadTimedOut":
            return .processingCloudDownloadTimedOut
        case "imageLoadFailed",
             "rawDisplayRenderFailed":
            return .processingDecodeFailed
        case PhotoProcessingInputPolicy.RejectionReason
            .unsupportedFormat.rawValue:
            return .processingUnsupportedFormat
        case PhotoProcessingInputPolicy.RejectionReason
            .livePhoto.rawValue:
            return .processingUnsupportedLivePhoto
        case PhotoProcessingInputPolicy.RejectionReason
            .missingPixelSize.rawValue:
            return .processingMissingPixelSize
        case PhotoProcessingInputPolicy.RejectionReason
            .oversizedPixelDimension.rawValue:
            return .processingOversizedDimension
        case PhotoProcessingInputPolicy.RejectionReason
            .oversizedPixelCount.rawValue:
            return .processingOversizedPixelCount
        case PhotoProcessingInputPolicy.RejectionReason
            .extremeAspectRatio.rawValue:
            return .processingExtremeAspectRatio
        default:
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain,
               nsError.code == NSFileNoSuchFileError {
                return .processingSourceMissing
            }
            return nil
        }
    }

    private static func photoLibraryCode(
        for error: Error
    ) -> ProductionDiagnosticErrorCode? {
#if !PHOTOMEMO_SHARE_EXTENSION
        if let livePhotoError =
            error as? LivePhotoAssetWritingError {
            switch livePhotoError {
            case .unauthorized:
                return .photoLibraryUnauthorized
            case .albumNotFound:
                return .photoLibraryAlbumNotFound
            case .albumCreateFailed:
                return .photoLibraryAlbumCreateFailed
            case .savedAssetReadbackPending:
                return .photoLibraryAssetReadbackPending
            case .savedAssetReadbackFailed,
                 .savedAssetNotLivePhoto:
                return .photoLibraryLivePhotoVerificationFailed
            case .photoLibraryWritesDisabledByRuntimeGate,
                 .stillPhotoFileMissing,
                 .pairedVideoFileMissing,
                 .outputFilenameBaseMismatch,
                 .pairingIdentityVerificationFailed:
                return .processingLivePhotoPreparationFailed
            case .assetSaveFailed:
                return .photoLibraryAssetSaveFailed
            }
        }
        if let diagnosticCode =
            (error as? PhotoMemoError)?
            .diagnosticCode,
           let code =
            ProductionDiagnosticErrorCode(
                rawValue: diagnosticCode
            ),
           code == .photoLibraryUnauthorized
            || code == .photoLibraryAlbumNotFound
            || code == .photoLibraryAlbumCreateFailed
            || code == .photoLibraryAssetSaveFailed
            || code == .photoLibraryAssetReadbackPending {
            return code
        }
        guard let exportError =
            error as? PhotoLibraryExportError else {
            return nil
        }
        switch exportError {
        case .unauthorized:
            return .photoLibraryUnauthorized
        case .albumNotFound:
            return .photoLibraryAlbumNotFound
        case .albumCreateFailed:
            return .photoLibraryAlbumCreateFailed
        case .assetSaveFailed:
            return .photoLibraryAssetSaveFailed
        case .savedAssetReadbackPending:
            return .photoLibraryAssetReadbackPending
        }
#else
        return nil
#endif
    }

    static func compatibilityProjection(
        operationID: UUID,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> ProductionDiagnosticFailure {
        failure(
            code:
                .configurationCompatibilityProjectionFailed,
            prefix: "CFG",
            operationID: operationID,
            language: language,
            systemError: nil
        )
    }

    static func candidateConstruction(
        _ error: Error,
        operationID: UUID,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> ProductionDiagnosticFailure {
        failure(
            code: .configurationCandidateInvalid,
            prefix: "CFG",
            operationID: operationID,
            language: language,
            systemError: systemError(for: error)
        )
    }

    static func diagnosticsExport(
        _ error: Error,
        operationID: UUID,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> ProductionDiagnosticFailure {
        failure(
            code: .diagnosticsExportFailed,
            prefix: "DIA",
            operationID: operationID,
            language: language,
            systemError: systemError(for: error)
        )
    }

    private static func writeCode(
        for systemError:
            ProductionDiagnosticSystemError?
    ) -> ProductionDiagnosticErrorCode? {
        guard let systemError else {
            return nil
        }
        if systemError.domain == NSCocoaErrorDomain {
            switch systemError.code {
            case NSFileWriteNoPermissionError,
                 NSFileReadNoPermissionError,
                 NSFileWriteVolumeReadOnlyError:
                return .configurationWritePermissionDenied
            case NSFileWriteOutOfSpaceError:
                return .configurationWriteNoSpace
            default:
                return nil
            }
        }
#if canImport(Darwin)
        if systemError.domain == NSPOSIXErrorDomain {
            switch Int32(systemError.code) {
            case ENOSPC:
                return .configurationWriteNoSpace
            case EACCES, EPERM, EROFS:
                return .configurationWritePermissionDenied
            default:
                return nil
            }
        }
#endif
        return nil
    }

    private static func systemError(
        fromPersistenceDescription description: String
    ) -> ProductionDiagnosticSystemError? {
        let structuredPattern = #"domain=([^;]+);code=(-?\d+)"#
        if let structuredExpression = try? NSRegularExpression(
            pattern: structuredPattern
        ) {
            let structuredRange = NSRange(
                description.startIndex..<description.endIndex,
                in: description
            )
            if let match = structuredExpression.firstMatch(
                in: description,
                range: structuredRange
            ),
            let domainRange = Range(
                match.range(at: 1),
                in: description
            ),
            let codeRange = Range(
                match.range(at: 2),
                in: description
            ),
            let code = Int(description[codeRange]) {
                return ProductionDiagnosticSystemError(
                    domain: String(description[domainRange]),
                    code: code
                )
            }
        }
        let pattern = #"Error Domain=([^\s]+) Code=(-?\d+)"#
        guard let expression = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return nil
        }
        let range = NSRange(
            description.startIndex..<description.endIndex,
            in: description
        )
        guard let match = expression.firstMatch(
            in: description,
            range: range
        ),
        let domainRange = Range(
            match.range(at: 1),
            in: description
        ),
        let codeRange = Range(
            match.range(at: 2),
            in: description
        ),
        let code = Int(description[codeRange]) else {
            return nil
        }
        return ProductionDiagnosticSystemError(
            domain: String(description[domainRange]),
            code: code
        )
    }

#if !PHOTOMEMO_SHARE_EXTENSION
    private static func configurationSystemError(
        for error: Error
    ) -> ProductionDiagnosticSystemError {
        guard let persistenceError = error as?
            ConfigurationLibraryPersistenceError else {
            return systemError(for: error)
        }
        let description: String?
        switch persistenceError {
        case .encodingFailed(let value),
             .readFailed(let value),
             .writeFailed(let value):
            description = value
        default:
            description = nil
        }
        return description.flatMap {
            systemError(
                fromPersistenceDescription: $0
            )
        } ?? systemError(for: error)
    }
#endif

    private static func systemError(
        for error: Error
    ) -> ProductionDiagnosticSystemError {
        let nsError = error as NSError
        return ProductionDiagnosticSystemError(
            domain: nsError.domain,
            code: nsError.code
        )
    }

    private static func failure(
        code: ProductionDiagnosticErrorCode,
        prefix: String,
        operationID: UUID,
        language: MemoMarkLanguage,
        systemError: ProductionDiagnosticSystemError?
    ) -> ProductionDiagnosticFailure {
        let supportID = ProductionDiagnosticSupportID.make(
            prefix: prefix,
            operationID: operationID
        )
        let guidance = userGuidance(
            for: code,
            language: language
        )
        let userMessage: String
        if language == .simplifiedChinese {
            userMessage =
                "\(guidance.reason)\(guidance.recovery)（故障编号：\(supportID)）"
        } else {
            userMessage =
                "\(guidance.reason) \(guidance.recovery) (Support ID: \(supportID))"
        }
        return ProductionDiagnosticFailure(
            code: code,
            supportID: supportID,
            userMessage: userMessage,
            systemError: systemError
        )
    }

    private static func userGuidance(
        for code: ProductionDiagnosticErrorCode,
        language: MemoMarkLanguage
    ) -> (reason: String, recovery: String) {
        if language == .english {
            return englishUserGuidance(for: code)
        }
        switch code {
        case .configurationCandidateInvalid,
             .configurationValidationFailed:
            return (
                "配置中有无法保存的关联信息。",
                "请返回检查当前记忆对象、预设与时间锚点后重试。"
            )
        case .configurationSelectionMissing:
            return (
                "当前没有可保存的记忆对象或预设。",
                "请先完成选择后再保存。"
            )
        case .configurationRevisionConflict:
            return (
                "保存期间检测到其他修改。",
                "请确认当前内容后再次保存。"
            )
        case .configurationEncodingFailed:
            return (
                "配置内容暂时无法整理为可保存的数据。",
                "请重新打开当前页面后重试。"
            )
        case .configurationReadFailed:
            return (
                "读取已有配置时遇到问题。",
                "请重新打开 MemoMark 后再试。"
            )
        case .configurationWritePermissionDenied:
            return (
                "系统不允许写入配置存储。",
                "请重新打开 MemoMark；若仍失败，请导出诊断信息反馈。"
            )
        case .configurationWriteNoSpace:
            return (
                "设备可用存储空间不足。",
                "请释放一些空间后重试。"
            )
        case .configurationWriteFailed:
            return (
                "系统未能把配置写入设备存储。",
                "请确认设备仍有可用空间后重试。"
            )
        case .configurationCorrupted:
            return (
                "已有配置数据无法完整读取。",
                "请先导出诊断信息，再尝试从配置备份恢复。"
            )
        case .configurationRevisionOverflow:
            return (
                "配置版本已达到系统可处理的上限。",
                "请导出诊断信息并联系支持。"
            )
        case .configurationUnavailable:
            return (
                "保存服务尚未准备好。",
                "请重新打开 MemoMark 后再试。"
            )
        case .configurationCompatibilityProjectionFailed:
            return (
                "配置已保存，但处理服务未能同步到最新内容。",
                "请重新打开 MemoMark 后再试；再次处理前请确认当前配置。"
            )
        case .configurationReconciliationDeferred:
            return (
                "配置已保存，同时保留了你刚刚继续做的修改。",
                "请再次保存以应用最新内容。"
            )
        case .processingImportFailed:
            return (
                "无法读取这张照片或实况照片。",
                "请确认照片仍可在系统图库中打开后重试。"
            )
        case .processingSourceMissing:
            return (
                "接收的照片副本已不可用。",
                "请从 Apple Photos 重新分享这张照片。"
            )
        case .processingSourceUnreadable:
            return (
                "系统无法读取接收的照片文件。",
                "请确认原图可在 Apple Photos 中打开后重新分享。"
            )
        case .processingCloudDownloadTimedOut:
            return (
                "原图尚未从 iCloud 完成下载。",
                "请先在 Apple Photos 打开原图，等待下载完成后再分享。"
            )
        case .processingDecodeFailed:
            return (
                "照片文件存在，但无法完整解码。",
                "文件可能不完整或已损坏，请重新分享原图。"
            )
        case .processingUnsupportedFormat:
            return (
                "当前版本暂不支持这种图片格式。",
                "请使用 JPEG、HEIC、PNG、TIFF 或受支持的 RAW 原图。"
            )
        case .processingUnsupportedLivePhoto:
            return (
                "系统本次没有提供实况照片的动态部分。",
                "请先在 Apple Photos 打开原片，等待 iCloud 下载完成并确认 MemoMark 可读取该照片后重新分享；若只需静态图片，可在输出设置选择“静态图片”。"
            )
        case .processingMissingPixelSize:
            return (
                "无法读取这张照片的像素尺寸。",
                "文件可能不完整，请重新分享原图。"
            )
        case .processingOversizedDimension:
            return (
                "照片单边尺寸超过当前处理范围。",
                "请先导出为单边不超过 8064 像素的版本。"
            )
        case .processingOversizedPixelCount:
            return (
                "照片总像素超过当前处理范围。",
                "请先导出为约 48MP 以内的版本。"
            )
        case .processingExtremeAspectRatio:
            return (
                "当前版本暂不处理全景图、长截图或特别细长的图片。",
                "请裁切为 3:1 以内的标准照片比例后重试。"
            )
        case .processingBackgroundExpired:
            return (
                "系统结束了本次后台处理时间。",
                "任务会保留并等待下次继续；也可以打开 MemoMark 继续处理。"
            )
        case .processingBuildFailed:
            return (
                "照片内容准备失败。",
                "请重新选择照片后再试。"
            )
        case .processingContentValidationFailed:
            return (
                MemoMarkLanguage.interfaceStored.localized(
                    key: "Batch.ContentValidation.Failed.Title",
                    fallback: "照片缺少当前配置需要的拍摄信息。"
                ),
                MemoMarkLanguage.interfaceStored.localized(
                    key: "Batch.ContentValidation.Failed.Recovery",
                    fallback: "请检查当前预设使用的内容，或选择包含这些信息的照片后重试。"
                )
            )
        case .processingRenderFailed:
            return (
                "回忆卡片绘制失败。",
                "请降低同时处理的照片数量后重试。"
            )
        case .processingExportFailed:
            return (
                "生成输出文件时失败。",
                "请确认设备存储空间后重试。"
            )
        case .processingLivePhotoPreparationFailed:
            return (
                "实况照片的静态部分与动态部分未能安全配对。",
                "请从 Apple Photos 重新分享原始实况照片；若再次失败，请导出诊断信息。"
            )
        case .photoLibrarySaveFailed:
            return (
                "无法把结果保存到系统图库。",
                "请检查照片权限和设备存储空间后重试。"
            )
        case .photoLibraryUnauthorized:
            return (
                "MemoMark 没有系统图库写入权限。",
                "请在系统设置中允许照片访问后重试。"
            )
        case .photoLibraryAlbumNotFound:
            return (
                "之前选择的相册已不存在。",
                "请刷新相册列表并重新选择。"
            )
        case .photoLibraryAlbumCreateFailed:
            return (
                "系统未能创建目标相册。",
                "请确认照片权限和存储空间后重试。"
            )
        case .photoLibraryAssetSaveFailed:
            return (
                "图片已生成，但写入系统图库失败。",
                "请确认照片权限和设备存储空间后重试。"
            )
        case .photoLibraryAssetReadbackPending:
            return (
                "系统图库仍在确认这张照片。",
                "请稍后重试；时光记不会在结果未确认时重复保存。"
            )
        case .photoLibraryLivePhotoVerificationFailed:
            return (
                "系统没有把处理结果保留为实况照片。",
                "本次不会按静态图片报成功；请确认原片动态效果可用后重试，若再次失败请导出诊断信息。"
            )
        case .processingFailed:
            return (
                "照片处理未能完成。",
                "请重试；若再次失败，请导出诊断信息反馈。"
            )
        case .diagnosticsReadFailed,
             .diagnosticsWriteFailed,
             .diagnosticsExportFailed:
            return (
                "诊断信息暂时无法准备。",
                "请重新打开 MemoMark 后再试。"
            )
        case .unexpected:
            return (
                "遇到了尚未识别的问题。",
                "请重试；若再次失败，请导出诊断信息反馈。"
            )
        }
    }

    private static func englishUserGuidance(
        for code: ProductionDiagnosticErrorCode
    ) -> (reason: String, recovery: String) {
        switch code {
        case .configurationCandidateInvalid,
             .configurationValidationFailed:
            return (
                "Some linked configuration information cannot be saved.",
                "Check the current memory subject, preset, and time anchor, then try again."
            )
        case .configurationSelectionMissing:
            return (
                "There is no memory subject or preset to save.",
                "Make a selection before saving."
            )
        case .configurationRevisionConflict:
            return (
                "Another change was detected while saving.",
                "Review the current content and save again."
            )
        case .configurationEncodingFailed:
            return (
                "The configuration could not be prepared for storage.",
                "Reopen this page and try again."
            )
        case .configurationReadFailed:
            return (
                "The saved configuration could not be read.",
                "Reopen MemoMark and try again."
            )
        case .configurationWritePermissionDenied:
            return (
                "The system denied access to configuration storage.",
                "Reopen MemoMark; if it still fails, export diagnostics for support."
            )
        case .configurationWriteNoSpace:
            return (
                "The device does not have enough available storage.",
                "Free some space and try again."
            )
        case .configurationWriteFailed:
            return (
                "The configuration could not be written to device storage.",
                "Check available storage and try again."
            )
        case .configurationCorrupted:
            return (
                "The saved configuration data could not be read completely.",
                "Export diagnostics first, then restore a configuration backup."
            )
        case .configurationRevisionOverflow:
            return (
                "The configuration version reached the supported limit.",
                "Export diagnostics and contact support."
            )
        case .configurationUnavailable:
            return (
                "The save service is not ready.",
                "Reopen MemoMark and try again."
            )
        case .configurationCompatibilityProjectionFailed:
            return (
                "The configuration was saved, but processing did not receive the latest content.",
                "Reopen MemoMark and confirm the current configuration before processing again."
            )
        case .configurationReconciliationDeferred:
            return (
                "The configuration was saved while your newer edits were kept.",
                "Save once more to apply the latest content."
            )
        case .processingImportFailed:
            return (
                "This photo or Live Photo could not be read.",
                "Confirm it still opens in Photos, then try again."
            )
        case .processingSourceMissing:
            return (
                "The received photo copy is no longer available.",
                "Share the photo again from Apple Photos."
            )
        case .processingSourceUnreadable:
            return (
                "The system could not read the received photo file.",
                "Confirm the original opens in Apple Photos, then share it again."
            )
        case .processingCloudDownloadTimedOut:
            return (
                "The original photo did not finish downloading from iCloud.",
                "Open it in Apple Photos, wait for the download, then share it again."
            )
        case .processingDecodeFailed:
            return (
                "The photo file exists but could not be decoded completely.",
                "It may be incomplete or damaged; share the original again."
            )
        case .processingUnsupportedFormat:
            return (
                "This image format is not supported in the current version.",
                "Use a JPEG, HEIC, PNG, TIFF, or supported RAW original."
            )
        case .processingUnsupportedLivePhoto:
            return (
                "The system did not provide the motion part of this Live Photo.",
                "Open the original in Apple Photos, wait for its iCloud download, confirm MemoMark can read it, then share it again. If you only need a still image, choose Static Image in Output settings."
            )
        case .processingMissingPixelSize:
            return (
                "The photo's pixel dimensions could not be read.",
                "The file may be incomplete; share the original again."
            )
        case .processingOversizedDimension:
            return (
                "One side of the photo exceeds the current processing limit.",
                "Export a version no larger than 8064 pixels on either side."
            )
        case .processingOversizedPixelCount:
            return (
                "The photo exceeds the current total-pixel limit.",
                "Export a version of about 48 MP or less."
            )
        case .processingExtremeAspectRatio:
            return (
                "Panoramas, long screenshots, and unusually narrow images are not currently processed.",
                "Crop the photo to an aspect ratio within 3:1 and try again."
            )
        case .processingBackgroundExpired:
            return (
                "The system ended this background processing window.",
                "The task remains available for the next run, or open MemoMark to continue."
            )
        case .processingBuildFailed:
            return (
                "The photo content could not be prepared.",
                "Select the photo again and retry."
            )
        case .processingContentValidationFailed:
            return (
                MemoMarkLanguage.interfaceStored.localized(
                    key: "Batch.ContentValidation.Failed.Title",
                    fallback: "This photo is missing information required by the current preset."
                ),
                MemoMarkLanguage.interfaceStored.localized(
                    key: "Batch.ContentValidation.Failed.Recovery",
                    fallback: "Check the current preset content, or choose a photo that contains the required information and retry."
                )
            )
        case .processingRenderFailed:
            return (
                "The memory card could not be rendered.",
                "Process fewer photos at once and try again."
            )
        case .processingExportFailed:
            return (
                "The output file could not be created.",
                "Check available storage and try again."
            )
        case .processingLivePhotoPreparationFailed:
            return (
                "The still and motion parts of the Live Photo could not be paired safely.",
                "Share the original Live Photo again from Apple Photos; export diagnostics if it repeats."
            )
        case .photoLibrarySaveFailed:
            return (
                "The result could not be saved to Photos.",
                "Check Photos access and available storage, then try again."
            )
        case .photoLibraryUnauthorized:
            return (
                "MemoMark does not have permission to write to Photos.",
                "Allow Photos access in Settings, then try again."
            )
        case .photoLibraryAlbumNotFound:
            return (
                "The selected album no longer exists.",
                "Refresh the album list and choose another album."
            )
        case .photoLibraryAlbumCreateFailed:
            return (
                "The destination album could not be created.",
                "Check Photos access and available storage, then try again."
            )
        case .photoLibraryAssetSaveFailed:
            return (
                "The image was created but could not be written to Photos.",
                "Check Photos access and available storage, then try again."
            )
        case .photoLibraryAssetReadbackPending:
            return (
                "Photos is still confirming this image.",
                "Try again shortly; MemoMark will not save a duplicate while the result is unknown."
            )
        case .photoLibraryLivePhotoVerificationFailed:
            return (
                "Photos did not preserve the processed result as a Live Photo.",
                "MemoMark will not report a still image as success. Confirm the original motion is available and try again; export diagnostics if it repeats."
            )
        case .processingFailed:
            return (
                "Photo processing did not finish.",
                "Try again; if it fails again, export diagnostics for support."
            )
        case .diagnosticsReadFailed,
             .diagnosticsWriteFailed,
             .diagnosticsExportFailed:
            return (
                "Diagnostics could not be prepared.",
                "Reopen MemoMark and try again."
            )
        case .unexpected:
            return (
                "MemoMark encountered an unrecognized problem.",
                "Try again; if it fails again, export diagnostics for support."
            )
        }
    }
}
