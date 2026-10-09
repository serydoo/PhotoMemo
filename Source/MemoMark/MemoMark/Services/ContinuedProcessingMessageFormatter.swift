import Foundation

nonisolated struct ContinuedProcessingMessage: Equatable, Sendable {
    let title: String
    let subtitle: String
}

nonisolated enum ContinuedProcessingMessageFormatter {
    static func processingTitle(language: MemoMarkLanguage) -> String {
        language.localized(key: "notification.continued.processing.title", fallback: "MemoMark is processing photos")
    }

    static func preparingSubtitle(language: MemoMarkLanguage) -> String {
        language.localized(key: "notification.continued.preparing", fallback: "Preparing photos")
    }

    static func message(for session: ExecutionSession, language: MemoMarkLanguage) -> ContinuedProcessingMessage {
        if session.totalCount > 0 && session.completedCount == session.totalCount {
            return ContinuedProcessingMessage(
                title: language.localized(key: "notification.continued.completed.title", fallback: "MemoMark photos are ready"),
                subtitle: language.localized(key: "notification.continued.completed.subtitle", fallback: "Photo processing is complete."))
        }
        let fraction = Double(session.completedProgressUnits) / Double(session.totalProgressUnits)
        let percent = fraction.formatted(.percent.precision(.fractionLength(0)).locale(language.locale))
        let stage = session.currentStage?.localizedStatusMessage(for: language) ?? preparingSubtitle(language: language)
        let subtitle = String(format: language.localized(key: "notification.continued.progress.subtitle",
            fallback: "%@ · %d/%d · %@"), locale: language.locale,
            percent, session.completedCount, session.totalCount, stage)
        return ContinuedProcessingMessage(title: processingTitle(language: language), subtitle: subtitle)
    }
}
