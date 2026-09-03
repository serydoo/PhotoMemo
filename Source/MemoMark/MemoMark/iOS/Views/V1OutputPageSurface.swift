#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct ConfigurationOutputPageSurface: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Binding
    var outputTarget: ConfigurationOutputTarget

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String
    let onReloadAlbums: () -> Void
    let isSavingConfiguration: Bool
    let configurationStatus: ConfigurationPersistenceStatus
    let onSaveConfiguration: () -> Void

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String
    let onDismissKeyboard: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                pageHeader

                OutputPhotoDescriptionSection(
                    usesCustomMemoryWriteText: $usesCustomMemoryWriteText,
                    customMemoryWriteText: $customMemoryWriteText,
                    resolvedMemoryWriteText: resolvedMemoryWriteText
                )

                OutputDestinationSection(
                    outputTarget: $outputTarget,
                    availableAlbums: availableAlbums,
                    selectedExistingAlbumIdentifier: $selectedExistingAlbumIdentifier,
                    newAlbumName: $newAlbumName,
                    isLoadingAlbums: isLoadingAlbums,
                    albumStatusMessage: albumStatusMessage,
                    onReloadAlbums: onReloadAlbums
                )
            }
            .padding(.top, 10)
            .padding(.bottom, 76)
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
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            outputConfigurationFooter
        }
    }

    private var pageHeader: some View {
        ConfigurationPageHeader(
            "output.page.title",
            subtitle: "output.page.subtitle"
        )
    }

    private var outputConfigurationFooter: some View {
        OutputSaveConfigurationButton(
            isSaving: isSavingConfiguration,
            configurationStatus: configurationStatus,
            action: onSaveConfiguration
        )
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

private struct OutputSaveConfigurationButton: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    let isSaving: Bool
    let configurationStatus: ConfigurationPersistenceStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(
                    systemName: systemImage
                )
                .font(.caption.weight(.semibold))
                .frame(width: 16)

                Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            }
        }
        .buttonStyle(
            OutputSaveButtonStyle(
                isSaved: configurationStatus == .saved
            )
        )
        .disabled(isSaving || configurationStatus == .saved)
        .accessibilityLabel(title)
    }

    private var title: String {
        if isSaving {
            return localized("output.save.saving")
        }

        switch configurationStatus {
        case .saved:
            return localized("output.save.saved")
        case .savedWithWarning:
            return localized("output.save.warning")
        case .failure:
            return localized("output.save.retry")
        case .idle,
             .dirty,
             .saving,
             .subjectSynced:
            return localized("output.save.action")
        }
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }

    private var systemImage: String {
        if isSaving {
            return "hourglass"
        }

        switch configurationStatus {
        case .saved:
            return "checkmark.circle.fill"
        case .savedWithWarning:
            return "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .failure:
            return "arrow.clockwise.circle.fill"
        case .idle,
             .dirty,
             .saving,
             .subjectSynced:
            return "square.and.arrow.down.fill"
        }
    }
}

private struct OutputSaveButtonStyle: ButtonStyle {

    let isSaved: Bool

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(
                isSaved
                ? Color.secondary
                : MemoMarkDesignTokens.Semantic.onAccent
            )
            .padding(.horizontal, 14)
            .frame(
                width: CompactBottomActionMetrics.width,
                height: CompactBottomActionMetrics.height
            )
            .background(
                RoundedRectangle(
                    cornerRadius: CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .fill(
                    isSaved
                    ? ConfigurationUI.controlBackground
                    : Color.accentColor.opacity(
                        MemoMarkDesignTokens.Layout
                            .compactPrimaryActionTintOpacity
                    )
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: CompactBottomActionMetrics.cornerRadius,
                    style: .continuous
                )
                .stroke(ConfigurationUI.faintHairline)
            )
            .opacity(
                isEnabled
                ? (configuration.isPressed ? 0.78 : 1)
                : (isSaved ? 1 : 0.56)
            )
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}

struct OutputPhotoDescriptionSection: View {

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String

    var body: some View {
        let presentation = MemoryWriteOptionPresenter.presentation(
            usesCustomText: usesCustomMemoryWriteText,
            resolvedText: resolvedMemoryWriteText
        )

        ConfigurationTitledSectionCard(
            title: presentation.defaultContentTitle,
            subtitle: presentation.defaultContentDescription
        ) {
            OutputPhotoDescriptionContent(
                usesCustomMemoryWriteText: $usesCustomMemoryWriteText,
                customMemoryWriteText: $customMemoryWriteText,
                resolvedMemoryWriteText: resolvedMemoryWriteText
            )
        }
    }
}

struct OutputPhotoDescriptionContent: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Binding
    var usesCustomMemoryWriteText: Bool

    @Binding
    var customMemoryWriteText: String

    let resolvedMemoryWriteText: String

    var body: some View {
        let presentation = MemoryWriteOptionPresenter.presentation(
            usesCustomText: usesCustomMemoryWriteText,
            resolvedText: resolvedMemoryWriteText
        )

        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.resolvedTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(presentation.resolvedDescription)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(presentation.fallbackNote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 2)

            HorizontalDivider()

            Toggle(isOn: $usesCustomMemoryWriteText) {
                OutputRetentionLabel(
                    title: presentation.toggleTitle,
                    subtitle: presentation.toggleDescription
                )
            }
            .toggleStyle(.switch)
            .padding(.vertical, 2)

            if usesCustomMemoryWriteText {
                TextField(
                    presentation.inputPlaceholder,
                    text: $customMemoryWriteText,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(.subheadline)
                .lineLimit(1...3)
                .submitLabel(.done)
                .configurationFieldChrome(isActive: true)
                .transition(
                    reduceMotion ? .opacity : .opacity.combined(
                        with: .move(edge: .top)
                    )
                )
            }

            Text(localized("output.memory_write.system_note"))
                .font(.caption)
                .foregroundStyle(Color.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .animation(
            reduceMotion
            ? nil
            : .easeOut(
                duration: MemoMarkDesignTokens.Motion.standard
            ),
            value: usesCustomMemoryWriteText
        )
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}

private struct OutputRetentionLabel: View {

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct OutputDestinationSection: View {

    @Binding
    var outputTarget: ConfigurationOutputTarget

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String
    let onReloadAlbums: () -> Void

    var body: some View {
        ConfigurationTitledSectionCard(
            title: "output.destination.title",
            subtitle: "output.destination.subtitle"
        ) {
            OutputDestinationContent(
                outputTarget: $outputTarget,
                availableAlbums: availableAlbums,
                selectedExistingAlbumIdentifier:
                    $selectedExistingAlbumIdentifier,
                newAlbumName: $newAlbumName,
                isLoadingAlbums: isLoadingAlbums,
                albumStatusMessage: albumStatusMessage,
                onReloadAlbums: onReloadAlbums
            )
        }
    }
}

struct OutputDestinationContent: View {

    private var interfaceLanguage: MemoMarkLanguage {
        .interfaceStored
    }

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @FocusState
    private var isNewAlbumNameFocused: Bool

    var automaticallyFocusesNewAlbumName = true

    @Binding
    var outputTarget: ConfigurationOutputTarget

    let availableAlbums: [PhotoAlbumOption]

    @Binding
    var selectedExistingAlbumIdentifier: String

    @Binding
    var newAlbumName: String

    let isLoadingAlbums: Bool
    let albumStatusMessage: String
    let onReloadAlbums: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            adaptiveOutputTargetPicker

            targetSpecificControls
        }
    }

    private var presentedOutputTarget: ConfigurationOutputTarget {
        outputTarget == .automatic ? .applePhotos : outputTarget
    }

    @ViewBuilder
    private var adaptiveOutputTargetPicker: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Picker(
                localized("output.destination.title"),
                selection: presentedOutputTargetBinding
            ) {
                outputTargetOptions
            }
        .pickerStyle(.menu)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } else {
            Picker(
                localized("output.destination.title"),
                selection: presentedOutputTargetBinding
            ) {
                outputTargetOptions
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var outputTargetOptions: some View {
        ForEach(selectableOutputTargets) { target in
            Label(
                target.localizedTitle(for: interfaceLanguage),
                systemImage: target.symbolName
            )
            .tag(target)
        }
    }

    private var selectableOutputTargets: [ConfigurationOutputTarget] {
        [.applePhotos, .existingAlbum, .newAlbum]
    }

    private var presentedOutputTargetBinding: Binding<ConfigurationOutputTarget> {
        Binding(
            get: { presentedOutputTarget },
            set: { outputTarget = $0 }
        )
    }

    @ViewBuilder
    private var targetSpecificControls: some View {
        switch presentedOutputTarget {
        case .automatic,
             .applePhotos:
            EmptyView()

        case .existingAlbum:
            VStack(alignment: .leading, spacing: 7) {
                Text(localized("output.destination.existing.title"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                existingAlbumControlRow

                Text(localized("output.destination.existing.detail"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                albumStatusView
            }

        case .newAlbum:
            VStack(alignment: .leading, spacing: 6) {
                TextField(
                    localized("output.destination.new.placeholder"),
                    text: $newAlbumName
                )
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(1)
                    .submitLabel(.done)
                    .focused($isNewAlbumNameFocused)
                    .configurationFieldChrome(isActive: true)

                Text(localized("output.destination.new.detail"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .onAppear {
                guard automaticallyFocusesNewAlbumName else { return }
                isNewAlbumNameFocused = true
            }
        }
    }

    private var existingAlbumControlRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Picker(
                localized("output.destination.existing.picker"),
                selection: $selectedExistingAlbumIdentifier
            ) {
                if availableAlbums.isEmpty {
                    Text(localized("output.destination.existing.empty")).tag("")
                } else {
                    ForEach(availableAlbums) { album in
                        Text(album.title).tag(album.id)
                    }
                }
            }
            .pickerStyle(.menu)
            .disabled(availableAlbums.isEmpty)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onReloadAlbums) {
                Group {
                    if isLoadingAlbums {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color(uiColor: .secondarySystemFill))
                )
                .overlay(
                    Circle()
                        .stroke(ConfigurationUI.faintHairline)
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isLoadingAlbums)
            .accessibilityLabel(
                isLoadingAlbums
                ? localized("output.destination.refreshing")
                : localized("output.destination.refresh")
            )
            .accessibilityHint(localized("output.destination.refresh.hint"))
        }
    }

    @ViewBuilder
    private var albumStatusView: some View {
        if isLoadingAlbums {
            Label(
                localized("output.destination.loading"),
                systemImage: "photo.on.rectangle"
            )
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else if !albumStatusMessage.isEmpty {
            Text(albumStatusMessage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func localized(_ key: String) -> String {
        interfaceLanguage.localized(key: key, fallback: key)
    }
}

private extension ConfigurationOutputTarget {

    func localizedTitle(for language: MemoMarkLanguage) -> String {
        let key: String
        switch self {
        case .automatic:
            key = "output.destination.target.automatic"
        case .applePhotos:
            key = "output.destination.target.apple_photos"
        case .existingAlbum:
            key = "output.destination.target.existing_album"
        case .newAlbum:
            key = "output.destination.target.new_album"
        }
        return language.localized(key: key, fallback: title)
    }

    var symbolName: String {
        switch self {
        case .automatic:
            return "wand.and.stars"
        case .applePhotos:
                return MemoMarkSymbol.applePhotos.name
        case .existingAlbum:
            return MemoMarkSymbol.localStorage.name
        case .newAlbum:
            return MemoMarkSymbol.output.name
        }
    }

    var tint: Color {
        switch self {
        case .automatic:
            return .blue
        case .applePhotos:
            return .green
        case .existingAlbum:
            return .orange
        case .newAlbum:
            return .purple
        }
    }

    var summaryTitle: String {
        switch self {
        case .automatic:
            return "自动选择保存位置"
        case .applePhotos:
            return "存储到系统图库"
        case .existingAlbum:
            return "存储到已有相册"
        case .newAlbum:
            return "创建或复用新相册"
        }
    }
}

#endif
