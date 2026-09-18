#if !MEMOMARK_SHARE_EXTENSION && os(iOS)
import SwiftUI

struct FilmMarkDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var configuration: FilmMarkConfiguration

    let locationPresentation: LocationDisplayInspectorPresentation
    let selectedLocationOptionID: Binding<String>
    let timePresentation: TimeDisplayInspectorPresentation
    let selectedTimeOptionID: Binding<String>
    let selectedTimeSupplement: Binding<TimeDisplayConfiguration.Supplement>
    let onChange: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    FilmMarkConfigurationControls(
                        configuration: $configuration,
                        includesPosition: false,
                        includesSubstrate: false,
                        includesFont: true,
                        includesFontSize: false,
                        includesColor: false,
                        includesCustomColor: false,
                        onChange: onChange
                    )

                    HorizontalDivider(horizontalInset: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(filmMarkLocalized("filmMark.details.time_place.title", fallback: "时间与地点"))
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(filmMarkLocalized("filmMark.details.time_place.help", fallback: "选择照片中的时间和地点怎样呈现。"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, CompactInformationRowMetrics.horizontalPadding)
                    .padding(.top, 14)
                    .padding(.bottom, 4)

                    AdvancedModulesContent(
                        locationPresentation: locationPresentation,
                        selectedLocationOptionID: selectedLocationOptionID,
                        timePresentation: timePresentation,
                        selectedTimeOptionID: selectedTimeOptionID,
                        selectedTimeSupplement: selectedTimeSupplement,
                        isEmbedded: true
                    )
                    .padding(.horizontal, CompactInformationRowMetrics.horizontalPadding)
                }
                .padding(.bottom, 28)
                .adaptiveScrollContent(horizontalPadding: ConfigurationUI.contentColumnPadding)
            }
            .background(ConfigurationUI.appBackground.ignoresSafeArea())
            .navigationTitle(filmMarkLocalized("filmMark.configuration.details.navigation_title", fallback: "胶片样式与细节"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(filmMarkLocalized("filmMark.details.done", fallback: "完成")) { dismiss() }
                }
            }
        }
        .memoMarkSheet(.browser, detents: [.height(ConfigurationUI.compactSheetHeight), .large])
    }
}
#endif
