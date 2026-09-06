#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

struct RootConfigurationProjectionState {

    var presentationStyle: RecordCardPresentationStyle = .classicWhite
    var logoMode: ConfigurationLogoMode = .appleMini
    var customLogoBadge: Badge?
    /// A paid expression can be explored in the live editor before it is
    /// written to the durable subject. The save action owns the commerce
    /// decision; this value is deliberately transient.
    var pendingMemoryDisplayStyle: MemoryAnchorExpressionStyle?

    var birthdayDate =
        Calendar.current.date(
            from: DateComponents(
                year: 2024,
                month: 1,
                day: 1
            )
        ) ?? Date()

    var locationDisplayConfiguration:
        ExpressionModuleConfiguration? =
        LocationDisplayInspectorPresenter
        .configuration(
            for: "legacyDisplay"
        )

    var timeDisplayConfiguration:
        ExpressionModuleConfiguration

    init(
        timeDisplayConfiguration:
            ExpressionModuleConfiguration? = nil
    ) {
        self.timeDisplayConfiguration =
            timeDisplayConfiguration
            ?? TimeDisplayInspectorPresenter.configuration(
                baseStyle: .daily,
                supplement: .none
            )
    }
}

#endif
