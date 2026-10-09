#if os(iOS) && canImport(ActivityKit) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class MemoMarkiOSLiveActivityBridgeService:
    ObservableObject {

    @Published private(set)
    var bridgeState =
        MemoMarkBackgroundLiveActivityBridgeState()

    private let backgroundStatusService:
        MemoMarkBackgroundStatusService

    private var projectedJobID:
        UUID?

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        backgroundStatusService:
            MemoMarkBackgroundStatusService
    ) {
        self.backgroundStatusService =
            backgroundStatusService

        bind()
        refresh(
            snapshot:
                backgroundStatusService
                .currentSnapshot
        )
    }

    func markObsoleteJobsHandled(
        _ jobIDs: [UUID]
    ) {

        guard !jobIDs.isEmpty else {
            return
        }

        bridgeState.obsoleteJobIDs =
            bridgeState.obsoleteJobIDs
            .filter {
                !jobIDs.contains($0)
            }
    }
}

private extension MemoMarkiOSLiveActivityBridgeService {

    func bind() {

        backgroundStatusService
            .$currentSnapshot
            .sink { [weak self] snapshot in
                self?.refresh(
                    snapshot: snapshot
                )
            }
            .store(in: &cancellables)
    }

    func refresh(
        snapshot:
            MemoMarkBackgroundJobSnapshot?
    ) {

        let newJobID = snapshot.map {
            backgroundStatusService.currentExecutionSession?.id ?? $0.jobID
        }

        var obsoleteJobIDs =
            bridgeState.obsoleteJobIDs

        if let projectedJobID,
           projectedJobID != newJobID,
           !obsoleteJobIDs.contains(
                projectedJobID
           ) {
            obsoleteJobIDs.append(
                projectedJobID
            )
        }

        let payload =
            snapshot.map {
                makePayload(
                    from: $0
                )
            }

        bridgeState =
            MemoMarkBackgroundLiveActivityBridgeState(
                currentPayload: payload,
                obsoleteJobIDs:
                    obsoleteJobIDs
            )
        projectedJobID = payload?.jobID
    }

    func makePayload(
        from snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> MemoMarkBackgroundLiveActivityPayload {

        let session = backgroundStatusService.currentExecutionSession
        let activityID = session?.id ?? snapshot.jobID
        let isTerminal = session.map { $0.pendingCount == 0 } ?? (snapshot.presentationState != .active)
        let fraction = session.map {
            $0.totalCount == 0 ? 0 : Double($0.totalCount - $0.pendingCount) / Double($0.totalCount)
        } ?? snapshot.progressFraction
        let progressPercent =
            Int(
                (
                    fraction
                    * 100
                )
                .rounded()
            )

        let attributes =
            MemoMarkBackgroundActivityAttributes(
                jobID:
                    activityID.uuidString,
                jobTitle:
                    snapshot.title,
                launchSourceTitle:
                    localizedLaunchSourceTitle(
                        snapshot.launchSource
                    )
            )

        let contentState =
            MemoMarkBackgroundActivityAttributes
            .ContentState(
                phaseTitle:
                    snapshot.currentPhaseTitle
                    ?? localizedJobStateTitle(
                        snapshot.jobState
                    ),
                statusMessage:
                    snapshot.localizedStatusMessage(
                        for: .interfaceStored
                    ),
                displayModeRawValue:
                    snapshot.displayMode
                    .rawValue,
                pipelineStepTitles:
                    snapshot.pipelineSteps.map(
                        \.title
                    ),
                activePipelineStepIndex:
                    snapshot.activePipelineStepIndex,
                queueLines:
                    snapshot.queueLines,
                overflowQueueCount:
                    snapshot.overflowQueueCount,
                currentFileName:
                    snapshot.currentFileName,
                completedCount:
                    session?.completedCount ?? snapshot.completedCount,
                failedCount:
                    session?.failedCount ?? snapshot.failedCount,
                totalCount:
                    session?.totalCount ?? snapshot.totalCount,
                progressPercent:
                    progressPercent,
                presentationStateRawValue:
                    presentationStateTitle(
                        isTerminal ? snapshot.presentationState : .active
                    ),
                feedbackStateRawValue:
                    snapshot.feedbackState
                    .rawValue,
                updatedAt:
                    snapshot.updatedAt
            )

        return MemoMarkBackgroundLiveActivityPayload(
            jobID: activityID,
            attributes: attributes,
            contentState:
                contentState,
            staleDate:
                resolvedStaleDate(
                    isTerminal:
                        isTerminal,
                    updatedAt: snapshot.updatedAt
                ),
            relevanceScore:
                resolvedRelevanceScore(
                    for: snapshot
                ),
            dismissalHint:
                isTerminal
                ? .afterDefaultLinger
                : .immediate,
            isTerminal: isTerminal
        )
    }

    func resolvedStaleDate(isTerminal: Bool, updatedAt: Date) -> Date? {
        ProcessingProgressFreshness.staleDate(updatedAt: updatedAt, isTerminal: isTerminal)
    }

    func resolvedRelevanceScore(
        for snapshot:
            MemoMarkBackgroundJobSnapshot
    ) -> Double {

        switch snapshot
            .presentationState {

        case .active:
            return 100

        case .needsAttention:
            return 80

        case .completed:
            return 40
        }
    }

    func presentationStateTitle(
        _ state:
            MemoMarkBackgroundPresentationState
    ) -> String {

        switch state {

        case .active:
            return "active"

        case .needsAttention:
            return "needsAttention"

        case .completed:
            return "completed"
        }
    }

    func localizedLaunchSourceTitle(
        _ source: BatchJobLaunchSource
    ) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: "legacy.home.recent.source.\(source.rawValue)",
            fallback: source.displayTitle
        )
    }

    func localizedJobStateTitle(
        _ state: BatchJobState
    ) -> String {
        MemoMarkLanguage.interfaceStored.localized(
            key: "processing.background.job_state.\(state.rawValue)",
            fallback: state.displayTitle
        )
    }
}
#endif
