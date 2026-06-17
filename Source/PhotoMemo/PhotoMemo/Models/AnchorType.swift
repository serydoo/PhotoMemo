import Foundation

enum AnchorType: String, Codable, CaseIterable {
    case birthday
    case relationship
    case marriage
    case exam
    case custom
}

extension AnchorType {

    var displayName: String {

        switch self {

        case .birthday:
            return "生日 / 出生"

        case .relationship:
            return "恋爱纪念"

        case .marriage:
            return "结婚纪念"

        case .exam:
            return "高考 / 考试"

        case .custom:
            return "自定义"
        }
    }

    var suggestedTitle: String {

        switch self {

        case .birthday:
            return "宝宝"

        case .relationship:
            return "恋爱"

        case .marriage:
            return "结婚纪念"

        case .exam:
            return "距离高考"

        case .custom:
            return "重要日子"
        }
    }

    var defaultCountdown: Bool {

        switch self {

        case .exam:
            return true

        case .birthday,
             .relationship,
             .marriage,
             .custom:
            return false
        }
    }

    var helperText: String {

        switch self {

        case .birthday:
            return "适合宝宝出生、生日等已发生事件。照片 EXIF 时间减去锚点时间，会得到几岁、几个月、几天。"

        case .relationship:
            return "适合恋爱、在一起、第一次见面等纪念日。会计算到照片拍摄当天已经过了多久。"

        case .marriage:
            return "适合结婚纪念、领证纪念等。会计算到照片拍摄当天已经过去多少年、月、天。"

        case .exam:
            return "适合高考、考试、旅行出发等未来目标。会优先按倒计时文案生成剩余天数。"

        case .custom:
            return "任何你想记录的关键时间点都可以。可手动选择“已发生纪念”或“未来倒计时”。"
        }
    }
}
