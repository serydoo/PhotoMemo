import Foundation

enum TemplatePreset: String, Codable, CaseIterable {

    case template1

    case template2

    case template3
}

extension TemplatePreset {

    var displayName: String {

        switch self {

        case .template1:
            return "模板 1"

        case .template2:
            return "模板 2"

        case .template3:
            return "模板 3"
        }
    }

    var summary: String {

        switch self {

        case .template1:
            return "成长纪念：左上标题、左下记录时间、右上设备摘要、右下默认展示“今天{{anchor_age_text}}”。"

        case .template2:
            return "纪念时长：保留完整拍摄信息，右下默认展示“已经{{anchor_duration_text}}”，适合恋爱、结婚、搬家等场景。"

        case .template3:
            return "未来倒计时：左下改为紧凑日期，右上保留机型与镜头，右下默认展示“{{anchor_countdown_text}}”。"
        }
    }

    static func infer(
        from templateName: String
    ) -> TemplatePreset {

        switch templateName {

        case TemplatePreset.template2.displayName:
            return .template2

        case TemplatePreset.template3.displayName:
            return .template3

        default:
            return .template1
        }
    }
}
