#if !PHOTOMEMO_SHARE_EXTENSION
import SwiftUI

struct V1SubjectHomeSummaryPresentation: Equatable {

    let configurationTitle: String
    let subjectTitle: String
    let relationshipSummary: String
    let anchorSummary: String
    let description: String
    let statusText: String
    let statusTone:
        V1IOSHomeStatusBadge.Tone
}

enum V1SubjectHomeSummaryPresenter {

    static func presentation(
        subject: MemorySubject?,
        currentConfigurationLabel: String,
        activeConfigurationStatus:
            V1ConfigurationStatus,
        currentTimeAnchorTitle: String,
        currentTimeAnchorDescription: String
    ) -> V1SubjectHomeSummaryPresentation {
        let subjectProjection =
            V1IOSHomeProjection
            .subjectSummary(
                subject: subject,
                selectedAnchorTitle:
                    currentTimeAnchorTitle
            )

        let subjectTitle =
            subjectProjection.title

        let statusText =
            activeConfigurationStatus
            .message(for: .shareConfiguration)

        let description =
            normalizedText(
                currentTimeAnchorDescription,
                fallback: "用于生成照片底部信息卡。"
            )

        return V1SubjectHomeSummaryPresentation(
            configurationTitle:
                normalizedText(
                    currentConfigurationLabel,
                    fallback: subjectTitle
                ),
            subjectTitle: subjectTitle,
            relationshipSummary:
                subjectProjection.subtitle,
            anchorSummary:
                subjectProjection.anchorTitle,
            description: description,
            statusText: statusText,
            statusTone:
                activeConfigurationStatus
                .tone
        )
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

    private static func normalizedText(
        _ text: String,
        fallback: String
    ) -> String {
        normalizedOptionalText(text)
        ?? fallback
    }
}

struct V1SubjectHomeSummaryView: View {

    let presentation:
        V1SubjectHomeSummaryPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(presentation.configurationTitle)
                    .font(.headline.weight(.semibold))
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Spacer(minLength: 12)

                V1IOSHomeStatusBadge(
                    text:
                        presentation.statusText,
                    tone:
                        presentation
                        .statusTone
                )
            }

            Text("下一次从 Apple Photos 分享进入 PhotoMemo 时，会默认使用当前这套配置组合与时间锚点。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            V1IOSHomeInsetGroup {
                V1IOSHomeSemanticRow(
                    title: "当前记忆对象",
                    value:
                        presentation
                        .subjectTitle,
                    detail:
                        presentation
                        .relationshipSummary,
                    systemImage:
                        "person.crop.circle.fill"
                )

                V1IOSHomeSemanticRow(
                    title: "当前时间锚点",
                    value:
                        presentation
                        .anchorSummary,
                    systemImage:
                        "clock.badge.checkmark"
                )

                V1IOSHomeSemanticRow(
                    title: "卡片摘要",
                    value: "已就绪",
                    detail:
                        presentation
                        .description,
                    systemImage: "text.quote",
                    showsDivider: false
                )
            }
        }
    }
}

#endif
