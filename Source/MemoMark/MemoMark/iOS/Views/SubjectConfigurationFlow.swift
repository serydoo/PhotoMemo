#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct SubjectConfigurationFlow: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    private let flowState:
        SubjectConfigurationFlowState

    private let onDeleteSubject: () -> Void
    private let onCancel: () -> Void
    private let onSave: () -> Void
    private let commerceStore: MemoMarkCommerceStore

    @State
    private var showsDeleteConfirmation = false

    @State
    private var showsNameRequiredAlert = false

    @State
    private var saveFailureMessage: String?

    @State
    private var isSaving = false

    @State
    private var showsCommercePurchase = false

    init(
        flowState: SubjectConfigurationFlowState,
        onDeleteSubject: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        commerceStore: MemoMarkCommerceStore
    ) {
        self.flowState = flowState
        self.onDeleteSubject = onDeleteSubject
        self.onCancel = onCancel
        self.onSave = onSave
        self.commerceStore = commerceStore
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        subjectSectionHeader(
                            title: localized(
                                "subject.configuration.identity.title",
                                fallback: "基础资料"
                            ),
                            subtitle: localized(
                                "subject.configuration.identity.subtitle",
                                fallback: "名字、关系和你熟悉的称呼。"
                            )
                        )

                        MemorySubjectEditorView(
                            session: flowState.draftSession,
                            mode: .identityOverview
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        subjectSectionHeader(
                            title: localized(
                                "subject.configuration.anchor.title",
                                fallback: "时间锚点"
                            ),
                            subtitle: localized(
                                "subject.configuration.anchor.subtitle",
                                fallback: "选择时间锚点，让照片拥有时间答案。"
                            )
                        )

                        SubjectAnchorDetailSection(
                            session: flowState.draftSession,
                            onPersistSubjectChanges: {},
                            allowsSwipeDeletion: true,
                            isPlusAccess: commerceStore.isPlus,
                            onRequestCommerce: requestCommerce,
                            onActivateSuggestion: activateSuggestedAnchor
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
            .toolbarBackground(
                ConfigurationUI.appBackground,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
            .navigationTitle(localized(
                "subject.configuration.navigation.title",
                fallback: "编辑记忆对象"
            ))
            .navigationBarTitleDisplayMode(.inline)
            .memoMarkEditorSheetToolbar(
                cancelTitle: localized("common.cancel", fallback: "取消"),
                doneTitle: localized("common.done", fallback: "完成"),
                doneDisabled: isSaving,
                onCancel: onCancel,
                onDone: {
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
            )
            .alert(
                localized(
                    "subject.configuration.delete.title",
                    fallback: "删除这个记忆对象？"
                ),
                isPresented: $showsDeleteConfirmation
            ) {
                Button(localized("common.cancel", fallback: "取消"), role: .cancel) {}
                Button(
                    localized(
                        "subject.configuration.delete.button",
                        fallback: "删除记忆对象"
                    ),
                    role: .destructive
                ) {
                    onDeleteSubject()
                }
            } message: {
                Text(localized(
                    "subject.configuration.delete.message",
                    fallback: "对象的基础资料和时间锚点都会被删除。此操作无法撤销。"
                ))
            }
            .alert(
                localized(
                    "subject.configuration.name_required.title",
                    fallback: "填写对象名称"
                ),
                isPresented: $showsNameRequiredAlert
            ) {
                Button(localized("common.ok", fallback: "好"), role: .cancel) {}
            } message: {
                Text(localized(
                    "subject.configuration.name_required.message",
                    fallback: "对象名称是保存记忆对象的必填信息。"
                ))
            }
            .alert(
                localized(
                    "subject.configuration.save_failed.title",
                    fallback: "无法保存"
                ),
                isPresented: Binding(
                    get: { saveFailureMessage != nil },
                    set: { if !$0 { saveFailureMessage = nil } }
                )
            ) {
                Button(localized("common.ok", fallback: "好"), role: .cancel) {}
            } message: {
                Text(
                    saveFailureMessage
                    ?? localized(
                        "subject.configuration.save_failed.message",
                        fallback: "请稍后再试。"
                    )
                )
            }
            .accessibilityIdentifier("subject-configuration-flow")
        }
        .sheet(isPresented: $showsCommercePurchase) {
            MemoMarkPlusPurchaseView(
                store: commerceStore,
                onDismiss: {
                    showsCommercePurchase = false
                }
            )
        }
    }

    private func requestCommerce() {
        showsCommercePurchase = true
    }

    private func activateSuggestedAnchor(
        _ suggestion: MemorySubject.TimeAnchor
    ) {
        guard let subject = flowState.draftSession.state.selectedSubject,
              subject.timeAnchors.count < 5,
              !subject.timeAnchors.contains(where: {
                  $0.title == suggestion.title
              }) else {
            return
        }

        var updatedSubject = subject
        updatedSubject.timeAnchors.append(suggestion)
        flowState.draftSession.updateSelectedSubject(updatedSubject)
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
                Text(localized(
                    "subject.configuration.delete.button",
                    fallback: "删除记忆对象"
                ))
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
        .accessibilityHint(localized(
            "subject.configuration.delete.hint",
            fallback: "删除对象的基础资料和时间锚点"
        ))
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func localized(
        _ key: String,
        fallback: String
    ) -> String {
        interfaceLanguage.localized(key: key, fallback: fallback)
    }
}
#endif
