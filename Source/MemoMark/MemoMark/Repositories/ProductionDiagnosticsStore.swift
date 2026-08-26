import Foundation

nonisolated enum ProductionDiagnosticsStoreError:
    Error,
    Sendable {

    case corrupted
}

actor ProductionDiagnosticsStore {

    nonisolated static let shared =
        ProductionDiagnosticsStore(
            directoryURL:
                MemoMarkSharedContainer
                .baseDirectoryURL
                .appendingPathComponent(
                    "ProductionDiagnostics",
                    isDirectory: true
                )
        )

    private let directoryURL: URL
    private let primaryURL: URL
    private let lastKnownGoodURL: URL
    private let maximumEventCount: Int
    private var cachedEvents:
        [ProductionDiagnosticEvent]?

    init(
        directoryURL: URL,
        maximumEventCount: Int = 512
    ) {
        self.directoryURL = directoryURL
        self.primaryURL = directoryURL
            .appendingPathComponent("events.json")
        self.lastKnownGoodURL = directoryURL
            .appendingPathComponent(
                "events-last-known-good.json"
            )
        self.maximumEventCount = max(
            maximumEventCount,
            1
        )
    }

    func record(
        _ event: ProductionDiagnosticEvent
    ) throws {
        let previousEvents: [ProductionDiagnosticEvent]
        let recoveredFromCorruption: Bool
        do {
            previousEvents = try loadEvents()
            recoveredFromCorruption = false
        } catch ProductionDiagnosticsStoreError.corrupted {
            cachedEvents = []
            previousEvents = []
            recoveredFromCorruption = true
        }
        let recoveryEvents = recoveredFromCorruption
            ? [
                ProductionDiagnosticEvent(
                    operationID: event.operationID,
                    category: .diagnostics,
                    stage: "diagnostics.storageRecovery",
                    outcome: .degraded,
                    errorCode: .diagnosticsReadFailed
                )
            ]
            : []
        let nextEvents = Array(
            (previousEvents + recoveryEvents + [event])
                .suffix(maximumEventCount)
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        if !previousEvents.isEmpty {
            try encoded(previousEvents).write(
                to: lastKnownGoodURL,
                options: .atomic
            )
        }
        try encoded(nextEvents).write(
            to: primaryURL,
            options: .atomic
        )
        cachedEvents = nextEvents
    }

    func loadEvents()
    throws -> [ProductionDiagnosticEvent] {
        if let cachedEvents {
            return cachedEvents
        }

        if let primaryData = try dataIfPresent(
            at: primaryURL
        ),
           let events = decoded(primaryData) {
            cachedEvents = events
            return events
        }

        if let recoveryData = try dataIfPresent(
            at: lastKnownGoodURL
        ),
           let events = decoded(recoveryData) {
            cachedEvents = events
            return events
        }

        let hasPrimary = FileManager.default
            .fileExists(atPath: primaryURL.path)
        let hasRecovery = FileManager.default
            .fileExists(atPath: lastKnownGoodURL.path)
        guard !hasPrimary && !hasRecovery else {
            throw ProductionDiagnosticsStoreError.corrupted
        }
        cachedEvents = []
        return []
    }

    func makeExport(
        metadata: ProductionDiagnosticEnvironment,
        legacyEvents: [MemoMarkShareDiagnosticEvent],
        exportDirectoryURL: URL =
            FileManager.default.temporaryDirectory
    ) throws -> URL {
        let report = ProductionDiagnosticReport(
            schemaVersion: 1,
            generatedAt: Date(),
            environment: metadata,
            events: try loadEvents(),
            legacyTimeline:
                legacyEvents.map {
                    ProductionDiagnosticLegacyEventSummary(
                        timestamp: $0.timestamp,
                        stage: $0.stage.rawValue,
                        detail:
                            Self.safeLegacyDetail(
                                for: $0
                            ),
                        requestID: $0.requestID,
                        jobID: $0.jobID
                    )
                }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        try FileManager.default.createDirectory(
            at: exportDirectoryURL,
            withIntermediateDirectories: true
        )
        let exportURL = exportDirectoryURL
            .appendingPathComponent(
                "MemoMark-Diagnostics-\(Self.exportTimestamp()).json"
            )
        try encoder.encode(report).write(
            to: exportURL,
            options: .atomic
        )
        return exportURL
    }

    private static func safeLegacyDetail(
        for event: MemoMarkShareDiagnosticEvent
    ) -> String? {
        func isBoolean(_ value: String) -> Bool {
            value == "true" || value == "false"
        }

        func isInteger(_ value: String) -> Bool {
            Int(value) != nil
        }

        func isSafeIdentifier(_ value: String) -> Bool {
            !value.isEmpty
                && value.count <= 80
                && value.allSatisfy {
                    $0.isASCII
                    && ($0.isLetter
                        || $0.isNumber
                        || $0 == "."
                        || $0 == "-"
                        || $0 == "_")
                }
        }

        func isResult(_ value: String) -> Bool {
            [
                "matched",
                "notFound",
                "ambiguous",
                "unavailable",
                "verified",
                "invalid",
                "failed"
            ].contains(value)
        }

        func isReadbackReason(_ value: String) -> Bool {
            value == "invalidLivePhotoContract"
                || value == "assetUnavailable"
        }

        let validators:
            [String: (String) -> Bool]
        switch event.stage.rawValue {
        case MemoMarkShareDiagnosticStage
            .appLivePhotoIdentityRecovery
            .rawValue:
            validators = [
                "result": isResult,
                "candidateCount": isInteger,
                "motionUnavailable": isBoolean,
                "assetIdentifierRecovered": isBoolean
            ]
        case MemoMarkShareDiagnosticStage
            .extensionLivePhotoRepresentationStaticPayload
            .rawValue:
            validators = [
                "index": isInteger,
                "requestedType": isSafeIdentifier,
                "contentType": isSafeIdentifier,
                "managedPayload": isSafeIdentifier,
                "pathExtension": isSafeIdentifier,
                "hasStillImage": isBoolean,
                "hasPairedMovie": isBoolean,
                "stillCandidateCount": isInteger,
                "movieCandidateCount": isInteger,
                "basenameMatches": isBoolean,
                "routeWillFallbackToStaticWithoutAssetIdentity": isBoolean
            ]
        case MemoMarkShareDiagnosticStage
            .extensionProviderLoadTimedOut
            .rawValue:
            validators = [
                "operation": isSafeIdentifier,
                "providerIndex": isInteger,
                "requestedType": isSafeIdentifier
            ]
        case MemoMarkShareDiagnosticStage
            .livePhotoAssetReadback
            .rawValue:
            validators = [
                "result": isResult,
                "attempt": isInteger,
                "attempts": isInteger,
                "livePhoto": isBoolean,
                "stillResource": isBoolean,
                "pairedVideoResource": isBoolean,
                "positiveDuration": isBoolean,
                "positivePixelSize": isBoolean,
                "errorCode": isInteger,
                "reason": isReadbackReason
            ]
        default:
            return nil
        }

        return event.message
            .split(separator: ",")
            .compactMap { component in
                let parts = component
                    .split(
                        separator: "=",
                        maxSplits: 1
                    )
                guard parts.count == 2 else {
                    return nil
                }
                let key =
                    parts[0]
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                let value =
                    parts[1]
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                guard let validator = validators[key],
                      validator(value) else {
                    return nil
                }
                return "\(key)=\(value)"
            }
            .joined(separator: ", ")
    }

    private func encoded(
        _ events: [ProductionDiagnosticEvent]
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(events)
    }

    private func decoded(
        _ data: Data
    ) -> [ProductionDiagnosticEvent]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(
            [ProductionDiagnosticEvent].self,
            from: data
        )
    }

    private func dataIfPresent(
        at url: URL
    ) throws -> Data? {
        guard FileManager.default.fileExists(
            atPath: url.path
        ) else {
            return nil
        }
        return try Data(contentsOf: url)
    }

    nonisolated private static func exportTimestamp()
    -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
