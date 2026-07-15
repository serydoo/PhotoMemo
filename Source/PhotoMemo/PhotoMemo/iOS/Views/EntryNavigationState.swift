#if !PHOTOMEMO_SHARE_EXTENSION
import CoreGraphics
import Foundation

enum PhotoMemoiOSV1EntrySection: Hashable {
    case region(CardRegion)
    case logo
    case anchor
}

struct EntryNavigationState {
    var flowState: V1EntryFlowState
    var expandedEditorSections: Set<PhotoMemoiOSV1EntrySection>
    var profileOffsetY: CGFloat
    var previewOffsetY: CGFloat

    init() {
        self.init(
            flowState: V1EntryFlowState(),
            expandedEditorSections: [],
            profileOffsetY: 0,
            previewOffsetY: 0
        )
    }

    init(flowState: V1EntryFlowState) {
        self.init(
            flowState: flowState,
            expandedEditorSections: [],
            profileOffsetY: 0,
            previewOffsetY: 0
        )
    }

    init(
        flowState: V1EntryFlowState,
        expandedEditorSections: Set<PhotoMemoiOSV1EntrySection>,
        profileOffsetY: CGFloat = 0,
        previewOffsetY: CGFloat = 0
    ) {
        self.flowState = flowState
        self.expandedEditorSections = expandedEditorSections
        self.profileOffsetY = profileOffsetY
        self.previewOffsetY = previewOffsetY
    }

    var editorRevealProgress: CGFloat {
        let threshold: CGFloat = 30
        let distance: CGFloat = 120
        let traveled = max(-profileOffsetY - threshold, 0)
        return min(traveled / distance, 1)
    }

    var previewPinProgress: CGFloat {
        let threshold: CGFloat = 6
        let distance: CGFloat = 56
        let traveled = max(-previewOffsetY - threshold, 0)
        return min(traveled / distance, 1)
    }

    mutating func apply(
        _ transition: (V1EntryFlowState) -> V1EntryFlowState
    ) {
        flowState = transition(flowState)
    }

    mutating func openSettings(
        presentation: V1EntryPresentation
    ) {
        apply { state in
            V1EntryFlowCoordinator.openSettings(
                presentation: presentation,
                from: state
            )
        }
    }

    mutating func updateScrollOffsets(
        profile: CGFloat? = nil,
        preview: CGFloat? = nil
    ) {
        if let profile {
            profileOffsetY = profile
        }
        if let preview {
            previewOffsetY = preview
        }
    }

    mutating func setEditorSection(
        _ section: PhotoMemoiOSV1EntrySection,
        isExpanded: Bool
    ) {
        if isExpanded {
            expandedEditorSections.insert(section)
        } else {
            expandedEditorSections.remove(section)
        }
    }
}
#endif
