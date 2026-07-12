import Foundation

enum MemoMarkSymbol: String, CaseIterable {
    case memorySubject = "person.crop.circle"
    case timeAnchor = "calendar.badge.clock"
    case memoryContent = "heart.text.square"
    case photoMetadata = "camera.aperture"
    case location = "location.circle"
    case configuration = "rectangle.stack"
    case module = "square.grid.2x2"
    case output = "square.and.arrow.down"
    case applePhotos = "photo.on.rectangle"
    case localStorage = "externaldrive"
    case processing = "gearshape.2"
    case completed = "checkmark.circle"
    case privacy = "lock.shield"
    case help = "questionmark.circle"
    case settings = "gearshape"

    var name: String { rawValue }
}
