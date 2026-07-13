#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1IOSSubjectOverviewPresentation:
    Equatable {

    let title: String
    let subtitle: String
    let expressionSubjectTitle: String
    let expressionSubjectValue: String
    let anchorTitle: String
    let anchorDateLabel: String
    let anchorDescription: String
}

enum V1IOSSubjectOverviewPresenter {

    static func presentation(
        subject: MemorySubject?,
        currentTimeAnchorTitle: String,
        currentTimeAnchorDescription: String
    ) -> V1IOSSubjectOverviewPresentation {

        let anchor =
            resolvedAnchor(
                subject: subject,
                currentTimeAnchorTitle:
                    currentTimeAnchorTitle
            )

        return V1IOSSubjectOverviewPresentation(
            title:
                normalizedTitle(
                    subject
                ),
            subtitle:
                normalizedSubtitle(
                    subject
                ),
            expressionSubjectTitle:
                subject?
                .expressionSubjectSource
                .displayTitle
                ?? "显示名称",
            expressionSubjectValue:
                normalizedOptionalText(
                    subject?
                    .resolvedExpressionSubjectText
                )
                ?? "记忆对象",
            anchorTitle:
                normalizedAnchorTitle(
                    anchor?.title
                    ?? currentTimeAnchorTitle
                ),
            anchorDateLabel:
                anchor.map {
                    V1UserFacingDateFormatter.date($0.date)
                }
                ?? "未设置",
            anchorDescription:
                normalizedAnchorDescription(
                    anchor: anchor,
                    fallback:
                        currentTimeAnchorDescription
                )
        )
    }

    private static func resolvedAnchor(
        subject: MemorySubject?,
        currentTimeAnchorTitle: String
    ) -> MemorySubject.TimeAnchor? {
        guard let subject else {
            return nil
        }

        return subject.primaryTimeAnchor
        ?? subject.timeAnchors.first {
            $0.title == currentTimeAnchorTitle
        }
        ?? subject.timeAnchors.first
    }

    private static func normalizedTitle(
        _ subject: MemorySubject?
    ) -> String {
        normalizedOptionalText(
            subject?.identity.shortName
        )
        ?? normalizedOptionalText(
            subject?.identity.displayName
        )
        ?? "记忆对象"
    }

    private static func normalizedSubtitle(
        _ subject: MemorySubject?
    ) -> String {
        normalizedOptionalText(
            subject?.relationship.label
        )
        ?? "补充主角信息"
    }

    private static func normalizedAnchorTitle(
        _ title: String
    ) -> String {
        normalizedOptionalText(title)
        ?? "未设置"
    }

    private static func normalizedAnchorDescription(
        anchor: MemorySubject.TimeAnchor?,
        fallback: String
    ) -> String {
        normalizedOptionalText(
            anchor?.note
        )
        ?? normalizedOptionalText(fallback)
        ?? "用于理解这张照片在回忆中的位置。"
    }

    private static func normalizedOptionalText(
        _ text: String?
    ) -> String? {
        guard let text else {
            return nil
        }

        let trimmed =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
#endif
