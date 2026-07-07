#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct V1IOSHomeSubjectSummaryProjection: Equatable {
    let title: String
    let subtitle: String
    let anchorTitle: String
}

struct V1IOSHomeOutputSummaryProjection: Equatable {
    let title: String
    let detail: String
    let memoryWriteLabel: String
    let targetNote: String
    let memoryWriteDetail: String
}

struct V1IOSHomePresetSummaryProjection: Equatable {
    let title: String
    let subtitle: String
    let detail: String
    let statusLabel: String
    let emphasizesAppliedState: Bool
}

enum V1IOSHomeProjection {

    static func subjectSummary(
        subject: MemorySubject?,
        selectedAnchorTitle: String?
    ) -> V1IOSHomeSubjectSummaryProjection {

        let title =
            normalizedSubjectTitle(
                subject
            )

        let subtitle =
            normalizedSubjectSubtitle(
                subject
            )

        let anchorTitle =
            normalizedAnchorTitle(
                subject?
                .primaryTimeAnchor?
                .title
                ?? selectedAnchorTitle
            )

        return V1IOSHomeSubjectSummaryProjection(
            title: title,
            subtitle: subtitle,
            anchorTitle: anchorTitle
        )
    }

    static func outputSummary(
        outputTarget: V1IOSOutputTarget,
        selectedExistingAlbumTitle: String,
        newAlbumName: String,
        writesMemoryDescription: Bool
    ) -> V1IOSHomeOutputSummaryProjection {

        V1IOSHomeOutputSummaryProjection(
            title: outputTarget.title,
            detail:
                normalizedOutputDetail(
                    outputTarget: outputTarget,
                    selectedExistingAlbumTitle:
                        selectedExistingAlbumTitle,
                    newAlbumName: newAlbumName
                ),
            memoryWriteLabel:
                writesMemoryDescription
                ? "写入说明已开启"
                : "写入说明已关闭",
            targetNote:
                outputTarget.note,
            memoryWriteDetail:
                writesMemoryDescription
                ? "生成结果会附带当前记忆说明。"
                : "生成结果不会额外写入说明文本。"
        )
    }

    static func presetSummary(
        presetTitle: String,
        configurationLabel: String,
        presetSummary: String,
        activeConfigurationStatus:
            V1ConfigurationStatus,
        isApplied: Bool
    ) -> V1IOSHomePresetSummaryProjection {

        return V1IOSHomePresetSummaryProjection(
            title:
                normalizedOptionalText(
                    presetTitle
                )
                ?? "记忆预设",
            subtitle:
                normalizedOptionalText(
                    configurationLabel
                )
                ?? "当前生效配置",
            detail:
                normalizedOptionalText(
                    presetSummary
                )
                ?? "当前生效配置摘要",
            statusLabel:
                isApplied
                ? V1ConfigurationStatus
                    .saved
                    .message(for: .preset)
                : activeConfigurationStatus
                    .message(for: .preset),
            emphasizesAppliedState:
                isApplied
        )
    }

    static func emptyPresetSummary(
        configurationLabel: String
    ) -> V1IOSHomePresetSummaryProjection {

        V1IOSHomePresetSummaryProjection(
            title: "当前对象还没有配置",
            subtitle:
                normalizedOptionalText(
                    configurationLabel
                )
                ?? "当前生效配置",
            detail: "请先到配置中心底部新建配置，之后这里就能直接下拉切换。",
            statusLabel: "等待配置",
            emphasizesAppliedState: false
        )
    }

    static func savedStatusValue(
        savedAt: Date?,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {

        guard let savedAt else {
            return "尚未保存"
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let components =
            calendar.dateComponents(
                [.month, .day, .hour, .minute],
                from: savedAt
            )

        guard
            let month = components.month,
            let day = components.day,
            let hour = components.hour,
            let minute = components.minute
        else {
            return "尚未保存"
        }

        return String(
            format: "%d月%d日 %02d:%02d",
            month,
            day,
            hour,
            minute
        )
    }

    private static func normalizedSubjectTitle(
        _ subject: MemorySubject?
    ) -> String {

        let shortName =
            subject?
            .identity
            .shortName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !shortName.isEmpty {
            return shortName
        }

        let displayName =
            subject?
            .identity
            .displayName
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !displayName.isEmpty {
            return displayName
        }

        return "记忆对象"
    }

    private static func normalizedSubjectSubtitle(
        _ subject: MemorySubject?
    ) -> String {

        let relationshipLabel =
            subject?
            .relationship
            .label
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !relationshipLabel.isEmpty {
            return relationshipLabel
        }

        return "补充主角信息"
    }

    private static func normalizedAnchorTitle(
        _ selectedAnchorTitle: String?
    ) -> String {

        let trimmed =
            selectedAnchorTitle?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        if !trimmed.isEmpty {
            return trimmed
        }

        return "未设置"
    }

    private static func normalizedOutputDetail(
        outputTarget: V1IOSOutputTarget,
        selectedExistingAlbumTitle: String,
        newAlbumName: String
    ) -> String {

        switch outputTarget {
        case .automatic:
            return "系统图库 + 时光记相册"
        case .applePhotos:
            return "仅写入系统图库"
        case .existingAlbum:
            let trimmed =
                selectedExistingAlbumTitle
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            return trimmed.isEmpty
                ? "尚未选择相册"
                : trimmed
        case .newAlbum:
            let trimmed =
                newAlbumName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

            return trimmed.isEmpty
                ? "保存时创建相册"
                : trimmed
        }
    }

    private static func normalizedOptionalText(
        _ text: String
    ) -> String? {

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
