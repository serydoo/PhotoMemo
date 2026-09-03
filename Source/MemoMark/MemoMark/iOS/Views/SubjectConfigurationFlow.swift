#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct SubjectConfigurationFlow: View {

    private let flowState:
        SubjectConfigurationFlowState

    private let onDeleteSubject: () -> Void
    private let onCancel: () -> Void
    private let onSave: () -> Void

    @State
    private var showsDeleteConfirmation = false

    @State
    private var showsNameRequiredAlert = false

    @State
    private var saveFailureMessage: String?

    @State
    private var isSaving = false

    init(
        flowState: SubjectConfigurationFlowState,
        onDeleteSubject: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) {
        self.flowState = flowState
        self.onDeleteSubject = onDeleteSubject
        self.onCancel = onCancel
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        subjectSectionHeader(
                            title: "基础资料",
                            subtitle: "名字、关系和你熟悉的称呼。"
                        )

                        MemorySubjectEditorView(
                            session: flowState.draftSession,
                            mode: .identityOverview
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        subjectSectionHeader(
                            title: "时间锚点",
                            subtitle: "选择重要日子，让照片拥有时间答案。"
                        )

                        SubjectAnchorDetailSection(
                            session: flowState.draftSession,
                            onPersistSubjectChanges: {},
                            allowsSwipeDeletion: true
                        )
                    }

                    deleteSubjectRow
                }
                .padding(.top, 12)
                .padding(.bottom, 34)
                .adaptiveScrollContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
                )
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        dismissKeyboard()
                    }
            )
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("编辑记忆对象")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        Task { @MainActor in
                            isSaving = true
                            defer { isSaving = false }
                            guard await flowState.saveChanges() else {
                                if let message = flowState.lastSaveFailureMessage {
                                    saveFailureMessage = message
                                } else {
                                    showsNameRequiredAlert = true
                                }
                                return
                            }
                            onSave()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .alert(
                "删除这个记忆对象？",
                isPresented: $showsDeleteConfirmation
            ) {
                Button("取消", role: .cancel) {}
                Button("删除记忆对象", role: .destructive) {
                    onDeleteSubject()
                }
            } message: {
                Text("对象的基础资料和时间锚点都会被删除。此操作无法撤销。")
            }
            .alert(
                "填写对象名称",
                isPresented: $showsNameRequiredAlert
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text("对象名称是保存记忆对象的必填信息。")
            }
            .alert(
                "无法保存",
                isPresented: Binding(
                    get: { saveFailureMessage != nil },
                    set: { if !$0 { saveFailureMessage = nil } }
                )
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text(saveFailureMessage ?? "请稍后再试。")
            }
            .accessibilityIdentifier("subject-configuration-flow")
        }
    }

    private func subjectSectionHeader(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
    }

    private var deleteSubjectRow: some View {
        Button {
            showsDeleteConfirmation = true
        } label: {
            HStack {
                Text("删除记忆对象")
                    .font(.body)
                    .foregroundStyle(.red)

                Spacer(minLength: 0)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: ConfigurationUI.minimumInteractiveHeight,
                alignment: .leading
            )
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityHint("删除对象的基础资料和时间锚点")
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif
