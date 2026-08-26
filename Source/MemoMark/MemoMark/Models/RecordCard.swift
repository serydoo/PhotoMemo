import Foundation

enum RecordCardPresentationStyle:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case classicWhite
    case minimal

    /// The content contract is the single source of truth for the editable
    /// surface, rendered text surface, and Apple Photos description source of
    /// each presentation style. Keeping this contract beside the shared
    /// presentation-style value lets the renderer, editor, and export path
    /// make the same decision without sharing slot state implicitly.
    nonisolated var contentContract: PresentationStyleContentContract {
        switch self {
        case .classicWhite:
            return PresentationStyleContentContract(
                editableTextAreas: [
                    .leftTop,
                    .leftBottom,
                    .rightTop,
                    .rightBottom
                ],
                renderedTextAreas: [
                    .leftTop,
                    .leftBottom,
                    .rightTop,
                    .rightBottom
                ],
                photoDescriptionTextAreas: [.rightBottom]
            )
        case .minimal:
            return PresentationStyleContentContract(
                editableTextAreas: [.leftTop],
                renderedTextAreas: [.leftTop],
                photoDescriptionTextAreas: [.leftTop]
            )
        }
    }
}

/// Defines how a presentation style owns and projects card text.
///
/// A style may expose two or three editable/rendered areas in the future by
/// extending these arrays. Consumers must use this contract instead of
/// assuming that slot A-D are globally shared between styles.
struct PresentationStyleContentContract: Hashable {

    let editableTextAreas: [CardTextArea]

    let renderedTextAreas: [CardTextArea]

    let photoDescriptionTextAreas: [CardTextArea]

    nonisolated init(
        editableTextAreas: [CardTextArea],
        renderedTextAreas: [CardTextArea],
        photoDescriptionTextAreas: [CardTextArea]
    ) {
        self.editableTextAreas = editableTextAreas
        self.renderedTextAreas = renderedTextAreas
        self.photoDescriptionTextAreas = photoDescriptionTextAreas
    }
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

#if !MEMOMARK_SHARE_EXTENSION
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
