#if !MEMOMARK_SHARE_EXTENSION
import Foundation

struct SubjectSelectionMutationDecision: Equatable {
    let updatedBirthdayDate: Date?
    let nextBirthdayDateBehavior: BirthdayDateChangeBehavior?
    let shouldRefreshPreview: Bool
    let shouldMarkDirty: Bool
}

struct BirthdayDateChangeEffect: Equatable {
    let shouldRefreshPreview: Bool
    let shouldMarkDirty: Bool
}

enum BirthdayDateChangeBehavior: Equatable {
    case userInitiated
    case refreshWithoutDirtying
    case suppressRefreshAndDirtying
}

enum SubjectSelectionMutationCoordinator {

    static func requiresSavingCurrentConfiguration(
        destinationSubjectID: UUID,
        currentSubjectID: UUID?,
        isCurrentConfigurationDirty: Bool
    ) -> Bool {
        isCurrentConfigurationDirty
            && destinationSubjectID != currentSubjectID
    }

    static func decision(
        subjectAnchorDate: Date?,
        currentBirthdayDate: Date,
        isApplyingBootstrapState: Bool
    ) -> SubjectSelectionMutationDecision {
        guard let subjectAnchorDate else {
            return SubjectSelectionMutationDecision(
                updatedBirthdayDate: nil,
                nextBirthdayDateBehavior: nil,
                shouldRefreshPreview: !isApplyingBootstrapState,
                shouldMarkDirty: false
            )
        }

        guard subjectAnchorDate != currentBirthdayDate else {
            return SubjectSelectionMutationDecision(
                updatedBirthdayDate: nil,
                nextBirthdayDateBehavior: nil,
                shouldRefreshPreview: !isApplyingBootstrapState,
                shouldMarkDirty: false
            )
        }

        return SubjectSelectionMutationDecision(
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
        for behavior: BirthdayDateChangeBehavior
    ) -> BirthdayDateChangeEffect {
        switch behavior {
        case .userInitiated:
            return BirthdayDateChangeEffect(
                shouldRefreshPreview: true,
                shouldMarkDirty: true
            )
        case .refreshWithoutDirtying:
            return BirthdayDateChangeEffect(
                shouldRefreshPreview: true,
                shouldMarkDirty: false
            )
        case .suppressRefreshAndDirtying:
            return BirthdayDateChangeEffect(
                shouldRefreshPreview: false,
                shouldMarkDirty: false
            )
        }
    }
}
#endif
