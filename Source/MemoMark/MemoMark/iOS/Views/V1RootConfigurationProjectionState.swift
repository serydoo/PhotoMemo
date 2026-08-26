#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation

struct V1RootConfigurationProjectionState {

    var presentationStyle: RecordCardPresentationStyle = .classicWhite
    var logoMode: V1LogoMode = .appleMini
    var customLogoBadge: Badge?

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
