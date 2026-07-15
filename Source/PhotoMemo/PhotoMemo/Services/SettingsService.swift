#if !PHOTOMEMO_SHARE_EXTENSION
import Combine
import Foundation

enum WorkspaceConfigurationSlotID:
    String,
    Codable,
    CaseIterable,
    Hashable,
    Identifiable {

    case slot1
    case slot2
    case slot3

    var id: String { rawValue }

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
        .classicWhite
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

    var title: String { id.title }

    var resolvedCustomTitle: String? {
        guard let trimmedTitle = customTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines),
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

    var defaultPreset: TemplatePreset { id.defaultPreset }
    var isCustomized: Bool { snapshot != nil }

    var resolvedDisplayName: String {
        guard let trimmedName = snapshot?.template.name
            .trimmingCharacters(in: .whitespacesAndNewlines),
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
        WorkspaceConfigurationSlotID.allCases.map {
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
        WorkspaceConfigurationSlotID.allCases.map { slotID in
            slots.first(where: { $0.id == slotID })
            ?? WorkspaceConfigurationSlot(
                id: slotID,
                customTitle: nil,
                snapshot: nil,
                updatedAt: nil
            )
        }
    }
}

struct V1ConfigurationBootstrapReadState {
    let configurationLibrary: ConfigurationLibraryRecord?
    let subjectLibraryResult:
        PhotoMemoSharedDefaultsReadResult<V1SubjectLibraryRecord>
    let subjectResult:
        PhotoMemoSharedDefaultsReadResult<MemorySubject>
    let badgeResult:
        PhotoMemoSharedDefaultsReadResult<Badge>
    let selectedAlbumIdentifier: String
    let selectedAlbumTitle: String
    let mediaOutputMode: V1MediaOutputMode
}

@MainActor
final class SettingsService: ObservableObject {

    private let autosaveDelayNanoseconds: UInt64 = 350_000_000
    private var templateSaveTask: Task<Void, Never>?
    private var editorStateSaveTask: Task<Void, Never>?
    private var photoDescriptionSaveTask: Task<Void, Never>?

    private let legacyStore: LegacySettingsStore
    private let configurationLibraryStore: ConfigurationLibraryStore
    private let configurationProjectionService:
        ConfigurationProjectionService
    private let configurationLibraryProjection:
        (@MainActor (ConfigurationLibraryRecord) throws -> Void)?

    private(set) var configurationLibraryStartupRecoveryError:
        ConfigurationLibraryPersistenceError?

    @Published var anchors: [Anchor] = []
    @Published var selectedTemplate: Template?
    @Published var selectedBadge: Badge?
    @Published var shouldWritePhotoDescription = true
    @Published var photoDescriptionOverride = ""
    @Published var selectedAnchorIDString = ""
    @Published var selectedAlbumIdentifier = ""
    @Published var selectedAlbumTitle = ""
    @Published var mediaOutputMode: V1MediaOutputMode = .originalFormat
    @Published var activeConfigurationSlotID:
        WorkspaceConfigurationSlotID = .slot1
    @Published var configurationSlots:
        [WorkspaceConfigurationSlot] =
            WorkspaceConfigurationSlot.defaultSlots

    init() {
        let defaults = PhotoMemoSharedContainer.sharedUserDefaults
        let storage = FileConfigurationLibraryStorage(
            legacyDefaults: defaults
        )
        let legacyStore = LegacySettingsStore(defaults: defaults)
        self.legacyStore = legacyStore
        self.configurationLibraryStore = ConfigurationLibraryStore(
            repository: ConfigurationLibraryRepository(
                persistence: ConfigurationLibraryPersistence(
                    storage: storage
                )
            ),
            storage: storage
        )
        self.configurationProjectionService =
            ConfigurationProjectionService(
                legacyStore: legacyStore,
                snapshotProvider:
                    BatchConfigurationSnapshotProvider(
                        defaults: defaults
                    )
            )
        self.configurationLibraryProjection = nil
        self.configurationLibraryStartupRecoveryError = nil
        restoreInitialState()
    }

    convenience init(defaults: UserDefaults) {
        self.init(
            defaults: defaults,
            configurationLibraryBaseDirectoryURL:
                FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
        )
    }

    init(
        defaults: UserDefaults,
        configurationLibraryBaseDirectoryURL: URL
    ) {
        let storage = FileConfigurationLibraryStorage(
            baseDirectoryURL:
                configurationLibraryBaseDirectoryURL,
            legacyDefaults: defaults
        )
        let legacyStore = LegacySettingsStore(defaults: defaults)
        self.legacyStore = legacyStore
        self.configurationLibraryStore = ConfigurationLibraryStore(
            repository: ConfigurationLibraryRepository(
                persistence: ConfigurationLibraryPersistence(
                    storage: storage
                )
            ),
            storage: storage
        )
        self.configurationProjectionService =
            ConfigurationProjectionService(
                legacyStore: legacyStore,
                snapshotProvider:
                    BatchConfigurationSnapshotProvider(
                        defaults: defaults
                    )
            )
        self.configurationLibraryProjection = nil
        self.configurationLibraryStartupRecoveryError = nil
        restoreInitialState()
    }

    init(
        defaults: UserDefaults,
        configurationLibraryRepository:
            ConfigurationLibraryRepository,
        configurationLibraryStorage:
            (any ConfigurationLibraryDataStorage)? = nil,
        configurationLibraryProjection:
            (@MainActor (ConfigurationLibraryRecord) throws -> Void)? = nil
    ) {
        let legacyStore = LegacySettingsStore(defaults: defaults)
        self.legacyStore = legacyStore
        self.configurationLibraryStore = ConfigurationLibraryStore(
            repository: configurationLibraryRepository,
            storage: configurationLibraryStorage
        )
        self.configurationProjectionService =
            ConfigurationProjectionService(
                legacyStore: legacyStore,
                snapshotProvider:
                    BatchConfigurationSnapshotProvider(
                        defaults: defaults
                    )
            )
        self.configurationLibraryProjection =
            configurationLibraryProjection
        self.configurationLibraryStartupRecoveryError = nil
        restoreInitialState()
    }

    func saveAnchors() {
        legacyStore.saveAnchors(anchors)
    }

    func saveTemplate() {
        legacyStore.saveTemplate(selectedTemplate)
    }

    func scheduleTemplateSave() {
        templateSaveTask?.cancel()
        templateSaveTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: autosaveDelayNanoseconds
            )
            guard !Task.isCancelled else {
                return
            }
            saveTemplate()
        }
    }

    func saveBadge() {
        legacyStore.saveBadge(selectedBadge)
    }

    func saveSelectedMemorySubject(
        _ subject: MemorySubject?
    ) {
        legacyStore.saveSelectedMemorySubject(subject)
    }

    func saveV1SubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {
        let record = V1SubjectLibraryRecord(
            subjects: subjects,
            selectedSubjectID: selectedSubjectID,
            memoryPresets: memoryPresets,
            selectedMemoryPresetID: selectedMemoryPresetID
        )
        guard legacyStore.saveSubjectLibrary(record) else {
            return
        }
        let selectedSubject = subjects.first {
            $0.id == selectedSubjectID
        } ?? subjects.first
        saveSelectedMemorySubject(selectedSubject)
    }

    func savePhotoDescriptionSettings() {
        legacyStore.savePhotoDescriptionSettings(
            LegacyPhotoDescriptionSettings(
                shouldWrite: shouldWritePhotoDescription,
                override: photoDescriptionOverride
            )
        )
    }

    func saveLocationDisplayConfiguration(
        _ configuration: ExpressionModuleConfiguration?
    ) {
        legacyStore.saveLocationDisplayConfiguration(configuration)
    }

    func saveMediaOutputMode(_ mode: V1MediaOutputMode) {
        mediaOutputMode = mode
        legacyStore.saveMediaOutputMode(mode)
    }

    func schedulePhotoDescriptionSettingsSave() {
        photoDescriptionSaveTask?.cancel()
        photoDescriptionSaveTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: autosaveDelayNanoseconds
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
        saveMediaOutputMode(mediaOutputMode)
        saveConfigurationSlots()
    }

    func saveEditorState(
        selectedAnchorID: UUID? = nil,
        selectedAlbumIdentifier: String? = nil,
        selectedAlbumTitle: String? = nil
    ) {
        updateEditorState(
            selectedAnchorID: selectedAnchorID,
            selectedAlbumIdentifier: selectedAlbumIdentifier,
            selectedAlbumTitle: selectedAlbumTitle
        )
        legacyStore.saveEditorState(currentEditorState)
    }

    func reloadV1BootstrapState() {
        switch legacyStore.loadBadgeResult() {
        case .noValue:
            break
        case .success(let badge):
            selectedBadge = badge
        case .decodingFailed:
            selectedBadge = nil
        }
        restoreEditorState()
    }

    func loadV1SelectedSubjectResult()
    -> PhotoMemoSharedDefaultsReadResult<MemorySubject> {
        legacyStore.loadSelectedMemorySubjectResult()
    }

    func loadV1SubjectLibraryResult()
    -> PhotoMemoSharedDefaultsReadResult<V1SubjectLibraryRecord> {
        legacyStore.loadSubjectLibraryResult()
    }

    func loadV1BootstrapReadState()
    -> V1ConfigurationBootstrapReadState {
        restoreEditorState()
        return V1ConfigurationBootstrapReadState(
            configurationLibrary:
                configurationLibraryStore.recoveredAggregate,
            subjectLibraryResult:
                loadV1SubjectLibraryResult(),
            subjectResult:
                loadV1SelectedSubjectResult(),
            badgeResult:
                legacyStore.loadBadgeResult(),
            selectedAlbumIdentifier:
                selectedAlbumIdentifier,
            selectedAlbumTitle:
                selectedAlbumTitle,
            mediaOutputMode:
                mediaOutputMode
        )
    }

    func saveConfigurationLibrary(
        _ aggregate: ConfigurationLibraryRecord,
        afterSuccessfulProjection:
            @MainActor (
                BatchConfigurationSnapshot,
                ConfigurationLibrarySaveReceipt
            ) -> Void = { _, _ in }
    ) async throws -> ConfigurationLibrarySaveReceipt {
        try await configurationLibraryStore.save(
            aggregate,
            compatibilityProjection: {
                [weak self]
                saved,
                provisionalReceipt in
                guard let self else {
                    return
                }
                if let configurationLibraryProjection {
                    try configurationLibraryProjection(saved)
                } else {
                    try applyDefaultProjection(saved)
                }
                afterSuccessfulProjection(
                    buildBatchConfigurationSnapshot()
                        .withConfigurationIdentity(
                            id: provisionalReceipt.configurationID,
                            revision:
                                provisionalReceipt
                                .configurationRevision
                        ),
                    provisionalReceipt
                )
            }
        )
    }

    func loadConfigurationLibrary()
    async throws -> ConfigurationLibraryLoadReceipt {
        try await configurationLibraryStore.load()
    }

    func resolveDurableProductionConfiguration(
        _ reference: ProductionConfigurationReference
    ) throws -> BatchConfigurationSnapshot {
        try configurationLibraryStore
            .resolveDurableProductionConfiguration(reference)
    }

    func saveConfigurationSlots() {
        legacyStore.saveConfigurationSlots(
            activeSlotID: activeConfigurationSlotID,
            slots: configurationSlots
        )
    }

    func updateConfigurationSlot(
        _ slotID: WorkspaceConfigurationSlotID,
        snapshot: BatchConfigurationSnapshot?
    ) {
        configurationSlots = configurationSlots.map { slot in
            guard slot.id == slotID else {
                return slot
            }
            var updatedSlot = slot
            updatedSlot.snapshot = snapshot
            updatedSlot.updatedAt = snapshot == nil ? nil : Date()
            return updatedSlot
        }
        saveConfigurationSlots()
    }

    func configurationSlot(
        for slotID: WorkspaceConfigurationSlotID
    ) -> WorkspaceConfigurationSlot? {
        configurationSlots.first { $0.id == slotID }
    }

    func renameConfigurationSlot(
        _ slotID: WorkspaceConfigurationSlotID,
        customTitle: String?
    ) {
        configurationSlots = configurationSlots.map { slot in
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
        updateEditorState(
            selectedAnchorID: selectedAnchorID,
            selectedAlbumIdentifier: selectedAlbumIdentifier,
            selectedAlbumTitle: selectedAlbumTitle
        )
        editorStateSaveTask?.cancel()
        editorStateSaveTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: autosaveDelayNanoseconds
            )
            guard !Task.isCancelled else {
                return
            }
            saveEditorState()
        }
    }

    func decodeValueResult<Value: Decodable>(
        _ valueType: Value.Type,
        forKey storageKey: String
    ) -> PhotoMemoSharedDefaultsReadResult<Value> {
        legacyStore.decodeValueResult(
            valueType,
            forKey: storageKey
        )
    }
}

extension SettingsService {

    var resolvedSelectedAnchor: Anchor? {
        resolvedAnchor(for: selectedAnchorIDString)
    }

    func resolvedAnchor(
        for identifierString: String
    ) -> Anchor? {
        guard let identifier = UUID(
            uuidString: identifierString
        ) else {
            return nil
        }
        return anchors.first { $0.id == identifier }
    }

    func buildBatchConfigurationSnapshot(
        selectedAnchorID: UUID? = nil,
        selectedAlbumIdentifier: String? = nil
    ) -> BatchConfigurationSnapshot {
        configurationProjectionService
            .buildBatchConfigurationSnapshot(
                input: ConfigurationSnapshotProjectionInput(
                    selectedTemplate: selectedTemplate,
                    selectedBadge: selectedBadge,
                    anchors: anchors,
                    selectedAnchorIDString:
                        selectedAnchorID?.uuidString
                        ?? selectedAnchorIDString,
                    selectedAlbumIdentifier:
                        selectedAlbumIdentifier
                        ?? self.selectedAlbumIdentifier,
                    shouldWritePhotoDescription:
                        shouldWritePhotoDescription,
                    photoDescriptionOverride:
                        photoDescriptionOverride,
                    mediaOutputMode: mediaOutputMode
                ),
                durableAggregate:
                    configurationLibraryStore
                    .recoveredAggregate
            )
    }

    func loadLocationDisplayConfiguration()
    -> ExpressionModuleConfiguration? {
        legacyStore.loadLocationDisplayConfiguration()
    }

    var normalizedSelectedAlbumIdentifier: String {
        normalizedAlbumIdentifier(selectedAlbumIdentifier)
    }

    func normalizedAlbumIdentifier(
        _ identifier: String
    ) -> String {
        configurationProjectionService
            .normalizedAlbumIdentifier(identifier)
    }
}

private extension SettingsService {

    var currentEditorState: LegacySettingsEditorState {
        LegacySettingsEditorState(
            selectedAnchorIDString: selectedAnchorIDString,
            selectedAlbumIdentifier: selectedAlbumIdentifier,
            selectedAlbumTitle: selectedAlbumTitle
        )
    }

    func restoreInitialState() {
        replayConfigurationLibraryProjectionIfAvailable()
        restoreCompatibilityProjectionState()
        let slots = legacyStore.loadConfigurationSlots()
        activeConfigurationSlotID = slots.activeSlotID
        configurationSlots = slots.slots

        if selectedTemplate == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedTemplate = .classicWhite
        }
        if selectedBadge == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedBadge = Badge.none
        }
    }

    func restoreCompatibilityProjectionState() {
        anchors = legacyStore.loadAnchors()
        selectedTemplate = legacyStore.loadTemplate()
        selectedBadge = legacyStore.loadBadge()
        let photoDescription =
            legacyStore.loadPhotoDescriptionSettings()
        shouldWritePhotoDescription =
            photoDescription.shouldWrite
        photoDescriptionOverride =
            photoDescription.override
        restoreEditorState()
        mediaOutputMode = legacyStore.loadMediaOutputMode()
    }

    func restoreEditorState() {
        let editorState = legacyStore.loadEditorState()
        selectedAnchorIDString =
            editorState.selectedAnchorIDString
        selectedAlbumIdentifier =
            editorState.selectedAlbumIdentifier
        selectedAlbumTitle =
            editorState.selectedAlbumTitle
    }

    func updateEditorState(
        selectedAnchorID: UUID?,
        selectedAlbumIdentifier: String?,
        selectedAlbumTitle: String?
    ) {
        if let selectedAnchorID {
            selectedAnchorIDString =
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
    }

    func replayConfigurationLibraryProjectionIfAvailable() {
        configurationLibraryStore
            .replayProjectionIfAvailable { aggregate in
                try applyDefaultProjection(aggregate)
            }
        configurationLibraryStartupRecoveryError =
            configurationLibraryStore.startupRecoveryError
    }

    func applyDefaultProjection(
        _ aggregate: ConfigurationLibraryRecord
    ) throws {
        let projection = try configurationProjectionService
            .projectAndPersist(aggregate)

        selectedTemplate = projection.template
        selectedBadge = projection.badge
        shouldWritePhotoDescription =
            projection.photoDescriptionSettings.shouldWrite
        photoDescriptionOverride =
            projection.photoDescriptionSettings.override
        selectedAnchorIDString =
            projection.editorState.selectedAnchorIDString
        selectedAlbumIdentifier =
            projection.editorState.selectedAlbumIdentifier
        selectedAlbumTitle =
            projection.editorState.selectedAlbumTitle
        mediaOutputMode = projection.mediaOutputMode

        let projectedSnapshot =
            buildBatchConfigurationSnapshot()
            .withConfigurationIdentity(
                id: projection
                    .productionConfigurationReference
                    .configurationID,
                revision: projection
                    .productionConfigurationReference
                    .revision
            )
        configurationSlots = configurationSlots.map { slot in
            guard slot.id == activeConfigurationSlotID else {
                return slot
            }
            var projectedSlot = slot
            projectedSlot.snapshot = projectedSnapshot
            projectedSlot.updatedAt = projection.savedAt
            return projectedSlot
        }
        saveConfigurationSlots()
    }
}
#endif
