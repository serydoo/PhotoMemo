import Foundation

struct AnchorResult: Hashable {

    let title: String

    let isFutureRelative: Bool

    let primaryText: String

    let secondaryText: String

    let summaryText: String

    let ageText: String

    let durationText: String

    let countdownText: String

    let elapsedText: String

    let dayIndexText: String

    let weekText: String

    let monthAgeText: String

    let milestoneText: String

    let years: Int

    let months: Int

    let days: Int

    let hours: Int

    let minutes: Int

    let seconds: Int

    let totalDays: Int

    init(
        title: String,
        isFutureRelative: Bool,
        primaryText: String,
        secondaryText: String,
        summaryText: String,
        ageText: String,
        durationText: String,
        countdownText: String,
        elapsedText: String,
        dayIndexText: String,
        weekText: String,
        monthAgeText: String,
        milestoneText: String,
        years: Int,
        months: Int,
        days: Int,
        hours: Int,
        minutes: Int,
        seconds: Int,
        totalDays: Int
    ) {
        self.title = title
        self.isFutureRelative = isFutureRelative
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.summaryText = summaryText
        self.ageText = ageText
        self.durationText = durationText
        self.countdownText = countdownText
        self.elapsedText = elapsedText
        self.dayIndexText = dayIndexText
        self.weekText = weekText
        self.monthAgeText = monthAgeText
        self.milestoneText = milestoneText
        self.years = years
        self.months = months
        self.days = days
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.totalDays = totalDays
    }
}
