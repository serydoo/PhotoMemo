import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryCalculationResult: Hashable {

    let daysSince: String

    let yearsSince: String

    let monthsSince: String

    let weeksSince: String

    let babyAge: String

    let memorySummary: String

    init(
        daysSince: String = "",
        yearsSince: String = "",
        monthsSince: String = "",
        weeksSince: String = "",
        babyAge: String = "",
        memorySummary: String = ""
    ) {
        self.daysSince = daysSince
        self.yearsSince = yearsSince
        self.monthsSince = monthsSince
        self.weeksSince = weeksSince
        self.babyAge = babyAge
        self.memorySummary = memorySummary
    }
}
#endif
