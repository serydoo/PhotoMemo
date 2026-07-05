import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
enum MemoryResultDirection:
    String,
    Codable,
    Hashable {

    case beforeAnchor
    case onAnchor
    case afterAnchor
}

enum MemoryResultPrecision:
    String,
    Codable,
    Hashable {

    case day
    case missingCaptureDate
}

enum MemoryAnchorResultStatus:
    String,
    Codable,
    Hashable {

    case resolved
    case missingCaptureDate
    case missingAnchor
    case disabledAnchor
    case unsupportedAnchor
}

enum MemoryResultSource:
    String,
    Codable,
    Hashable {

    case frozenConfiguration
    case compatibility
}

struct MemoryElapsedTime:
    Codable,
    Hashable {

    let years: Int
    let months: Int
    let days: Int
    let totalDays: Int
    let weeks: Int
    let totalMonths: Int
    let isFutureRelative: Bool

    init(
        years: Int,
        months: Int,
        days: Int,
        totalDays: Int,
        weeks: Int,
        totalMonths: Int,
        isFutureRelative: Bool
    ) {
        self.years = max(years, 0)
        self.months = max(months, 0)
        self.days = max(days, 0)
        self.totalDays = max(totalDays, 0)
        self.weeks = max(weeks, 0)
        self.totalMonths = max(totalMonths, 0)
        self.isFutureRelative =
            isFutureRelative
    }

    init(
        relativeSnapshot:
            MemoryAnchorRelativeSnapshot
    ) {
        self.init(
            years: relativeSnapshot.years,
            months: relativeSnapshot.months,
            days: relativeSnapshot.days,
            totalDays:
                relativeSnapshot.totalDays,
            weeks:
                relativeSnapshot.totalDays / 7,
            totalMonths:
                relativeSnapshot.years * 12
                + relativeSnapshot.months,
            isFutureRelative:
                relativeSnapshot.isFutureRelative
        )
    }

    var relativeSnapshot:
        MemoryAnchorRelativeSnapshot {

        MemoryAnchorRelativeSnapshot(
            years: years,
            months: months,
            days: days,
            totalDays: totalDays,
            isFutureRelative:
                isFutureRelative
        )
    }
}

struct MemoryAnchorResult:
    Identifiable,
    Codable,
    Hashable {

    let id: UUID
    let anchorID: UUID
    let anchorType: AnchorType?
    let anchorTitle: String
    let anchorDate: Date
    let direction: MemoryResultDirection
    let elapsed: MemoryElapsedTime
    let precision: MemoryResultPrecision
    let status: MemoryAnchorResultStatus
    let source: MemoryResultSource

    init(
        id: UUID,
        anchorID: UUID,
        anchorType: AnchorType?,
        anchorTitle: String,
        anchorDate: Date,
        direction: MemoryResultDirection,
        elapsed: MemoryElapsedTime,
        precision: MemoryResultPrecision,
        status: MemoryAnchorResultStatus,
        source: MemoryResultSource
    ) {
        self.id = id
        self.anchorID = anchorID
        self.anchorType = anchorType
        self.anchorTitle = anchorTitle
        self.anchorDate = anchorDate
        self.direction = direction
        self.elapsed = elapsed
        self.precision = precision
        self.status = status
        self.source = source
    }
}

struct MemoryResult:
    Codable,
    Hashable {

    let subjectID: MemorySubject.ID
    let captureDate: Date?
    let primaryAnchorResultID: UUID?
    let anchorResults: [MemoryAnchorResult]

    init(
        subjectID: MemorySubject.ID,
        captureDate: Date?,
        primaryAnchorResultID: UUID?,
        anchorResults: [MemoryAnchorResult]
    ) {
        self.subjectID = subjectID
        self.captureDate = captureDate
        self.primaryAnchorResultID =
            primaryAnchorResultID
        self.anchorResults = anchorResults
    }

    var primaryAnchorResult:
        MemoryAnchorResult? {

        guard let primaryAnchorResultID else {
            return nil
        }

        return anchorResults.first {
            $0.id == primaryAnchorResultID
        }
    }
}
#endif
