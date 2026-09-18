#if !MEMOMARK_SHARE_EXTENSION
import SwiftUI

func filmMarkLocalized(_ key: String, fallback: String) -> String {
    MemoMarkLanguage.interfaceStored.localized(key: key, fallback: fallback)
}

extension FilmMarkPlacementAnchor {
    var displayTitle: String {
        switch self {
        case .bottomLeft:
            return filmMarkLocalized("filmMark.configuration.anchor.bottom_left", fallback: "左下")
        case .bottomRight:
            return filmMarkLocalized("filmMark.configuration.anchor.bottom_right", fallback: "右下")
        }
    }
}

extension FilmMarkPlacementDirection {
    var accessibilityLabel: String {
        switch self {
        case .up: return filmMarkLocalized("filmMark.configuration.direction.up", fallback: "向上移动")
        case .down: return filmMarkLocalized("filmMark.configuration.direction.down", fallback: "向下移动")
        case .left: return filmMarkLocalized("filmMark.configuration.direction.left", fallback: "向左移动")
        case .right: return filmMarkLocalized("filmMark.configuration.direction.right", fallback: "向右移动")
        }
    }
}

extension FilmMarkFontID {
    var displayTitle: String {
        switch self {
        case .systemMonospaced: return filmMarkLocalized("filmMark.configuration.font.system_monospaced", fallback: "系统等宽")
        case .ibmPlexMono: return filmMarkLocalized("filmMark.configuration.font.ibm_plex_mono", fallback: "IBM Plex Mono")
        case .spaceMono: return filmMarkLocalized("filmMark.configuration.font.space_mono", fallback: "Space Mono")
        case .jetBrainsMono: return filmMarkLocalized("filmMark.configuration.font.jetbrains_mono", fallback: "JetBrains Mono")
        }
    }
}

extension FilmMarkFontSize {
    static let userSelectableCases: [FilmMarkFontSize] = [.compact, .standard, .large, .prominent]

    var displayTitle: String {
        switch self {
        case .compact: return filmMarkLocalized("filmMark.configuration.size.compact", fallback: "紧凑")
        case .standard: return filmMarkLocalized("filmMark.configuration.size.standard", fallback: "标准")
        case .large: return filmMarkLocalized("filmMark.configuration.size.large", fallback: "较大")
        case .prominent: return filmMarkLocalized("filmMark.configuration.size.prominent", fallback: "醒目")
        default: return filmMarkLocalized("filmMark.configuration.size.custom", fallback: "自定义")
        }
    }
}

extension FilmMarkSubstrate {
    var displayTitle: String {
        switch self {
        case .none: return filmMarkLocalized("filmMark.configuration.substrate.none", fallback: "无")
        case .paperWhite: return filmMarkLocalized("filmMark.configuration.substrate.paper_white", fallback: "纸白")
        case .systemGlass: return filmMarkLocalized("filmMark.configuration.substrate.system_glass", fallback: "系统玻璃")
        case .softShadow: return filmMarkLocalized("filmMark.configuration.substrate.soft_shadow", fallback: "柔和阴影")
        case .translucentLabel: return filmMarkLocalized("filmMark.configuration.substrate.translucent_label", fallback: "半透明底")
        }
    }
}
#endif
