import Foundation

#if !MEMOMARK_SHARE_EXTENSION
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
        calendar: Calendar,
        comparesByCalendarDay: Bool
    ) -> Self {
        let anchorDay = comparesByCalendarDay
            ? calendar.startOfDay(for: anchorDate)
            : anchorDate
        let captureDay = comparesByCalendarDay
            ? calendar.startOfDay(for: captureDate)
            : captureDate
        let isFutureRelative =
            captureDay < anchorDay
        let startDate =
            isFutureRelative
            ? captureDay
            : anchorDay
        let endDate =
            isFutureRelative
            ? anchorDay
            : captureDay
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

    var isOnAnchorDay: Bool {
        !isFutureRelative && totalDays == 0
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
            MemoryAnchorRelativeSnapshot,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {
        if relativeSnapshot.isFutureRelative {
            return relativeSnapshot
                .countdownText(language: language)
        }

        switch anchorType {
        case .birthday:
            if relativeSnapshot.isOnAnchorDay {
                return MemoryNarrativeFormatter.birthDayLabel(
                    language: language
                )
            }
            return relativeSnapshot.ageText(language: language)
        case .relationship,
             .marriage,
             .exam,
             .custom:
            return relativeSnapshot
                .durationText(language: language)
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
            Bool = false,
        language: MemoMarkLanguage = .simplifiedChinese
    ) -> String {
        let resolvedStyle =
            MemoryAnchorExpressionStyle
            .resolvedStyle(
                for: anchorType,
                candidate: expressionStyle
            )

        if resolvedStyle.isCanonicalNatural,
           prefersAnnualOccurrence,
           !relativeSnapshot.isFutureRelative,
           let annualOccurrence {
            return canonicalAnnualText(
                subjectText: subjectText,
                anchorTitle: anchorTitle,
                anchorType: anchorType,
                annualOccurrence: annualOccurrence,
                language: language
            )
        }

        if resolvedStyle.isCanonicalNatural {
            return narrativeText(
                subjectText: subjectText,
                anchorTitle: anchorTitle,
                anchorType: anchorType,
                relativeSnapshot: relativeSnapshot,
                annualOccurrence: annualOccurrence,
                prefersAnnualOccurrence: prefersAnnualOccurrence,
                language: language
            )
        }

        // The legacy style matrix is currently localized only for Chinese and
        // English. A Japanese/Korean request must never fall through to the
        // historical Chinese branch, so use the canonical Narrative strategy
        // until those style-specific phrases are migrated.
        if language == .japanese || language == .korean {
            return narrativeText(
                subjectText: subjectText,
                anchorTitle: anchorTitle,
                anchorType: anchorType,
                relativeSnapshot: relativeSnapshot,
                annualOccurrence: annualOccurrence,
                prefersAnnualOccurrence: prefersAnnualOccurrence,
                language: language
            )
        }

        if language == .english {
            return englishRenderedText(
                subjectText: subjectText,
                anchorTitle: anchorTitle,
                anchorType: anchorType,
                expressionStyle: expressionStyle,
                relativeSnapshot: relativeSnapshot,
                annualOccurrence: annualOccurrence,
                prefersAnnualOccurrence: prefersAnnualOccurrence
            )
        }

        let resolvedSubject =
            normalizedText(subjectText)
            ?? normalizedText(anchorTitle)
            ?? "记忆对象"
        let resolvedAnchorTitle =
            normalizedText(anchorTitle)
            ?? anchorType.suggestedTitle

        if anchorType == .birthday,
           relativeSnapshot.isOnAnchorDay {
            return "\(resolvedSubject)今天来到这个世界啦！"
        }

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

    static func canonicalAnnualText(
        subjectText: String,
        anchorTitle: String,
        anchorType: AnchorType,
        annualOccurrence: MemoryAnchorAnnualOccurrence,
        language: MemoMarkLanguage
    ) -> String {
        let style = MemoryAnchorExpressionStyle.resolvedStyle(
            for: anchorType,
            candidate: nil
        )
        let subject = normalizedText(subjectText)
            ?? normalizedText(anchorTitle)
            ?? (language == .english ? "this memory" : "记忆对象")
        let title = normalizedText(anchorTitle)
            ?? anchorType.suggestedTitle

        switch language {
        case .simplifiedChinese:
            switch anchorType {
            case .birthday:
                if annualOccurrence.daysUntilOccurrence == 0 {
                    return "今天是\(subject)\(annualOccurrence.yearsAtOccurrence)岁生日"
                }
                return renderedBirthdayAnnualText(
                    subjectText: subject,
                    style: style,
                    occurrence: annualOccurrence
                )
            case .marriage:
                if annualOccurrence.daysUntilOccurrence == 0 {
                    return "今天是结婚\(annualOccurrence.yearsAtOccurrence)周年"
                }
                return renderedMarriageAnnualText(
                    style: style,
                    occurrence: annualOccurrence
                )
            case .relationship:
                if annualOccurrence.daysUntilOccurrence == 0 {
                    return "今天是\(title)\(annualOccurrence.yearsAtOccurrence)周年"
                }
                return renderedRelationshipAnnualText(
                    anchorTitle: title,
                    style: style,
                    occurrence: annualOccurrence
                )
            case .exam, .custom:
                return "还有\(annualOccurrence.countdownValueText)，就是\(title)"
            }
        case .english:
            switch anchorType {
            case .birthday:
                if annualOccurrence.daysUntilOccurrence == 0 {
                    return "Today is \(subject)'s \(annualOccurrence.englishBirthdayText)"
                }
                return englishBirthdayAnnualText(
                    subjectText: subject,
                    style: style,
                    occurrence: annualOccurrence
                )
            case .marriage:
                if annualOccurrence.daysUntilOccurrence == 0 {
                    return "Today marks \(annualOccurrence.yearsAtOccurrence) years of marriage"
                }
                return englishMarriageAnnualText(
                    style: style,
                    occurrence: annualOccurrence
                )
            case .relationship:
                if annualOccurrence.daysUntilOccurrence == 0 {
                    return "Today marks \(annualOccurrence.yearsAtOccurrence) years since \(title)"
                }
                return englishRelationshipAnnualText(
                    anchorTitle: title,
                    style: style,
                    occurrence: annualOccurrence
                )
            case .exam, .custom:
                return "\(annualOccurrence.englishCountdownValueText) until \(title)"
            }
        case .japanese, .korean:
            let days = annualOccurrence.daysUntilOccurrence
            switch anchorType {
            case .birthday:
                if days == 0 {
                    return language == .japanese
                        ? "今日は\(subject)の\(annualOccurrence.yearsAtOccurrence)歳の誕生日です"
                        : "오늘은 \(subject)의 \(annualOccurrence.yearsAtOccurrence)번째 생일입니다"
                }
                return language == .japanese
                    ? "あと\(days)日で\(subject)の\(annualOccurrence.yearsAtOccurrence)歳の誕生日"
                    : "\(days)일 후 \(subject)의 \(annualOccurrence.yearsAtOccurrence)번째 생일입니다"
            case .marriage:
                let marriageTitle = language == .japanese ? "結婚" : "결혼"
                if days == 0 {
                    return language == .japanese
                        ? "今日は\(marriageTitle)\(annualOccurrence.yearsAtOccurrence)周年です"
                        : "오늘은 \(marriageTitle) \(annualOccurrence.yearsAtOccurrence)주년입니다"
                }
                return language == .japanese
                    ? "あと\(days)日で\(marriageTitle)\(annualOccurrence.yearsAtOccurrence)周年です"
                    : "\(days)일 후 \(marriageTitle) \(annualOccurrence.yearsAtOccurrence)주년입니다"
            case .relationship, .exam, .custom:
                if days == 0 {
                    return language == .japanese
                        ? "今日は\(title)\(annualOccurrence.yearsAtOccurrence)周年です"
                        : "오늘은 \(title) \(annualOccurrence.yearsAtOccurrence)주년입니다"
                }
                return language == .japanese
                    ? "あと\(days)日で\(title)\(annualOccurrence.yearsAtOccurrence)周年です"
                    : "\(days)일 후 \(title) \(annualOccurrence.yearsAtOccurrence)주년입니다"
            }
        }
    }

    static func narrativeText(
        subjectText: String,
        anchorTitle: String,
        anchorType: AnchorType,
        relativeSnapshot: MemoryAnchorRelativeSnapshot,
        annualOccurrence: MemoryAnchorAnnualOccurrence?,
        prefersAnnualOccurrence: Bool,
        language: MemoMarkLanguage
    ) -> String {

        let occurrence: MemoryNarrativeOccurrence
        if relativeSnapshot.isFutureRelative {
            occurrence = .countdown
        } else if prefersAnnualOccurrence,
                  annualOccurrence != nil {
            occurrence = .anniversary
        } else if relativeSnapshot.isOnAnchorDay {
            occurrence = anchorType == .birthday
                ? .birthDay
                : .anchorDay
        } else {
            occurrence = .elapsed
        }

        return MemoryNarrativeFormatter.format(
            context: MemoryNarrativeContext(
                anchorType: anchorType,
                subjectDisplayName: subjectText,
                anchorTitle: anchorTitle,
                occurrence: occurrence,
                ageComponents:
                    anchorType == .birthday
                    ? MemoryAgeComponents(
                        years: relativeSnapshot.years,
                        months: relativeSnapshot.months,
                        days: relativeSnapshot.days
                    )
                    : nil,
                durationComponents:
                    MemoryDurationComponents(
                        years: relativeSnapshot.years,
                        months: relativeSnapshot.months,
                        days: relativeSnapshot.days,
                        totalDays: relativeSnapshot.totalDays
                    ),
                countdownComponents:
                    occurrence == .countdown
                    ? MemoryCountdownComponents(
                        totalDays: relativeSnapshot.totalDays
                    )
                    : nil,
                annualOccurrence: annualOccurrence,
                expressionStyle:
                    MemoryAnchorExpressionStyle.resolvedStyle(
                        for: anchorType,
                        candidate: nil
                    ),
                language: language,
                formattingMode: .legacyCompatible
            )
        )
    }

    static func englishRenderedText(
        subjectText: String,
        anchorTitle: String,
        anchorType: AnchorType,
        expressionStyle: MemoryAnchorExpressionStyle?,
        relativeSnapshot: MemoryAnchorRelativeSnapshot,
        annualOccurrence: MemoryAnchorAnnualOccurrence?,
        prefersAnnualOccurrence: Bool
    ) -> String {
        let resolvedStyle = MemoryAnchorExpressionStyle.resolvedStyle(
            for: anchorType,
            candidate: expressionStyle
        )
        let subject = normalizedText(subjectText) ?? normalizedText(anchorTitle) ?? "this memory"
        let title = normalizedText(anchorTitle) ?? anchorType.suggestedTitle

        if anchorType == .birthday,
           relativeSnapshot.isOnAnchorDay {
            return "\(subject) arrived in the world today"
        }

        if prefersAnnualOccurrence,
           !relativeSnapshot.isFutureRelative,
           let annualOccurrence {
            switch anchorType {
            case .birthday:
                return englishBirthdayAnnualText(
                    subjectText: subject,
                    style: resolvedStyle,
                    occurrence: annualOccurrence
                )
            case .marriage:
                return englishMarriageAnnualText(
                    style: resolvedStyle,
                    occurrence: annualOccurrence
                )
            case .relationship:
                return englishRelationshipAnnualText(
                    anchorTitle: title,
                    style: resolvedStyle,
                    occurrence: annualOccurrence
                )
            case .exam, .custom:
                break
            }
        }

        let duration = relativeSnapshot.durationText(language: .english)
        let age = relativeSnapshot.ageText(language: .english)
        let countdown = relativeSnapshot.countdownValueText(language: .english)

        switch resolvedStyle {
        case .birthdayNatural:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(subject) arrives"
                : "\(subject) is \(age) old today"
        case .birthdayCeremonial:
            return relativeSnapshot.isFutureRelative
                ? "In \(countdown), \(subject) will arrive"
                : "Today, \(subject) is \(age) old"
        case .birthdayGrowth:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until we first meet"
                : "\(subject) has grown to \(age)"
        case .birthdayWarm:
            return relativeSnapshot.isFutureRelative
                ? "Waiting for \(subject), \(countdown) to go"
                : "With \(subject) for \(age)"
        case .birthdayMinimal:
            return relativeSnapshot.isFutureRelative
                ? "\(subject) arrives in \(countdown)"
                : "\(subject) | \(age)"
        case .marriageNatural:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until we get married"
                : "Married for \(duration)"
        case .marriageCeremonial:
            return relativeSnapshot.isFutureRelative
                ? "In \(countdown), we get married"
                : "Today marks \(duration) of marriage"
        case .marriageWarm:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until we say I do"
                : "Together for \(duration)"
        case .marriageMinimal:
            return relativeSnapshot.isFutureRelative
                ? "Wedding in \(countdown)"
                : "Married \(duration)"
        case .marriageMemory:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until that day"
                : "\(duration) since that day"
        case .relationshipNatural:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "\(title) has been \(duration)"
        case .relationshipCeremonial:
            return relativeSnapshot.isFutureRelative
                ? "In \(countdown), it will be \(title)"
                : "Today marks \(duration) with \(title)"
        case .relationshipMemory:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "\(duration) since \(title)"
        case .relationshipWarm:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "The story of \(title), \(duration)"
        case .relationshipMinimal:
            return relativeSnapshot.isFutureRelative
                ? "\(title) in \(countdown)"
                : "\(title) | \(duration)"
        case .examNatural:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "\(title) was \(duration) ago"
        case .examCeremonial:
            return relativeSnapshot.isFutureRelative
                ? "In \(countdown), it will be \(title)"
                : "\(duration) since \(title)"
        case .examMotivational:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) to \(title)"
                : "\(duration) since \(title)"
        case .examMinimal:
            return relativeSnapshot.isFutureRelative
                ? "Countdown: \(countdown)"
                : "\(duration) passed"
        case .examRecord:
            return relativeSnapshot.isFutureRelative
                ? "\(title) in \(countdown)"
                : "\(duration) since \(title)"
        case .customNatural:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "\(duration) since \(title)"
        case .customCeremonial:
            return relativeSnapshot.isFutureRelative
                ? "In \(countdown), it will be \(title)"
                : "Today marks \(duration) with \(title)"
        case .customMemory:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "\(duration) since \(title)"
        case .customWarm:
            return relativeSnapshot.isFutureRelative
                ? "\(countdown) until \(title)"
                : "The story of \(title), \(duration)"
        case .customMinimal:
            return relativeSnapshot.isFutureRelative
                ? "\(title) in \(countdown)"
                : "\(title) | \(duration)"
        }
    }

    static func englishBirthdayAnnualText(
        subjectText: String,
        style: MemoryAnchorExpressionStyle,
        occurrence: MemoryAnchorAnnualOccurrence
    ) -> String {
        let countdown = occurrence.englishCountdownValueText
        let birthday = occurrence.englishBirthdayText
        switch style {
        case .birthdayNatural:
            return "\(countdown) until \(subjectText)'s \(birthday)"
        case .birthdayCeremonial:
            return "In \(countdown), \(subjectText) turns \(occurrence.yearsAtOccurrence)"
        case .birthdayGrowth:
            return "\(subjectText) turns \(occurrence.yearsAtOccurrence) in \(countdown)"
        case .birthdayWarm:
            return "\(countdown) until \(subjectText) turns \(occurrence.yearsAtOccurrence)"
        case .birthdayMinimal:
            return "\(subjectText)'s \(birthday) in \(countdown)"
        default:
            return "\(countdown) until \(subjectText)'s \(birthday)"
        }
    }

    static func englishMarriageAnnualText(
        style: MemoryAnchorExpressionStyle,
        occurrence: MemoryAnchorAnnualOccurrence
    ) -> String {
        let countdown = occurrence.englishCountdownValueText
        let anniversary = occurrence.englishAnniversaryText
        switch style {
        case .marriageNatural:
            return "\(countdown) until our \(anniversary)"
        case .marriageCeremonial:
            return "In \(countdown), we celebrate our \(anniversary)"
        case .marriageWarm:
            return "\(countdown) until we reach our \(anniversary)"
        case .marriageMinimal:
            return "Our \(anniversary) in \(countdown)"
        case .marriageMemory:
            return "\(countdown) until our anniversary"
        default:
            return "\(countdown) until our \(anniversary)"
        }
    }

    static func englishRelationshipAnnualText(
        anchorTitle: String,
        style: MemoryAnchorExpressionStyle,
        occurrence: MemoryAnchorAnnualOccurrence
    ) -> String {
        let countdown = occurrence.englishCountdownValueText
        let anniversary = occurrence.englishAnniversaryText
        switch style {
        case .relationshipNatural:
            return "\(countdown) until \(anchorTitle)'s \(anniversary)"
        case .relationshipCeremonial:
            return "In \(countdown), we celebrate \(anchorTitle)'s \(anniversary)"
        case .relationshipMemory:
            return "\(countdown) until \(anchorTitle)'s day"
        case .relationshipWarm:
            return "\(countdown) until \(anchorTitle)'s \(anniversary)"
        case .relationshipMinimal:
            return "\(anchorTitle)'s \(anniversary) in \(countdown)"
        default:
            return "\(countdown) until \(anchorTitle)'s \(anniversary)"
        }
    }

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
