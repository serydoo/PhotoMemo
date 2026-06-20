import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct MainTemplateFieldEditorView: View {

    let slot: MainFieldSlot

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    @Binding
    var moduleSpans: [TemplateEditorModuleSpan]

    let placeholder: String

    let focusedField: MainFieldSlot?

    let isFocused: Bool

    let onContentChange:
        (String, NSRange, [TemplateEditorModuleSpan]) -> Void

    let onActivateEditingSlot: () -> Void

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(slot.title)
                    .font(.headline)

                Spacer()

                if focusedField == slot {

                    Text("当前区域")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(
                            MinimalPalette.accent
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    MinimalPalette
                                    .accent.opacity(0.12)
                                )
                        )
                }
            }

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                ZStack(
                    alignment: .topLeading
                ) {

                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        Color.gray.opacity(0.08)
                    )

                    if text.isEmpty {

                        Text(placeholder)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    MainInlineTemplateTextEditor(
                        text: $text,
                        selection: $selection,
                        moduleSpans: $moduleSpans,
                        isFocused: isFocused,
                        onContentChange: onContentChange,
                        onFocus: onActivateEditingSlot
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .frame(minHeight: 58)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .stroke(
                        focusedField == slot
                        ? MinimalPalette.accent.opacity(0.22)
                        : MinimalPalette.border,
                        lineWidth:
                            focusedField == slot
                            ? 1.2
                            : 1
                    )
                )
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                )
                .onTapGesture {
                    onActivateEditingSlot()
                }

            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onActivateEditingSlot()
        }
    }
}

struct MainInlineTemplateTextEditor: View {

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    @Binding
    var moduleSpans: [TemplateEditorModuleSpan]

    let isFocused: Bool

    let onContentChange:
        (String, NSRange, [TemplateEditorModuleSpan]) -> Void

    let onFocus: () -> Void

#if os(macOS)
    var body: some View {
        MacInlineTemplateTextEditor(
            text: $text,
            selection: $selection,
            moduleSpans: $moduleSpans,
            isFocused: isFocused,
            onContentChange: onContentChange,
            onFocus: onFocus
        )
    }
#elseif canImport(UIKit)
    var body: some View {
        UIKitInlineTemplateTextEditor(
            text: $text,
            selection: $selection,
            moduleSpans: $moduleSpans,
            isFocused: isFocused,
            onContentChange: onContentChange,
            onFocus: onFocus
        )
    }
#else
    var body: some View {
        TextField(
            "",
            text: $text,
            axis: .vertical
        )
        .textFieldStyle(.plain)
        .font(.system(size: 14))
    }
#endif
}

#if os(macOS)
private struct MacInlineTemplateTextEditor: NSViewRepresentable {

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    @Binding
    var moduleSpans: [TemplateEditorModuleSpan]

    let isFocused: Bool

    let onContentChange:
        (String, NSRange, [TemplateEditorModuleSpan]) -> Void

    let onFocus: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(
        context: Context
    ) -> NSScrollView {

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(
            width: 0,
            height: 8
        )
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = NSColor.labelColor
        textView.alignment = .left
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textStorage?.setAttributedString(
            context.coordinator.styledAttributedString(
                for: text,
                moduleSpans: moduleSpans
            )
        )
        textView.typingAttributes =
            context.coordinator.baseTypingAttributes

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.applySelection()
        return scrollView
    }

    func updateNSView(
        _ nsView: NSScrollView,
        context: Context
    ) {

        guard let textView =
            context.coordinator.textView
        else {
            return
        }

        context.coordinator.parent = self

        guard !textView.hasMarkedText() else {
            return
        }

        context.coordinator.applyStyledText()
        context.coordinator.applySelection()
        context.coordinator.applyFocusState()
    }

    final class Coordinator:
        NSObject,
        NSTextViewDelegate
    {

        var parent: MacInlineTemplateTextEditor

        weak var textView: NSTextView?

        var isApplyingProgrammaticUpdate = false

        let baseTypingAttributes:
            [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]

        init(
            _ parent: MacInlineTemplateTextEditor
        ) {
            self.parent = parent
        }

        func textDidBeginEditing(
            _ notification: Notification
        ) {

            parent.onFocus()
        }

        func textDidChange(
            _ notification: Notification
        ) {

            guard
                let textView,
                !isApplyingProgrammaticUpdate
            else {
                return
            }

            let sanitizedModuleSpans =
                EditorProjectionEngine
                .sanitizedModuleSpans(
                    parent.moduleSpans,
                    in: textView.string
                )

            let adjustedSelection =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    textView.selectedRange(),
                    moduleSpans:
                        sanitizedModuleSpans,
                    in: textView.string
                )

            if adjustedSelection
                != textView.selectedRange() {
                isApplyingProgrammaticUpdate = true
                textView.setSelectedRange(
                    adjustedSelection
                )
                isApplyingProgrammaticUpdate = false
            }

            parent.onContentChange(
                textView.string,
                adjustedSelection,
                sanitizedModuleSpans
            )

            applyStyledText()
        }

        func textViewDidChangeSelection(
            _ notification: Notification
        ) {

            guard
                let textView,
                !isApplyingProgrammaticUpdate
            else {
                return
            }

            let adjustedSelection =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    textView.selectedRange(),
                    moduleSpans:
                        parent.moduleSpans,
                    in: textView.string
                )

            if adjustedSelection
                != textView.selectedRange() {
                isApplyingProgrammaticUpdate = true
                textView.setSelectedRange(
                    adjustedSelection
                )
                isApplyingProgrammaticUpdate = false
            }

            parent.selection = adjustedSelection
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {

            guard !isApplyingProgrammaticUpdate else {
                return true
            }

            let adjustedRange =
                EditorProjectionEngine
                .adjustedReplacementRange(
                    affectedCharRange,
                    replacementText:
                        replacementString ?? "",
                    moduleSpans:
                        parent.moduleSpans,
                    in: textView.string
                )

            isApplyingProgrammaticUpdate = true

            let replacement =
                replacementString ?? ""

            let replacementState =
                EditorProjectionEngine
                .replacementResult(
                    for: textView.string,
                    moduleSpans:
                        parent.moduleSpans,
                    replacementRange:
                        adjustedRange,
                    replacementText: replacement
                )

            textView.textStorage?.setAttributedString(
                styledAttributedString(
                    for: replacementState.text,
                    moduleSpans:
                        replacementState
                        .moduleSpans
                )
            )

            let nextSelection =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    NSRange(
                        location:
                            adjustedRange.location
                            + (replacement as NSString)
                            .length,
                        length: 0
                    ),
                    moduleSpans:
                        replacementState
                        .moduleSpans,
                    in: replacementState.text
                )

            textView.setSelectedRange(nextSelection)
            textView.typingAttributes =
                baseTypingAttributes

            parent.onContentChange(
                replacementState.text,
                nextSelection,
                replacementState.moduleSpans
            )

            isApplyingProgrammaticUpdate = false
            return false
        }

        func applyStyledText() {

            guard
                let textView,
                !isApplyingProgrammaticUpdate
            else {
                return
            }

            let currentSelection =
                textView.selectedRange()

            isApplyingProgrammaticUpdate = true

            textView.textStorage?.setAttributedString(
                styledAttributedString(
                    for: parent.text,
                    moduleSpans: parent.moduleSpans
                )
            )
            textView.typingAttributes =
                baseTypingAttributes
            textView.setSelectedRange(
                EditorProjectionEngine
                .adjustedSelectionRange(
                    currentSelection,
                    moduleSpans:
                        parent.moduleSpans,
                    in: parent.text
                )
            )

            isApplyingProgrammaticUpdate = false
        }

        func styledAttributedString(
            for text: String,
            moduleSpans: [TemplateEditorModuleSpan]
        ) -> NSAttributedString {

            let attributedText =
                NSMutableAttributedString(
                    string: text,
                    attributes: baseTypingAttributes
                )

            for span in EditorProjectionEngine
                .sanitizedModuleSpans(
                    moduleSpans,
                    in: text
                ) {

                attributedText.addAttributes(
                    [
                        .font: NSFont.systemFont(
                            ofSize: 12,
                            weight: .medium
                        ),
                        .foregroundColor: NSColor(
                            red: 74 / 255,
                            green: 87 / 255,
                            blue: 122 / 255,
                            alpha: 1
                        ),
                        .backgroundColor: NSColor(
                            red: 228 / 255,
                            green: 233 / 255,
                            blue: 244 / 255,
                            alpha: 1
                        )
                    ],
                    range: span.range
                )
            }

            return attributedText
        }

        func applySelection() {

            guard let textView else {
                return
            }

            let safeRange =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    parent.selection,
                    moduleSpans:
                        parent.moduleSpans,
                    in: textView.string
                )

            if textView.selectedRange() != safeRange {
                textView.setSelectedRange(safeRange)
            }

            textView.typingAttributes =
                baseTypingAttributes
        }

        func applyFocusState() {

            guard let textView else {
                return
            }

            if parent.isFocused {
                guard
                    textView.window?.firstResponder
                    !== textView
                else {
                    return
                }

                DispatchQueue.main.async {
                    textView.window?.makeFirstResponder(
                        textView
                    )
                }
                return
            }

            guard
                textView.window?.firstResponder
                === textView
            else {
                return
            }

            DispatchQueue.main.async {
                textView.window?.makeFirstResponder(
                    nil
                )
            }
        }
    }
}
#endif

#if canImport(UIKit)
private struct UIKitInlineTemplateTextEditor: UIViewRepresentable {

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    @Binding
    var moduleSpans: [TemplateEditorModuleSpan]

    let isFocused: Bool

    let onContentChange:
        (String, NSRange, [TemplateEditorModuleSpan]) -> Void

    let onFocus: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(
        context: Context
    ) -> UITextView {

        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: 8,
            right: 0
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.attributedText =
            context.coordinator.styledAttributedString(
                for: text,
                moduleSpans: moduleSpans
            )
        textView.typingAttributes =
            context.coordinator.baseTypingAttributes

        context.coordinator.textView = textView
        context.coordinator.applySelection()
        return textView
    }

    func updateUIView(
        _ uiView: UITextView,
        context: Context
    ) {

        context.coordinator.parent = self

        guard
            uiView.markedTextRange == nil
        else {
            return
        }

        context.coordinator.applyStyledText()
        context.coordinator.applySelection()
        context.coordinator.applyFocusState()
    }

    final class Coordinator:
        NSObject,
        UITextViewDelegate
    {

        var parent: UIKitInlineTemplateTextEditor

        weak var textView: UITextView?

        var isApplyingProgrammaticUpdate = false

        let baseTypingAttributes:
            [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]

        init(
            _ parent: UIKitInlineTemplateTextEditor
        ) {
            self.parent = parent
        }

        func textViewDidBeginEditing(
            _ textView: UITextView
        ) {

            parent.onFocus()
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {

            guard !isApplyingProgrammaticUpdate else {
                return true
            }

            if shouldUseNativeIMEHandling(
                for: textView,
                range: range,
                replacementText: text
            ) {
                return true
            }

            let adjustedRange =
                EditorProjectionEngine
                .adjustedReplacementRange(
                    range,
                    replacementText: text,
                    moduleSpans:
                        parent.moduleSpans,
                    in: textView.text
                )

            isApplyingProgrammaticUpdate = true

            let replacementState =
                EditorProjectionEngine
                .replacementResult(
                    for: textView.text,
                    moduleSpans:
                        parent.moduleSpans,
                    replacementRange:
                        adjustedRange,
                    replacementText:
                        text
                )

            textView.attributedText =
                styledAttributedString(
                    for: replacementState.text,
                    moduleSpans:
                        replacementState
                        .moduleSpans
                )

            let nextSelection =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    NSRange(
                        location:
                            adjustedRange.location
                            + (text as NSString)
                            .length,
                        length: 0
                    ),
                    moduleSpans:
                        replacementState
                        .moduleSpans,
                    in: replacementState.text
                )

            textView.selectedRange = nextSelection
            textView.typingAttributes =
                baseTypingAttributes

            parent.onContentChange(
                replacementState.text,
                nextSelection,
                replacementState.moduleSpans
            )

            isApplyingProgrammaticUpdate = false
            return false
        }

        func textViewDidChange(
            _ textView: UITextView
        ) {

            guard !isApplyingProgrammaticUpdate else {
                return
            }

            if textView.markedTextRange != nil {
                parent.onContentChange(
                    textView.text,
                    textView.selectedRange,
                    parent.moduleSpans
                )
                return
            }

            let sanitizedModuleSpans =
                EditorProjectionEngine
                .sanitizedModuleSpans(
                    parent.moduleSpans,
                    in: textView.text
                )

            let adjustedSelection =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    textView.selectedRange,
                    moduleSpans:
                        sanitizedModuleSpans,
                    in: textView.text
                )

            if adjustedSelection
                != textView.selectedRange {
                isApplyingProgrammaticUpdate = true
                textView.selectedRange =
                    adjustedSelection
                isApplyingProgrammaticUpdate = false
            }

            parent.onContentChange(
                textView.text,
                adjustedSelection,
                sanitizedModuleSpans
            )

            applyStyledText()
        }

        func textViewDidChangeSelection(
            _ textView: UITextView
        ) {

            guard !isApplyingProgrammaticUpdate else {
                return
            }

            if textView.markedTextRange != nil {
                parent.selection =
                    textView.selectedRange
                return
            }

            let adjustedSelection =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    textView.selectedRange,
                    moduleSpans:
                        parent.moduleSpans,
                    in: textView.text
                )

            if adjustedSelection
                != textView.selectedRange {
                isApplyingProgrammaticUpdate = true
                textView.selectedRange =
                    adjustedSelection
                isApplyingProgrammaticUpdate = false
            }

            parent.selection = adjustedSelection
        }

        func applyStyledText() {

            guard
                let textView,
                !isApplyingProgrammaticUpdate
            else {
                return
            }

            let currentSelection =
                textView.selectedRange

            isApplyingProgrammaticUpdate = true

            textView.attributedText =
                styledAttributedString(
                    for: parent.text,
                    moduleSpans: parent.moduleSpans
                )
            textView.typingAttributes =
                baseTypingAttributes
            textView.selectedRange =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    currentSelection,
                    moduleSpans:
                        parent.moduleSpans,
                    in: parent.text
                )

            isApplyingProgrammaticUpdate = false
        }

        func shouldUseNativeIMEHandling(
            for textView: UITextView,
            range: NSRange,
            replacementText text: String
        ) -> Bool {

            if textView.markedTextRange != nil {
                return true
            }

            guard
                let primaryLanguage =
                    textView.textInputMode?
                    .primaryLanguage
            else {
                return false
            }

            let usesCJKKeyboard =
                primaryLanguage.hasPrefix("zh")
                || primaryLanguage.hasPrefix("ja")
                || primaryLanguage.hasPrefix("ko")

            guard usesCJKKeyboard else {
                return false
            }

            if text == "\n" {
                return false
            }

            return !text.isEmpty
                && range.length == 0
        }

        func styledAttributedString(
            for text: String,
            moduleSpans: [TemplateEditorModuleSpan]
        ) -> NSAttributedString {

            let attributedText =
                NSMutableAttributedString(
                    string: text,
                    attributes: baseTypingAttributes
                )

            for span in EditorProjectionEngine
                .sanitizedModuleSpans(
                    moduleSpans,
                    in: text
                ) {

                attributedText.addAttributes(
                    [
                        .font: UIFont.systemFont(
                            ofSize: 12,
                            weight: .medium
                        ),
                        .foregroundColor: UIColor(
                            red: 74 / 255,
                            green: 87 / 255,
                            blue: 122 / 255,
                            alpha: 1
                        ),
                        .backgroundColor: UIColor(
                            red: 228 / 255,
                            green: 233 / 255,
                            blue: 244 / 255,
                            alpha: 1
                        )
                    ],
                    range: span.range
                )
            }

            return attributedText
        }

        func applySelection() {

            guard let textView else {
                return
            }

            let safeRange =
                EditorProjectionEngine
                .adjustedSelectionRange(
                    parent.selection,
                    moduleSpans:
                        parent.moduleSpans,
                    in: textView.text
                )

            if textView.selectedRange != safeRange {
                textView.selectedRange = safeRange
            }
        }

        func applyFocusState() {

            guard let textView else {
                return
            }

            if parent.isFocused {
                guard !textView.isFirstResponder else {
                    return
                }

                DispatchQueue.main.async {
                    textView.becomeFirstResponder()
                }
                return
            }

            guard textView.isFirstResponder else {
                return
            }

            DispatchQueue.main.async {
                textView.resignFirstResponder()
            }
        }
    }
}
#endif
