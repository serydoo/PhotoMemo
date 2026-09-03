#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// Bridges the legacy in-memory editor/preview representations to the
/// canonical preview composition engine. The bridge itself has no schema or
/// persistence responsibility, so its name describes that active role only.
enum PreviewDraftAdapter {

    static func renderModel(
        for draft: MemoryCardPreviewDraft,
        context: MemoryCardPreviewCompositionContext,
        engine: MemoryCardPreviewCompositionEngine
    ) -> MemoryCardPreviewRenderModel {
        switch BuildMemoryCardPreviewRenderModelIntent(
            draft: draft,
            context: context,
            engine: engine
        )
        .executeSynchronously() {
        case .success(let model):
            return model
        case .failure:
            return MemoryCardPreviewRenderModel(
                templateSourceText: draft.singleLineTemplateText,
                displayText: draft.resolvedSingleLineText
            )
        }
    }

    static func composedText(
        for draft: MemoryCardEditorDraft,
        context: MemoryCardPreviewCompositionContext,
        engine: MemoryCardPreviewCompositionEngine
    ) -> String {
        renderModel(
            for: DraftBridge.previewDraft(from: draft),
            context: context,
            engine: engine
        )
        .displayText
    }

    static func defaultDraft(
        for region: CardRegion,
        templateID: String?,
        context: MemoryCardPreviewCompositionContext,
        engine: MemoryCardPreviewCompositionEngine
    ) -> MemoryCardEditorDraft {
        DraftBridge.editorDraft(
            from: engine.defaultDraft(
                for: region,
                templateID: templateID,
                context: context
            )
        )
    }

    static func moduleItem(
        _ module: IOSInsertableModule,
        context: MemoryCardPreviewCompositionContext,
        engine: MemoryCardPreviewCompositionEngine
    ) -> MemoryCardContentItem {
        return DraftBridge.editorItem(
            from: engine.makeModuleItem(
                module,
                context: context
            )
        )
    }

    static func moduleDisplayText(
        _ module: IOSInsertableModule,
        context: MemoryCardPreviewCompositionContext,
        engine: MemoryCardPreviewCompositionEngine
    ) -> String {
        engine.displayText(
            for: module,
            context: context
        )
    }
}
#endif
