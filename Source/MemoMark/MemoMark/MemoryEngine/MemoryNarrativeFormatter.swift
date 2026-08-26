import Foundation

enum MemoryNarrativeOccurrence: String, Codable, Hashable {

    case birthDay
    case anchorDay
    case elapsed
    case countdown
    case anniversary
}

enum MemoryNarrativeFormattingMode: Hashable {

    case canonical
    case legacyCompatible
}

struct MemoryNarrativeContext: Hashable {

    let anchorType: AnchorType
    let subjectDisplayName: String
    let anchorTitle: String
    let occurrence: MemoryNarrativeOccurrence
    let ageComponents: MemoryAgeComponents?
    let durationComponents: MemoryDurationComponents?
    let countdownComponents: MemoryCountdownComponents?
    let annualOccurrence: MemoryAnchorAnnualOccurrence?
    let expressionStyle: MemoryAnchorExpressionStyle?
    let captureDate: Date?
    let language: MemoMarkLanguage
    let formattingMode: MemoryNarrativeFormattingMode

    init(
        anchorType: AnchorType,
        subjectDisplayName: String,
        anchorTitle: String,
        occurrence: MemoryNarrativeOccurrence,
        ageComponents: MemoryAgeComponents? = nil,
        durationComponents: MemoryDurationComponents? = nil,
        countdownComponents: MemoryCountdownComponents? = nil,
        annualOccurrence: MemoryAnchorAnnualOccurrence? = nil,
        expressionStyle: MemoryAnchorExpressionStyle? = nil,
        captureDate: Date? = nil,
        language: MemoMarkLanguage,
        formattingMode: MemoryNarrativeFormattingMode = .canonical
    ) {
        self.anchorType = anchorType
        self.subjectDisplayName = subjectDisplayName
        self.anchorTitle = anchorTitle
        self.occurrence = occurrence
        self.ageComponents = ageComponents
        self.durationComponents = durationComponents
        self.countdownComponents = countdownComponents
        self.annualOccurrence = annualOccurrence
        self.expressionStyle = expressionStyle
        self.captureDate = captureDate
        self.language = language
        self.formattingMode = formattingMode
    }
}

protocol MemoryNarrativeFormatting {

    func birthDayLabel() -> String

    func format(
        _ context: MemoryNarrativeContext
    ) -> String
}

enum MemoryNarrativeFormatter {

    static func birthDayLabel(
        language: MemoMarkLanguage
    ) -> String {
        strategy(for: language).birthDayLabel()
    }

    static func format(
        context: MemoryNarrativeContext
    ) -> String {
        strategy(for: context.language).format(context)
    }

    private static func strategy(
        for language: MemoMarkLanguage
    ) -> any MemoryNarrativeFormatting {
        switch language {
        case .simplifiedChinese:
            return SimplifiedChineseMemoryNarrativeStrategy()
        case .english:
            return EnglishMemoryNarrativeStrategy()
        case .japanese:
            return JapaneseMemoryNarrativeStrategy()
        case .korean:
            return KoreanMemoryNarrativeStrategy()
        }
    }
}

private struct SimplifiedChineseMemoryNarrativeStrategy:
    MemoryNarrativeFormatting {

    func birthDayLabel() -> String {
        "出生当天"
    }

    func format(
        _ context: MemoryNarrativeContext
    ) -> String {
        if context.formattingMode == .legacyCompatible {
            return legacyFormat(context)
        }

        switch context.occurrence {
        case .birthDay:
            return "\(subject(context))今天来到这个世界啦！"
        case .elapsed:
            return elapsed(context)
        case .countdown:
            return countdown(context)
        case .anchorDay:
            return "今天是\(title(context))"
        case .anniversary:
            return anniversary(context)
        }
    }

    private func legacyFormat(
        _ context: MemoryNarrativeContext
    ) -> String {
        switch context.occurrence {
        case .birthDay:
            return "\(subject(context))今天来到这个世界啦！"
        case .elapsed:
            let value = (context.anchorType == .birthday
                ? context.ageComponents.map {
                    MemoryAgeFormatter.format(
                        $0,
                        language: .simplifiedChinese
                    )
                }
                : context.durationComponents.map {
                MemoryDurationFormatter.format(
                    $0,
                    language: .simplifiedChinese
                )
                }) ?? "0天"
            switch context.anchorType {
            case .birthday:
                return "今天\(subject(context))\(value)"
            case .marriage:
                return "结婚已经\(value)"
            case .relationship:
                return "\(title(context))已经\(value)"
            case .exam:
                return "\(title(context))已经过去\(value)"
            case .custom:
                return "自\(title(context))起，已有\(value)"
            }
        case .countdown:
            let value = context.countdownComponents.map {
                MemoryCountdownFormatter.format(
                    $0,
                    language: .simplifiedChinese
                )
            } ?? "0天"
            switch context.anchorType {
            case .birthday:
                return "还有\(value)，\(subject(context))就要出生了"
            case .marriage:
                return "结婚还有\(value)"
            case .relationship,
                 .exam,
                 .custom:
                return "距离\(title(context))还有\(value)"
            }
        case .anchorDay:
            return "今天是\(title(context))"
        case .anniversary:
            return anniversary(context)
        }
    }

    private func elapsed(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.anchorType == .birthday
            ? context.ageComponents.map {
                MemoryAgeFormatter.format(
                    $0,
                    language: .simplifiedChinese
                )
            }
            : context.durationComponents.map {
                MemoryDurationFormatter.format(
                    $0,
                    language: .simplifiedChinese
                )
            }
        guard let age = context.ageComponents,
              age.years > 0 || age.months > 0
        else {
            // Keep the established short natural form for day-only ages.
            return "今天\(subject(context))\(value ?? "0天")"
        }

        return "今天\(subject(context))\(value ?? "0天")啦！"
    }

    private func countdown(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.countdownComponents.map {
            MemoryCountdownFormatter.format(
                $0,
                language: .simplifiedChinese
            )
        } ?? "0天"
        if context.anchorType == .birthday {
            return "还有\(value)，\(subject(context))就要出生了"
        }
        return "还有\(value)到\(title(context))"
    }

    private func anniversary(
        _ context: MemoryNarrativeContext
    ) -> String {
        let years = context.annualOccurrence?.yearsAtOccurrence ?? 0
        return "今天是\(title(context))\(years)周年"
    }

    private func subject(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.subjectDisplayName, fallback: "宝宝")
    }

    private func title(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.anchorTitle, fallback: "这一天")
    }
}

private struct EnglishMemoryNarrativeStrategy:
    MemoryNarrativeFormatting {

    func birthDayLabel() -> String {
        "Day of birth"
    }

    func format(
        _ context: MemoryNarrativeContext
    ) -> String {
        if context.formattingMode == .legacyCompatible {
            return legacyFormat(context)
        }

        switch context.occurrence {
        case .birthDay:
            return "\(subject(context)) arrived in the world today"
        case .elapsed:
            return elapsed(context)
        case .countdown:
            return countdown(context)
        case .anchorDay:
            return "Today is \(title(context))"
        case .anniversary:
            return anniversary(context)
        }
    }

    private func legacyFormat(
        _ context: MemoryNarrativeContext
    ) -> String {
        switch context.occurrence {
        case .birthDay:
            return "\(subject(context)) arrived in the world today"
        case .elapsed:
            let value = (context.anchorType == .birthday
                ? context.ageComponents.map {
                    MemoryAgeFormatter.format(
                        $0,
                        language: .english
                    )
                }
                : context.durationComponents.map {
                MemoryDurationFormatter.format(
                    $0,
                    language: .english
                )
                }) ?? "0 days"
            switch context.anchorType {
            case .birthday:
                return "\(subject(context)) is \(value) old today"
            case .marriage:
                return "Married for \(value)"
            case .relationship:
                return "\(title(context)) has been \(value)"
            case .exam:
                return "\(title(context)) was \(value) ago"
            case .custom:
                return "\(value) since \(title(context))"
            }
        case .countdown:
            let value = context.countdownComponents.map {
                MemoryCountdownFormatter.format(
                    $0,
                    language: .english
                )
            } ?? "0 days"
            switch context.anchorType {
            case .birthday:
                return "\(value) until \(subject(context)) arrives"
            case .marriage:
                return "\(value) until we get married"
            case .relationship,
                 .exam,
                 .custom:
                return "\(value) until \(title(context))"
            }
        case .anchorDay:
            return "Today is \(title(context))"
        case .anniversary:
            return anniversary(context)
        }
    }

    private func elapsed(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.anchorType == .birthday
            ? context.ageComponents.map {
                MemoryAgeFormatter.format(
                    $0,
                    language: .english
                )
            }
            : context.durationComponents.map {
                MemoryDurationFormatter.format(
                    $0,
                    language: .english
                )
            }
        if context.anchorType == .birthday {
            return "\(subject(context)) is \(value ?? "0 days") old today"
        }
        return "\(value ?? "0 days") since \(title(context))"
    }

    private func countdown(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.countdownComponents.map {
            MemoryCountdownFormatter.format(
                $0,
                language: .english
            )
        } ?? "0 days"
        if context.anchorType == .birthday {
            return "\(value) until \(subject(context)) arrives"
        }
        return "\(value) until \(title(context))"
    }

    private func anniversary(
        _ context: MemoryNarrativeContext
    ) -> String {
        let years = context.annualOccurrence?.yearsAtOccurrence ?? 0
        if context.anchorType == .marriage {
            return "Today marks \(years) years of marriage"
        }
        return "Today marks \(years) years since \(title(context))"
    }

    private func subject(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.subjectDisplayName, fallback: "Baby")
    }

    private func title(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.anchorTitle, fallback: "this day")
    }
}

private struct JapaneseMemoryNarrativeStrategy:
    MemoryNarrativeFormatting {

    func birthDayLabel() -> String {
        "生まれた日"
    }

    func format(
        _ context: MemoryNarrativeContext
    ) -> String {
        switch context.occurrence {
        case .birthDay:
            return "\(subject(context))が生まれた日"
        case .elapsed:
            return elapsed(context)
        case .countdown:
            return countdown(context)
        case .anchorDay:
            return "今日は\(title(context))"
        case .anniversary:
            return anniversary(context)
        }
    }

    private func elapsed(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.anchorType == .birthday
            ? context.ageComponents.map {
                MemoryAgeFormatter.format(
                    $0,
                    language: .japanese
                )
            }
            : context.durationComponents.map {
                MemoryDurationFormatter.format(
                    $0,
                    language: .japanese
                )
            }
        if context.anchorType == .birthday {
            return "今日は\(subject(context))が\(value ?? "0日")です"
        }
        return "\(title(context))から\(value ?? "0日")です"
    }

    private func countdown(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.countdownComponents.map {
            MemoryCountdownFormatter.format(
                $0,
                language: .japanese
            )
        } ?? "0日"
        if context.anchorType == .birthday {
            return "あと\(value)で\(subject(context))が生まれます"
        }
        return "あと\(value)で\(title(context))です"
    }

    private func anniversary(
        _ context: MemoryNarrativeContext
    ) -> String {
        let years = context.annualOccurrence?.yearsAtOccurrence ?? 0
        if context.anchorType == .marriage {
            return "今日は結婚\(years)周年です"
        }
        return "今日は\(title(context))\(years)周年です"
    }

    private func subject(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.subjectDisplayName, fallback: "Baby")
    }

    private func title(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.anchorTitle, fallback: "この日")
    }
}

private struct KoreanMemoryNarrativeStrategy:
    MemoryNarrativeFormatting {

    func birthDayLabel() -> String {
        "태어난 날"
    }

    func format(
        _ context: MemoryNarrativeContext
    ) -> String {
        switch context.occurrence {
        case .birthDay:
            return "\(subject(context))가 태어난 날"
        case .elapsed:
            return elapsed(context)
        case .countdown:
            return countdown(context)
        case .anchorDay:
            return "오늘은 \(title(context))"
        case .anniversary:
            return anniversary(context)
        }
    }

    private func elapsed(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.anchorType == .birthday
            ? context.ageComponents.map {
                MemoryAgeFormatter.format(
                    $0,
                    language: .korean
                )
            }
            : context.durationComponents.map {
                MemoryDurationFormatter.format(
                    $0,
                    language: .korean
                )
            }
        if context.anchorType == .birthday {
            return "오늘 \(subject(context))는 \(value ?? "0일")입니다"
        }
        return "\(title(context))부터 \(value ?? "0일")입니다"
    }

    private func countdown(
        _ context: MemoryNarrativeContext
    ) -> String {
        let value = context.countdownComponents.map {
            MemoryCountdownFormatter.format(
                $0,
                language: .korean
            )
        } ?? "0일"
        if context.anchorType == .birthday {
            return "\(value) 후 \(subject(context))가 태어납니다"
        }
        return "\(value) 후 \(title(context))입니다"
    }

    private func anniversary(
        _ context: MemoryNarrativeContext
    ) -> String {
        let years = context.annualOccurrence?.yearsAtOccurrence ?? 0
        if context.anchorType == .marriage {
            return "오늘은 결혼 \(years)주년입니다"
        }
        return "오늘은 \(title(context)) \(years)주년입니다"
    }

    private func subject(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.subjectDisplayName, fallback: "Baby")
    }

    private func title(
        _ context: MemoryNarrativeContext
    ) -> String {
        nonEmpty(context.anchorTitle, fallback: "이 날")
    }
}

extension MemoryAnchorExpressionStyle {

    var isCanonicalNatural: Bool {
        switch self {
        case .birthdayNatural,
             .marriageNatural,
             .relationshipNatural,
             .examNatural,
             .customNatural:
            return true
        default:
            return false
        }
    }
}

private func nonEmpty(
    _ value: String,
    fallback: String
) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? fallback : trimmed
}
