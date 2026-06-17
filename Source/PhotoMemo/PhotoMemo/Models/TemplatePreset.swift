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
            return "成长纪念：右下角默认使用时间锚点文案，适合“今天几岁了”这类效果。"

        case .template2:
            return "日常记录：保留拍摄信息，同时把你的自定义故事作为主记忆文案。"

        case .template3:
            return "器材笔记：更强调机型、镜头和拍摄参数，适合摄影记录。"
        }
    }
}
