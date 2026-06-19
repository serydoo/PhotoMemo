import SwiftUI

extension MainView {

    func templateValue(
        for slot: MainFieldSlot
    ) -> String {

        switch slot {

        case .leftTop:
            return activeTemplate.leftTopArea.items.first?.value ?? ""

        case .rightTop:
            return activeTemplate.rightTopArea.items.first?.value ?? ""

        case .leftBottom:
            return activeTemplate.leftBottomArea.items.first?.value ?? ""

        case .rightBottom:
            return activeTemplate.rightBottomArea.items.first?.value ?? ""
        }
    }

    func templateEditorDisplayText(
        for slot: MainFieldSlot
    ) -> String {

        editorSession.displayTexts[slot]
        ?? EditorProjectionEngine
        .displayState(
            from: templateValue(for: slot)
        ).text
    }

    func templateEditorModuleSpans(
        for slot: MainFieldSlot
    ) -> [TemplateEditorModuleSpan] {

        editorSession.moduleSpansBySlot[slot]
        ?? EditorProjectionEngine
        .displayState(
            from: templateValue(for: slot)
        ).moduleSpans
    }

    func updateTemplateEditorDisplayText(
        _ displayText: String,
        for slot: MainFieldSlot
    ) {

        editorSession.displayTexts[slot] =
            displayText
    }

    func updateTemplateEditorModuleSpans(
        _ moduleSpans: [TemplateEditorModuleSpan],
        for slot: MainFieldSlot
    ) {

        editorSession.moduleSpansBySlot[slot] =
            EditorProjectionEngine
            .sanitizedModuleSpans(
                moduleSpans,
                in: templateEditorDisplayText(
                    for: slot
                )
            )
    }

    func applyTemplateEditorContentChange(
        displayText: String,
        selection: NSRange,
        moduleSpans: [TemplateEditorModuleSpan],
        for slot: MainFieldSlot
    ) {

        editorSession.displayTexts[slot] =
            displayText

        editorSession.moduleSpansBySlot[slot] =
            EditorProjectionEngine
            .sanitizedModuleSpans(
                moduleSpans,
                in: displayText
            )

        editorSession.selections[slot] =
            EditorProjectionEngine
            .normalizedSelectionRange(
                selection,
                in: displayText
            )

        updateTemplateValue(
            rawTemplateValue(
                from: displayText,
                moduleSpans:
                    templateEditorModuleSpans(
                        for: slot
                    )
            ),
            for: slot
        )
    }

    func templateEditorDisplayBinding(
        for slot: MainFieldSlot
    ) -> Binding<String> {

        Binding(
            get: {
                templateEditorDisplayText(
                    for: slot
                )
            },
            set: { newValue in
                updateTemplateEditorDisplayText(
                    newValue,
                    for: slot
                )
            }
        )
    }

    func templateEditorModuleSpansBinding(
        for slot: MainFieldSlot
    ) -> Binding<[TemplateEditorModuleSpan]> {

        Binding(
            get: {
                templateEditorModuleSpans(
                    for: slot
                )
            },
            set: { newValue in
                updateTemplateEditorModuleSpans(
                    newValue,
                    for: slot
                )
            }
        )
    }

    func templateEditorSelectionBinding(
        for slot: MainFieldSlot
    ) -> Binding<NSRange> {

        Binding(
            get: {
                editorSession.selections[slot]
                ?? NSRange(
                    location:
                        (
                            templateEditorDisplayText(
                                for: slot
                            ) as NSString
                        ).length,
                    length: 0
                )
            },
            set: { newValue in
                editorSession.selections[slot] =
                    EditorProjectionEngine
                    .normalizedSelectionRange(
                        newValue,
                        in: templateEditorDisplayText(
                            for: slot
                        )
                    )
            }
        )
    }

    func rawTemplateValue(
        from displayText: String,
        moduleSpans: [TemplateEditorModuleSpan]
    ) -> String {

        EditorProjectionEngine
            .rawTemplateValue(
                from: displayText,
                moduleSpans: moduleSpans
            )
    }

    func configureInitialState() {

        normalizeSelectedTemplateIfNeeded()

        if selectedAnchorID == nil {
            let persistedAnchorID =
                UUID(uuidString: settings.selectedAnchorIDString)

            if let persistedAnchorID,
               settings.anchors.contains(
                where: { $0.id == persistedAnchorID }
               ) {
                selectedAnchorID = persistedAnchorID
            } else {
                selectedAnchorID =
                    settings.anchors.first?.id
            }
        }

        if selectedAlbumIdentifier
            == PhotoAlbumOption.automaticIdentifier,
           !settings.selectedAlbumIdentifier.isEmpty {
            selectedAlbumIdentifier =
                settings.selectedAlbumIdentifier
        }

        syncComposerItemsFromTemplate(
            resetTransientState: true
        )
    }

    func normalizeSelectedTemplateIfNeeded() {

        guard let selectedTemplate =
            settings.selectedTemplate
        else {
            return
        }

        let normalizedTemplate =
            normalizedPrimaryTemplate(
                selectedTemplate
            )

        guard normalizedTemplate != selectedTemplate else {
            return
        }

        settings.selectedTemplate = normalizedTemplate
        settings.saveTemplate()
    }

    func migrateLegacyConfigurationIntoActiveSlotIfNeeded() {

        let hasNoCustomizedSlots =
            settings.configurationSlots.allSatisfy {
                !$0.isCustomized
            }

        guard hasNoCustomizedSlots else {
            return
        }

        settings.updateConfigurationSlot(
            settings.activeConfigurationSlotID,
            snapshot:
                currentBatchConfigurationSnapshot
        )
    }

    func syncComposerItemsFromTemplate(
        resetTransientState: Bool = false
    ) {

        if resetTransientState {
            editorSession.focusedField = nil
        }

        for slot in MainFieldSlot.allCases {

            let rawValue =
                templateValue(for: slot)

            let projectionState =
                EditorProjectionEngine
                .synchronizedState(
                    from: rawValue,
                    selection:
                        editorSession.selections[slot],
                    resetSelectionToEnd:
                        resetTransientState
                )

            editorSession.displayTexts[slot] =
                projectionState.text
            editorSession.moduleSpansBySlot[slot] =
                projectionState.moduleSpans
            editorSession.selections[slot] =
                projectionState.selection
        }
    }
}
