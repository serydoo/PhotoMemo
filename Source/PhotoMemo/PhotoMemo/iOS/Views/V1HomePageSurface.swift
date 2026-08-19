import Foundation

#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI
import UIKit

struct V1HomePageSurface<ProfileTrackingBackground: View>: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @AppStorage("photomemo.v1.applePhotosGuideDismissed")
    private var hasDismissedApplePhotosGuide = false

    let subjectSummary: V1IOSHomeSubjectSummaryProjection
    let subject: MemorySubject?
    let activitySnapshot: PhotoMemoBackgroundJobSnapshot?
    let completedPhotoCount: Int
    let borderStyleName: String
    let borderStyleDescription: String
    let memoryPresets: [MemoryPreset]
    let selectedMemoryPresetID: MemoryPreset.ID?
    let isEditingMemoryPresetTitle: Bool
    let memoryPresetTitleDraft: Binding<String>
    let memoryPresetTitleFieldFocused: FocusState<Bool>.Binding
    let isConfigurationReady: Bool
    let isSavingConfiguration: Bool
    let showsMemoMarkPlusBadge: Bool
    let isFirstRecorder: Bool
    let onOpenSubject: () -> Void
    let onOpenProcessing: () -> Void
    let onCommitMemoryPresetTitle: () -> Void
    let onOpenWorkflowGuide: () -> Void
    let onOpenPhotoPicker: () -> Void
    let onOpenSettings: () -> Void
    let onOpenMemoMarkPlus: () -> Void
    let onSelectMemoryPreset: (MemoryPreset) -> Void
    let onRenameMemoryPreset: () -> Void
    let onSaveMemoryPreset: (MemoryPreset) -> Void
    let onDeleteMemoryPreset: (MemoryPreset) -> Void
    let onOpenLocalConfigurationLibrary: () -> Void
    let onDismissKeyboard: () -> Void
    let profileTrackingBackground: ProfileTrackingBackground

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topHeaderSection

                topSummaryCluster
            }
            .padding(.top, 16)
            .padding(.bottom, 104)
            .v1AdaptiveScrollContent(
                horizontalPadding: ConfigurationUI.contentColumnPadding
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onDismissKeyboard()
                }
        )
        .background(
            ConfigurationUI.appBackground
                .ignoresSafeArea()
        )
        .navigationTitle(localized("home.title"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            processPhotoFooter
        }
    }

    private var topSummaryCluster: some View {
        VStack(spacing: 14) {
            if !hasDismissedApplePhotosGuide {
                applePhotosEntrySection
            }

            profileSection
                .background(profileTrackingBackground)

            activitySection

            currentPresetSection

            workflowReminderCard
        }
    }

    private var workflowReminderCard: some View {
        V1HomeWorkflowReminderCard()
    }

    private var applePhotosEntrySection: some View {
        V1TitledSectionCard(
            title: interfaceLanguage.localized(
                key: "home.apple_photos.title",
                fallback: "从 Apple Photos 开始"
            ),
            subtitle: interfaceLanguage.localized(
                key: "home.apple_photos.subtitle",
                fallback: "在系统相册选好照片，分享给时光记。"
            ),
            trailingAccessory: {
                Button(action: dismissApplePhotosGuide) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(localized("home.apple_photos.close"))
                .accessibilityHint(localized("home.apple_photos.close_hint"))
            }
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(applePhotosWorkflowIntroduction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(applePhotosWorkflowSteps) { step in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 9)

                        if step.id != applePhotosWorkflowSteps.last?.id {
                            Divider()
                        }
                    }
                }

                Button(action: onOpenWorkflowGuide) {
                    Text(localized("home.apple_photos.share_guide"))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                        .v1CompactBottomPrimaryAction()
                }
                .buttonStyle(V1CompactPrimaryActionButtonStyle())
                .frame(maxWidth: .infinity)

                Text(nextShareConfigurationText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(nextShareConfigurationText)
            }
        }
    }

    private var applePhotosWorkflowSteps:
        [V1WelcomePresentation.WorkflowStep] {
        V1WelcomePresentation.workflowSteps(
            for: interfaceLanguage
        )
    }

    private var applePhotosWorkflowIntroduction: String {
        interfaceLanguage.localized(
            key: "welcome.workflow.introduction",
            fallback: "日常记录从 Apple Photos 开始：选择照片，分享给时光记，完成后再回到相册查看。"
        )
    }

    private func dismissApplePhotosGuide() {
        hasDismissedApplePhotosGuide = true
    }

    private var nextShareConfigurationText: String {
        let language = interfaceLanguage

        guard isConfigurationReady,
              let selectedMemoryPresetID,
              let preset = memoryPresets.first(where: {
                  $0.id == selectedMemoryPresetID
              }) else {
            return language.localized(
                key: "home.next_share.save_configuration",
                fallback: "保存配置后，下一次分享会自动使用当前配置。"
            )
        }

        let format = language.localized(
            key: "home.next_share.configuration_format",
            fallback: "下一次从 Apple Photos 分享时，将使用当前配置“%@”。"
        )
        return String(format: format, locale: language.locale, preset.title)
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }

    @ViewBuilder
    private var activitySection: some View {
        if let projection =
            V1IOSHomeActivityPresenter
            .projection(from: activitySnapshot),
           V1IOSHomeActivityPresenter
            .shouldShow(projection) {
            V1IOSHomeActivityCard(
                projection: projection,
                onOpenProcessing: onOpenProcessing
            )
        }
    }

    private var topHeaderSection: some View {
        ViewThatFits(in: .horizontal) {
            regularTopHeaderSection
            compactTopHeaderSection
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private var regularTopHeaderSection: some View {
        HStack(alignment: .top, spacing: 12) {
            V1HomeAppMark()

            VStack(alignment: .leading, spacing: 7) {
                brandIdentity
                adaptiveHeaderPills
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 0)

            settingsButton
        }
    }

    private var compactTopHeaderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                V1HomeAppMark()
                brandIdentity
                Spacer(minLength: 0)
                settingsButton
            }

            adaptiveHeaderPills
        }
    }

    private var brandIdentity: some View {
        VStack(alignment: .leading, spacing: 7) {
            brandTitle

            Text(localized("home.brand.tagline"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var brandTitle: some View {
        if showsMemoMarkPlusBadge {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    productTitle
                    memoMarkPlusBadge
                }

                VStack(alignment: .leading, spacing: 6) {
                    productTitle
                    memoMarkPlusBadge
                }
            }
        } else {
            productTitle
        }
    }

    private var productTitle: some View {
        Text(
            interfaceLanguage.localized(
                key: "welcome.title",
                fallback: "MemoMark"
            )
        )
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
    }

    private var memoMarkPlusBadge: some View {
        MemoMarkPlusBadge(
            isFirstRecorder: isFirstRecorder,
            action: onOpenMemoMarkPlus
        )
    }

    private var settingsButton: some View {
        Button(action: onOpenSettings) {
            Image(systemName: MemoMarkSymbol.settings.name)
                .font(.body.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            Color(
                                uiColor: .secondarySystemFill
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localized("home.settings.accessibility"))
    }

    private var adaptiveHeaderPills: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                privacyHeaderPill
                applePhotosHeaderPill
            }

            VStack(alignment: .leading, spacing: 6) {
                privacyHeaderPill
                applePhotosHeaderPill
            }
        }
    }

    private var privacyHeaderPill: some View {
        V1HomeHeaderPill(
            systemImage: MemoMarkSymbol.privacy.name,
            title: interfaceLanguage.localized(
                key: "settings.overview.tag.local_first",
                fallback: "Local First"
            )
        )
    }

    private var applePhotosHeaderPill: some View {
        V1HomeHeaderPill(
            systemImage: MemoMarkSymbol.applePhotos.name,
            title: interfaceLanguage.localized(
                key: "home.apple_photos.brand",
                fallback: "Apple Photos"
            )
        )
    }

    private var profileSection: some View {
        V1TitledSectionSurface(
            title: "home.profile.title",
            subtitle: "home.profile.subtitle"
        ) {
            V1IOSSubjectHomeEntryContent(
                subjectSummary: subjectSummary,
                subject: subject,
                onOpenSubject: onOpenSubject,
                statisticsStrip:
                    todayTimeAnswerStrip
            )
        }
    }

    @ViewBuilder
    private var todayTimeAnswerStrip: some View {
        if let anchor = selectedTimeAnswerAnchor {
            V1IOSTodayTimeAnswerStrip(
                anchor: anchor,
                subjectName:
                    subject?.identity.shortName
                    ?? subjectSummary.title
            )
        }
    }

    private var selectedTimeAnswerAnchor: MemorySubject.TimeAnchor? {
        let selectedPreset = memoryPresets.first {
            $0.id == selectedMemoryPresetID
        }
        if let anchorID = selectedPreset?.selectedTimeAnchorID,
           let anchor = subject?.timeAnchor(id: anchorID) {
            return anchor
        }

        return subject?.primaryTimeAnchor
            ?? subject?.timeAnchors.first
    }

    private func anchorType(
        for preset: MemoryPreset
    ) -> AnchorType {
        guard
            let anchorID = preset.selectedTimeAnchorID,
            let anchor = subject?.timeAnchor(id: anchorID)
        else {
            return .custom
        }

        return anchor.resolvedAnchorType
    }

    private var currentPresetSection: some View {
        V1TitledSectionSurface(
            title: "home.presets.title",
            subtitle: "home.presets.subtitle",
            trailingAccessory: {
                V1CardHeaderIconButton(
                    systemImage: "ellipsis",
                    accessibilityLabel: localized("home.presets.manage"),
                    action: onOpenLocalConfigurationLibrary
                )
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if memoryPresets.isEmpty {
                    V1HomeEmptyPresetRow()
                } else {
                    VStack(spacing: 8) {
                        ForEach(memoryPresets) { preset in
                            V1HomeMemoryPresetRow(
                                preset: preset,
                                borderStyleName: borderStyleName,
                                anchorType: anchorType(for: preset),
                                subjectAvatarImagePath:
                                    subject?.identity.avatarPreviewImagePath
                                    ?? subject?.identity.avatarImagePath,
                                isSelected:
                                    preset.id == selectedMemoryPresetID,
                                onSelect: {
                                    onSelectMemoryPreset(preset)
                                },
                                onRename: {
                                    if preset.id != selectedMemoryPresetID {
                                        onSelectMemoryPreset(preset)
                                    }
                                    onRenameMemoryPreset()
                                },
                                onSave: {
                                    onSaveMemoryPreset(preset)
                                },
                                isSaveDisabled: isSavingConfiguration,
                                onDelete: {
                                    onDeleteMemoryPreset(preset)
                                }
                            )
                        }
                    }
                }

                if isEditingMemoryPresetTitle {
                    HStack(spacing: 8) {
                        TextField(
                            localized("home.preset.configuration_name"),
                            text: memoryPresetTitleDraft
                        )
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                        .submitLabel(.done)
                        .focused(memoryPresetTitleFieldFocused)
                        .configurationFieldChrome(isActive: true)
                        .onSubmit {
                            onCommitMemoryPresetTitle()
                        }

                        Button(localized("common.done")) {
                            onCommitMemoryPresetTitle()
                        }
                        .buttonStyle(.plain)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.controlBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )
                        .accessibilityLabel(localized("home.preset.done_editing"))
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(localized("home.presets.manage_hint"))
                    Text(localized("home.presets.edit_hint"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
                .padding(.top, 2)
            }
        }
    }

    private var processPhotoFooter: some View {
        VStack(spacing: 0) {
            Button(action: onOpenPhotoPicker) {
                Label(
                    isConfigurationReady
                    ? localized("home.process.choose_photo")
                    : localized("home.process.configure_first"),
                    systemImage: "photo.on.rectangle"
                )
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .v1CompactBottomPrimaryAction()
            }
            .buttonStyle(V1CompactPrimaryActionButtonStyle())
            .accessibilityLabel(
                isConfigurationReady
                ? localized("home.process.choose_photo")
                : localized("home.process.configure_first")
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            ConfigurationUI.appBackground
                .opacity(0.96)
                .ignoresSafeArea()
        )
    }
}

private struct V1IOSHomeActivityCard: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    let projection: V1IOSHomeActivityProjection
    let onOpenProcessing: () -> Void

    @State
    private var isMounted =
        V1IOSHomeActivityPresentationState()
        .isMounted

    @State
    private var isVisible =
        V1IOSHomeActivityPresentationState()
        .isVisible

    var body: some View {
        Group {
            if isMounted {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localized("home.activity.title"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Button(action: onOpenProcessing) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(projection.countText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.82)

                                Spacer(minLength: 8)

                                Text(projection.statusText)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(statusColor)
                                    .lineLimit(1)
                            }

                            activityProgressBar
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, ConfigurationUI.innerPanelPadding)
                        .padding(.vertical, ConfigurationUI.innerPanelPadding)
                        .background(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                                style: .continuous
                            )
                            .fill(ConfigurationUI.controlBackground)
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                                style: .continuous
                            )
                            .stroke(ConfigurationUI.faintHairline)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(
                        "\(projection.countText)，\(projection.statusText)"
                    )
                    .accessibilityValue(
                        String(
                            format: localized("home.activity.progress"),
                            locale: interfaceLanguage.locale,
                            progressPercentText
                        )
                    )
                }
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible || accessibilityReduceMotion ? 0 : -6)
            }
        }
        .task(id: projection.lifecycleID) {
            await present(projection)
        }
    }

    private var activityProgressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(Color.accentColor.opacity(0.16))

                Capsule(style: .continuous)
                    .fill(Color.accentColor)
                    .frame(
                        width: proxy.size.width
                            * projection.progressFraction
                    )
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    private var statusColor: Color {
        switch projection.state {
        case .processing:
            return .accentColor
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }

    private var progressPercentText: String {
        "\(Int((projection.progressFraction * 100).rounded()))%"
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }

    @MainActor
    private func present(
        _ projection: V1IOSHomeActivityProjection
    ) async {
        let wasVisible = isVisible
        guard V1IOSHomeActivityPresenter.shouldShow(projection) else {
            await dismiss()
            return
        }

        isMounted = true

        if !wasVisible {
            isVisible = false
            await Task.yield()
            withAnimation(
                accessibilityReduceMotion
                ? nil
                : .easeOut(duration: 0.25)
            ) {
                isVisible = true
            }
        } else {
            isVisible = true
        }

        guard projection.state == .completed else {
            return
        }

        let elapsed =
            Date().timeIntervalSince(projection.updatedAt)
        let remaining =
            max(
                V1IOSHomeActivityPresenter
                    .completionDisplayDuration
                    - elapsed,
                0
            )

        if remaining > 0 {
            try? await Task.sleep(
                nanoseconds: UInt64(remaining * 1_000_000_000)
            )
        }

        guard !Task.isCancelled else {
            return
        }

        await dismiss()
    }

    @MainActor
    private func dismiss() async {
        withAnimation(
            accessibilityReduceMotion
            ? nil
            : .easeOut(duration: 0.2)
        ) {
            isVisible = false
        }

        if !accessibilityReduceMotion {
            try? await Task.sleep(
                nanoseconds: 200_000_000
            )
        }

        guard !Task.isCancelled else {
            return
        }

        isMounted = false
    }
}

private struct V1HomeMemoryPresetRow: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let preset: MemoryPreset
    let borderStyleName: String
    let anchorType: AnchorType
    let subjectAvatarImagePath: String?
    let isSelected: Bool
    let onSelect: () -> Void
    let onRename: () -> Void
    let onSave: () -> Void
    let isSaveDisabled: Bool
    let onDelete: () -> Void

    @State private var showsDeleteConfirmation = false

    var body: some View {
        rowContent
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label(localized("home.preset.delete"), systemImage: "trash")
                }
                .tint(.red)
                .accessibilityLabel(localized("home.preset.delete_accessibility"))

                Button(action: onSave) {
                    Label(
                        localized("home.preset.save"),
                        systemImage: MemoMarkSymbol.localStorage.name
                    )
                }
                .tint(.blue)
                .disabled(isSaveDisabled)
                .accessibilityLabel(localized("home.preset.save_accessibility"))
            }
            .alert(
                String(
                    format: localized("home.preset.delete_confirmation"),
                    locale: interfaceLanguage.locale,
                    preset.title
                ),
                isPresented: $showsDeleteConfirmation
            ) {
                Button(localized("home.preset.cancel"), role: .cancel) {}
                Button(localized("home.preset.delete"), role: .destructive) {
                    onDelete()
                }
            } message: {
                Text(localized("home.preset.delete_message"))
            }
    }

    private var rowContent: some View {
        adaptivePresetRowContent
            .padding(10)
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
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: 12,
                y: 5
            )
    }

    @ViewBuilder
    private var adaptivePresetRowContent: some View {
        if dynamicTypeSize.isAccessibilitySize {
            verticalPresetRowContent
        } else {
            ViewThatFits(in: .horizontal) {
                horizontalPresetRowContent
                verticalPresetRowContent
            }
        }
    }

    private var horizontalPresetRowContent: some View {
        HStack(alignment: .center, spacing: 12) {
            presetIdentityMark
            presetTextContent(lineLimit: 1)

            Spacer(minLength: 4)
            presetActions
        }
    }

    private var verticalPresetRowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                presetIdentityMark
                presetTextContent(lineLimit: 3)
            }

            presetActions
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func presetTextContent(
        lineLimit: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(preset.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(lineLimit)

            Text(borderStyleName)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(lineLimit)

            Text(presetDetail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(lineLimit)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var presetActions: some View {
        HStack(spacing: 8) {
            Menu {
                if isSelected {
                    Button(action: onRename) {
                        Label(localized("home.preset.rename"), systemImage: "pencil")
                    }
                }

                Button(action: onSave) {
                    Label(
                        localized("home.preset.save"),
                        systemImage: MemoMarkSymbol.localStorage.name
                    )
                }
                .disabled(isSaveDisabled)

                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    Label(localized("home.preset.delete"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .contentShape(
                        Rectangle().inset(by: -7)
                    )
            }
            .accessibilityLabel(localized("home.preset.more_actions"))

            Image(
                systemName:
                    isSelected
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(.title3.weight(.semibold))
            .foregroundStyle(
                isSelected
                ? Color.accentColor
                : Color.secondary.opacity(0.58)
            )
            .frame(width: 26, height: 30)
        }
        .opacity(isSelected ? 1 : 0.42)
    }

    private var presetDetail: String {
        guard isSelected, let savedAt = preset.savedAt else {
            return preset.summary
        }

        return V1IOSHomeProjection.savedStatusValue(
            savedAt: savedAt
        )
    }

    private var presetIdentityMark: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(anchorTint.opacity(0.11))
            .overlay {
                Image(systemName: anchorSystemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(anchorTint)
            }

            logoBadge
                .offset(x: 3, y: 3)
        }
        .frame(width: 48, height: 48)
        .overlay(
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(anchorTint.opacity(0.12))
        )
        .accessibilityLabel(
            String(
                format: localized("home.preset.identity_format"),
                locale: interfaceLanguage.locale,
                anchorType.localizedDisplayName(for: interfaceLanguage),
                localizedLogoTitle
            )
        )
    }

    @ViewBuilder
    private var logoBadge: some View {
        ZStack {
            Circle()
                .fill(MemoMarkDesignTokens.Semantic.fixedLightBackground)
                .overlay(
                    Circle()
                        .stroke(ConfigurationUI.faintHairline)
                )

            switch preset.logoMode {
            case .appleMini:
                Image(systemName: "apple.logo")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.primary)
            case .customUpload:
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.purple)
            case .subjectAvatar:
                if let subjectAvatarImagePath,
                   let image = UIImage(
                    contentsOfFile: subjectAvatarImagePath
                   ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image(systemName: MemoMarkSymbol.memorySubject.name)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.pink)
                }
            }
        }
        .frame(width: 19, height: 19)
        .shadow(color: ConfigurationUI.cardShadow, radius: 3, y: 1)
        .environment(\.colorScheme, .light)
    }

    private var anchorSystemImage: String {
        switch anchorType {
        case .birthday:
            return "birthday.cake.fill"
        case .relationship:
            return "heart.fill"
        case .marriage:
            return "sparkles"
        case .exam:
            return "flag.checkered"
        case .custom:
            return "calendar"
        }
    }

    private var anchorTint: Color {
        switch anchorType {
        case .birthday:
            return .orange
        case .relationship:
            return .pink
        case .marriage:
            return .purple
        case .exam:
            return .green
        case .custom:
            return .blue
        }
    }

    private var localizedLogoTitle: String {
        switch preset.logoMode {
        case .appleMini:
            return localized("home.logo.apple")
        case .customUpload:
            return localized("home.logo.custom")
        case .subjectAvatar:
            return localized("home.logo.avatar")
        }
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}

private struct V1HomeEmptyPresetRow: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    var body: some View {
        HStack(spacing: 12) {
            V1HomeConfigurationGlyph()

            VStack(alignment: .leading, spacing: 4) {
                Text(localized("home.empty.title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(localized("home.empty.detail"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}

private struct V1HomeProcessPhotoIcon: View {

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .stroke(
                MemoMarkDesignTokens.Semantic.onAccent.opacity(0.92),
                lineWidth: 1.6
            )
            .frame(width: 20, height: 16)

            Image(systemName: "sparkles")
                .font(.system(size: 9, weight: .bold))
                .offset(x: 9, y: -8)
        }
        .frame(width: 24, height: 24)
    }
}

private struct V1HomeConfigurationGlyph: View {

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(Color.accentColor.opacity(0.10))

            Image(systemName: MemoMarkSymbol.configuration.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 48, height: 48)
    }
}

private struct V1HomeAppMark: View {

    var body: some View {
        Image("HomeAppIcon")
            .resizable()
            .scaledToFill()
            .frame(width: 70, height: 70)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .shadow(
                color: ConfigurationUI.cardShadow,
                radius: 8,
                y: 3
            )
    }
}

private struct V1HomeHeaderPill: View {

    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(MemoMarkDesignTokens.Semantic.quietInformation)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(Color(uiColor: .secondarySystemFill))
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct V1HomeWorkflowReminderCard: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("home.workflow.title"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(
                localized("home.workflow.detail")
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Text(
                localized("home.workflow.note")
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                style: .continuous
            )
            .fill(ConfigurationUI.controlBackground.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.innerPanelCornerRadius,
                style: .continuous
            )
            .stroke(ConfigurationUI.faintHairline)
        )
        .accessibilityElement(children: .combine)
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}
#endif
