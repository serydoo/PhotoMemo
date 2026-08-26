import Foundation

enum MediaGeometryOrientation:
    String,
    Codable,
    Hashable,
    Sendable {

    case up
    case upMirrored
    case down
    case downMirrored
    case leftMirrored
    case right
    case rightMirrored
    case left

    init(rawImageIOValue: Int) {
        switch rawImageIOValue {
        case 2:
            self = .upMirrored
        case 3:
            self = .down
        case 4:
            self = .downMirrored
        case 5:
            self = .leftMirrored
        case 6:
            self = .right
        case 7:
            self = .rightMirrored
        case 8:
            self = .left
        default:
            self = .up
        }
    }

    var rawImageIOValue: Int {
        switch self {
        case .up:
            return 1
        case .upMirrored:
            return 2
        case .down:
            return 3
        case .downMirrored:
            return 4
        case .leftMirrored:
            return 5
        case .right:
            return 6
        case .rightMirrored:
            return 7
        case .left:
            return 8
        }
    }

    var swapsDisplayAxes: Bool {
        switch self {
        case .left,
             .leftMirrored,
             .right,
             .rightMirrored:
            return true
        case .up,
             .upMirrored,
             .down,
             .downMirrored:
            return false
        }
    }
}
