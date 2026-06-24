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

    var displayTitle: String {
        switch self {
        case .subject:
            return "Subject"
        case .slotA:
            return "Slot A"
        case .slotB:
            return "Slot B"
        case .slotC:
            return "Slot C"
        case .slotD:
            return "Slot D"
        case .icon:
            return "Icon"
        case .badge:
            return "Badge"
        }
    }

    var semanticTitle: String {
        switch self {
        case .subject:
            return "Memory Subject"
        case .icon:
            return "Icon Decoration"
        case .badge:
            return "Badge Decoration"
        case .slotA:
            return "Recorder"
        case .slotB:
            return "Timeline"
        case .slotC:
            return "Location"
        case .slotD:
            return "Memory"
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
