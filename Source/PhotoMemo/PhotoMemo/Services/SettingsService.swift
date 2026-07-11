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
            return .classicWhite

        case .slot2:
            return .classicWhite

        case .slot3:
            return .classicWhite
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

    let configurationLibrary:
        ConfigurationLibraryRecord?

    let subjectLibraryResult:
        PhotoMemoSharedDefaultsReadResult<
            V1SubjectLibraryRecord
        >

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

    let mediaOutputMode:
        V1MediaOutputMode
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

    private let configurationLibraryRepository:
        ConfigurationLibraryRepository

    private let configurationLibraryStorage:
        (any ConfigurationLibraryDataStorage)?

    private let configurationLibraryProjection:
        (@MainActor (ConfigurationLibraryRecord) throws -> Void)?

    private(set) var configurationLibraryStartupRecoveryError:
        ConfigurationLibraryPersistenceError?

    private var recoveredConfigurationLibrary:
        ConfigurationLibraryRecord?

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

        static let mediaOutputMode =
            "photomemo.v1.mediaOutputMode"

        static let selectedMemorySubject =
            "photomemo.selectedMemorySubject"

        static let selectedMemorySubjectText =
            "photomemo.selectedMemorySubjectText"

        static let locationDisplayConfiguration =
            "photomemo.locationDisplayConfiguration"

        static let subjectLibrary =
            "photomemo.v1.subjectLibrary"

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
    var mediaOutputMode:
        V1MediaOutputMode = .originalFormat

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
        let configurationLibraryStorage =
            FileConfigurationLibraryStorage(
                legacyDefaults: self.defaults
            )
        self.configurationLibraryStorage =
            configurationLibraryStorage
        self.configurationLibraryRepository =
            ConfigurationLibraryRepository(
                persistence:
                    ConfigurationLibraryPersistence(
                        storage:
                            configurationLibraryStorage
                    )
            )
        self.configurationLibraryProjection = nil
        self.configurationLibraryStartupRecoveryError = nil
        self.recoveredConfigurationLibrary = nil

        replayConfigurationLibraryProjectionIfAvailable()

        loadConfigurationSlots()

        loadAnchors()

        loadTemplate()

        loadBadge()

        loadPhotoDescriptionSettings()

        loadEditorState()

        loadMediaOutputMode()

        if selectedTemplate == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedTemplate = .classicWhite
        }

        if selectedBadge == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedBadge = Badge.none
        }
    }

    convenience init(
        defaults: UserDefaults
    ) {
        self.init(
            defaults: defaults,
            isolatedConfigurationLibraryBaseDirectoryURL:
                FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
        )
    }

    init(
        defaults: UserDefaults,
        isolatedConfigurationLibraryBaseDirectoryURL: URL
    ) {
        self.defaults = defaults
        self.snapshotProvider =
            BatchConfigurationSnapshotProvider(
                defaults: self.defaults
            )
        let configurationLibraryStorage =
            FileConfigurationLibraryStorage(
                baseDirectoryURL:
                    isolatedConfigurationLibraryBaseDirectoryURL,
                legacyDefaults: nil
            )
        self.configurationLibraryStorage =
            configurationLibraryStorage
        self.configurationLibraryRepository =
            ConfigurationLibraryRepository(
                persistence:
                    ConfigurationLibraryPersistence(
                        storage:
                            configurationLibraryStorage
                    )
            )
        self.configurationLibraryProjection = nil
        self.configurationLibraryStartupRecoveryError = nil
        self.recoveredConfigurationLibrary = nil

        replayConfigurationLibraryProjectionIfAvailable()

        loadConfigurationSlots()

        loadAnchors()

        loadTemplate()

        loadBadge()

        loadPhotoDescriptionSettings()

        loadEditorState()

        loadMediaOutputMode()

        if selectedTemplate == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedTemplate = .classicWhite
        }

        if selectedBadge == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedBadge = Badge.none
        }
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
        self.defaults = defaults
        self.snapshotProvider =
            BatchConfigurationSnapshotProvider(
                defaults: self.defaults
            )
        self.configurationLibraryRepository =
            configurationLibraryRepository
        self.configurationLibraryStorage =
            configurationLibraryStorage
        self.configurationLibraryProjection =
            configurationLibraryProjection
        self.configurationLibraryStartupRecoveryError = nil
        self.recoveredConfigurationLibrary = nil

        replayConfigurationLibraryProjectionIfAvailable()

        loadConfigurationSlots()
        loadAnchors()
        loadTemplate()
        loadBadge()
        loadPhotoDescriptionSettings()
        loadEditorState()
        loadMediaOutputMode()

        if selectedTemplate == nil,
           configurationLibraryStartupRecoveryError == nil {
            selectedTemplate = .classicWhite
        }
        if selectedBadge == nil,
           configurationLibraryStartupRecoveryError == nil {
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

    func saveV1SubjectLibrary(
        subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset] = [],
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {
        let record =
            V1SubjectLibraryRecord(
                subjects: subjects,
                selectedSubjectID: selectedSubjectID,
                memoryPresets: memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            )

        guard let data =
            try? JSONEncoder().encode(record)
        else {
            return
        }

        defaults.set(
            data,
            forKey: Keys.subjectLibrary
        )

        let selectedSubject =
            subjects.first {
                $0.id == selectedSubjectID
            }
            ?? subjects.first

        saveSelectedMemorySubject(selectedSubject)
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

    func saveLocationDisplayConfiguration(
        _ configuration: ExpressionModuleConfiguration?
    ) {
        guard let configuration else {
            defaults.removeObject(
                forKey:
                    Keys.locationDisplayConfiguration
            )
            return
        }

        guard
            let data =
                try? JSONEncoder().encode(
                    configuration
                )
        else {
            return
        }

        defaults.set(
            data,
            forKey:
                Keys.locationDisplayConfiguration
        )
    }

    func saveMediaOutputMode(
        _ mode: V1MediaOutputMode
    ) {
        mediaOutputMode = mode
        defaults.set(
            mode.rawValue,
            forKey: Keys.mediaOutputMode
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
        saveMediaOutputMode(mediaOutputMode)
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

    func loadV1SubjectLibraryResult()
    -> PhotoMemoSharedDefaultsReadResult<
        V1SubjectLibraryRecord
    > {

        decodeValueResult(
            V1SubjectLibraryRecord.self,
            forKey: Keys.subjectLibrary
        )
    }

    func loadV1BootstrapReadState()
    -> V1ConfigurationBootstrapReadState {

        loadEditorState()

        return V1ConfigurationBootstrapReadState(
            configurationLibrary:
                recoveredConfigurationLibrary,
            subjectLibraryResult:
                loadV1SubjectLibraryResult(),
            subjectResult:
                loadV1SelectedSubjectResult(),
            badgeResult:
                snapshotProvider
                .loadBadgeResult(),
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
        try await configurationLibraryRepository.save(
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
                    try emitCompatibilityProjections(
                        from: saved
                    )
                }
                afterSuccessfulProjection(
                    buildBatchConfigurationSnapshot()
                        .withConfigurationIdentity(
                            id: provisionalReceipt
                                .configurationID,
                            revision: provisionalReceipt
                                .revision
                        ),
                    provisionalReceipt
                )
            }
        )
    }

    func loadConfigurationLibrary()
    async throws -> ConfigurationLibraryLoadReceipt {
        try await configurationLibraryRepository.load()
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

    private func loadMediaOutputMode() {
        guard let rawValue =
            defaults.string(
                forKey: Keys.mediaOutputMode
            ),
              let mode =
            V1MediaOutputMode(rawValue: rawValue)
        else {
            mediaOutputMode = .originalFormat
            return
        }

        mediaOutputMode = mode
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
                        ),
                    rawPayload: data
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
                ?? self.selectedAlbumIdentifier,
            locationDisplayConfiguration:
                loadLocationDisplayConfiguration(),
            mediaOutputModeRawValue:
                mediaOutputMode.rawValue
        )
    }

    func loadLocationDisplayConfiguration()
    -> ExpressionModuleConfiguration? {
        guard
            let data =
                defaults.data(
                    forKey:
                        Keys.locationDisplayConfiguration
                )
        else {
            return nil
        }

        return try? JSONDecoder().decode(
            ExpressionModuleConfiguration.self,
            from: data
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

    private func emitCompatibilityProjections(
        from aggregate: ConfigurationLibraryRecord
    ) throws {
        guard
            let activeSubjectID = aggregate.activeSubjectID,
            let activeConfigurationID =
                aggregate.activeConfigurationID,
            let activeSubjectRecord =
                aggregate.subjects.first(where: {
                    $0.subject.id == activeSubjectID
                }),
            let activeConfiguration =
                activeSubjectRecord.configurations.first(
                    where: {
                        $0.id == activeConfigurationID
                    }
                )
        else {
            throw ConfigurationLibraryPersistenceError
                .missingActiveSelection
        }

        let subjectLibrary = V1SubjectLibraryRecord(
            subjects: aggregate.subjects.map(\.subject),
            selectedSubjectID: activeSubjectID,
            memoryPresets:
                aggregate.subjects.flatMap { subjectRecord in
                    subjectRecord.configurations.map {
                        legacyMemoryPreset(
                            from: $0,
                            subjectID:
                                subjectRecord.subject.id
                        )
                    }
                },
            selectedMemoryPresetID:
                activeConfigurationID
        )

        defaults.set(
            try JSONEncoder().encode(subjectLibrary),
            forKey: Keys.subjectLibrary
        )
        defaults.set(
            try JSONEncoder().encode(
                activeSubjectRecord.subject
            ),
            forKey: Keys.selectedMemorySubject
        )
        defaults.set(
            activeSubjectRecord.subject
                .resolvedExpressionSubjectText,
            forKey: Keys.selectedMemorySubjectText
        )

        selectedTemplate =
            activeConfiguration.editor.template
                .normalizedForEditing
        defaults.set(
            try JSONEncoder().encode(
                activeConfiguration.editor.template
                    .normalizedForEditing
            ),
            forKey: Keys.selectedTemplate
        )

        selectedBadge = legacyBadge(
            from: activeConfiguration.presentation.logo.badge
        )
        if let selectedBadge {
            defaults.set(
                try JSONEncoder().encode(selectedBadge),
                forKey: Keys.selectedBadge
            )
        } else {
            defaults.removeObject(forKey: Keys.selectedBadge)
        }

        if let locationConfiguration =
            activeConfiguration.presentation
                .locationConfiguration {
            defaults.set(
                try JSONEncoder().encode(
                    locationConfiguration
                ),
                forKey: Keys.locationDisplayConfiguration
            )
        } else {
            defaults.removeObject(
                forKey: Keys.locationDisplayConfiguration
            )
        }

        shouldWritePhotoDescription =
            activeConfiguration.output
                .photosDescriptionPolicy.isEnabled
        photoDescriptionOverride =
            activeConfiguration.output
                .photosDescriptionPolicy.overrideText
        defaults.set(
            shouldWritePhotoDescription,
            forKey: Keys.shouldWritePhotoDescription
        )
        defaults.set(
            photoDescriptionOverride,
            forKey: Keys.photoDescriptionOverride
        )

        selectedAnchorIDString =
            activeConfiguration.selectedTimeAnchorID?
                .uuidString ?? ""
        selectedAlbumIdentifier =
            legacyAlbumIdentifier(
                activeConfiguration.output.album
            )
        selectedAlbumTitle =
            activeConfiguration.output.album.title
        defaults.set(
            selectedAnchorIDString,
            forKey: Keys.selectedAnchorID
        )
        defaults.set(
            selectedAlbumIdentifier,
            forKey: Keys.selectedAlbumIdentifier
        )
        defaults.set(
            selectedAlbumTitle,
            forKey: Keys.selectedAlbumTitle
        )

        mediaOutputMode =
            activeConfiguration.output.mediaMode
        defaults.set(
            mediaOutputMode.rawValue,
            forKey: Keys.mediaOutputMode
        )

        let projectedSnapshot = buildBatchConfigurationSnapshot()
            .withConfigurationIdentity(
                id: activeConfigurationID,
                revision: aggregate.revision
            )
        configurationSlots = configurationSlots.map { slot in
            guard slot.id == activeConfigurationSlotID else {
                return slot
            }
            var projectedSlot = slot
            projectedSlot.snapshot = projectedSnapshot
            projectedSlot.updatedAt = activeConfiguration.savedAt
            return projectedSlot
        }
        saveConfigurationSlots()
    }

    private func legacyBadge(
        from descriptor:
            MemoryConfigurationRecord.Presentation.Logo
            .BadgeDescriptor?
    ) -> Badge? {
        guard let descriptor else {
            return nil
        }
        return Badge(
            id: descriptor.id,
            name: descriptor.name,
            type: descriptor.type,
            imageName: descriptor.imageName,
            imagePath:
                descriptor.assetReference?.relativePath,
            systemSymbol: descriptor.systemSymbol,
            isSystemDefault: descriptor.isSystemDefault
        )
    }

    private func legacyMemoryPreset(
        from configuration: MemoryConfigurationRecord,
        subjectID: UUID
    ) -> MemoryPreset {
        MemoryPreset(
            id: configuration.id,
            title: configuration.title,
            summary: "",
            regionTemplateIDs:
                configuration.editor.regionTemplateIDs,
            savedAt: configuration.savedAt,
            selectedSubjectID: subjectID,
            selectedTimeAnchorID:
                configuration.selectedTimeAnchorID,
            outputOption: .processedImage,
            storageOption: .appFolder,
            logoMode:
                configuration.presentation.logo.mode,
            usesCustomMemoryWriteText:
                configuration.editor.memoryCopy
                    .usesCustomText,
            customMemoryWriteText:
                configuration.editor.memoryCopy
                    .customText,
            savedOutputConfiguration:
                legacyOutputConfiguration(
                    configuration.output
                )
        )
    }

    private func legacyOutputConfiguration(
        _ output: MemoryConfigurationRecord.Output
    ) -> V1SavedOutputConfiguration {
        let outputTarget: V1IOSOutputTarget
        switch output.album.destination {
        case .automatic:
            outputTarget = .automatic
        case .applePhotos:
            outputTarget = .applePhotos
        case .existingAlbum:
            outputTarget = .existingAlbum
        case .newAlbum:
            outputTarget = .newAlbum
        }
        return V1SavedOutputConfiguration(
            outputTarget: outputTarget,
            mediaOutputMode: output.mediaMode,
            selectedExistingAlbumIdentifier:
                output.album.destination == .existingAlbum
                ? output.album.identifier
                : "",
            newAlbumName:
                output.album.destination == .newAlbum
                ? output.album.title
                : ""
        )
    }

    private func legacyAlbumIdentifier(
        _ album: MemoryConfigurationRecord.Output
            .AlbumDescriptor
    ) -> String {
        switch album.destination {
        case .automatic:
            return PhotoMemoAlbumSelection
                .automaticIdentifier
        case .applePhotos:
            return PhotoMemoAlbumSelection
                .systemLibraryIdentifier
        case .existingAlbum,
             .newAlbum:
            return album.identifier
        }
    }

    private func replayConfigurationLibraryProjectionIfAvailable() {
        guard let configurationLibraryStorage else {
            return
        }
        do {
            let snapshot = try
                ConfigurationLibrarySynchronousStorageLoader
                .snapshot(from: configurationLibraryStorage)
            guard let recovered = try
                ConfigurationLibraryRecordRecovery.recover(
                    from: snapshot,
                    allowNoValue: true
                )
            else {
                return
            }
            recoveredConfigurationLibrary =
                recovered.aggregate
            try emitCompatibilityProjections(
                from: recovered.aggregate
            )
        } catch ConfigurationLibraryPersistenceTransportError
            .readFailed(let description) {
            configurationLibraryStartupRecoveryError =
                .readFailed(description)
        } catch let error as
            ConfigurationLibraryPersistenceError {
            configurationLibraryStartupRecoveryError = error
        } catch {
            configurationLibraryStartupRecoveryError =
                .encodingFailed(String(describing: error))
        }
    }
}
