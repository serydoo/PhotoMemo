#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1LocalConfigurationLibraryPresentationModifier: ViewModifier {
    @Binding var presentation:
        V1LocalConfigurationLibraryPresentationState

    let subjectName: String
    let onRefresh: () -> Void
    let onRestore: (LocalConfigurationBackupRecord, Bool) -> Void
    let onDelete: (LocalConfigurationBackupRecord) -> Void

    func body(content: Content) -> some View {
        content
            .alert(
                "无法完成配置操作",
                isPresented: $presentation.showsHomeActionFailureAlert
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(
                    presentation.statusMessage
                    ?? "操作未完成，请稍后重试。"
                )
            }
            .sheet(isPresented: $presentation.isPresented) {
                V1LocalConfigurationLibrarySheet(
                    subjectName: subjectName,
                    backups: presentation.backups,
                    isWorking: presentation.isWorking,
                    onRefresh: onRefresh,
                    onRestore: { onRestore($0, false) },
                    onRestoreAndMakeCurrent: { onRestore($0, true) },
                    onDelete: onDelete
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
    }
}
#endif
