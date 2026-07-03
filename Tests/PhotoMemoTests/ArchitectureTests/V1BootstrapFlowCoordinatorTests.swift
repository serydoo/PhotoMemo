#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 bootstrap flow coordinator")
struct V1BootstrapFlowCoordinatorTests {

    @Test("bootstrap composes persisted restore welcome state and draft bootstrap into one compact patch")
    func bootstrapComposesPersistedRestoreWelcomeStateAndDraftBootstrapIntoOneCompactPatch() {
        let selectedAnchorDate =
            Date(timeIntervalSince1970: 86_400)
        let selectedSubject =
            Self.makeSubject(
                displayName: "途途成长记录",
                shortName: "途途",
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
                suggestedNewAlbumName: "成长记录"
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

        switch patch.sessionRestorePlan {
        case .restoreLibrary(
            let restoredSubjects,
            let selectedSubjectID
        ):
            #expect(
                restoredSubjects
                == [earlierSubject, selectedSubject]
            )
            #expect(
                selectedSubjectID
                == selectedSubject.id
            )
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
