import Foundation

struct PhotoMemoShareDiagnosticEvent:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID

    let timestamp: Date

    let stage: String

    let message: String

    let requestID: UUID?

    let jobID: UUID?

    nonisolated init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        stage: String,
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

        persist([
            PhotoMemoShareDiagnosticEvent(
                stage: "start",
                message: reason
            )
        ])
    }

    nonisolated static func record(
        stage: String,
        message: String,
        requestID: UUID? = nil,
        jobID: UUID? = nil
    ) {

        var events =
            loadEvents()
        events.append(
            PhotoMemoShareDiagnosticEvent(
                stage: stage,
                message: message,
                requestID: requestID,
                jobID: jobID
            )
        )

        persist(
            Array(
                events.suffix(maxEventCount)
            )
        )
    }

    nonisolated static func loadEvents()
    -> [PhotoMemoShareDiagnosticEvent] {

        guard let data =
            PhotoMemoSharedContainer
            .sharedUserDefaults
            .data(
                forKey:
                    storageKey
            )
        else {
            return []
        }

        return (
            try? JSONDecoder()
                .decode(
                    [PhotoMemoShareDiagnosticEvent].self,
                    from: data
                )
        ) ?? []
    }

    nonisolated private static func persist(
        _ events: [PhotoMemoShareDiagnosticEvent]
    ) {

        guard let data =
            try? JSONEncoder()
            .encode(events)
        else {
            return
        }

        let defaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
        defaults.set(
            data,
            forKey:
                storageKey
        )
        defaults.synchronize()
    }
}
