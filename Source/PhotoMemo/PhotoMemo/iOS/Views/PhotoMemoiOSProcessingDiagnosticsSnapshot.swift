import Foundation

enum PhotoMemoiOSProcessingDiagnosticsAvailability:
    Equatable {

    case empty
    case available
    case corrupted
}

struct PhotoMemoiOSProcessingDiagnosticsSnapshot:
    Equatable {

    let events:
        [PhotoMemoShareDiagnosticEvent]

    let shareDiagnosticsAvailability:
        PhotoMemoiOSProcessingDiagnosticsAvailability

    let sharedQueueAvailability:
        PhotoMemoiOSProcessingDiagnosticsAvailability

    let externalIntakeAvailability:
        PhotoMemoiOSProcessingDiagnosticsAvailability

    let shareDiagnosticsFailure:
        PhotoMemoSharedDefaultsReadFailure?

    let sharedQueueFailure:
        PhotoMemoSharedDefaultsReadFailure?

    let externalIntakeFailure:
        PhotoMemoSharedDefaultsReadFailure?

    init(
        events: [PhotoMemoShareDiagnosticEvent] = [],
        shareDiagnosticsAvailability:
            PhotoMemoiOSProcessingDiagnosticsAvailability = .empty,
        sharedQueueAvailability:
            PhotoMemoiOSProcessingDiagnosticsAvailability = .empty,
        externalIntakeAvailability:
            PhotoMemoiOSProcessingDiagnosticsAvailability = .empty,
        shareDiagnosticsFailure:
            PhotoMemoSharedDefaultsReadFailure? = nil,
        sharedQueueFailure:
            PhotoMemoSharedDefaultsReadFailure? = nil,
        externalIntakeFailure:
            PhotoMemoSharedDefaultsReadFailure? = nil
    ) {
        self.events = events
        self.shareDiagnosticsAvailability =
            shareDiagnosticsAvailability
        self.sharedQueueAvailability =
            sharedQueueAvailability
        self.externalIntakeAvailability =
            externalIntakeAvailability
        self.shareDiagnosticsFailure =
            shareDiagnosticsFailure
        self.sharedQueueFailure =
            sharedQueueFailure
        self.externalIntakeFailure =
            externalIntakeFailure
    }

    var hasCorruptedPersistence: Bool {
        shareDiagnosticsAvailability == .corrupted
        || sharedQueueAvailability == .corrupted
        || externalIntakeAvailability == .corrupted
    }

    var recoveryMessage: String? {
        var components: [String] = []

        if shareDiagnosticsAvailability == .corrupted {
            components.append("共享进度记录")
        }

        if sharedQueueAvailability == .corrupted {
            components.append("共享队列快照")
        }

        if externalIntakeAvailability == .corrupted {
            components.append("共享接单记录")
        }

        guard !components.isEmpty else {
            return nil
        }

        let joinedComponents =
            components.joined(separator: "、")

        return "\(joinedComponents) 不可读取，当前已按空状态继续。重新分享后会生成新的本地记录。"
    }

    static func load(
        defaults: UserDefaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
    ) -> Self {

        let diagnosticsResult =
            PhotoMemoShareDiagnostics
            .loadEventsResult(
                defaults: defaults
            )
        let queueResult =
            SharedBatchQueueSnapshotService(
                defaults: defaults
            )
            .loadJobsResult()
        let intakeResult =
            ExternalPhotoIntakeStore(
                defaults: defaults
            )
            .loadRequestsResult()

        let diagnosticsSummary =
            summarize(diagnosticsResult)
        let queueSummary =
            summarize(queueResult)
        let intakeSummary =
            summarize(intakeResult)

        return Self(
            events:
                diagnosticsSummary.value ?? [],
            shareDiagnosticsAvailability:
                diagnosticsSummary.availability,
            sharedQueueAvailability:
                queueSummary.availability,
            externalIntakeAvailability:
                intakeSummary.availability,
            shareDiagnosticsFailure:
                diagnosticsSummary.failure,
            sharedQueueFailure:
                queueSummary.failure,
            externalIntakeFailure:
                intakeSummary.failure
        )
    }

    private static func summarize<Value>(
        _ result:
            PhotoMemoSharedDefaultsReadResult<
                Value
            >
    ) -> (
        availability:
            PhotoMemoiOSProcessingDiagnosticsAvailability,
        value: Value?,
        failure:
            PhotoMemoSharedDefaultsReadFailure?
    ) {

        switch result {
        case .noValue:
            return (
                .empty,
                nil,
                nil
            )

        case .success(let value):
            return (
                .available,
                value,
                nil
            )

        case .decodingFailed(let failure):
            return (
                .corrupted,
                nil,
                failure
            )
        }
    }
}
