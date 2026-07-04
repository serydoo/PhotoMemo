import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryContext {

    let metadata: PhotoMetadata

    let anchor: Anchor?

    let anchorResult: AnchorResult?

    let story: String

    let subjectText: String?

    init(
        metadata: PhotoMetadata,
        anchor: Anchor? = nil,
        anchorResult: AnchorResult? = nil,
        story: String = "",
        subjectText: String? = nil
    ) {
        self.metadata = metadata
        self.anchor = anchor
        self.anchorResult = anchorResult
        self.story = story
        self.subjectText =
            subjectText
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

    var trimmedSubjectText: String? {
        guard let subjectText else {
            return nil
        }

        let trimmed =
            subjectText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
#endif
