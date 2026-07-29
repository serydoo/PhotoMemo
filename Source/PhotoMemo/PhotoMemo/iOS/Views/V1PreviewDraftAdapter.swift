#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

enum V1PreviewDraftAdapter {

    static func renderModel(
        for draft: V1PreviewDraft,
        context: V1PreviewCompositionContext,
        engine: V1PreviewCompositionEngine
    ) -> V1PreviewRenderModel {
        switch BuildV1PreviewRenderModelIntent(
            draft: draft,
            context: context,
            engine: engine
        )
        .executeSynchronously() {
        case .success(let model):
            return model
        case .failure:
            return V1PreviewRenderModel(
                templateSourceText: draft.singleLineTemplateText,
                displayText: draft.resolvedSingleLineText
            )
        }
    }

    static func composedText(
        for draft: V1EditorDraft,
        context: V1PreviewCompositionContext,
        engine: V1PreviewCompositionEngine
    ) -> String {
        renderModel(
            for: V1DraftBridge.previewDraft(from: draft),
            context: context,
            engine: engine
        )
        .displayText
    }

    static func defaultDraft(
        for region: CardRegion,
        templateID: String?,
        context: V1PreviewCompositionContext,
        engine: V1PreviewCompositionEngine
    ) -> V1EditorDraft {
        V1DraftBridge.editorDraft(
            from: engine.defaultDraft(
                for: region,
                templateID: templateID,
                context: context
            )
        )
    }

    static func moduleItem(
        _ module: IOSInsertableModule,
        previewModule: V1PreviewCompositionModule?,
        fallbackDisplayText: String,
        context: V1PreviewCompositionContext,
        engine: V1PreviewCompositionEngine
    ) -> V1ContentItem {
        guard let previewModule else {
            return .token(
                module.title,
                value: fallbackDisplayText,
                templateValue: module.rendererToken,
                systemImage: module.systemImage
            )
        }
        return V1DraftBridge.editorItem(
            from: engine.makeModuleItem(
                previewModule,
                context: context
            )
        )
    }
}
#endif
