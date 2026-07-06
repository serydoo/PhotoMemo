#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct ConfigurationCenterPreviewCompositionContext: Hashable {

    let subject: MemorySubject?

    let captureDate: Date

    init(
        subject: MemorySubject?,
        captureDate: Date = ConfigurationCenterPreviewCompositionHelper.defaultCaptureDate
    ) {
        self.subject = subject
        self.captureDate = captureDate
    }

    var subjectNameFallback: String {
        if let shortName = subject?.identity.shortName,
           !shortName.isEmpty {
            return shortName
        }

        return subject?.identity.displayName
        ?? "途途"
    }
}

struct ConfigurationCenterPreviewCompositionUpdate {

    let store: ConfigurationCenterRegionDraftStore

    let previewText: String
}

struct ConfigurationCenterPreviewCompositionHelper {

    static let defaultCaptureDate: Date = {
        var components =
            DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 24
        components.hour = 14
        components.minute = 33
        components.second = 13
        return Calendar.current.date(from: components)
            ?? Date()
    }()

    let context: ConfigurationCenterPreviewCompositionContext

    func insertModule(
        _ module: IOSInsertableModule,
        into region: CardRegion,
        store: ConfigurationCenterRegionDraftStore,
        expressionConfiguration:
            ExpressionModuleConfiguration? = nil
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        guard CardRegion.memoryCardRegions.contains(region) else {
            return .init(
                store: store,
                previewText: composedPreviewText(
                    for: region,
                    store: store
                )
            )
        }

        var updatedStore = store
        let configurationID =
            updatedStore.activeConfigurationID(for: region)

        if updatedStore.regionDraftTexts[configurationID] == nil {
            updatedStore.setText(
                updatedStore.defaultText(
                    for: region,
                    configurationID: configurationID,
                    subject: context.subject
                ),
                for: region
            )
        }

        var currentModules =
            updatedStore.modules(for: region)
        currentModules.append(
            IOSInsertedModule(
                title: module.title,
                value: moduleDisplayText(
                    module,
                    expressionConfiguration:
                        expressionConfiguration
                ),
                systemImage: module.systemImage,
                expressionConfiguration:
                    expressionConfiguration
            )
        )
        updatedStore.setModules(
            currentModules,
            for: region
        )

        return .init(
            store: updatedStore,
            previewText: composedPreviewText(
                for: region,
                store: updatedStore
            )
        )
    }

    func removeInsertedModule(
        _ module: IOSInsertedModule,
        from region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        var updatedStore = store
        var currentModules =
            updatedStore.modules(for: region)
        currentModules.removeAll {
            $0.id == module.id
        }
        updatedStore.setModules(
            currentModules,
            for: region
        )

        return .init(
            store: updatedStore,
            previewText: composedPreviewText(
                for: region,
                store: updatedStore
            )
        )
    }

    func updateInsertedModule(
        _ module: IOSInsertedModule,
        in region: CardRegion,
        store: ConfigurationCenterRegionDraftStore,
        expressionConfiguration:
            ExpressionModuleConfiguration
    ) -> ConfigurationCenterPreviewCompositionUpdate {
        var updatedStore = store
        var currentModules =
            updatedStore.modules(for: region)

        guard
            let index =
                currentModules
                .firstIndex(where: { $0.id == module.id })
        else {
            return .init(
                store: store,
                previewText:
                    composedPreviewText(
                        for: region,
                        store: store
                    )
            )
        }

        guard module.representsLocationModule else {
            return .init(
                store: store,
                previewText:
                    composedPreviewText(
                        for: region,
                        store: store
                    )
            )
        }

        let updatedModule =
            IOSInsertedModule(
                id: module.id,
                title: module.title,
                value:
                    moduleDisplayText(
                        .location,
                        expressionConfiguration:
                            expressionConfiguration
                    ),
                systemImage: module.systemImage,
                expressionConfiguration:
                    expressionConfiguration
            )
        currentModules[index] =
            updatedModule
        updatedStore.setModules(
            currentModules,
            for: region
        )

        return .init(
            store: updatedStore,
            previewText:
                composedPreviewText(
                    for: region,
                    store: updatedStore
                )
        )
    }

    func composedPreviewText(
        for region: CardRegion,
        store: ConfigurationCenterRegionDraftStore
    ) -> String {
        let configurationID =
            store.activeConfigurationID(for: region)

        let baseText =
            (store.regionDraftTexts[configurationID]
             ?? store.defaultText(
                for: region,
                configurationID: configurationID,
                subject: context.subject
             ))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let continuationText =
            (store.regionContinuationTexts[configurationID]
             ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return InlineContentTextComposer.compose(
            [
                InlineContentTextComposer.Piece(
                    kind: .text,
                    value: baseText
                )
            ]
            + (store.regionInsertedModules[configurationID] ?? [])
            .map { module in
                InlineContentTextComposer.Piece(
                    kind: .token,
                    value: module.value
                )
            }
            + [
                InlineContentTextComposer.Piece(
                    kind: .text,
                    value: continuationText
                )
            ]
        )
    }

    func moduleDisplayText(
        _ module: IOSInsertableModule,
        expressionConfiguration:
            ExpressionModuleConfiguration? = nil
    ) -> String {
        switch module {
        case .subjectNickname:
            return context.subject?.identity.shortName
            ?? context.subject?.identity.displayName
            ?? "途途"
        case .smartTime:
            return smartTimeResult
        case .captureDate:
            return "2026.05.24"
        case .captureTime:
            return "14:33:13"
        case .cameraMaker:
            return ""
        case .cameraModel:
            return "iPhone 17 Pro Max"
        case .lensModel:
            return ""
        case .focalLength:
            return ""
        case .aperture:
            return ""
        case .shutterSpeed:
            return ""
        case .iso:
            return ""
        case .exposureBias:
            return ""
        case .meteringMode:
            return ""
        case .flash:
            return ""
        case .whiteBalance:
            return ""
        case .captureSummary:
            return "20mm f/1.9 1/117s ISO80"
        case .location:
            return previewExpressionContext(
                expressionConfiguration:
                    expressionConfiguration
            )?
            .value(
                for: LocationExpressionProvider.locationToken
            )?
            .resolvedText
            ?? ""
        case .altitude:
            return ""
        case .imageSize:
            return ""
        case .orientation:
            return ""
        case .fileFormat:
            return ""
        case .custom:
            return "自定义内容"
        }
    }

    var smartTimeResult: String {
        MemoryExpressionPreviewResolver
            .previewText(
                subject: context.subject,
                captureDate: context.captureDate
            )
            ?? "未设置时间"
    }

    private func previewExpressionContext(
        expressionConfiguration:
            ExpressionModuleConfiguration?
    ) -> ExpressionContext? {
        let metadata =
            PhotoMetadata(
                city: " 商丘 ",
                district: " 永城 ",
                province: " 河南 "
            )

        let locationContext =
            LocationContextBuilder()
            .build(
                from: metadata
            )

        let providerInput =
            LocationConfigurationAdapter()
            .providerInput(
                from:
                    expressionConfiguration
                    ?? ExpressionModuleConfiguration(
                        token: LocationExpressionProvider.locationToken
                    )
            )
            ?? LocationProviderInput(
                requestedPresentation: .provinceCity,
                resolutionConfiguration:
                    LocationResolutionConfiguration()
            )

        guard
            let locationValue =
                LocationExpressionProvider()
                .expressionValue(
                    for: LocationExpressionProvider.locationToken,
                    context: locationContext,
                    requestedPresentation:
                        providerInput.requestedPresentation,
                    configuration:
                        providerInput.resolutionConfiguration
                )
        else {
            return nil
        }

        return try? ExpressionContext(
            values: [
                locationValue
            ]
        )
    }
}

private extension IOSInsertedModule {
    var representsLocationModule: Bool {
        title == IOSInsertableModule.location.title
        && systemImage == IOSInsertableModule.location.systemImage
    }
}
#endif
