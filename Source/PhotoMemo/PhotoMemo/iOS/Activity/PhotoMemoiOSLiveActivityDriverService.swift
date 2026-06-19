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
            await updateAndEndActivity(
                for: payload
            )
            return
        }

        if let activity =
            trackedActivities[
                payload.jobID
            ] {
            await update(
                activity: activity,
                with: payload
            )
            return
        }

        guard !hasPermanentlyDisabledRequests else {
            return
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
            lastAppliedPayloads[
                payload.jobID
            ] = payload
        } catch {
            hasPermanentlyDisabledRequests =
                true
        }
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
            lastAppliedPayloads[
                payload.jobID
            ] = payload
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
        lastAppliedPayloads[
            payload.jobID
        ] = payload
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
                    currentFileName: nil,
                    completedCount: 0,
                    failedCount: 0,
                    totalCount: 0,
                    progressPercent: 100,
                    presentationStateRawValue:
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
