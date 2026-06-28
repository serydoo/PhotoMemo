#if os(iOS) && canImport(ActivityKit) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Combine

@MainActor
final class PhotoMemoiOSLiveActivityBridgeService:
    ObservableObject {

    @Published private(set)
    var bridgeState =
        PhotoMemoBackgroundLiveActivityBridgeState()

    private let backgroundStatusService:
        PhotoMemoBackgroundStatusService

    private var projectedJobID:
        UUID?

    private var cancellables:
        Set<AnyCancellable> = []

    init(
        backgroundStatusService:
            PhotoMemoBackgroundStatusService
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

private extension PhotoMemoiOSLiveActivityBridgeService {

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
            PhotoMemoBackgroundJobSnapshot?
    ) {

        let newJobID =
            snapshot?.jobID

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
            PhotoMemoBackgroundLiveActivityBridgeState(
                currentPayload: payload,
                obsoleteJobIDs:
                    obsoleteJobIDs
            )
        projectedJobID = payload?.jobID
    }

    func makePayload(
        from snapshot:
            PhotoMemoBackgroundJobSnapshot
    ) -> PhotoMemoBackgroundLiveActivityPayload {

        let progressPercent =
            Int(
                (
                    snapshot.progressFraction
                    * 100
                )
                .rounded()
            )

        let attributes =
            PhotoMemoBackgroundActivityAttributes(
                jobID:
                    snapshot.jobID
                    .uuidString,
                jobTitle:
                    snapshot.title,
                launchSourceTitle:
                    snapshot.launchSource
                    .displayTitle
            )

        let contentState =
            PhotoMemoBackgroundActivityAttributes
            .ContentState(
                phaseTitle:
                    snapshot.currentPhaseTitle
                    ?? snapshot.jobState
                    .displayTitle,
                statusMessage:
                    snapshot.statusMessage,
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
                    snapshot.completedCount,
                failedCount:
                    snapshot.failedCount,
                totalCount:
                    snapshot.totalCount,
                progressPercent:
                    progressPercent,
                presentationStateRawValue:
                    presentationStateTitle(
                        snapshot
                        .presentationState
                    ),
                updatedAt:
                    snapshot.updatedAt
            )

        let isTerminal =
            snapshot.presentationState
            != .active

        return PhotoMemoBackgroundLiveActivityPayload(
            jobID: snapshot.jobID,
            attributes: attributes,
            contentState:
                contentState,
            staleDate:
                resolvedStaleDate(
                    isTerminal:
                        isTerminal
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

    func resolvedStaleDate(
        isTerminal: Bool
    ) -> Date? {

        if isTerminal {
            return nil
        }

        return Date()
            .addingTimeInterval(300)
    }

    func resolvedRelevanceScore(
        for snapshot:
            PhotoMemoBackgroundJobSnapshot
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
            PhotoMemoBackgroundPresentationState
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
}
#endif
