#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Preview composition migration", .serialized)
struct PreviewCompositionMigrationTests {

    @MainActor
    @Test("BootstrapV1PreviewDraftsIntent preserves the current default V1 preview texts")
    func bootstrapIntentPreservesCurrentDefaultV1PreviewTexts() throws {

        let engine =
            V1PreviewCompositionEngine()
        let subject =
            previewSubject()
        let context =
            V1PreviewCompositionContext(
                subject: subject,
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
                                    ""
                                )
                            }
                    ),
                context: context,
                engine: engine
            )
            .executeSynchronously()

        switch result {
        case .success(let drafts):
            let slotAModel =
                renderModel(
                    for: try #require(drafts[.slotA]),
                    context: context,
                    engine: engine
                )
            let slotBModel =
                renderModel(
                    for: try #require(drafts[.slotB]),
                    context: context,
                    engine: engine
                )
            let slotCModel =
                renderModel(
                    for: try #require(drafts[.slotC]),
                    context: context,
                    engine: engine
                )
            let slotDModel =
                renderModel(
                    for: try #require(drafts[.slotD]),
                    context: context,
                    engine: engine
                )

            #expect(
                slotAModel.templateSourceText
                == "记录{{model}}"
            )
            #expect(
                slotAModel.displayText
                == "记录iPhone 17 Pro Max"
            )
            #expect(
                slotBModel.templateSourceText
                == "记录于{{capture_date_short}} {{capture_time_short}}"
            )
            #expect(
                slotBModel.displayText
                == "记录于2026.05.24 14:33:00"
            )
            #expect(
                slotCModel.templateSourceText
                == "{{camera_summary}}"
            )
            #expect(
                slotCModel.displayText
                == "20mm f/1.9 1/117s ISO80"
            )
            #expect(
                slotDModel.templateSourceText
                == "{{memory_summary}}"
            )
            #expect(
                slotDModel.displayText
                == "这一天，途途11个月28天"
            )
        case .failure(let error):
            Issue.record(
                "Expected default V1 draft bootstrap to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("BuildV1PreviewRenderModelIntent resolves renderer tokens and keeps unknown token values unchanged")
    func buildRenderModelIntentResolvesRendererTokensAndKeepsUnknownTokenValues() {

        let engine =
            V1PreviewCompositionEngine()
        let context =
            V1PreviewCompositionContext(
                subject: previewSubject(),
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

        let captureDateModel =
            renderModel(
                for: V1PreviewDraft(
                    items: [captureDateItem]
                ),
                context: context,
                engine: engine
            )
        let unknownItemModel =
            renderModel(
                for: V1PreviewDraft(
                    items: [unknownItem]
                ),
                context: context,
                engine: engine
            )

        #expect(
            captureDateModel.templateSourceText
            == "{{capture_date_short}}"
        )
        #expect(
            captureDateModel.displayText
            == "2026.05.24"
        )
        #expect(
            unknownItemModel.templateSourceText
            == "{{not_mapped}}"
        )
        #expect(
            unknownItemModel.displayText
            == "保持原样"
        )
    }

    @Test("Default presets use Memory Summary instead of legacy anchor variables")
    func defaultPresetsUseMemorySummaryInsteadOfLegacyAnchorVariables() {
        let templates = [
            Template.template1,
            Template.template2,
            Template.template3,
            Template.immersWhite
        ]

        for template in templates {
            #expect(
                template.rightBottomArea.items.first?.value
                == "{{memory_summary}}"
            )
        }
    }

    @Test("Legacy built-in anchor sentence items migrate to Memory Summary")
    func legacyBuiltInAnchorSentenceItemsMigrateToMemorySummary() {
        let legacyValues = [
            "今天{{anchor_age_text}}",
            "{{anchor_title}}今天{{anchor_age_text}}啦",
            "已经{{anchor_duration_text}}",
            "{{anchor_countdown_text}}"
        ]

        for legacyValue in legacyValues {
            let template = Template(
                preset: .template1,
                name: "Legacy Anchor Sentence",
                leftTopArea: .leftTop,
                leftBottomArea: .leftBottom,
                rightTopArea: .rightTop,
                rightBottomArea: TemplateArea(
                    name: "Right Bottom",
                    items: [
                        TemplateItem(
                            type: .variable,
                            name: "Legacy",
                            value: legacyValue
                        )
                    ]
                ),
                badgeArea: .badge
            )

            #expect(
                template.normalizedForEditing
                    .rightBottomArea.items.first?.value
                == "{{memory_summary}}"
            )
        }
    }

    @MainActor
    @Test("BuildV1PreviewRenderModelIntent preserves the current slot B and slot D wording")
    func buildRenderModelIntentPreservesCurrentSlotBWordingAndSmartTimeWording() {

        let engine =
            V1PreviewCompositionEngine()
        let context =
            V1PreviewCompositionContext(
                subject: previewSubject(),
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
            renderModel(
                for: slotBDraft,
                context: context,
                engine: engine
            )
            .displayText == "记录于2026.05.24 14:33:00"
        )
        #expect(
            renderModel(
                for: slotDDraft,
                context: context,
                engine: engine
            )
            .displayText == "这一天，途途11个月28天"
        )
    }

    @MainActor
    @Test("V1 preview location module keeps legacy token while sourcing display value from ExpressionContext")
    func v1PreviewLocationModuleKeepsLegacyTokenWhileSourcingDisplayValueFromExpressionContext() {

        let engine =
            V1PreviewCompositionEngine()
        let subject =
            previewSubject()
        let context =
            V1PreviewCompositionContext(
                subject: subject,
                birthdayDate: subject.referenceDate
            )

        let model =
            renderModel(
                for:
                    V1PreviewDraft(
                        items: [
                            engine.makeModuleItem(
                                .location,
                                context: context
                            )
                        ]
                    ),
                context: context,
                engine: engine
            )

        #expect(
            model.templateSourceText
            == "{{location_display}}"
        )
        #expect(
            model.displayText
            == "河南 · 商丘"
        )
    }

    @Test("Boundary V1 preview location source uses ExpressionContext instead of direct rendered demo string")
    func boundaryV1PreviewLocationSourceUsesExpressionContextInsteadOfDirectRenderedDemoString() throws {
        let source =
            try String(
                contentsOfFile:
                    "/Users/rui/Desktop/PhotoMemo/Source/PhotoMemo/PhotoMemo/iOS/Views/V1PreviewCompositionEngine.swift",
                encoding: .utf8
            )

        #expect(source.contains("ExpressionContext"))
        #expect(source.contains("LocationExpressionProvider"))
        #expect(source.contains("LocationContextBuilder"))
        #expect(!source.contains("return \"河南 · 商丘\""))
        #expect(!source.contains("PreviewExpressionContext"))
        #expect(!source.contains("ConfigurationCenterPreviewCompositionHelper"))
        #expect(!source.contains("CardVariableProvider"))
        #expect(!source.contains("RecordCardBuildService"))
        #expect(!source.contains("RecordCardRenderer"))
    }

    @MainActor
    @Test("smart module inserted into slot A follows the selected anchor formula style")
    func smartModuleInsertedIntoSlotAFollowsSelectedAnchorFormulaStyle() {
        let birthday =
            Calendar.current.date(
                from: DateComponents(
                    year: 2025,
                    month: 5,
                    day: 26
                )
            ) ?? Date()
        let subject =
            MemorySubject(
                identity: .init(
                    displayName: "王途途",
                    shortName: "途途"
                ),
                relationship: .init(
                    role: "宝宝",
                    label: "妈妈眼里的宝宝"
                ),
                definition: "测试对象",
                referenceDate: birthday,
                timeAnchors: [
                    .init(
                        title: "生日",
                        date: birthday,
                        note: "出生日期",
                        anchorType: .birthday,
                        expressionStyle: .birthdayMinimal
                    )
                ],
                activeTimeAnchorID: nil,
                expressionSubjectSource: .shortName,
                behavior: .init(
                    primaryAnchor: "生日",
                    iconStrategy: .autoMatch,
                    badgeStrategy: .autoMatch,
                    memoryExpression: .init(
                        title: "生日记忆",
                        blocks: []
                    )
                ),
                decorations: []
            )
        let engine =
            V1PreviewCompositionEngine()
        let context =
            V1PreviewCompositionContext(
                subject: subject,
                birthdayDate: birthday
            )
        let slotADraft =
            V1PreviewDraft(
                items: [
                    .text("记录"),
                    engine.makeModuleItem(
                        .smartTime,
                        context: context
                    )
                ]
            )

        #expect(
            renderModel(
                for: slotADraft,
                context: context,
                engine: engine
            )
            .displayText == "记录途途｜11个月28天"
        )
    }
}

private func renderModel(
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
    case .failure(let error):
        Issue.record(
            "Expected preview render-model build to succeed, got \(error.message)"
        )
        return V1PreviewRenderModel(
            templateSourceText: "",
            displayText: ""
        )
    }
}

private func previewSubject() -> MemorySubject {
    let birthday =
        Calendar.current.date(
            from: DateComponents(
                year: 2025,
                month: 5,
                day: 26
            )
        ) ?? Date()

    return MemorySubject(
        identity: .init(
            displayName: "王途途",
            shortName: "途途"
        ),
        relationship: .init(
            role: "宝宝",
            label: "妈妈眼里的宝宝"
        ),
        definition: "测试对象",
        referenceDate: birthday,
        timeAnchors: [
            .init(
                title: "生日",
                date: birthday,
                note: "出生日期",
                anchorType: .birthday
            )
        ],
        activeTimeAnchorID: nil,
        expressionSubjectSource: .shortName,
        behavior: MemoryBehavior(
            primaryAnchor: "生日",
            iconStrategy: .autoMatch,
            badgeStrategy: .autoMatch,
            memoryExpression: MemoryExpression(
                title: "生日记忆",
                blocks: [.text("生日智能模块")]
            )
        ),
        decorations: []
    )
}
#endif
