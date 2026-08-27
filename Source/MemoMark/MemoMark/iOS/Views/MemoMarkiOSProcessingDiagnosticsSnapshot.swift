import Foundation

enum MemoMarkiOSProcessingDiagnosticsAvailability:
    Equatable {

    case empty
    case available
    case corrupted
}

struct MemoMarkiOSProcessingDiagnosticsSnapshot:
    Equatable {

    let events:
        [MemoMarkShareDiagnosticEvent]

    let shareDiagnosticsAvailability:
        MemoMarkiOSProcessingDiagnosticsAvailability

    let sharedQueueAvailability:
        MemoMarkiOSProcessingDiagnosticsAvailability

    let externalIntakeAvailability:
        MemoMarkiOSProcessingDiagnosticsAvailability

    let shareDiagnosticsFailure:
        MemoMarkSharedDefaultsReadFailure?

    let sharedQueueFailure:
        MemoMarkSharedDefaultsReadFailure?

    let externalIntakeFailure:
        MemoMarkSharedDefaultsReadFailure?

    init(
        events: [MemoMarkShareDiagnosticEvent] = [],
        shareDiagnosticsAvailability:
            MemoMarkiOSProcessingDiagnosticsAvailability = .empty,
        sharedQueueAvailability:
            MemoMarkiOSProcessingDiagnosticsAvailability = .empty,
        externalIntakeAvailability:
            MemoMarkiOSProcessingDiagnosticsAvailability = .empty,
        shareDiagnosticsFailure:
            MemoMarkSharedDefaultsReadFailure? = nil,
        sharedQueueFailure:
            MemoMarkSharedDefaultsReadFailure? = nil,
        externalIntakeFailure:
            MemoMarkSharedDefaultsReadFailure? = nil
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
            MemoMarkSharedContainer
            .sharedUserDefaults,
        externalIntakeStore:
            ExternalPhotoIntakeStore? = nil,
        sharedQueueSnapshotService:
            SharedBatchQueueSnapshotService? = nil
    ) -> Self {

        let diagnosticsResult =
            MemoMarkShareDiagnostics
            .loadEventsResult(
                defaults: defaults
            )
        let queueResult =
            (sharedQueueSnapshotService
             ?? SharedBatchQueueSnapshotService(
                 defaults: defaults
             ))
            .loadJobsResult()
        let intakeResult =
            (
                externalIntakeStore
                ?? ExternalPhotoIntakeStore(
                    defaults: defaults
                )
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
            MemoMarkSharedDefaultsReadResult<
                Value
            >
    ) -> (
        availability:
            MemoMarkiOSProcessingDiagnosticsAvailability,
        value: Value?,
        failure:
            MemoMarkSharedDefaultsReadFailure?
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
