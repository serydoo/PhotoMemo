import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryContext {

    let metadata: PhotoMetadata

    let anchor: Anchor?

    let anchorResult: AnchorResult?

    let story: String

    init(
        metadata: PhotoMetadata,
        anchor: Anchor? = nil,
        anchorResult: AnchorResult? = nil,
        story: String = ""
    ) {
        self.metadata = metadata
        self.anchor = anchor
        self.anchorResult = anchorResult
        self.story = story
    }

    var photoDate: Date? {

        metadata.captureDate
    }

    var calendar: Calendar {

        metadata.captureCalendar
    }

    var trimmedStory: String {

        story.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}
#endif
