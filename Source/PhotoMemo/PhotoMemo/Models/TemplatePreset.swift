import Foundation

enum TemplatePreset: String, Codable, CaseIterable {

    case template1

    case template2

    case template3

    case immersWhite
}

enum TemplateRenderLayout: Equatable {

    case classicWhite

    case immersWhite
}

extension TemplatePreset {

    var renderLayout: TemplateRenderLayout {

        switch self {

        case .template1,
             .immersWhite:
            return .immersWhite

        case .template2,
             .template3:
            return .classicWhite
        }
    }

    var displayName: String {

        switch self {

        case .template1:
            return "模板 1"

        case .template2:
            return "模板 2"

        case .template3:
            return "模板 3"

        case .immersWhite:
            return "Immers 白边"
        }
    }

    var summary: String {

        switch self {

        case .template1:
            return "当前固定骨架：左上默认记录者 + 设备，左下拍摄时间，右上参数摘要，右下默认展示主角称呼 + 今天 + 年岁。"

        case .template2:
            return "已归并到当前模板 1 主流程。"

        case .template3:
            return "已归并到当前模板 1 主流程。"

        case .immersWhite:
            return "当前主界面已固定沿用模板 1，不再暴露其他预设切换入口。"
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

        case TemplatePreset.immersWhite.displayName:
            return .immersWhite

        default:
            return .template1
        }
    }
}
