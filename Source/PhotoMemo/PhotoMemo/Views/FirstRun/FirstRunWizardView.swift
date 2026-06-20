import SwiftUI

#if !PHOTOMEMO_SHARE_EXTENSION
struct FirstRunWizardView: View {

    private enum Step: Int, CaseIterable {

        case welcome

        case relationship

        case nickname

        case birthday

        case destination
    }

    @State
    private var step: Step = .welcome

    @State
    private var draftProfile: PersonalProfile

    @State
    private var birthday: Date

    let onComplete: (PersonalProfile) -> Void

    init(
        initialProfile: PersonalProfile,
        onComplete: @escaping (PersonalProfile) -> Void
    ) {
        let normalizedProfile =
            initialProfile.normalized

        self._draftProfile =
            State(initialValue: normalizedProfile)
        self._birthday =
            State(
                initialValue:
                    normalizedProfile.babyBirthday
                    ?? Date()
            )
        self.onComplete = onComplete
    }

    var body: some View {

        ZStack {
            MinimalPalette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 24
                ) {
                    heroHeader

                    GroupBox {
                        VStack(
                            alignment: .leading,
                            spacing: 18
                        ) {
                            stepProgress
                            stepBody
                        }
                    } label: {
                        Text(stepTitle)
                    }
                    .groupBoxStyle(
                        MinimalCardGroupBoxStyle()
                    )

                    footerActions
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private extension FirstRunWizardView {

    var heroHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("欢迎使用 PhotoMemo")
                .font(.system(size: 32, weight: .bold))

            Text("我们只需要花 1 分钟完成设置，以后就可以一直使用。")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    var stepProgress: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text(progressTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(MinimalPalette.accent)

            ProgressView(
                value: Double(step.rawValue + 1),
                total: Double(Step.allCases.count)
            )
            .tint(MinimalPalette.accent)
        }
    }

    @ViewBuilder
    var stepBody: some View {

        switch step {

        case .welcome:
            welcomeStep

        case .relationship:
            relationshipStep

        case .nickname:
            nicknameStep

        case .birthday:
            birthdayStep

        case .destination:
            destinationStep
        }
    }

    var welcomeStep: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("欢迎来到 PhotoMemo")
                .font(.title3.weight(.semibold))

            Text("把宝宝照片变成值得长期保存的成长记录。")
                .font(.body)
                .foregroundStyle(.secondary)

            MinimalInsetCard {
                Text("现在花 1 分钟完成设置，以后就可以一直在系统相册中直接分享使用。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
    }

    var relationshipStep: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("这是为谁记录？")
                .font(.title3.weight(.semibold))

            Text("以后 PhotoMemo 会用这个称呼来生成记忆内容。")
                .font(.body)
                .foregroundStyle(.secondary)

            ForEach(
                PersonalRelationshipRole.allCases,
                id: \.self
            ) { role in
                selectionRow(
                    title: role.title,
                    subtitle: relationshipSubtitle(
                        for: role
                    ),
                    isSelected:
                        draftProfile.relationshipRole
                        == role
                ) {
                    draftProfile.relationshipRole =
                        role
                }
            }

            if draftProfile.relationshipRole == .custom {
                TextField(
                    "例如：爷爷",
                    text:
                        $draftProfile
                        .customRelationshipLabel
                )
                .textFieldStyle(.roundedBorder)
            }
        }
    }

    var nicknameStep: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("宝宝叫什么？")
                .font(.title3.weight(.semibold))

            Text("以后会直接使用这个昵称，不再反复询问。")
                .font(.body)
                .foregroundStyle(.secondary)

            TextField(
                "宝宝昵称",
                text: $draftProfile.babyNickname
            )
            .textFieldStyle(.roundedBorder)

            MinimalInsetCard {
                Text("例如：小满、可乐、糖糖")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var birthdayStep: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("出生日期")
                .font(.title3.weight(.semibold))

            Text("PhotoMemo 将自动计算每张照片拍摄时的年龄。")
                .font(.body)
                .foregroundStyle(.secondary)

            DatePicker(
                "出生日期",
                selection: $birthday,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
        }
    }

    var destinationStep: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("保存位置")
                .font(.title3.weight(.semibold))

            Text("以后处理完成后，会默认保存到这里。")
                .font(.body)
                .foregroundStyle(.secondary)

            MinimalInsetCard {
                Text("设置完成后，日常只需要在系统相册里分享照片到 PhotoMemo。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Divider()

                summaryRow(
                    title: "记录身份",
                    value: draftProfile.resolvedRelationshipLabel
                )
                summaryRow(
                    title: "宝宝昵称",
                    value: normalizedNicknameSummary
                )
                summaryRow(
                    title: "默认风格",
                    value: PersonalProfile.recommendedStyleTitle
                )
            }

            selectionRow(
                title: "系统相册",
                subtitle: "直接写回系统图库，不额外放进某个相册。",
                isSelected:
                    draftProfile.defaultSaveDestination
                    == .systemLibrary
            ) {
                draftProfile.defaultSaveDestination =
                    .systemLibrary
                draftProfile.selectedAlbumIdentifier = ""
                draftProfile.selectedAlbumTitle = ""
            }

            selectionRow(
                title: "PhotoMemo 相册（推荐）",
                subtitle: "自动创建或复用 PhotoMemo 相册，方便集中查看生成结果。",
                isSelected:
                    draftProfile.defaultSaveDestination
                    == .photoMemoAlbum
            ) {
                draftProfile.defaultSaveDestination =
                    .photoMemoAlbum
                draftProfile.selectedAlbumIdentifier = ""
                draftProfile.selectedAlbumTitle = ""
            }
        }
    }

    var footerActions: some View {

        HStack(spacing: 12) {
            if showsBackButton {
                Button("上一步") {
                    moveBackward()
                }
                .buttonStyle(.bordered)
            }

            Spacer(minLength: 0)

            Button(primaryButtonTitle) {
                advance()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdvance)
        }
    }

    var showsBackButton: Bool {
        step != .welcome
    }

    var stepTitle: String {

        switch step {

        case .welcome:
            return "1 / 5"

        case .relationship:
            return "2 / 5"

        case .nickname:
            return "3 / 5"

        case .birthday:
            return "4 / 5"

        case .destination:
            return "5 / 5"
        }
    }

    var progressTitle: String {
        "首次设置"
    }

    var primaryButtonTitle: String {

        switch step {

        case .welcome:
            return "继续"

        case .destination:
            return "立即体验"

        default:
            return "继续"
        }
    }

    var canAdvance: Bool {

        switch step {

        case .welcome:
            return true

        case .relationship:
            if draftProfile.relationshipRole == .custom {
                return !draftProfile
                    .customRelationshipLabel
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
            }

            return true

        case .nickname:
            return !draftProfile
                .babyNickname
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty

        case .birthday,
             .destination:
            return true
        }
    }

    var normalizedNicknameSummary: String {

        let trimmed =
            draftProfile.babyNickname
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? "未填写"
            : trimmed
    }

    func relationshipSubtitle(
        for role: PersonalRelationshipRole
    ) -> String {

        switch role {

        case .mother:
            return "以后会显示为“妈妈记录”。"

        case .father:
            return "以后会显示为“爸爸记录”。"

        case .familyMember:
            return "适合统一使用“家人记录”。"

        case .custom:
            return "例如：爷爷、奶奶、舅舅。"
        }
    }

    func selectionRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            HStack(
                alignment: .top,
                spacing: 14
            ) {
                Image(
                    systemName:
                        isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(
                    isSelected
                    ? MinimalPalette.accent
                    : .secondary
                )

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    isSelected
                    ? MinimalPalette.accent.opacity(0.38)
                    : MinimalPalette.border,
                    lineWidth: isSelected ? 1.5 : 1
                )
            )
        }
        .buttonStyle(.plain)
    }

    func summaryRow(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    func moveBackward() {

        guard let previousStep =
            Step(rawValue: step.rawValue - 1)
        else {
            return
        }

        step = previousStep
    }

    func advance() {

        draftProfile.babyBirthday = birthday
        draftProfile.defaultStyleIdentifier = "slot1"

        if step == .destination {
            onComplete(
                draftProfile.normalized
            )
            return
        }

        guard let nextStep =
            Step(rawValue: step.rawValue + 1)
        else {
            return
        }

        step = nextStep
    }
}
#endif
