#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing
@testable import MemoMark

@Suite("V1 bootstrap runtime coordinator")
struct V1BootstrapRuntimeCoordinatorTests {

    @Test("home bootstrap forwards an empty preset library instead of treating it as absent")
    func homeBootstrapForwardsEmptyPresetLibrary() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: repositoryRoot.appendingPathComponent(
                "Source/MemoMark/MemoMark/iOS/Views/MemoMarkiOSV1View.swift"
            ),
            encoding: .utf8
        )

        #expect(
            source.contains(
                "memoryPresets:\n                        memoryPresets,"
            )
        )
        #expect(
            source.contains("memoryPresets.isEmpty\n                        ? nil") == false
        )
    }

    @Test("restore-library patch updates view projection, welcome state, and preview refresh")
    @MainActor
    func restoreLibraryPatchUpdatesViewProjectionWelcomeStateAndPreviewRefresh() {
        let selectedSubject =
            Self.makeSubject(
                displayName: "小宝",
                anchorTitle: "生日",
                anchorDate: Date(timeIntervalSince1970: 86_400)
            )
        let earlierSubject =
            Self.makeSubject(
                displayName: "妈妈",
                anchorTitle: "纪念日",
                anchorDate: Date(timeIntervalSince1970: 43_200)
            )
        let expectedDrafts: [CardRegion: V1EditorDraft] = [
            .slotA: V1EditorDraft(items: [.text("A")])
        ]
        let patch =
            V1BootstrapFlowPatch(
                shouldSaveSubjectLibrary: true,
                customLogoBadge: nil,
                logoMode: .subjectAvatar,
                logoStatusMessage: "已使用头像",
                outputTarget: .existingAlbum,
                mediaOutputMode: .staticImage,
                selectedExistingAlbumIdentifier: "album-1",
                suggestedNewAlbumName: "成长记录",
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "coordinate"
                    ),
                sessionRestorePlan: .restoreLibrary(
                    subjects: [earlierSubject, selectedSubject],
                    selectedSubjectID: selectedSubject.id,
                    memoryPresets: [],
                    selectedMemoryPresetID: nil
                ),
                birthdayDate: selectedSubject.primaryTimeAnchor?.date,
                welcomeState: V1WelcomeFlowState(
                    hasSeenWelcome: true,
                    showsWelcomePage: false,
                    showsWorkflowGuide: false
                ),
                regionDrafts: expectedDrafts
            )

        var applyingStates: [Bool] = []
        var receivedProjection: V1BootstrapViewProjection?
        var restoredLibrary: (
            subjects: [MemorySubject],
            selectedID: MemorySubject.ID?,
            memoryPresets: [MemoryPreset],
            selectedMemoryPresetID: MemoryPreset.ID?
        )?
        var restoredSubject: MemorySubject?
        var receivedWelcomeState: V1WelcomeFlowState?
        var refreshCount = 0

        let coordinator =
            V1BootstrapRuntimeCoordinator(
                setApplyingBootstrapState: {
                    applyingStates.append($0)
                },
                updateProjection: {
                    receivedProjection = $0
                },
                restoreSubjectLibrary: {
                    restoredLibrary = ($0, $1, $2, $3)
                },
                restoreSelectedSubject: {
                    restoredSubject = $0
                },
                applyWelcomeState: {
                    receivedWelcomeState = $0
                },
                refreshDynamicPreview: {
                    refreshCount += 1
                }
            )

        coordinator.apply(patch)

        #expect(applyingStates == [true, false])
        #expect(
            receivedProjection
            == V1BootstrapViewProjection(
                shouldSaveSubjectLibrary: true,
                customLogoBadge: nil,
                logoMode: .subjectAvatar,
                logoStatusMessage: "已使用头像",
                outputTarget: .existingAlbum,
                mediaOutputMode: .staticImage,
                selectedExistingAlbumIdentifier: "album-1",
                suggestedNewAlbumName: "成长记录",
                locationDisplayConfiguration:
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: "coordinate"
                    ),
                birthdayDate:
                    selectedSubject.primaryTimeAnchor?.date,
                regionDrafts: expectedDrafts
            )
        )
        #expect(
            restoredLibrary?.subjects
            == [earlierSubject, selectedSubject]
        )
        #expect(
            restoredLibrary?.selectedID
            == selectedSubject.id
        )
        #expect(restoredLibrary?.memoryPresets.isEmpty == true)
        #expect(restoredLibrary?.selectedMemoryPresetID == nil)
        #expect(restoredSubject == nil)
        #expect(
            receivedWelcomeState
            == V1WelcomeFlowState(
                hasSeenWelcome: true,
                showsWelcomePage: false,
                showsWorkflowGuide: false
            )
        )
        #expect(refreshCount == 1)
    }

    @Test("restore-selected-subject patch avoids library restore and still refreshes preview")
    @MainActor
    func restoreSelectedSubjectPatchAvoidsLibraryRestoreAndStillRefreshesPreview() {
        let subject =
            Self.makeSubject(
                displayName: "宝宝",
                anchorTitle: "生日",
                anchorDate: Date(timeIntervalSince1970: 172_800)
            )
        let patch =
            V1BootstrapFlowPatch(
                shouldSaveSubjectLibrary: false,
                customLogoBadge: nil,
                logoMode: .appleMini,
                logoStatusMessage: nil,
                outputTarget: .automatic,
                mediaOutputMode: .originalFormat,
                selectedExistingAlbumIdentifier: "",
                suggestedNewAlbumName: nil,
                locationDisplayConfiguration: nil,
                sessionRestorePlan: .restoreSelectedSubject(
                    subject
                ),
                birthdayDate: nil,
                welcomeState: V1WelcomeFlowState(
                    hasSeenWelcome: false,
                    showsWelcomePage: true,
                    showsWorkflowGuide: false
                ),
                regionDrafts: [:]
            )

        var didRestoreLibrary = false
        var restoredSubject: MemorySubject?
        var refreshCount = 0

        let coordinator =
            V1BootstrapRuntimeCoordinator(
                setApplyingBootstrapState: { _ in },
                updateProjection: { _ in },
                restoreSubjectLibrary: { _, _, _, _ in
                    didRestoreLibrary = true
                },
                restoreSelectedSubject: {
                    restoredSubject = $0
                },
                applyWelcomeState: { _ in },
                refreshDynamicPreview: {
                    refreshCount += 1
                }
            )

        coordinator.apply(patch)

        #expect(didRestoreLibrary == false)
        #expect(restoredSubject == subject)
        #expect(refreshCount == 1)
    }

    @Test("clear-session patch removes transient mock configuration content")
    @MainActor
    func clearSessionPatchRemovesTransientMockConfigurationContent() {
        let session = ConfigurationSession()
        #expect(!session.state.memoryPresets.isEmpty)
        let patch = V1BootstrapFlowPatch(
            shouldSaveSubjectLibrary: false,
            customLogoBadge: nil,
            logoMode: .appleMini,
            logoStatusMessage: nil,
            outputTarget: .automatic,
            mediaOutputMode: .originalFormat,
            selectedExistingAlbumIdentifier: "",
            suggestedNewAlbumName: nil,
            locationDisplayConfiguration: nil,
            sessionRestorePlan: .clearSession,
            birthdayDate: nil,
            welcomeState: V1WelcomeFlowState(
                hasSeenWelcome: true,
                showsWelcomePage: false,
                showsWorkflowGuide: false
            ),
            regionDrafts: [:]
        )
        let coordinator = V1BootstrapRuntimeCoordinator(
            setApplyingBootstrapState: { _ in },
            updateProjection: { _ in },
            restoreSubjectLibrary: { _, _, _, _ in },
            restoreSelectedSubject: { _ in },
            clearSession: {
                session.clearBootstrapContent()
            },
            applyWelcomeState: { _ in },
            refreshDynamicPreview: {}
        )

        coordinator.apply(patch)

        #expect(session.state.subjects.isEmpty)
        #expect(session.state.memoryPresets.isEmpty)
        #expect(session.state.configurationLibrary == nil)
    }

    private static func makeSubject(
        displayName: String,
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
                shortName: displayName
            ),
            relationship: .init(
                role: "family",
                label: "家庭"
            ),
            definition: "用于测试 bootstrap 运行时。",
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
