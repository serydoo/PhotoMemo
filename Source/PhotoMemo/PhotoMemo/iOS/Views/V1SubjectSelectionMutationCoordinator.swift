#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1SubjectSelectionMutationDecision: Equatable {
    let updatedBirthdayDate: Date?
    let nextBirthdayDateBehavior: V1BirthdayDateChangeBehavior?
    let shouldRefreshPreview: Bool
    let shouldMarkDirty: Bool
}

struct V1BirthdayDateChangeEffect: Equatable {
    let shouldRefreshPreview: Bool
    let shouldMarkDirty: Bool
}

enum V1BirthdayDateChangeBehavior: Equatable {
    case userInitiated
    case refreshWithoutDirtying
    case suppressRefreshAndDirtying
}

enum V1SubjectSelectionMutationCoordinator {

    static func decision(
        subjectAnchorDate: Date?,
        currentBirthdayDate: Date,
        isApplyingBootstrapState: Bool
    ) -> V1SubjectSelectionMutationDecision {
        guard let subjectAnchorDate else {
            return V1SubjectSelectionMutationDecision(
                updatedBirthdayDate: nil,
                nextBirthdayDateBehavior: nil,
                shouldRefreshPreview: !isApplyingBootstrapState,
                shouldMarkDirty: !isApplyingBootstrapState
            )
        }

        guard subjectAnchorDate != currentBirthdayDate else {
            return V1SubjectSelectionMutationDecision(
                updatedBirthdayDate: nil,
                nextBirthdayDateBehavior: nil,
                shouldRefreshPreview: !isApplyingBootstrapState,
                shouldMarkDirty: !isApplyingBootstrapState
            )
        }

        return V1SubjectSelectionMutationDecision(
            updatedBirthdayDate: subjectAnchorDate,
            nextBirthdayDateBehavior:
                isApplyingBootstrapState
                ? .suppressRefreshAndDirtying
                : .refreshWithoutDirtying,
            shouldRefreshPreview: false,
            shouldMarkDirty: false
        )
    }

    static func effect(
        for behavior: V1BirthdayDateChangeBehavior
    ) -> V1BirthdayDateChangeEffect {
        switch behavior {
        case .userInitiated:
            return V1BirthdayDateChangeEffect(
                shouldRefreshPreview: true,
                shouldMarkDirty: true
            )
        case .refreshWithoutDirtying:
            return V1BirthdayDateChangeEffect(
                shouldRefreshPreview: true,
                shouldMarkDirty: false
            )
        case .suppressRefreshAndDirtying:
            return V1BirthdayDateChangeEffect(
                shouldRefreshPreview: false,
                shouldMarkDirty: false
            )
        }
    }
}
#endif
