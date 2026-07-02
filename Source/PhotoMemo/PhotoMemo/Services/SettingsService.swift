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
            return "模块 1"

        case .slot2:
            return "模块 2"

        case .slot3:
            return "模块 3"
        }
    }

    var defaultPreset: TemplatePreset {

        switch self {

        case .slot1:
            return .template1

        case .slot2:
            return .template1

        case .slot3:
            return .template1
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

struct V1ConfigurationBootstrapReadState {

    let subjectResult:
        PhotoMemoSharedDefaultsReadResult<
            MemorySubject
        >

    let badgeResult:
        PhotoMemoSharedDefaultsReadResult<
            Badge
        >

    let selectedAlbumIdentifier: String

    let selectedAlbumTitle: String
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

    private let defaults:
        UserDefaults

    private let snapshotProvider:
        BatchConfigurationSnapshotProvider

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

        static let selectedAlbumIdentifier =
            "photomemo.selectedAlbumIdentifier"

        static let selectedAlbumTitle =
            "photomemo.selectedAlbumTitle"

        static let selectedMemorySubject =
            "photomemo.selectedMemorySubject"

        static let selectedMemorySubjectText =
            "photomemo.selectedMemorySubjectText"

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

    @Published var selectedAlbumIdentifier = ""

    @Published var selectedAlbumTitle = ""

    @Published
    var activeConfigurationSlotID:
        WorkspaceConfigurationSlotID = .slot1

    @Published
    var configurationSlots:
        [WorkspaceConfigurationSlot] =
            WorkspaceConfigurationSlot.defaultSlots

    init() {

        self.defaults =
            PhotoMemoSharedContainer
            .sharedUserDefaults
        self.snapshotProvider =
            BatchConfigurationSnapshotProvider(
                defaults: self.defaults
            )

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

    init(
        defaults: UserDefaults
    ) {

        self.defaults = defaults
        self.snapshotProvider =
            BatchConfigurationSnapshotProvider(
                defaults: self.defaults
            )

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

        defaults.set(
            data,
            forKey: Keys.anchors
        )
    }

    func saveTemplate() {

        guard let selectedTemplate else {
            defaults.removeObject(
                forKey: Keys.selectedTemplate
            )
            return
        }

        guard let data = try? JSONEncoder().encode(selectedTemplate) else {
            return
        }

        defaults.set(
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
            defaults.removeObject(
                forKey: Keys.selectedBadge
            )
            return
        }

        guard let data = try? JSONEncoder().encode(selectedBadge) else {
            return
        }

        defaults.set(
            data,
            forKey: Keys.selectedBadge
        )
    }

    func saveSelectedMemorySubject(
        _ subject: MemorySubject?
    ) {

        guard let subject else {
            defaults.removeObject(
                forKey: Keys.selectedMemorySubject
            )
            defaults.removeObject(
                forKey:
                    Keys.selectedMemorySubjectText
            )
            return
        }

        guard let data =
            try? JSONEncoder().encode(subject)
        else {
            return
        }

        defaults.set(
            data,
            forKey: Keys.selectedMemorySubject
        )

        defaults.set(
            subject.resolvedExpressionSubjectText,
            forKey:
                Keys.selectedMemorySubjectText
        )
    }

    func savePhotoDescriptionSettings() {

        defaults.set(
            shouldWritePhotoDescription,
            forKey: Keys.shouldWritePhotoDescription
        )

        defaults.set(
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
        selectedAlbumIdentifier: String? = nil,
        selectedAlbumTitle: String? = nil
    ) {

        if let selectedAnchorID {
            self.selectedAnchorIDString =
                selectedAnchorID.uuidString
        }

        if let selectedAlbumIdentifier {
            self.selectedAlbumIdentifier =
                selectedAlbumIdentifier
        }

        if let selectedAlbumTitle {
            self.selectedAlbumTitle =
                selectedAlbumTitle
        }

        defaults.set(
            selectedAnchorIDString,
            forKey: Keys.selectedAnchorID
        )

        defaults.set(
            self.selectedAlbumIdentifier,
            forKey: Keys.selectedAlbumIdentifier
        )

        defaults.set(
            self.selectedAlbumTitle,
            forKey: Keys.selectedAlbumTitle
        )
    }

    func reloadV1BootstrapState() {
        loadBadge()
        loadEditorState()
    }

    func loadV1SelectedSubjectResult()
    -> PhotoMemoSharedDefaultsReadResult<
        MemorySubject
    > {

        decodeValueResult(
            MemorySubject.self,
            forKey: Keys.selectedMemorySubject
        )
    }

    func loadV1BootstrapReadState()
    -> V1ConfigurationBootstrapReadState {

        loadEditorState()

        return V1ConfigurationBootstrapReadState(
            subjectResult:
                loadV1SelectedSubjectResult(),
            badgeResult:
                snapshotProvider
                .loadBadgeResult(),
            selectedAlbumIdentifier:
                selectedAlbumIdentifier,
            selectedAlbumTitle:
                selectedAlbumTitle
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

        defaults.set(
            activeConfigurationSlotID.rawValue,
            forKey: Keys.activeConfigurationSlotID
        )

        defaults.set(
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
        selectedAlbumIdentifier: String? = nil,
        selectedAlbumTitle: String? = nil
    ) {

        if let selectedAnchorID {
            self.selectedAnchorIDString =
                selectedAnchorID.uuidString
        }

        if let selectedAlbumIdentifier {
            self.selectedAlbumIdentifier =
                selectedAlbumIdentifier
        }

        if let selectedAlbumTitle {
            self.selectedAlbumTitle =
                selectedAlbumTitle
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
            let data = defaults.data(
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
            let data = defaults.data(
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
            let data = defaults.data(
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

        if defaults.object(
            forKey: Keys.shouldWritePhotoDescription
        ) != nil {

            shouldWritePhotoDescription =
                defaults.bool(
                    forKey: Keys.shouldWritePhotoDescription
                )
        }

        photoDescriptionOverride =
            defaults.string(
                forKey: Keys.photoDescriptionOverride
            ) ?? ""
    }

    private func loadEditorState() {

        selectedAnchorIDString =
            defaults.string(
                forKey: Keys.selectedAnchorID
            ) ?? ""

        selectedAlbumIdentifier =
            defaults.string(
                forKey: Keys.selectedAlbumIdentifier
            ) ?? ""

        selectedAlbumTitle =
            defaults.string(
                forKey: Keys.selectedAlbumTitle
            ) ?? ""
    }

    private func loadConfigurationSlots() {

        if let activeSlotRawValue =
            defaults.string(
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
                defaults.data(
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

    func decodeValueResult<Value: Decodable>(
        _ valueType: Value.Type,
        forKey storageKey: String
    ) -> PhotoMemoSharedDefaultsReadResult<
        Value
    > {

        guard
            let data = defaults.data(
                forKey: storageKey
            )
        else {
            return .noValue
        }

        do {
            return .success(
                try JSONDecoder().decode(
                    valueType,
                    from: data
                )
            )
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey: storageKey,
                    payloadByteCount: data.count,
                    underlyingDescription:
                        String(
                            describing: error
                        )
                )
            )
        }
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
        selectedAlbumIdentifier: String? = nil
    ) -> BatchConfigurationSnapshot {

        let resolvedSelectedAnchorIDString =
            selectedAnchorID?.uuidString
            ?? selectedAnchorIDString

        return snapshotProvider.makeSnapshot(
            template: selectedTemplate,
            badge: selectedBadge,
            anchors: anchors,
            selectedAnchorIDString:
                resolvedSelectedAnchorIDString,
            memorySubjectText:
                defaults.string(
                    forKey:
                        Keys.selectedMemorySubjectText
                ),
            shouldWritePhotoDescription:
                shouldWritePhotoDescription,
            photoDescriptionOverride:
                photoDescriptionOverride,
            selectedAlbumIdentifier:
                selectedAlbumIdentifier
                ?? self.selectedAlbumIdentifier
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

        snapshotProvider
            .normalizedAlbumIdentifier(identifier)
    }
}
