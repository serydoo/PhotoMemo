#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1TimeAnchorTodayPresentation: Equatable {

    let title: String
    let value: String
    let accessibilityText: String
}

enum V1TimeAnchorTodayPresenter {

    static func presentation(
        anchor: MemorySubject.TimeAnchor,
        subjectName: String,
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> V1TimeAnchorTodayPresentation {
        let anchorTitle = normalized(anchor.title) ?? "重要日子"
        let resolvedSubjectName = normalized(subjectName) ?? "记忆对象"
        let value: String

        if calendar.isDate(referenceDate, inSameDayAs: anchor.date) {
            value = anchor.resolvedAnchorType == .birthday
                ? "今天 · 出生当天"
                : "就是今天"
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
                photoDate: referenceDate
            )

            if result.isFutureRelative {
                value = result.countdownText.isEmpty
                    ? "还有\(result.primaryText)"
                    : result.countdownText
            } else {
                let elapsed = anchor.resolvedAnchorType == .birthday
                    ? result.ageText
                    : result.durationText
                value = elapsed.isEmpty
                    ? "时间答案待更新"
                    : "今天 · \(elapsed)"
            }
        }

        return V1TimeAnchorTodayPresentation(
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
}
#endif
