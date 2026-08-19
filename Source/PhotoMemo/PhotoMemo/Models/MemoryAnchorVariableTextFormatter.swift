import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemoryAnchorVariableTextFormatter {

    static func babyAgeText(
        from elapsed: MemoryElapsedTime,
        language: MemoMarkLanguage
    ) -> String {
        if elapsed.relativeSnapshot.isOnAnchorDay {
            return MemoryNarrativeFormatter.birthDayLabel(
                language: language
            )
        }

        return MemoryAgeFormatter.format(
            MemoryAgeComponents(
                years: elapsed.years,
                months: elapsed.months,
                days: elapsed.days
            ),
            language: language
        )
    }

    static func smartAnchorText(
        from anchorResult: MemoryAnchorResult,
        language: MemoMarkLanguage
    ) -> String {

        let elapsed = anchorResult.elapsed

        if elapsed.isFutureRelative {
            return MemoryCountdownPhraseFormatter.format(
                totalDays: elapsed.totalDays,
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
        MemoryDurationFormatter.format(
            MemoryDurationComponents(
                years: elapsed.years,
                months: elapsed.months,
                days: elapsed.days,
                totalDays: elapsed.totalDays
            ),
            language: language
        )
    }

    static func rawDayText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryCountdownFormatter.format(
            MemoryCountdownComponents(totalDays: totalDays),
            language: language
        )
    }

    static func elapsedText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryElapsedFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    static func dayIndexText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryDayIndexFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    static func weekText(
        from totalDays: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryWeekFormatter.format(
            totalDays: totalDays,
            language: language
        )
    }

    static func monthAgeText(
        from totalMonths: Int,
        language: MemoMarkLanguage
    ) -> String {
        MemoryMonthAgeFormatter.format(
            totalMonths: totalMonths,
            language: language
        )
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
}
#endif
