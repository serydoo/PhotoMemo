import Foundation
import Testing
@testable import PhotoMemo

@Suite("MetadataContext")
struct MetadataContextTests {

    @Test("Uses capture timezone when deriving date components")
    func usesCaptureTimezoneForDerivedDateFields() throws {

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let captureDate = try #require(
            utcCalendar.date(
                from: DateComponents(
                    timeZone: TimeZone(secondsFromGMT: 0),
                    year: 2026,
                    month: 6,
                    day: 20,
                    hour: 2,
                    minute: 30,
                    second: 0
                )
            )
        )

        let context = MetadataContext.build(
            from: PhotoMetadata(
                captureDate: captureDate,
                captureTimezoneOffsetSeconds: 8 * 3600,
                deviceBrand: "Apple",
                deviceModel: "iPhone 17 Pro"
            )
        )

        #expect(context[MetadataContext.Key.year] == "2026")
        #expect(context[MetadataContext.Key.month] == "06")
        #expect(context[MetadataContext.Key.day] == "20")
        #expect(context[MetadataContext.Key.hour] == "10")
        #expect(context[MetadataContext.Key.minute] == "30")
        #expect(context[MetadataContext.Key.captureDateShort] == "2026.06.20")
        #expect(context[MetadataContext.Key.captureTimeShort] == "10:30")
        #expect(context[MetadataContext.Key.captureTimezone] == "UTC+08:00")
    }
}
