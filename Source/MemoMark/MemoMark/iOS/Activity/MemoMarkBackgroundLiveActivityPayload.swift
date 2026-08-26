#if os(iOS) && canImport(ActivityKit) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import ActivityKit

nonisolated struct MemoMarkBackgroundActivityAttributes:
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

nonisolated enum MemoMarkBackgroundLiveActivityDismissalHint:
    Hashable,
    Sendable {

    case immediate

    case afterDefaultLinger
}

nonisolated struct MemoMarkBackgroundLiveActivityPayload:
    Hashable,
    Sendable {

    let jobID: UUID

    let attributes:
        MemoMarkBackgroundActivityAttributes

    let contentState:
        MemoMarkBackgroundActivityAttributes
        .ContentState

    let staleDate: Date?

    let relevanceScore: Double

    let dismissalHint:
        MemoMarkBackgroundLiveActivityDismissalHint

    let isTerminal: Bool
}

extension MemoMarkBackgroundLiveActivityPayload {

    @available(iOS 16.2, *)
    var activityContent:
        ActivityContent<
            MemoMarkBackgroundActivityAttributes
            .ContentState
        > {

        ActivityContent(
            state: contentState,
            staleDate: staleDate,
            relevanceScore: relevanceScore
        )
    }
}

nonisolated struct MemoMarkBackgroundLiveActivityBridgeState:
    Hashable,
    Sendable {

    var currentPayload:
        MemoMarkBackgroundLiveActivityPayload?

    var obsoleteJobIDs:
        [UUID]

    init(
        currentPayload:
            MemoMarkBackgroundLiveActivityPayload? = nil,
        obsoleteJobIDs: [UUID] = []
    ) {
        self.currentPayload =
            currentPayload
        self.obsoleteJobIDs =
            obsoleteJobIDs
    }
}
#endif
