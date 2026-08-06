#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1WelcomePresentation: Equatable {

    struct Feature:
        Equatable,
        Identifiable {

        let id: String
        let title: String
        let detail: String
        let systemImage: String
    }

    struct WorkflowStep:
        Equatable,
        Identifiable {

        let id: String
        let title: String
        let detail: String
        let systemImage: String
    }

    let title: String
    let subtitle: String
    let message: String
    let features: [Feature]
    let workflowSteps: [WorkflowStep]
    let primaryActionTitle: String
    let secondaryActionTitle: String

    static let `default` =
        V1WelcomePresentation(
            title: "时光记",
            subtitle: "让照片记得，它在人生里的位置。",
            message: "时光记会把照片里的时间，和你选择的人、重要时刻放在一起，留下更容易读懂的回忆；原图保持不变。",
            features: [
                .init(
                    id: "local-first",
                    title: "本地优先",
                    detail: "照片处理留在你的设备中，不上传原始内容。",
                    systemImage: "internaldrive.fill"
                ),
                .init(
                    id: "keep-original",
                    title: "保留原图",
                    detail: "生成新图输出，不改动系统相册里的原始照片。",
                    systemImage: MemoMarkSymbol.originalPhoto.name
                ),
                .init(
                    id: "time-anchor",
                    title: "时间锚点",
                    detail: "让照片知道，它处在人生里的哪个时刻。",
                    systemImage: MemoMarkSymbol.timeAnchor.name
                ),
                .init(
                    id: "configure-once",
                    title: "一次设好，之后继续记录",
                    detail: "记忆对象、时间锚点和保存方式设好后，以后每次记录都会更轻松。",
                    systemImage: "checkmark.seal.fill"
                )
            ],
            workflowSteps: workflowSteps(for: .simplifiedChinese),
            primaryActionTitle: "开始使用",
            secondaryActionTitle: "查看使用流程"
        )

    static func localized(
        for language: MemoMarkLanguage
    ) -> Self {
        V1WelcomePresentation(
            title: language.localized(
                key: "welcome.title",
                fallback: "时光记"
            ),
            subtitle: language.localized(
                key: "welcome.subtitle",
                fallback: "让照片记得，它在人生里的位置。"
            ),
            message: language.localized(
                key: "welcome.message",
                fallback: "时光记会把照片里的时间，和你选择的人、重要时刻放在一起，留下更容易读懂的回忆；原图保持不变。"
            ),
            features: [
                .init(
                    id: "local-first",
                    title: language.localized(
                        key: "welcome.feature.local_first.title",
                        fallback: "本地优先"
                    ),
                    detail: language.localized(
                        key: "welcome.feature.local_first.detail",
                        fallback: "照片处理留在你的设备中，不上传原始内容。"
                    ),
                    systemImage: "internaldrive.fill"
                ),
                .init(
                    id: "keep-original",
                    title: language.localized(
                        key: "welcome.feature.original.title",
                        fallback: "保留原图"
                    ),
                    detail: language.localized(
                        key: "welcome.feature.original.detail",
                        fallback: "生成新图输出，不改动系统相册里的原始照片。"
                    ),
                    systemImage: MemoMarkSymbol.originalPhoto.name
                ),
                .init(
                    id: "time-anchor",
                    title: language.localized(
                        key: "welcome.feature.anchor.title",
                        fallback: "时间锚点"
                    ),
                    detail: language.localized(
                        key: "welcome.feature.anchor.detail",
                        fallback: "让照片知道，它处在人生里的哪个时刻。"
                    ),
                    systemImage: MemoMarkSymbol.timeAnchor.name
                ),
                .init(
                    id: "configure-once",
                    title: language.localized(
                        key: "welcome.feature.configure.title",
                        fallback: "一次设好，之后继续记录"
                    ),
                    detail: language.localized(
                        key: "welcome.feature.configure.detail",
                        fallback: "记忆对象、时间锚点和保存方式设好后，以后每次记录都会更轻松。"
                    ),
                    systemImage: "checkmark.seal.fill"
                )
            ],
            workflowSteps: workflowSteps(for: language),
            primaryActionTitle: language.localized(
                key: "welcome.primary_action",
                fallback: "开始使用"
            ),
            secondaryActionTitle: language.localized(
                key: "welcome.secondary_action",
                fallback: "查看使用流程"
            )
        )
    }

    static func workflowSteps(
        for language: MemoMarkLanguage
    ) -> [WorkflowStep] {
        [
            .init(
                id: "photos",
                title: language.localized(
                    key: "welcome.workflow.photos.title",
                    fallback: "在 Apple Photos 选择照片"
                ),
                detail: language.localized(
                    key: "welcome.workflow.photos.detail",
                    fallback: "从系统相册里找到想记录的照片。"
                ),
                systemImage: "photo.on.rectangle.angled"
            ),
            .init(
                id: "share",
                title: language.localized(
                    key: "welcome.workflow.share.title",
                    fallback: "分享给时光记"
                ),
                detail: language.localized(
                    key: "welcome.workflow.share.detail",
                    fallback: "也可以直接在首页选择照片。"
                ),
                systemImage: "square.and.arrow.up"
            ),
            .init(
                id: "processing",
                title: language.localized(
                    key: "welcome.workflow.processing.title",
                    fallback: "时光记在后台整理"
                ),
                detail: language.localized(
                    key: "welcome.workflow.processing.detail",
                    fallback: "它会按你保存的预设，完成这次记录。"
                ),
                systemImage: "arrow.trianglehead.2.clockwise.circle"
            ),
            .init(
                id: "return",
                title: language.localized(
                    key: "welcome.workflow.return.title",
                    fallback: "回到相册"
                ),
                detail: language.localized(
                    key: "welcome.workflow.return.detail",
                    fallback: "完成后，新的照片会保存回 Apple Photos。"
                ),
                systemImage: "checkmark.circle.fill"
            )
        ]
    }
}

#if os(iOS)
struct V1WelcomePageSurface: View {

    let presentation: V1WelcomePresentation
    let language: MemoMarkLanguage
    let onStart: () -> Void
    let onShowWorkflow: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    V1WelcomeHeroSection(
                        presentation: presentation,
                        language: language
                    )

                    V1CardSurface(
                        title: language.localized(
                            key: "welcome.introduction.title",
                            fallback: "开始前，先认识这几件事"
                        ),
                        systemImage: MemoMarkSymbol.welcome.name,
                        tint: .orange
                    ) {
                        Text(presentation.message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(presentation.features) { feature in
                            V1WelcomeFeatureRow(feature: feature)
                        }
                    }

                    V1CardSurface(
                        title: language.localized(
                            key: "welcome.workflow.title",
                            fallback: "日常这样记录"
                        ),
                        systemImage: MemoMarkSymbol.workflow.name,
                        tint: .purple
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(
                                language.localized(
                                    key: "welcome.workflow.pipeline",
                                    fallback: "Apple Photos -> 分享 -> 时光记 -> 处理 -> Apple Photos"
                                )
                            )
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            LazyVStack(spacing: 10) {
                                ForEach(
                                    Array(
                                        presentation.workflowSteps.prefix(3)
                                            .enumerated()
                                    ),
                                    id: \.offset
                                ) { index, step in
                                    V1WelcomeWorkflowPreviewRow(
                                        step: step,
                                        showsDivider: index != 2
                                    )
                                }
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        Button(action: onStart) {
                            Text(presentation.primaryActionTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        Button(action: onShowWorkflow) {
                            Text(presentation.secondaryActionTitle)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
                    horizontalPadding: 22
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle(
                language.localized(
                    key: "welcome.navigation_title",
                    fallback: "欢迎"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct V1FirstRunConfigurationSheet: View {

    @State private var subjectName = ""
    @State private var birthday = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showsNameRequiredAlert = false

    let onSave: (String, Date) async -> Bool
    let onDefer: () -> Void

    private var isFirstRunConfigurationReady: Bool {
        hasValidSubjectName && birthday <= Date()
    }

    private var hasValidSubjectName: Bool {
        !subjectName.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.blue)

                        Text("从一个人和一个重要时刻开始。")
                            .font(.title2.weight(.semibold))

                        Text("告诉时光记这段回忆围绕谁，以及哪个重要日子最重要。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    TextField(
                        "例如：小宝、妈妈、团团",
                        text: $subjectName
                    )
                    .accessibilityLabel("对象名称，必填")
                    .textInputAutocapitalization(.never)

                    Text("这个名字会陪着这段回忆一起被记住。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    HStack(spacing: 2) {
                        Text("对象名称")
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }

                Section("重要日期") {
                    DatePicker(
                        "选择日期",
                        selection: $birthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    LabeledContent("时间锚点", value: "生日")
                    LabeledContent("表达语气", value: "自然")
                }

                Section("接下来会发生") {
                    Label(
                        "按这个重要时刻呈现时间变化",
                        systemImage: "rectangle.and.text.magnifyingglass"
                    )
                    Label(
                        "自动保存到 Apple Photos",
                        systemImage: "photo.on.rectangle"
                    )
                    Label(
                        "保留原图，另存一张新照片",
                        systemImage: "photo.stack"
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        save()
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                            }
                            Text(isSaving ? "正在保存" : "完成设置")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("首次配置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("稍后设置", action: onDefer)
                        .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .alert(
                "填写对象名称",
                isPresented: $showsNameRequiredAlert
            ) {
                Button("好", role: .cancel) {}
            } message: {
                Text("对象名称是完成首次配置的必填信息。")
            }
        }
    }

    private func save() {
        guard hasValidSubjectName else {
            showsNameRequiredAlert = true
            return
        }

        guard isFirstRunConfigurationReady else {
            errorMessage = "请选择有效的重要日期。"
            return
        }

        isSaving = true
        errorMessage = nil
        Task {
            let succeeded = await onSave(subjectName, birthday)
            await MainActor.run {
                isSaving = false
                if !succeeded {
                    errorMessage = "配置没有保存成功，请稍后重试。"
                }
            }
        }
    }
}

struct V1WorkflowGuideSurface: View {

    let steps: [V1WelcomePresentation.WorkflowStep]
    let language: MemoMarkLanguage
    let onClose: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    V1CardSurface(
                        title: language.localized(
                            key: "welcome.workflow.title",
                            fallback: "日常这样记录"
                        ),
                        systemImage: MemoMarkSymbol.workflow.name,
                        tint: .purple
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(
                                language.localized(
                                    key: "welcome.workflow.introduction",
                                    fallback: "日常记录从 Apple Photos 开始：选择照片，分享给时光记，完成后再回到相册查看。"
                                )
                            )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            VStack(spacing: 12) {
                                ForEach(steps) { step in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: step.systemImage)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.blue)
                                            .frame(width: 22, height: 22)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(step.title)
                                                .font(.subheadline.weight(.semibold))

                                            Text(step.detail)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }

                                        Spacer(minLength: 0)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 34)
                .v1AdaptiveScrollContent(
                    horizontalPadding: ConfigurationUI.contentColumnPadding
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle(
                language.localized(
                    key: "welcome.workflow.navigation_title",
                    fallback: "怎么记录"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(
                            language.localized(
                                key: "welcome.workflow.close",
                                fallback: "关闭"
                            ),
                            action: onClose
                        )
                    }
                }
            }
        }
    }
}

private struct V1WelcomeFeatureRow: View {

    let feature: V1WelcomePresentation.Feature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))

                Text(feature.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

private struct V1WelcomeHeroSection: View {

    let presentation: V1WelcomePresentation
    let language: MemoMarkLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                V1WelcomeHeroMark()

                VStack(alignment: .leading, spacing: 8) {
                    Text(presentation.title)
                        .font(.title.weight(.semibold))

                    Text(presentation.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(
                        language.localized(
                            key: "welcome.hero.detail",
                            fallback: "让照片沿着时间与对象重新被阅读。"
                        )
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                V1WelcomePill(
                    systemImage: "sparkles",
                    title: language.localized(
                        key: "welcome.hero.version",
                        fallback: "V1.0"
                    )
                )

                V1WelcomePill(
                    systemImage: "internaldrive",
                    title: language.localized(
                        key: "welcome.hero.local_first",
                        fallback: "本地优先"
                    )
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(ConfigurationUI.panelBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: ConfigurationUI.cardShadow,
            radius: 18,
            y: 8
        )
        .padding(.top, 12)
    }
}

private struct V1WelcomeWorkflowPreviewRow: View {

    let step: V1WelcomePresentation.WorkflowStep
    let showsDivider: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .fill(Color.blue.opacity(0.12))

                    Image(systemName: step.systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.subheadline.weight(.semibold))

                    Text(step.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

            if showsDivider {
                V1HorizontalDivider()
                    .padding(.top, 8)
            }
        }
    }
}

private struct V1WelcomePill: View {

    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(Color.blue)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.blue.opacity(0.08))
        )
    }
}

private struct V1WelcomeHeroMark: View {

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(MemoMarkDesignTokens.Semantic.fixedLightBackground)
                .shadow(color: ConfigurationUI.cardShadow, radius: 18, y: 8)

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black, lineWidth: 8)
                .frame(width: 88, height: 104)
                .offset(x: -10, y: -2)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.92), lineWidth: 6)
                .frame(width: 74, height: 86)
                .offset(x: 18, y: 12)

            Circle()
                .fill(Color.blue)
                .frame(width: 18, height: 18)
                .offset(x: 36, y: -30)

            Path { path in
                path.move(to: CGPoint(x: 46, y: 70))
                path.addLine(to: CGPoint(x: 70, y: 46))
                path.addLine(to: CGPoint(x: 88, y: 62))
            }
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 134, height: 134)
    }
}
#endif
#endif
