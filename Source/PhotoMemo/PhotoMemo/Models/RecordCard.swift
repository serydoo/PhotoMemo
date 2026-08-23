import Foundation

enum RecordCardPresentationStyle:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case classicWhite
    case minimal
}

struct RecordCard: Identifiable, Hashable {

    let id: UUID

    var template: Template

    var presentationStyle: RecordCardPresentationStyle

    var metadata: PhotoMetadata

    var context: MetadataContext

    var language: MemoMarkLanguage

    var anchor: Anchor?

    var anchorResult: AnchorResult?

    var badge: Badge?

    var title: String

    var story: String

#if !PHOTOMEMO_SHARE_EXTENSION
    var memoryResult: MemoryResult? = nil

    var memoryModule: MemoryModule? = nil

    var productionExpressionContext: ExpressionContext? = nil
#endif

    var tags: [String]

    var memorySubjectText: String?

    var exportDescriptionOverride: String?

    init(
        id: UUID = UUID(),
        template: Template = .classicWhite,
        presentationStyle: RecordCardPresentationStyle = .classicWhite,
        metadata: PhotoMetadata,
        context: MetadataContext,
        language: MemoMarkLanguage = .simplifiedChinese,
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
        self.presentationStyle = presentationStyle
        self.metadata = metadata
        self.context = context
        self.language = language
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
