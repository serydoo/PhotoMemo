#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

struct ConfigurationPageSurface<
    PreviewContent: View,
    EditorContent: View
>: View {

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.verticalSizeClass)
    private var verticalSizeClass

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let configurationStatus: ConfigurationPersistenceStatus
    let isSavingConfiguration: Bool
    let isSelectedProcessingDefault: Bool
    let isEditingCardContent: Bool
    let usesExternalConfigurationActions: Bool
    let isPreviewVisible: Bool
    let onTogglePreview: (() -> Void)?
    let previewWidthPolicy: ConfigurationPreviewWidthPolicy
    let editorScrollRequest: ConfigurationEditorScrollRequest?
    let onDismissKeyboard: () -> Void
    let onSaveCurrentConfiguration: () -> Void
    let onSetAsProcessingDefault: () -> Void
    let onCreateConfiguration: () -> Void
    let onResetConfiguration: () -> Void
    let onDeleteConfiguration: () -> Void

    private let previewContent: PreviewContent
    private let editorContent: EditorContent

    init(
        previewPinProgress: CGFloat,
        editorRevealProgress: CGFloat,
        configurationStatus: ConfigurationPersistenceStatus,
        isSavingConfiguration: Bool,
        isSelectedProcessingDefault: Bool,
        isEditingCardContent: Bool = false,
        usesExternalConfigurationActions: Bool = false,
        isPreviewVisible: Bool = true,
        onTogglePreview: (() -> Void)? = nil,
        previewWidthPolicy: ConfigurationPreviewWidthPolicy = .readable,
        editorScrollRequest: ConfigurationEditorScrollRequest? = nil,
        onDismissKeyboard: @escaping () -> Void,
        onSaveCurrentConfiguration: @escaping () -> Void,
        onSetAsProcessingDefault: @escaping () -> Void,
        onCreateConfiguration: @escaping () -> Void,
        onResetConfiguration: @escaping () -> Void,
        onDeleteConfiguration: @escaping () -> Void,
        @ViewBuilder previewContent: () -> PreviewContent,
        @ViewBuilder editorContent: () -> EditorContent
    ) {
        self.previewPinProgress = previewPinProgress
        self.editorRevealProgress = editorRevealProgress
        self.configurationStatus = configurationStatus
        self.isSavingConfiguration = isSavingConfiguration
        self.isSelectedProcessingDefault = isSelectedProcessingDefault
        self.isEditingCardContent = isEditingCardContent
        self.usesExternalConfigurationActions = usesExternalConfigurationActions
        self.isPreviewVisible = isPreviewVisible
        self.onTogglePreview = onTogglePreview
        self.previewWidthPolicy = previewWidthPolicy
        self.editorScrollRequest = editorScrollRequest
        self.onDismissKeyboard = onDismissKeyboard
        self.onSaveCurrentConfiguration = onSaveCurrentConfiguration
        self.onSetAsProcessingDefault = onSetAsProcessingDefault
        self.onCreateConfiguration = onCreateConfiguration
        self.onResetConfiguration = onResetConfiguration
        self.onDeleteConfiguration = onDeleteConfiguration
        self.previewContent = previewContent()
        self.editorContent = editorContent()
    }

    var body: some View {
        MemoryCardEditorPageSurface(
            previewPinProgress: previewPinProgress,
            editorRevealProgress: editorRevealProgress,
            pageTitle: isEditingCardContent ? nil : interfaceLanguage.localized(
                key: "configuration.page.title",
                fallback: "记忆配置"
            ),
            pageSubtitle: isEditingCardContent ? nil : interfaceLanguage.localized(
                key: "configuration.page.subtitle",
                fallback: "决定这段记忆围绕哪个重要时刻、如何呈现，以及保存到哪里。"
            ),
            isPreviewVisible: isPreviewVisible,
            onTogglePreview: onTogglePreview,
            previewWidthPolicy: previewWidthPolicy,
            editorScrollRequest: editorScrollRequest,
            editorContentOwnsScrolling: isEditingCardContent,
            usesSystemBottomAccessory: usesExternalConfigurationActions,
            onDismissKeyboard: onDismissKeyboard
        ) {
            previewContent
        } editorContent: {
            editorContent
        } accessoryContent: {
            if usesToolbarConfigurationActions
                || usesExternalConfigurationActions
                || isEditingCardContent {
                EmptyView()
            } else {
                ConfigurationActionFooter(
                    configurationStatus: configurationStatus,
                    isSavingConfiguration: isSavingConfiguration,
                    isSelectedProcessingDefault: isSelectedProcessingDefault,
                    onSaveCurrentConfiguration: onSaveCurrentConfiguration,
                    onSetAsProcessingDefault: onSetAsProcessingDefault,
                    onCreateConfiguration: onCreateConfiguration,
                    onResetConfiguration: onResetConfiguration,
                    onDeleteConfiguration: onDeleteConfiguration
                )
            }
        }
        .navigationTitle("")
        .toolbar(usesToolbarConfigurationActions && !isEditingCardContent ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if usesToolbarConfigurationActions && !isEditingCardContent {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ConfigurationActionToolbar(
                        configurationStatus: configurationStatus,
                        isSavingConfiguration: isSavingConfiguration,
                        isSelectedProcessingDefault: isSelectedProcessingDefault,
                        onSaveCurrentConfiguration: onSaveCurrentConfiguration,
                        onSetAsProcessingDefault: onSetAsProcessingDefault,
                        onCreateConfiguration: onCreateConfiguration,
                        onResetConfiguration: onResetConfiguration,
                        onDeleteConfiguration: onDeleteConfiguration
                    )
                }
            }
        }
    }

    private var usesToolbarConfigurationActions: Bool {
        AdaptivePageLayout.usesRegularWorkspace(
            hasRegularHorizontalSizeClass: horizontalSizeClass == .regular,
            hasRegularVerticalSizeClass: verticalSizeClass == .regular
        )
    }

    private var interfaceLanguage: MemoMarkLanguage {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        )?.resolvedLanguage ?? .interfaceStored
    }
}
#endif
