import Foundation

struct CanonicalGeometry:
    Codable,
    Equatable,
    Sendable {

    let facts: MediaGeometryFacts
    let canvas: CanvasGeometry
}
