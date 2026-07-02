#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Preview composition migration", .serialized)
struct PreviewCompositionMigrationTests {

    @MainActor
    @Test("BootstrapV1PreviewDraftsIntent preserves the current default V1 preview texts")
    func bootstrapIntentPreservesCurrentDefaultV1PreviewTexts() throws {

        let session =
            ConfigurationSession()
        let engine =
            V1PreviewCompositionEngine()
        let context =
            V1PreviewCompositionContext(
                subject: session.state.selectedSubject,
                birthdayDate: try #require(
                    Calendar.current.date(
                        from: DateComponents(
                            year: 2025,
                            month: 5,
                            day: 26
                        )
                    )
                )
            )

        let result =
            BootstrapV1PreviewDraftsIntent(
                templateIDsByRegion:
                    Dictionary(
                        uniqueKeysWithValues:
                            CardRegion
                            .memoryCardRegions
                            .map { region in
                                (
                                    region,
                                    session.activeTemplateID(
                                        for: region
                                    ) ?? ""
                                )
                            }
                    ),
                context: context,
                engine: engine
            )
            .executeSynchronously()

        switch result {
        case .success(let drafts):
            #expect(
                composedText(
                    for: try #require(drafts[.slotA]),
                    context: context,
                    engine: engine
                ) == "记录iPhone 17 Pro Max"
            )
            #expect(
                composedText(
                    for: try #require(drafts[.slotB]),
                    context: context,
                    engine: engine
                ) == "记录于2026.05.24 14:33:00"
            )
            #expect(
                composedText(
                    for: try #require(drafts[.slotC]),
                    context: context,
                    engine: engine
                ) == "20mm f/1.9 1/117s ISO80"
            )
            #expect(
                composedText(
                    for: try #require(drafts[.slotD]),
                    context: context,
                    engine: engine
                ) == "途途今天11个月28天啦！"
            )
        case .failure(let error):
            Issue.record(
                "Expected default V1 draft bootstrap to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("ResolveV1PreviewDisplayValueIntent resolves renderer tokens and keeps unknown token values unchanged")
    func resolveDisplayValueIntentResolvesRendererTokensAndKeepsUnknownValues() {

        let session =
            ConfigurationSession()
        let engine =
            V1PreviewCompositionEngine()
        let context =
            V1PreviewCompositionContext(
                subject: session.state.selectedSubject,
                birthdayDate:
                    Calendar.current.date(
                        from: DateComponents(
                            year: 2025,
                            month: 5,
                            day: 26
                        )
                    ) ?? Date()
            )
        let captureDateItem =
            V1PreviewDraftItem.token(
                V1PreviewCompositionModule
                    .captureDate
                    .title,
                value: "旧值",
                templateValue:
                    V1PreviewCompositionModule
                    .captureDate
                    .rendererToken,
                systemImage:
                    V1PreviewCompositionModule
                    .captureDate
                    .systemImage
            )
        let unknownItem =
            V1PreviewDraftItem.token(
                "未知",
                value: "保持原样",
                templateValue: "{{not_mapped}}",
                systemImage: "questionmark.circle"
            )

        #expect(
            resolvedDisplayValue(
                for: captureDateItem,
                context: context,
                engine: engine
            ) == "2026.05.24"
        )
        #expect(
            resolvedDisplayValue(
                for: unknownItem,
                context: context,
                engine: engine
            ) == "保持原样"
        )
    }

    @MainActor
    @Test("ComposeV1PreviewTextIntent preserves the current slot B and slot D wording")
    func composeIntentPreservesCurrentSlotBWordingAndSmartTimeWording() {

        let session =
            ConfigurationSession()
        let engine =
            V1PreviewCompositionEngine()
        let context =
            V1PreviewCompositionContext(
                subject: session.state.selectedSubject,
                birthdayDate:
                    Calendar.current.date(
                        from: DateComponents(
                            year: 2025,
                            month: 5,
                            day: 26
                        )
                    ) ?? Date()
            )
        let slotBDraft =
            V1PreviewDraft(
                items: [
                    .text("记录于"),
                    engine.makeModuleItem(
                        .captureDate,
                        context: context
                    ),
                    engine.makeModuleItem(
                        .captureTime,
                        context: context
                    )
                ]
            )
        let slotDDraft =
            V1PreviewDraft(
                items: [
                    engine.makeModuleItem(
                        .smartTime,
                        context: context
                    )
                ]
            )

        #expect(
            composedText(
                for: slotBDraft,
                context: context,
                engine: engine
            ) == "记录于2026.05.24 14:33:00"
        )
        #expect(
            composedText(
                for: slotDDraft,
                context: context,
                engine: engine
            ) == "途途今天11个月28天啦！"
        )
    }
}

private func composedText(
    for draft: V1PreviewDraft,
    context: V1PreviewCompositionContext,
    engine: V1PreviewCompositionEngine
) -> String {

    switch ComposeV1PreviewTextIntent(
        draft: draft,
        context: context,
        engine: engine
    )
    .executeSynchronously() {
    case .success(let text):
        return text
    case .failure(let error):
        Issue.record(
            "Expected preview composition to succeed, got \(error.message)"
        )
        return ""
    }
}

private func resolvedDisplayValue(
    for item: V1PreviewDraftItem,
    context: V1PreviewCompositionContext,
    engine: V1PreviewCompositionEngine
) -> String {

    switch ResolveV1PreviewDisplayValueIntent(
        item: item,
        context: context,
        engine: engine
    )
    .executeSynchronously() {
    case .success(let text):
        return text
    case .failure(let error):
        Issue.record(
            "Expected preview display resolution to succeed, got \(error.message)"
        )
        return ""
    }
}
#endif
