#if os(iOS) && canImport(ActivityKit) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine
import ActivityKit

@MainActor
final class PhotoMemoiOSLiveActivityDriverService {

    private let bridgeService:
        PhotoMemoiOSLiveActivityBridgeService

    private var trackedActivities:
        [UUID:
            Activity<
                PhotoMemoBackgroundActivityAttributes
            >
        ] = [:]

    private var lastAppliedPayloads:
        [UUID:
            PhotoMemoBackgroundLiveActivityPayload
        ] = [:]

    private var activityStartDates:
        [UUID: Date] = [:]

    private var delayedTerminalEndTasks:
        [UUID: Task<Void, Never>] = [:]

    private let minimumVisibleActivityDuration:
        TimeInterval = 2.8

    private var hasPermanentlyDisabledRequests =
        false

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        bridgeService:
            PhotoMemoiOSLiveActivityBridgeService
    ) {
        self.bridgeService =
            bridgeService

        bootstrapExistingActivities()
        bind()
    }
}

private extension PhotoMemoiOSLiveActivityDriverService {

    func bootstrapExistingActivities() {

        guard #available(iOS 16.2, *) else {
            return
        }

        trackedActivities =
            Dictionary(
                uniqueKeysWithValues:
                    Activity<
                        PhotoMemoBackgroundActivityAttributes
                    >
                    .activities.compactMap {
                        activity in

                        guard let jobID =
                            UUID(
                                uuidString:
                                    activity
                                    .attributes
                                    .jobID
                            ) else {
                            return nil
                        }

                        return (
                            jobID,
                            activity
                        )
                    }
            )

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
            PhotoMemoBackgroundLiveActivityBridgeState
    ) async {

        guard #available(iOS 16.2, *) else {
            return
        }

        guard ActivityAuthorizationInfo()
            .areActivitiesEnabled else {
            PhotoMemoShareDiagnostics.record(
                stage: .liveActivityDisabled,
                message: "ActivityAuthorizationInfo.areActivitiesEnabled=false"
            )
            await endAllTrackedActivities(
                dismissalPolicy:
                    .immediate
            )
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
            PhotoMemoBackgroundLiveActivityPayload
    ) async {

        if payload.isTerminal {
            PhotoMemoShareDiagnostics.record(
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
            PhotoMemoBackgroundActivityAttributes
        >,
        with payload:
            PhotoMemoBackgroundLiveActivityPayload
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
            PhotoMemoBackgroundLiveActivityPayload
    ) async {

        guard let activity =
            trackedActivities[
                payload.jobID
            ] else {
            guard await requestActivity(
                for: payload
            ) != nil else {
                lastAppliedPayloads[
                    payload.jobID
                ] = payload
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
            PhotoMemoBackgroundLiveActivityPayload
    ) async -> Activity<
        PhotoMemoBackgroundActivityAttributes
    >? {

        guard !hasPermanentlyDisabledRequests else {
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

            PhotoMemoShareDiagnostics.record(
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
            PhotoMemoShareDiagnostics.record(
                stage: .liveActivityRequestFailed,
                message:
                    "\(nsError.domain) / \(nsError.code): \(nsError.localizedDescription)",
                jobID:
                    payload.jobID
            )
            hasPermanentlyDisabledRequests =
                true
            return nil
        }
    }

    func scheduleTerminalEnd(
        for payload:
            PhotoMemoBackgroundLiveActivityPayload
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
            PhotoMemoBackgroundLiveActivityPayload
    ) async {

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
            PhotoMemoBackgroundActivityAttributes
        >,
        jobID: UUID
    ) -> PhotoMemoBackgroundLiveActivityPayload {

        PhotoMemoBackgroundLiveActivityPayload(
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
            PhotoMemoBackgroundLiveActivityPayload
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
