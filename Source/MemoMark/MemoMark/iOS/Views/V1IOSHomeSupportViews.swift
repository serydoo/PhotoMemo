#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

enum V1IOSHomeActivityState: Equatable {

    case processing

    case completed

    case failed

    func statusText(language: MemoMarkLanguage) -> String {
        switch self {
        case .processing:
            return language.localized(
                key: "home.activity.status.processing",
                fallback: "Processing"
            )
        case .completed:
            return language.localized(
                key: "home.activity.status.completed",
                fallback: "Completed"
            )
        case .failed:
            return language.localized(
                key: "home.activity.status.failed",
                fallback: "Failed"
            )
        }
    }

    var statusText: String {
        statusText(language: .interfaceStored)
    }
}

struct V1IOSHomeActivityProjection: Equatable {

    let jobID: UUID

    let state: V1IOSHomeActivityState

    let currentPosition: Int

    let totalCount: Int

    let queuedJobCount: Int

    let progressFraction: Double

    let updatedAt: Date

    func countText(language: MemoMarkLanguage) -> String {
        let key = queuedJobCount > 0
            ? "home.activity.count.queued_format"
            : "home.activity.count.format"
        let fallback = queuedJobCount > 0
            ? "Task %d / %d photos · %d more queued"
            : "Task %d / %d photos"
        let format = language.localized(key: key, fallback: fallback)

        if queuedJobCount > 0 {
            return String(
                format: format,
                locale: language.locale,
                currentPosition,
                totalCount,
                queuedJobCount
            )
        }

        return String(
            format: format,
            locale: language.locale,
            currentPosition,
            totalCount
        )
    }

    var countText: String {
        countText(language: .interfaceStored)
    }

    func statusText(language: MemoMarkLanguage) -> String {
        state.statusText(language: language)
    }

    var statusText: String {
        statusText(language: .interfaceStored)
    }

    var lifecycleID: String {
        "\(jobID.uuidString)-\(state)"
    }
}

struct V1IOSHomeActivityPresentationState {

    var isMounted = true

    var isVisible = false
}

enum V1IOSHomeActivityPresenter {

    static let completionDisplayDuration: TimeInterval = 10 * 60

    static func projection(
        from snapshot: MemoMarkBackgroundJobSnapshot?
    ) -> V1IOSHomeActivityProjection? {
        guard let snapshot, snapshot.totalCount > 0 else {
            return nil
        }

        let state: V1IOSHomeActivityState
        switch snapshot.feedbackState {
        case .preparing,
             .processing:
            state = .processing
        case .completed:
            state = .completed
        case .partialSuccess,
             .needsAttention,
             .unsupported:
            state = .failed
        }

        let currentPosition: Int
        switch state {
        case .processing:
            currentPosition = min(
                max(snapshot.completedCount + snapshot.failedCount + 1, 1),
                snapshot.totalCount
            )
        case .completed:
            currentPosition = snapshot.totalCount
        case .failed:
            currentPosition = min(
                max(snapshot.completedCount + snapshot.failedCount, 1),
                snapshot.totalCount
            )
        }

        let progressFraction: Double
        switch state {
        case .processing:
            progressFraction = min(max(snapshot.progressFraction, 0), 1)
        case .completed:
            progressFraction = 1
        case .failed:
            progressFraction = min(
                max(
                    Double(currentPosition)
                        / Double(snapshot.totalCount),
                    0
                ),
                1
            )
        }

        return V1IOSHomeActivityProjection(
            jobID: snapshot.jobID,
            state: state,
            currentPosition: currentPosition,
            totalCount: snapshot.totalCount,
            queuedJobCount: snapshot.queuedJobCount,
            progressFraction: progressFraction,
            updatedAt: snapshot.updatedAt
        )
    }

    static func shouldShow(
        _ projection: V1IOSHomeActivityProjection,
        now: Date = Date()
    ) -> Bool {
        switch projection.state {
        case .processing,
             .failed:
            return true
        case .completed:
            return now.timeIntervalSince(projection.updatedAt)
                <= completionDisplayDuration
        }
    }
}

struct V1IOSHomeQuickAction:
    Equatable,
    Identifiable {

    enum Destination:
        Hashable {
        case processPhotos
        case configurationCenter
        case timeAnchor
        case usageGuide
    }

    let id: Destination
    let title: String
    let subtitle: String
    let compactDetail: String
    let systemImage: String

    static func defaultActions(
        language: MemoMarkLanguage = .interfaceStored
    ) -> [Self] {
        [
        .init(
            id: .processPhotos,
            title: language.localized(
                key: "legacy.home.quick.process.title",
                fallback: "Process Photos"
            ),
            subtitle: language.localized(
                key: "legacy.home.quick.process.subtitle",
                fallback: "Choose photos in MemoMark when needed; share daily memories from Apple Photos"
            ),
            compactDetail: language.localized(
                key: "legacy.home.quick.process.detail",
                fallback: "Choose Photos"
            ),
            systemImage: MemoMarkSymbol.applePhotos.name
        ),
        .init(
            id: .configurationCenter,
            title: language.localized(
                key: "legacy.home.quick.configuration.title",
                fallback: "Configuration Center"
            ),
            subtitle: language.localized(
                key: "legacy.home.quick.configuration.subtitle",
                fallback: "View the configuration currently in use"
            ),
            compactDetail: language.localized(
                key: "legacy.home.quick.configuration.detail",
                fallback: "View Configuration"
            ),
            systemImage: MemoMarkSymbol.configurationCenter.name
        ),
        .init(
            id: .timeAnchor,
            title: language.localized(
                key: "legacy.home.quick.anchor.title",
                fallback: "Time Anchor"
            ),
            subtitle: language.localized(
                key: "legacy.home.quick.anchor.subtitle",
                fallback: "View the Memory Subject and active anchor"
            ),
            compactDetail: language.localized(
                key: "legacy.home.quick.anchor.detail",
                fallback: "Change Anchor"
            ),
            systemImage: MemoMarkSymbol.timeAnchor.name
        ),
        .init(
            id: .usageGuide,
            title: language.localized(
                key: "legacy.home.quick.guide.title",
                fallback: "Usage Guide"
            ),
            subtitle: language.localized(
                key: "legacy.home.quick.guide.subtitle",
                fallback: "View the Apple Photos workflow and guidance"
            ),
            compactDetail: language.localized(
                key: "legacy.home.quick.guide.detail",
                fallback: "View Guide"
            ),
            systemImage: "book.pages"
        )
        ]
    }

    static var defaultActions: [Self] {
        defaultActions(language: .interfaceStored)
    }
}

struct V1IOSHomeRecentProcessingPresentation:
    Equatable {

    let headline: String

    let subheadline: String

    let symbolName: String

    let tint:
        MemoMarkiOSQueueDiagnosticsTint

    let statusValue: String

    let sourceValue: String

    let updatedAtValue: String

    let recoveryMessage: String?

    let viewAllTitle: String

    let statusLabel: String

    let sourceLabel: String

    let updatedLabel: String

    let updatedDetail: String
}

enum V1IOSHomeRecentProcessingPresenter {

    static func presentation(
        header:
            MemoMarkiOSQueueDiagnosticsHeaderProjection,
        snapshot:
            MemoMarkBackgroundJobSnapshot?,
        recoveryMessage: String?,
        language: MemoMarkLanguage = .interfaceStored
    ) -> V1IOSHomeRecentProcessingPresentation {

        V1IOSHomeRecentProcessingPresentation(
            headline:
                header.headline,
            subheadline:
                header.subheadline,
            symbolName:
                header.symbolName,
            tint:
                header.tint,
            statusValue:
                snapshot.map {
                    localizedFeedbackState(
                        $0.feedbackState,
                        language: language
                    )
                }
                ?? (
                    recoveryMessage == nil
                    ? language.localized(
                        key: "legacy.home.recent.waiting",
                        fallback: "Waiting for the next share"
                    )
                    : language.localized(
                        key: "legacy.home.recent.recovery",
                        fallback: "Needs recovery"
                    )
                ),
            sourceValue: snapshot.map {
                localizedLaunchSource(
                    $0.launchSource,
                    language: language
                )
            }
            ?? language.localized(
                key: "legacy.home.recent.source.apple_photos",
                fallback: "Apple Photos Share"
            ),
            updatedAtValue:
                snapshot.map {
                    formattedUpdatedAt(
                        $0.updatedAt,
                        language: language
                    )
                }
                ?? language.localized(
                    key: "legacy.home.recent.empty_date",
                    fallback: "No recent update"
                ),
            recoveryMessage:
                recoveryMessage,
            viewAllTitle:
                language.localized(
                    key: "legacy.home.recent.view_all",
                    fallback: "View All"
                ),
            statusLabel:
                language.localized(
                    key: "legacy.home.recent.status_label",
                    fallback: "Status"
                ),
            sourceLabel:
                language.localized(
                    key: "legacy.home.recent.source_label",
                    fallback: "Source"
                ),
            updatedLabel:
                language.localized(
                    key: "legacy.home.recent.updated_label",
                    fallback: "Last Updated"
                ),
            updatedDetail:
                language.localized(
                    key: "legacy.home.recent.updated_detail",
                    fallback: "Keeps the latest background progress time"
                )
        )
    }
}

private extension V1IOSHomeRecentProcessingPresenter {

    static func formattedUpdatedAt(
        _ date: Date,
        language: MemoMarkLanguage
    ) -> String {

        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.dateFormat = language.localized(
            key: "legacy.home.recent.updated_date_format",
            fallback: "MMM d, HH:mm"
        )
        return formatter.string(from: date)
    }

    static func localizedFeedbackState(
        _ state: MemoMarkBackgroundFeedbackState,
        language: MemoMarkLanguage
    ) -> String {
        language.localized(
            key: "legacy.home.recent.feedback.\(state.rawValue)",
            fallback: state.displayTitle
        )
    }

    static func localizedLaunchSource(
        _ source: BatchJobLaunchSource,
        language: MemoMarkLanguage
    ) -> String {
        language.localized(
            key: "legacy.home.recent.source.\(source.rawValue)",
            fallback: source.displayTitle
        )
    }
}

struct V1IOSHomeQuickActionsContent: View {

    let language: MemoMarkLanguage = .interfaceStored

    let openPhotoPicker: () -> Void

    let openEditor: () -> Void

    let openTimeAnchor: () -> Void

    let openUsageGuide: () -> Void

    var body: some View {
        actionButtons
    }

    @ViewBuilder
    private var actionButtons: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .flexible(),
                    spacing: 8
                ),
                count: 4
            ),
            spacing: 8
        ) {
            ForEach(
                V1IOSHomeQuickAction.defaultActions(
                    language: language
                )
            ) { action in
                V1IOSHomeActionTileButton(
                    title: action.title,
                    detail: action.compactDetail,
                    systemImage: action.systemImage,
                    action: {
                        perform(action.id)
                    }
                )
            }
        }
    }

    private func perform(
        _ destination: V1IOSHomeQuickAction.Destination
    ) {
        switch destination {
        case .processPhotos:
            openPhotoPicker()
        case .configurationCenter:
            openEditor()
        case .timeAnchor:
            openTimeAnchor()
        case .usageGuide:
            openUsageGuide()
        }
    }
}

struct V1IOSHomeRecentProcessingContent: View {

    let presentation:
        V1IOSHomeRecentProcessingPresentation

    let openStatus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: presentation.symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        presentation.tint.color
                    )
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.headline)
                        .font(.subheadline.weight(.semibold))

                    Text(presentation.subheadline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer(minLength: 0)

                Button(presentation.viewAllTitle) {
                    openStatus()
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.semibold))
            }

            V1IOSHomeInsetGroup {
                facts
            }

            if let recoveryMessage =
                presentation.recoveryMessage {
                Label(
                    recoveryMessage,
                    systemImage:
                        "exclamationmark.triangle.fill"
                )
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
            }
        }
    }

    @ViewBuilder
    private var facts: some View {
        V1IOSHomeSemanticRow(
            title: presentation.statusLabel,
            value: presentation.statusValue,
            detail: presentation.headline,
            systemImage:
                MemoMarkSymbol.processing.name
        )

        V1IOSHomeSemanticRow(
            title: presentation.sourceLabel,
            value: presentation.sourceValue,
            detail: presentation.subheadline,
            systemImage:
                MemoMarkSymbol.applePhotos.name
        )

        V1IOSHomeSemanticRow(
            title: presentation.updatedLabel,
            value: presentation.updatedAtValue,
            detail: presentation.updatedDetail,
            systemImage:
                "clock.arrow.circlepath",
            showsDivider: false
        )
    }
}

#endif
