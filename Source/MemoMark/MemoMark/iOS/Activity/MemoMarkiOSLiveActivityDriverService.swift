import Foundation

struct MemoMarkLiveActivityBootstrapResolution<ActivityValue> {
    let trackedActivities: [UUID: ActivityValue]
    let duplicateActivities:
        [(jobID: UUID, activity: ActivityValue)]
    let activitiesToEnd:
        [(jobID: UUID?, activity: ActivityValue)]
}

enum MemoMarkLiveActivityBootstrapResolver {

    static func resolve<ActivityValue>(
        candidates:
            [(jobID: UUID, activity: ActivityValue)]
    ) -> MemoMarkLiveActivityBootstrapResolution<
        ActivityValue
    > {
        var trackedActivities:
            [UUID: ActivityValue] = [:]
        var duplicateActivities:
            [(jobID: UUID, activity: ActivityValue)] = []
        var seenJobIDs: Set<UUID> = []

        for candidate in candidates {
            guard seenJobIDs.insert(
                candidate.jobID
            ).inserted else {
                duplicateActivities.append(
                    candidate
                )
                continue
            }

            trackedActivities[
                candidate.jobID
            ] = candidate.activity
        }

        return .init(
            trackedActivities:
                trackedActivities,
            duplicateActivities:
                duplicateActivities,
            activitiesToEnd:
                duplicateActivities.map {
                    (
                        jobID: Optional($0.jobID),
                        activity: $0.activity
                    )
                }
        )
    }

    static func resolve<ActivityValue>(
        candidates:
            [(
                jobIDString: String,
                activity: ActivityValue
            )],
        currentJobID: UUID?
    ) -> MemoMarkLiveActivityBootstrapResolution<
        ActivityValue
    > {
        var trackedActivities:
            [UUID: ActivityValue] = [:]
        var duplicateActivities:
            [(jobID: UUID, activity: ActivityValue)] = []
        var activitiesToEnd:
            [(jobID: UUID?, activity: ActivityValue)] = []

        for candidate in candidates {
            let jobID = UUID(
                uuidString:
                    candidate.jobIDString
            )

            guard let jobID,
                  jobID == currentJobID else {
                activitiesToEnd.append(
                    (
                        jobID: jobID,
                        activity: candidate.activity
                    )
                )
                continue
            }

            guard trackedActivities[jobID] == nil else {
                duplicateActivities.append(
                    (
                        jobID: jobID,
                        activity: candidate.activity
                    )
                )
                activitiesToEnd.append(
                    (
                        jobID: jobID,
                        activity: candidate.activity
                    )
                )
                continue
            }

            trackedActivities[jobID] =
                candidate.activity
        }

        return .init(
            trackedActivities:
                trackedActivities,
            duplicateActivities:
                duplicateActivities,
            activitiesToEnd:
                activitiesToEnd
        )
    }
}

enum MemoMarkLiveActivityQueueReconciliationResolver {

    static func jobIDsToEnd(
        trackedJobIDs: Set<UUID>,
        currentJobID: UUID?
    ) -> [UUID] {
        trackedJobIDs
            .filter {
                $0 != currentJobID
            }
            .sorted {
                $0.uuidString < $1.uuidString
            }
    }
}

enum MemoMarkLiveActivityRequestFailureKind {
    case temporarilyUnavailable
    case invalidRequest
    case serviceUnavailable
}

enum MemoMarkLiveActivityRequestFailureDisposition:
    Equatable {
    case retryAfter(TimeInterval)
    case suppressJob
    case disableRequestsForRun
}

enum MemoMarkLiveActivityRequestFailurePolicy {

    static func disposition(
        for kind:
            MemoMarkLiveActivityRequestFailureKind
    ) -> MemoMarkLiveActivityRequestFailureDisposition {
        switch kind {
        case .temporarilyUnavailable:
            return .retryAfter(15)
        case .invalidRequest:
            return .suppressJob
        case .serviceUnavailable:
            return .disableRequestsForRun
        }
    }
}

struct MemoMarkLiveActivityRequestRetryRegistry<Payload: Equatable> {

    private struct Entry {
        var payload: Payload
        let token: UUID
    }

    private var entries: [UUID: Entry] = [:]

    mutating func schedule(
        payload: Payload,
        for jobID: UUID
    ) -> UUID {
        let token = UUID()
        entries[jobID] = Entry(
            payload: payload,
            token: token
        )
        return token
    }

    mutating func updateScheduledPayload(
        _ payload: Payload,
        for jobID: UUID
    ) {
        guard var entry = entries[jobID] else {
            return
        }
        entry.payload = payload
        entries[jobID] = entry
    }

    mutating func consumeRetry(
        for jobID: UUID,
        token: UUID,
        currentPayload: Payload
    ) -> Payload? {
        guard let entry = entries[jobID],
              entry.token == token else {
            return nil
        }
        entries[jobID] = nil
        guard entry.payload == currentPayload else {
            return nil
        }
        return entry.payload
    }

    func hasScheduledRetry(
        for jobID: UUID
    ) -> Bool {
        entries[jobID] != nil
    }

    @discardableResult
    mutating func cancel(
        for jobID: UUID
    ) -> Bool {
        entries.removeValue(forKey: jobID) != nil
    }

    mutating func cancelAll(
        except currentJobID: UUID?
    ) -> Set<UUID> {
        let jobIDs = Set(entries.keys).filter {
            $0 != currentJobID
        }
        for jobID in jobIDs {
            entries[jobID] = nil
        }
        return Set(jobIDs)
    }
}

#if os(iOS) && canImport(ActivityKit) && !MEMOMARK_SHARE_EXTENSION
import Combine
import ActivityKit

@MainActor
final class MemoMarkiOSLiveActivityDriverService {

    private let bridgeService:
        MemoMarkiOSLiveActivityBridgeService

    private var trackedActivities:
        [UUID:
            Activity<
                MemoMarkBackgroundActivityAttributes
            >
        ] = [:]

    private var lastAppliedPayloads:
        [UUID:
            MemoMarkBackgroundLiveActivityPayload
        ] = [:]

    private var activityStartDates:
        [UUID: Date] = [:]

    private var delayedTerminalEndTasks:
        [UUID: Task<Void, Never>] = [:]

    private var requestRetryTasks:
        [UUID: Task<Void, Never>] = [:]

    private var requestRetryRegistry =
        MemoMarkLiveActivityRequestRetryRegistry<
            MemoMarkBackgroundLiveActivityPayload
        >()

    private let minimumVisibleActivityDuration:
        TimeInterval = 2.8

    private var hasDisabledRequestsForRun =
        false

    private var suppressedRequestJobIDs:
        Set<UUID> = []

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        bridgeService:
            MemoMarkiOSLiveActivityBridgeService
    ) {
        self.bridgeService =
            bridgeService

        bootstrapExistingActivities()
        bind()
    }
}

private extension MemoMarkiOSLiveActivityDriverService {

    func bootstrapExistingActivities() {

        guard #available(iOS 16.2, *) else {
            return
        }

        let candidates:
            [(
                jobIDString: String,
                activity: Activity<
                    MemoMarkBackgroundActivityAttributes
                >
            )] =
                Activity<
                    MemoMarkBackgroundActivityAttributes
                >
                .activities.map {
                    activity in

                    return (
                        jobIDString:
                            activity
                            .attributes
                            .jobID,
                        activity: activity
                    )
                }

        let resolution =
            MemoMarkLiveActivityBootstrapResolver
            .resolve(
                candidates:
                    candidates,
                currentJobID:
                    bridgeService
                    .bridgeState
                    .currentPayload?
                    .jobID
            )

        trackedActivities =
            resolution.trackedActivities

        let now = Date()
        activityStartDates =
            Dictionary(
                uniqueKeysWithValues:
                    trackedActivities
                    .keys
                    .map {
                        (
                            $0,
                            now
                        )
                    }
            )

        guard !resolution
            .activitiesToEnd
            .isEmpty else {
            return
        }

        Task { @MainActor [weak self] in
            await self?
                .endBootstrapActivities(
                    resolution
                    .activitiesToEnd
                )
        }
    }

    func endBootstrapActivities(
        _ activities:
            [(
                jobID: UUID?,
                activity: Activity<
                    MemoMarkBackgroundActivityAttributes
                >
            )]
    ) async {
        for candidate in activities {
            let payload =
                fallbackPayload(
                    for:
                        candidate.activity,
                    jobID:
                        candidate.jobID
                        ?? UUID()
                )

            await candidate
                .activity
                .end(
                    payload.activityContent,
                    dismissalPolicy:
                        .immediate
                )
        }
    }

    func bind() {

        bridgeService.$bridgeState
            .sink { [weak self] state in
                Task { @MainActor in
                    await self?
                        .apply(
                            bridgeState:
                                state
                        )
                }
            }
            .store(in: &cancellables)
    }

    func apply(
        bridgeState:
            MemoMarkBackgroundLiveActivityBridgeState
    ) async {

        guard #available(iOS 16.2, *) else {
            return
        }

        if let currentJobID = bridgeState.currentPayload?.jobID {
            suppressedRequestJobIDs.formIntersection([currentJobID])
            cancelRequestRetries(except: currentJobID)
            if let payload = bridgeState.currentPayload {
                requestRetryRegistry.updateScheduledPayload(
                    payload,
                    for: currentJobID
                )
            }
        } else {
            suppressedRequestJobIDs.removeAll()
            cancelRequestRetries(except: nil)
        }

        guard ActivityAuthorizationInfo()
            .areActivitiesEnabled else {
            MemoMarkShareDiagnostics.record(
                stage: .liveActivityDisabled,
                message: "ActivityAuthorizationInfo.areActivitiesEnabled=false"
            )
            await endAllTrackedActivities(
                dismissalPolicy:
                    .immediate
            )
            cancelRequestRetries(except: nil)
            lastAppliedPayloads.removeAll()
            return
        }

        if !bridgeState.obsoleteJobIDs.isEmpty {
            await endTrackedActivities(
                for: bridgeState.obsoleteJobIDs,
                dismissalPolicy:
                    .immediate
            )
            bridgeService
                .markObsoleteJobsHandled(
                    bridgeState
                    .obsoleteJobIDs
                )
        }

        let reconciledJobIDs =
            MemoMarkLiveActivityQueueReconciliationResolver
            .jobIDsToEnd(
                trackedJobIDs:
                    Set(trackedActivities.keys),
                currentJobID:
                    bridgeState
                    .currentPayload?
                    .jobID
            )

        if !reconciledJobIDs.isEmpty {
            await endTrackedActivities(
                for: reconciledJobIDs,
                dismissalPolicy:
                    .immediate
            )
        }

        guard let payload =
            bridgeState.currentPayload else {
            return
        }

        if lastAppliedPayloads[
            payload.jobID
        ] == payload {
            return
        }

        await apply(payload: payload)
    }

    func apply(
        payload:
            MemoMarkBackgroundLiveActivityPayload
    ) async {

        if payload.isTerminal {
            MemoMarkShareDiagnostics.record(
                stage: .liveActivityPayloadTerminal,
                message:
                    "\(payload.contentState.presentationStateRawValue), progress=\(payload.contentState.progressPercent)",
                jobID:
                    payload.jobID
            )
            await updateAndEndActivity(
                for: payload
            )
            return
        }

        if let activity =
            trackedActivities[
                payload.jobID
            ] {
            cancelRequestRetry(
                for: payload.jobID
            )
            delayedTerminalEndTasks[
                payload.jobID
            ]?
                .cancel()
            delayedTerminalEndTasks[
                payload.jobID
            ] = nil

            await update(
                activity: activity,
                with: payload
            )
            return
        }

        _ = await requestActivity(
            for: payload
        )
    }

    func update(
        activity: Activity<
            MemoMarkBackgroundActivityAttributes
        >,
        with payload:
            MemoMarkBackgroundLiveActivityPayload
    ) async {

        await activity.update(
            payload.activityContent
        )
        lastAppliedPayloads[
            payload.jobID
        ] = payload
    }

    func updateAndEndActivity(
        for payload:
            MemoMarkBackgroundLiveActivityPayload
    ) async {

        guard let activity =
            trackedActivities[
                payload.jobID
            ] else {
            guard await requestActivity(
                for: payload
            ) != nil else {
                return
            }

            await scheduleTerminalEnd(
                for: payload
            )
            return
        }

        await activity.update(
            payload.activityContent
        )

        lastAppliedPayloads[
            payload.jobID
        ] = payload

        await scheduleTerminalEnd(
            for: payload
        )
    }

    func endTrackedActivities(
        for jobIDs: [UUID],
        dismissalPolicy:
            ActivityUIDismissalPolicy
    ) async {

        for jobID in jobIDs {
            cancelRequestRetry(
                for: jobID
            )
            guard let activity =
                trackedActivities[jobID]
            else {
                continue
            }

            let payload =
                lastAppliedPayloads[jobID]
                ?? fallbackPayload(
                    for: activity,
                    jobID: jobID
                )

            await activity.end(
                payload.activityContent,
                dismissalPolicy:
                    dismissalPolicy
            )
            trackedActivities[jobID] = nil
            activityStartDates[jobID] = nil
            delayedTerminalEndTasks[jobID]?
                .cancel()
            delayedTerminalEndTasks[jobID] = nil
            lastAppliedPayloads[jobID] = payload
        }
    }

    func endAllTrackedActivities(
        dismissalPolicy:
            ActivityUIDismissalPolicy
    ) async {

        await endTrackedActivities(
            for: Array(
                trackedActivities.keys
            ),
            dismissalPolicy:
                dismissalPolicy
        )
    }

    func requestActivity(
        for payload:
            MemoMarkBackgroundLiveActivityPayload
    ) async -> Activity<
        MemoMarkBackgroundActivityAttributes
    >? {

        guard !hasDisabledRequestsForRun,
              !suppressedRequestJobIDs.contains(payload.jobID),
              !requestRetryRegistry.hasScheduledRetry(
                for: payload.jobID
              ) else {
            return nil
        }

        do {
            let activity =
                try Activity
                .request(
                    attributes:
                        payload.attributes,
                    content:
                        payload
                        .activityContent,
                    pushType: nil
                )

            trackedActivities[
                payload.jobID
            ] = activity
            activityStartDates[
                payload.jobID
            ] = Date()
            lastAppliedPayloads[
                payload.jobID
            ] = payload
            cancelRequestRetry(
                for: payload.jobID
            )

            MemoMarkShareDiagnostics.record(
                stage: .liveActivityRequestCreated,
                message:
                    "activityID=\(activity.id), progress=\(payload.contentState.progressPercent)",
                jobID:
                    payload.jobID
            )

            return activity
        } catch {
            let nsError =
                error as NSError
            MemoMarkShareDiagnostics.record(
                stage: .liveActivityRequestFailed,
                message:
                    "\(nsError.domain) / \(nsError.code): \(nsError.localizedDescription)",
                jobID:
                    payload.jobID
            )
            let failureKind =
                requestFailureKind(
                    for: error
                )
            switch MemoMarkLiveActivityRequestFailurePolicy
                .disposition(for: failureKind) {
            case .retryAfter(let delay):
                scheduleRequestRetry(
                    for: payload,
                    after: delay
                )
            case .suppressJob:
                cancelRequestRetry(
                    for: payload.jobID
                )
                suppressedRequestJobIDs.insert(payload.jobID)
            case .disableRequestsForRun:
                cancelRequestRetries(except: nil)
                hasDisabledRequestsForRun = true
            }
            return nil
        }
    }

    func scheduleRequestRetry(
        for payload:
            MemoMarkBackgroundLiveActivityPayload,
        after delay: TimeInterval
    ) {
        cancelRequestRetry(
            for: payload.jobID
        )
        let token = requestRetryRegistry.schedule(
            payload: payload,
            for: payload.jobID
        )
        requestRetryTasks[payload.jobID] =
            Task { @MainActor [weak self] in
                try? await Task.sleep(
                    nanoseconds:
                        UInt64(
                            max(delay, 0)
                            * 1_000_000_000
                        )
                )
                guard !Task.isCancelled else {
                    return
                }
                await self?.performScheduledRequestRetry(
                    for: payload.jobID,
                    token: token
                )
            }
    }

    func performScheduledRequestRetry(
        for jobID: UUID,
        token: UUID
    ) async {
        guard let currentPayload =
                bridgeService.bridgeState.currentPayload,
              currentPayload.jobID == jobID,
              let payload = requestRetryRegistry.consumeRetry(
                for: jobID,
                token: token,
                currentPayload: currentPayload
              ) else {
            requestRetryTasks[jobID] = nil
            return
        }
        requestRetryTasks[jobID] = nil
        await apply(payload: payload)
    }

    func cancelRequestRetry(
        for jobID: UUID
    ) {
        requestRetryTasks[jobID]?.cancel()
        requestRetryTasks[jobID] = nil
        requestRetryRegistry.cancel(for: jobID)
    }

    func cancelRequestRetries(
        except currentJobID: UUID?
    ) {
        let jobIDs =
            requestRetryRegistry.cancelAll(
                except: currentJobID
            )
            .union(
                requestRetryTasks.keys.filter {
                    $0 != currentJobID
                }
            )
        for jobID in jobIDs {
            requestRetryTasks[jobID]?.cancel()
            requestRetryTasks[jobID] = nil
        }
    }

    func requestFailureKind(
        for error: Error
    ) -> MemoMarkLiveActivityRequestFailureKind {
        guard let authorizationError =
            error as? ActivityAuthorizationError else {
            return .temporarilyUnavailable
        }

        switch authorizationError {
        case .unsupported,
             .denied,
             .unsupportedTarget,
             .unentitled:
            return .serviceUnavailable

        case .attributesTooLarge,
             .missingProcessIdentifier,
             .malformedActivityIdentifier:
            return .invalidRequest

        case .globalMaximumExceeded,
             .targetMaximumExceeded,
             .visibility,
             .persistenceFailure,
             .reconnectNotPermitted:
            return .temporarilyUnavailable

        @unknown default:
            return .temporarilyUnavailable
        }
    }

    func scheduleTerminalEnd(
        for payload:
            MemoMarkBackgroundLiveActivityPayload
    ) async {

        let startedAt =
            activityStartDates[
                payload.jobID
            ] ?? Date()
        let elapsed =
            Date()
                .timeIntervalSince(
                    startedAt
                )
        let delay =
            max(
                minimumVisibleActivityDuration
                - elapsed,
                0
            )

        delayedTerminalEndTasks[
            payload.jobID
        ]?
            .cancel()

        guard delay > 0 else {
            delayedTerminalEndTasks[
                payload.jobID
            ] = nil
            await finishTerminalEnd(
                for: payload
            )
            return
        }

        delayedTerminalEndTasks[
            payload.jobID
        ] = Task { @MainActor [weak self] in
            try? await Task.sleep(
                nanoseconds:
                    UInt64(
                        delay
                        * 1_000_000_000
                    )
            )

            guard !Task.isCancelled else {
                return
            }

            await self?
                .finishTerminalEnd(
                    for: payload
                )
        }
    }

    func finishTerminalEnd(
        for payload:
            MemoMarkBackgroundLiveActivityPayload
    ) async {

        cancelRequestRetry(
            for: payload.jobID
        )

        guard let activity =
            trackedActivities[
                payload.jobID
            ] else {
            delayedTerminalEndTasks[
                payload.jobID
            ] = nil
            activityStartDates[
                payload.jobID
            ] = nil
            return
        }

        await activity.end(
            payload.activityContent,
            dismissalPolicy:
                dismissalPolicy(
                    for: payload
                )
        )

        trackedActivities[
            payload.jobID
        ] = nil
        activityStartDates[
            payload.jobID
        ] = nil
        delayedTerminalEndTasks[
            payload.jobID
        ] = nil
        lastAppliedPayloads[
            payload.jobID
        ] = payload
    }

    func fallbackPayload(
        for activity: Activity<
            MemoMarkBackgroundActivityAttributes
        >,
        jobID: UUID
    ) -> MemoMarkBackgroundLiveActivityPayload {

        MemoMarkBackgroundLiveActivityPayload(
            jobID: jobID,
            attributes:
                activity.attributes,
            contentState:
                .init(
                    phaseTitle: "处理完成",
                    statusMessage:
                        "后台任务已结束",
                    displayModeRawValue:
                        "singleTask",
                    pipelineStepTitles: [
                        "接收照片",
                        "读取信息",
                        "生成卡片",
                        "写入图库",
                        "完成"
                    ],
                    activePipelineStepIndex: 4,
                    queueLines: [
                        "已完成 · 后台任务已结束"
                    ],
                    overflowQueueCount: 0,
                    currentFileName: nil,
                    completedCount: 0,
                    failedCount: 0,
                    totalCount: 0,
                    progressPercent: 100,
                    presentationStateRawValue:
                        "completed",
                    feedbackStateRawValue:
                        "completed",
                    updatedAt: Date()
                ),
            staleDate: nil,
            relevanceScore: 0,
            dismissalHint:
                .immediate,
            isTerminal: true
        )
    }

    func dismissalPolicy(
        for payload:
            MemoMarkBackgroundLiveActivityPayload
    ) -> ActivityUIDismissalPolicy {

        switch payload
            .dismissalHint {

        case .immediate:
            return .immediate

        case .afterDefaultLinger:
            return .default
        }
    }
}
#endif
