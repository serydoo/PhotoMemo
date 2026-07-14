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

        NavigationStack {
            Form {
                Section {
                    heroHeader
                }

                Section(stepTitle) {
                    stepProgress
                    stepBody
                }

                Section {
                    footerActions
                }
            }
            .formStyle(.grouped)
            .navigationTitle("时光记")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .animation(.default, value: step)
        }
    }
}

private extension FirstRunWizardView {

    var heroHeader: some View {

        VStack(alignment: .leading) {
            Text("欢迎使用时光记")
                .font(.title)
                .fontWeight(.semibold)

            Text("我们只需要花 1 分钟完成设置，以后就可以一直使用。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }

    var stepProgress: some View {

        VStack(alignment: .leading) {
            Text(progressTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(
                value: Double(step.rawValue + 1),
                total: Double(Step.allCases.count)
            )
            .tint(.accentColor)
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

        VStack(alignment: .leading) {
            Text("欢迎来到时光记")
                .font(.headline)

            Text("把宝宝照片变成值得长期保存的成长记录。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Text("现在完成一次设定，以后就可以在系统相册中直接分享使用。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }

    var relationshipStep: some View {

        VStack(alignment: .leading) {
            Text("这是为谁记录？")
                .font(.headline)

            Text("以后时光记会用这个称呼来生成记忆内容。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Picker(
                "你的身份",
                selection: $draftProfile.relationshipRole
            ) {
                ForEach(
                    PersonalRelationshipRole.allCases,
                    id: \.self
                ) { role in
                    Text(role.title)
                        .tag(role)
                }
            }
            .pickerStyle(.inline)

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

        VStack(alignment: .leading) {
            Text("宝宝叫什么？")
                .font(.headline)

            Text("以后会直接使用这个昵称，不再反复询问。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            TextField(
                "宝宝昵称",
                text: $draftProfile.babyNickname
            )
            .textFieldStyle(.roundedBorder)

            Text("例如：小宝、宝贝儿、安安")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    var birthdayStep: some View {

        VStack(alignment: .leading) {
            Text("出生日期")
                .font(.headline)

            Text("时光记将自动计算每张照片拍摄时的年龄。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

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

        VStack(alignment: .leading) {
            Text("保存位置")
                .font(.headline)

            Text("以后处理完成后，会默认保存到这里。")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Picker(
                "默认保存位置",
                selection: $draftProfile.defaultSaveDestination
            ) {
                Text("系统相册")
                    .tag(PersonalProfileSaveDestination.systemLibrary)
                Text("时光记相册（推荐）")
                    .tag(PersonalProfileSaveDestination.photoMemoAlbum)
            }
            .pickerStyle(.inline)
            .onChange(
                of: draftProfile.defaultSaveDestination
            ) { _, _ in
                clearSelectedAlbum()
            }

            LabeledContent(
                "记录身份",
                value: draftProfile.resolvedRelationshipLabel
            )

            LabeledContent(
                "宝宝昵称",
                value: normalizedNicknameSummary
            )

            LabeledContent(
                "默认风格",
                value: PersonalProfile.recommendedStyleTitle
            )

            Text("设置完成后，日常只需要在系统相册里分享照片到时光记。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }

    var footerActions: some View {

        HStack {
            if showsBackButton {
                Button("上一步") {
                    withAnimation {
                        moveBackward()
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer(minLength: 0)

            Button(primaryButtonTitle) {
                withAnimation {
                    advance()
                }
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

    func clearSelectedAlbum() {
        draftProfile.selectedAlbumIdentifier = ""
        draftProfile.selectedAlbumTitle = ""
    }
}
#endif
