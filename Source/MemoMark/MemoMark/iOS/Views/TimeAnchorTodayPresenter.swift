#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct TimeAnchorTodayPresentation: Equatable {

    let title: String
    let value: String
    let accessibilityText: String
}

enum TimeAnchorTodayPresenter {

    static func presentation(
        anchor: MemorySubject.TimeAnchor,
        subjectName: String,
        referenceDate: Date = .now,
        calendar: Calendar = .current,
        outputLanguage: MemoMarkLanguage = .simplifiedChinese
    ) -> TimeAnchorTodayPresentation {
        let anchorTitle = normalized(anchor.title)
            ?? outputLanguage.localized(
                key: "time_anchor.fallback_title",
                fallback: "时间锚点"
            )
        let resolvedSubjectName = normalized(subjectName)
            ?? outputLanguage.localized(
                key: "memory_subject.fallback_title",
                fallback: "记忆对象"
            )
        let value: String

        if calendar.isDate(referenceDate, inSameDayAs: anchor.date) {
            value = anchor.resolvedAnchorType == .birthday
                ? "\(todayLabel(for: outputLanguage)) · \(MemoryNarrativeFormatter.birthDayLabel(language: outputLanguage))"
                : anchorDayLabel(for: outputLanguage)
        } else {
            let result = AnchorEngine(calendar: calendar).build(
                from: Anchor(
                    id: anchor.id,
                    type: anchor.resolvedAnchorType,
                    title: anchorTitle,
                    date: anchor.date,
                    isCountdown: anchor.resolvedAnchorType.defaultCountdown,
                    expressionStyle: anchor.resolvedExpressionStyle
                ),
                photoDate: referenceDate,
                outputLanguage: outputLanguage
            )

            if result.isFutureRelative {
                value = result.countdownText.isEmpty
                    ? fallbackCountdown(
                        result.primaryText,
                        language: outputLanguage
                    )
                    : result.countdownText
            } else {
                let elapsed = anchor.resolvedAnchorType == .birthday
                    ? result.ageText
                    : result.durationText
                value = elapsed.isEmpty
                    ? outputLanguage.localized(
                        key: "time_anchor.pending_answer",
                        fallback: "时间答案待更新"
                    )
                    : "\(todayLabel(for: outputLanguage)) · \(elapsed)"
            }
        }

        return TimeAnchorTodayPresentation(
            title: anchorTitle,
            value: value,
            accessibilityText:
                "\(resolvedSubjectName)，\(anchorTitle)，\(value)"
        )
    }

    private static func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func todayLabel(
        for language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "今天"
        case .english:
            return "Today"
        case .japanese:
            return "今日"
        case .korean:
            return "오늘"
        }
    }

    private static func anchorDayLabel(
        for language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "就是今天"
        case .english:
            return "Today"
        case .japanese:
            return "今日はこの日"
        case .korean:
            return "오늘이에요"
        }
    }

    private static func fallbackCountdown(
        _ value: String,
        language: MemoMarkLanguage
    ) -> String {
        switch language {
        case .simplifiedChinese:
            return "还有\(value)"
        case .english:
            return "\(value) left"
        case .japanese:
            return "あと\(value)"
        case .korean:
            return "\(value) 남음"
        }
    }
}
#endif
