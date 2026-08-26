import CoreGraphics
import Foundation

struct MediaGeometryFacts:
    Codable,
    Equatable,
    Sendable {

    let rawPixelSize: CGSize
    let displaySize: CGSize
    let orientation: MediaGeometryOrientation
}
