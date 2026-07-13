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
        VStack(alignment: .leading, spacing: 14) {
            MemorySubjectEditorView(
                session: session,
                mode: .identityOverview
            ) {
                basicInfoNavigationTabs
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .v1CardChrome()
    }

    private var basicInfoNavigationTabs: some View {
        HStack(spacing: 8) {
            Label(
                "基本资料",
                systemImage: "person.text.rectangle"
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .fill(Color.accentColor.opacity(0.10))
            )

            NavigationLink {
                timeAnchorConfigurationPage
            } label: {
                Label(
                    "锚点维护",
                    systemImage: "calendar.badge.clock"
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .fill(ConfigurationUI.controlBackground.opacity(0.72))
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .stroke(ConfigurationUI.faintHairline)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
    }

    private var timeAnchorConfigurationPage: some View {
        ScrollView {
            VStack(spacing: 14) {
                V1CardSurface(title: "锚点维护") {
                    MemorySubjectEditorView(
                        session: session,
                        mode: .timeAnchors
                    )
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 34)
            .v1AdaptiveScrollContent(
                horizontalPadding: 18
            )
        }
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
