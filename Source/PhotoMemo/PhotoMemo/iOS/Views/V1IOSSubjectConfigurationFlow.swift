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
                    subjectConfigurationIntro

                    MemorySubjectEditorView(
                        session: flowState.draftSession
                    )
                }
                .padding(.top, 16)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
                    horizontalPadding: 18
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

    private var subjectConfigurationIntro: some View {
        V1CardSurface(title: "记忆对象配置") {
            Text("这里专门维护对象头像、名称、关系与时间锚点。当前生效锚点切换已经收拢到配置中心摘要区，这里只负责对象本身的长期资料与锚点内容。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
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
}
#endif
