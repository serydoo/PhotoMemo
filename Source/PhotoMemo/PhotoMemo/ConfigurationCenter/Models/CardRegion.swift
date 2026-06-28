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

enum CompactInformationBarTextPosition: String, CaseIterable {
    case leftPrimary
    case leftSecondary
    case rightPrimary
    case rightSecondary
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
            return "拍摄参数"
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

    static func region(
        for position: CompactInformationBarTextPosition
    ) -> CardRegion {
        switch position {
        case .leftPrimary:
            return .slotA
        case .leftSecondary:
            return .slotB
        case .rightPrimary:
            return .slotC
        case .rightSecondary:
            return .slotD
        }
    }

    var compactInformationBarTextPosition:
        CompactInformationBarTextPosition? {

        switch self {
        case .slotA:
            return .leftPrimary
        case .slotB:
            return .leftSecondary
        case .slotC:
            return .rightPrimary
        case .slotD:
            return .rightSecondary
        case .subject,
             .icon,
             .badge:
            return nil
        }
    }

    var compactInformationBarTextArea: CardTextArea? {
        switch compactInformationBarTextPosition {
        case .leftPrimary:
            return .leftTop
        case .leftSecondary:
            return .leftBottom
        case .rightPrimary:
            return .rightTop
        case .rightSecondary:
            return .rightBottom
        case nil:
            return nil
        }
    }
}
#endif
