#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Location display inspector presenter")
struct LocationDisplayInspectorPresenterTests {

    @Test("product language uses display capability labels")
    func productLanguageUsesDisplayCapabilityLabels() {
        let presentation =
            LocationDisplayInspectorPresenter.presentation

        #expect(presentation.title == "位置显示")
        #expect(presentation.unavailableValue == "位置模块未插入")
        #expect(presentation.selectedValue == "自动兼容")
        #expect(presentation.systemImage == "location")
        #expect(
            presentation.options.map(\.title)
            == [
                "自动兼容",
                "省份 · 城市",
                "城市 · 区县",
                "省份 · 城市 · 区县",
                "经纬度"
            ]
        )
        #expect(
            presentation.options.first?.note
            == "根据照片中的位置数据自动选择最佳显示方式。"
        )
    }

    @Test("product language does not expose implementation terminology")
    func productLanguageDoesNotExposeImplementationTerminology() {
        let presentation =
            LocationDisplayInspectorPresenter.presentation
        let visibleText =
            (
                [
                    presentation.title,
                    presentation.unavailableValue,
                    presentation.selectedValue,
                    presentation.systemImage
                ]
                + presentation.options.flatMap {
                    [
                        $0.title,
                        $0.note ?? ""
                    ]
                }
            )
            .joined(separator: " ")

        #expect(!visibleText.contains("Location Module"))
        #expect(!visibleText.contains("Provider"))
        #expect(!visibleText.contains("Presentation Mode"))
        #expect(!visibleText.contains("Expression"))
        #expect(!visibleText.contains("位置设置"))
        #expect(!visibleText.contains("位置配置"))
    }

    @Test("selected option falls back to automatic compatible display")
    func selectedOptionFallsBackToAutomaticCompatibleDisplay() {
        #expect(
            LocationDisplayInspectorPresenter
                .selectedOptionID(from: nil)
            == "legacyDisplay"
        )
        #expect(
            LocationDisplayInspectorPresenter
                .selectedValue(from: nil)
            == "自动兼容"
        )
    }

    @Test("configuration maps user option to location expression configuration")
    func configurationMapsUserOptionToLocationExpressionConfiguration() {
        let configuration =
            LocationDisplayInspectorPresenter
            .configuration(
                for: "provinceCityDistrict"
            )

        #expect(configuration.token == LocationExpressionProvider.locationToken)
        #expect(
            configuration.options["presentationMode"]
            == "provinceCityDistrict"
        )
    }
}
#endif
