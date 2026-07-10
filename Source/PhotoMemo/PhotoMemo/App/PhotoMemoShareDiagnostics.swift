import Foundation
import UniformTypeIdentifiers

struct PhotoMemoShareDiagnosticStage:
    RawRepresentable,
    Hashable,
    Codable,
    Sendable {

    let rawValue: String

    nonisolated init(
        rawValue: String
    ) {
        self.rawValue = rawValue
    }

    nonisolated static let start =
        Self(rawValue: "start")

    nonisolated static let appDrain =
        Self(rawValue: "app.drain")
    nonisolated static let appEnqueueCreated =
        Self(rawValue: "app.enqueue.created")
    nonisolated static let appEnqueueFailed =
        Self(rawValue: "app.enqueue.failed")
    nonisolated static let appOpenURLFile =
        Self(rawValue: "app.openURL.file")
    nonisolated static let appOpenURLShare =
        Self(rawValue: "app.openURL.share")
    nonisolated static let appPickerItemObserved =
        Self(rawValue: "app.picker.itemObserved")
    nonisolated static let appRequestDropped =
        Self(rawValue: "app.request.dropped")
    nonisolated static let appRequestValidated =
        Self(rawValue: "app.request.validated")
    nonisolated static let appEnqueueTaskRoute =
        Self(rawValue: "app.enqueue.taskRoute")
    nonisolated static let batchTaskRoute =
        Self(rawValue: "batch.task.route")
    nonisolated static let batchTaskDuration =
        Self(rawValue: "batch.task.duration")

    nonisolated static let extensionError =
        Self(rawValue: "extension.error")
    nonisolated static let extensionErrorUnexpected =
        Self(rawValue: "extension.error.unexpected")
    nonisolated static let extensionHandoffConfirmed =
        Self(rawValue: "extension.handoff.confirmed")
    nonisolated static let extensionHandoffFailed =
        Self(rawValue: "extension.handoff.failed")
    nonisolated static let extensionHandoffFallback =
        Self(rawValue: "extension.handoff.fallback")
    nonisolated static let extensionHandoffPrimary =
        Self(rawValue: "extension.handoff.primary")
    nonisolated static let extensionHandoffRequested =
        Self(rawValue: "extension.handoff.requested")
    nonisolated static let extensionHandoffUnconfirmed =
        Self(rawValue: "extension.handoff.unconfirmed")
    nonisolated static let extensionInput =
        Self(rawValue: "extension.input")
    nonisolated static let extensionInputEmpty =
        Self(rawValue: "extension.input.empty")
    nonisolated static let extensionInputTooManyPhotos =
        Self(rawValue: "extension.input.tooManyPhotos")
    nonisolated static let extensionItemFailed =
        Self(rawValue: "extension.item.failed")
    nonisolated static let extensionItemImported =
        Self(rawValue: "extension.item.imported")
    nonisolated static let extensionItemSkipped =
        Self(rawValue: "extension.item.skipped")
    nonisolated static let extensionLivePhotoRepresentationProbe =
        Self(rawValue: "extension.livePhotoRepresentation.probe")
    nonisolated static let extensionPersisted =
        Self(rawValue: "extension.persisted")
    nonisolated static let extensionProviderObserved =
        Self(rawValue: "extension.provider.observed")
    nonisolated static let extensionRequestCreated =
        Self(rawValue: "extension.request.created")
    nonisolated static let extensionRequestPersisted =
        Self(rawValue: "extension.request.persisted")
    nonisolated static let extensionSourcePrepare =
        Self(rawValue: "extension.source.prepare")
    nonisolated static let extensionSourceReady =
        Self(rawValue: "extension.source.ready")
    nonisolated static let extensionSourceUnavailable =
        Self(rawValue: "extension.source.unavailable")

    nonisolated static let liveActivityDisabled =
        Self(rawValue: "liveActivity.disabled")
    nonisolated static let liveActivityPayloadTerminal =
        Self(rawValue: "liveActivity.payload.terminal")
    nonisolated static let liveActivityRequestCreated =
        Self(rawValue: "liveActivity.request.created")
    nonisolated static let liveActivityRequestFailed =
        Self(rawValue: "liveActivity.request.failed")
    nonisolated static let livePhotoVideoCompositionGeometry =
        Self(rawValue: "livePhoto.videoComposition.geometry")
    nonisolated static let livePhotoAssetResourcesObserved =
        Self(rawValue: "livePhoto.assetResources.observed")
    nonisolated static let livePhotoAssetResourceExportFailed =
        Self(rawValue: "livePhoto.assetResource.exportFailed")
}

struct PhotoMemoShareDiagnosticEvent:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID

    let timestamp: Date

    let stage:
        PhotoMemoShareDiagnosticStage

    let message: String

    let requestID: UUID?

    let jobID: UUID?

    nonisolated init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        stage: PhotoMemoShareDiagnosticStage,
        message: String,
        requestID: UUID? = nil,
        jobID: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.stage = stage
        self.message = message
        self.requestID = requestID
        self.jobID = jobID
    }
}

enum PhotoMemoShareDiagnostics {

    nonisolated private static let storageKey =
        "photomemo.shareDiagnostics.events"

    nonisolated private static let maxEventCount = 80

    nonisolated static func reset(
        reason: String
    ) {

        _ = resetResult(
            reason: reason
        )
    }

    nonisolated static func resetResult(
        reason: String,
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults,
        encode:
            ([PhotoMemoShareDiagnosticEvent]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> PhotoMemoSharedDefaultsWriteResult {

        persistResult(
            [
                PhotoMemoShareDiagnosticEvent(
                    stage: .start,
                    message: reason
                )
            ],
            defaults: defaults,
            encode: encode
        )
    }

    nonisolated static func record(
        stage: PhotoMemoShareDiagnosticStage,
        message: String,
        requestID: UUID? = nil,
        jobID: UUID? = nil
    ) {

        _ = recordResult(
            stage: stage,
            message: message,
            requestID: requestID,
            jobID: jobID
        )
    }

    nonisolated static func recordResult(
        stage: PhotoMemoShareDiagnosticStage,
        message: String,
        requestID: UUID? = nil,
        jobID: UUID? = nil,
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) -> PhotoMemoSharedDefaultsWriteResult {

        var events =
            loadEvents(
                defaults: defaults
            )
        events.append(
            PhotoMemoShareDiagnosticEvent(
                stage: stage,
                message: message,
                requestID: requestID,
                jobID: jobID
            )
        )

        return persistResult(
            Array(
                events.suffix(maxEventCount)
            ),
            defaults: defaults
        )
    }

    nonisolated static func loadEvents()
    -> [PhotoMemoShareDiagnosticEvent] {

        loadEvents(
            defaults:
                PhotoMemoSharedContainer
                .sharedUserDefaults
        )
    }

    nonisolated static func loadEvents(
        defaults: UserDefaults
    ) -> [PhotoMemoShareDiagnosticEvent] {

        switch loadEventsResult(
            defaults: defaults
        ) {
        case .success(let events):
            return events
        case .noValue,
             .decodingFailed:
            return []
        }
    }

    nonisolated static func loadEventsResult(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) -> PhotoMemoSharedDefaultsReadResult<
        [PhotoMemoShareDiagnosticEvent]
    > {

        guard let data =
            defaults
            .data(
                forKey:
                    storageKey
            )
        else {
            return .noValue
        }

        do {
            let events =
                try JSONDecoder()
                .decode(
                    [PhotoMemoShareDiagnosticEvent].self,
                    from: data
                )
            return .success(events)
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey:
                        storageKey,
                    payloadByteCount:
                        data.count,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }
    }

    nonisolated static func persistResult(
        _ events: [PhotoMemoShareDiagnosticEvent],
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults,
        encode:
            ([PhotoMemoShareDiagnosticEvent]) throws
            -> Data = {
                try JSONEncoder().encode($0)
            }
    ) -> PhotoMemoSharedDefaultsWriteResult {

        let data: Data

        do {
            data = try encode(events)
        } catch {
            return .encodingFailed(
                PhotoMemoSharedDefaultsWriteFailure(
                    storageKey:
                        storageKey,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }

        defaults.set(
            data,
            forKey:
                storageKey
        )
        defaults.synchronize()
        return .success
    }
}

enum PhotoMemoShareProviderTypeSelection {

    nonisolated static let livePhotoTypeIdentifiers: Set<String> = [
        "com.apple.live-photo",
        "com.apple.live-photo-bundle"
    ]

    nonisolated static func preferredImportTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        preferredLivePhotoTypeIdentifier(
            from: registeredTypeIdentifiers
        )
        ?? preferredImageTypeIdentifier(
            from: registeredTypeIdentifiers
        )
    }

    nonisolated static func preferredLivePhotoTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        registeredTypeIdentifiers.first {
            livePhotoTypeIdentifiers.contains($0)
        }
    }

    nonisolated static func preferredImageTypeIdentifier(
        from registeredTypeIdentifiers: [String]
    ) -> String? {

        registeredTypeIdentifiers
            .compactMap(UTType.init)
            .first { type in
                type.conforms(to: .image)
            }?
            .identifier
    }

    nonisolated static func supportsLivePhoto(
        _ registeredTypeIdentifiers: [String]
    ) -> Bool {

        registeredTypeIdentifiers.contains {
            livePhotoTypeIdentifiers.contains($0)
        }
    }
}

enum PhotoMemoShareLivePhotoRepresentationProbe {

    nonisolated static func message(
        operation: String,
        providerIndex: Int,
        typeIdentifier: String,
        resultDescription: String? = nil,
        url: URL?,
        error: Error?
    ) -> String {

        var parts = [
            "operation=\(operation)",
            "providerIndex=\(providerIndex)",
            "type=\(typeIdentifier)"
        ]

        if let resultDescription {
            parts.append(resultDescription)
        }

        if let error {
            let nsError = error as NSError
            parts.append(
                "error=\(nsError.domain)/\(nsError.code)"
            )
            parts.append(
                "description=\(nsError.localizedDescription)"
            )
            return parts.joined(separator: ", ")
        }

        guard let url else {
            if resultDescription == nil {
                parts.append("result=nil")
            }
            return parts.joined(separator: ", ")
        }

        let normalizedURL =
            url.standardizedFileURL
        var isDirectory =
            ObjCBool(false)
        let exists =
            FileManager.default.fileExists(
                atPath: normalizedURL.path,
                isDirectory:
                    &isDirectory
            )
        let fileSize =
            (
                try? normalizedURL
                    .resourceValues(
                        forKeys: [
                            .fileSizeKey
                        ]
                    )
                    .fileSize
            ) ?? nil
        let childNames =
            isDirectory.boolValue
            ? (
                (
                    try? FileManager.default
                        .contentsOfDirectory(
                            atPath:
                                normalizedURL.path
                        )
                ) ?? []
            )
            : []

        parts.append(
            "result=url"
        )
        parts.append(
            "lastPathComponent=\(normalizedURL.lastPathComponent)"
        )
        parts.append(
            "pathExtension=\(normalizedURL.pathExtension)"
        )
        parts.append(
            "exists=\(exists)"
        )
        parts.append(
            "isDirectory=\(isDirectory.boolValue)"
        )

        if let fileSize {
            parts.append(
                "bytes=\(fileSize)"
            )
        }

        if !childNames.isEmpty {
            parts.append(
                "children=\(childNames.prefix(8).joined(separator: "|"))"
            )
        }

        return parts.joined(separator: ", ")
    }
}

extension PhotoMemoShareDiagnosticEvent {

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case stage
        case message
        case requestID
        case jobID
    }

    init(
        from decoder: Decoder
    ) throws {

        let container =
            try decoder.container(
                keyedBy: CodingKeys.self
            )

        id =
            try container.decode(
                UUID.self,
                forKey: .id
            )
        timestamp =
            try container.decode(
                Date.self,
                forKey: .timestamp
            )
        stage =
            PhotoMemoShareDiagnosticStage(
                rawValue:
                    try container.decode(
                        String.self,
                        forKey: .stage
                    )
            )
        message =
            try container.decode(
                String.self,
                forKey: .message
            )
        requestID =
            try container.decodeIfPresent(
                UUID.self,
                forKey: .requestID
            )
        jobID =
            try container.decodeIfPresent(
                UUID.self,
                forKey: .jobID
            )
    }

    func encode(
        to encoder: Encoder
    ) throws {

        var container =
            encoder.container(
                keyedBy: CodingKeys.self
            )

        try container.encode(
            id,
            forKey: .id
        )
        try container.encode(
            timestamp,
            forKey: .timestamp
        )
        try container.encode(
            stage.rawValue,
            forKey: .stage
        )
        try container.encode(
            message,
            forKey: .message
        )
        try container.encodeIfPresent(
            requestID,
            forKey: .requestID
        )
        try container.encodeIfPresent(
            jobID,
            forKey: .jobID
        )
    }
}
