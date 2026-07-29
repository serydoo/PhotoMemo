import Foundation
import Testing
@testable import PhotoMemo

@Suite("Time display module")
struct TimeDisplayModuleContractTests {

    @Test("daily style keeps the solar date as the primary expression")
    func dailyStyleIsPrimaryExpression() {
        let configuration = TimeDisplayInspectorPresenter.configuration(
            baseStyle: .daily,
            supplement: .lunarAndSolarTerm
        )

        #expect(configuration.options["baseStyle"] == "daily")
        #expect(configuration.options["supplement"] == "lunarAndSolarTerm")
        #expect(configuration.token == TimeExpressionProvider.timeToken)
    }

    @Test("solar term is appended only when the date is a solar-term date")
    func solarTermIsConditional() {
        let regularDate = TimeDisplayInspectorPresenter.compose(
            base: "2026年7月28日",
            lunar: "农历六月十四",
            solarTerm: nil,
            holiday: nil,
            statutoryHoliday: nil,
            separator: " · "
        )
        let solarTermDate = TimeDisplayInspectorPresenter.compose(
            base: "2026年7月29日",
            lunar: "农历六月十五",
            solarTerm: "大暑",
            holiday: nil,
            statutoryHoliday: nil,
            separator: " · "
        )

        #expect(regularDate == "2026年7月28日 · 农历六月十四")
        #expect(solarTermDate == "2026年7月29日 · 农历六月十五 · 大暑")
    }

    @Test("statutory holiday is appended as a range-aware event")
    func statutoryHolidayIsAppended() {
        let result = TimeDisplayInspectorPresenter.compose(
            base: "2026年10月3日 星期六 下午2:18",
            lunar: nil,
            solarTerm: nil,
            holiday: "国庆节",
            statutoryHoliday: "国庆假期",
            separator: " · "
        )

        #expect(result == "2026年10月3日 星期六 下午2:18 · 国庆节 · 国庆假期")
    }
}
