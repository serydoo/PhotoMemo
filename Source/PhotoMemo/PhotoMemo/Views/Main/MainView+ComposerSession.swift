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
        ?? MainTemplateEditorDisplayEngine
        .displayState(
            from: templateValue(for: slot)
        ).text
    }

    func templateEditorModuleSpans(
        for slot: MainFieldSlot
    ) -> [TemplateEditorModuleSpan] {

        editorSession.moduleSpansBySlot[slot]
        ?? MainTemplateEditorDisplayEngine
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
            MainTemplateEditorDisplayEngine
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
            MainTemplateEditorDisplayEngine
            .sanitizedModuleSpans(
                moduleSpans,
                in: displayText
            )

        editorSession.selections[slot] =
            clampedSelection(
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
                    clampedSelection(
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

        MainTemplateEditorDisplayEngine
            .rawTemplateValue(
                from: displayText,
                moduleSpans: moduleSpans
            )
    }

    func clampedSelection(
        _ selection: NSRange,
        in text: String
    ) -> NSRange {

        let length =
            (text as NSString).length

        let clampedLocation =
            min(
                max(selection.location, 0),
                length
            )

        let clampedLength =
            min(
                max(selection.length, 0),
                length - clampedLocation
            )

        return NSRange(
            location: clampedLocation,
            length: clampedLength
        )
    }

    func configureInitialState() {

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

        if titleText.isEmpty {
            titleText = settings.draftTitleText
        }

        if storyText.isEmpty {
            storyText = settings.draftStoryText
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

            let editorDisplayState =
                MainTemplateEditorDisplayEngine
                .displayState(
                    from: rawValue
                )

            editorSession.displayTexts[slot] =
                editorDisplayState.text
            editorSession.moduleSpansBySlot[slot] =
                editorDisplayState.moduleSpans

            let displayLength =
                (
                    editorDisplayState.text
                    as NSString
                ).length

            if resetTransientState
                || editorSession.selections[slot]
                == nil {
                editorSession.selections[slot] =
                    NSRange(
                        location: displayLength,
                        length: 0
                    )
            } else if let selection =
                editorSession.selections[slot] {
                editorSession.selections[slot] =
                    clampedSelection(
                        selection,
                        in: editorDisplayState.text
                    )
            }
        }
    }
}
