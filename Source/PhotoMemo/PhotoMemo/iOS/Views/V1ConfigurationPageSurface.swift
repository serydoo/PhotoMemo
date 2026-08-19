#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1ConfigurationPageSurface<
    PreviewContent: View,
    EditorContent: View
>: View {

    @AppStorage(
        MemoMarkLanguage.interfacePreferenceStorageKey,
        store: PhotoMemoSharedContainer.sharedUserDefaults
    )
    private var interfaceLanguagePreferenceRawValue =
        MemoMarkInterfaceLanguagePreference.system.rawValue

    let previewPinProgress: CGFloat
    let editorRevealProgress: CGFloat
    let configurationStatus: V1ConfigurationStatus
    let isSavingConfiguration: Bool
    let onDismissKeyboard: () -> Void
    let onSaveCurrentConfiguration: () -> Void
    let onCreateConfiguration: () -> Void
    let onResetConfiguration: () -> Void
    let onDeleteConfiguration: () -> Void

    private let previewContent: PreviewContent
    private let editorContent: EditorContent

    init(
        previewPinProgress: CGFloat,
        editorRevealProgress: CGFloat,
        configurationStatus: V1ConfigurationStatus,
        isSavingConfiguration: Bool,
        onDismissKeyboard: @escaping () -> Void,
        onSaveCurrentConfiguration: @escaping () -> Void,
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
        self.onDismissKeyboard = onDismissKeyboard
        self.onSaveCurrentConfiguration = onSaveCurrentConfiguration
        self.onCreateConfiguration = onCreateConfiguration
        self.onResetConfiguration = onResetConfiguration
        self.onDeleteConfiguration = onDeleteConfiguration
        self.previewContent = previewContent()
        self.editorContent = editorContent()
    }

    var body: some View {
        V1EditorPageSurface(
            previewPinProgress: previewPinProgress,
            editorRevealProgress: editorRevealProgress,
            pageTitle: interfaceLanguage.localized(
                key: "configuration.page.title",
                fallback: "配置中心"
            ),
            pageSubtitle: interfaceLanguage.localized(
                key: "configuration.page.subtitle",
                fallback: "围绕一个人和一个重要时刻，决定照片如何呈现。"
            ),
            onDismissKeyboard: onDismissKeyboard
        ) {
            previewContent
        } editorContent: {
            editorContent
        } accessoryContent: {
            V1ConfigurationActionFooter(
                configurationStatus: configurationStatus,
                isSavingConfiguration: isSavingConfiguration,
                onSaveCurrentConfiguration: onSaveCurrentConfiguration,
                onCreateConfiguration: onCreateConfiguration,
                onResetConfiguration: onResetConfiguration,
                onDeleteConfiguration: onDeleteConfiguration
            )
        }
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }

    private var interfaceLanguage: MemoMarkLanguage {
        MemoMarkInterfaceLanguagePreference(
            rawValue: interfaceLanguagePreferenceRawValue
        )?.resolvedLanguage ?? .interfaceStored
    }
}
#endif
