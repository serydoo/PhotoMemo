#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum CardRegion:
    String,
    Codable,
    CaseIterable,
    Identifiable,
    Hashable {

    case subject
    case icon
    case badge
    case slotA
    case slotB
    case slotC
    case slotD

    var id: String {
        rawValue
    }
}

extension CardRegion {

    static let memoryCardRegions: [CardRegion] = [
        .slotA,
        .slotB,
        .slotC,
        .slotD
    ]

    var displayTitle: String {
        switch self {
        case .subject:
            return "记忆对象"
        case .slotA:
            return "区域 A"
        case .slotB:
            return "区域 B"
        case .slotC:
            return "区域 C"
        case .slotD:
            return "区域 D"
        case .icon:
            return "图标"
        case .badge:
            return "徽标"
        }
    }

    var semanticTitle: String {
        switch self {
        case .subject:
            return "记忆对象"
        case .icon:
            return "图标装饰"
        case .badge:
            return "徽标装饰"
        case .slotA:
            return "记录"
        case .slotB:
            return "时间线"
        case .slotC:
            return "上下文"
        case .slotD:
            return "记忆"
        }
    }

    var accessibilityIdentifier: String {
        "configurationCenter.memoryCard.\(rawValue)"
    }

    var accessibilityLabel: String {
        "\(displayTitle), \(semanticTitle)"
    }
}
#endif
