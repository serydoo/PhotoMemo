#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("Presentation style persistence")
struct PresentationStylePersistenceTests {

    @Test("Each presentation style declares its own content projection")
    func contentContractKeepsStyleContentIndependent() {
        let classic = RecordCardPresentationStyle
            .classicWhite
            .contentContract
        let minimal = RecordCardPresentationStyle
            .minimal
            .contentContract

        #expect(
            classic.editableTextAreas == [
                .leftTop,
                .leftBottom,
                .rightTop,
                .rightBottom
            ]
        )
        #expect(classic.renderedTextAreas.count == 4)
        #expect(classic.photoDescriptionTextAreas == [.rightBottom])

        #expect(minimal.editableTextAreas == [.leftTop])
        #expect(minimal.renderedTextAreas == [.leftTop])
        #expect(minimal.photoDescriptionTextAreas == [.leftTop])
    }

    @Test("Semantic content roles are owned by each presentation style")
    func semanticRolesDoNotReuseClassicMeaningAccidentally() {
        let classic = RecordCardPresentationStyle
            .classicWhite
            .contentContract
        let minimal = RecordCardPresentationStyle
            .minimal
            .contentContract

        #expect(
            classic.textArea(for: .recorder) == .leftTop
        )
        #expect(
            classic.textArea(for: .memory) == .rightBottom
        )
        #expect(
            classic.photoDescriptionRoles == [.memory]
        )
        #expect(
            minimal.textArea(for: .primaryOutput) == .leftTop
        )
        #expect(
            minimal.role(for: .leftTop) == .primaryOutput
        )
        #expect(
            minimal.photoDescriptionRoles == [.primaryOutput]
        )
        #expect(
            minimal.role(for: .rightBottom) == nil
        )
    }

    @Test("Editor semantics follow the selected presentation style")
    func editorSemanticsFollowPresentationStyle() {
        let classic = RecordCardPresentationStyle
            .classicWhite
            .contentContract
        let minimal = RecordCardPresentationStyle
            .minimal
            .contentContract

        #expect(
            classic.editorTitle(using: .simplifiedChinese)
                == "输出内容"
        )
        #expect(
            minimal.editorTitle(using: .simplifiedChinese)
                == "极简内容"
        )
        #expect(
            minimal.editorAccessibilityLabel(
                using: .simplifiedChinese
            ) == "极简卡片内容"
        )
        #expect(
            minimal.editorAccessibilityHint(
                using: .simplifiedChinese
            )?.contains("Apple Photos") == true
        )
        #expect(
            classic.editorAccessibilityHint(
                using: .simplifiedChinese
            ) == nil
        )
    }

    @Test("Card regions are derived from the selected style contract")
    func cardRegionsFollowStyleContract() {
        #expect(
            CardRegion.editableRegions(for: .classicWhite)
                == CardRegion.memoryCardRegions
        )
        #expect(
            CardRegion.editableRegions(for: .minimal)
                == [.slotA]
        )
    }

    @Test("Minimal presentation style survives a persistence round trip")
    func minimalStyleRoundTrip() throws {
        let presentation = makePresentation(route: .minimal)

        let data = try JSONEncoder().encode(presentation)
        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Presentation.self,
            from: data
        )

        #expect(decoded == presentation)
        #expect(decoded.route == .minimal)
    }

    @Test("Classic and Minimal presentations do not encode FM payload")
    func nonFilmMarkPresentationsDoNotEncodeFilmMarkPayload() throws {
        for route in [
            RecordCardPresentationStyle.classicWhite,
            RecordCardPresentationStyle.minimal
        ] {
            let object = try #require(
                JSONSerialization.jsonObject(
                    with: JSONEncoder().encode(
                        makePresentation(route: route)
                    )
                ) as? [String: Any]
            )

            #expect(object["filmMark"] == nil)
        }
    }

    @Test("FilmMark appearance and placement survive a persistence round trip")
    func filmMarkConfigurationRoundTrip() throws {
        let configuration = FilmMarkConfiguration(
            appearance: FilmMarkAppearanceDraft(
                fontID: .spaceMono,
                fontSize: .prominent,
                color: FilmMarkRGBAColor(
                    red: 0.17,
                    green: 0.64,
                    blue: 0.92,
                    alpha: 0.82
                ),
                substrate: .translucentLabel
            ),
            placement: FilmMarkPlacementDraft(
                anchor: .bottomLeft,
                normalizedOffset: FilmMarkNormalizedOffset(
                    x: 0.125,
                    y: -0.075
                )
            )
        )
        let presentation = MemoryConfigurationRecord.Presentation(
            route: .filmMark,
            locationConfiguration: nil,
            logo: .init(mode: .appleMini, badge: nil),
            filmMark: configuration
        )

        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Presentation.self,
            from: JSONEncoder().encode(presentation)
        )

        #expect(decoded.route == .filmMark)
        #expect(decoded.filmMark == configuration)
    }

    @Test("A legacy presentation without a route defaults to classic white")
    func missingRouteDefaultsToClassicWhite() throws {
        let data = try encodedPresentationObject(route: .minimal) { object in
            object.removeValue(forKey: "route")
        }

        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Presentation.self,
            from: data
        )

        #expect(decoded.route == .classicWhite)
        #expect(decoded.logo.mode == .appleMini)
    }

    @Test("An explicit unknown presentation route fails closed")
    func unknownRouteFailsClosed() throws {
        let data = try encodedPresentationObject(route: .minimal) { object in
            object["route"] = "futureStyle"
        }

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                MemoryConfigurationRecord.Presentation.self,
                from: data
            )
        }
    }

    @Test("An explicit FilmMark route fails closed without its payload")
    func explicitFilmMarkRouteFailsClosedWithoutPayload() throws {
        let data = try encodedPresentationObject(route: .minimal) { object in
            object["route"] = RecordCardPresentationStyle.filmMark.rawValue
            object.removeValue(forKey: "filmMark")
        }

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                MemoryConfigurationRecord.Presentation.self,
                from: data
            )
        }
    }

    @Test("Editor persists independent templates for each presentation style")
    func editorPersistsIndependentTemplatesForEachPresentationStyle() throws {
        var classic = Template.classicWhite
        classic.leftTopArea.items = [.title]
        var minimal = Template.classicWhite
        minimal.leftTopArea.items = [.story]

        let editor = MemoryConfigurationRecord.Editor(
            template: classic,
            templatesByPresentationStyle: [
                .classicWhite: classic,
                .minimal: minimal
            ],
            regionTemplateIDs: [:],
            memoryCopy: .init(
                usesCustomText: false,
                customText: ""
            )
        )
        let decoded = try JSONDecoder().decode(
            MemoryConfigurationRecord.Editor.self,
            from: JSONEncoder().encode(editor)
        )

        #expect(
            decoded.template(for: .classicWhite)
                .leftTopArea.items == [.title]
        )
        #expect(
            decoded.template(for: .minimal)
                .leftTopArea.items == [.story]
        )
        #expect(
            decoded.template(for: .classicWhite)
                != decoded.template(for: .minimal)
        )
    }

    @Test("FM does not enter the legacy template transport dictionary")
    func filmMarkDoesNotEnterLegacyTemplateTransportDictionary() throws {
        let editor = MemoryConfigurationRecord.Editor(
            template: .classicWhite,
            templatesByPresentationStyle: [
                .classicWhite: .classicWhite,
                .minimal: .classicWhite,
                .filmMark: .classicWhite
            ],
            regionTemplateIDs: [:],
            memoryCopy: .init(
                usesCustomText: false,
                customText: ""
            )
        )

        let object = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(editor)
            ) as? [String: Any]
        )
        let bindings = try #require(
            object["templatesByPresentationStyle"] as? [[String: Any]]
        )
        #expect(
            bindings.contains {
                ($0["style"] as? String) == "filmMark"
            } == false
        )
        #expect(
            MemoryConfigurationRecord.Editor(
                template: .classicWhite,
                templatesByPresentationStyle: [
                    .filmMark: .classicWhite
                ],
                regionTemplateIDs: [:],
                memoryCopy: .init(
                    usesCustomText: false,
                    customText: ""
                )
            ).templatesByPresentationStyle[.filmMark] == nil
        )
    }

    @Test("explicit FM transport fails closed when its payload is missing")
    func explicitFilmMarkTransportFailsClosedWithoutPayload() {
        let snapshot = BatchConfigurationSnapshot(
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            presentationRouteRawValue:
                RecordCardPresentationStyle.filmMark.rawValue,
            filmMarkConfiguration: nil,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )

        #expect(
            snapshot.presentationRouteValidationError?.diagnosticCode
                == "missing_film_mark_configuration"
        )
    }

    @Test("legacy compatibility cleanup keeps the frozen FM route and payload")
    func legacyCompatibilityCleanupKeepsFilmMarkPayload() {
        let configuration = FilmMarkConfiguration.default
        let snapshot = BatchConfigurationSnapshot(
            configurationID: UUID(),
            configurationRevision: 3,
            productionContractVersion: 1,
            template: .classicWhite,
            badge: nil,
            anchor: nil,
            presentationRouteRawValue:
                RecordCardPresentationStyle.filmMark.rawValue,
            filmMarkConfiguration: configuration,
            shouldWritePhotoDescription: false,
            photoDescriptionOverride: "",
            selectedAlbumIdentifier: ""
        )

        let legacy = snapshot.asLegacyTransportCompatibility()
        #expect(legacy.configurationID == nil)
        #expect(legacy.configurationRevision == nil)
        #expect(legacy.productionContractVersion == nil)
        #expect(
            legacy.presentationRouteRawValue
                == RecordCardPresentationStyle.filmMark.rawValue
        )
        #expect(legacy.filmMarkConfiguration == configuration)
    }

    @Test("Classic and Minimal production snapshots do not carry FM payload")
    func nonFilmMarkProductionSnapshotsDoNotCarryFilmMarkPayload() throws {
        let subject = ConfigurationCenterMockSeed.makeState().subjects[0]

        for route in [
            RecordCardPresentationStyle.classicWhite,
            RecordCardPresentationStyle.minimal
        ] {
            let configuration = MemoryConfigurationRecord(
                id: UUID(),
                title: "隔离测试",
                revision: 1,
                savedAt: Date(timeIntervalSince1970: 0),
                selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
                editor: .init(
                    template: .classicWhite,
                    regionTemplateIDs: [:],
                    memoryCopy: .init(
                        usesCustomText: false,
                        customText: ""
                    )
                ),
                presentation: .init(
                    route: route,
                    locationConfiguration: nil,
                    logo: .init(mode: .appleMini, badge: nil)
                ),
                output: .init(
                    mediaMode: .originalFormat,
                    livePhotoPolicy: .preserveMotion,
                    photosDescriptionPolicy: .init(
                        isEnabled: false,
                        overrideText: ""
                    ),
                    album: .automatic
                )
            )
            let state = ConfigurationLibraryRecord(
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

            let snapshot = try ProductionConfigurationSnapshotFactory.resolve(
                reference: .init(
                    configurationID: configuration.id,
                    revision: configuration.revision
                ),
                from: state
            )

            #expect(snapshot.filmMarkConfiguration == nil)
        }
    }

    private func makePresentation(
        route: RecordCardPresentationStyle
    ) -> MemoryConfigurationRecord.Presentation {
        MemoryConfigurationRecord.Presentation(
            route: route,
            locationConfiguration: nil,
            logo: .init(
                mode: .appleMini,
                badge: nil
            )
        )
    }

    private func encodedPresentationObject(
        route: RecordCardPresentationStyle,
        mutation: (inout [String: Any]) -> Void
    ) throws -> Data {
        let encoded = try JSONEncoder().encode(
            makePresentation(route: route)
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded)
                as? [String: Any]
        )
        mutation(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }
}
#endif
