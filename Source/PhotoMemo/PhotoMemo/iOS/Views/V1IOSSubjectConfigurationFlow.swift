#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1IOSSubjectConfigurationFlow: View {

    private let flowState:
        V1IOSSubjectConfigurationFlowState

    private let onClose: () -> Void
    init(
        flowState: V1IOSSubjectConfigurationFlowState,
        onClose: @escaping () -> Void
    ) {
        self.flowState = flowState
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    V1IOSSubjectOverviewCard(
                        presentation: overviewPresentation
                    )

                    V1CardSurface(title: "基本资料") {
                        Text("以下信息会作为当前记忆对象的长期身份资料，并同步影响时间锚点与记忆卡预览。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                            .padding(.bottom, 8)

                        MemorySubjectEditorView(
                            session: flowState.draftSession
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 34)
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
            .navigationTitle("记忆对象配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("返回") {
                        onClose()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        flowState.saveChanges()
                        onClose()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private var overviewPresentation:
        V1IOSSubjectOverviewPresentation {
        V1IOSSubjectOverviewPresenter.presentation(
            subject: flowState.draftSession.state.selectedSubject,
            currentTimeAnchorTitle:
                flowState.draftSession.currentTimeAnchorTitle,
            currentTimeAnchorDescription:
                flowState.draftSession.currentTimeAnchorDescription
        )
    }
}
#endif
