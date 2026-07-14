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
            subtitle: "记录人生，珍藏记忆",
            message: "时光记会结合照片信息、时间锚点与记忆对象，生成更有意义的记忆表达，同时保留原图。",
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
                    systemImage: "photo.stack.fill"
                ),
                .init(
                    id: "time-anchor",
                    title: "时间锚点",
                    detail: "让照片回到人生时间线中的具体位置。",
                    systemImage: "calendar.badge.clock"
                ),
                .init(
                    id: "configure-once",
                    title: "一次配置，长期受益",
                    detail: "对象、锚点、输出设定好之后，后续处理会更轻松。",
                    systemImage: "checkmark.seal.fill"
                )
            ],
            workflowSteps: [
                .init(
                    id: "photos",
                    title: "在 Apple Photos 选择照片",
                    detail: "从系统相册里找到想处理的照片。",
                    systemImage: "photo.on.rectangle.angled"
                ),
                .init(
                    id: "share",
                    title: "分享给时光记",
                    detail: "也可以直接在首页点“处理照片”进入相同流程。",
                    systemImage: "square.and.arrow.up"
                ),
                .init(
                    id: "processing",
                    title: "后台生成记忆表达",
                    detail: "时光记会按当前配置、时间锚点和输出规则自动处理。",
                    systemImage: "arrow.trianglehead.2.clockwise.circle"
                ),
                .init(
                    id: "return",
                    title: "写回相册继续查看",
                    detail: "处理完成后回到 Apple Photos 继续阅读和整理记忆。",
                    systemImage: "checkmark.circle.fill"
                )
            ],
            primaryActionTitle: "开始使用",
            secondaryActionTitle: "查看使用流程"
        )
}

#if os(iOS)
struct V1WelcomePageSurface: View {

    let presentation: V1WelcomePresentation
    let onStart: () -> Void
    let onShowWorkflow: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    V1WelcomeHeroSection(
                        presentation: presentation
                    )

                    V1CardSurface(title: "初次打开你会用到") {
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

                    V1CardSurface(title: "推荐流程") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Apple Photos -> 分享 -> 时光记 -> 处理 -> Apple Photos")
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
            .navigationTitle("欢迎")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct V1FirstRunConfigurationSheet: View {

    @State private var subjectName = ""
    @State private var birthday = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onSave: (String, Date) async -> Bool
    let onDefer: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.blue)

                        Text("开始回顾")
                            .font(.title2.weight(.semibold))

                        Text("先建立第一套记忆配置。以后从 Apple Photos 分享照片时，时光记会直接使用它。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 6)
                }

                Section("记忆主角") {
                    TextField(
                        "例如：小宝、宝贝儿、安安",
                        text: $subjectName
                    )
                    .textInputAutocapitalization(.never)

                    Text("这个名称会同时作为第一个记忆对象的显示名称和昵称。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("生日") {
                    DatePicker(
                        "选择日期",
                        selection: $birthday,
                        in: ...Date(),
                        displayedComponents: .date
                    )

                    LabeledContent("时间锚点", value: "生日")
                    LabeledContent("表达语气", value: "自然")
                }

                Section("系统已为你准备") {
                    Label("生日成长预设", systemImage: "rectangle.and.text.magnifyingglass")
                    Label("自动保存到 Apple Photos", systemImage: "photo.on.rectangle")
                    Label("保留原图，生成一张新图片", systemImage: "photo.stack")
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
                            Text(isSaving ? "正在保存" : "保存配置")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(
                        subjectName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty || isSaving
                    )
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
        }
    }

    private func save() {
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    V1CardSurface(title: "使用流程") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("推荐日常路径保持在 Apple Photos 内：选择照片，分享给时光记，后台处理完成后再回到系统相册继续阅读。")
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
                    horizontalPadding: 18
                )
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("使用说明")
            .navigationBarTitleDisplayMode(.inline)
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
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

private struct V1WelcomeHeroSection: View {

    let presentation: V1WelcomePresentation

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

                    Text("让照片沿着时间与对象重新被阅读。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                V1WelcomePill(
                    systemImage: "sparkles",
                    title: "V1.0"
                )

                V1WelcomePill(
                    systemImage: "internaldrive",
                    title: "本地优先"
                )
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
        .shadow(
            color: Color.black.opacity(0.06),
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
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 46)
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
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)

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
