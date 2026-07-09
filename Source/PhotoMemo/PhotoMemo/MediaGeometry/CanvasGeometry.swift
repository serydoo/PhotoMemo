import CoreGraphics
import Foundation

struct CanvasGeometry:
    Codable,
    Equatable,
    Sendable {

    let canvasSize: CGSize
    let photoFrame: CGRect
    let footerFrame: CGRect
}
