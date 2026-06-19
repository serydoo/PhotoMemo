import Foundation

struct MainAlertState {

    var title = ""

    var message = ""

    var isPresented = false
}

struct MainPresentationState {

    enum CompactTab: String {

        case preview

        case editor
    }

    var showsAnchorManager = false

    var showsTemplateRenameSheet = false

    var showsPermissionSetupSheet = false

    var showsOperationGuideSheet = false

    var showsWorkspaceConfigurationRenameSheet =
        false

    var selectedOperationGuideTopic:
        MainOperationGuideTopic = .overview

    var compactTab: CompactTab = .preview

    var workspaceConfigurationNameDraft =
        ""

    var templateNameDraft = ""
}

struct MainSaveFeedbackState {

    var isPresented = false

    var title = ""

    var message = ""
}

struct MainEditorSessionState {

    var focusedField: MainFieldSlot?

    var displayTexts:
        [MainFieldSlot: String] = [:]

    var selections:
        [MainFieldSlot: NSRange] = [:]

    var moduleSpansBySlot:
        [MainFieldSlot: [TemplateEditorModuleSpan]] = [:]
}
