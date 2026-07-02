import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryAnchorRelativeSnapshot:
    Codable,
    Hashable {

    let years: Int
    let months: Int
    let days: Int
    let totalDays: Int
    let isFutureRelative: Bool

    init(
        years: Int,
        months: Int,
        days: Int,
        totalDays: Int,
        isFutureRelative: Bool
    ) {
        self.years = max(years, 0)
        self.months = max(months, 0)
        self.days = max(days, 0)
        self.totalDays = max(totalDays, 0)
        self.isFutureRelative =
            isFutureRelative
    }

    static func resolve(
        anchorDate: Date,
        captureDate: Date,
        calendar: Calendar
    ) -> Self {
        let isFutureRelative =
            captureDate < anchorDate
        let startDate =
            isFutureRelative
            ? captureDate
            : anchorDate
        let endDate =
            isFutureRelative
            ? anchorDate
            : captureDate
        let components =
            calendar.dateComponents(
                [.year, .month, .day],
                from: startDate,
                to: endDate
            )
        let totalDays =
            calendar.dateComponents(
                [.day],
                from: startDate,
                to: endDate
            ).day ?? 0

        return Self(
            years: components.year ?? 0,
            months: components.month ?? 0,
            days: components.day ?? 0,
            totalDays: totalDays,
            isFutureRelative:
                isFutureRelative
        )
    }

    var ageText: String {
        if years > 0 {
            return [
                "\(years)年",
                months > 0
                    ? "\(months)个月"
                    : nil,
                days > 0
                    ? "\(days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        if months > 0 {
            return [
                "\(months)个月",
                days > 0
                    ? "\(days)天"
                    : nil
            ]
            .compactMap { $0 }
            .joined()
        }

        return "\(days)天"
    }

    var durationText: String {
        let parts = [
            years > 0 ? "\(years)年" : nil,
            months > 0 ? "\(months)个月" : nil,
            days > 0 ? "\(days)天" : nil
        ]
        .compactMap { $0 }

        return parts.isEmpty
            ? "0天"
            : parts.joined()
    }

    var countdownText: String {
        "还有\(totalDays)天"
    }

    var countdownValueText: String {
        "\(totalDays)天"
    }
}

enum MemoryAnchorExpressionResolver {

    static func semanticKind(
        anchorType: AnchorType,
        relativeSnapshot:
            MemoryAnchorRelativeSnapshot
    ) -> MemorySemanticKind {
        if relativeSnapshot.isFutureRelative {
            return .countdown
        }

        switch anchorType {
        case .birthday:
            return .birthdayAge
        case .relationship:
            return .relationshipDuration
        case .marriage:
            return .marriageDuration
        case .exam:
            return .examDuration
        case .custom:
            return .customDuration
        }
    }

    static func semanticDisplayText(
        anchorType: AnchorType,
        relativeSnapshot:
            MemoryAnchorRelativeSnapshot
    ) -> String {
        if relativeSnapshot.isFutureRelative {
            return relativeSnapshot
                .countdownText
        }

        switch anchorType {
        case .birthday:
            return relativeSnapshot.ageText
        case .relationship,
             .marriage,
             .exam,
             .custom:
            return relativeSnapshot
                .durationText
        }
    }

    static func renderedText(
        subjectText: String,
        anchorTitle: String,
        anchorType: AnchorType,
        expressionStyle:
            MemoryAnchorExpressionStyle?,
        relativeSnapshot:
            MemoryAnchorRelativeSnapshot
    ) -> String {
        let resolvedStyle =
            MemoryAnchorExpressionStyle
            .resolvedStyle(
                for: anchorType,
                candidate: expressionStyle
            )
        let resolvedSubject =
            normalizedText(subjectText)
            ?? normalizedText(anchorTitle)
            ?? "记忆对象"
        let resolvedAnchorTitle =
            normalizedText(anchorTitle)
            ?? anchorType.suggestedTitle

        switch resolvedStyle {
        case .birthdayNatural:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedSubject)出生还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedSubject)今天\(relativeSnapshot.ageText)啦！"

        case .birthdayCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedSubject)生日"
            }

            return "今天是\(resolvedSubject)\(relativeSnapshot.ageText)"

        case .birthdayGrowth:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedSubject)还有\(relativeSnapshot.countdownValueText)迎来新的一岁"
            }

            return "\(resolvedSubject)成长到\(relativeSnapshot.ageText)"

        case .birthdayWarm:
            if relativeSnapshot.isFutureRelative {
                return "等待\(resolvedSubject)生日，还有\(relativeSnapshot.countdownValueText)"
            }

            return "陪伴\(resolvedSubject)\(relativeSnapshot.ageText)"

        case .birthdayMinimal:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedSubject)生日倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedSubject)\(relativeSnapshot.ageText)"

        case .marriageNatural:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedSubject)结婚还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedSubject)婚后\(relativeSnapshot.durationText)"

        case .marriageCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是结婚纪念日"
            }

            return "今天是婚后\(relativeSnapshot.durationText)"

        case .marriageWarm:
            if relativeSnapshot.isFutureRelative {
                return "距离结婚纪念日还有\(relativeSnapshot.countdownValueText)"
            }

            return "与你相伴\(relativeSnapshot.durationText)"

        case .marriageMinimal:
            if relativeSnapshot.isFutureRelative {
                return "婚礼倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "婚后\(relativeSnapshot.durationText)"

        case .marriageMemory:
            if relativeSnapshot.isFutureRelative {
                return "距离人生重要的一天还有\(relativeSnapshot.countdownValueText)"
            }

            return "从那一天起已有\(relativeSnapshot.durationText)"

        case .relationshipNatural:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedSubject)距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedSubject)与\(resolvedAnchorTitle)已有\(relativeSnapshot.durationText)"

        case .relationshipCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedAnchorTitle)"
            }

            return "今天是\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"

        case .relationshipMemory:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)起已有\(relativeSnapshot.durationText)"

        case .relationshipWarm:
            if relativeSnapshot.isFutureRelative {
                return "期待\(resolvedAnchorTitle)，还有\(relativeSnapshot.countdownValueText)"
            }

            return "关于\(resolvedAnchorTitle)的故事已有\(relativeSnapshot.durationText)"

        case .relationshipMinimal:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedAnchorTitle)倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"

        case .examNatural:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)已经\(relativeSnapshot.durationText)"

        case .examCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedAnchorTitle)"
            }

            return "今天距离\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"

        case .examMotivational:
            if relativeSnapshot.isFutureRelative {
                return "冲刺\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)圆满结束\(relativeSnapshot.durationText)"

        case .examMinimal:
            if relativeSnapshot.isFutureRelative {
                return "倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "已过\(relativeSnapshot.durationText)"

        case .examRecord:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)以来已有\(relativeSnapshot.durationText)"

        case .customNatural:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)起已有\(relativeSnapshot.durationText)"

        case .customCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedAnchorTitle)"
            }

            return "今天是\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"

        case .customMemory:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)起已有\(relativeSnapshot.durationText)"

        case .customWarm:
            if relativeSnapshot.isFutureRelative {
                return "期待\(resolvedAnchorTitle)，还有\(relativeSnapshot.countdownValueText)"
            }

            return "关于\(resolvedAnchorTitle)已有\(relativeSnapshot.durationText)"

        case .customMinimal:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedAnchorTitle)倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"
        }
    }
}

private extension MemoryAnchorExpressionResolver {

    static func normalizedText(
        _ text: String
    ) -> String? {
        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
#endif
