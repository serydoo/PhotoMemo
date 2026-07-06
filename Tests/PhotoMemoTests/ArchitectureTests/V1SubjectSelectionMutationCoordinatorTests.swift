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

    @Test("user subject change without an anchor-date mutation refreshes and marks the view dirty directly")
    func userSubjectChangeWithoutAnAnchorDateMutationRefreshesAndMarksTheViewDirtyDirectly() {
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
        #expect(decision.shouldMarkDirty)
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
