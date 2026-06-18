import Foundation
import Combine

@MainActor
final class SettingsService: ObservableObject {

    private let autosaveDelayNanoseconds:
        UInt64 = 350_000_000

    private var templateSaveTask:
        Task<Void, Never>?

    private var editorStateSaveTask:
        Task<Void, Never>?

    private var photoDescriptionSaveTask:
        Task<Void, Never>?

    private enum Keys {

        static let anchors = "photomemo.anchors"

        static let selectedTemplate = "photomemo.selectedTemplate"

        static let selectedBadge = "photomemo.selectedBadge"

        static let shouldWritePhotoDescription =
            "photomemo.shouldWritePhotoDescription"

        static let photoDescriptionOverride =
            "photomemo.photoDescriptionOverride"

        static let selectedAnchorID =
            "photomemo.selectedAnchorID"

        static let draftTitleText =
            "photomemo.draftTitleText"

        static let draftStoryText =
            "photomemo.draftStoryText"

        static let selectedAlbumIdentifier =
            "photomemo.selectedAlbumIdentifier"
    }

    @Published var anchors: [Anchor] = []

    @Published var selectedTemplate: Template?

    @Published var selectedBadge: Badge?

    @Published var shouldWritePhotoDescription = true

    @Published var photoDescriptionOverride = ""

    @Published var selectedAnchorIDString = ""

    @Published var draftTitleText = ""

    @Published var draftStoryText = ""

    @Published var selectedAlbumIdentifier = ""

    init() {

        loadAnchors()

        loadTemplate()

        loadBadge()

        loadPhotoDescriptionSettings()

        loadEditorState()

        if selectedTemplate == nil {
            selectedTemplate = .template1
        }

        if selectedBadge == nil {
            selectedBadge = Badge.none
        }
    }

    func saveAnchors() {

        guard let data = try? JSONEncoder().encode(anchors) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.anchors
        )
    }

    func saveTemplate() {

        guard let selectedTemplate else {
            UserDefaults.standard.removeObject(
                forKey: Keys.selectedTemplate
            )
            return
        }

        guard let data = try? JSONEncoder().encode(selectedTemplate) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.selectedTemplate
        )
    }

    func scheduleTemplateSave() {

        templateSaveTask?.cancel()
        templateSaveTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds:
                    autosaveDelayNanoseconds
            )

            guard !Task.isCancelled else {
                return
            }

            saveTemplate()
        }
    }

    func saveBadge() {

        guard let selectedBadge else {
            UserDefaults.standard.removeObject(
                forKey: Keys.selectedBadge
            )
            return
        }

        guard let data = try? JSONEncoder().encode(selectedBadge) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Keys.selectedBadge
        )
    }

    func savePhotoDescriptionSettings() {

        UserDefaults.standard.set(
            shouldWritePhotoDescription,
            forKey: Keys.shouldWritePhotoDescription
        )

        UserDefaults.standard.set(
            photoDescriptionOverride,
            forKey: Keys.photoDescriptionOverride
        )
    }

    func schedulePhotoDescriptionSettingsSave() {

        photoDescriptionSaveTask?.cancel()
        photoDescriptionSaveTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds:
                    autosaveDelayNanoseconds
            )

            guard !Task.isCancelled else {
                return
            }

            savePhotoDescriptionSettings()
        }
    }

    func saveAll() {

        saveAnchors()
        saveTemplate()
        saveBadge()
        savePhotoDescriptionSettings()
        saveEditorState()
    }

    func saveEditorState(
        selectedAnchorID: UUID? = nil,
        draftTitleText: String? = nil,
        draftStoryText: String? = nil,
        selectedAlbumIdentifier: String? = nil
    ) {

        if let selectedAnchorID {
            self.selectedAnchorIDString =
                selectedAnchorID.uuidString
        }

        if let draftTitleText {
            self.draftTitleText = draftTitleText
        }

        if let draftStoryText {
            self.draftStoryText = draftStoryText
        }

        if let selectedAlbumIdentifier {
            self.selectedAlbumIdentifier =
                selectedAlbumIdentifier
        }

        UserDefaults.standard.set(
            selectedAnchorIDString,
            forKey: Keys.selectedAnchorID
        )

        UserDefaults.standard.set(
            self.draftTitleText,
            forKey: Keys.draftTitleText
        )

        UserDefaults.standard.set(
            self.draftStoryText,
            forKey: Keys.draftStoryText
        )

        UserDefaults.standard.set(
            self.selectedAlbumIdentifier,
            forKey: Keys.selectedAlbumIdentifier
        )
    }

    func scheduleEditorStateSave(
        selectedAnchorID: UUID? = nil,
        draftTitleText: String? = nil,
        draftStoryText: String? = nil,
        selectedAlbumIdentifier: String? = nil
    ) {

        if let selectedAnchorID {
            self.selectedAnchorIDString =
                selectedAnchorID.uuidString
        }

        if let draftTitleText {
            self.draftTitleText = draftTitleText
        }

        if let draftStoryText {
            self.draftStoryText = draftStoryText
        }

        if let selectedAlbumIdentifier {
            self.selectedAlbumIdentifier =
                selectedAlbumIdentifier
        }

        editorStateSaveTask?.cancel()
        editorStateSaveTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds:
                    autosaveDelayNanoseconds
            )

            guard !Task.isCancelled else {
                return
            }

            saveEditorState()
        }
    }

    private func loadAnchors() {

        guard
            let data = UserDefaults.standard.data(
                forKey: Keys.anchors
            )
        else {
            return
        }

        anchors =
            (try? JSONDecoder().decode(
                [Anchor].self,
                from: data
            )) ?? []
    }

    private func loadTemplate() {

        guard
            let data = UserDefaults.standard.data(
                forKey: Keys.selectedTemplate
            )
        else {
            return
        }

        guard let decodedTemplate =
            try? JSONDecoder().decode(
                Template.self,
                from: data
            )
        else {
            return
        }

        let normalizedTemplate =
            decodedTemplate.normalizedForEditing

        selectedTemplate =
            normalizedTemplate

        if normalizedTemplate != decodedTemplate {
            saveTemplate()
        }
    }

    private func loadBadge() {

        guard
            let data = UserDefaults.standard.data(
                forKey: Keys.selectedBadge
            )
        else {
            return
        }

        selectedBadge =
            try? JSONDecoder().decode(
                Badge.self,
                from: data
            )
    }

    private func loadPhotoDescriptionSettings() {

        if UserDefaults.standard.object(
            forKey: Keys.shouldWritePhotoDescription
        ) != nil {

            shouldWritePhotoDescription =
                UserDefaults.standard.bool(
                    forKey: Keys.shouldWritePhotoDescription
                )
        }

        photoDescriptionOverride =
            UserDefaults.standard.string(
                forKey: Keys.photoDescriptionOverride
            ) ?? ""
    }

    private func loadEditorState() {

        selectedAnchorIDString =
            UserDefaults.standard.string(
                forKey: Keys.selectedAnchorID
            ) ?? ""

        draftTitleText =
            UserDefaults.standard.string(
                forKey: Keys.draftTitleText
            ) ?? ""

        draftStoryText =
            UserDefaults.standard.string(
                forKey: Keys.draftStoryText
            ) ?? ""

        selectedAlbumIdentifier =
            UserDefaults.standard.string(
                forKey: Keys.selectedAlbumIdentifier
            ) ?? ""
    }
}

extension SettingsService {

    var resolvedSelectedAnchor: Anchor? {

        guard
            let identifier = UUID(
                uuidString: selectedAnchorIDString
            )
        else {
            return nil
        }

        return anchors.first {
            $0.id == identifier
        }
    }

    func buildBatchConfigurationSnapshot() -> BatchConfigurationSnapshot {

        BatchConfigurationSnapshot(
            template:
                (selectedTemplate ?? .template1)
                .normalizedForEditing,
            badge:
                selectedBadge?.type == BadgeType.none
                ? nil
                : selectedBadge,
            anchor: resolvedSelectedAnchor,
            shouldWritePhotoDescription:
                shouldWritePhotoDescription,
            photoDescriptionOverride:
                photoDescriptionOverride,
            selectedAlbumIdentifier:
                normalizedSelectedAlbumIdentifier,
            titleText: draftTitleText,
            storyText: draftStoryText
        )
    }

    var normalizedSelectedAlbumIdentifier: String {

        if selectedAlbumIdentifier.isEmpty
            || selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier {
            return ""
        }

        return selectedAlbumIdentifier
    }
}
