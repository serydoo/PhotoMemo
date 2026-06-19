import Foundation

struct MainAlertState {

    var title = ""

    var message = ""

    var isPresented = false
}

struct MainPresentationState {

    var showsAnchorManager = false

    var showsTemplateRenameSheet = false

    var showsPermissionSetupSheet = false

    var showsOperationGuideSheet = false

    var showsWorkspaceConfigurationRenameSheet =
        false

    var selectedOperationGuideTopic:
        MainOperationGuideTopic = .overview

    var workspaceConfigurationNameDraft =
        ""

    var templateNameDraft = ""
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
