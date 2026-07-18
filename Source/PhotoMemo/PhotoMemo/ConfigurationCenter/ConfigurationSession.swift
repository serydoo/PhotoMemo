#if !PHOTOMEMO_SHARE_EXTENSION
import Combine
import Foundation

@MainActor
final class ConfigurationSession: ObservableObject {

    @Published
    private var editingState: ConfigurationEditingState

    private let persistenceReconciler =
        ConfigurationPersistenceReconciler()

    init(
        state: ConfigurationCenterState? = nil
    ) {
        editingState = ConfigurationEditingState(
            state: state
        )
    }

    var state: ConfigurationCenterState {
        get { editingState.state }
        set { editingState.state = newValue }
    }

    var selectedOutputOption: ConfigurationOutputOption {
        get { editingState.selectedOutputOption }
        set { editingState.selectedOutputOption = newValue }
    }

    var selectedStorageOption: ConfigurationStorageOption {
        get { editingState.selectedStorageOption }
        set { editingState.selectedStorageOption = newValue }
    }

    var usesCustomMemoryWriteText: Bool {
        get { editingState.usesCustomMemoryWriteText }
        set { editingState.usesCustomMemoryWriteText = newValue }
    }

    var customMemoryWriteText: String {
        get { editingState.customMemoryWriteText }
        set { editingState.customMemoryWriteText = newValue }
    }

    func restoreMemoryCopy(
        usesCustomText: Bool,
        customText: String
    ) {
        editingState.restoreMemoryCopy(
            usesCustomText: usesCustomText,
            customText: customText
        )
    }

    var latestModuleInsertion: MemoryModuleInsertion? {
        get { editingState.latestModuleInsertion }
        set { editingState.latestModuleInsertion = newValue }
    }

    var appliedMemoryPresetID: MemoryPreset.ID? {
        get { editingState.appliedMemoryPresetID }
        set { editingState.appliedMemoryPresetID = newValue }
    }

    var selectedMemoryConfiguration: MemoryConfigurationRecord? {
        editingState.selectedMemoryConfiguration
    }

    func selectSubject(_ subject: MemorySubject) {
        editingState.selectSubject(subject)
    }

    func selectRegion(_ region: CardRegion) {
        editingState.selectRegion(region)
    }

    func select(_ behavior: CardRegionBehavior) {
        editingState.select(behavior)
    }

    func hoverRegion(_ region: CardRegion?) {
        editingState.hoverRegion(region)
    }

    func selectBlock(_ block: MemoryBlock) {
        editingState.selectBlock(block)
    }

    func updateSelectedSubject(_ subject: MemorySubject) {
        editingState.updateSelectedSubject(subject)
    }

    func restoreSelectedSubject(_ subject: MemorySubject) {
        editingState.restoreSelectedSubject(subject)
    }

    func restoreSubjectLibrary(
        _ subjects: [MemorySubject],
        selectedSubjectID: MemorySubject.ID?,
        memoryPresets: [MemoryPreset]? = nil,
        selectedMemoryPresetID: MemoryPreset.ID? = nil
    ) {
        editingState.restoreSubjectLibrary(
            subjects,
            selectedSubjectID: selectedSubjectID,
            memoryPresets: memoryPresets,
            selectedMemoryPresetID: selectedMemoryPresetID
        )
    }

    func restoreConfigurationLibrary(
        _ aggregate: ConfigurationLibraryRecord
    ) {
        persistenceReconciler.restoreConfigurationLibrary(
            aggregate,
            editingState: &editingState
        )
    }

    func updateConfigurationLibraryReference(
        _ aggregate: ConfigurationLibraryRecord
    ) {
        editingState.state.configurationLibrary = aggregate
    }

    @discardableResult
    func reconcileConfigurationLibrarySave(
        candidate: V1ConfigurationAggregateCandidate,
        receipt: ConfigurationLibrarySaveReceipt
    ) -> ConfigurationPersistenceReconciliationOutcome {
        persistenceReconciler.reconcileConfigurationLibrarySave(
            candidate: candidate,
            receipt: receipt,
            editingState: &editingState
        )
    }

    func appendSubject(
        _ subject: MemorySubject,
        selectAfterInsert: Bool = true
    ) {
        editingState.appendSubject(
            subject,
            selectAfterInsert: selectAfterInsert
        )
    }

    func removeSubject(id: MemorySubject.ID) {
        editingState.removeSubject(id: id)
    }

    func updateRegionPreview(
        region: CardRegion,
        text: String
    ) {
        editingState.updateRegionPreview(
            region: region,
            text: text
        )
    }

    func appendPreviewModule(
        title: String,
        value: String,
        systemImage: String = "tag.fill",
        token: String? = nil
    ) {
        editingState.appendPreviewModule(
            title: title,
            value: value,
            systemImage: systemImage,
            token: token
        )
    }

    var currentOutputPreview: String {
        editingState.currentOutputPreview
    }

    var smartModuleCarrierRegion: CardRegion {
        editingState.smartModuleCarrierRegion
    }

    var currentConfigurationSnapshot: ConfigurationSnapshot? {
        ConfigurationSnapshotBuilder.build(from: self)
    }

    var generatedMemoryModule: MemoryModule? {
        guard
            let snapshot = currentConfigurationSnapshot,
            let subject = state.selectedSubject
        else {
            return nil
        }

        let context = MemoryExpressionContext(
            subject: subject,
            snapshot: snapshot,
            captureDate:
                MemoryExpressionPreviewResolver.defaultCaptureDate
        )
        let result = MemoryExpressionEngine().generateResult(
            context: context
        )

        return MemoryResultPresentationAdapter().makeModule(
            result: result,
            context: context
        )
    }

    var resolvedMemoryWriteText: String {
        let customText = customMemoryWriteText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if usesCustomMemoryWriteText,
           !customText.isEmpty {
            return customText
        }

        let memoryText = generatedMemoryModule?.renderedText
            ?? generatedMemoryModuleText
                .trimmingCharacters(in: .whitespacesAndNewlines)
        return memoryText.isEmpty
            ? "当前智能模块暂无内容"
            : memoryText
    }

    var generatedMemoryModuleText: String {
        generatedMemoryModule?.renderedText
            ?? ConfigurationEditingState.generatedMemoryModuleText(
                subject: state.selectedSubject,
                smartModuleCarrierRegion: smartModuleCarrierRegion
            ) ?? ""
    }

    func selectMemoryPreset(_ preset: MemoryPreset) {
        editingState.selectMemoryPreset(preset)
    }

    func saveCurrentMemoryPreset(
        logoMode: V1LogoMode? = nil,
        outputConfiguration: V1SavedOutputConfiguration? = nil
    ) {
        guard let presetIndex =
            editingState.writableSelectedMemoryPresetIndex()
        else {
            createMemoryPresetFromCurrent(
                savedAt: Date(),
                applyImmediately: true,
                logoMode: logoMode,
                outputConfiguration: outputConfiguration
            )
            return
        }

        let snapshot = persistenceReconciler
            .configurationSnapshot(
                in: editingState.state.memoryPresets[presetIndex],
                editingState: editingState,
                savedAt: Date(),
                logoMode: logoMode,
                outputConfiguration: outputConfiguration
            )
        editingState.state.memoryPresets[presetIndex] = snapshot
        editingState.state.selectedMemoryPresetID = snapshot.id
        editingState.appliedMemoryPresetID = snapshot.id
    }

    func createMemoryPresetFromCurrent(
        logoMode: V1LogoMode? = nil,
        outputConfiguration: V1SavedOutputConfiguration? = nil
    ) {
        createMemoryPresetFromCurrent(
            savedAt: nil,
            applyImmediately: false,
            logoMode: logoMode,
            outputConfiguration: outputConfiguration
        )
    }

    @discardableResult
    func deleteSelectedMemoryPreset() -> Bool {
        editingState.deleteSelectedMemoryPreset()
    }

    func persistenceSnapshotForCurrentConfiguration(
        logoMode: V1LogoMode? = nil,
        outputConfiguration: V1SavedOutputConfiguration? = nil,
        savedAt: Date = Date()
    ) -> (
        memoryPresets: [MemoryPreset],
        selectedMemoryPresetID: MemoryPreset.ID
    ) {
        let snapshot = persistenceReconciler
            .persistenceSnapshotForCurrentConfiguration(
                editingState: editingState,
                logoMode: logoMode,
                outputConfiguration: outputConfiguration,
                savedAt: savedAt
            )
        return (
            snapshot.memoryPresets,
            snapshot.selectedMemoryPresetID
        )
    }

    @discardableResult
    func reconcilePersistenceSnapshot(
        memoryPresets: [MemoryPreset],
        selectedMemoryPresetID: MemoryPreset.ID?,
        configurationID: UUID? = nil,
        configurationRevision: Int? = nil
    ) -> ConfigurationPersistenceReconciliationOutcome {
        guard let selectedMemoryPresetID else {
            return .newerEditsPreserved
        }
        return persistenceReconciler.reconcilePersistenceSnapshot(
            ConfigurationPersistenceSnapshot(
                memoryPresets: memoryPresets,
                selectedMemoryPresetID:
                    selectedMemoryPresetID
            ),
            editingState: &editingState,
            configurationID: configurationID,
            configurationRevision: configurationRevision
        )
    }

    func updateSelectedMemoryPresetTitle(_ title: String) {
        editingState.updateSelectedMemoryPresetTitle(title)
    }

    func updateActiveTemplate(
        for region: CardRegion,
        templateID: String
    ) {
        editingState.updateActiveTemplate(
            for: region,
            templateID: templateID
        )
    }

    func activeTemplateID(for region: CardRegion) -> String? {
        editingState.activeTemplateID(for: region)
    }

    var currentMemoryPresetTitle: String {
        editingState.currentMemoryPresetTitle
    }

    var currentMemoryPresetSummary: String {
        editingState.currentMemoryPresetSummary
    }

    var selectedMemoryPresetIsApplied: Bool {
        editingState.selectedMemoryPresetIsApplied
    }

    var availableMemoryPresetsForSelectedSubject: [MemoryPreset] {
        editingState.availableMemoryPresetsForSelectedSubject
    }

    func applySelectedMemoryPreset() {
        editingState.applySelectedMemoryPreset()
    }

    func resetSelectedMemoryPreset() {
        editingState.resetSelectedMemoryPreset()
    }

    var currentConfigurationLabel: String {
        editingState.currentConfigurationLabel
    }

    var currentDefaultMemoryPresetTitle: String {
        editingState.currentDefaultMemoryPresetTitle
    }

    var currentTimeAnchorTitle: String {
        editingState.currentTimeAnchorTitle
    }

    var availableTimeAnchors: [MemorySubject.TimeAnchor] {
        editingState.availableTimeAnchors
    }

    var selectedTimeAnchorID: UUID? {
        editingState.selectedTimeAnchorID
    }

    func selectTimeAnchor(id: UUID) {
        editingState.selectTimeAnchor(id: id)
    }

    func selectCurrentTimeAnchorExpressionStyle(
        _ style: MemoryAnchorExpressionStyle
    ) {
        editingState.selectCurrentTimeAnchorExpressionStyle(style)
    }

    var currentTimeAnchorDescription: String {
        editingState.currentTimeAnchorDescription
    }

    func previewText(for region: CardRegion) -> String {
        editingState.previewText(for: region)
    }

    func insertBlock(_ block: MemoryBlock) {
        editingState.insertBlock(block)
    }

    func removeBlock(_ block: MemoryBlock) {
        editingState.removeBlock(block)
    }

    func moveBlock(
        _ block: MemoryBlock,
        direction: Int
    ) {
        editingState.moveBlock(
            block,
            direction: direction
        )
    }

    func selectDecoration(_ decoration: DecorationAsset) {
        editingState.selectDecoration(decoration)
    }

    static func defaultPreviewText(
        for region: CardRegion,
        subject: MemorySubject?
    ) -> String {
        ConfigurationCenterPreviewDefaults.defaultPreviewText(
            for: region,
            subject: subject
        )
    }

    static func defaultPreviewText(
        for region: CardRegion,
        templateID: String?,
        subject: MemorySubject?
    ) -> String {
        ConfigurationCenterPreviewDefaults.defaultPreviewText(
            for: region,
            templateID: templateID,
            subject: subject
        )
    }
}

private extension ConfigurationSession {

    func createMemoryPresetFromCurrent(
        savedAt: Date?,
        applyImmediately: Bool,
        logoMode: V1LogoMode?,
        outputConfiguration: V1SavedOutputConfiguration?
    ) {
        let basePreset = MemoryPreset(
            title: editingState.currentDefaultMemoryPresetTitle,
            summary:
                editingState.state.selectedMemoryPreset?.summary
                ?? "当前区域组合",
            regionTemplateIDs:
                editingState.currentRegionTemplateIDs
        )
        let snapshot = persistenceReconciler
            .configurationSnapshot(
                in: basePreset,
                editingState: editingState,
                savedAt: savedAt,
                logoMode: logoMode,
                outputConfiguration: outputConfiguration
            )

        editingState.state.memoryPresets.append(snapshot)
        editingState.state.selectedMemoryPresetID = snapshot.id
        editingState.appliedMemoryPresetID =
            applyImmediately ? snapshot.id : nil
        editingState.refreshPresetDrivenPreview()
    }
}
#endif
