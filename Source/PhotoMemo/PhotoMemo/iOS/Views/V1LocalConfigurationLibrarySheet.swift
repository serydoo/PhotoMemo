#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1LocalConfigurationLibrarySheet: View {

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
                            "还没有本地备份",
                            systemImage: MemoMarkSymbol.localStorage.name,
                            description: Text(
                                "在首页保存配置后，会自动保留在当前记忆对象的本地备份中。"
                            )
                        )
                    } else {
                        ForEach(backups, id: \.configurationID) {
                            backup in
                            backupRow(backup)
                        }
                    }
                } header: {
                    Text("\(subjectName)的配置")
                } footer: {
                    Text("恢复为副本会保留当前配置；恢复并设为当前会立即切换到该备份。")
                }
            }
            .navigationTitle("本地备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
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
                    .accessibilityLabel("刷新本地备份")
                }
            }
            .alert(
                pendingDeleteBackup.map { "删除“\($0.title)”备份？" }
                    ?? "删除本地备份？",
                isPresented: Binding(
                    get: { pendingDeleteBackup != nil },
                    set: { if !$0 { pendingDeleteBackup = nil } }
                )
            ) {
                Button("取消", role: .cancel) {
                    pendingDeleteBackup = nil
                }
                Button("删除本地备份", role: .destructive) {
                    guard let backup = pendingDeleteBackup else { return }
                    pendingDeleteBackup = nil
                    onDelete(backup)
                }
            } message: {
                Text("当前正在使用的配置不会被删除。此操作无法撤销。")
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
                    "版本 \(backup.revision) · \(V1UserFacingDateFormatter.dateTime(backup.savedAt))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button("恢复为副本") {
                    onRestore(backup)
                }

                Button("恢复并设为当前") {
                    onRestoreAndMakeCurrent(backup)
                }

                Divider()

                Button("删除本地备份", role: .destructive) {
                    pendingDeleteBackup = backup
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .disabled(isWorking)
            .accessibilityLabel("更多备份操作")
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDeleteBackup = backup
            } label: {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button("恢复为副本") { onRestore(backup) }
            Button("恢复并设当前") { onRestoreAndMakeCurrent(backup) }
            Button("删除本地备份", role: .destructive) {
                pendingDeleteBackup = backup
            }
        }
    }

}
#endif
