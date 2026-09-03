import Foundation

#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct HomePageSurface<ProfileTrackingBackground: View>: View {

    let runtimeEnvironment:
        MemoMarkRuntimeEnvironment

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @AppStorage("photomemo.v1.applePhotosGuideDismissed")
    private var hasDismissedApplePhotosGuide = false

    @AppStorage(
        MemoMarkSharedContainer.didUseApplePhotosShareKey,
        store: MemoMarkSharedContainer.sharedUserDefaults
    )
    private var hasUsedApplePhotosShare = false

    let subjectSummary: HomeSubjectSummaryProjection
    let subject: MemorySubject?
    let activitySnapshot: MemoMarkBackgroundJobSnapshot?
    let completedPhotoCount: Int
    let hasProcessingRecord: Bool
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

    @State
    private var showsCurrentPresetDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topHeaderSection

                topSummaryCluster
            }
            .padding(.top, 16)
            .padding(.bottom, 104)
            .adaptiveScrollContent(
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
        .alert(
            currentPresetDeleteTitle,
            isPresented: $showsCurrentPresetDeleteConfirmation
        ) {
            Button(localized("home.preset.cancel"), role: .cancel) {}
            Button(localized("home.preset.delete"), role: .destructive) {
                guard let selectedPreset else {
                    return
                }
                onDeleteMemoryPreset(selectedPreset)
            }
        } message: {
            Text(localized("home.preset.delete_message"))
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
        HomeWorkflowReminderCard()
    }

    private var applePhotosEntrySection: some View {
        ConfigurationTitledSectionCard(
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
                .buttonStyle(CompactPrimaryActionButtonStyle())
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
        [WelcomePresentation.WorkflowStep] {
        WelcomePresentation.workflowSteps(
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
            HomeActivityPresenter
            .projection(from: activitySnapshot),
           HomeActivityPresenter
            .shouldShow(projection) {
            HomeActivityCard(
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
            HomeAppMark()

            VStack(alignment: .leading, spacing: 7) {
                brandIdentity
                adaptiveHeaderFacts
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 0)

            settingsButton
        }
    }

    private var compactTopHeaderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                HomeAppMark()
                brandIdentity
                Spacer(minLength: 0)
                settingsButton
            }

            adaptiveHeaderFacts
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

    private var adaptiveHeaderFacts: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                privacyHeaderFact
                Text("·")
                    .foregroundStyle(.tertiary)
                applePhotosHeaderFact
            }

            VStack(alignment: .leading, spacing: 6) {
                privacyHeaderFact
                applePhotosHeaderFact
            }
        }
    }

    private var privacyHeaderFact: some View {
        HomeHeaderFact(
            systemImage: MemoMarkSymbol.privacy.name,
            title: interfaceLanguage.localized(
                key: "settings.overview.tag.local_first",
                fallback: "Local First"
            )
        )
    }

    private var applePhotosHeaderFact: some View {
        HomeHeaderFact(
            systemImage: MemoMarkSymbol.applePhotos.name,
            title: interfaceLanguage.localized(
                key: "home.apple_photos.brand",
                fallback: "Apple Photos"
            )
        )
    }

    private var profileSection: some View {
        ConfigurationTitledSectionSurface(
            title: "home.profile.title",
            subtitle: "home.profile.subtitle"
        ) {
            SubjectHomeEntryContent(
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
            TodayTimeAnswerStrip(
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
        ConfigurationTitledSectionSurface(
            title: "home.presets.title",
            subtitle: "home.presets.subtitle",
            trailingAccessory: {
                presetManagementMenu
            }
        ) {
            VStack(alignment: .leading, spacing: 10) {
                if memoryPresets.isEmpty {
                    HomeEmptyPresetRow()
                } else {
                    HomeInsetGroup {
                        VStack(spacing: 0) {
                            ForEach(memoryPresets) { preset in
                                HomeMemoryPresetRow(
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
                                    }
                                )

                                if preset.id != memoryPresets.last?.id {
                                    HorizontalDivider(
                                        horizontalInset:
                                            ConfigurationUI.innerPanelPadding
                                    )
                                }
                            }
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

    private var presetManagementMenu: some View {
        Menu {
            if let selectedPreset {
                Button(action: onRenameMemoryPreset) {
                    Label(
                        localized("home.preset.rename"),
                        systemImage: "pencil"
                    )
                }

                Button {
                    onSaveMemoryPreset(selectedPreset)
                } label: {
                    Label(
                        localized("home.preset.save"),
                        systemImage: MemoMarkSymbol.localStorage.name
                    )
                }
                .disabled(isSavingConfiguration)

                Button(role: .destructive) {
                    showsCurrentPresetDeleteConfirmation = true
                } label: {
                    Label(
                        localized("home.preset.delete"),
                        systemImage: "trash"
                    )
                }

                Divider()
            }

            Button(action: onOpenLocalConfigurationLibrary) {
                Label(
                    localized("home.presets.manage"),
                    systemImage: "folder"
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            Color(
                                uiColor: .secondarySystemFill
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(ConfigurationUI.faintHairline)
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(localized("home.presets.manage"))
    }

    private var selectedPreset: MemoryPreset? {
        guard let selectedMemoryPresetID else {
            return nil
        }

        return memoryPresets.first {
            $0.id == selectedMemoryPresetID
        }
    }

    private var currentPresetDeleteTitle: String {
        guard let selectedPreset else {
            return localized("home.preset.delete")
        }

        return String(
            format: localized("home.preset.delete_confirmation"),
            locale: interfaceLanguage.locale,
            selectedPreset.title
        )
    }

    @ViewBuilder
    private var processPhotoFooter: some View {
        if shouldShowInAppPhotoPicker {
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
                .buttonStyle(CompactPrimaryActionButtonStyle())
                .accessibilityLabel(
                    isConfigurationReady
                    ? localized("home.process.choose_photo")
                    : localized("home.process.configure_first")
                )
                .accessibilityIdentifier("home-photo-picker")
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

    private var shouldShowInAppPhotoPicker: Bool {
        runtimeEnvironment.isUITestingHarness
            || (!hasProcessingRecord && !hasUsedApplePhotosShare)
    }
}

private struct HomeEmptyPresetRow: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    var body: some View {
        HStack(spacing: 12) {
            HomeConfigurationGlyph()

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

private struct HomeProcessPhotoIcon: View {

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

private struct HomeConfigurationGlyph: View {

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

private struct HomeAppMark: View {

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

private struct HomeHeaderFact: View {

    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text(title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct HomeWorkflowReminderCard: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized("home.workflow.title"))
                .font(.caption.weight(.semibold))
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
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}
#endif
