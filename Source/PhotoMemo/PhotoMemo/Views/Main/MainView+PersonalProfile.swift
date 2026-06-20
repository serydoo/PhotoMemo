#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct MainPersonalProfileSectionView: View {

    let profile: PersonalProfile

    let saveDestinationSummary: String

    let onUpdateProfile: (PersonalProfile) -> Void

    @State
    private var draftProfile: PersonalProfile

    @State
    private var birthday: Date

    init(
        profile: PersonalProfile,
        saveDestinationSummary: String,
        onUpdateProfile: @escaping (PersonalProfile) -> Void
    ) {
        self.profile = profile
        self.saveDestinationSummary =
            saveDestinationSummary
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

            Text("这些信息只需要认真设定一次，之后分享照片时会自动沿用。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            profileSummaryCard

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

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

    private var profileSummaryCard: some View {

        MinimalInsetCard {
            summaryRow(
                title: "记录身份",
                value:
                    draftProfile
                    .resolvedRelationshipLabel
            )

            Divider()

            summaryRow(
                title: "宝宝昵称",
                value: nicknameSummary
            )

            Divider()

            summaryRow(
                title: "出生日期",
                value: birthdaySummary
            )
        }
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

    private var birthdaySummary: String {
        birthday.formatted(date: .abbreviated, time: .omitted)
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
}
#endif
