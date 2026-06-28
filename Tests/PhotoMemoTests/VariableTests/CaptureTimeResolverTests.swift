import Foundation
import Testing
@testable import PhotoMemo

@Suite("CaptureTimeResolver")
struct CaptureTimeResolverTests {

    @Test("Formats full year month day differences for the new smart module")
    func formatsFullYearMonthDayDifferences() throws {

        let resolver =
            CaptureTimeResolver()

        let result =
            resolver.resolveText(
                captureDate: try date(
                    year: 2026,
                    month: 5,
                    day: 24
                ),
                referenceDate: try date(
                    year: 2024,
                    month: 4,
                    day: 18
                ),
                calendar: calendar
            )

        #expect(result == "2年1个月6天")
    }

    @Test("Omits the year segment when the difference is under one year")
    func omitsYearForSubYearDifferences() throws {

        let resolver =
            CaptureTimeResolver()

        let result =
            resolver.resolveText(
                captureDate: try date(
                    year: 2026,
                    month: 5,
                    day: 24
                ),
                referenceDate: try date(
                    year: 2025,
                    month: 9,
                    day: 1
                ),
                calendar: calendar
            )

        #expect(result == "8个月23天")
    }

    @Test("Falls back to day-only wording when months are also zero")
    func fallsBackToDayOnlyWording() throws {

        let resolver =
            CaptureTimeResolver()

        let result =
            resolver.resolveText(
                captureDate: try date(
                    year: 2026,
                    month: 5,
                    day: 24
                ),
                referenceDate: try date(
                    year: 2026,
                    month: 5,
                    day: 12
                ),
                calendar: calendar
            )

        #expect(result == "12天")
    }

    private var calendar: Calendar {

        var resolved =
            Calendar(identifier: .gregorian)
        resolved.timeZone = .gmt
        return resolved
    }

    private func date(
        year: Int,
        month: Int,
        day: Int
    ) throws -> Date {

        let components = DateComponents(
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: 12
        )

        return try #require(
            calendar.date(from: components)
        )
    }
}
