import Foundation

enum MemoMarkSymbol: String, CaseIterable {
    case home = "house.fill"
    case configurationCenter = "slider.horizontal.3"
    case memorySubject = "person.crop.circle.fill"
    case timeAnchor = "calendar.badge.clock"
    case memoryContent = "heart.text.square.fill"
    case photoMetadata = "doc.badge.gearshape"
    case location = "location.fill"
    case configuration = "rectangle.stack"
    case module = "square.grid.2x2.fill"
    case output = "square.and.arrow.down.fill"
    case applePhotos = "photo.on.rectangle"
    case localStorage = "books.vertical.fill"
    case processing = "gearshape.2.fill"
    case completed = "checkmark.circle.fill"
    case privacy = "hand.raised.fill"
    case help = "questionmark.circle.fill"
    case settings = "gearshape.fill"
    case feedback = "bubble.left.and.bubble.right.fill"
    case retention = "archivebox.fill"
    case workflow = "point.3.connected.trianglepath.dotted"
    case information = "info.circle.fill"
    case capability = "shield.lefthalf.filled"
    case welcome = "sparkles"
    case borderStyle = "paintpalette.fill"
    case task = "checklist"
    case expressionFormula = "function"
    case originalPhoto = "photo.stack.fill"
    case writingDescription = "text.document.fill"

    nonisolated var name: String { rawValue }
}
