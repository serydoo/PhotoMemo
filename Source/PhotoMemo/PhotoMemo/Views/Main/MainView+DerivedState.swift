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
            return "当前生效：\(slot.displayTitleWithReference)。切换到其他配置后，左侧模板、时间点、Logo 标识、补充信息和输出规则会整体刷新。"
        }

        return "当前生效：\(slot.displayTitleWithReference)。这套配置还未单独保存，暂时使用\(slot.defaultPreset.displayName)默认骨架。"
    }

    var activeTemplate: Template {

        settings.selectedTemplate
        ?? .template1
    }

    var currentPreset: TemplatePreset {

        activeTemplate.preset
    }

    var currentPresetDefaultOutput: String {

        switch currentPreset {

        case .template1:
            return "今天 + 年岁"

        case .template2:
            return "已经 + 纪念时长"

        case .template3:
            return "倒计时"

        case .immersWhite:
            return "记忆摘要"
        }
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

    var photoTimeDescription: String {

        guard let captureDate =
            selectedPhoto?.metadata.captureDate
        else {
            return "导入照片后，系统会用照片 EXIF 拍摄时间与锚点时间做差值计算，可生成年岁、纪念时长、已过天数、未来倒计时，以及第几天、周数、月龄等时间结果。"
        }

        return "当前照片 EXIF 时间：\(captureDate.formatted(date: .numeric, time: .standard))"
    }

    var anchorPhotoSummary: String {

        guard let captureDate =
            selectedPhoto?.metadata.captureDate
        else {
            return "导入照片后会自动读取 EXIF 拍摄时间"
        }

        return captureDate.formatted(
            date: .abbreviated,
            time: .shortened
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

        return availableAlbums.first {
            $0.id == selectedAlbumIdentifier
        }?.title ?? "当前相册"
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

            return "当前模板会保留标识区域留白，适合更极简的版式。"
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

    var selectedTemplatePreset: Binding<TemplatePreset> {

        Binding(
            get: {

                currentPreset
            },
            set: { preset in

                settings.selectedTemplate =
                    templatePresetEngine.build(
                        preset: preset
                    )

                syncComposerItemsFromTemplate(
                    resetTransientState: true
                )
                settings.saveTemplate()
            }
        )
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
}
