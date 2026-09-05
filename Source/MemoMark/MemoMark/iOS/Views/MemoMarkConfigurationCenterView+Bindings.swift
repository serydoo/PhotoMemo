#if os(iOS)
import SwiftUI

extension MemoMarkConfigurationCenterView {

    func modules(for region: CardRegion) -> [IOSInsertableModule] {
        ModuleLibraryPresenter
            .modules(
                for: region,
                usageStorage:
                    moduleUsageCountsStorage
            )
    }

    func moduleCategoryTitle(
        _ module: IOSInsertableModule
    ) -> String {
        ModuleLibraryPresenter
            .categoryTitle(
                for: module
            )
    }

    func moduleDisplayText(
        _ module: IOSInsertableModule
    ) -> String {
        PreviewDraftAdapter.moduleDisplayText(
            module,
            context: previewCompositionContext,
            engine: previewCompositionEngine
        )
    }

    var previewCompositionContext:
        MemoryCardPreviewCompositionContext {

        MemoryCardPreviewCompositionContext(
            subject:
                alignedSelectedSubject()
                ?? session.state.selectedSubject,
            birthdayDate: birthdayDate,
            locationDisplayConfiguration:
                locationDisplayConfiguration,
            timeDisplayConfiguration:
                timeDisplayConfiguration,
            language: session.language
        )
    }

    var locationDisplayOptionBinding:
        Binding<String> {
        Binding(
            get: {
                LocationDisplayInspectorPresenter
                    .selectedOptionID(
                        fromConfiguration:
                            locationDisplayConfiguration
                    )
            },
            set: { optionID in
                let configuration =
                    LocationDisplayInspectorPresenter
                    .configuration(
                        for: optionID
                    )
                locationDisplayConfiguration =
                    configuration
                _ = configurationCoordinator?
                    .saveLocationDisplayConfiguration(
                        configuration
                    )
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    var timeDisplayOptionBinding: Binding<String> {
        Binding(
            get: {
                timeDisplayConfiguration.options["baseStyle"] ?? "daily"
            },
            set: { optionID in
                let style = TimeDisplayConfiguration.BaseStyle(rawValue: optionID) ?? .daily
                timeDisplayConfiguration = TimeDisplayInspectorPresenter.configuration(
                    baseStyle: style,
                    supplement: selectedTimeSupplement
                )
                _ = configurationCoordinator?.saveTimeDisplayConfiguration(timeDisplayConfiguration)
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    var selectedTimeSupplement: TimeDisplayConfiguration.Supplement {
        TimeDisplayConfiguration.Supplement(
            rawValue: timeDisplayConfiguration.options["supplement"] ?? "none"
        ) ?? .none
    }

    var timeDisplaySupplementBinding: Binding<TimeDisplayConfiguration.Supplement> {
        Binding(
            get: { selectedTimeSupplement },
            set: { supplement in
                let style = TimeDisplayConfiguration.BaseStyle(
                    rawValue: timeDisplayConfiguration.options["baseStyle"] ?? "daily"
                ) ?? .daily
                timeDisplayConfiguration = TimeDisplayInspectorPresenter.configuration(
                    baseStyle: style,
                    supplement: supplement
                )
                _ = configurationCoordinator?.saveTimeDisplayConfiguration(timeDisplayConfiguration)
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    var selectedTimeAnchorBinding:
        Binding<UUID> {
        Binding(
            get: {
                session.selectedTimeAnchorID
                ?? session.availableTimeAnchors.first?.id
                ?? UUID()
            },
            set: selectConfigurationSummaryTimeAnchor
        )
    }

    var selectedMemoryDisplayStyleBinding:
        Binding<MemoryAnchorExpressionStyle> {
        Binding(
            get: {
                guard let subject = session.state.selectedSubject,
                      let anchor = subject.primaryTimeAnchor else {
                    return .birthdayNatural
                }
                let selected = anchor.resolvedExpressionStyle
                guard MemoMarkCommerceCapability
                    .allowsFirstPartyExpressionStyle(
                        selected,
                        accessSource:
                            commerceStore.snapshot.accessSource
                    ) else {
                    return .birthdayNatural
                }
                return selected
            },
            set: { style in
                guard MemoMarkCommerceCapability
                    .allowsFirstPartyExpressionStyle(
                        style,
                        accessSource: commerceStore.snapshot.accessSource
                    ) else {
                    return
                }
                session
                    .selectCurrentTimeAnchorExpressionStyle(
                        style
                    )
                activeConfigurationStatus = .dirty
                refreshDynamicPreview()
            }
        )
    }

    func alignedSelectedSubject()
    -> MemorySubject? {
        SaveConfigurationCommandBuilder
            .alignedSelectedSubject(
                from:
                    session
                    .state
                    .selectedSubject,
                birthdayDate:
                    birthdayDate
            )
    }

    var shareDiagnosticsHeaderProjection:
        MemoMarkiOSQueueDiagnosticsHeaderProjection {

        MemoMarkiOSQueueDiagnosticsProjectionEngine
            .headerProjection(
                backgroundSnapshot:
                    backgroundStatusService
                    .currentSnapshot,
                processingDiagnosticsSnapshot:
                    processingDiagnosticsSnapshot,
                events:
                    shareDiagnosticEvents,
                language: .interfaceStored
            )
    }
}

#endif
