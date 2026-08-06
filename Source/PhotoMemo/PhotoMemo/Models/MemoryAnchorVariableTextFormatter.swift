import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemoryAnchorVariableTextFormatter {

    static func babyAgeText(
        from elapsed: MemoryElapsedTime,
        language: MemoMarkLanguage
    ) -> String {
        if elapsed.relativeSnapshot.isOnAnchorDay {
            return language == .english
                ? "day of birth"
                : "出生当天"
        }

        return elapsed.relativeSnapshot.ageText(
            language: language
        )
    }

    static func smartAnchorText(
        from anchorResult: MemoryAnchorResult,
        language: MemoMarkLanguage
    ) -> String {

        let elapsed =
            anchorResult.elapsed

        if elapsed.isFutureRelative {
            return elapsed.relativeSnapshot.countdownText(
                language: language
            )
        }

        switch anchorResult.anchorType {
        case .birthday:
            return firstNonEmpty(
                babyAgeText(
                    from: elapsed,
                    language: language
                ),
                durationText(
                    from: elapsed,
                    language: language
                )
            )

        case .marriage:
            return durationText(
                from: elapsed,
                language: language
            )

        case .relationship,
             .exam,
             .custom:
            return elapsed.totalDays < 100
                ? elapsedText(
                    from: elapsed.totalDays,
                    language: language
                )
                : durationText(
                    from: elapsed,
                    language: language
                )

        case nil:
            return durationText(
                from: elapsed,
                language: language
            )
        }
    }

    static func durationText(
        from elapsed: MemoryElapsedTime,
        language: MemoMarkLanguage
    ) -> String {

        elapsed.relativeSnapshot.durationText(
            language: language
        )
    }

    static func rawDayText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {

        let safeTotalDays =
            max(totalDays, 0)

        switch language {
        case .simplifiedChinese:
            return "\(safeTotalDays)天"
        case .english:
            return "\(safeTotalDays) \(englishUnit("day", value: safeTotalDays))"
        }
    }

    static func elapsedText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {

        switch language {
        case .simplifiedChinese:
            return "已过\(max(totalDays, 0))天"
        case .english:
            return "\(rawDayText(from: totalDays, language: language)) elapsed"
        }
    }

    static func dayIndexText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {

        let dayIndex =
            max(totalDays, 1)

        switch language {
        case .simplifiedChinese:
            return "第\(dayIndex)天"
        case .english:
            return "Day \(dayIndex)"
        }
    }

    static func weekText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {

        let safeTotalDays =
            max(totalDays, 0)
        let weeks =
            safeTotalDays / 7
        let days =
            safeTotalDays % 7

        switch language {
        case .simplifiedChinese:
            if weeks == 0,
               days == 0 {
                return "0周"
            }

            if days == 0 {
                return "\(weeks)周"
            }

            return "\(weeks)周\(days)天"
        case .english:
            if days == 0 {
                return "\(weeks) \(englishUnit("week", value: weeks))"
            }

            return "\(weeks) \(englishUnit("week", value: weeks)) \(days) \(englishUnit("day", value: days))"
        }
    }

    static func monthAgeText(
        from totalMonths: Int,
        language: MemoMarkLanguage
    ) -> String {

        let safeTotalMonths =
            max(totalMonths, 0)

        switch language {
        case .simplifiedChinese:
            return "\(safeTotalMonths)个月"
        case .english:
            return "\(safeTotalMonths) \(englishUnit("month", value: safeTotalMonths))"
        }
    }
}

private extension MemoryAnchorVariableTextFormatter {

    static func firstNonEmpty(
        _ candidates: String...
    ) -> String {

        candidates.first {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        } ?? ""
    }

    static func englishUnit(
        _ singular: String,
        value: Int
    ) -> String {

        value == 1
            ? singular
            : "\(singular)s"
    }
}
#endif
