#if os(macOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import PhotosUI

private func macLocalized(
    _ key: String,
    fallback: String
) -> String {
    MemoMarkLanguage.interfaceStored.localized(
        key: key,
        fallback: fallback
    )
}

enum MacConfigurationWorkspaceRoute: String, Identifiable, Hashable {
    case subject
    case preset
    case cardContent
    case filmMarkDetails
    case timeAndPlace

    var id: String { rawValue }

    var title: String {
        switch self {
        case .subject: return macLocalized("mac.route.subject", fallback: "Memory Subject")
        case .preset: return macLocalized("mac.route.preset", fallback: "Current Preset")
        case .cardContent: return macLocalized("mac.route.card_content", fallback: "Card Content")
        case .filmMarkDetails: return macLocalized("mac.route.film_mark_details", fallback: "FilmMark Style and Details")
        case .timeAndPlace: return macLocalized("mac.route.time_and_place", fallback: "Time and Place")
        }
    }

    var systemImage: String {
        switch self {
        case .subject: return "person.crop.circle"
        case .preset: return "rectangle.stack.fill"
        case .cardContent: return "rectangle.3.group"
        case .filmMarkDetails: return "paintpalette"
        case .timeAndPlace: return "clock.badge.checkmark"
        }
    }
}

private enum MacConfigurationInspectorPresentation {
    case sheet
    case inspector
}

struct MacConfigurationCenterPage: View {

    @ObservedObject
    var session: ConfigurationSession

    @ObservedObject
    var commerceStore: MemoMarkCommerceStore

    @ObservedObject
    var backgroundStatusService:
        MemoMarkBackgroundStatusService

    let loadConfigurationBootstrap:
        LoadConfigurationBootstrapTransaction

    let loadPhotoLibraryAlbums:
        LoadPhotoLibraryAlbumsTransaction

    let saveConfiguration:
        SaveConfigurationTransaction

    let configurationCoordinator:
        ConfigurationCoordinator

    @State
    private var configurationStatus = ConfigurationPersistenceStatus.saved

    @State
    private var showsUnsavedSubjectSwitchAlert = false

    @State
    private var isSubjectBrowserPresented = false

    @State
    private var isPresetBrowserPresented = false

    @State
    private var pendingMemoryPresetActivation: MemoryPreset?

    @State
    private var inspectorRoute: MacConfigurationWorkspaceRoute?

    @State
    private var configurationInspectorRoute: MacConfigurationWorkspaceRoute?

    @State
    private var presentationStyle = RecordCardPresentationStyle.classicWhite

    @State
    private var filmMarkConfiguration = FilmMarkConfiguration.default

    /// FilmMark authored content is an independent configuration payload. It
    /// must not be reconstructed from the classic slot-A region.
    @State
    private var filmMarkContentDraft = MemoryCardEditorDraft(items: [])

    @State
    private var logoMode = ConfigurationLogoMode.appleMini

    @State
    private var customLogoBadge: Badge?

    @State
    private var didBootstrapRuntime = false

    var body: some View {
        GeometryReader { proxy in
            let availableWidth = max(
                0,
                proxy.size.width
                    - MacConfigurationCenterMetrics.pageHorizontalPadding * 2
            )
            let workspaceWidth =
                MacConfigurationCenterMetrics.workspaceWidth(
                    for: availableWidth
                )

            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: 16,
                    pinnedViews: [.sectionHeaders]
                ) {
                    MacConfigurationCenterHeader(
                        session: session,
                        commerceStore: commerceStore,
                        onOpenSubject: {
                            isSubjectBrowserPresented = true
                        },
                        onOpenPreset: {
                            isPresetBrowserPresented = true
                        }
                    )

                    Section {
                        configurationSection(workspaceWidth: workspaceWidth)
                        recentSituationSection
                    } header: {
                        // Pin the real preview surface while the lower
                        // configuration content scrolls. The header owns an
                        // opaque background so rows never bleed through it.
                        previewSection(workspaceWidth: workspaceWidth)
                            .padding(.bottom, 2)
                            .background(ConfigurationUI.appBackground)
                            .zIndex(2)
                    }
                }
                .frame(width: workspaceWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, MacConfigurationCenterMetrics.pageHorizontalPadding)
                .padding(.vertical, MacConfigurationCenterMetrics.pageVerticalPadding)
            }
        }
        .background(ConfigurationUI.appBackground)
        .navigationTitle(macLocalized("mac.page.title", fallback: "Configuration"))
        .alert(
            macLocalized("mac.alert.unsaved_subject.title", fallback: "Unsaved Changes"),
            isPresented: $showsUnsavedSubjectSwitchAlert
        ) {
            Button(macLocalized("common.ok", fallback: "OK"), role: .cancel) {}
        } message: {
            Text(macLocalized("mac.alert.unsaved_subject.message", fallback: "Save the current configuration before switching memory subjects."))
        }
        .onAppear {
            bootstrapRuntimeIfNeeded()
            presentationStyle = session.selectedMemoryConfiguration?.presentation.route
                ?? .classicWhite
            filmMarkConfiguration = session.selectedMemoryConfiguration?.presentation.filmMark
                ?? .default
            logoMode = session.selectedMemoryConfiguration?.presentation.logo.mode
                ?? session.state.selectedMemoryPreset?.logoMode
                ?? .appleMini
        }
        .popover(isPresented: $isSubjectBrowserPresented) {
            MemorySubjectListView(
                session: session,
                onSelectSubject: requestSubjectSelection,
                onEditSubject: {
                    isSubjectBrowserPresented = false
                    // A popover cannot be dismissed and replaced by a sheet
                    // in the same presentation transaction on macOS. Defer
                    // the route until the popover has completed dismissal.
                    DispatchQueue.main.async {
                        inspectorRoute = .subject
                    }
                },
                onCreateSubject: {
                    isSubjectBrowserPresented = false
                    DispatchQueue.main.async {
                        createSubjectAndOpenInspector()
                    }
                }
            )
                .frame(width: 320, height: 520)
        }
        .popover(isPresented: $isPresetBrowserPresented) {
            MacMemoryPresetList(
                session: session,
                onSelectPreset: { preset in
                    isPresetBrowserPresented = false
                    DispatchQueue.main.async {
                        requestMemoryPresetSelectionFromHeader(preset)
                    }
                }
            )
            .frame(width: 360, height: 420)
        }
        .sheet(item: $inspectorRoute) { route in
            MacConfigurationInspector(
                route: route,
                session: session,
                commerceStore: commerceStore,
                configurationCoordinator: configurationCoordinator,
                saveConfiguration: saveConfiguration,
                configurationStatus: $configurationStatus,
                onSelectPreset: { preset in
                    pendingMemoryPresetActivation = preset
                },
                onInsertModule: { _ in },
                onDraftChange: { _, _, _ in },
                selectedLocationOptionID: nil,
                selectedTimeOptionID: nil,
                selectedTimeSupplement: nil,
                filmMarkConfiguration: nil,
                filmMarkContentDraft: nil,
                onSaveCardContent: {},
                regionDrafts: nil,
                presentationStyle: nil,
                onDirty: {},
                presentation: .sheet
            )
        }
    }

    private func previewSection(workspaceWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MacConfigurationSectionHeader(
                title: macLocalized("mac.preview.title", fallback: "Preview"),
                subtitle: macLocalized("mac.preview.subtitle", fallback: "A preview of the memory card generated by this configuration."),
                trailingTitle: nil,
                trailingSystemImage: nil
            ) {}

            HStack {
                MemoryCardPreviewSurface(
                    presentationStyle: presentationStyle,
                    logoMode: logoMode,
                    customLogoImagePath: customLogoImagePath,
                    subjectAvatarLogoImagePath: subjectAvatarLogoImagePath,
                    regionText: session.previewText(for: .slotA),
                    timeText: session.previewText(for: .slotB),
                    contextText: session.previewText(for: .slotC),
                    memoryText: session.resolvedMemoryWriteText,
                    filmMarkOutputText: filmMarkContentDraft.singleLineText,
                    filmMarkConfiguration: filmMarkConfiguration
                )
                .frame(
                    maxWidth: MacConfigurationCenterMetrics.previewWidth(
                        for: workspaceWidth
                    )
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .macConfigurationCenterSurface(
                cornerRadius: MacConfigurationCenterStyle.regionCornerRadius
            )
            .accessibilityIdentifier("mac.configurationCenter.preview")
        }
    }

    private func requestSubjectSelection(_ subject: MemorySubject) {
        if SubjectSelectionMutationCoordinator
            .requiresSavingCurrentConfiguration(
                destinationSubjectID: subject.id,
                currentSubjectID: session.state.selectedSubjectID,
                isCurrentConfigurationDirty:
                    configurationStatus.hasUncommittedChanges
            ) {
            showsUnsavedSubjectSwitchAlert = true
            return
        }

        guard let patch = SubjectOverviewActionCoordinator.selectSubject(
            subject.id,
            in: session,
            shouldSaveSubjectLibrary: true,
            configurationCoordinator: configurationCoordinator
        ) else {
            return
        }
        configurationStatus = patch.activeConfigurationStatus
    }

    private func createSubjectAndOpenInspector() {
        let patch = SubjectOverviewActionCoordinator.addDefaultSubject(
            referenceDate: Date(),
            to: session,
            shouldSaveSubjectLibrary: true,
            configurationCoordinator: configurationCoordinator,
            onPersistedSubject: { persistedPatch in
                configurationStatus = persistedPatch.activeConfigurationStatus
            }
        )
        configurationStatus = patch.activeConfigurationStatus
        inspectorRoute = .subject
    }

    private func requestMemoryPresetSelectionFromHeader(_ preset: MemoryPreset) {
        guard preset.id != session.state.selectedMemoryPresetID else {
            return
        }
        pendingMemoryPresetActivation = preset
    }

    private func configurationSection(workspaceWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MacConfigurationSectionHeader(
                title: macLocalized("mac.configuration.title", fallback: "Configuration"),
                subtitle: macLocalized("mac.configuration.subtitle", fallback: "Adjust the memory card and confirm the result as you edit."),
                trailingTitle: macLocalized("mac.configuration.inspector", fallback: "Object Inspector"),
                trailingSystemImage: "slider.horizontal.3"
            ) {
                configurationInspectorRoute = .cardContent
            }

            MacIOSConfigurationEditor(
                session: session,
                commerceStore: commerceStore,
                presentationStyle: $presentationStyle,
                filmMarkConfiguration: $filmMarkConfiguration,
                filmMarkContentDraft: $filmMarkContentDraft,
                logoMode: $logoMode,
                customLogoBadge: $customLogoBadge,
                loadPhotoLibraryAlbums: loadPhotoLibraryAlbums,
                saveConfiguration: saveConfiguration,
                configurationCoordinator: configurationCoordinator,
                pendingMemoryPresetActivation: $pendingMemoryPresetActivation,
                configurationStatus: $configurationStatus,
                onPresetActivated: synchronizeSelectedPresetPresentation,
                inspectorRoute: $configurationInspectorRoute
            )
            .frame(
                maxWidth: MacConfigurationCenterMetrics.formWidth(
                    for: workspaceWidth
                )
            )
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var recentSituationSection: some View {
        MacRecentSituationSection(
            backgroundStatusService: backgroundStatusService
        )
    }

    private var subjectAvatarLogoImagePath: String? {
        session.state.selectedSubject?.identity.avatarBadgeImagePath
            ?? session.state.selectedSubject?.identity.avatarImagePath
    }

    private var customLogoImagePath: String? {
        customLogoBadge?.imagePath
            ?? session.selectedMemoryConfiguration?.presentation.logo.badge?.imageName
    }

    private func synchronizeSelectedPresetPresentation() {
        presentationStyle = session.selectedMemoryConfiguration?.presentation.route
            ?? .classicWhite
        filmMarkConfiguration = session.selectedMemoryConfiguration?.presentation.filmMark
            ?? .default
        logoMode = session.selectedMemoryConfiguration?.presentation.logo.mode
            ?? session.state.selectedMemoryPreset?.logoMode
            ?? .appleMini
    }

    private func bootstrapRuntimeIfNeeded() {
        guard !didBootstrapRuntime else {
            return
        }
        didBootstrapRuntime = true

        let flow = ConfigurationBootstrapFlowCoordinator(
            loadConfigurationState: {
                ConfigurationBootstrapCoordinator(
                    loadTransaction: loadConfigurationBootstrap
                ).loadState()
            },
            loadDrafts: { _, _ in [:] }
        )
        let patch = flow.bootstrap(
            hasSeenWelcome: true,
            fallbackBirthdayDate: Date(),
            makeDefaultDraft: { _ in
                MemoryCardEditorDraft(items: [.text("")])
            }
        )
        ConfigurationBootstrapRuntimeCoordinator(
            setApplyingBootstrapState: { _ in },
            updateProjection: { _ in },
            restoreSubjectLibrary: {
                subjects,
                selectedSubjectID,
                memoryPresets,
                selectedMemoryPresetID in
                session.restoreSubjectLibrary(
                    subjects,
                    selectedSubjectID: selectedSubjectID,
                    memoryPresets: memoryPresets,
                    selectedMemoryPresetID: selectedMemoryPresetID
                )
            },
            restoreConfigurationLibrary: { aggregate in
                session.restoreConfigurationLibrary(aggregate)
            },
            restoreSelectedSubject: { subject in
                session.restoreSelectedSubject(subject)
            },
            clearSession: {
                session.clearBootstrapContent()
            },
            applyWelcomeState: { _ in },
            refreshDynamicPreview: {}
        )
        .apply(patch)
    }
}

private enum MacConfigurationCenterMetrics {

    // The large-screen shell should use the available canvas as a workspace,
    // while retaining a small breathing margin around the preview card.
    static let workspaceWidthRatio: CGFloat = 0.92
    static let minimumWorkspaceWidth: CGFloat = 880
    static let maximumWorkspaceWidth: CGFloat = 1500
    static let pageHorizontalPadding: CGFloat = 24
    static let pageVerticalPadding: CGFloat = 20
    static let previewWidthRatio: CGFloat = 0.88
    static let maximumPreviewWidth: CGFloat = 1280
    static let maximumFormWidth: CGFloat = 1120

    static func workspaceWidth(for availableWidth: CGFloat) -> CGFloat {
        let availableWidth = max(0, availableWidth)
        let preferredWidth = availableWidth * workspaceWidthRatio
        return min(
            availableWidth,
            max(minimumWorkspaceWidth, min(preferredWidth, maximumWorkspaceWidth))
        )
    }

    static func previewWidth(for workspaceWidth: CGFloat) -> CGFloat {
        min(workspaceWidth * previewWidthRatio, maximumPreviewWidth)
    }

    static func formWidth(for workspaceWidth: CGFloat) -> CGFloat {
        min(workspaceWidth, maximumFormWidth)
    }
}

enum MacConfigurationCenterStyle {

    static let regionCornerRadius: CGFloat = 16
    static let regionBorder = Color.primary.opacity(0.14)
    static let regionBorderWidth: CGFloat = 1
}

struct MacConfigurationCenterSurface: ViewModifier {

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(ConfigurationUI.panelBackground)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        MacConfigurationCenterStyle.regionBorder,
                        lineWidth: MacConfigurationCenterStyle.regionBorderWidth
                    )
            )
    }
}

extension View {

    func macConfigurationCenterSurface(
        cornerRadius: CGFloat = MacConfigurationCenterStyle.regionCornerRadius
    ) -> some View {
        modifier(MacConfigurationCenterSurface(cornerRadius: cornerRadius))
    }
}

private struct MacConfigurationSectionHeader: View {

    let title: String
    let subtitle: String
    let trailingTitle: String?
    let trailingSystemImage: String?
    let action: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let trailingTitle, let trailingSystemImage {
                Button(action: action) {
                    Label(trailingTitle, systemImage: trailingSystemImage)
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(macLocalized("mac.help.inspector", fallback: "Open the object inspector for the selected region"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Hosts the actual iOS option list directly inside the macOS page. The
/// option list owns the disclosure grammar and selection controls; this host
/// only supplies the platform shell's state bindings and inline fallbacks for
/// controls that still have iOS-specific persistence coordinators.
private struct MacIOSConfigurationEditor: View {

    @EnvironmentObject
    private var undoCoordinator: MacConfigurationUndoCoordinator

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ObservedObject
    var session: ConfigurationSession

    @ObservedObject
    var commerceStore: MemoMarkCommerceStore

    @Binding
    var presentationStyle: RecordCardPresentationStyle

    @Binding
    var filmMarkConfiguration: FilmMarkConfiguration

    @Binding
    var filmMarkContentDraft: MemoryCardEditorDraft

    @Binding
    var logoMode: ConfigurationLogoMode

    @Binding
    var customLogoBadge: Badge?

    let loadPhotoLibraryAlbums:
        LoadPhotoLibraryAlbumsTransaction

    let saveConfiguration:
        SaveConfigurationTransaction

    let configurationCoordinator:
        ConfigurationCoordinator

    @Binding
    var pendingMemoryPresetActivation: MemoryPreset?

    @Binding
    var configurationStatus: ConfigurationPersistenceStatus

    let onPresetActivated: () -> Void

    @Binding
    var inspectorRoute: MacConfigurationWorkspaceRoute?

    @State private var disclosureState = ConfigurationDisclosureState()
    /// Matches iOS's independent FM authored-output draft. It is projected
    /// into `FilmMarkContentSchemaV2` on save and never aliases slot A.
    @State private var isFilmMarkGeometryExpanded = false
    @State private var selectedLogoItem: PhotosPickerItem?
    @State private var isLogoPickerPresented = false
    @State private var isOptimizingLogo = false
    @State private var logoStatusMessage = ""
    @State private var pendingMemoryDisplayStyle: MemoryAnchorExpressionStyle?
    @State private var selectedLocationOptionID = "legacyDisplay"
    @State private var selectedTimeOptionID = "daily"
    @State private var selectedTimeSupplement = TimeDisplayConfiguration.Supplement.none
    @State private var timeDisplayConfiguration =
        TimeDisplayInspectorPresenter.configuration(
            baseStyle: .daily,
            supplement: .none
        )
    @State private var outputTarget = ConfigurationOutputTarget.automatic
    @State private var selectedExistingAlbumIdentifier = ""
    @State private var newAlbumName = MemoMarkAlbumSelection.defaultAlbumTitle
    @State private var availableAlbums: [PhotoAlbumOption] = []
    @State private var isLoadingAlbums = false
    @State private var albumStatusMessage = ""
    @State private var shouldWritePhotosDescription = true
    @State private var outputAlbumRuntimeCoordinator = OutputAlbumRuntimeCoordinator()
    @State private var editingContext: MacConfigurationEditingContext?
    @State private var regionDraftsByPresentationStyle:
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]] = [:]
    @State private var showsUnsavedPresetActivationAlert = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            configurationHeader

            ConfigurationOptionList(
                disclosureState: $disclosureState,
                subjectAvatarLogoImagePath: subjectAvatarLogoImagePath,
                presentationStyle: presentationStyleBinding,
                filmMarkConfiguration: filmMarkConfigurationBinding,
                filmMarkOutputText: filmMarkContentDraft.singleLineText,
                isFilmMarkGeometryExpanded: $isFilmMarkGeometryExpanded,
                logoMode: $logoMode,
                selectedLogoItem: $selectedLogoItem,
                isLogoPickerPresented: $isLogoPickerPresented,
                logoValue: logoMode.title,
                customLogoImagePath: customLogoImagePath,
                isOptimizingLogo: isOptimizingLogo,
                timeAnchorTitle: session.currentTimeAnchorTitle,
                timeAnchorCount: session.availableTimeAnchors.count,
                availableTimeAnchors: session.availableTimeAnchors,
                selectedTimeAnchorID: selectedTimeAnchorBinding,
                locationPresentation: LocationDisplayInspectorPresenter.presentation,
                selectedLocationOptionID: selectedLocationOptionBinding,
                timePresentation: TimeDisplayInspectorPresenter.presentation,
                selectedTimeOptionID: selectedTimeOptionBinding,
                selectedTimeSupplement: selectedTimeSupplementBinding,
                memoryDisplayValue: memoryDisplayValue,
                memoryDisplayDetail: memoryDisplayDetail,
                availableMemoryDisplayStyles: availableMemoryDisplayStyles,
                selectedMemoryDisplayStyle: selectedMemoryDisplayStyleBinding,
                pendingMemoryDisplayStyle: $pendingMemoryDisplayStyle,
                commerceStore: commerceStore,
                isMemoryDisplayStyleLocked: isMemoryDisplayStyleLocked,
                onRequestMemoryDisplayCommerce: { _ in },
                output: configurationOutputBindings,
                configurationStatus: configurationStatus,
                onOpenRegionContent: {
                    inspectorRoute = .cardContent
                },
                onOpenAdvancedModules: {
                    inspectorRoute = .timeAndPlace
                },
                onOpenFilmMarkDetails: {
                    inspectorRoute = .filmMarkDetails
                }
            )

            logoStatus

        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .macConfigurationCenterSurface()
        .alert(
            MemoMarkLanguage.interfaceStored.localized(
                key: "configuration.unsaved_activation.title",
                fallback: "Unsaved changes"
            ),
            isPresented: $showsUnsavedPresetActivationAlert
        ) {
            Button(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "common.save_and_activate",
                    fallback: "Save and Use"
                )
            ) {
                saveCurrentConfigurationThenActivatePendingPreset()
            }
            Button(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "common.discard_and_activate",
                    fallback: "Discard Changes and Use"
                ),
                role: .destructive
            ) {
                discardCurrentConfigurationThenActivatePendingPreset()
            }
            Button(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "common.cancel",
                    fallback: "Cancel"
                ),
                role: .cancel
            ) {}
        } message: {
            Text(
                MemoMarkLanguage.interfaceStored.localized(
                    key: "configuration.unsaved_activation.message",
                    fallback: "Choose whether to save the current configuration before using another preset."
                )
            )
        }
        .onAppear(perform: synchronizeFromSession)
        .onAppear {
            undoCoordinator.setRestoreHandler { snapshot in
                applyDraftSnapshot(snapshot)
            }
        }
        .onChange(of: configurationStatus) { _, newValue in
            // Region drafts and inspector bindings are view-owned state. Keep
            // the same save fence as typed session edits so an async receipt
            // cannot commit over a newer macOS edit.
            if newValue.hasUncommittedChanges {
                session.markEditorChange()
            }
        }
        .onDisappear {
            undoCoordinator.clearRestoreHandler()
        }
        .onChange(of: session.state.selectedSubjectID) { _, _ in
            synchronizeFromSession()
        }
        .onChange(of: session.state.selectedMemoryPresetID) { _, _ in
            synchronizeFromSession()
        }
        .onChange(of: selectedLogoItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await optimizeSelectedLogo(item)
            }
        }
        .onChange(of: pendingMemoryPresetActivation) { _, preset in
            guard let preset else { return }
            Task { @MainActor in
                await activateMemoryPreset(preset)
            }
        }
        .inspector(isPresented: inspectorPresentedBinding) {
            if let route = inspectorRoute {
                MacConfigurationInspector(
                    route: route,
                    session: session,
                    commerceStore: commerceStore,
                    configurationCoordinator: configurationCoordinator,
                    saveConfiguration: saveConfiguration,
                    configurationStatus: $configurationStatus,
                    onSelectPreset: { preset in
                        requestMemoryPresetSelection(preset)
                    },
                    onInsertModule: insertModule,
                    onDraftChange: recordDraftChange,
                    selectedLocationOptionID: selectedLocationOptionBinding,
                    selectedTimeOptionID: selectedTimeOptionBinding,
                    selectedTimeSupplement: selectedTimeSupplementBinding,
                    filmMarkConfiguration: $filmMarkConfiguration,
                    filmMarkContentDraft: $filmMarkContentDraft,
                    onSaveCardContent: {
                        Task { await saveCurrentConfiguration() }
                    },
                    regionDrafts: $regionDraftsByPresentationStyle,
                    presentationStyle: presentationStyle,
                    onDirty: {
                        configurationStatus = .dirty
                    },
                    presentation: .inspector
                )
            }
        }
    }

    private var configurationHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.currentMemoryPresetTitle)
                    .font(.headline.weight(.semibold))
                Text(configurationStatus.message(for: .preset))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Button {
                Task { await saveCurrentConfiguration() }
            } label: {
                Label(macLocalized("mac.configurationCenter.save_changes", fallback: "Save Changes"), systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("s", modifiers: .command)
            .disabled(configurationStatus.isSaving)
            .accessibilityIdentifier("mac.configurationCenter.save")
        }
    }

    private var inspectorPresentedBinding: Binding<Bool> {
        Binding(
            get: { inspectorRoute != nil },
            set: { isPresented in
                if !isPresented {
                    inspectorRoute = nil
                }
            }
        )
    }

    @ViewBuilder
    private var logoStatus: some View {
        if !logoStatusMessage.isEmpty {
            Text(logoStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("mac.configurationCenter.logoStatus")
        }
    }

    private var presentationStyleBinding: Binding<RecordCardPresentationStyle> {
        Binding(
            get: { presentationStyle },
            set: {
                presentationStyle = $0
                configurationStatus = .dirty
            }
        )
    }

    private var filmMarkConfigurationBinding:
        Binding<FilmMarkConfiguration> {
        Binding(
            get: { filmMarkConfiguration },
            set: {
                filmMarkConfiguration = $0
                configurationStatus = .dirty
            }
        )
    }

    private var selectedTimeAnchorBinding: Binding<UUID> {
        Binding(
            get: {
                session.selectedTimeAnchorID
                    ?? session.availableTimeAnchors.first?.id
                    ?? UUID()
            },
            set: {
                session.selectTimeAnchor(id: $0)
                configurationStatus = .dirty
            }
        )
    }

    private var selectedLocationOptionBinding: Binding<String> {
        Binding(
            get: { selectedLocationOptionID },
            set: {
                selectedLocationOptionID = $0
                configurationStatus = .dirty
            }
        )
    }

    private var selectedTimeOptionBinding: Binding<String> {
        Binding(
            get: { selectedTimeOptionID },
            set: {
                selectedTimeOptionID = $0
                updateTimeDisplayConfiguration(
                    baseStyle: TimeDisplayConfiguration.BaseStyle(
                        rawValue: $0
                    ) ?? .daily,
                    supplement: selectedTimeSupplement
                )
                configurationStatus = .dirty
            }
        )
    }

    private var selectedTimeSupplementBinding:
        Binding<TimeDisplayConfiguration.Supplement> {
        Binding(
            get: { selectedTimeSupplement },
            set: {
                selectedTimeSupplement = $0
                updateTimeDisplayConfiguration(
                    baseStyle: currentTimeDisplayBaseStyle,
                    supplement: $0
                )
                configurationStatus = .dirty
            }
        )
    }

    private var selectedMemoryDisplayStyleBinding: Binding<MemoryAnchorExpressionStyle> {
        Binding(
            get: {
                session.state.selectedSubject?.primaryTimeAnchor?
                    .resolvedExpressionStyle ?? .birthdayNatural
            },
            set: {
                session.selectCurrentTimeAnchorExpressionStyle($0)
                pendingMemoryDisplayStyle = nil
                configurationStatus = .dirty
            }
        )
    }

    private var customMemoryWriteTextBinding: Binding<String> {
        Binding(
            get: { session.customMemoryWriteText },
            set: {
                session.customMemoryWriteText = $0
                configurationStatus = .dirty
            }
        )
    }

    private var outputTargetBinding: Binding<ConfigurationOutputTarget> {
        Binding(
            get: { outputTarget },
            set: {
                outputTarget = $0
                configurationStatus = .dirty
                if $0 == .existingAlbum {
                    reloadAlbums()
                }
            }
        )
    }

    private var selectedExistingAlbumBinding: Binding<String> {
        Binding(
            get: { selectedExistingAlbumIdentifier },
            set: {
                selectedExistingAlbumIdentifier = $0
                configurationStatus = .dirty
            }
        )
    }

    private var newAlbumNameBinding: Binding<String> {
        Binding(
            get: { newAlbumName },
            set: {
                newAlbumName = $0
                configurationStatus = .dirty
            }
        )
    }

    private var usesCustomMemoryWriteTextBinding: Binding<Bool> {
        Binding(
            get: { session.usesCustomMemoryWriteText },
            set: {
                session.usesCustomMemoryWriteText = $0
                configurationStatus = .dirty
            }
        )
    }

    private var subjectAvatarLogoImagePath: String? {
        session.state.selectedSubject?.identity.avatarBadgeImagePath
            ?? session.state.selectedSubject?.identity.avatarImagePath
    }

    private var customLogoImagePath: String? {
        customLogoBadge?.imagePath
            ?? session.selectedMemoryConfiguration?.presentation.logo.badge?.imageName
    }

    private var availableMemoryDisplayStyles: [MemoryAnchorExpressionStyle] {
        ConfigurationCenterMemoryDisplaySupport.availableStyles(
            subject: session.state.selectedSubject,
            accessSource: commerceStore.snapshot.accessSource
        )
    }

    private func isMemoryDisplayStyleLocked(
        _ style: MemoryAnchorExpressionStyle
    ) -> Bool {
        !MemoMarkCommerceCapability.allowsFirstPartyExpressionStyle(
            style,
            snapshot: commerceStore.snapshot
        )
    }

    private var configurationOutputBindings: ConfigurationOutputBindings {
        ConfigurationOutputBindings(
            outputTarget: outputTargetBinding,
            availableAlbums: availableAlbums,
            selectedExistingAlbumIdentifier: selectedExistingAlbumBinding,
            newAlbumName: newAlbumNameBinding,
            isLoadingAlbums: isLoadingAlbums,
            albumStatusMessage: albumStatusMessage,
            onReloadAlbums: reloadAlbums,
            usesCustomMemoryWriteText: usesCustomMemoryWriteTextBinding,
            customMemoryWriteText: customMemoryWriteTextBinding,
            shouldWritePhotosDescription: shouldWritePhotosDescription,
            resolvedMemoryWriteText: session.resolvedMemoryWriteText
        )
    }

    private var memoryDisplayValue: String {
        pendingMemoryDisplayStyle?.displayTitle
            ?? ConfigurationCenterMemoryDisplaySupport.summaryValue(
                subject: session.state.selectedSubject,
                language: .interfaceStored
            )
    }

    private var memoryDisplayDetail: String {
        ConfigurationCenterMemoryDisplaySupport.summaryDetail(
            subject: session.state.selectedSubject,
            style: pendingMemoryDisplayStyle,
            language: .interfaceStored
        )
    }

    private func synchronizeFromSession() {
        let savedConfiguration = session.selectedMemoryConfiguration
        let nextContext = MacConfigurationEditingContext(
            subjectID: session.state.selectedSubjectID,
            configuration: savedConfiguration
        )
        guard nextContext.requiresProjection(comparedWith: editingContext) else {
            return
        }
        let savedProjection = savedConfiguration.map {
            ConfigurationDraftProjection(configuration: $0)
        }
        presentationStyle = savedConfiguration?.presentation.route
            ?? .classicWhite
        filmMarkConfiguration = savedConfiguration?.presentation.filmMark
            ?? .default
        filmMarkContentDraft = savedProjection?.filmMarkContentDraft
            ?? MemoryCardEditorDraft(items: [])
        logoMode = savedConfiguration?.presentation.logo.mode
            ?? session.state.selectedMemoryPreset?.logoMode
            ?? .appleMini
        customLogoBadge = savedProjection?.badge
        editingContext = nextContext
        regionDraftsByPresentationStyle =
            savedProjection?.regionDraftsByPresentationStyle
            ?? defaultRegionDraftsByPresentationStyle()
        undoCoordinator.reset(
            to: MacConfigurationDraftSnapshot(
                regionDraftsByPresentationStyle: regionDraftsByPresentationStyle
            )
        )
        timeDisplayConfiguration =
            configurationCoordinator.loadTimeDisplayConfiguration()
            ?? TimeDisplayInspectorPresenter.configuration(
                baseStyle: .daily,
                supplement: .none
            )
        selectedTimeOptionID =
            timeDisplayConfiguration.options["baseStyle"] ?? "daily"
        selectedTimeSupplement =
            TimeDisplayConfiguration.Supplement(
                rawValue:
                timeDisplayConfiguration.options["supplement"] ?? "none"
            ) ?? .none
        configurationStatus =
            MacConfigurationEditingContext.statusAfterProjection(
                isDurable: session.selectedMemoryPresetIsDurable
            )
        logoStatusMessage = ""
        shouldWritePhotosDescription = savedConfiguration?
            .output.photosDescriptionPolicy.isEnabled ?? true
        if let savedProjection {
            outputTarget = savedProjection.outputTarget
            selectedExistingAlbumIdentifier =
                savedProjection.selectedAlbumIdentifier
            newAlbumName = savedProjection.albumTitle.isEmpty
                ? MemoMarkAlbumSelection.defaultAlbumTitle
                : savedProjection.albumTitle
            selectedLocationOptionID =
                LocationDisplayInspectorPresenter
                .selectedOptionID(
                    fromConfiguration:
                        savedProjection.locationConfiguration
                )
        } else {
            outputTarget = .automatic
            selectedExistingAlbumIdentifier = ""
            newAlbumName = MemoMarkAlbumSelection.defaultAlbumTitle
            selectedLocationOptionID = "legacyDisplay"
        }
    }

    private var currentTimeDisplayBaseStyle:
        TimeDisplayConfiguration.BaseStyle {
        TimeDisplayConfiguration.BaseStyle(
            rawValue: timeDisplayConfiguration.options["baseStyle"]
                ?? selectedTimeOptionID
        ) ?? .daily
    }

    private func updateTimeDisplayConfiguration(
        baseStyle: TimeDisplayConfiguration.BaseStyle,
        supplement: TimeDisplayConfiguration.Supplement
    ) {
        timeDisplayConfiguration =
            TimeDisplayInspectorPresenter.configuration(
                baseStyle: baseStyle,
                supplement: supplement
            )
        _ = configurationCoordinator
            .saveTimeDisplayConfiguration(timeDisplayConfiguration)
    }

    private func defaultRegionDraftsByPresentationStyle()
        -> [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]] {
        let fallback = ConfigurationDraftProjection.makeRegionDrafts(
            from: Template.classicWhite,
            interfaceLanguage: .interfaceStored
        )
        return Dictionary(
            uniqueKeysWithValues:
                RecordCardPresentationStyle.allCases.map {
                    ($0, fallback)
                }
        )
    }

    private func requestMemoryPresetSelection(_ preset: MemoryPreset) {
        guard preset.id != session.state.selectedMemoryPresetID else {
            return
        }

        Task { @MainActor in
            await activateMemoryPreset(preset)
        }
    }

    private func insertModule(_ module: CenterInsertableModule) {
        let region = session.smartModuleCarrierRegion
        let before = regionDraftsByPresentationStyle
        var drafts = regionDraftsByPresentationStyle[presentationStyle]
            ?? defaultRegionDraftsByPresentationStyle()[presentationStyle]
            ?? [:]
        var draft = drafts[region]
            ?? MemoryCardEditorDraft(items: [.text("")])
        draft.appendComposedItem(
            .token(
                module.title,
                value: module.previewValue,
                templateValue: module.centerToken,
                systemImage: module.systemImage
            )
        )
        drafts[region] = draft
        regionDraftsByPresentationStyle[presentationStyle] = drafts
        undoCoordinator.record(
            before: MacConfigurationDraftSnapshot(
                regionDraftsByPresentationStyle: before
            ),
            after: MacConfigurationDraftSnapshot(
                regionDraftsByPresentationStyle: regionDraftsByPresentationStyle
            )
        )
        session.appendPreviewModule(
            title: module.title,
            value: module.previewValue,
            systemImage: module.systemImage,
            token: module.centerToken
        )
        configurationStatus = .dirty
    }

    private func recordDraftChange(
        region: CardRegion,
        before: MemoryCardEditorDraft,
        after: MemoryCardEditorDraft
    ) {
        var beforeDrafts = regionDraftsByPresentationStyle
        var afterDrafts = beforeDrafts
        var beforeStyleDrafts = beforeDrafts[presentationStyle] ?? [:]
        beforeStyleDrafts[region] = before
        beforeDrafts[presentationStyle] = beforeStyleDrafts
        var afterStyleDrafts = afterDrafts[presentationStyle] ?? [:]
        afterStyleDrafts[region] = after
        afterDrafts[presentationStyle] = afterStyleDrafts
        undoCoordinator.record(
            before: MacConfigurationDraftSnapshot(
                regionDraftsByPresentationStyle: beforeDrafts
            ),
            after: MacConfigurationDraftSnapshot(
                regionDraftsByPresentationStyle: afterDrafts
            )
        )
    }

    private func applyDraftSnapshot(
        _ snapshot: MacConfigurationDraftSnapshot
    ) {
        regionDraftsByPresentationStyle =
            snapshot.regionDraftsByPresentationStyle
        for (style, drafts) in snapshot.regionDraftsByPresentationStyle
        where style == presentationStyle {
            for (region, draft) in drafts {
                session.updateRegionPreview(
                    region: region,
                    text: draft.singleLineText
                )
            }
        }
        configurationStatus = .dirty
    }

    private func macOutputTarget(
        _ destination: MemoryConfigurationRecord.Output.AlbumDescriptor.Destination
    ) -> ConfigurationOutputTarget {
        switch destination {
        case .automatic: return .automatic
        case .applePhotos: return .applePhotos
        case .existingAlbum: return .existingAlbum
        case .newAlbum: return .newAlbum
        }
    }

    private func reloadAlbums() {
        let context = OutputAlbumLoadContext(
            subjectID: session.state.selectedSubject?.id,
            configurationID: session.state.selectedMemoryPresetID,
            outputTarget: outputTarget,
            selectedExistingAlbumIdentifier:
                selectedExistingAlbumIdentifier
        )
        let currentAlbums = availableAlbums
        let selectedIdentifier = selectedExistingAlbumIdentifier
        Task {
            await outputAlbumRuntimeCoordinator.load(
                context: context,
                performLoad: {
                    await ExportAlbumLoadingPresenter.loadProjection(
                        currentAvailableAlbums: currentAlbums,
                        selectedExistingAlbumIdentifier: selectedIdentifier,
                        transaction: loadPhotoLibraryAlbums
                    )
                },
                currentContext: {
                    OutputAlbumLoadContext(
                        subjectID: session.state.selectedSubject?.id,
                        configurationID: session.state.selectedMemoryPresetID,
                        outputTarget: outputTarget,
                        selectedExistingAlbumIdentifier:
                            selectedExistingAlbumIdentifier
                    )
                },
                apply: { update in
                    switch update {
                    case .loadingStarted:
                        isLoadingAlbums = true
                    case .loadingEnded:
                        isLoadingAlbums = false
                    case .completed(let projection):
                        isLoadingAlbums = false
                        availableAlbums = projection.availableAlbums
                        selectedExistingAlbumIdentifier =
                            projection.selectedExistingAlbumIdentifier
                        albumStatusMessage = projection.albumStatusMessage
                    }
                }
            )
        }
    }

    @MainActor
    private func optimizeSelectedLogo(_ item: PhotosPickerItem) async {
        selectedLogoItem = nil
        let runtimeCoordinator = LogoAssetRuntimeCoordinator()
        await runtimeCoordinator.optimize(
            editingContext: LogoAssetEditingContext(
                subjectID: session.state.selectedSubject?.id,
                configurationID: session.state.selectedMemoryPresetID
            ),
            performOptimization: {
                await LogoAssetCoordinator().optimize(item)
            },
            currentContext: {
                LogoAssetEditingContext(
                    subjectID: session.state.selectedSubject?.id,
                    configurationID: session.state.selectedMemoryPresetID
                )
            },
            discardUnappliedAsset: { badge in
                guard let path = badge?.imagePath else {
                    return
                }
                LogoAssetOptimizationService
                    .discardUncommittedAsset(atPath: path)
            },
            apply: { update in
                isOptimizingLogo = update.isOptimizingLogo
                if let badge = update.customLogoBadge {
                    customLogoBadge = badge
                }
                if let logoMode = update.logoMode {
                    self.logoMode = logoMode
                }
                logoStatusMessage = update.logoStatusMessage
                if update.activeConfigurationStatus != nil {
                    configurationStatus = .dirty
                }
            }
        )
    }

    @MainActor
    private func activateMemoryPreset(_ preset: MemoryPreset) async {
        if configurationStatus.hasUncommittedChanges {
            showsUnsavedPresetActivationAlert = true
            return
        }

        await activateMemoryPresetNow(preset)
    }

    @MainActor
    private func activateMemoryPresetNow(_ preset: MemoryPreset) async {

        guard await setProcessingDefault(configurationID: preset.id) else {
            return
        }

        pendingMemoryPresetActivation = nil
        showsUnsavedPresetActivationAlert = false
        session.selectMemoryPreset(preset)
        onPresetActivated()
    }

    @MainActor
    private func saveCurrentConfigurationThenActivatePendingPreset() {
        guard let preset = pendingMemoryPresetActivation else {
            return
        }
        Task { @MainActor in
            guard await saveCurrentConfiguration() else {
                return
            }
            await activateMemoryPresetNow(preset)
        }
    }

    @MainActor
    private func discardCurrentConfigurationThenActivatePendingPreset() {
        guard let preset = pendingMemoryPresetActivation else {
            return
        }
        _ = session.discardSelectedMemoryPresetChanges()
        synchronizeFromSession()
        configurationStatus = .saved
        Task { @MainActor in
            await activateMemoryPresetNow(preset)
        }
    }

    @MainActor
    private func setProcessingDefault(
        configurationID: MemoryPreset.ID
    ) async -> Bool {
        guard !configurationStatus.isSaving,
              configurationStatus.isProcessingProjectionReady,
              let subjectID = session.state.selectedSubject?.id,
              let aggregate = session.state.configurationLibrary else {
            return false
        }

        configurationStatus = .saving

        do {
            let transaction = ActivateConfigurationTransaction(
                configurationCoordinator: configurationCoordinator
            )
            let result = try await transaction.apply(
                ActivateConfigurationCommand(
                    subjectID: subjectID,
                    configurationID: configurationID
                ),
                in: aggregate
            )
            let receipt = result.saveReceipt
            session.updateConfigurationLibraryReference(result.candidate)
            session.processingDefaultMemoryPresetID = configurationID
            configurationStatus = receipt.compatibilityProjectionFailure == nil
                ? .saved
                : .savedWithWarning(
                    message: macLocalized("mac.configuration.save_compatibility_warning", fallback: "The default configuration was saved, but compatibility settings could not be fully synchronized.")
                )
            return configurationStatus.isDurablySaved
        } catch {
            configurationStatus = .failure(
                message: macLocalized("mac.configuration.activate_failed", fallback: "Could not make this the current configuration. Try again.")
            )
            return false
        }
    }

    @MainActor
    private func saveCurrentConfiguration() async -> Bool {
        guard let configurationLibrary = session.state.configurationLibrary,
              let savedConfiguration = session.selectedMemoryConfiguration
        else {
            configurationStatus = .failure(message: macLocalized("mac.configuration.load_failed", fallback: "The current configuration has not finished loading."))
            return false
        }

        let savedProjection = ConfigurationDraftProjection(
            configuration: savedConfiguration
        )
        let aggregateDraft = ConfigurationAggregateDraft(
            title: savedProjection.title,
            regionDrafts:
                regionDraftsByPresentationStyle[presentationStyle]
                ?? savedProjection.regionDrafts,
            regionDraftsByPresentationStyle:
                regionDraftsByPresentationStyle.isEmpty
                ? savedProjection.regionDraftsByPresentationStyle
                : regionDraftsByPresentationStyle,
            regionTemplateIDs: savedProjection.regionTemplateIDs,
            locationConfiguration:
                LocationDisplayInspectorPresenter.configuration(
                    for: selectedLocationOptionID
                ),
            logoMode: logoMode,
            badge: selectedBadgeForSaving(
                projection: savedProjection
            ),
            usesCustomMemoryWriteText: session.usesCustomMemoryWriteText,
            customMemoryWriteText: session.customMemoryWriteText,
            shouldWritePhotosDescription: shouldWritePhotosDescription,
            photosDescriptionOverride:
                savedProjection.photosDescriptionOverride,
            outputTarget: outputTarget,
            selectedAlbumIdentifier: selectedExistingAlbumIdentifier,
            albumTitle: outputTarget == .newAlbum
                ? newAlbumName
                : savedProjection.albumTitle,
            mediaOutputMode: .originalFormat,
            livePhotoPolicy: .preserveMotion,
            presentationRoute: presentationStyle,
            filmMarkConfiguration: filmMarkConfiguration,
            filmMarkContentDraft: filmMarkContentDraft,
            selectedTimeAnchorID: session.selectedTimeAnchorID,
            savedAt: Date(),
            language: session.language
        )
        let saveRuntime = ConfigurationSaveRuntimeCoordinator(
            coordinator: saveConfiguration,
            reloadAlbums: {
                reloadAlbums()
            },
            setOutputTarget: { outputTarget = $0 },
            setSelectedExistingAlbumIdentifier: {
                selectedExistingAlbumIdentifier = $0
            },
            restoreSubject: { session.restoreSelectedSubject($0) },
            reconcileConfigurationLibrary: { candidate, receipt in
                session.reconcileConfigurationLibrarySave(
                    candidate: candidate,
                    receipt: receipt
                )
            },
            reconcileConfigurationLibraryWithGeneration: {
                candidate,
                receipt,
                editorGeneration in
                session.reconcileConfigurationLibrarySave(
                    candidate: candidate,
                    receipt: receipt,
                    editorGeneration: editorGeneration
                )
            },
            applySelectedMemoryPreset: {},
            updateStatus: { status in
                configurationStatus = status.status
            }
        )

        let didSave = await saveRuntime.applyAggregate(
            configurationLibrary: configurationLibrary,
            aggregateDraft: aggregateDraft,
            availableAlbums: availableAlbums,
            editorGeneration: session.editorGeneration
        )
        synchronizeFromSession()
        return didSave && configurationStatus.isDurablySaved
    }

    private func selectedBadgeForSaving(
        projection: ConfigurationDraftProjection
    ) -> Badge {
        switch logoMode {
        case .appleMini:
            return .appleClassic
        case .customUpload:
            return customLogoBadge ?? projection.badge ?? .none
        case .subjectAvatar:
            return .none
        }
    }
}

private struct MacCardContentInspector: View {

    @ObservedObject var session: ConfigurationSession
    @ObservedObject var commerceStore: MemoMarkCommerceStore
    let onSelectMemoryPreset: (MemoryPreset) -> Void
    let onSaveMemoryPreset: () -> Void
    let onInsertModule: (CenterInsertableModule) -> Void
    let regionDrafts: Binding<
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]
    >?
    let presentationStyle: RecordCardPresentationStyle?
    let filmMarkContentDraft: Binding<MemoryCardEditorDraft>?
    let onDraftChange:
        (CardRegion, MemoryCardEditorDraft, MemoryCardEditorDraft) -> Void
    let onDirty: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Label(macLocalized("mac.configurationCenter.cardContent.editor", fallback: "Card Content Editor"), systemImage: "rectangle.3.group")
                    .font(.headline.weight(.semibold))
                Spacer()
                Button(macLocalized("mac.configurationCenter.save", fallback: "Save"), action: onSaveMemoryPreset)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }

            Text(macLocalized("mac.editor.card_content.description", fallback: "Each region maps to a real position in the preview. You choose the text and where modules appear."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let filmMarkContentDraft,
               presentationStyle == .filmMark {
                MacFilmMarkContentDraftEditor(
                    session: session,
                    draft: filmMarkContentDraft,
                    onDirty: onDirty
                )
            } else if let regionDrafts, let presentationStyle {
                MacRegionDraftEditor(
                    session: session,
                    presentationStyle: presentationStyle,
                    regionDrafts: regionDrafts,
                    onInsertModule: onInsertModule,
                    onDraftChange: onDraftChange,
                    onDirty: onDirty
                )
            } else {
                InteractiveMemoryCard(
                    session: session,
                    commerceStore: commerceStore,
                    onSelectMemoryPreset: onSelectMemoryPreset,
                    onSaveMemoryPreset: onSaveMemoryPreset,
                    onInsertModule: onInsertModule
                )
                .previewContent

                Text(macLocalized("mac.editor.card_content.instruction", fallback: "Open Card Content from the configuration sections to edit the four regions directly."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(ConfigurationUI.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: ConfigurationUI.cardCornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ConfigurationUI.cardCornerRadius, style: .continuous).stroke(MacConfigurationCenterStyle.regionBorder, lineWidth: MacConfigurationCenterStyle.regionBorderWidth))
    }
}

private struct MacFilmMarkContentDraftEditor: View {

    @ObservedObject
    var session: ConfigurationSession

    @Binding
    var draft: MemoryCardEditorDraft

    let onDirty: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(macLocalized("mac.editor.film_mark.title", fallback: "FilmMark Content"))
                .font(.subheadline.weight(.semibold))
            Text(macLocalized("mac.editor.film_mark.description", fallback: "This content is independent from Classic card regions and is used for preview, saving, and output."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            MacRegionDraftRow(
                session: session,
                region: .slotA,
                draft: $draft,
                onInsertModule: { module in
                    draft.appendComposedItem(
                        .token(
                            module.title,
                            value: module.previewValue,
                            templateValue: module.centerToken,
                            systemImage: module.systemImage
                        )
                    )
                    onDirty()
                },
                onDirty: onDirty
            )
        }
        .padding(.top, 4)
        .accessibilityIdentifier("mac.configurationCenter.filmMarkContent.editor")
    }
}

private struct MacRegionDraftEditor: View {

    @ObservedObject
    var session: ConfigurationSession

    let presentationStyle: RecordCardPresentationStyle
    let regionDrafts: Binding<
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]
    >
    let onInsertModule: (CenterInsertableModule) -> Void
    let onDraftChange:
        (CardRegion, MemoryCardEditorDraft, MemoryCardEditorDraft) -> Void
    let onDirty: () -> Void

    private var editableRegions: [CardRegion] {
        CardRegion.editableRegions(for: presentationStyle)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(editableRegions, id: \.self) { region in
                MacRegionDraftRow(
                    session: session,
                    region: region,
                    draft: draftBinding(for: region),
                    onInsertModule: { module in
                        session.select(CardRegionBehavior(region: region))
                        onInsertModule(module)
                        onDirty()
                    },
                    onDirty: onDirty
                )
                .id(region)
            }
        }
        .accessibilityIdentifier("mac.configurationCenter.cardContent.editor")
    }

    private func draftBinding(for region: CardRegion) -> Binding<MemoryCardEditorDraft> {
        Binding(
            get: {
                regionDrafts.wrappedValue[presentationStyle]?[region]
                    ?? MemoryCardEditorDraft(items: [.text("")])
            },
            set: { nextDraft in
                var byStyle = regionDrafts.wrappedValue
                var drafts = byStyle[presentationStyle] ?? [:]
                let previousDraft = drafts[region]
                    ?? MemoryCardEditorDraft(items: [.text("")])
                onDraftChange(region, previousDraft, nextDraft)
                drafts[region] = nextDraft
                byStyle[presentationStyle] = drafts
                regionDrafts.wrappedValue = byStyle
                session.updateRegionPreview(
                    region: region,
                    text: nextDraft.singleLineText
                )
            }
        )
    }
}

private struct MacRegionDraftRow: View {

    @ObservedObject
    var session: ConfigurationSession

    let region: CardRegion
    @Binding var draft: MemoryCardEditorDraft
    let onInsertModule: (CenterInsertableModule) -> Void
    let onDirty: () -> Void

    @FocusState
    private var focusedTextItemID: UUID?

    @State
    private var shouldFocusTrailingTextInput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            editorStrip
        }
        .padding(12)
        .background(ConfigurationUI.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(cardBorder)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button {
                session.select(CardRegionBehavior(region: region))
            } label: {
                Label(region.semanticTitle, systemImage: "rectangle.3.group")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("mac.configurationCenter.cardContent.\(region.rawValue)")

            Text(region.editorSubtitle ?? macLocalized("mac.editor.region.default_subtitle", fallback: "Edit this region's text and modules"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            Menu {
                ForEach(availableModules) { module in
                    Button {
                        shouldFocusTrailingTextInput = true
                        onInsertModule(module)
                    } label: {
                        Label(module.title, systemImage: module.systemImage)
                    }
                }
            } label: {
                Label(macLocalized("mac.editor.insert_module", fallback: "Insert Module"), systemImage: "plus")
                    .font(.caption.weight(.semibold))
            }
            .menuStyle(.borderlessButton)
            .help(macLocalized("mac.editor.insert_module.help", fallback: "Insert into the \(region.semanticTitle) region"))
        }
    }

    private var editorStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(draft.items) { item in
                        itemEditor(item)
                            .id(item.id)
                    }

                    Button {
                        var nextDraft = draft
                        let itemID = nextDraft.appendTextInput()
                        draft = nextDraft
                        session.updateRegionPreview(
                            region: region,
                            text: nextDraft.singleLineText
                        )
                        onDirty()
                        focusedTextItemID = itemID
                        withAnimation(.snappy) {
                            proxy.scrollTo(itemID, anchor: .trailing)
                        }
                    } label: {
                        Label(macLocalized("mac.editor.text", fallback: "Text"), systemImage: "text.cursor")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.vertical, 2)
            }
            .onChange(of: focusedTextItemID) { _, itemID in
                guard let itemID else {
                    return
                }
                withAnimation(.snappy) {
                    proxy.scrollTo(itemID, anchor: .center)
                }
            }
            .onChange(of: draft.items) { _, _ in
                guard shouldFocusTrailingTextInput else {
                    return
                }
                shouldFocusTrailingTextInput = false
                guard let itemID = draft.items.last(where: { $0.kind == .text })?.id else {
                    return
                }
                focusedTextItemID = itemID
                withAnimation(.snappy) {
                    proxy.scrollTo(itemID, anchor: .trailing)
                }
            }
        }
        .frame(minHeight: 42)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.10))
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                session.state.selectedRegion == region
                    ? Color.accentColor.opacity(0.46)
                    : Color.primary.opacity(0.10),
                lineWidth: session.state.selectedRegion == region ? 1.5 : 1
            )
    }

    @ViewBuilder
    private func itemEditor(_ item: MemoryCardContentItem) -> some View {
        switch item.kind {
        case .text:
            TextField(
                macLocalized("mac.editor.text.placeholder", fallback: "Enter text"),
                text: textBinding(for: item)
            )
            .textFieldStyle(.roundedBorder)
            .focused($focusedTextItemID, equals: item.id)
            .frame(minWidth: max(120, min(280, CGFloat(max(item.value.count, 6)) * 12)))
            .accessibilityIdentifier(
                "mac.configurationCenter.cardContent.\(region.rawValue).text.\(item.id.uuidString)"
            )

        case .token, .separator, .lineBreak:
            Label(
                item.kind == .lineBreak ? macLocalized("mac.editor.line_break", fallback: "Line Break") : item.title,
                systemImage: item.systemImage
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(item.isUnresolvedModule ? .orange : .accentColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        (item.isUnresolvedModule ? Color.orange : Color.accentColor)
                            .opacity(0.12)
                    )
            )
            .help(item.value.isEmpty ? item.title : item.value)
            .contextMenu {
                Button(macLocalized("mac.editor.remove_module", fallback: "Remove Module"), role: .destructive) {
                    remove(item)
                }
            }
        }
    }

    private func remove(_ item: MemoryCardContentItem) {
        var nextDraft = draft
        nextDraft.items.removeAll { $0.id == item.id }
        nextDraft.normalizeTrailingTextInput()
        draft = nextDraft
        session.updateRegionPreview(
            region: region,
            text: nextDraft.singleLineText
        )
        onDirty()
    }

    private func textBinding(for item: MemoryCardContentItem) -> Binding<String> {
        Binding(
            get: { item.value },
            set: { nextText in
                var nextDraft = draft
                nextDraft.updateTextItem(item, text: nextText)
                draft = nextDraft
                session.updateRegionPreview(
                    region: region,
                    text: nextDraft.singleLineText
                )
                onDirty()
            }
        )
    }

    private var availableModules: [CenterInsertableModule] {
        CenterInsertableModule.allCases.filter {
            $0 != .custom && $0.isProductionBacked
        }
    }
}

private struct MacTimeAndPlaceInspector: View {

    let selectedLocationOptionID: Binding<String>
    let selectedTimeOptionID: Binding<String>
    let selectedTimeSupplement: Binding<TimeDisplayConfiguration.Supplement>
    let onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(macLocalized("mac.configurationCenter.currentSituation", fallback: "Time and Place"), systemImage: "clock.badge.checkmark")
                    .font(.headline.weight(.semibold))
                Spacer()
            }

            Picker(macLocalized("mac.editor.location_display", fallback: "Location Display"), selection: selectedLocationOptionID) {
                ForEach(LocationDisplayInspectorPresenter.presentation.options) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.menu)

            Picker(macLocalized("mac.editor.time_display", fallback: "Time Display"), selection: selectedTimeOptionID) {
                ForEach(TimeDisplayInspectorPresenter.presentation.options) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .pickerStyle(.menu)

            Picker(macLocalized("mac.editor.date_supplement", fallback: "Date Supplement"), selection: selectedTimeSupplement) {
                Text(macLocalized("mac.editor.date_supplement.none", fallback: "None")).tag(TimeDisplayConfiguration.Supplement.none)
                Text(macLocalized("mac.editor.date_supplement.lunar", fallback: "Lunar Calendar")).tag(TimeDisplayConfiguration.Supplement.lunar)
                Text(macLocalized("mac.editor.date_supplement.lunar_solar_term", fallback: "Lunar Calendar · Solar Term")).tag(TimeDisplayConfiguration.Supplement.lunarAndSolarTerm)
                Text(macLocalized("mac.editor.date_supplement.holiday", fallback: "Holiday")).tag(TimeDisplayConfiguration.Supplement.holiday)
                Text(macLocalized("mac.editor.date_supplement.statutory_holiday", fallback: "Public Holiday")).tag(TimeDisplayConfiguration.Supplement.statutoryHoliday)
            }
            .pickerStyle(.menu)
        }
        .padding(14)
        .background(ConfigurationUI.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: ConfigurationUI.cardCornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: ConfigurationUI.cardCornerRadius, style: .continuous).stroke(MacConfigurationCenterStyle.regionBorder, lineWidth: MacConfigurationCenterStyle.regionBorderWidth))
        .onChange(of: selectedLocationOptionID.wrappedValue) { _, _ in
            onChange()
        }
        .onChange(of: selectedTimeOptionID.wrappedValue) { _, _ in
            onChange()
        }
        .onChange(of: selectedTimeSupplement.wrappedValue) { _, _ in
            onChange()
        }
    }
}

// These small platform adapters keep the iOS option list's information
// architecture shared without importing UIKit-only support views into the
// macOS target. Their values and interaction semantics remain the same.
struct OutputPhotoDescriptionContent: View {

    @Binding var usesCustomMemoryWriteText: Bool
    @Binding var customMemoryWriteText: String
    let resolvedMemoryWriteText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(macLocalized("mac.editor.output_preview.title", fallback: "What Will Be Written"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(resolvedMemoryWriteText)
                .font(.callout.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Toggle(macLocalized("mac.editor.output_preview.custom_toggle", fallback: "Add a Personal Note"), isOn: $usesCustomMemoryWriteText)
                .toggleStyle(.checkbox)

            if usesCustomMemoryWriteText {
                TextField(macLocalized("mac.editor.output_preview.placeholder", fallback: "Add the words you want to keep"), text: $customMemoryWriteText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)
            }

            Text(macLocalized("mac.editor.output_preview.description", fallback: "This text is written to the generated photo's description. The original stays unchanged."))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct OutputDestinationContent: View {

    var automaticallyFocusesNewAlbumName = true
    @Binding var outputTarget: ConfigurationOutputTarget
    let availableAlbums: [PhotoAlbumOption]
    @Binding var selectedExistingAlbumIdentifier: String
    @Binding var newAlbumName: String
    let isLoadingAlbums: Bool
    let albumStatusMessage: String
    let onReloadAlbums: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker(macLocalized("output.destination.title", fallback: "Save Location"), selection: $outputTarget) {
                Text(macLocalized("output.destination.target.apple_photos", fallback: "Apple Photos Library")).tag(ConfigurationOutputTarget.applePhotos)
                Text(macLocalized("output.destination.target.existing_album", fallback: "Existing Album")).tag(ConfigurationOutputTarget.existingAlbum)
                Text(macLocalized("output.destination.target.new_album", fallback: "New Album")).tag(ConfigurationOutputTarget.newAlbum)
            }
            .pickerStyle(.segmented)

            switch outputTarget {
            case .automatic, .applePhotos:
                Text(macLocalized("mac.editor.output.destination.description", fallback: "Generated photos are added to Photos without changing the originals."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .existingAlbum:
                HStack(spacing: 8) {
                    Picker(macLocalized("output.destination.target.existing_album", fallback: "Existing Album"), selection: $selectedExistingAlbumIdentifier) {
                        if availableAlbums.isEmpty {
                            Text(macLocalized("output.destination.existing.empty", fallback: "No available albums")).tag("")
                        } else {
                            ForEach(availableAlbums) { album in
                                Text(album.title).tag(album.id)
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(availableAlbums.isEmpty)

                    Button(action: onReloadAlbums) {
                        if isLoadingAlbums {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if !albumStatusMessage.isEmpty {
                    Text(albumStatusMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            case .newAlbum:
                TextField(macLocalized("output.destination.new.placeholder", fallback: "Album Name"), text: $newAlbumName)
                    .textFieldStyle(.roundedBorder)
                Text(macLocalized("output.destination.target.new_album.note", fallback: "The album is created or reused when you save this configuration."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CompactSelectionLabel: View {

    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.76)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: ConfigurationUI.smallCornerRadius, style: .continuous)
                .fill(ConfigurationUI.controlBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ConfigurationUI.smallCornerRadius, style: .continuous)
                .stroke(ConfigurationUI.faintHairline)
        )
        .frame(minHeight: ConfigurationUI.minimumInteractiveHeight)
    }
}

enum ConfigurationSectionCardMetrics {
    static let compactConfigurationRowMinimumHeight: CGFloat = 64
    static let cardHeaderContentSpacing: CGFloat = 6
    static let cardVerticalPadding: CGFloat = 10
}

enum CompactInformationRowMetrics {
    static let iconSize = ConfigurationUI.compactIconSize
    static let iconCornerRadius = ConfigurationUI.compactIconCornerRadius
    static let horizontalPadding: CGFloat = ConfigurationUI.innerPanelPadding
    static let verticalPadding = ConfigurationUI.compactRowVerticalPadding
    static let contentSpacing: CGFloat = 12
}

struct ConfigurationCompactSectionRow: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let subtitle: String
    let resultTitle: String
    let resultAccessibilityLabel: String
    let resultAccessibilityValue: String
    let isExpanded: Bool
    let expandedAccessibilityLabel: String
    let collapsedAccessibilityLabel: String
    var keepsResultOnSingleLine: Bool = false
    var resultMaximumWidth: CGFloat = ConfigurationUI.compactTrailingControlWidth
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 8) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 2) {
                        titleText
                        subtitleText
                    }
                    .layoutPriority(1)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        titleText
                        subtitleText
                    }
                    .layoutPriority(1)
                }

                Spacer(minLength: 8)

                Text(localized(resultTitle))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isExpanded ? .secondary : .primary)
                    .lineLimit(keepsResultOnSingleLine ? 1 : 2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.trailing)
                    .frame(
                        minWidth: 72,
                        maxWidth: resultMaximumWidth,
                        alignment: .trailing
                    )

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: ConfigurationUI.minimumInteractiveHeight, height: ConfigurationUI.minimumInteractiveHeight)
            }
            .frame(maxWidth: .infinity, minHeight: ConfigurationSectionCardMetrics.compactConfigurationRowMinimumHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(localized(resultAccessibilityLabel))
        .accessibilityValue(localized(resultAccessibilityValue) + ", " + macLocalized(isExpanded ? "mac.accessibility.expanded" : "mac.accessibility.collapsed", fallback: isExpanded ? "Expanded" : "Collapsed"))
        .accessibilityHint(localized(isExpanded ? expandedAccessibilityLabel : collapsedAccessibilityLabel))
    }

    private func localized(_ value: String) -> String {
        MemoMarkLanguage.interfaceStored.localized(key: value, fallback: value)
    }

    private var titleText: some View {
        Text(localized(title))
            .font(.headline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .allowsTightening(true)
    }

    private var subtitleText: some View {
        Text(localized(subtitle))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .minimumScaleFactor(0.82)
            .allowsTightening(!dynamicTypeSize.isAccessibilitySize)
    }
}

extension View {
    func v1SectionSurfaceLayout() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
    }
}

private struct MacRecentSituationSection: View {

    @ObservedObject
    var backgroundStatusService:
        MemoMarkBackgroundStatusService

    private var language: MemoMarkLanguage {
        .interfaceStored
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MacConfigurationSectionHeader(
                title: language.localized(
                    key: "task.page.title",
                    fallback: "Progress"
                ),
                subtitle: language.localized(
                    key: "task.page.subtitle",
                    fallback: "Current progress and saved results appear here."
                ),
                trailingTitle: nil,
                trailingSystemImage: nil
            ) {}

            currentSituationCard
            recentHistoryCard
        }
    }

    @ViewBuilder
    private var currentSituationCard: some View {
        if let snapshot = backgroundStatusService.currentSnapshot {
            MacCurrentSituationCard(snapshot: snapshot)
        } else {
            MacEmptySituationCard(
                title: language.localized(
                    key: "task.waiting.card.title",
                    fallback: "Ready"
                ),
                detail: language.localized(
                    key: "task.waiting.card.subtitle",
                    fallback: "New memories appear here when they are ready."
                )
            )
        }
    }

    private var recentHistoryCard: some View {
        let summaries = Array(
            backgroundStatusService.recentJobSummaries.prefix(5)
        )

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.localized(
                        key: "task.recent.title",
                        fallback: "Recently Saved"
                    ))
                    .font(.headline.weight(.semibold))

                    Text(language.localized(
                        key: "task.recent.subtitle",
                        fallback: "Recently completed memories appear here."
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(overviewText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if summaries.isEmpty {
                MacEmptySituationCard(
                    title: language.localized(
                        key: "task.recent.empty.title",
                        fallback: "No Saved Memories"
                    ),
                    detail: language.localized(
                        key: "task.recent.empty.detail",
                        fallback: "Recently saved memories appear here after you share photos from Apple Photos."
                    )
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(summaries) { summary in
                        MacRecentJobRow(summary: summary)

                        if summary.id != summaries.last?.id {
                            HorizontalDivider(horizontalInset: 12)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .configurationPanelChrome()
            }
        }
    }

    private var overviewText: String {
        let overview = backgroundStatusService.taskOverview
        return String(
            format: macLocalized("mac.progress.today_summary", fallback: "%d tasks today · %d photos complete"),
            overview.todayProcessingCount,
            overview.completedPhotoCount
        )
    }
}

private struct MacCurrentSituationCard: View {

    let snapshot: MemoMarkBackgroundJobSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: statusSymbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(statusColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.configurationName)
                        .font(.headline.weight(.semibold))
                        .lineLimit(1)

                    Text(snapshot.statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(statusTitle)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(statusColor.opacity(0.11))
                    )
            }

            HStack(spacing: 12) {
                Text(String(format: macLocalized("mac.progress.photo_count", fallback: "%d/%d photos"), snapshot.completedCount, snapshot.totalCount))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                if snapshot.failedCount > 0 {
                    Text(String(format: macLocalized("mac.progress.failed_count", fallback: "%d failed"), snapshot.failedCount))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }

                Spacer(minLength: 0)

                Text(snapshot.templateName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if snapshot.presentationState == .active {
                ProgressView(value: min(max(snapshot.progressFraction, 0), 1))
                    .tint(statusColor)
                    .accessibilityLabel(macLocalized("mac.progress.accessibility_label", fallback: "Current processing progress"))
                    .accessibilityValue(String(format: macLocalized("mac.progress.photo_count", fallback: "%d/%d photos"), snapshot.completedCount, snapshot.totalCount))
            }
        }
        .padding(16)
        .configurationPanelChrome()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("mac.configurationCenter.currentSituation")
    }

    private var statusTitle: String {
        switch snapshot.presentationState {
        case .active:
            return macLocalized("mac.status.processing", fallback: "Processing")
        case .needsAttention:
            return macLocalized("mac.status.needs_attention", fallback: "Needs Attention")
        case .completed:
            return macLocalized("mac.status.completed", fallback: "Completed")
        }
    }

    private var statusSymbol: String {
        switch snapshot.presentationState {
        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch snapshot.presentationState {
        case .active:
            return .blue
        case .needsAttention:
            return .orange
        case .completed:
            return .green
        }
    }
}

private struct MacRecentJobRow: View {

    let summary: MemoMarkBackgroundJobSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusSymbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(statusColor)
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(statusColor.opacity(0.11))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(summary.configurationName.isEmpty ? macLocalized("mac.configuration.unnamed", fallback: "Unnamed Configuration") : summary.configurationName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(String(format: macLocalized("mac.configuration.summary", fallback: "%@ · %d photos processed"), summary.templateName, summary.totalCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(formattedTimestamp)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 3) {
                Text(statusTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)

                if let albumName = summary.savedAlbumName,
                   !albumName.isEmpty {
                    Text(albumName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    private var statusTitle: String {
        switch summary.presentationState {
        case .active:
            return macLocalized("mac.status.processing", fallback: "Processing")
        case .needsAttention:
            return macLocalized("mac.status.needs_attention", fallback: "Needs Attention")
        case .completed:
            return macLocalized("mac.status.completed", fallback: "Completed")
        }
    }

    private var statusSymbol: String {
        switch summary.presentationState {
        case .active:
            return "arrow.trianglehead.2.clockwise.circle.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch summary.presentationState {
        case .active:
            return .blue
        case .needsAttention:
            return .orange
        case .completed:
            return .green
        }
    }

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = MemoMarkLanguage.interfaceStored.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: summary.updatedAt)
    }
}

private struct MacEmptySituationCard: View {

    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(ConfigurationUI.controlBackground)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .configurationPanelChrome()
    }
}

private struct MacMemoryPresetList: View {

    @ObservedObject
    var session: ConfigurationSession

    let onSelectPreset: (MemoryPreset) -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(macLocalized("mac.presets.title", fallback: "Presets"))
                        .font(.title3.weight(.semibold))
                    Text(macLocalized("mac.presets.description", fallback: "Select a preset to make it the current configuration for future processing."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section(macLocalized("mac.presets.current_subject", fallback: "Presets for Current Subject")) {
                ForEach(session.availableMemoryPresetsForSelectedSubject) { preset in
                    Button {
                        onSelectPreset(preset)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.stack")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(
                                    preset.id == session.processingDefaultMemoryPresetID
                                    ? String(format: macLocalized("mac.presets.active_summary", fallback: "Current · %@"), preset.summary)
                                    : preset.summary
                                )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 0)
                            if preset.id == session.state.selectedMemoryPresetID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(macLocalized("mac.presets.switch_hint", fallback: "Switch current preset"))
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct MacConfigurationInspector: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.dismiss)
    private var dismiss

    let route: MacConfigurationWorkspaceRoute

    @ObservedObject
    var session: ConfigurationSession

    @ObservedObject
    var commerceStore: MemoMarkCommerceStore

    let configurationCoordinator: ConfigurationCoordinator
    let saveConfiguration: SaveConfigurationTransaction

    @Binding
    var configurationStatus: ConfigurationPersistenceStatus

    let onSelectPreset: (MemoryPreset) -> Void
    let onInsertModule: (CenterInsertableModule) -> Void
    let onDraftChange:
        (CardRegion, MemoryCardEditorDraft, MemoryCardEditorDraft) -> Void
    let selectedLocationOptionID: Binding<String>?
    let selectedTimeOptionID: Binding<String>?
    let selectedTimeSupplement: Binding<TimeDisplayConfiguration.Supplement>?
    let filmMarkConfiguration: Binding<FilmMarkConfiguration>?
    let filmMarkContentDraft: Binding<MemoryCardEditorDraft>?
    let onSaveCardContent: () -> Void
    let regionDrafts: Binding<
        [RecordCardPresentationStyle: [CardRegion: MemoryCardEditorDraft]]
    >?
    let presentationStyle: RecordCardPresentationStyle?
    let onDirty: () -> Void
    let presentation: MacConfigurationInspectorPresentation

    @State private var subjectFlowState: SubjectConfigurationFlowState?

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Label(route.title, systemImage: route.systemImage)
                    .font(.title3.weight(.semibold))
                Spacer(minLength: 12)
                Button(macLocalized("common.done", fallback: "Done")) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    inspectorContent
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onAppear {
                    revealSelectedRegion(using: proxy)
                }
                .onChange(of: session.state.selectedRegion) { _, _ in
                    revealSelectedRegion(using: proxy)
                }
            }
        }
        .background(ConfigurationUI.appBackground)
        .frame(
            minWidth: presentation == .inspector ? 320 : 520,
            idealWidth: presentation == .inspector ? 380 : 620,
            minHeight: 680
        )
        .inspectorColumnWidth(
            min: presentation == .inspector ? 320 : nil,
            ideal: presentation == .inspector ? 380 : 620,
            max: presentation == .inspector ? 520 : nil
        )
        .onAppear(perform: prepareSubjectFlow)
    }

    private func revealSelectedRegion(
        using proxy: ScrollViewProxy
    ) {
        guard route == .cardContent else {
            return
        }
        let region = session.state.selectedRegion
        DispatchQueue.main.async {
            withAnimation(reduceMotion ? nil : .snappy) {
                proxy.scrollTo(region, anchor: .center)
            }
        }
    }

    @ViewBuilder
    private var inspectorContent: some View {
        switch route {
        case .subject:
            if let subjectFlowState {
                VStack(alignment: .leading, spacing: 18) {
                    MemorySubjectEditorView(
                        session: subjectFlowState.draftSession,
                        mode: .full
                    )
                    inspectorActions
                }
            } else {
                ContentUnavailableView(
                    macLocalized("mac.editor.subject_missing.title", fallback: "No Editable Memory Subject"),
                    systemImage: "person.crop.circle.badge.exclamationmark",
                    description: Text(macLocalized("mac.editor.subject_missing.message", fallback: "Select or create a memory subject first."))
                )
            }
        case .preset:
            MacMemoryPresetList(
                session: session,
                onSelectPreset: onSelectPreset
            )
            .frame(minHeight: 360)
        case .cardContent:
            MacCardContentInspector(
                session: session,
                commerceStore: commerceStore,
                onSelectMemoryPreset: onSelectPreset,
                onSaveMemoryPreset: onSaveCardContent,
                onInsertModule: onInsertModule,
                regionDrafts: regionDrafts,
                presentationStyle: presentationStyle,
                filmMarkContentDraft: filmMarkContentDraft,
                onDraftChange: onDraftChange,
                onDirty: onDirty
            )
        case .filmMarkDetails:
            if let filmMarkConfiguration {
                FilmMarkConfigurationControls(
                    configuration: filmMarkConfiguration,
                    onChange: onDirty
                )
            } else {
                ContentUnavailableView(
                    macLocalized("mac.editor.film_mark_unavailable.title", fallback: "FilmMark Is Not Editable Yet"),
                    systemImage: "paintpalette",
                    description: Text(macLocalized("mac.editor.open_from_library", fallback: "Open this editor from the configuration library."))
                )
            }
        case .timeAndPlace:
            if let selectedLocationOptionID,
               let selectedTimeOptionID,
               let selectedTimeSupplement {
                MacTimeAndPlaceInspector(
                    selectedLocationOptionID: selectedLocationOptionID,
                    selectedTimeOptionID: selectedTimeOptionID,
                    selectedTimeSupplement: selectedTimeSupplement,
                    onChange: {
                        configurationStatus = .dirty
                    }
                )
            } else {
                ContentUnavailableView(
                    macLocalized("mac.editor.time_place_unavailable.title", fallback: "Time and Place Is Not Editable Yet"),
                    systemImage: "clock.badge.exclamationmark",
                    description: Text(macLocalized("mac.editor.open_from_library", fallback: "Open this editor from the configuration library."))
                )
            }
        }
    }

    private var inspectorActions: some View {
        HStack(spacing: 10) {
            Button(macLocalized("common.cancel", fallback: "Cancel")) {
                dismiss()
            }
            .buttonStyle(.bordered)

            Spacer(minLength: 0)

            Button(macLocalized("mac.editor.save_subject", fallback: "Save Subject")) {
                guard let subjectFlowState else {
                    return
                }
                Task { @MainActor in
                    if await subjectFlowState.saveChanges() {
                        configurationStatus = .saved
                        dismiss()
                    } else {
                        configurationStatus = .failure(
                            message: subjectFlowState.lastSaveFailureMessage
                                ?? macLocalized("mac.editor.subject_save_failed", fallback: "The memory subject could not be saved. Try again later.")
                        )
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("s", modifiers: .command)
        }
    }

    private func prepareSubjectFlow() {
        guard route == .subject, subjectFlowState == nil else {
            return
        }

        subjectFlowState = SubjectOverviewActionCoordinator
            .makeConfigurationFlowState(
                from: session,
                shouldSaveSubjectLibrary: true,
                configurationCoordinator: configurationCoordinator,
                savedStatus: configurationStatus,
                onPersistedSubject: { patch in
                    configurationStatus = patch.activeConfigurationStatus
                }
            )
    }
}

#Preview {
    ConfigurationCenterView(runtime: MemoMarkAppRuntime())
    .frame(width: 1180, height: 900)
}
#endif
