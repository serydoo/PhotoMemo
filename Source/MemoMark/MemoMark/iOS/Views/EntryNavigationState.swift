#if !MEMOMARK_SHARE_EXTENSION
import CoreGraphics
import Foundation

enum ConfigurationCenterSection: Hashable {
    case region(CardRegion)
    case logo
    case anchor
}

struct EntryNavigationState {
    var flowState: EntryFlowState
    var expandedEditorSections: Set<ConfigurationCenterSection>
    var profileOffsetY: CGFloat
    var previewOffsetY: CGFloat

    init() {
        self.init(
            flowState: EntryFlowState(),
            expandedEditorSections: [],
            profileOffsetY: 0,
            previewOffsetY: 0
        )
    }

    init(flowState: EntryFlowState) {
        self.init(
            flowState: flowState,
            expandedEditorSections: [],
            profileOffsetY: 0,
            previewOffsetY: 0
        )
    }

    init(
        flowState: EntryFlowState,
        expandedEditorSections: Set<ConfigurationCenterSection>,
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
        _ transition: (EntryFlowState) -> EntryFlowState
    ) {
        flowState = transition(flowState)
    }

    mutating func openSettings(
        presentation: EntryPresentation
    ) {
        apply { state in
            EntryFlowCoordinator.openSettings(
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
        _ section: ConfigurationCenterSection,
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
