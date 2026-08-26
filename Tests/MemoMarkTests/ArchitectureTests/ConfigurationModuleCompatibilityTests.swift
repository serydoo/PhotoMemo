#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Configuration module compatibility")
struct ConfigurationModuleCompatibilityTests {

    @Test("Legacy normalization never replaces a multi-item region")
    func legacyNormalizationNeverReplacesAMultiItemRegion() {
        let trailingText = TemplateItem(
            type: .text,
            name: "User Text",
            value: "不要丢失"
        )
        let template = Template(
            preset: .classicWhite,
            name: "Legacy",
            leftTopArea: TemplateArea(
                name: "Left Top",
                items: [.title, trailingText]
            ),
            leftBottomArea: TemplateArea(
                name: "Left Bottom",
                items: [.captureDateLine, trailingText]
            ),
            rightTopArea: .rightTop,
            rightBottomArea: .rightBottom,
            badgeArea: .badge
        )

        let normalized = template.normalizedForEditing

        #expect(
            normalized.leftTopArea.items.map(\.value)
            == ["{{title}}", "不要丢失"]
        )
        #expect(
            normalized.leftBottomArea.items.map(\.value)
            == ["记录于{{capture_date_display}}", "不要丢失"]
        )
    }

    @Test("Dynamic modules persist production tokens instead of preview samples")
    func dynamicModulesPersistProductionTokensInsteadOfPreviewSamples() {
        let engine = V1PreviewCompositionEngine()
        let context = V1PreviewCompositionContext(
            subject: nil,
            birthdayDate: Date(timeIntervalSince1970: 0)
        )

        for module in IOSInsertableModule.allCases
            where module != .custom {
            let item = engine.makeModuleItem(
                module,
                context: context
            )

            #expect(
                item.savedValue == module.rendererToken,
                "\(module.rawValue) persisted \(item.savedValue)"
            )
        }
    }

    @Test("Classic White composite items project into localized lossless editor items")
    func classicWhiteCompositeItemsProjectIntoLocalizedLosslessEditorItems() throws {
        let configuration = Self.configuration(
            template: .classicWhite
        )

        let projection = V1ConfigurationDraftProjection(
            configuration: configuration,
            interfaceLanguage: .simplifiedChinese
        )
        let recorderItems = try #require(
            projection.regionDrafts[.slotA]?.items
        )
        let timelineItems = try #require(
            projection.regionDrafts[.slotB]?.items
        )

        #expect(
            recorderItems.map(\.templateValue)
            == [
                "{{relationship_label}}",
                "手持",
                "{{model}}",
                "记录"
            ]
        )
        #expect(
            recorderItems.map(\.kind)
            == [
                V1ContentItem.Kind.token,
                .text,
                .token,
                .text
            ]
        )
        #expect(recorderItems[0].title == "记录者称呼")
        #expect(recorderItems[2].title == "设备型号")
        #expect(
            recorderItems.allSatisfy {
                $0.title != "Relationship Device Line"
            }
        )
        #expect(
            timelineItems.prefix(2).map(\.templateValue)
            == ["记录于", "{{capture_date_display}}"]
        )
        #expect(timelineItems[1].title == "完整时间")
        #expect(
            recorderItems
                .filter { $0.kind == .token }
                .allSatisfy { !$0.value.contains("{{") }
            && !timelineItems[1].value.contains("{{")
        )
    }

    @Test("Composite projection identities remain stable across reloads")
    func compositeProjectionIdentitiesRemainStableAcrossReloads() throws {
        let configuration = Self.configuration(
            template: .classicWhite
        )

        let first = V1ConfigurationDraftProjection(
            configuration: configuration,
            interfaceLanguage: .simplifiedChinese
        )
        let second = V1ConfigurationDraftProjection(
            configuration: configuration,
            interfaceLanguage: .simplifiedChinese
        )
        let firstItems = try #require(
            first.regionDrafts[.slotA]?.items
        )
        let secondItems = try #require(
            second.regionDrafts[.slotA]?.items
        )

        #expect(
            firstItems.map(\.id)
            == secondItems.map(\.id)
        )
    }

    @Test("Module titles follow interface language without changing tokens")
    func moduleTitlesFollowInterfaceLanguageWithoutChangingTokens() throws {
        let configuration = Self.configuration(
            template: .classicWhite
        )
        let englishProjection = V1ConfigurationDraftProjection(
            configuration: configuration,
            interfaceLanguage: .english
        )
        let recorderItems = try #require(
            englishProjection.regionDrafts[.slotA]?.items
        )

        #expect(
            IOSInsertableModule.cameraModel.title(
                for: .simplifiedChinese
            ) == "设备型号"
        )
        #expect(
            IOSInsertableModule.cameraModel.title(
                for: .english
            ) == "Camera model"
        )
        #expect(recorderItems[0].title == "Recorder label")
        #expect(recorderItems[2].title == "Camera model")
        #expect(
            recorderItems.map(\.templateValue)
            == [
                "{{relationship_label}}",
                "手持",
                "{{model}}",
                "记录"
            ]
        )
    }

    @Test("Unknown tokens remain lossless without exposing persisted internal names")
    func unknownTokensRemainLosslessWithoutExposingPersistedInternalNames() throws {
        let unknownItem = TemplateItem(
            id: UUID(
                uuidString:
                    "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
            )!,
            type: .variable,
            name: "Future Internal Module Name",
            value: "before {{future_variable}} after"
        )
        let template = Self.template(
            leftTopItems: [unknownItem]
        )

        let chineseProjection = V1ConfigurationDraftProjection(
            configuration: Self.configuration(template: template),
            interfaceLanguage: .simplifiedChinese
        )
        let englishProjection = V1ConfigurationDraftProjection(
            configuration: Self.configuration(template: template),
            interfaceLanguage: .english
        )
        let chineseItems = try #require(
            chineseProjection.regionDrafts[.slotA]?.items
        )
        let englishItems = try #require(
            englishProjection.regionDrafts[.slotA]?.items
        )

        #expect(
            chineseItems.map(\.templateValue)
            == ["before ", "{{future_variable}}", " after"]
        )
        #expect(chineseItems[1].title == "无法识别的内容")
        #expect(englishItems[1].title == "Unsupported content")
        #expect(chineseItems[1].savedValue == "{{future_variable}}")
        #expect(chineseItems[1].value == "无法识别的内容")
        #expect(
            chineseItems.allSatisfy {
                $0.title != "Future Internal Module Name"
            }
        )
    }

    @Test("Every built-in composite item projects without raw display tokens or internal titles")
    func everyBuiltInCompositeItemProjectsWithoutRawDisplayTokensOrInternalTitles() throws {
        let compositeItems: [TemplateItem] = [
            .dateTime,
            .relationshipDeviceLine,
            .captureDateLine,
            .captureDateCompact,
            .deviceCameraLine,
            .immersCameraLine,
            .immersDateTimeLine,
            .immersLocationLine,
            .gearLine
        ]

        for sourceItem in compositeItems {
            let projection = V1ConfigurationDraftProjection(
                configuration: Self.configuration(
                    template: Self.template(
                        leftTopItems: [sourceItem]
                    )
                ),
                interfaceLanguage: .simplifiedChinese
            )
            let projectedItems = try #require(
                projection.regionDrafts[.slotA]?.items
            )
            let tokens = projectedItems.filter {
                $0.kind == .token
            }

            #expect(!tokens.isEmpty)
            #expect(
                tokens.allSatisfy {
                    !$0.value.contains("{{")
                }
            )
            #expect(
                projectedItems.allSatisfy {
                    $0.title != sourceItem.name
                }
            )
            #expect(
                projectedItems.map(\.templateValue)
                    .joined()
                == sourceItem.value
            )
        }
    }

    @Test("Known metadata tokens resolve from preview context without title fallback")
    func knownMetadataTokensResolveFromPreviewContextWithoutTitleFallback() {
        let engine = V1PreviewCompositionEngine()
        let context = V1PreviewCompositionContext(
            subject: nil,
            birthdayDate: Date(timeIntervalSince1970: 0),
            language: .english
        )
        let draft = V1PreviewDraft(
            items: [
                .token(
                    "Aspect ratio",
                    value: "Aspect ratio",
                    templateValue: "{{aspect_ratio}}",
                    systemImage: "rectangle"
                ),
                .token(
                    "Unknown",
                    value: "Unknown",
                    templateValue: "{{future_unknown}}",
                    systemImage: "curlybraces"
                )
            ]
        )

        let rendered = engine.renderModel(
            for: draft,
            context: context
        )

        #expect(rendered.displayText == "4:3")
        #expect(!rendered.displayText.contains("Unknown"))
    }

    @Test("Image size renderer expression remains one semantic module")
    func imageSizeRendererExpressionRemainsOneSemanticModule() throws {
        let imageSizeItem = TemplateItem(
            type: .variable,
            name: "Image Size",
            value: IOSInsertableModule.imageSize.rendererToken
        )
        let projection = V1ConfigurationDraftProjection(
            configuration: Self.configuration(
                template: Self.template(
                    leftTopItems: [imageSizeItem]
                )
            ),
            interfaceLanguage: .english
        )
        let items = try #require(
            projection.regionDrafts[.slotA]?.items
        )

        #expect(items[0].kind == .token)
        #expect(items[0].title == "Image size")
        #expect(
            items[0].savedValue
            == "{{width}} × {{height}}"
        )
    }

    @Test("Composite configuration survives JSON reload and renders without raw tokens")
    func compositeConfigurationSurvivesJSONReloadAndRendersWithoutRawTokens() throws {
        let original = Self.configuration(template: .classicWhite)
        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(
            MemoryConfigurationRecord.self,
            from: data
        )
        let projection = V1ConfigurationDraftProjection(
            configuration: restored,
            interfaceLanguage: .english
        )
        let recorderDraft = try #require(
            projection.regionDrafts[.slotA]
        )
        let engine = V1PreviewCompositionEngine()
        let renderModel = engine.renderModel(
            for: V1DraftBridge.previewDraft(from: recorderDraft),
            context: V1PreviewCompositionContext(
                subject: nil,
                birthdayDate: Date(timeIntervalSince1970: 0),
                language: restored.language
            )
        )

        #expect(
            recorderDraft.items.map(\.templateValue).joined()
            == TemplateItem.relationshipDeviceLine.value
        )
        #expect(!renderModel.displayText.contains("{{"))
        #expect(!renderModel.displayText.contains("Relationship Device Line"))
        #expect(renderModel.templateSourceText.contains("{{model}}"))
    }

    @Test("Disabled items and area identity survive edit-save round trip")
    func disabledItemsAndAreaIdentitySurviveEditSaveRoundTrip() throws {
        let disabledItem = TemplateItem(
            id: UUID(
                uuidString: "99999999-AAAA-BBBB-CCCC-DDDDDDDDDDDD"
            )!,
            type: .text,
            name: "Hidden legacy content",
            value: "必须保留",
            isEnabled: false
        )
        var template = Template.classicWhite
        let originalAreaID = template.leftTopArea.id
        template.leftTopArea.items.append(disabledItem)
        let configuration = Self.configuration(template: template)
        let projection = V1ConfigurationDraftProjection(
            configuration: configuration,
            interfaceLanguage: .simplifiedChinese
        )
        let subject = Self.subject()
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                SubjectConfigurationRecord(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: PortableAssetManifest(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )
        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: Self.aggregateDraft(from: projection)
        )
        let savedArea = candidate.configuration.editor.template.leftTopArea

        #expect(savedArea.id == originalAreaID)
        #expect(savedArea.items.contains(disabledItem))
        #expect(
            savedArea.items.first(where: { $0.id == disabledItem.id })?
                .isEnabled == false
        )
        #expect(
            savedArea.items.first(where: { $0.isEnabled })?.value
            == TemplateItem.relationshipDeviceLine.value
        )
    }

    @Test("Legacy tokens survive edit-save without semantic rewriting")
    func legacyTokensSurviveEditSaveWithoutSemanticRewriting() throws {
        for legacyValue in ["{{capture_date}}", "{{location}}"] {
            let template = Self.template(
                leftTopItems: [
                    TemplateItem(
                        type: .variable,
                        name: "Legacy",
                        value: legacyValue
                    )
                ]
            )
            let configuration = Self.configuration(template: template)
            let projection = V1ConfigurationDraftProjection(
                configuration: configuration,
                interfaceLanguage: .english
            )
            let subject = Self.subject()
            let aggregate = ConfigurationLibraryRecord(
                revision: 1,
                subjects: [
                    SubjectConfigurationRecord(
                        subject: subject,
                        configurations: [configuration],
                        assetManifest: .init(entries: [])
                    )
                ],
                activeSubjectID: subject.id,
                activeConfigurationID: configuration.id
            )
            let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
                from: aggregate,
                draft: Self.aggregateDraft(from: projection)
            )

            #expect(
                candidate.configuration.editor.template
                    .leftTopArea.items.first?.value
                == legacyValue
            )
        }
    }

    @Test("Adjacent composite tokens survive bootstrap and edit-save without inserted spaces")
    func adjacentCompositeTokensSurviveBootstrapAndEditSave() throws {
        let expression = "{{year}}{{month}}"
        let template = Self.template(
            leftTopItems: [
                TemplateItem(
                    type: .variable,
                    name: "Adjacent",
                    value: expression
                )
            ]
        )
        let configuration = Self.configuration(template: template)
        let projection = V1ConfigurationDraftProjection(
            configuration: configuration
        )
        let projectedDraft = try #require(
            projection.regionDrafts[.slotA]
        )
        let bridgedDraft = V1DraftBridge.editorDraft(
            from: V1DraftBridge.previewDraft(from: projectedDraft)
        )
        #expect(
            bridgedDraft.items.map(\.sourceItemID)
            == projectedDraft.items.map(\.sourceItemID)
        )
        let draft = Self.aggregateDraft(from: projection)
        let subject = Self.subject()
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )

        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: draft
        )

        #expect(
            candidate.configuration.editor.template.leftTopArea
                .items.map(\.value)
            == [expression]
        )
    }

    @Test("Custom module identity preserves imported literal content")
    func customModuleIdentityPreservesImportedLiteralContent() throws {
        let literal = "用户输入 {{title}} 不应被替换"
        let template = Self.template(
            leftTopItems: [
                TemplateItem(
                    type: .variable,
                    name: "Custom",
                    value: literal,
                    moduleID: .custom
                )
            ]
        )
        let projection = V1ConfigurationDraftProjection(
            configuration: Self.configuration(template: template),
            interfaceLanguage: .simplifiedChinese
        )
        let item = try #require(
            projection.regionDrafts[.slotA]?.items.first
        )

        #expect(item.kind == .text)
        #expect(item.templateValue == literal)
    }

    @Test("Persisted line breaks restore as line-break editor items")
    func persistedLineBreaksRestoreAsLineBreakEditorItems() throws {
        let template = Self.template(
            leftTopItems: [
                TemplateItem(
                    type: .text,
                    name: "Line Break",
                    value: "\n"
                )
            ]
        )
        let projection = V1ConfigurationDraftProjection(
            configuration: Self.configuration(template: template)
        )
        let item = try #require(
            projection.regionDrafts[.slotA]?.items.first
        )

        #expect(item.kind == .lineBreak)
        #expect(item.templateValue == "\n")
    }

    @Test("Unknown future module identity degrades to token inference")
    func unknownFutureModuleIdentityDegradesToTokenInference() throws {
        let item = TemplateItem(
            type: .variable,
            name: "Future",
            value: "{{future_token}}"
        )
        let encoded = try JSONEncoder().encode(item)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        object["moduleID"] = "futureModule"
        let futureData = try JSONSerialization.data(
            withJSONObject: object
        )
        let decoded = try JSONDecoder().decode(
            TemplateItem.self,
            from: futureData
        )

        #expect(decoded.moduleID == nil)
        #expect(decoded.value == "{{future_token}}")
    }

    @Test("Disabled item ordering survives edit-save round trip")
    func disabledItemOrderingSurvivesEditSaveRoundTrip() throws {
        let disabledItem = TemplateItem(
            type: .text,
            name: "Hidden",
            value: "hidden",
            isEnabled: false
        )
        let template = Self.template(
            leftTopItems: [
                TemplateItem(type: .text, name: "A", value: "A"),
                disabledItem,
                TemplateItem(type: .text, name: "B", value: "B")
            ]
        )
        let configuration = Self.configuration(template: template)
        let projection = V1ConfigurationDraftProjection(
            configuration: configuration
        )
        let subject = Self.subject()
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )
        let candidate = try V1ConfigurationAggregateCandidateBuilder.build(
            from: aggregate,
            draft: Self.aggregateDraft(from: projection)
        )

        #expect(
            candidate.configuration.editor.template.leftTopArea
                .items.map(\.value)
            == ["A", "hidden", "B"]
        )
    }

    @Test("Duplicate template item identities fail configuration validation")
    func duplicateTemplateItemIdentitiesFailConfigurationValidation() {
        let duplicateID = UUID(
            uuidString: "88888888-AAAA-BBBB-CCCC-DDDDDDDDDDDD"
        )!
        var template = Template.classicWhite
        template.leftTopArea.items = [
            TemplateItem(
                id: duplicateID,
                type: .text,
                name: "First",
                value: "A"
            ),
            TemplateItem(
                id: duplicateID,
                type: .text,
                name: "Second",
                value: "B"
            )
        ]
        let configuration = Self.configuration(template: template)

        #expect(
            PortableMemoryConfigurationDocument
                .templateItemIssues(configuration)
                .contains(
                    .duplicateTemplateItemID(
                        configurationID: configuration.id,
                        itemID: duplicateID
                    )
                )
        )
    }

    @Test("Legacy library repair preserves content while replacing duplicate item identities")
    func legacyLibraryRepairPreservesContentWhileReplacingDuplicateItemIdentities() throws {
        let duplicateID = UUID()
        let template = Self.template(
            leftTopItems: [
                TemplateItem(
                    id: duplicateID,
                    type: .text,
                    name: "A",
                    value: "A"
                ),
                TemplateItem(
                    id: duplicateID,
                    type: .text,
                    name: "B",
                    value: "B"
                )
            ]
        )
        let configuration = Self.configuration(template: template)
        let subject = Self.subject()
        let aggregate = ConfigurationLibraryRecord(
            revision: 1,
            subjects: [
                .init(
                    subject: subject,
                    configurations: [configuration],
                    assetManifest: .init(entries: [])
                )
            ],
            activeSubjectID: subject.id,
            activeConfigurationID: configuration.id
        )

        let repaired = aggregate.repairingDuplicateTemplateItemIDs()
        let repairedItems = try #require(
            repaired.subjects.first?.configurations.first?
                .editor.template.leftTopArea.items
        )

        #expect(repairedItems.map(\.value) == ["A", "B"])
        #expect(Set(repairedItems.map(\.id)).count == 2)
        #expect(repaired.validationResult == .valid)
    }

    private static func configuration(
        template: Template
    ) -> MemoryConfigurationRecord {
        MemoryConfigurationRecord(
            id: UUID(
                uuidString:
                    "11111111-2222-3333-4444-555555555555"
            )!,
            title: "兼容测试",
            revision: 1,
            savedAt: Date(timeIntervalSince1970: 100),
            selectedTimeAnchorID: nil,
            language: .simplifiedChinese,
            editor: .init(
                template: template,
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration: nil,
                logo: .init(
                    mode: .appleMini,
                    badge: nil
                )
            ),
            output: .init(
                mediaMode: .staticImage,
                livePhotoPolicy: .staticImageOnly,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: ""
                ),
                album: .automatic
            )
        )
    }

    private static func template(
        leftTopItems: [TemplateItem]
    ) -> Template {
        Template(
            preset: .classicWhite,
            name: "Compatibility",
            leftTopArea: TemplateArea(
                name: "Left Top",
                items: leftTopItems
            ),
            leftBottomArea: .empty,
            rightTopArea: .empty,
            rightBottomArea: .empty,
            badgeArea: .badge
        )
    }

    private static func aggregateDraft(
        from projection: V1ConfigurationDraftProjection
    ) -> V1ConfigurationAggregateDraft {
        V1ConfigurationAggregateDraft(
            title: projection.title,
            regionDrafts: projection.regionDrafts,
            regionTemplateIDs: projection.regionTemplateIDs,
            locationConfiguration: projection.locationConfiguration,
            logoMode: projection.logoMode,
            badge: projection.badge,
            usesCustomMemoryWriteText:
                projection.usesCustomMemoryWriteText,
            customMemoryWriteText: projection.customMemoryWriteText,
            shouldWritePhotosDescription:
                projection.shouldWritePhotosDescription,
            photosDescriptionOverride:
                projection.photosDescriptionOverride,
            outputTarget: projection.outputTarget,
            selectedAlbumIdentifier:
                projection.selectedAlbumIdentifier,
            albumTitle: projection.albumTitle,
            mediaOutputMode: projection.mediaOutputMode,
            livePhotoPolicy: projection.livePhotoPolicy,
            selectedTimeAnchorID: projection.selectedTimeAnchorID,
            savedAt: Date(timeIntervalSince1970: 200),
            language: projection.language
        )
    }

    private static func subject() -> MemorySubject {
        MemorySubject(
            identity: .init(
                displayName: "兼容测试对象",
                shortName: "测试"
            ),
            relationship: .init(
                role: "家庭",
                label: "记录者"
            ),
            referenceDate: Date(timeIntervalSince1970: 0),
            behavior: MemoryBehavior(
                primaryAnchor: "生日",
                iconStrategy: .autoMatch,
                badgeStrategy: .autoMatch,
                memoryExpression: MemoryExpression(
                    title: "测试",
                    blocks: [.text("测试")]
                )
            ),
            decorations: []
        )
    }
}
#endif
