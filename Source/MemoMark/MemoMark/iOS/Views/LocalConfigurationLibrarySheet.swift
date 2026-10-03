#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

private func uiText(_ key: String) -> String {
    MemoMarkLanguage.interfaceStored.localized(key: key, fallback: key)
}

struct LocalConfigurationLibrarySheet: View {

    let subjectName: String
    let backups: [LocalConfigurationBackupRecord]
    let isWorking: Bool
    let onRefresh: () -> Void
    let onRestore: (LocalConfigurationBackupRecord) -> Void
    let onRestoreAndMakeCurrent:
        (LocalConfigurationBackupRecord) -> Void
    let onDelete: (LocalConfigurationBackupRecord) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var pendingDeleteBackup: LocalConfigurationBackupRecord?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if backups.isEmpty {
                        ContentUnavailableView(
                            uiText("还没有本地备份"),
                            systemImage: MemoMarkSymbol.localStorage.name,
                            description: Text(
                                uiText("在首页保存配置后，就能从这里找回。")
                            )
                        )
                    } else {
                        ForEach(backups, id: \.configurationID) {
                            backup in
                            backupRow(backup)
                        }
                    }
                } header: {
                    Text(
                        MemoMarkDynamicInterfaceText
                        .subjectConfigurationTitle(
                            subjectName:
                                subjectName,
                            language:
                                .interfaceStored
                        )
                    )
                } footer: {
                    Text(
                        uiText("最近保存的配置会留在这里。恢复时会保留当前配置；恢复并设为当前会立即切换到该备份。")
                    )
                }
            }
            .navigationTitle(uiText("本地备份"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(uiText("完成")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onRefresh) {
                        if isWorking {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isWorking)
                    .accessibilityLabel(uiText("刷新本地备份"))
                }
            }
            .alert(
                pendingDeleteBackup.map { String(format: uiText("local_backup.delete.named"), $0.title) }
                    ?? uiText("删除本地备份？"),
                isPresented: Binding(
                    get: { pendingDeleteBackup != nil },
                    set: { if !$0 { pendingDeleteBackup = nil } }
                )
            ) {
                Button(uiText("取消"), role: .cancel) {
                    pendingDeleteBackup = nil
                }
                Button(uiText("删除本地备份"), role: .destructive) {
                    guard let backup = pendingDeleteBackup else { return }
                    pendingDeleteBackup = nil
                    onDelete(backup)
                }
            } message: {
                Text(uiText("当前正在使用的配置不会被删除。此操作无法撤销。"))
            }
        }
    }

    private func backupRow(
        _ backup: LocalConfigurationBackupRecord
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.title)
                    .font(.subheadline.weight(.semibold))

                Text(
                    String(format: uiText("local_backup.revision_date"), String(backup.revision), UserFacingDateFormatter.dateTime(backup.savedAt))
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button(uiText("恢复为副本")) {
                    onRestore(backup)
                }

                Button(uiText("恢复并设为当前")) {
                    onRestoreAndMakeCurrent(backup)
                }

                Divider()

                Button(uiText("删除本地备份"), role: .destructive) {
                    pendingDeleteBackup = backup
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .disabled(isWorking)
            .accessibilityLabel(uiText("更多备份操作"))
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeleteBackup = backup
            } label: {
                Label(uiText("删除"), systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button(uiText("恢复为副本")) { onRestore(backup) }
            Button(uiText("恢复并设为当前")) { onRestoreAndMakeCurrent(backup) }
            Button(uiText("删除本地备份"), role: .destructive) {
                pendingDeleteBackup = backup
            }
        }
    }

}
#endif
