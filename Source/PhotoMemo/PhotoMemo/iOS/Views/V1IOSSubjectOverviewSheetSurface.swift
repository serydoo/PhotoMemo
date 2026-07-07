#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewSheet: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subjects: [MemorySubject]

    let subject: MemorySubject?

    let selectedSubjectID: MemorySubject.ID?

    let onSelectSubject: (MemorySubject.ID) -> Void

    let onAddSubject: () -> Void

    let onDeleteCurrentSubject: () -> Void

    let onOpenEditor: () -> Void

    @State
    private var showsDeleteConfirmation = false

    @State
    private var isSwitchingSubject = false

    @State
    private var switchCandidateSubjectID: MemorySubject.ID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    V1IOSSubjectOverviewSubjectRail(
                        subjects: subjects,
                        selectedSubjectID:
                            selectedSubjectID,
                        switchCandidateSubjectID:
                            switchCandidateSubjectID,
                        isSwitchingSubject:
                            isSwitchingSubject,
                        onSelectSubject: {
                            subjectID in
                            switchCandidateSubjectID =
                                subjectID
                        },
                        onAddSubject: onAddSubject,
                        onBeginSwitch: {
                            switchCandidateSubjectID =
                                selectedSubjectID
                                ?? subject?.id
                                ?? subjects.first?.id
                            isSwitchingSubject = true
                        },
                        onCancelSwitch: {
                            switchCandidateSubjectID = nil
                            isSwitchingSubject = false
                        },
                        onCommitSwitch: {
                            guard
                                let subjectID =
                                    switchCandidateSubjectID
                            else {
                                return
                            }

                            onSelectSubject(subjectID)
                            switchCandidateSubjectID = nil
                            isSwitchingSubject = false
                        }
                    )

                    V1IOSSubjectIdentitySection(
                        presentation:
                            presentation,
                        subject: subject
                    )

                    V1IOSSubjectOverviewFooter(
                        onOpenEditor: onOpenEditor
                    )
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("记忆对象")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if subjects.count > 1 {
                        Button(
                            "删除",
                            role: .destructive
                        ) {
                            showsDeleteConfirmation = true
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onAddSubject) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增记忆对象")
                }
            }
            .confirmationDialog(
                "删除这个记忆对象？",
                isPresented:
                    $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "删除当前对象",
                    role: .destructive
                ) {
                    onDeleteCurrentSubject()
                }

                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后会立即切换到仍然保留的记忆对象，并同步首页记忆对象。")
            }
        }
        .onChange(of: selectedSubjectID) { _, newValue in
            guard !isSwitchingSubject else {
                return
            }

            switchCandidateSubjectID = newValue
        }
    }
}
#endif
