import Foundation

extension MainView {

    func resetCurrentTemplateToPresetDefaults() {

        settings.selectedTemplate =
            templatePresetEngine.build(
                preset: currentPreset
            )
        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
        settings.saveTemplate()
    }

    var currentEditingSlot: MainFieldSlot? {

        editorSession.focusedField
    }

    func shouldRefreshComposerItemsFromTemplate()
    -> Bool {

        for slot in MainFieldSlot.allCases {

            guard
                let displayText =
                    editorSession.displayTexts[slot]
            else {
                return true
            }

            if rawTemplateValue(
                from: displayText,
                moduleSpans:
                    templateEditorModuleSpans(
                        for: slot
                    )
            )
                != templateValue(for: slot) {
                return true
            }
        }

        return false
    }

    func updateTemplateValue(
        _ value: String,
        for slot: MainFieldSlot
    ) {

        var template = activeTemplate

        switch slot {

        case .leftTop:
            update(
                &template.leftTopArea.items,
                fallback: .title,
                value: value
            )

        case .rightTop:
            update(
                &template.rightTopArea.items,
                fallback: .cameraSummary,
                value: value
            )

        case .leftBottom:
            update(
                &template.leftBottomArea.items,
                fallback: .captureDateLine,
                value: value
            )

        case .rightBottom:
            update(
                &template.rightBottomArea.items,
                fallback: .anchorSmartText,
                value: value
            )
        }

        settings.selectedTemplate = template
        settings.scheduleTemplateSave()
    }

    func update(
        _ items: inout [TemplateItem],
        fallback: TemplateItem,
        value: String
    ) {

        var item =
            items.first ?? fallback

        item.value = value
        item.isEnabled = true
        items = [item]
    }

    func insertToken(
        _ token: String
    ) {

        if let descriptor =
            MainTemplateEditorDisplayEngine
            .descriptor(
                forToken: token
            ) {

            let label =
                MainTemplateEditorDisplayEngine
                .displayLabel(
                    for: descriptor
                )

            insertSnippet(
                label,
                insertedModuleSpans: [
                    TemplateEditorModuleSpan(
                        token: token,
                        range: NSRange(
                            location: 0,
                            length:
                                (label as NSString)
                                .length
                        )
                    )
                ]
            )

        } else {
            let displayState =
                MainTemplateEditorDisplayEngine
                .displayState(
                    from: token
                )

            insertSnippet(
                displayState.text,
                insertedModuleSpans:
                    displayState.moduleSpans
            )
        }
    }

    func insertSnippet(
        _ snippet: String,
        insertedModuleSpans:
            [TemplateEditorModuleSpan] = []
    ) {

        guard let slot = currentEditingSlot else {
            presentAlert(
                title: "请先选择自定义区域",
                message: "先点左上、右上、左下或右下任意一个区域，再插入 EXIF、智能数据或自定义文字。"
            )
            return
        }

        let currentDisplayText =
            templateEditorDisplayText(
                for: slot
            )

        let currentSelection =
            MainTemplateEditorDisplayEngine
            .adjustedEditingRange(
                editorSession.selections[slot]
                ?? NSRange(
                    location:
                        (
                            currentDisplayText
                            as NSString
                        ).length,
                    length: 0
                ),
                moduleSpans:
                    templateEditorModuleSpans(
                        for: slot
                    ),
                in: currentDisplayText
            )

        let replacementState =
            MainTemplateEditorDisplayEngine
            .replacementResult(
                for: currentDisplayText,
                moduleSpans:
                    templateEditorModuleSpans(
                        for: slot
                    ),
                replacementRange:
                    currentSelection,
                replacementText: snippet,
                insertedModuleSpans:
                    insertedModuleSpans
            )

        let nextSelection = NSRange(
            location:
                currentSelection.location
                + (snippet as NSString).length,
            length: 0
        )

        applyTemplateEditorContentChange(
            displayText: replacementState.text,
            selection:
                MainTemplateEditorDisplayEngine
                .adjustedSelectionRange(
                    nextSelection,
                    moduleSpans:
                        replacementState
                        .moduleSpans,
                    in: replacementState.text
                ),
            moduleSpans:
                replacementState.moduleSpans,
            for: slot
        )

        editorSession.focusedField = slot
    }

    func activateEditingSlot(_ slot: MainFieldSlot) {

        editorSession.focusedField = slot
    }
}
