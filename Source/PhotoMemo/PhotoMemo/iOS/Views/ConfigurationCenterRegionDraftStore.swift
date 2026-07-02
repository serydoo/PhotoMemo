#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct IOSRegionConfigurationOption:
    Identifiable,
    Hashable {

    let id: String
    let title: String
}

struct ConfigurationCenterRegionDraftStore {

    var selectedRegionConfigurationIDs: [CardRegion: String] = [:]
    var regionDraftTexts: [String: String] = [:]
    var regionInsertedModules: [String: [IOSInsertedModule]] = [:]
    var regionContinuationTexts: [String: String] = [:]
    var savedRegionConfigurationIDs: Set<String> = []
    var regionConfigurationNames: [String: String] = [:]
    var renamingRegionConfigurationID: String?

    func text(
        for region: CardRegion,
        subject: MemorySubject?
    ) -> String {
        let configurationID =
            activeConfigurationID(for: region)

        return regionDraftTexts[configurationID]
            ?? defaultText(
                for: region,
                configurationID: configurationID,
                subject: subject
            )
    }

    mutating func setText(
        _ newValue: String,
        for region: CardRegion
    ) {
        regionDraftTexts[
            activeConfigurationID(for: region)
        ] = newValue
    }

    func modules(
        for region: CardRegion
    ) -> [IOSInsertedModule] {
        regionInsertedModules[
            activeConfigurationID(for: region)
        ] ?? []
    }

    mutating func setModules(
        _ modules: [IOSInsertedModule],
        for region: CardRegion
    ) {
        regionInsertedModules[
            activeConfigurationID(for: region)
        ] = modules
    }

    func continuationText(
        for region: CardRegion
    ) -> String {
        regionContinuationTexts[
            activeConfigurationID(for: region)
        ] ?? ""
    }

    mutating func setContinuationText(
        _ newValue: String,
        for region: CardRegion
    ) {
        regionContinuationTexts[
            activeConfigurationID(for: region)
        ] = newValue
    }

    func selectedConfigurationID(
        for region: CardRegion
    ) -> String {
        activeConfigurationID(for: region)
    }

    mutating func setSelectedConfigurationID(
        _ newValue: String,
        for region: CardRegion
    ) {
        selectedRegionConfigurationIDs[region] = newValue
    }

    func configurationName(
        for region: CardRegion
    ) -> String {
        let configurationID =
            activeConfigurationID(for: region)

        return regionConfigurationNames[configurationID]
            ?? defaultConfigurationTitle(
                for: region,
                configurationID: configurationID
            )
    }

    mutating func setConfigurationName(
        _ newValue: String,
        for region: CardRegion
    ) {
        regionConfigurationNames[
            activeConfigurationID(for: region)
        ] = newValue
    }

    func isRenamingConfiguration(
        for region: CardRegion
    ) -> Bool {
        renamingRegionConfigurationID
            == activeConfigurationID(for: region)
    }

    mutating func setRenamingConfiguration(
        _ isRenaming: Bool,
        for region: CardRegion
    ) {
        renamingRegionConfigurationID =
            isRenaming
            ? activeConfigurationID(for: region)
            : nil
    }

    func isSaved(
        for region: CardRegion
    ) -> Bool {
        savedRegionConfigurationIDs.contains(
            activeConfigurationID(for: region)
        )
    }

    mutating func markSaved(
        for region: CardRegion
    ) {
        savedRegionConfigurationIDs.insert(
            activeConfigurationID(for: region)
        )
    }

    func activeConfigurationID(
        for region: CardRegion
    ) -> String {
        selectedRegionConfigurationIDs[region]
            ?? defaultConfigurationID(for: region)
    }

    func defaultConfigurationID(
        for region: CardRegion
    ) -> String {
        switch region {
        case .slotA:
            return "recorder.configuration1"
        case .slotB:
            return "timeline.configuration1"
        case .slotC:
            return "context.configuration1"
        case .slotD:
            return "memory.configuration1"
        case .subject,
             .icon,
             .badge:
            return "\(region.rawValue).configuration1"
        }
    }

    func configurationOptions(
        for region: CardRegion
    ) -> [IOSRegionConfigurationOption] {
        switch region {
        case .slotA:
            return [
                option(region, "recorder.configuration1", "配置 1：记录者信息"),
                option(region, "recorder.configuration2", "配置 2：自定义记录"),
                option(region, "recorder.configuration3", "配置 3：自定义记录")
            ]
        case .slotB:
            return [
                option(region, "timeline.configuration1", "配置 1：拍摄时间"),
                option(region, "timeline.configuration2", "配置 2：日期"),
                option(region, "timeline.configuration3", "配置 3：自定义时间线")
            ]
        case .slotC:
            return [
                option(region, "context.configuration1", "配置 1：拍摄参数汇总"),
                option(region, "context.configuration2", "配置 2：备用拍摄参数"),
                option(region, "context.configuration3", "配置 3：自定义拍摄参数")
            ]
        case .slotD:
            return [
                option(
                    region,
                    "memory.configuration1",
                    ConfigurationCenterMemoryTemplateCatalog
                        .birthdayAgeTitle
                ),
                option(region, "memory.configuration2", "配置 2：自定义记忆"),
                option(region, "memory.configuration3", "配置 3：自定义记忆")
            ]
        case .subject,
             .icon,
             .badge:
            return []
        }
    }

    func defaultConfigurationTitle(
        for region: CardRegion,
        configurationID: String
    ) -> String {
        configurationOptions(for: region)
            .first {
                $0.id == configurationID
            }?
            .title
            ?? "自定义配置"
    }

    func defaultText(
        for region: CardRegion,
        configurationID: String,
        subject: MemorySubject?
    ) -> String {
        ConfigurationSession.defaultPreviewText(
            for: region,
            templateID: configurationID,
            subject: subject
        )
    }

    private func option(
        _ region: CardRegion,
        _ id: String,
        _ defaultTitle: String
    ) -> IOSRegionConfigurationOption {
        IOSRegionConfigurationOption(
            id: id,
            title:
                regionConfigurationNames[id]
                ?? defaultTitle
        )
    }
}
#endif
