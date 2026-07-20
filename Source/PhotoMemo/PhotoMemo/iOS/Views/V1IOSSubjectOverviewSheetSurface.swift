#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1IOSSubjectOverviewSheet: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subjects: [MemorySubject]

    let subject: MemorySubject?

    @ObservedObject
    var session: ConfigurationSession

    let selectedSubjectID: MemorySubject.ID?

    let onSelectSubject: (MemorySubject.ID) -> Void

    let onAddSubject: () -> Void

    let onDeleteCurrentSubject: () -> Void

    let onPersistSubjectChanges: () -> Void

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
                        onSaveSubject:
                            onPersistSubjectChanges,
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

                    basicInfoSection

                    V1IOSSubjectAnchorSection(
                        presentation: presentation,
                        subject: subject
                    )
                }
                .padding(.top, 16)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
                    horizontalPadding: 18
                )
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
        .onDisappear {
            onPersistSubjectChanges()
        }
        .onChange(of: selectedSubjectID) { _, newValue in
            guard !isSwitchingSubject else {
                return
            }

            switchCandidateSubjectID = newValue
        }
    }

    private var basicInfoSection: some View {
        V1ConfigurationCardContainer {
            basicInfoInnerPanel
        }
    }

    private var basicInfoInnerPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            MemorySubjectEditorView(
                session: session,
                mode: .identityOverview
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)

            Divider()
                .padding(.vertical, 10)

            timeAnchorNavigationRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var timeAnchorNavigationRow: some View {
        NavigationLink {
            timeAnchorConfigurationPage
        } label: {
            HStack(spacing: 10) {
                Text("时间锚点配置")
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                Text(
                    "已设定锚点数 \(subject?.timeAnchors.count ?? 0) 个"
                )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .font(.body)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var timeAnchorConfigurationPage: some View {
        MemorySubjectEditorView(
            session: session,
            mode: .timeAnchors
        )
        .scrollDismissesKeyboard(.interactively)
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle("时间锚点配置")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
