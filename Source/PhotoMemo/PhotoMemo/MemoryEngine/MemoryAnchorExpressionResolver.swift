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
                "\(years)岁",
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

struct MemoryAnchorAnnualOccurrence:
    Hashable {

    let date: Date
    let yearsAtOccurrence: Int
    let daysUntilOccurrence: Int

    static func resolve(
        anchorDate: Date,
        captureDate: Date,
        calendar: Calendar
    ) -> Self? {
        let anchorDay =
            calendar.startOfDay(
                for: anchorDate
            )
        let captureDay =
            calendar.startOfDay(
                for: captureDate
            )

        guard captureDay >= anchorDay else {
            return nil
        }

        let anchorComponents =
            calendar.dateComponents(
                [.month, .day],
                from: anchorDay
            )
        guard
            let anchorMonth =
                anchorComponents.month,
            let anchorDayValue =
                anchorComponents.day
        else {
            return nil
        }

        let captureYear =
            calendar.component(
                .year,
                from: captureDay
            )
        guard
            var occurrence =
                annualDate(
                    year: captureYear,
                    month: anchorMonth,
                    day: anchorDayValue,
                    calendar: calendar
                )
        else {
            return nil
        }

        if occurrence < captureDay {
            guard
                let nextOccurrence =
                    annualDate(
                        year: captureYear + 1,
                        month: anchorMonth,
                        day: anchorDayValue,
                        calendar: calendar
                    )
            else {
                return nil
            }
            occurrence = nextOccurrence
        }

        let yearsAtOccurrence =
            calendar.dateComponents(
                [.year],
                from: anchorDay,
                to: occurrence
            ).year ?? 0
        let daysUntilOccurrence =
            calendar.dateComponents(
                [.day],
                from: captureDay,
                to: occurrence
            ).day ?? 0

        return Self(
            date: occurrence,
            yearsAtOccurrence:
                max(yearsAtOccurrence, 0),
            daysUntilOccurrence:
                max(daysUntilOccurrence, 0)
        )
    }

    var countdownValueText: String {
        "\(daysUntilOccurrence)天"
    }

    var birthdayText: String {
        "\(yearsAtOccurrence)岁生日"
    }

    var anniversaryText: String {
        "\(yearsAtOccurrence)周年"
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
            MemoryAnchorRelativeSnapshot,
        annualOccurrence:
            MemoryAnchorAnnualOccurrence? = nil,
        prefersAnnualOccurrence:
            Bool = false
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

        if prefersAnnualOccurrence,
           !relativeSnapshot.isFutureRelative,
           let annualOccurrence {

            if anchorType == .birthday {
                return renderedBirthdayAnnualText(
                    subjectText: resolvedSubject,
                    style: resolvedStyle,
                    occurrence:
                        annualOccurrence
                )
            }

            if anchorType == .marriage {
                return renderedMarriageAnnualText(
                    style: resolvedStyle,
                    occurrence:
                        annualOccurrence
                )
            }

            if anchorType == .relationship {
                return renderedRelationshipAnnualText(
                    anchorTitle:
                        resolvedAnchorTitle,
                    style: resolvedStyle,
                    occurrence:
                        annualOccurrence
                )
            }
        }

        switch resolvedStyle {
        case .birthdayNatural:
            if relativeSnapshot.isFutureRelative {
                return "还有\(relativeSnapshot.countdownValueText)，\(resolvedSubject)就要出生了"
            }

            return "今天\(resolvedSubject)\(relativeSnapshot.ageText)"

        case .birthdayCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedSubject)来到世界的日子"
            }

            return "今天是\(resolvedSubject)\(relativeSnapshot.ageText)"

        case .birthdayGrowth:
            if relativeSnapshot.isFutureRelative {
                return "距离第一次见面还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedSubject)长到\(relativeSnapshot.ageText)了"

        case .birthdayWarm:
            if relativeSnapshot.isFutureRelative {
                return "等待\(resolvedSubject)到来，还有\(relativeSnapshot.countdownValueText)"
            }

            return "陪\(resolvedSubject)走到\(relativeSnapshot.ageText)"

        case .birthdayMinimal:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedSubject)出生倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedSubject)｜\(relativeSnapshot.ageText)"

        case .marriageNatural:
            if relativeSnapshot.isFutureRelative {
                return "结婚还有\(relativeSnapshot.countdownValueText)"
            }

            return "结婚已经\(relativeSnapshot.durationText)"

        case .marriageCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是结婚的日子"
            }

            return "今天是婚后\(relativeSnapshot.durationText)"

        case .marriageWarm:
            if relativeSnapshot.isFutureRelative {
                return "距离结婚还有\(relativeSnapshot.countdownValueText)"
            }

            return "与你相伴\(relativeSnapshot.durationText)"

        case .marriageMinimal:
            if relativeSnapshot.isFutureRelative {
                return "结婚倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "婚后\(relativeSnapshot.durationText)"

        case .marriageMemory:
            if relativeSnapshot.isFutureRelative {
                return "距离那一天还有\(relativeSnapshot.countdownValueText)"
            }

            return "从那一天起，已有\(relativeSnapshot.durationText)"

        case .relationshipNatural:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedSubject)距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)已经\(relativeSnapshot.durationText)"

        case .relationshipCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedAnchorTitle)"
            }

            return "今天是\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"

        case .relationshipMemory:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)起，已有\(relativeSnapshot.durationText)"

        case .relationshipWarm:
            if relativeSnapshot.isFutureRelative {
                return "期待\(resolvedAnchorTitle)，还有\(relativeSnapshot.countdownValueText)"
            }

            return "关于\(resolvedAnchorTitle)的故事，已有\(relativeSnapshot.durationText)"

        case .relationshipMinimal:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedAnchorTitle)倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)｜\(relativeSnapshot.durationText)"

        case .examNatural:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)已经过去\(relativeSnapshot.durationText)"

        case .examCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedAnchorTitle)"
            }

            return "从\(resolvedAnchorTitle)那天起，已经\(relativeSnapshot.durationText)"

        case .examMotivational:
            if relativeSnapshot.isFutureRelative {
                return "冲刺\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)结束已经\(relativeSnapshot.durationText)"

        case .examMinimal:
            if relativeSnapshot.isFutureRelative {
                return "倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "已过\(relativeSnapshot.durationText)"

        case .examRecord:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)以来，已有\(relativeSnapshot.durationText)"

        case .customNatural:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "自\(resolvedAnchorTitle)起，已有\(relativeSnapshot.durationText)"

        case .customCeremonial:
            if relativeSnapshot.isFutureRelative {
                return "再过\(relativeSnapshot.countdownValueText)，就是\(resolvedAnchorTitle)"
            }

            return "今天是\(resolvedAnchorTitle)\(relativeSnapshot.durationText)"

        case .customMemory:
            if relativeSnapshot.isFutureRelative {
                return "距离\(resolvedAnchorTitle)还有\(relativeSnapshot.countdownValueText)"
            }

            return "从\(resolvedAnchorTitle)那天起，已有\(relativeSnapshot.durationText)"

        case .customWarm:
            if relativeSnapshot.isFutureRelative {
                return "期待\(resolvedAnchorTitle)，还有\(relativeSnapshot.countdownValueText)"
            }

            return "关于\(resolvedAnchorTitle)，已经\(relativeSnapshot.durationText)"

        case .customMinimal:
            if relativeSnapshot.isFutureRelative {
                return "\(resolvedAnchorTitle)倒计时：\(relativeSnapshot.countdownValueText)"
            }

            return "\(resolvedAnchorTitle)｜\(relativeSnapshot.durationText)"
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

    static func renderedBirthdayAnnualText(
        subjectText: String,
        style: MemoryAnchorExpressionStyle,
        occurrence:
            MemoryAnchorAnnualOccurrence
    ) -> String {
        switch style {
        case .birthdayNatural:
            return "还有\(occurrence.countdownValueText)，就是\(subjectText)\(occurrence.birthdayText)"
        case .birthdayCeremonial:
            return "再过\(occurrence.countdownValueText)，就是\(subjectText)\(occurrence.birthdayText)"
        case .birthdayGrowth:
            return "\(subjectText)还有\(occurrence.countdownValueText)迎来\(occurrence.yearsAtOccurrence)岁"
        case .birthdayWarm:
            return "再等\(occurrence.countdownValueText)，\(subjectText)就\(occurrence.yearsAtOccurrence)岁了"
        case .birthdayMinimal:
            return "\(subjectText)\(occurrence.birthdayText)倒计时：\(occurrence.countdownValueText)"
        default:
            return "还有\(occurrence.countdownValueText)，就是\(subjectText)\(occurrence.birthdayText)"
        }
    }

    static func renderedMarriageAnnualText(
        style: MemoryAnchorExpressionStyle,
        occurrence:
            MemoryAnchorAnnualOccurrence
    ) -> String {
        switch style {
        case .marriageNatural:
            return "还有\(occurrence.countdownValueText)，就是结婚\(occurrence.anniversaryText)"
        case .marriageCeremonial:
            return "再过\(occurrence.countdownValueText)，就是结婚\(occurrence.anniversaryText)"
        case .marriageWarm:
            return "还有\(occurrence.countdownValueText)，就一起走过\(occurrence.anniversaryText)"
        case .marriageMinimal:
            return "结婚\(occurrence.anniversaryText)倒计时：\(occurrence.countdownValueText)"
        case .marriageMemory:
            return "还有\(occurrence.countdownValueText)，又到结婚纪念日"
        default:
            return "还有\(occurrence.countdownValueText)，就是结婚\(occurrence.anniversaryText)"
        }
    }

    static func renderedRelationshipAnnualText(
        anchorTitle: String,
        style: MemoryAnchorExpressionStyle,
        occurrence:
            MemoryAnchorAnnualOccurrence
    ) -> String {
        switch style {
        case .relationshipNatural:
            return "还有\(occurrence.countdownValueText)，就是\(anchorTitle)\(occurrence.anniversaryText)"
        case .relationshipCeremonial:
            return "再过\(occurrence.countdownValueText)，就是\(anchorTitle)\(occurrence.anniversaryText)"
        case .relationshipMemory:
            return "还有\(occurrence.countdownValueText)，又到\(anchorTitle)的日子"
        case .relationshipWarm:
            return "还有\(occurrence.countdownValueText)，这段故事就满\(occurrence.yearsAtOccurrence)年"
        case .relationshipMinimal:
            return "\(anchorTitle)\(occurrence.anniversaryText)倒计时：\(occurrence.countdownValueText)"
        default:
            return "还有\(occurrence.countdownValueText)，就是\(anchorTitle)\(occurrence.anniversaryText)"
        }
    }
}

private extension MemoryAnchorAnnualOccurrence {

    static func annualDate(
        year: Int,
        month: Int,
        day: Int,
        calendar: Calendar
    ) -> Date? {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day
            )
        )
    }
}
#endif
