#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center region composer presenter")
struct ConfigurationCenterRegionComposerPresenterTests {

    @Test("projection prefers the selected configuration option title")
    func projectionPrefersTheSelectedConfigurationOptionTitle() {
        let projection =
            ConfigurationCenterRegionComposerPresenter
            .projection(
                for: .slotC,
                selectedConfigurationID: "context.configuration2",
                configurationName: "手动标题",
                configurationOptions: [
                    .init(
                        id: "context.configuration1",
                        title: "默认"
                    ),
                    .init(
                        id: "context.configuration2",
                        title: "参数强化"
                    )
                ],
                isSaved: true
            )

        #expect(
            projection.selectedConfigurationTitle
            == "参数强化"
        )
        #expect(
            projection.statusSymbolName
            == "checkmark.circle.fill"
        )
        #expect(
            projection.statusTitle
            == "已生效"
        )
        #expect(
            projection.usesSavedAccentStyle
        )
        #expect(
            projection.textPlaceholder
            == "输入或补充 拍摄参数"
        )
    }

    @Test("projection falls back to the editable configuration name when no option matches")
    func projectionFallsBackToEditableConfigurationName() {
        let projection =
            ConfigurationCenterRegionComposerPresenter
            .projection(
                for: .slotD,
                selectedConfigurationID: "missing",
                configurationName: "记忆自定义",
                configurationOptions: [],
                isSaved: false
            )

        #expect(
            projection.selectedConfigurationTitle
            == "记忆自定义"
        )
        #expect(
            projection.statusSymbolName
            == "circle"
        )
        #expect(
            projection.statusTitle
            == "未保存"
        )
        #expect(
            !projection.usesSavedAccentStyle
        )
        #expect(
            projection.continuationPlaceholder
            == "继续输入"
        )
    }
}
#endif
