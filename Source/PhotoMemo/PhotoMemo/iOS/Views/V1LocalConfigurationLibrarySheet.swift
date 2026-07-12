#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1LocalConfigurationLibrarySheet: View {

    let subjectName: String
    let backups: [LocalConfigurationBackupRecord]
    let isWorking: Bool
    let statusMessage: String?
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
                if let statusMessage {
                    Section {
                        Label(
                            statusMessage,
                            systemImage: "info.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if backups.isEmpty {
                        ContentUnavailableView(
                            "还没有本地备份",
                            systemImage: MemoMarkSymbol.localStorage.name,
                            description: Text(
                                "在首页向左滑动配置并点按“保存”，备份会保留在当前记忆对象的本地库中。"
                            )
                        )
                    } else {
                        ForEach(backups, id: \.configurationID) {
                            backup in
                            backupRow(backup)
                        }
                    }
                } header: {
                    Text(subjectName)
                } footer: {
                    Text("恢复会作为副本加入；“恢复并设当前”会通过正常保存路径切换当前配置。")
                }
            }
            .navigationTitle("本地配置库")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(true)
                    .accessibilityLabel("导入配置备份即将开放")

                    Button(action: onRefresh) {
                        if isWorking {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(isWorking)
                    .accessibilityLabel("刷新本地配置库")
                }
            }
            .confirmationDialog(
                "删除这个本地备份？",
                isPresented: Binding(
                    get: { pendingDeleteBackup != nil },
                    set: { if !$0 { pendingDeleteBackup = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("删除本地备份", role: .destructive) {
                    guard let backup = pendingDeleteBackup else { return }
                    pendingDeleteBackup = nil
                    onDelete(backup)
                }
                Button("取消", role: .cancel) {
                    pendingDeleteBackup = nil
                }
            } message: {
                Text("这只会删除本地备份，不会删除当前正在使用的配置。")
            }
        }
    }

    private func backupRow(
        _ backup: LocalConfigurationBackupRecord
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.title)
                    .font(.subheadline.weight(.semibold))

                Text(
                    "版本 \(backup.revision) · \(backup.savedAt.formatted(date: .abbreviated, time: .shortened))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button("恢复") {
                    onRestore(backup)
                }
                .buttonStyle(.bordered)

                Button("恢复并设当前") {
                    onRestoreAndMakeCurrent(backup)
                }
                .buttonStyle(.borderedProminent)

                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(true)
                .accessibilityLabel("含资源的完整导出即将开放")

                Button(role: .destructive) {
                    pendingDeleteBackup = backup
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("删除本地配置备份")
            }
            .font(.caption.weight(.semibold))
            .disabled(isWorking)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                pendingDeleteBackup = backup
            } label: {
                Label("删除", systemImage: "trash")
            }
            .tint(.red)
        }
        .contextMenu {
            Button("恢复") { onRestore(backup) }
            Button("恢复并设当前") { onRestoreAndMakeCurrent(backup) }
            Button("删除本地备份", role: .destructive) {
                pendingDeleteBackup = backup
            }
        }
    }
}
#endif
