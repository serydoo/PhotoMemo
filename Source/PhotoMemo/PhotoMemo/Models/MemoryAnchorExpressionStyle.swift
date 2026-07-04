import Foundation

enum MemoryAnchorExpressionStyle:
    Codable,
    Hashable,
    CaseIterable,
    Identifiable {

    case birthdayNatural
    case birthdayCeremonial
    case birthdayGrowth
    case birthdayWarm
    case birthdayMinimal

    case marriageNatural
    case marriageCeremonial
    case marriageWarm
    case marriageMinimal
    case marriageMemory

    case relationshipNatural
    case relationshipCeremonial
    case relationshipMemory
    case relationshipWarm
    case relationshipMinimal

    case examNatural
    case examCeremonial
    case examMotivational
    case examMinimal
    case examRecord

    case customNatural
    case customCeremonial
    case customMemory
    case customWarm
    case customMinimal

    var id: String {
        rawValue
    }

    var rawValue: String {
        switch self {
        case .birthdayNatural:
            return "birthdayNatural"
        case .birthdayCeremonial:
            return "birthdayCeremonial"
        case .birthdayGrowth:
            return "birthdayGrowth"
        case .birthdayWarm:
            return "birthdayWarm"
        case .birthdayMinimal:
            return "birthdayMinimal"
        case .marriageNatural:
            return "marriageNatural"
        case .marriageCeremonial:
            return "marriageCeremonial"
        case .marriageWarm:
            return "marriageWarm"
        case .marriageMinimal:
            return "marriageMinimal"
        case .marriageMemory:
            return "marriageMemory"
        case .relationshipNatural:
            return "relationshipNatural"
        case .relationshipCeremonial:
            return "relationshipCeremonial"
        case .relationshipMemory:
            return "relationshipMemory"
        case .relationshipWarm:
            return "relationshipWarm"
        case .relationshipMinimal:
            return "relationshipMinimal"
        case .examNatural:
            return "examNatural"
        case .examCeremonial:
            return "examCeremonial"
        case .examMotivational:
            return "examMotivational"
        case .examMinimal:
            return "examMinimal"
        case .examRecord:
            return "examRecord"
        case .customNatural:
            return "customNatural"
        case .customCeremonial:
            return "customCeremonial"
        case .customMemory:
            return "customMemory"
        case .customWarm:
            return "customWarm"
        case .customMinimal:
            return "customMinimal"
        }
    }

    static var birthdayAgeToday: Self {
        .birthdayNatural
    }

    static var relationshipAnniversary: Self {
        .relationshipNatural
    }

    static var marriageAnniversary: Self {
        .marriageNatural
    }

    static var examCountdown: Self {
        .examNatural
    }

    static func availableStyles(
        for anchorType: AnchorType
    ) -> [Self] {
        switch anchorType {
        case .birthday:
            return [
                .birthdayNatural,
                .birthdayCeremonial,
                .birthdayGrowth,
                .birthdayWarm,
                .birthdayMinimal
            ]
        case .relationship:
            return [
                .relationshipNatural,
                .relationshipCeremonial,
                .relationshipMemory,
                .relationshipWarm,
                .relationshipMinimal
            ]
        case .marriage:
            return [
                .marriageNatural,
                .marriageCeremonial,
                .marriageWarm,
                .marriageMinimal,
                .marriageMemory
            ]
        case .exam:
            return [
                .examNatural,
                .examCeremonial,
                .examMotivational,
                .examMinimal,
                .examRecord
            ]
        case .custom:
            return [
                .customNatural,
                .customCeremonial,
                .customMemory,
                .customWarm,
                .customMinimal
            ]
        }
    }

    static func defaultStyle(
        for anchorType: AnchorType
    ) -> Self {
        switch anchorType {
        case .birthday:
            return .birthdayNatural
        case .relationship:
            return .relationshipNatural
        case .marriage:
            return .marriageNatural
        case .exam:
            return .examNatural
        case .custom:
            return .customNatural
        }
    }

    static func resolvedStyle(
        for anchorType: AnchorType,
        candidate: Self?
    ) -> Self {
        let defaultStyle =
            defaultStyle(for: anchorType)

        guard let candidate else {
            return defaultStyle
        }

        return availableStyles(
            for: anchorType
        )
        .contains(candidate)
        ? candidate
        : defaultStyle
    }

    var displayTitle: String {
        switch self {
        case .birthdayNatural,
             .marriageNatural,
             .relationshipNatural,
             .examNatural,
             .customNatural:
            return "自然（默认）"
        case .birthdayCeremonial,
             .marriageCeremonial,
             .relationshipCeremonial,
             .examCeremonial,
             .customCeremonial:
            return "仪式感"
        case .birthdayGrowth:
            return "成长"
        case .birthdayWarm,
             .marriageWarm,
             .relationshipWarm,
             .customWarm:
            return "温馨"
        case .birthdayMinimal,
             .marriageMinimal,
             .relationshipMinimal,
             .examMinimal,
             .customMinimal:
            return "极简"
        case .marriageMemory,
             .relationshipMemory,
             .customMemory:
            return "回忆"
        case .examMotivational:
            return "激励"
        case .examRecord:
            return "记录"
        }
    }

    func formulaPreview(
        subjectText: String,
        anchorTitle: String
    ) -> String {
        switch self {
        case .birthdayNatural:
            return "锚点前：距离\(subjectText)出生还有倒计时天数｜锚点后：\(subjectText)今天年龄结果啦！"
        case .birthdayCeremonial:
            return "锚点前：再过倒计时天数，就是\(subjectText)生日｜锚点后：今天是\(subjectText)年龄结果"
        case .birthdayGrowth:
            return "锚点前：\(subjectText)还有倒计时天数迎来新的一岁｜锚点后：\(subjectText)成长到年龄结果"
        case .birthdayWarm:
            return "锚点前：等待\(subjectText)生日，还有倒计时天数｜锚点后：陪伴\(subjectText)年龄结果"
        case .birthdayMinimal:
            return "锚点前：\(subjectText)生日倒计时：倒计时天数｜锚点后：\(subjectText)年龄结果"
        case .marriageNatural:
            return "锚点前：\(subjectText)结婚还有倒计时结果｜锚点后：\(subjectText)婚后时长结果"
        case .marriageCeremonial:
            return "锚点前：再过倒计时结果，就是结婚纪念日｜锚点后：今天是婚后时长结果"
        case .marriageWarm:
            return "锚点前：距离结婚纪念日还有倒计时结果｜锚点后：与你相伴时长结果"
        case .marriageMinimal:
            return "锚点前：婚礼倒计时：倒计时结果｜锚点后：婚后时长结果"
        case .marriageMemory:
            return "锚点前：距离人生重要的一天还有倒计时结果｜锚点后：从那一天起已有时长结果"
        case .relationshipNatural:
            return "锚点前：\(subjectText)距离\(anchorTitle)还有倒计时结果｜锚点后：\(subjectText)与\(anchorTitle)已有时长结果"
        case .relationshipCeremonial:
            return "锚点前：再过倒计时结果，就是\(anchorTitle)｜锚点后：今天是\(anchorTitle)时长结果"
        case .relationshipMemory:
            return "锚点前：距离\(anchorTitle)还有倒计时结果｜锚点后：自\(anchorTitle)起已有时长结果"
        case .relationshipWarm:
            return "锚点前：期待\(anchorTitle)，还有倒计时结果｜锚点后：关于\(anchorTitle)的故事已有时长结果"
        case .relationshipMinimal:
            return "锚点前：\(anchorTitle)倒计时：倒计时结果｜锚点后：\(anchorTitle)时长结果"
        case .examNatural:
            return "锚点前：距离\(anchorTitle)还有倒计时结果｜锚点后：\(anchorTitle)已经时长结果"
        case .examCeremonial:
            return "锚点前：再过倒计时结果，就是\(anchorTitle)｜锚点后：今天距离\(anchorTitle)时长结果"
        case .examMotivational:
            return "锚点前：冲刺\(anchorTitle)还有倒计时结果｜锚点后：\(anchorTitle)圆满结束时长结果"
        case .examMinimal:
            return "锚点前：倒计时：倒计时结果｜锚点后：已过时长结果"
        case .examRecord:
            return "锚点前：\(anchorTitle)还有倒计时结果｜锚点后：自\(anchorTitle)以来已有时长结果"
        case .customNatural:
            return "锚点前：距离\(anchorTitle)还有倒计时结果｜锚点后：自\(anchorTitle)起已有时长结果"
        case .customCeremonial:
            return "锚点前：再过倒计时结果，就是\(anchorTitle)｜锚点后：今天是\(anchorTitle)时长结果"
        case .customMemory:
            return "锚点前：距离\(anchorTitle)还有倒计时结果｜锚点后：自\(anchorTitle)起已有时长结果"
        case .customWarm:
            return "锚点前：期待\(anchorTitle)，还有倒计时结果｜锚点后：关于\(anchorTitle)已有时长结果"
        case .customMinimal:
            return "锚点前：\(anchorTitle)倒计时：倒计时结果｜锚点后：\(anchorTitle)时长结果"
        }
    }
}

extension MemoryAnchorExpressionStyle {

    init(from decoder: any Decoder) throws {
        let container =
            try decoder.singleValueContainer()
        let rawValue =
            try container.decode(String.self)

        if let resolved =
            Self.resolved(rawValue: rawValue) {
            self = resolved
            return
        }

        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription:
                "Unknown MemoryAnchorExpressionStyle raw value: \(rawValue)"
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container =
            encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

private extension MemoryAnchorExpressionStyle {

    static func resolved(
        rawValue: String
    ) -> Self? {
        switch rawValue {
        case "birthdayNatural":
            return .birthdayNatural
        case "birthdayCeremonial":
            return .birthdayCeremonial
        case "birthdayGrowth":
            return .birthdayGrowth
        case "birthdayWarm":
            return .birthdayWarm
        case "birthdayMinimal":
            return .birthdayMinimal
        case "marriageNatural":
            return .marriageNatural
        case "marriageCeremonial":
            return .marriageCeremonial
        case "marriageWarm":
            return .marriageWarm
        case "marriageMinimal":
            return .marriageMinimal
        case "marriageMemory":
            return .marriageMemory
        case "relationshipNatural":
            return .relationshipNatural
        case "relationshipCeremonial":
            return .relationshipCeremonial
        case "relationshipMemory":
            return .relationshipMemory
        case "relationshipWarm":
            return .relationshipWarm
        case "relationshipMinimal":
            return .relationshipMinimal
        case "examNatural":
            return .examNatural
        case "examCeremonial":
            return .examCeremonial
        case "examMotivational":
            return .examMotivational
        case "examMinimal":
            return .examMinimal
        case "examRecord":
            return .examRecord
        case "customNatural":
            return .customNatural
        case "customCeremonial":
            return .customCeremonial
        case "customMemory":
            return .customMemory
        case "customWarm":
            return .customWarm
        case "customMinimal":
            return .customMinimal
        case "birthdayAgeToday":
            return .birthdayNatural
        case "relationshipAnniversary":
            return .relationshipNatural
        case "marriageAnniversary":
            return .marriageNatural
        case "examCountdown":
            return .examNatural
        default:
            return nil
        }
    }
}
