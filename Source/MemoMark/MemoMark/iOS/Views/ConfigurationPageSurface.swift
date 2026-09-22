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
            pageTitle: interfaceLanguage.localized(
                key: "configuration.page.title",
                fallback: "记忆配置"
            ),
            pageSubtitle: interfaceLanguage.localized(
                key: "configuration.page.subtitle",
                fallback: "决定这段记忆围绕哪个重要时刻、如何呈现，以及保存到哪里。"
            ),
            previewWidthPolicy: previewWidthPolicy,
            editorScrollRequest: editorScrollRequest,
            onDismissKeyboard: onDismissKeyboard
        ) {
            previewContent
        } editorContent: {
            editorContent
        } accessoryContent: {
            if usesToolbarConfigurationActions {
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
        .toolbar(usesToolbarConfigurationActions ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            if usesToolbarConfigurationActions {
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
