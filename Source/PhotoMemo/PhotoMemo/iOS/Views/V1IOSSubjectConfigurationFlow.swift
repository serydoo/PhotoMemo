#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1IOSSubjectConfigurationFlow: View {

    private let flowState:
        V1IOSSubjectConfigurationFlowState

    private let onDeleteSubject: () -> Void
    private let onCancel: () -> Void
    private let onSave: () -> Void

    @State
    private var showsDeleteConfirmation = false

    @State
    private var showsNameRequiredAlert = false

    init(
        flowState: V1IOSSubjectConfigurationFlowState,
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
                VStack(spacing: 14) {
                    V1TitledSectionSurface(
                        title: "基础资料",
                        subtitle: "编辑对象身份与关系信息"
                    ) {
                        MemorySubjectEditorView(
                            session: flowState.draftSession,
                            mode: .identityOverview
                        )
                    }

                    V1TitledSectionSurface(
                        title: "时间锚点",
                        subtitle: "维护与这个对象有关的重要时刻。"
                    ) {
                        V1IOSSubjectAnchorDetailSection(
                            session: flowState.draftSession,
                            subject: flowState.draftSession.state.selectedSubject,
                            onPersistSubjectChanges: {},
                            allowsSwipeDeletion: true
                        )
                    }

                    deleteSubjectRow
                }
                .padding(.top, 12)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
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
                        guard flowState.saveChanges() else {
                            showsNameRequiredAlert = true
                            return
                        }
                        onSave()
                    }
                    .fontWeight(.semibold)
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
        }
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
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .contentShape(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.cornerRadius,
                style: .continuous
            )
        )
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
