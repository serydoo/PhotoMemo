import Foundation

enum RecordCardPresentationStyle:
    String,
    Codable,
    CaseIterable,
    Hashable {

    case classicWhite
    case minimal
    case filmMark

    /// Only these styles are backed by the legacy template dictionary. FM
    /// keeps its presentation payload in `Presentation.filmMark`, so adding
    /// it to the enum must not change the Classic White / Minimal transport
    /// shape.
    static let legacyTemplateBackedStyles: [Self] = [
        .classicWhite,
        .minimal
    ]

    /// The content contract is the single source of truth for the editable
    /// surface, rendered text surface, and Apple Photos description source of
    /// each presentation style. Keeping this contract beside the shared
    /// presentation-style value lets the renderer, editor, and export path
    /// make the same decision without sharing slot state implicitly.
    nonisolated var contentContract: PresentationStyleContentContract {
        switch self {
        case .classicWhite:
            return PresentationStyleContentContract(
                semanticProjections: [
                    .init(role: .recorder, textArea: .leftTop),
                    .init(role: .timeline, textArea: .leftBottom),
                    .init(role: .captureSummary, textArea: .rightTop),
                    .init(role: .memory, textArea: .rightBottom)
                ],
                editableContentRoles: [
                    .recorder,
                    .timeline,
                    .captureSummary,
                    .memory
                ],
                renderedContentRoles: [
                    .recorder,
                    .timeline,
                    .captureSummary,
                    .memory
                ],
                photoDescriptionRoles: [.memory],
                editorTitleKey: "configuration.card_editor.output_content",
                editorTitleFallback: "输出内容",
                editorAccessibilityLabelKey:
                    "configuration.card_editor.accessibility_label",
                editorAccessibilityLabelFallback: "卡片内容编辑",
                editorAccessibilityHintKey: nil,
                editorAccessibilityHintFallback: nil
            )
        case .minimal:
            return PresentationStyleContentContract(
                semanticProjections: [
                    .init(role: .primaryOutput, textArea: .leftTop)
                ],
                editableContentRoles: [.primaryOutput],
                renderedContentRoles: [.primaryOutput],
                photoDescriptionRoles: [.primaryOutput],
                editorTitleKey:
                    "configuration.card_editor.minimal_content",
                editorTitleFallback: "极简内容",
                editorAccessibilityLabelKey:
                    "accessibility.editor.minimal.label",
                editorAccessibilityLabelFallback: "极简卡片内容",
                editorAccessibilityHintKey:
                    "accessibility.editor.minimal.hint",
                editorAccessibilityHintFallback:
                    "这部分内容会显示在极简卡片上，也会写入 Apple Photos 的照片说明，方便之后查找。"
            )
        case .filmMark:
            return PresentationStyleContentContract(
                semanticProjections: [
                    .init(role: .primaryOutput, textArea: .leftTop)
                ],
                editableContentRoles: [.primaryOutput],
                renderedContentRoles: [.primaryOutput],
                photoDescriptionRoles: [.primaryOutput],
                editorTitleKey:
                    "configuration.card_editor.film_mark_content",
                editorTitleFallback: "胶片时间标记内容",
                editorAccessibilityLabelKey:
                    "accessibility.editor.film_mark.label",
                editorAccessibilityLabelFallback:
                    "胶片时间标记内容",
                editorAccessibilityHintKey:
                    "accessibility.editor.film_mark.hint",
                editorAccessibilityHintFallback:
                    "这部分内容会显示在照片上，也会写入 Apple Photos 的照片说明，方便之后查找。"
            )
        }
    }
}

/// Describes the user-facing meaning carried by a style-owned text area.
///
/// CardRegion remains the persistence-compatible slot carrier. These roles
/// keep editor, preview, and photo-description decisions from treating slot A
/// as a universal semantic owner when a style intentionally has a different
/// content surface.
enum PresentationContentRole: String, CaseIterable, Hashable {
    case recorder
    case timeline
    case captureSummary
    case memory
    case primaryOutput
}

struct PresentationContentProjection: Hashable {
    let role: PresentationContentRole
    let textArea: CardTextArea

    nonisolated init(
        role: PresentationContentRole,
        textArea: CardTextArea
    ) {
        self.role = role
        self.textArea = textArea
    }
}

/// Defines how a presentation style owns and projects card text.
///
/// A style may expose two or three editable/rendered areas in the future by
/// extending these arrays. Consumers must use this contract instead of
/// assuming that slot A-D are globally shared between styles.
struct PresentationStyleContentContract: Hashable {

    let semanticProjections: [PresentationContentProjection]

    let editableContentRoles: [PresentationContentRole]

    let renderedContentRoles: [PresentationContentRole]

    let photoDescriptionRoles: [PresentationContentRole]

    let editorTitleKey: String

    let editorTitleFallback: String

    let editorAccessibilityLabelKey: String

    let editorAccessibilityLabelFallback: String

    let editorAccessibilityHintKey: String?

    let editorAccessibilityHintFallback: String?

    nonisolated init(
        semanticProjections: [PresentationContentProjection],
        editableContentRoles: [PresentationContentRole],
        renderedContentRoles: [PresentationContentRole],
        photoDescriptionRoles: [PresentationContentRole],
        editorTitleKey: String,
        editorTitleFallback: String,
        editorAccessibilityLabelKey: String,
        editorAccessibilityLabelFallback: String,
        editorAccessibilityHintKey: String?,
        editorAccessibilityHintFallback: String?
    ) {
        self.semanticProjections = semanticProjections
        self.editableContentRoles = editableContentRoles
        self.renderedContentRoles = renderedContentRoles
        self.photoDescriptionRoles = photoDescriptionRoles
        self.editorTitleKey = editorTitleKey
        self.editorTitleFallback = editorTitleFallback
        self.editorAccessibilityLabelKey = editorAccessibilityLabelKey
        self.editorAccessibilityLabelFallback =
            editorAccessibilityLabelFallback
        self.editorAccessibilityHintKey = editorAccessibilityHintKey
        self.editorAccessibilityHintFallback = editorAccessibilityHintFallback
    }

    nonisolated var editableTextAreas: [CardTextArea] {
        editableContentRoles.compactMap { textArea(for: $0) }
    }

    nonisolated var renderedTextAreas: [CardTextArea] {
        renderedContentRoles.compactMap { textArea(for: $0) }
    }

    nonisolated var photoDescriptionTextAreas: [CardTextArea] {
        photoDescriptionRoles.compactMap { textArea(for: $0) }
    }

    nonisolated func textArea(
        for role: PresentationContentRole
    ) -> CardTextArea? {
        semanticProjections.first(where: { $0.role == role })?.textArea
    }

    nonisolated func role(
        for textArea: CardTextArea
    ) -> PresentationContentRole? {
        semanticProjections.first(where: { $0.textArea == textArea })?.role
    }

    nonisolated func editorTitle(
        using language: MemoMarkLanguage
    ) -> String {
        language.localized(
            key: editorTitleKey,
            fallback: editorTitleFallback
        )
    }

    nonisolated func editorAccessibilityLabel(
        using language: MemoMarkLanguage
    ) -> String {
        language.localized(
            key: editorAccessibilityLabelKey,
            fallback: editorAccessibilityLabelFallback
        )
    }

    nonisolated func editorAccessibilityHint(
        using language: MemoMarkLanguage
    ) -> String? {
        guard let key = editorAccessibilityHintKey,
              let fallback = editorAccessibilityHintFallback else {
            return nil
        }
        return language.localized(
            key: key,
            fallback: fallback
        )
    }
}

struct RecordCard: Identifiable, Hashable {

    let id: UUID

    var template: Template

    var presentationStyle: RecordCardPresentationStyle

    var filmMarkConfiguration: FilmMarkConfiguration

    /// FM owns an independent authored content payload. Classic White and
    /// Minimal continue to use `template`; FM never infers content from it.
    var filmMarkContent: FilmMarkContentSchemaV2?

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
        filmMarkConfiguration: FilmMarkConfiguration = .default,
        filmMarkContent: FilmMarkContentSchemaV2? = nil,
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
        self.filmMarkConfiguration = filmMarkConfiguration
        self.filmMarkContent = filmMarkContent
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
