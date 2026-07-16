#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 bootstrap flow coordinator")
struct V1BootstrapFlowCoordinatorTests {

    @Test("aggregate runtime applies the active configuration draft after restoring the library")
    @MainActor
    func aggregateRuntimeAppliesActiveConfigurationDraftAfterRestore() throws {
        let subject = try #require(
            ConfigurationCenterState.mock.selectedSubject
        )
        var template = Template.classicWhite
        template.leftTopArea.items = [
            TemplateItem(
                type: .text,
                name: "Recorder",
                value: "Aggregate Recorder",
                isEnabled: true
            )
        ]
        let configuration = MemoryConfigurationRecord(
            id: UUID(uuidString: "91919191-9191-9191-9191-919191919191")!,
            title: "Aggregate Active",
            revision: 5,
            savedAt: Date(timeIntervalSince1970: 500),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: template,
                regionTemplateIDs: [.slotA: "aggregate.recorder"],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: "Aggregate Memory"
                )
            ),
            presentation: .init(
                route: .classicWhite,
                locationConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(for: "cityDistrict"),
                logo: .init(mode: .customUpload, badge: nil)
            ),
            output: .init(
                mediaMode: .originalFormat,
                livePhotoPolicy: .preserveMotion,
                photosDescriptionPolicy: .init(
                    isEnabled: false,
                    overrideText: "Aggregate Description"
                ),
                album: .init(
                    destination: .existingAlbum,
                    identifier: "aggregate-album",
                    title: "Aggregate Album"
                )
            )
        )
        let aggregate = ConfigurationLibraryRecord(
            revision: 9,
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
        var events: [String] = []
        var appliedProjection: V1ConfigurationDraftProjection?
        let runtime = V1BootstrapRuntimeCoordinator(
            setApplyingBootstrapState: { _ in },
            updateProjection: { _ in },
            restoreSubjectLibrary: { _, _, _, _ in },
            restoreConfigurationLibrary: { restored in
                #expect(restored == aggregate)
                events.append("restore")
            },
            applyConfigurationDraftProjection: { projection in
                events.append("project")
                appliedProjection = projection
            },
            restoreSelectedSubject: { _ in },
            applyWelcomeState: { _ in },
            refreshDynamicPreview: {}
        )

        runtime.apply(
            V1BootstrapFlowPatch(
                shouldSaveSubjectLibrary: true,
                customLogoBadge: nil,
                logoMode: .appleMini,
                logoStatusMessage: nil,
                outputTarget: .automatic,
                mediaOutputMode: .staticImage,
                selectedExistingAlbumIdentifier: "",
                suggestedNewAlbumName: nil,
                locationDisplayConfiguration: nil,
                sessionRestorePlan:
                    .restoreConfigurationLibrary(aggregate),
                birthdayDate: nil,
                welcomeState: .init(
                    hasSeenWelcome: true,
                    showsWelcomePage: false,
                    showsWorkflowGuide: false
                ),
                regionDrafts: [:]
            )
        )

        #expect(events == ["restore", "project"])
        #expect(appliedProjection?.configurationID == configuration.id)
        #expect(appliedProjection?.customMemoryWriteText == "Aggregate Memory")
        #expect(appliedProjection?.photosDescriptionOverride == "Aggregate Description")
        #expect(appliedProjection?.selectedAlbumIdentifier == "aggregate-album")
        #expect(
            appliedProjection?.regionDrafts[.slotA]?.items.first?.value
            == "Aggregate Recorder"
        )
    }

    @Test("aggregate bootstrap restores the configuration library instead of legacy slots")
    @MainActor
    func aggregateBootstrapRestoresConfigurationLibrary() throws {
        var state = ConfigurationCenterState.mock
        let subject = try #require(state.selectedSubject)
        let configuration = MemoryConfigurationRecord(
            id: UUID(uuidString: "81818181-8181-8181-8181-818181818181")!,
            title: "Aggregate Active",
            revision: 4,
            savedAt: Date(timeIntervalSince1970: 400),
            selectedTimeAnchorID: subject.primaryTimeAnchor?.id,
            editor: .init(
                template: .classicWhite,
                regionTemplateIDs: [.slotA: "aggregate.recorder"],
                memoryCopy: .init(
                    usesCustomText: true,
                    customText: "Aggregate Memory"
                )
            ),
            presentation: .init(
                route: .classicWhite,
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
        let aggregate = ConfigurationLibraryRecord(
            revision: 9,
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
        let bootstrapState = V1ConfigurationBootstrapState(
            configurationLibrary: aggregate,
            draftProjection: .init(configuration: configuration),
            subjects: [subject],
            selectedSubjectID: subject.id,
            memoryPresets: [],
            selectedMemoryPresetID: nil,
            selectedSubject: subject,
            customLogoBadge: nil,
            logoMode: .appleMini,
            outputTarget: .automatic,
            selectedExistingAlbumIdentifier: "",
            suggestedNewAlbumName: nil
        )
        let coordinator = V1BootstrapFlowCoordinator(
            loadConfigurationState: { bootstrapState },
            loadDrafts: { _, makeDefaultDraft in
                Dictionary(
                    uniqueKeysWithValues: CardRegion.memoryCardRegions.map {
                        ($0, makeDefaultDraft($0))
                    }
                )
            }
        )

        let patch = coordinator.bootstrap(
            hasSeenWelcome: true,
            fallbackBirthdayDate: Date(timeIntervalSince1970: 1),
            makeDefaultDraft: { _ in V1EditorDraft(items: []) }
        )

        guard case .restoreConfigurationLibrary(let restored) =
            patch.sessionRestorePlan else {
            Issue.record("Expected aggregate restore plan")
            return
        }
        #expect(restored == aggregate)
    }

    @Test("bootstrap composes persisted restore welcome state and draft bootstrap into one compact patch")
    func bootstrapComposesPersistedRestoreWelcomeStateAndDraftBootstrapIntoOneCompactPatch() {
        let selectedAnchorDate =
            Date(timeIntervalSince1970: 86_400)
        let selectedSubject =
            Self.makeSubject(
                displayName: "小宝成长记录",
                shortName: "小宝",
                label: "成长记录",
                anchorTitle: "生日",
                anchorDate: selectedAnchorDate
            )
        let earlierSubject =
            Self.makeSubject(
                displayName: "另一位对象",
                shortName: "另一位",
                label: "备用对象",
                anchorTitle: "纪念日",
                anchorDate: Date(timeIntervalSince1970: 0)
            )
        let badge =
            Badge(
                name: "自选标识",
                type: .customUpload,
                imagePath: "/tmp/custom-logo.png"
            )
        let state =
            V1ConfigurationBootstrapState(
                subjects: [earlierSubject, selectedSubject],
                selectedSubjectID: selectedSubject.id,
                selectedSubject: nil,
                subjectLibraryReadFailure: nil,
                customLogoBadge: badge,
                logoMode: .customUpload,
                outputTarget: .existingAlbum,
                selectedExistingAlbumIdentifier: "album-existing",
                suggestedNewAlbumName: "成长记录",
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "provinceCityDistrict"
                    )
            )
        let expectedDrafts: [CardRegion: V1EditorDraft] = [
            .slotA: V1EditorDraft(items: [.text("A 区")]),
            .slotD: V1EditorDraft(items: [.text("D 区")])
        ]
        let fallbackBirthdayDate =
            Date(timeIntervalSince1970: 999_999)
        var capturedContext: V1PreviewCompositionContext?

        let coordinator =
            V1BootstrapFlowCoordinator(
                loadConfigurationState: {
                    state
                },
                loadDrafts: { context, _ in
                    capturedContext = context
                    return expectedDrafts
                },
                presentWelcome: { hasSeenWelcome in
                    V1WelcomeFlowCoordinator
                        .presentWelcome(
                            hasSeenWelcome: hasSeenWelcome
                        )
                }
            )

        let patch =
            coordinator.bootstrap(
                hasSeenWelcome: false,
                fallbackBirthdayDate: fallbackBirthdayDate,
                makeDefaultDraft: { _ in
                    V1EditorDraft(items: [.text("默认")])
                }
            )

        #expect(patch.shouldSaveSubjectLibrary == true)
        #expect(patch.customLogoBadge == badge)
        #expect(patch.logoMode == .customUpload)
        #expect(patch.logoStatusMessage == "已使用自选 Logo。")
        #expect(patch.outputTarget == .existingAlbum)
        #expect(
            patch.selectedExistingAlbumIdentifier
            == "album-existing"
        )
        #expect(
            patch.suggestedNewAlbumName
            == "成长记录"
        )
        #expect(
            patch.locationDisplayConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(
                    for: "provinceCityDistrict"
                )
        )
        #expect(patch.birthdayDate == selectedAnchorDate)
        #expect(
            patch.welcomeState
            == V1WelcomeFlowState(
                hasSeenWelcome: false,
                showsWelcomePage: true,
                showsWorkflowGuide: false
            )
        )
        #expect(patch.regionDrafts == expectedDrafts)
        #expect(capturedContext?.subject == selectedSubject)
        #expect(
            capturedContext?.birthdayDate
            == selectedAnchorDate
        )
        #expect(
            capturedContext?.locationDisplayConfiguration
            == LocationDisplayInspectorPresenter
                .configuration(
                    for: "provinceCityDistrict"
                )
        )

        switch patch.sessionRestorePlan {
        case .restoreLibrary(
            let restoredSubjects,
            let selectedSubjectID,
            let memoryPresets,
            let selectedMemoryPresetID
        ):
            #expect(
                restoredSubjects
                == [earlierSubject, selectedSubject]
            )
            #expect(
                selectedSubjectID
                == selectedSubject.id
            )
            #expect(memoryPresets.isEmpty)
            #expect(selectedMemoryPresetID == nil)
        default:
            Issue.record(
                "Expected bootstrap patch to restore the saved subject library."
            )
        }
    }

    @Test("bootstrap preserves decode-failure guard and falls back to single selected subject restore")
    func bootstrapPreservesDecodeFailureGuardAndFallsBackToSingleSelectedSubjectRestore() {
        let fallbackSubject =
            Self.makeSubject(
                displayName: "备用对象",
                shortName: "宝宝",
                label: "家庭记录",
                anchorTitle: "生日",
                anchorDate: Date(
                    timeIntervalSince1970: 345_600
                )
            )
        let readFailure =
            PhotoMemoSharedDefaultsReadFailure(
                storageKey: "photomemo.v1.subjectLibrary",
                payloadByteCount: 256,
                underlyingDescription: "Corrupted payload"
            )
        var capturedContext: V1PreviewCompositionContext?

        let coordinator =
            V1BootstrapFlowCoordinator(
                loadConfigurationState: {
                    V1ConfigurationBootstrapState(
                        subjects: nil,
                        selectedSubjectID: nil,
                        selectedSubject: fallbackSubject,
                        subjectLibraryReadFailure:
                            readFailure,
                        customLogoBadge: nil,
                        logoMode: .subjectAvatar,
                        outputTarget: .automatic,
                        selectedExistingAlbumIdentifier:
                            "",
                        suggestedNewAlbumName: nil
                    )
                },
                loadDrafts: { context, _ in
                    capturedContext = context
                    return [:]
                },
                presentWelcome: { hasSeenWelcome in
                    V1WelcomeFlowCoordinator
                        .presentWelcome(
                            hasSeenWelcome: hasSeenWelcome
                        )
                }
            )

        let patch =
            coordinator.bootstrap(
                hasSeenWelcome: true,
                fallbackBirthdayDate: Date(
                    timeIntervalSince1970: 0
                ),
                makeDefaultDraft: { _ in
                    V1EditorDraft(items: [.text("默认")])
                }
            )

        #expect(patch.shouldSaveSubjectLibrary == false)
        #expect(patch.customLogoBadge == nil)
        #expect(patch.logoMode == .subjectAvatar)
        #expect(patch.logoStatusMessage == nil)
        #expect(patch.outputTarget == .automatic)
        #expect(
            patch.selectedExistingAlbumIdentifier
                .isEmpty
        )
        #expect(
            patch.birthdayDate
            == fallbackSubject.primaryTimeAnchor?.date
        )
        #expect(
            patch.welcomeState
            == V1WelcomeFlowState(
                hasSeenWelcome: true,
                showsWelcomePage: false,
                showsWorkflowGuide: false
            )
        )
        #expect(capturedContext?.subject == fallbackSubject)

        switch patch.sessionRestorePlan {
        case .restoreSelectedSubject(let subject):
            #expect(subject == fallbackSubject)
        default:
            Issue.record(
                "Expected bootstrap patch to restore the fallback selected subject."
            )
        }
    }

    private static func makeSubject(
        displayName: String,
        shortName: String,
        label: String,
        anchorTitle: String,
        anchorDate: Date
    ) -> MemorySubject {
        let anchor =
            MemorySubject.TimeAnchor(
                title: anchorTitle,
                date: anchorDate,
                note: "\(anchorTitle)说明",
                anchorType: .birthday,
                expressionStyle: .birthdayAgeToday
            )

        return MemorySubject(
            identity: .init(
                displayName: displayName,
                shortName: shortName
            ),
            relationship: .init(
                role: "family",
                label: label
            ),
            definition: "用于测试 bootstrap 协调器。",
            referenceDate: anchorDate,
            timeAnchors: [anchor],
            activeTimeAnchorID: anchor.id,
            behavior: .init(
                primaryAnchor: anchorTitle,
                iconStrategy: .autoMatch,
                badgeStrategy: .fixed,
                memoryExpression: .init(
                    title: "默认表达",
                    blocks: []
                )
            ),
            decorations: []
        )
    }
}
#endif
