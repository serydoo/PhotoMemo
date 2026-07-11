import Foundation

enum TemplatePreset: String, CaseIterable {

    case classicWhite
}

enum TemplateRenderLayout: Equatable {

    case classicWhite
}

extension TemplatePreset {

    var renderLayout: TemplateRenderLayout {

        .classicWhite
    }

    var displayName: String {

        "Classic White"
    }

    var summary: String {

        "当前主界面固定使用 Classic White，不再暴露其他预设切换入口。"
    }

    static func infer(
        from templateName: String
    ) -> TemplatePreset {

        .classicWhite
    }
}

extension TemplatePreset: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "classicWhite",
             "template1",
             "template2",
             "template3",
             "immersWhite":
            self = .classicWhite
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription:
                    "Unsupported template preset: \(rawValue)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Self.classicWhite.rawValue)
    }
}
