#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct LegacySettingsEditorState: Equatable {
    var selectedAnchorIDString: String
    var selectedAlbumIdentifier: String
    var selectedAlbumTitle: String
}

struct LegacyPhotoDescriptionSettings: Equatable {
    var shouldWrite: Bool
    var override: String
}

@MainActor
final class LegacySettingsStore {

    private let defaults: UserDefaults

    private enum Keys {
        static let anchors = "photomemo.anchors"
        static let selectedTemplate = "photomemo.selectedTemplate"
        static let selectedBadge = "photomemo.selectedBadge"
        static let shouldWritePhotoDescription =
            "photomemo.shouldWritePhotoDescription"
        static let photoDescriptionOverride =
            "photomemo.photoDescriptionOverride"
        static let selectedAnchorID = "photomemo.selectedAnchorID"
        static let selectedAlbumIdentifier =
            "photomemo.selectedAlbumIdentifier"
        static let selectedAlbumTitle =
            "photomemo.selectedAlbumTitle"
        static let mediaOutputMode = "photomemo.v1.mediaOutputMode"
        static let selectedMemorySubject =
            "photomemo.selectedMemorySubject"
        static let productionConfigurationReference =
            "photomemo.productionConfigurationReference"
        static let selectedMemorySubjectText =
            "photomemo.selectedMemorySubjectText"
        static let locationDisplayConfiguration =
            "photomemo.locationDisplayConfiguration"
        static let subjectLibrary = "photomemo.v1.subjectLibrary"
        static let activeConfigurationSlotID =
            "photomemo.activeConfigurationSlotID"
        static let configurationSlots = "photomemo.configurationSlots"
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func saveAnchors(_ anchors: [Anchor]) {
        try? setEncoded(anchors, forKey: Keys.anchors)
    }

    func loadAnchors() -> [Anchor] {
        guard let data = defaults.data(forKey: Keys.anchors) else {
            return []
        }
        return (try? JSONDecoder().decode([Anchor].self, from: data)) ?? []
    }

    func saveTemplate(_ template: Template?) {
        guard let template else {
            defaults.removeObject(forKey: Keys.selectedTemplate)
            return
        }
        try? setEncoded(template, forKey: Keys.selectedTemplate)
    }

    func loadTemplate() -> Template? {
        guard let data = defaults.data(forKey: Keys.selectedTemplate),
              let decoded = try? JSONDecoder().decode(
                  Template.self,
                  from: data
              ) else {
            return nil
        }
        let normalized = decoded.normalizedForEditing
        if normalized != decoded {
            saveTemplate(normalized)
        }
        return normalized
    }

    func saveBadge(_ badge: Badge?) {
        guard let badge else {
            defaults.removeObject(forKey: Keys.selectedBadge)
            return
        }
        try? setEncoded(badge, forKey: Keys.selectedBadge)
    }

    func loadBadge() -> Badge? {
        guard let data = defaults.data(forKey: Keys.selectedBadge) else {
            return nil
        }
        return try? JSONDecoder().decode(Badge.self, from: data)
    }

    func saveSelectedMemorySubject(_ subject: MemorySubject?) {
        guard let subject else {
            defaults.removeObject(forKey: Keys.selectedMemorySubject)
            defaults.removeObject(forKey: Keys.selectedMemorySubjectText)
            return
        }
        do {
            try setEncoded(
                subject,
                forKey: Keys.selectedMemorySubject
            )
        } catch {
            return
        }
        defaults.set(
            subject.resolvedExpressionSubjectText,
            forKey: Keys.selectedMemorySubjectText
        )
    }

    @discardableResult
    func saveSubjectLibrary(_ record: V1SubjectLibraryRecord) -> Bool {
        do {
            try setEncoded(record, forKey: Keys.subjectLibrary)
            return true
        } catch {
            return false
        }
    }

    func savePhotoDescriptionSettings(
        _ settings: LegacyPhotoDescriptionSettings
    ) {
        defaults.set(
            settings.shouldWrite,
            forKey: Keys.shouldWritePhotoDescription
        )
        defaults.set(
            settings.override,
            forKey: Keys.photoDescriptionOverride
        )
    }

    func loadPhotoDescriptionSettings()
    -> LegacyPhotoDescriptionSettings {
        let shouldWrite = defaults.object(
            forKey: Keys.shouldWritePhotoDescription
        ) != nil
        ? defaults.bool(forKey: Keys.shouldWritePhotoDescription)
        : true
        return LegacyPhotoDescriptionSettings(
            shouldWrite: shouldWrite,
            override: defaults.string(
                forKey: Keys.photoDescriptionOverride
            ) ?? ""
        )
    }

    func saveLocationDisplayConfiguration(
        _ configuration: ExpressionModuleConfiguration?
    ) {
        guard let configuration else {
            defaults.removeObject(
                forKey: Keys.locationDisplayConfiguration
            )
            return
        }
        try? setEncoded(
            configuration,
            forKey: Keys.locationDisplayConfiguration
        )
    }

    func loadLocationDisplayConfiguration()
    -> ExpressionModuleConfiguration? {
        guard let data = defaults.data(
            forKey: Keys.locationDisplayConfiguration
        ) else {
            return nil
        }
        return try? JSONDecoder().decode(
            ExpressionModuleConfiguration.self,
            from: data
        )
    }

    func saveMediaOutputMode(_ mode: V1MediaOutputMode) {
        defaults.set(mode.rawValue, forKey: Keys.mediaOutputMode)
    }

    func loadMediaOutputMode() -> V1MediaOutputMode {
        guard let rawValue = defaults.string(
            forKey: Keys.mediaOutputMode
        ), let mode = V1MediaOutputMode(rawValue: rawValue) else {
            return .originalFormat
        }
        return mode
    }

    func saveEditorState(_ state: LegacySettingsEditorState) {
        defaults.set(
            state.selectedAnchorIDString,
            forKey: Keys.selectedAnchorID
        )
        defaults.set(
            state.selectedAlbumIdentifier,
            forKey: Keys.selectedAlbumIdentifier
        )
        defaults.set(
            state.selectedAlbumTitle,
            forKey: Keys.selectedAlbumTitle
        )
    }

    func loadEditorState() -> LegacySettingsEditorState {
        LegacySettingsEditorState(
            selectedAnchorIDString: defaults.string(
                forKey: Keys.selectedAnchorID
            ) ?? "",
            selectedAlbumIdentifier: defaults.string(
                forKey: Keys.selectedAlbumIdentifier
            ) ?? "",
            selectedAlbumTitle: defaults.string(
                forKey: Keys.selectedAlbumTitle
            ) ?? ""
        )
    }

    func saveConfigurationSlots(
        activeSlotID: WorkspaceConfigurationSlotID,
        slots: [WorkspaceConfigurationSlot]
    ) {
        guard let data = try? JSONEncoder().encode(slots) else {
            return
        }
        defaults.set(
            activeSlotID.rawValue,
            forKey: Keys.activeConfigurationSlotID
        )
        defaults.set(data, forKey: Keys.configurationSlots)
    }

    func loadConfigurationSlots()
    -> (
        activeSlotID: WorkspaceConfigurationSlotID,
        slots: [WorkspaceConfigurationSlot]
    ) {
        let activeSlotID = defaults.string(
            forKey: Keys.activeConfigurationSlotID
        ).flatMap(WorkspaceConfigurationSlotID.init(rawValue:))
            ?? .slot1
        guard let data = defaults.data(
            forKey: Keys.configurationSlots
        ), let decoded = try? JSONDecoder().decode(
            [WorkspaceConfigurationSlot].self,
            from: data
        ) else {
            return (
                activeSlotID,
                WorkspaceConfigurationSlot.defaultSlots
            )
        }
        return (
            activeSlotID,
            WorkspaceConfigurationSlot.normalized(decoded)
        )
    }

    func selectedMemorySubjectText() -> String? {
        defaults.string(forKey: Keys.selectedMemorySubjectText)
    }

    func loadProductionConfigurationReference()
    -> ProductionConfigurationReference? {
        guard let data = defaults.data(
            forKey: Keys.productionConfigurationReference
        ) else {
            return nil
        }
        return try? JSONDecoder().decode(
            ProductionConfigurationReference.self,
            from: data
        )
    }

    func persistCompatibilityProjection(
        _ projection: ConfigurationCompatibilityProjection
    ) throws {
        try setEncoded(
            projection.subjectLibrary,
            forKey: Keys.subjectLibrary
        )
        try setEncoded(
            projection.productionConfigurationReference,
            forKey: Keys.productionConfigurationReference
        )
        try setEncoded(
            projection.selectedSubject,
            forKey: Keys.selectedMemorySubject
        )
        defaults.set(
            projection.selectedSubjectText,
            forKey: Keys.selectedMemorySubjectText
        )
        try setEncoded(
            projection.template,
            forKey: Keys.selectedTemplate
        )
        if let badge = projection.badge {
            try setEncoded(badge, forKey: Keys.selectedBadge)
        } else {
            defaults.removeObject(forKey: Keys.selectedBadge)
        }
        if let location = projection.locationDisplayConfiguration {
            try setEncoded(
                location,
                forKey: Keys.locationDisplayConfiguration
            )
        } else {
            defaults.removeObject(
                forKey: Keys.locationDisplayConfiguration
            )
        }
        savePhotoDescriptionSettings(
            projection.photoDescriptionSettings
        )
        saveEditorState(projection.editorState)
        saveMediaOutputMode(projection.mediaOutputMode)
    }

    func decodeValueResult<Value: Decodable>(
        _ valueType: Value.Type,
        forKey storageKey: String
    ) -> PhotoMemoSharedDefaultsReadResult<Value> {
        guard let data = defaults.data(forKey: storageKey) else {
            return .noValue
        }
        do {
            return .success(
                try JSONDecoder().decode(valueType, from: data)
            )
        } catch {
            return .decodingFailed(
                PhotoMemoSharedDefaultsReadFailure(
                    storageKey: storageKey,
                    payloadByteCount: data.count,
                    underlyingDescription: String(describing: error),
                    rawPayload: data
                )
            )
        }
    }

    func loadSelectedMemorySubjectResult()
    -> PhotoMemoSharedDefaultsReadResult<MemorySubject> {
        decodeValueResult(
            MemorySubject.self,
            forKey: Keys.selectedMemorySubject
        )
    }

    func loadBadgeResult()
    -> PhotoMemoSharedDefaultsReadResult<Badge> {
        decodeValueResult(
            Badge.self,
            forKey: Keys.selectedBadge
        )
    }

    func loadSubjectLibraryResult()
    -> PhotoMemoSharedDefaultsReadResult<V1SubjectLibraryRecord> {
        decodeValueResult(
            V1SubjectLibraryRecord.self,
            forKey: Keys.subjectLibrary
        )
    }

    private func setEncoded<Value: Encodable>(
        _ value: Value,
        forKey key: String
    ) throws {
        defaults.set(
            try JSONEncoder().encode(value),
            forKey: key
        )
    }
}
#endif
