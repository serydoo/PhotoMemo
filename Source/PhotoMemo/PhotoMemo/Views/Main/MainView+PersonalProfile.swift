#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MainSubjectSectionView: View {

    let profile: PersonalProfile

    let anchors: [Anchor]

    @Binding
    var selectedAnchorID: Anchor.ID?

    let selectedAnchorTitle: String?

    let selectedAnchorDateText: String?

    let anchorQuickFacts: [MainAnchorQuickFact]

    let saveDestinationSummary: String

    let onPresentAnchorManager: () -> Void

    let onUpdateProfile: (PersonalProfile) -> Void

    @State
    private var draftProfile: PersonalProfile

    @State
    private var birthday: Date

    init(
        profile: PersonalProfile,
        anchors: [Anchor],
        selectedAnchorID: Binding<Anchor.ID?>,
        selectedAnchorTitle: String?,
        selectedAnchorDateText: String?,
        anchorQuickFacts: [MainAnchorQuickFact],
        saveDestinationSummary: String,
        onPresentAnchorManager: @escaping () -> Void,
        onUpdateProfile: @escaping (PersonalProfile) -> Void
    ) {
        self.profile = profile
        self.anchors = anchors
        self._selectedAnchorID = selectedAnchorID
        self.selectedAnchorTitle =
            selectedAnchorTitle
        self.selectedAnchorDateText =
            selectedAnchorDateText
        self.anchorQuickFacts =
            anchorQuickFacts
        self.saveDestinationSummary =
            saveDestinationSummary
        self.onPresentAnchorManager =
            onPresentAnchorManager
        self.onUpdateProfile =
            onUpdateProfile
        self._draftProfile =
            State(initialValue: profile.normalized)
        self._birthday =
            State(
                initialValue:
                    profile.babyBirthday
                    ?? Date()
            )
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text("记忆对象会决定这张记忆卡在讲述谁、围绕哪个时间锚点展开。这里稳定设定一次，之后分享照片时会自动沿用。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            subjectOverviewCard

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                subjectSubsectionHeader(
                    title: "基本资料",
                    summary: "先确认主角身份、称呼和默认保存习惯。"
                )

                Picker(
                    "你的身份",
                    selection:
                        $draftProfile.relationshipRole
                ) {

                    ForEach(
                        PersonalRelationshipRole
                        .allCases,
                        id: \.self
                    ) { role in

                        Text(role.title)
                            .tag(role)
                    }
                }
                .pickerStyle(.segmented)

                if draftProfile.relationshipRole == .custom {
                    TextField(
                        "例如：爷爷",
                        text:
                            $draftProfile
                            .customRelationshipLabel
                    )
                    .textFieldStyle(.roundedBorder)
                }

                TextField(
                    "宝宝昵称",
                    text: $draftProfile.babyNickname
                )
                .textFieldStyle(.roundedBorder)

                DatePicker(
                    "出生日期",
                    selection: $birthday,
                    displayedComponents: .date
                )

                LabeledContent("默认风格") {
                    Text(
                        PersonalProfile
                        .recommendedStyleTitle
                    )
                    .foregroundStyle(.secondary)
                }

                LabeledContent("默认保存位置") {
                    Text(saveDestinationSummary)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                subjectSubsectionHeader(
                    title: "时间锚点",
                    summary: "这里维护长期时间参照；后续在编辑和生成阶段都会沿用当前选择。"
                )

                MainSubjectAnchorSectionView(
                    anchors: anchors,
                    selectedAnchorID:
                        $selectedAnchorID,
                    selectedAnchorTitle:
                        selectedAnchorTitle,
                    selectedAnchorDateText:
                        selectedAnchorDateText,
                    anchorQuickFacts:
                        anchorQuickFacts,
                    onPresentAnchorManager:
                        onPresentAnchorManager
                )
            }
        }
        .onAppear(
            perform: syncDraftWithProfile
        )
        .onChange(of: profile) { _, _ in
            syncDraftWithProfile()
        }
        .onChange(of: draftProfile.relationshipRole) {
            _, _ in
            persistDraft()
        }
        .onChange(
            of: draftProfile.customRelationshipLabel
        ) { _, _ in
            persistDraft()
        }
        .onChange(of: draftProfile.babyNickname) { _, _ in
            persistDraft()
        }
        .onChange(of: birthday) { _, _ in
            persistDraft()
        }
    }

    private var subjectOverviewCard: some View {

        MinimalInsetCard {
            summaryRow(
                title: "当前记忆对象",
                value: subjectNameSummary
            )

            Divider()

            summaryRow(
                title: "记录身份",
                value:
                    draftProfile
                    .resolvedRelationshipLabel
            )

            Divider()

            summaryRow(
                title: "当前时间锚点",
                value: selectedAnchorSummary
            )

            Divider()

            summaryRow(
                title: "默认保存位置",
                value: saveDestinationSummary
            )
        }
    }

    private var subjectNameSummary: String {
        nicknameSummary == "未填写"
            ? "未命名记忆对象"
            : nicknameSummary
    }

    private var nicknameSummary: String {

        let trimmed =
            draftProfile.babyNickname
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? "未填写"
            : trimmed
    }

    private var selectedAnchorSummary: String {

        guard let selectedAnchorTitle else {
            return "未设置"
        }

        let trimmed =
            selectedAnchorTitle
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? "未设置"
            : trimmed
    }

    private func summaryRow(
        title: String,
        value: String
    ) -> some View {

        LabeledContent(title) {
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }

    private func syncDraftWithProfile() {

        draftProfile =
            profile.normalized
        birthday =
            profile.babyBirthday
            ?? Date()
    }

    private func persistDraft() {

        draftProfile.babyBirthday =
            birthday
        onUpdateProfile(draftProfile.normalized)
    }

    private func subjectSubsectionHeader(
        title: String,
        summary: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }
}

private struct MainSubjectAnchorSectionView: View {

    let anchors: [Anchor]

    @Binding
    var selectedAnchorID: Anchor.ID?

    let selectedAnchorTitle: String?

    let selectedAnchorDateText: String?

    let anchorQuickFacts: [MainAnchorQuickFact]

    let onPresentAnchorManager: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(spacing: 10) {
                Picker(
                    "当前时间锚点",
                    selection: $selectedAnchorID
                ) {

                    Text("未选择")
                        .tag(Optional<Anchor.ID>.none)

                    ForEach(anchors) { anchor in

                        Text(anchor.title)
                            .tag(Optional(anchor.id))
                    }
                }
                .pickerStyle(.menu)
                .controlSize(.small)

                Button(action: onPresentAnchorManager) {
                    Label(
                        "管理锚点",
                        systemImage: "calendar.badge.plus"
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            MinimalInsetCard {
                subjectAnchorRow(
                    title: "当前锚点",
                    value: selectedAnchorDisplayTitle
                )

                Divider()

                subjectAnchorRow(
                    title: "记忆日期",
                    value: selectedAnchorDateText
                    ?? "未设置"
                )
            }

            if !anchorQuickFacts.isEmpty {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(
                                minimum: 120
                            ),
                            spacing: 8
                        )
                    ],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(anchorQuickFacts) { fact in
                        MainSubjectAnchorFactView(
                            title: fact.label,
                            value: fact.value
                        )
                    }
                }
            }
        }
    }

    private var selectedAnchorDisplayTitle: String {

        guard let selectedAnchorTitle else {
            return "未设置"
        }

        let trimmed =
            selectedAnchorTitle
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? "未设置"
            : trimmed
    }

    private func subjectAnchorRow(
        title: String,
        value: String
    ) -> some View {

        LabeledContent(title) {
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

private struct MainSubjectAnchorFactView: View {

    let title: String

    let value: String

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(MinimalPalette.border)
        )
    }
}
#endif
