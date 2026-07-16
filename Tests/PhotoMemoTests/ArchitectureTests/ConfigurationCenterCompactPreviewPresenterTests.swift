#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import Testing
@testable import PhotoMemo

@Suite("Configuration center compact preview presenter")
struct ConfigurationCenterCompactPreviewPresenterTests {

    @Test("formattedCaptureSummaryText keeps only the allowed fact count")
    func formattedCaptureSummaryTextKeepsOnlyAllowedFactCount() {
        let text =
            ConfigurationCenterCompactPreviewPresenter
            .formattedCaptureSummaryText(
                from: "20mm f/1.9 1/117s ISO80 extra",
                allowedFactCount: 4
            )

        #expect(text == "20mm f/1.9 1/117s ISO80")
    }

    @Test("formattedCaptureSummaryText returns the original text when there are no whitespace-separated facts")
    func formattedCaptureSummaryTextReturnsOriginalWhenNoFacts() {
        let text =
            ConfigurationCenterCompactPreviewPresenter
            .formattedCaptureSummaryText(
                from: "",
                allowedFactCount: 4
            )

        #expect(text.isEmpty)
    }

    @Test("selectedBadgeName falls back to apple logo when no badge decoration exists")
    func selectedBadgeNameFallsBackWhenNoBadgeExists() {
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "示例昵称",
                        shortName: "示例昵称"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "女儿"
                    ),
                referenceDate: Date(timeIntervalSince1970: 1_704_067_200),
                behavior:
                    .init(
                        primaryAnchor: "出生",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            .init(
                                title: "记忆",
                                blocks: [.text("记录于")]
                            )
                    ),
                decorations: []
            )

        #expect(
            ConfigurationCenterCompactPreviewPresenter
            .selectedBadgeName(subject: subject)
            == "apple.logo"
        )
    }

    @Test("selectedBadgeName prefers the first badge decoration symbol")
    func selectedBadgeNamePrefersFirstBadgeDecoration() {
        let subject =
            MemorySubject(
                identity:
                    .init(
                        displayName: "示例昵称",
                        shortName: "示例昵称"
                    ),
                relationship:
                    .init(
                        role: "家庭",
                        label: "女儿"
                    ),
                referenceDate: Date(timeIntervalSince1970: 1_704_067_200),
                behavior:
                    .init(
                        primaryAnchor: "出生",
                        iconStrategy: .autoMatch,
                        badgeStrategy: .autoMatch,
                        memoryExpression:
                            .init(
                                title: "记忆",
                                blocks: [.text("记录于")]
                            )
                    ),
                decorations: [
                    .init(
                        kind: .badge,
                        title: "相机",
                        systemSymbolName: "camera.fill"
                    )
                ]
            )

        #expect(
            ConfigurationCenterCompactPreviewPresenter
            .selectedBadgeName(subject: subject)
            == "camera.fill"
        )
    }
}
#endif
