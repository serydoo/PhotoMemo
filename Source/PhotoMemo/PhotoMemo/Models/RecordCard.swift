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

#if !PHOTOMEMO_SHARE_EXTENSION
    var memoryModule: MemoryModule? = nil
#endif

    var tags: [String]

    var memorySubjectText: String?

    var exportDescriptionOverride: String?

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
        tags: [String] = [],
        memorySubjectText: String? = nil,
        exportDescriptionOverride: String? = nil
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
        self.memorySubjectText =
            memorySubjectText
        self.exportDescriptionOverride =
            exportDescriptionOverride
    }
}
