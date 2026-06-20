import SwiftUI

extension MainView {

    var selectedPhotoDeviceModelText: String? {

        guard let selectedPhoto else {
            return nil
        }

        let deviceModel =
            selectedPhoto.metadata.deviceModel

        return deviceModel.isEmpty
            ? "未识别设备"
            : deviceModel
    }

    var selectedPhotoCaptureDateText: String? {

        selectedPhoto?.metadata.captureDate?
            .formatted(
                date: .abbreviated,
                time: .shortened
            )
    }

    var currentCard: RecordCard? {

        guard let selectedPhoto else {
            return nil
        }

        return cardBuildService.buildCard(
            from: selectedPhoto,
            configuration:
                currentBatchConfigurationSnapshot
        )
    }

    var workspaceConfigurationSummary: String {

        let slot =
            activeWorkspaceConfigurationSlot

        if slot.isCustomized {
            return "当前使用：\(slot.displayTitleWithReference)。切换后，左侧内容和右侧预览会一起刷新。"
        }

        return "当前使用：\(slot.displayTitleWithReference)。这套风格还没有单独保存。"
    }

    var activeTemplate: Template {

        normalizedPrimaryTemplate(
            settings.selectedTemplate
            ?? .template1
        )
    }

    var currentPreset: TemplatePreset {

        .template1
    }

    var currentPresetDefaultOutput: String {

        "主角称呼 + 今天 + 年岁"
    }

    var selectedAnchor: Anchor? {

        settings.anchors.first {
            $0.id == selectedAnchorID
        }
    }

    var anchorPreviewResult: AnchorResult? {

        guard let selectedAnchor else {
            return nil
        }

        return anchorEngine.build(
            from: selectedAnchor,
            photoDate:
                selectedPhoto?.metadata.captureDate
                ?? Date()
        )
    }

    var selectedAlbumSummary: String {

        guard permissionCenter.canAccessPhotoLibrary else {
            return "请先允许访问系统相册"
        }

        if selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier {
            return "自动存入 PhotoMemo"
        }

        if selectedAlbumIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            return "系统相册"
        }

        return resolvedAlbumTitle(
            for: selectedAlbumIdentifier
        ) ?? "当前相册"
    }

    var anchorQuickFactItems:
        [MainAnchorQuickFact] {

        anchorPreviewResult.map { preview in
            anchorQuickFacts(preview).map {
                MainAnchorQuickFact(
                    label: $0.label,
                    value: $0.value
                )
            }
        } ?? []
    }

    var selectedBadgeTitle: String {

        guard let badge = settings.selectedBadge,
              badge.type != .none else {
            if currentPreset == .immersWhite {
                return "自动 Apple 标识"
            }

            return "保持留白"
        }

        return badge.name
    }

    var selectedBadgeSummary: String {

        guard let badge = settings.selectedBadge,
              badge.type != .none else {
            if currentPreset == .immersWhite {
                return "未自定义时，Immers 白边会自动使用经典 Apple 小标识，并贴近右侧信息区显示。"
            }

            return "当前风格会保留标识区域留白，适合更极简的版式。"
        }

        if badge.isSystemDefault {
            return "使用系统标识，适合底栏白边的克制视觉风格。"
        }

        return "使用自定义标识资源。"
    }

    var defaultPhotoDescription: String {

        guard let selectedPhoto else {
            return ""
        }

        return cardBuildService
            .defaultPhotoDescription(
                from: selectedPhoto,
                configuration:
                    currentBatchConfigurationSnapshot
            )
    }

    var defaultPhotoDescriptionHint: String {

        let resolvedDefault =
            defaultPhotoDescription

        if resolvedDefault.isEmpty {
            return "默认说明会跟随右下区域内容；如果右下区域暂时为空，就不会额外写入说明。"
        }

        return "默认说明：\(resolvedDefault)"
    }

    var canExportCurrentCard: Bool {

        selectedPhoto != nil
        && currentCard != nil
    }

    func anchorDateText(
        _ anchor: Anchor
    ) -> String {

        anchor.date.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    func anchorQuickFacts(
        _ preview: AnchorResult
    ) -> [(label: String, value: String)] {

        if preview.isFutureRelative {
            return [
                ("倒计时", preview.countdownText),
                ("时间点", preview.secondaryText)
            ]
        }

        if let anchor = selectedAnchor,
           anchor.type == .birthday {
            return [
                ("年岁", preview.ageText),
                ("第几天", preview.dayIndexText),
                ("月龄", preview.monthAgeText)
            ]
            .filter {
                !$0.value.isEmpty
            }
        }

        var facts: [(String, String)] = [
            ("时长", preview.durationText),
            ("已过", preview.elapsedText)
        ]

        if !preview.milestoneText.isEmpty {
            facts.append(
                ("里程碑", preview.milestoneText)
            )
        }

        return facts.filter {
            !$0.1.isEmpty
        }
    }

    var resolvedTemplateDisplayName: String {

        let trimmed =
            activeTemplate.name
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if !trimmed.isEmpty {
            return trimmed
        }

        return currentPreset.displayName
    }

    func normalizedPrimaryTemplate(
        _ template: Template
    ) -> Template {

        var normalized = template
        normalized.preset = .template1
        return normalized.normalizedForEditing
    }

    func resolvedAlbumTitle(
        for identifier: String
    ) -> String? {

        let normalizedIdentifier =
            settings.normalizedAlbumIdentifier(
                identifier
            )

        guard !normalizedIdentifier.isEmpty else {
            return nil
        }

        if normalizedIdentifier
            == PhotoMemoAlbumSelection
            .systemLibraryIdentifier {
            return "系统相册"
        }

        if let availableAlbumTitle =
            availableAlbums.first(where: {
                $0.id == normalizedIdentifier
            })?.title
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
           !availableAlbumTitle.isEmpty {
            return availableAlbumTitle
        }

        let persistedAlbumTitle =
            settings.selectedAlbumTitle
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if settings.normalizedSelectedAlbumIdentifier
            == normalizedIdentifier,
           !persistedAlbumTitle.isEmpty {
            return persistedAlbumTitle
        }

        return nil
    }
}
