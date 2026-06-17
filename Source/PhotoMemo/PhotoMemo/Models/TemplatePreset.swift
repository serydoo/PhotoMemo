import Foundation

enum TemplatePreset: String, Codable, CaseIterable {

    case classicWhite

    case dark

    case travel

    case film

    case family
}

extension TemplatePreset {

    var displayName: String {

        switch self {

        case .classicWhite:
            return "Classic White"

        case .dark:
            return "Dark"

        case .travel:
            return "Travel"

        case .film:
            return "Film"

        case .family:
            return "Family"
        }
    }
}
