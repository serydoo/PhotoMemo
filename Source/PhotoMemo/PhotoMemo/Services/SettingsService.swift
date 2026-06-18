import Foundation
import Combine

enum WorkspaceConfigurationSlotID:
    String,
    Codable,
    CaseIterable,
    Hashable,
    Identifiable {

    case slot1

    case slot2

    case slot3

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .slot1:
            return "配置 1"

        case .slot2:
            return "配置 2"

        case .slot3:
            return "配置 3"
        }
    }

    var defaultPreset: TemplatePreset {

        switch self {

        case .slot1:
            return .template1

        case .slot2:
            return .template2

        case .slot3:
            return .template3
        }
    }
}

struct WorkspaceConfigurationSlot:
    Identifiable,
    Codable,
    Hashable {

    let id: WorkspaceConfigurationSlotID

    var customTitle: String?

    var snapshot: BatchConfigurationSnapshot?

    var updatedAt: Date?

    var title: String {
        id.title
    }

    var resolvedCustomTitle: String? {

        guard
            let trimmedTitle =
                customTitle?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !trimmedTitle.isEmpty
        else {
            return nil
        }

        return trimmedTitle
    }

    var displayTitle: String {
        resolvedCustomTitle ?? title
    }

    var displayTitleWithReference: String {

        guard let resolvedCustomTitle else {
            return title
        }

        return "\(resolvedCustomTitle)（\(title)）"
    }

    var defaultPreset: TemplatePreset {
        id.defaultPreset
    }

    var isCustomized: Bool {
        snapshot != nil
    }

    var resolvedDisplayName: String {

        guard
            let trimmedName =
                snapshot?.template.name
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !trimmedName.isEmpty
        else {
            return defaultPreset.displayName
        }

        return trimmedName
    }

    var statusText: String {
        isCustomized ? "已保存" : "默认"
    }

    static var defaultSlots: [WorkspaceConfigurationSlot] {

        WorkspaceConfigurationSlotID
            .allCases
            .map {
                WorkspaceConfigurationSlot(
                    id: $0,
                    customTitle: nil,
                    snapshot: nil,
                    updatedAt: nil
                )
            }
    }

    static func normalized(
        _ slots: [WorkspaceConfigurationSlot]
    ) -> [WorkspaceConfigurationSlot] {

        WorkspaceConfigurationSlotID
            .allCases
            .map { slotID in

                slots.first(where: {
                    $0.id == slotID
                }) ?? WorkspaceConfigurationSlot(
                    id: slotID,
                    customTitle: nil,
                    snapshot: nil,
                    updatedAt: nil
                )
            }
    }
}

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

        static let activeConfigurationSlotID =
            "photomemo.activeConfigurationSlotID"

        static let configurationSlots =
            "photomemo.configurationSlots"
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

    @Published
    var activeConfigurationSlotID:
        WorkspaceConfigurationSlotID = .slot1

    @Published
    var configurationSlots:
        [WorkspaceConfigurationSlot] =
            WorkspaceConfigurationSlot.defaultSlots

    init() {

        loadConfigurationSlots()

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
        saveConfigurationSlots()
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

    func saveConfigurationSlots() {

        guard
            let slotsData =
                try? JSONEncoder().encode(
                    configurationSlots
                )
        else {
            return
        }

        UserDefaults.standard.set(
            activeConfigurationSlotID.rawValue,
            forKey: Keys.activeConfigurationSlotID
        )

        UserDefaults.standard.set(
            slotsData,
            forKey: Keys.configurationSlots
        )
    }

    func updateConfigurationSlot(
        _ slotID: WorkspaceConfigurationSlotID,
        snapshot: BatchConfigurationSnapshot?
    ) {

        configurationSlots =
            configurationSlots.map { slot in

                guard slot.id == slotID else {
                    return slot
                }

                var updatedSlot = slot
                updatedSlot.snapshot = snapshot
                updatedSlot.updatedAt =
                    snapshot == nil ? nil : Date()
                return updatedSlot
            }

        saveConfigurationSlots()
    }

    func configurationSlot(
        for slotID: WorkspaceConfigurationSlotID
    ) -> WorkspaceConfigurationSlot? {

        configurationSlots.first {
            $0.id == slotID
        }
    }

    func renameConfigurationSlot(
        _ slotID: WorkspaceConfigurationSlotID,
        customTitle: String?
    ) {

        configurationSlots =
            configurationSlots.map { slot in

                guard slot.id == slotID else {
                    return slot
                }

                var updatedSlot = slot
                updatedSlot.customTitle = customTitle
                return updatedSlot
            }

        saveConfigurationSlots()
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

    private func loadConfigurationSlots() {

        if let activeSlotRawValue =
            UserDefaults.standard.string(
                forKey: Keys.activeConfigurationSlotID
            ),
           let activeSlotID =
            WorkspaceConfigurationSlotID(
                rawValue: activeSlotRawValue
            ) {
            activeConfigurationSlotID =
                activeSlotID
        }

        guard
            let slotsData =
                UserDefaults.standard.data(
                    forKey: Keys.configurationSlots
                ),
            let decodedSlots =
                try? JSONDecoder().decode(
                    [WorkspaceConfigurationSlot].self,
                    from: slotsData
                )
        else {
            configurationSlots =
                WorkspaceConfigurationSlot.defaultSlots
            return
        }

        configurationSlots =
            WorkspaceConfigurationSlot.normalized(
                decodedSlots
            )
    }
}

extension SettingsService {

    var resolvedSelectedAnchor: Anchor? {

        resolvedAnchor(
            for: selectedAnchorIDString
        )
    }

    func resolvedAnchor(
        for identifierString: String
    ) -> Anchor? {

        guard
            let identifier = UUID(
                uuidString: identifierString
            )
        else {
            return nil
        }

        return anchors.first {
            $0.id == identifier
        }
    }

    func buildBatchConfigurationSnapshot(
        selectedAnchorID: UUID? = nil,
        draftTitleText: String? = nil,
        draftStoryText: String? = nil,
        selectedAlbumIdentifier: String? = nil
    ) -> BatchConfigurationSnapshot {

        let resolvedAnchorIdentifier =
            selectedAnchorID?.uuidString
            ?? selectedAnchorIDString

        let resolvedTitleText =
            draftTitleText
            ?? self.draftTitleText

        let resolvedStoryText =
            draftStoryText
            ?? self.draftStoryText

        let resolvedAlbumIdentifier =
            normalizedAlbumIdentifier(
                selectedAlbumIdentifier
                ?? self.selectedAlbumIdentifier
            )

        return BatchConfigurationSnapshot(
            template:
                (selectedTemplate ?? .template1)
                .normalizedForEditing,
            badge:
                selectedBadge?.type == BadgeType.none
                ? nil
                : selectedBadge,
            anchor: resolvedAnchor(
                for: resolvedAnchorIdentifier
            ),
            shouldWritePhotoDescription:
                shouldWritePhotoDescription,
            photoDescriptionOverride:
                photoDescriptionOverride,
            selectedAlbumIdentifier:
                resolvedAlbumIdentifier,
            titleText: resolvedTitleText,
            storyText: resolvedStoryText
        )
    }

    var normalizedSelectedAlbumIdentifier: String {

        normalizedAlbumIdentifier(
            selectedAlbumIdentifier
        )
    }

    func normalizedAlbumIdentifier(
        _ identifier: String
    ) -> String {

        if identifier.isEmpty
            || identifier
            == PhotoAlbumOption.automaticIdentifier {
            return ""
        }

        return identifier
    }
}
