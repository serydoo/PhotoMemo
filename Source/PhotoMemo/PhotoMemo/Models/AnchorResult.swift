import Foundation

struct AnchorResult: Hashable {

    let title: String

    let primaryText: String

    let secondaryText: String

    let summaryText: String

    let ageText: String

    let durationText: String

    let years: Int

    let months: Int

    let days: Int

    let hours: Int

    let minutes: Int

    let seconds: Int

    let totalDays: Int

    init(
        title: String,
        primaryText: String,
        secondaryText: String,
        summaryText: String,
        ageText: String,
        durationText: String,
        years: Int,
        months: Int,
        days: Int,
        hours: Int,
        minutes: Int,
        seconds: Int,
        totalDays: Int
    ) {
        self.title = title
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.summaryText = summaryText
        self.ageText = ageText
        self.durationText = durationText
        self.years = years
        self.months = months
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.totalDays = totalDays
    }
}
