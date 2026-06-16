import Foundation

struct Anchor: Identifiable, Codable {
    let id: UUID
    var name: String
    var date: Date
    var type: AnchorType
}
