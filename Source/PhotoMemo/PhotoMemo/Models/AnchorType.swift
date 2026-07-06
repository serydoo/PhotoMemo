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
            return "未来目标 / 高考 / 毕业"

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
            return "适合高考、毕业、入学、考试、旅行出发、演唱会、回家、搬家等目标时间点。可用于未来倒计时，也可用于已发生后的纪念时长。"

        case .custom:
            return "任何你想记录的关键时间点都可以。可手动选择“已发生纪念”或“未来倒计时”。"
        }
    }

    var sceneExamples: String {

        switch self {

        case .birthday:
            return "常见场景：出生、满月、百天、周岁、第一次站立、第一次入园。"

        case .relationship:
            return "常见场景：在一起、第一次见面、第一次旅行、求婚成功。"

        case .marriage:
            return "常见场景：领证、结婚日、结婚纪念日、蜜月出发。"

        case .exam:
            return "常见场景：高考、毕业典礼、入学报到、旅行出发、演唱会、回家倒计时。"

        case .custom:
            return "常见场景：任何自定义纪念日、目标日、截止日或生活节点。"
        }
    }
}
