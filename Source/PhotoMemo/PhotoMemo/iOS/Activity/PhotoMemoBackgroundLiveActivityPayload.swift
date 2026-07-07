#if os(iOS) && canImport(ActivityKit) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import ActivityKit

nonisolated struct PhotoMemoBackgroundActivityAttributes:
    ActivityAttributes,
    Hashable,
    Sendable {

    nonisolated struct ContentState:
        Codable,
        Hashable,
        Sendable {

        let phaseTitle: String

        let statusMessage: String

        let displayModeRawValue: String

        let pipelineStepTitles: [String]

        let activePipelineStepIndex: Int

        let queueLines: [String]

        let overflowQueueCount: Int

        let currentFileName: String?

        let completedCount: Int

        let failedCount: Int

        let totalCount: Int

        let progressPercent: Int

        let presentationStateRawValue: String

        let feedbackStateRawValue: String

        let updatedAt: Date
    }

    let jobID: String

    let jobTitle: String

    let launchSourceTitle: String
}

nonisolated enum PhotoMemoBackgroundLiveActivityDismissalHint:
    Hashable,
    Sendable {

    case immediate

    case afterDefaultLinger
}

nonisolated struct PhotoMemoBackgroundLiveActivityPayload:
    Hashable,
    Sendable {

    let jobID: UUID

    let attributes:
        PhotoMemoBackgroundActivityAttributes

    let contentState:
        PhotoMemoBackgroundActivityAttributes
        .ContentState

    let staleDate: Date?

    let relevanceScore: Double

    let dismissalHint:
        PhotoMemoBackgroundLiveActivityDismissalHint

    let isTerminal: Bool
}

extension PhotoMemoBackgroundLiveActivityPayload {

    @available(iOS 16.2, *)
    var activityContent:
        ActivityContent<
            PhotoMemoBackgroundActivityAttributes
            .ContentState
        > {

        ActivityContent(
            state: contentState,
            staleDate: staleDate,
            relevanceScore: relevanceScore
        )
    }
}

nonisolated struct PhotoMemoBackgroundLiveActivityBridgeState:
    Hashable,
    Sendable {

    var currentPayload:
        PhotoMemoBackgroundLiveActivityPayload?

    var obsoleteJobIDs:
        [UUID]

    init(
        currentPayload:
            PhotoMemoBackgroundLiveActivityPayload? = nil,
        obsoleteJobIDs: [UUID] = []
    ) {
        self.currentPayload =
            currentPayload
        self.obsoleteJobIDs =
            obsoleteJobIDs
    }
}
#endif
