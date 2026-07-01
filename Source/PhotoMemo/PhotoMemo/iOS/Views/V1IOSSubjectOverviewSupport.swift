#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

#endif

struct V1IOSSubjectOverviewPresentation:
    Equatable {

    let title: String
    let subtitle: String
    let definition: String
    let anchorTitle: String
    let anchorDateLabel: String
    let anchorCountLabel: String
    let anchorDescription: String
}

enum V1IOSSubjectOverviewPresenter {

    static func presentation(
        subject: MemorySubject?,
        currentTimeAnchorTitle: String,
        currentTimeAnchorDescription: String
    ) -> V1IOSSubjectOverviewPresentation {

        let anchor =
            resolvedAnchor(
                subject: subject,
                currentTimeAnchorTitle:
                    currentTimeAnchorTitle
            )

        return V1IOSSubjectOverviewPresentation(
            title:
                normalizedTitle(
                    subject
                ),
            subtitle:
                normalizedSubtitle(
                    subject
                ),
            definition:
                normalizedDefinition(
                    subject
                ),
            anchorTitle:
                normalizedAnchorTitle(
                    anchor?.title
                    ?? currentTimeAnchorTitle
                ),
            anchorDateLabel:
                anchor?.date.formatted(
                    .dateTime
                        .year()
                        .month()
                        .day()
                )
                ?? "未设置",
            anchorCountLabel:
                "\(subject?.timeAnchors.count ?? 0) 个时间锚点",
            anchorDescription:
                normalizedAnchorDescription(
                    anchor: anchor,
                    fallback:
                        currentTimeAnchorDescription
                )
        )
    }

    private static func resolvedAnchor(
        subject: MemorySubject?,
        currentTimeAnchorTitle: String
    ) -> MemorySubject.TimeAnchor? {
        guard let subject else {
            return nil
        }

        return subject.primaryTimeAnchor
        ?? subject.timeAnchors.first {
            $0.title == currentTimeAnchorTitle
        }
        ?? subject.timeAnchors.first
    }

    private static func normalizedTitle(
        _ subject: MemorySubject?
    ) -> String {
        normalizedOptionalText(
            subject?.identity.shortName
        )
        ?? normalizedOptionalText(
            subject?.identity.displayName
        )
        ?? "记忆对象"
    }

    private static func normalizedSubtitle(
        _ subject: MemorySubject?
    ) -> String {
        normalizedOptionalText(
            subject?.relationship.label
        )
        ?? "补充主角信息"
    }

    private static func normalizedDefinition(
        _ subject: MemorySubject?
    ) -> String {
        normalizedOptionalText(
            subject?.definition
        )
        ?? "用于生成照片底部信息卡。"
    }

    private static func normalizedAnchorTitle(
        _ title: String
    ) -> String {
        normalizedOptionalText(title)
        ?? "未设置"
    }

    private static func normalizedAnchorDescription(
        anchor: MemorySubject.TimeAnchor?,
        fallback: String
    ) -> String {
        normalizedOptionalText(
            anchor?.note
        )
        ?? normalizedOptionalText(fallback)
        ?? "用于理解这张照片在回忆中的位置。"
    }

    private static func normalizedOptionalText(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}

@MainActor
final class V1IOSSubjectConfigurationFlowState:
    Identifiable {

    let sourceSubjectID: MemorySubject.ID
    let draftSession: ConfigurationSession

    private let liveSession: ConfigurationSession
    private let persistSubject:
        ((MemorySubject) -> Void)?

    init?(
        liveSession: ConfigurationSession,
        persistSubject: ((MemorySubject) -> Void)? = nil
    ) {
        guard let selectedSubject = liveSession.state.selectedSubject else {
            return nil
        }

        self.sourceSubjectID = selectedSubject.id
        self.liveSession = liveSession
        self.persistSubject = persistSubject
        self.draftSession = ConfigurationSession(
            state: liveSession.state
        )
        self.draftSession.selectSubject(selectedSubject)
    }

    func saveChanges() {
        guard let updatedSubject =
            draftSession.state.selectedSubject,
            updatedSubject.id == sourceSubjectID
        else {
            return
        }

        liveSession.updateSelectedSubject(updatedSubject)
        persistSubject?(updatedSubject)
    }
}

enum V1IOSSubjectConfigurationFlowPresenter {

    @MainActor
    static func makeFlowState(
        from liveSession: ConfigurationSession,
        persistSubject: ((MemorySubject) -> Void)? = nil
    ) -> V1IOSSubjectConfigurationFlowState? {
        V1IOSSubjectConfigurationFlowState(
            liveSession: liveSession,
            persistSubject: persistSubject
        )
    }
}

#if os(iOS)

struct V1IOSSubjectHomeEntryContent: View {

    let subjectSummary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

    let onOpenSubject: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            V1IOSSubjectPrimaryCard(
                summary: subjectSummary,
                subject: subject,
                action: onOpenSubject
            )

            Text(subjectSummary.definition)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
    }
}

struct V1IOSSubjectOverviewSheet: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subject: MemorySubject?

    let onConfirmActiveAnchor: (UUID) -> Void

    let onOpenEditor: () -> Void

    @State
    private var pendingActiveAnchorID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    V1IOSSubjectOverviewCard(
                        presentation:
                            presentation
                    )

                    V1IOSSubjectIdentitySection(
                        presentation:
                            presentation,
                        subject: subject
                    )

                    V1IOSSubjectAnchorSection(
                        presentation:
                            presentation,
                        subject: subject,
                        selectedAnchorID:
                            Binding(
                                get: {
                                    pendingActiveAnchorID
                                    ?? subject?
                                    .primaryTimeAnchor?
                                    .id
                                },
                                set: {
                                    pendingActiveAnchorID = $0
                                }
                            )
                    )

                    V1CardSurface(title: "对象说明") {
                        Text(presentation.definition)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if let resolvedPendingAnchorID,
                           subject?.timeAnchors.isEmpty == false {
                            Button {
                                onConfirmActiveAnchor(
                                    resolvedPendingAnchorID
                                )
                            } label: {
                                Label(
                                    "设为生效",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!hasAnchorSelectionChange)
                        }

                        Button {
                            onOpenEditor()
                        } label: {
                            Label(
                                "前往对象配置",
                                systemImage:
                                    "slider.horizontal.3"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Text("这里可以快速切换当前生效时间锚点；如果还要调整头像、基本资料或锚点内容，再进入专属配置页继续编辑。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 34)
            }
            .background(
                ConfigurationUI.appBackground
                    .ignoresSafeArea()
            )
            .navigationTitle("当前记忆对象")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                pendingActiveAnchorID =
                    subject?.primaryTimeAnchor?.id
            }
        }
    }

    private var resolvedPendingAnchorID: UUID? {
        pendingActiveAnchorID
        ?? subject?.primaryTimeAnchor?.id
    }

    private var hasAnchorSelectionChange: Bool {
        resolvedPendingAnchorID
        != subject?.primaryTimeAnchor?.id
    }
}

private struct V1IOSSubjectPrimaryCard: View {

    let summary:
        V1IOSHomeSubjectSummaryProjection

    let subject: MemorySubject?

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                V1SubjectAvatarView(
                    imagePath:
                        subject?
                        .identity.avatarImagePath
                        ?? subject?
                        .identity.avatarPreviewImagePath,
                    size: 68
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("当前记忆对象")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(summary.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(summary.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        V1IOSHomeStatusBadge(
                            text: "当前生效时间锚点",
                            tone: .accent
                        )

                        Text(summary.anchorTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.cornerRadius,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
        }
        .buttonStyle(.plain)
    }
}

struct V1IOSSubjectOverviewCard: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    var body: some View {
        V1CardSurface(title: "概览") {
            VStack(alignment: .leading, spacing: 10) {
                overviewRow(
                    title: "当前记忆对象",
                    value: presentation.title
                )
                overviewRow(
                    title: "记录身份",
                    value: presentation.subtitle
                )
                overviewRow(
                    title: "当前生效时间锚点",
                    value: presentation.anchorTitle
                )
                overviewRow(
                    title: "锚点日期",
                    value: presentation.anchorDateLabel
                )
            }
        }
    }

    private func overviewRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct V1IOSSubjectIdentitySection: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subject: MemorySubject?

    var body: some View {
        V1CardSurface(title: "基本资料") {
            VStack(alignment: .leading, spacing: 10) {
                identityRow(
                    title: "显示名称",
                    value:
                        subject?
                        .identity.displayName
                        ?? presentation.title
                )
                identityRow(
                    title: "昵称",
                    value:
                        normalized(
                            subject?
                            .identity.shortName
                        )
                        ?? "未设置"
                )
                identityRow(
                    title: "身份类型",
                    value:
                        normalized(
                            subject?
                            .relationship.role
                        )
                        ?? "未设置"
                )
                identityRow(
                    title: "记录身份",
                    value:
                        normalized(
                            subject?
                            .relationship.label
                        )
                        ?? "未设置"
                )
            }
        }
    }

    private func identityRow(
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
    }

    private func normalized(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}

private struct V1IOSSubjectAnchorSection: View {

    let presentation:
        V1IOSSubjectOverviewPresentation

    let subject: MemorySubject?

    @Binding
    var selectedAnchorID: UUID?

    var body: some View {
        let selectedAnchor =
            resolvedAnchor

        return V1CardSurface(title: "当前生效时间锚点") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            selectedAnchor?.title
                            ?? presentation.anchorTitle
                        )
                            .font(.subheadline.weight(.semibold))

                        Text(
                            selectedAnchor?.date.formatted(
                                .dateTime
                                    .year()
                                    .month()
                                    .day()
                            )
                            ?? presentation.anchorDateLabel
                        )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    V1IOSHomeStatusBadge(
                        text: presentation.anchorCountLabel,
                        tone: .accent
                    )
                }

                Text(
                    normalizedDescription(
                        for: selectedAnchor
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                if let subject,
                   !subject.timeAnchors.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("选择要立即生效的时间锚点")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker(
                            "当前生效时间锚点",
                            selection:
                                Binding(
                                    get: {
                                        selectedAnchorID
                                        ?? subject
                                        .primaryTimeAnchor?
                                        .id
                                        ?? subject
                                        .timeAnchors
                                        .first?
                                        .id
                                        ?? UUID()
                                    },
                                    set: {
                                        selectedAnchorID = $0
                                    }
                                )
                        ) {
                            ForEach(subject.timeAnchors) { anchor in
                                Text(anchor.title)
                                    .tag(anchor.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
    }

    private var resolvedAnchor: MemorySubject.TimeAnchor? {
        guard let subject else {
            return nil
        }

        if let selectedAnchorID {
            return subject.timeAnchors.first {
                $0.id == selectedAnchorID
            }
        }

        return subject.primaryTimeAnchor
    }

    private func normalizedDescription(
        for anchor: MemorySubject.TimeAnchor?
    ) -> String {
        let trimmedNote =
            anchor?.note
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmedNote.isEmpty {
            return trimmedNote
        }

        return presentation.anchorDescription
    }
}

private struct V1SubjectAvatarView: View {

    let imagePath: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    Color.accentColor
                        .opacity(0.12)
                )

            if let imagePath {
                V1PlatformAvatarImage(path: imagePath)
                    .scaledToFill()
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: size * 0.36, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(ConfigurationUI.faintHairline)
        )
    }
}

private struct V1PlatformAvatarImage: View {

    let path: String

    var body: some View {
#if os(macOS)
        if let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image)
                .resizable()
        } else {
            Color.clear
        }
#elseif canImport(UIKit)
        if let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
        } else {
            Color.clear
        }
#endif
    }
}

private struct V1IOSHomeLinkRow: View {

    let title: String
    let subtitle: String
    let value: String
    let detail: String
    let systemImage: String
    let showsDivider: Bool
    let action: () -> Void
    let emphasizedValue: Bool

    init(
        title: String,
        subtitle: String,
        value: String,
        detail: String,
        systemImage: String,
        showsDivider: Bool = true,
        action: @escaping () -> Void,
        emphasizedValue: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.detail = detail
        self.systemImage = systemImage
        self.showsDivider = showsDivider
        self.action = action
        self.emphasizedValue = emphasizedValue
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius: 10,
                            style: .continuous
                        )
                        .fill(ConfigurationUI.controlBackground)

                        Image(systemName: systemImage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(value)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(
                                emphasizedValue
                                ? Color.accentColor
                                : .primary
                            )
                            .lineLimit(1)

                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if showsDivider {
                Rectangle()
                    .fill(ConfigurationUI.faintHairline)
                    .frame(height: 0.5)
                    .padding(.leading, 50)
            }
        }
    }
}

#endif
