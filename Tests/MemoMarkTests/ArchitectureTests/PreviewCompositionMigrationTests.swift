#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Preview composition migration", .serialized)
struct PreviewCompositionMigrationTests {

    @MainActor
    @Test("BootstrapMemoryCardPreviewDraftsIntent preserves the current default V1 preview texts")
    func bootstrapIntentPreservesCurrentDefaultV1PreviewTexts() throws {

        let engine =
            MemoryCardPreviewCompositionEngine()
        let subject =
            previewSubject()
        let context =
            MemoryCardPreviewCompositionContext(
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
            BootstrapMemoryCardPreviewDraftsIntent(
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
                == "记录于2026年6月1日 星期一 下午 12:00"
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
                == "今天小宝1岁6天"
            )
        case .failure(let error):
            Issue.record(
                "Expected default V1 draft bootstrap to succeed, got \(error.message)"
            )
        }
    }

    @MainActor
    @Test("BuildMemoryCardPreviewRenderModelIntent resolves known tokens and mirrors production removal for unknown tokens")
    func buildRenderModelIntentMirrorsProductionUnknownTokenBehavior() {

        let engine =
            MemoryCardPreviewCompositionEngine()
        let context =
            MemoryCardPreviewCompositionContext(
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
            MemoryCardPreviewDraftItem.token(
                MemoryCardPreviewCompositionModule
                    .captureDate
                    .title,
                value: "旧值",
                templateValue:
                    MemoryCardPreviewCompositionModule
                    .captureDate
                    .rendererToken,
                systemImage:
                    MemoryCardPreviewCompositionModule
                    .captureDate
                    .systemImage
            )
        let unknownItem =
            MemoryCardPreviewDraftItem.token(
                "未知",
                value: "保持原样",
                templateValue: "{{not_mapped}}",
                systemImage: "questionmark.circle"
            )

        let captureDateModel =
            renderModel(
                for: MemoryCardPreviewDraft(
                    items: [captureDateItem]
                ),
                context: context,
                engine: engine
            )
        let unknownItemModel =
            renderModel(
                for: MemoryCardPreviewDraft(
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
            == "2026年6月1日 星期一"
        )
        #expect(
            unknownItemModel.templateSourceText
            == "{{not_mapped}}"
        )
        #expect(
            unknownItemModel.displayText
            == ""
        )
    }

    @MainActor
    @Test("Subject nickname module saves the production nickname token")
    func subjectNicknameModuleSavesProductionNicknameToken() {

        let engine =
            MemoryCardPreviewCompositionEngine()
        let context =
            MemoryCardPreviewCompositionContext(
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
        let item =
            engine.makeModuleItem(
                .subjectNickname,
                context: context
            )
        let model =
            renderModel(
                for:
                    MemoryCardPreviewDraft(
                        items: [item]
                    ),
                context: context,
                engine: engine
            )

        #expect(
            MemoryCardPreviewCompositionModule
                .subjectNickname
                .rendererToken == "{{subject_nickname}}"
        )
        #expect(
            IOSInsertableModule
                .subjectNickname
                .rendererToken == "{{subject_nickname}}"
        )
        #expect(
            model.templateSourceText == "{{subject_nickname}}"
        )
        #expect(
            model.displayText == "小宝"
        )
    }

    @Test("Dynamic preview modules save production renderer tokens")
    func dynamicPreviewModulesSaveProductionRendererTokens() {
        let engine = MemoryCardPreviewCompositionEngine()
        let context = MemoryCardPreviewCompositionContext(
            subject: previewSubject(),
            birthdayDate: Date(timeIntervalSince1970: 0)
        )

        for module in MemoryCardPreviewCompositionModule.allCases
            where module != .custom {
            let item = engine.makeModuleItem(
                module,
                context: context
            )

            #expect(
                item.savedValue == module.rendererToken,
                "\(module.rawValue) saved preview sample \(item.savedValue)"
            )
        }
    }

    @Test("Custom preview module remains literal content")
    func customPreviewModuleRemainsLiteralContent() {
        let engine = MemoryCardPreviewCompositionEngine()
        let context = MemoryCardPreviewCompositionContext(
            subject: nil,
            birthdayDate: Date(timeIntervalSince1970: 0)
        )
        let item = engine.makeModuleItem(
            .custom,
            context: context
        )

        #expect(item.savedValue == item.value)
        #expect(
            item.savedValue
            != MemoryCardPreviewCompositionModule.custom.rendererToken
        )
        #expect(
            engine.templateText(
                for: MemoryCardPreviewDraft(items: [item])
            ) == item.value
        )
    }

    @Test("Classic White uses Memory Summary instead of legacy anchor variables")
    func classicWhiteUsesMemorySummaryInsteadOfLegacyAnchorVariables() {
        #expect(
            Template.classicWhite
                .rightBottomArea
                .items
                .first?
                .value
            == "{{memory_summary}}"
        )
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
                preset: .classicWhite,
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
    @Test("BuildMemoryCardPreviewRenderModelIntent preserves the current slot B and slot D wording")
    func buildRenderModelIntentPreservesCurrentSlotBWordingAndSmartTimeWording() {

        let engine =
            MemoryCardPreviewCompositionEngine()
        let context =
            MemoryCardPreviewCompositionContext(
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
            MemoryCardPreviewDraft(
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
            MemoryCardPreviewDraft(
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
            .displayText == "记录于2026年6月1日 星期一 下午 12:00"
        )
        #expect(
            renderModel(
                for: slotDDraft,
                context: context,
                engine: engine
            )
            .displayText == "今天小宝1岁6天"
        )
    }

    @MainActor
    @Test("V1 preview location module keeps legacy token while sourcing display value from ExpressionContext")
    func v1PreviewLocationModuleKeepsLegacyTokenWhileSourcingDisplayValueFromExpressionContext() {

        let engine =
            MemoryCardPreviewCompositionEngine()
        let subject =
            previewSubject()
        let context =
            MemoryCardPreviewCompositionContext(
                subject: subject,
                birthdayDate: subject.referenceDate
            )

        let model =
            renderModel(
                for:
                    MemoryCardPreviewDraft(
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
            == "示例省 · 示例市"
        )
    }

    @Test("Boundary V1 preview location source uses ExpressionContext instead of direct rendered demo string")
    func boundaryV1PreviewLocationSourceUsesExpressionContextInsteadOfDirectRenderedDemoString() throws {
        let source =
            try String(
                contentsOfFile:
                    MemoMarkTestPaths.path(
                        "Source/MemoMark/MemoMark/iOS/Views/MemoryCardPreviewCompositionEngine.swift"
                    ),
                encoding: .utf8
            )

        #expect(source.contains("ExpressionContext"))
        #expect(source.contains("LocationExpressionProvider"))
        #expect(source.contains("LocationContextBuilder"))
        #expect(!source.contains("return \"示例省 · 示例市\""))
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
                    displayName: "示例对象",
                    shortName: "小宝"
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
            MemoryCardPreviewCompositionEngine()
        let context =
            MemoryCardPreviewCompositionContext(
                subject: subject,
                birthdayDate: birthday
            )
        let slotADraft =
            MemoryCardPreviewDraft(
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
            .displayText == "记录小宝｜1岁6天"
        )
    }
}

private func renderModel(
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
    case .failure(let error):
        Issue.record(
            "Expected preview render-model build to succeed, got \(error.message)"
        )
        return MemoryCardPreviewRenderModel(
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
            displayName: "示例对象",
            shortName: "小宝"
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
