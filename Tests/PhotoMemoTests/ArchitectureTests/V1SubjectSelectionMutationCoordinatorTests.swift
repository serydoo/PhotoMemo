#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("V1 subject selection mutation coordinator")
struct V1SubjectSelectionMutationCoordinatorTests {

    @Test("user subject change with a new anchor date refreshes through birthday sync without marking dirty twice")
    func userSubjectChangeWithANewAnchorDateRefreshesThroughBirthdaySyncWithoutMarkingDirtyTwice() {
        let decision =
            V1SubjectSelectionMutationCoordinator
            .decision(
                subjectAnchorDate: Date(timeIntervalSince1970: 86_400),
                currentBirthdayDate: Date(timeIntervalSince1970: 0),
                isApplyingBootstrapState: false
            )

        #expect(
            decision.updatedBirthdayDate
            == Date(timeIntervalSince1970: 86_400)
        )
        #expect(
            decision.nextBirthdayDateBehavior
            == .refreshWithoutDirtying
        )
        #expect(decision.shouldRefreshPreview == false)
        #expect(decision.shouldMarkDirty == false)
    }

    @Test("bootstrap subject restore suppresses birthday side effects and lets bootstrap runtime refresh once")
    func bootstrapSubjectRestoreSuppressesBirthdaySideEffectsAndLetsBootstrapRuntimeRefreshOnce() {
        let decision =
            V1SubjectSelectionMutationCoordinator
            .decision(
                subjectAnchorDate: Date(timeIntervalSince1970: 86_400),
                currentBirthdayDate: Date(timeIntervalSince1970: 0),
                isApplyingBootstrapState: true
            )

        #expect(
            decision.updatedBirthdayDate
            == Date(timeIntervalSince1970: 86_400)
        )
        #expect(
            decision.nextBirthdayDateBehavior
            == .suppressRefreshAndDirtying
        )
        #expect(decision.shouldRefreshPreview == false)
        #expect(decision.shouldMarkDirty == false)
    }

    @Test("subject restoration with the same anchor refreshes without marking dirty")
    func subjectRestorationWithTheSameAnchorRefreshesWithoutMarkingDirty() {
        let date =
            Date(timeIntervalSince1970: 86_400)
        let decision =
            V1SubjectSelectionMutationCoordinator
            .decision(
                subjectAnchorDate: date,
                currentBirthdayDate: date,
                isApplyingBootstrapState: false
            )

        #expect(decision.updatedBirthdayDate == nil)
        #expect(decision.nextBirthdayDateBehavior == nil)
        #expect(decision.shouldRefreshPreview)
        #expect(decision.shouldMarkDirty == false)
    }

    @Test("subject restoration without an anchor refreshes without marking dirty")
    func subjectRestorationWithoutAnAnchorRefreshesWithoutMarkingDirty() {
        let decision =
            V1SubjectSelectionMutationCoordinator
            .decision(
                subjectAnchorDate: nil,
                currentBirthdayDate: Date(timeIntervalSince1970: 86_400),
                isApplyingBootstrapState: false
            )

        #expect(decision.updatedBirthdayDate == nil)
        #expect(decision.nextBirthdayDateBehavior == nil)
        #expect(decision.shouldRefreshPreview)
        #expect(decision.shouldMarkDirty == false)
    }

    @Test("dirty configuration requires saving before selecting another subject")
    func dirtyConfigurationRequiresSavingBeforeSelectingAnotherSubject() {
        let currentID = UUID(
            uuidString: "11111111-1111-1111-1111-111111111111"
        )!
        let destinationID = UUID(
            uuidString: "22222222-2222-2222-2222-222222222222"
        )!

        #expect(
            V1SubjectSelectionMutationCoordinator
                .requiresSavingCurrentConfiguration(
                    destinationSubjectID: destinationID,
                    currentSubjectID: currentID,
                    isCurrentConfigurationDirty: true
                )
        )
        #expect(
            V1SubjectSelectionMutationCoordinator
                .requiresSavingCurrentConfiguration(
                    destinationSubjectID: currentID,
                    currentSubjectID: currentID,
                    isCurrentConfigurationDirty: true
                ) == false
        )
        #expect(
            V1SubjectSelectionMutationCoordinator
                .requiresSavingCurrentConfiguration(
                    destinationSubjectID: destinationID,
                    currentSubjectID: currentID,
                    isCurrentConfigurationDirty: false
                ) == false
        )
    }

    @Test("birthday-date behavior keeps user edits dirty but suppresses programmatic dirtying")
    func birthdayDateBehaviorKeepsUserEditsDirtyButSuppressesProgrammaticDirtying() {
        #expect(
            V1SubjectSelectionMutationCoordinator
            .effect(for: .userInitiated)
            == .init(
                shouldRefreshPreview: true,
                shouldMarkDirty: true
            )
        )
        #expect(
            V1SubjectSelectionMutationCoordinator
            .effect(for: .refreshWithoutDirtying)
            == .init(
                shouldRefreshPreview: true,
                shouldMarkDirty: false
            )
        )
        #expect(
            V1SubjectSelectionMutationCoordinator
            .effect(for: .suppressRefreshAndDirtying)
            == .init(
                shouldRefreshPreview: false,
                shouldMarkDirty: false
            )
        )
    }
}
#endif
