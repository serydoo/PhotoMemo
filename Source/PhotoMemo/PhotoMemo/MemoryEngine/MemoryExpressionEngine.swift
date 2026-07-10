import Foundation

#if !PHOTOMEMO_SHARE_EXTENSION
struct MemoryExpressionEngine {

    private let subjectStrategy:
        any SubjectStrategy

    init(
        subjectStrategy:
            any SubjectStrategy = ConfiguredSubjectStrategy()
    ) {
        self.subjectStrategy =
            subjectStrategy
    }

    func generateResult(
        context: MemoryExpressionContext
    ) -> MemoryResult {
        guard let sourceAnchor =
            context.snapshot.primaryAnchor
        else {
            return MemoryResult(
                subjectID:
                    context.subject.id,
                captureDate:
                    context.captureDate,
                primaryAnchorResultID: nil,
                anchorResults: []
            )
        }

        if !sourceAnchor.isEnabled {
            let anchorResult =
                unresolvedAnchorResult(
                    anchor: sourceAnchor,
                    status:
                        .disabledAnchor,
                    precision: .day
                )

            return MemoryResult(
                subjectID:
                    context.subject.id,
                captureDate:
                    context.captureDate,
                primaryAnchorResultID:
                    anchorResult.id,
                anchorResults: [
                    anchorResult
                ]
            )
        }

        if sourceAnchor.anchorType == nil {
            let anchorResult =
                unresolvedAnchorResult(
                    anchor: sourceAnchor,
                    status:
                        .unsupportedAnchor,
                    precision: .day
                )

            return MemoryResult(
                subjectID:
                    context.subject.id,
                captureDate:
                    context.captureDate,
                primaryAnchorResultID:
                    anchorResult.id,
                anchorResults: [
                    anchorResult
                ]
            )
        }

        guard let captureDate =
            context.captureDate
        else {
            let anchorResult =
                unresolvedAnchorResult(
                    anchor: sourceAnchor,
                    status:
                        .missingCaptureDate,
                    precision:
                        .missingCaptureDate
                )

            return MemoryResult(
                subjectID:
                    context.subject.id,
                captureDate: nil,
                primaryAnchorResultID:
                    anchorResult.id,
                anchorResults: [
                    anchorResult
                ]
            )
        }

        let relativeSnapshot =
            MemoryAnchorRelativeSnapshot
            .resolve(
                anchorDate:
                    sourceAnchor.date,
                captureDate:
                    captureDate,
                calendar:
                    context.captureCalendar
            )
        let anchorResult =
            MemoryAnchorResult(
                id: UUID(),
                anchorID:
                    sourceAnchor.id,
                anchorType:
                    sourceAnchor.anchorType,
                anchorTitle:
                    sourceAnchor.title,
                anchorDate:
                    sourceAnchor.date,
                direction:
                    direction(
                        relativeSnapshot:
                            relativeSnapshot
                    ),
                elapsed:
                    MemoryElapsedTime(
                        relativeSnapshot:
                            relativeSnapshot
                    ),
                precision: .day,
                status: .resolved,
                source:
                    .frozenConfiguration
            )

        return MemoryResult(
            subjectID:
                context.subject.id,
            captureDate:
                captureDate,
            primaryAnchorResultID:
                anchorResult.id,
            anchorResults: [
                anchorResult
            ]
        )
    }
}

private extension MemoryExpressionEngine {

    func unresolvedAnchorResult(
        anchor: MemoryAnchor,
        status: MemoryAnchorResultStatus,
        precision: MemoryResultPrecision
    ) -> MemoryAnchorResult {
        MemoryAnchorResult(
            id: UUID(),
            anchorID: anchor.id,
            anchorType:
                anchor.anchorType,
            anchorTitle:
                anchor.title,
            anchorDate:
                anchor.date,
            direction:
                .onAnchor,
            elapsed:
                MemoryElapsedTime(
                    years: 0,
                    months: 0,
                    days: 0,
                    totalDays: 0,
                    weeks: 0,
                    totalMonths: 0,
                    isFutureRelative:
                        false
                ),
            precision: precision,
            status: status,
            source:
                .frozenConfiguration
        )
    }

    func direction(
        relativeSnapshot:
            MemoryAnchorRelativeSnapshot
    ) -> MemoryResultDirection {

        if relativeSnapshot.isFutureRelative {
            return .beforeAnchor
        }

        return relativeSnapshot.totalDays == 0
            ? .onAnchor
            : .afterAnchor
    }
}
#endif
