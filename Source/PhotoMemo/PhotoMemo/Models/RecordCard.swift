import Foundation

struct RecordCard: Identifiable, Hashable {

    let id: UUID

    var template: Template

    var metadata: PhotoMetadata

    var context: MetadataContext

    var anchor: Anchor?

    var anchorResult: AnchorResult?

    var badge: Badge?

    var title: String

    var story: String

    var tags: [String]

    init(
        id: UUID = UUID(),
        template: Template = .classicWhite,
        metadata: PhotoMetadata,
        context: MetadataContext,
        anchor: Anchor? = nil,
        anchorResult: AnchorResult? = nil,
        badge: Badge? = nil,
        title: String = "",
        story: String = "",
        tags: [String] = []
    ) {
        self.id = id
        self.template = template
        self.metadata = metadata
        self.context = context
        self.anchor = anchor
        self.anchorResult = anchorResult
        self.badge = badge
        self.title = title
        self.story = story
        self.tags = tags
    }
}
