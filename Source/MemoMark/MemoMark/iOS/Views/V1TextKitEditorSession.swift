#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import Foundation
import SwiftUI
import UIKit

@MainActor
final class V1TextKitCommandBus {
    var insertHandler: ((V1ContentItem) -> Void)?
    var focusHandler: (() -> Void)?
    var prefersTrailingInsertion = false
    private(set) var commandRevision = 0

    func insert(_ item: V1ContentItem) {
        commandRevision += 1
        V1TextKitTrace.log("commandBus.insert", extra: "revision=\(commandRevision) item=\(item.kind)")
        insertHandler?(item)
    }

    func requestFocus() {
        V1TextKitTrace.log("commandBus.requestFocus")
        focusHandler?()
    }
}

private enum V1TextKitSelectionOwner: String {
    case uikit
    case userTouch
    case swiftUIUpdate
    case commandBus
    case projectionRestore
}

private enum V1TextKitTrace {
    static func log(_ event: String, extra: String = "") {
        #if DEBUG
        print("[TextKitSlotA] event=\(event) \(extra)")
        #endif
    }
}

private enum V1EditorPasteboard {
    static let structuredType = "com.serydoo.MemoMark.editor-content"
    static let legacyStructuredType = "com.serydoo.PhotoMemo.editor-content"
    static let plainTextType = "public.utf8-plain-text"
}

private struct V1TextKitUndoSnapshot {
    let attributedString: NSAttributedString
    let selectedRange: NSRange
}

/// Shared visual metrics for the compact card-content editor.
///
/// The editor keeps a 48pt effective touch area through the row padding,
/// while the visible field is intentionally a little shorter. Keeping these
/// values together prevents the caret, TextKit line fragment, and SwiftUI
/// shell from drifting apart as new presentation styles add their own regions.
enum V1EditorInputMetrics {
    static let controlHeight: CGFloat = 40
    static let rowVerticalPadding: CGFloat = 4
    static let titleColumnWidth: CGFloat = 60
    static let multiRegionTitleColumnWidth: CGFloat = 36
    static let titleInputSpacing: CGFloat = 4
    /// Keeps the insertion point from touching the rounded field border. This
    /// is the same leading/trailing rhythm used by the native message inputs
    /// we use as a visual reference, while the field remains a 40pt control.
    static let textContainerHorizontalInset: CGFloat = 8
    static let caretWidth: CGFloat = 2
    static let caretHeight: CGFloat = 16
    static let fallbackLineHeight: CGFloat = 22
    static let moduleAttachmentHeight: CGFloat = 28

    /// TextKit's shared line box is the vertical source of truth for both
    /// ordinary glyphs and module attachments whenever the editor rebuilds its
    /// attributed content from the current font metrics.
    static func lineHeight(for font: UIFont) -> CGFloat {
        max(moduleAttachmentHeight, ceil(font.lineHeight))
    }

    static func textBaselineOffset(for font: UIFont) -> CGFloat {
        V1EditorLineBoxGeometry.textBaselineOffset(
            lineHeight: lineHeight(for: font),
            fontLineHeight: font.lineHeight
        )
    }

    static func attachmentBaselineOffset(
        for font: UIFont,
        attachmentHeight: CGFloat
    ) -> CGFloat {
        // Keep the attachment canvas inside the same canonical line box as
        // ordinary glyphs. A cap-height offset contributes a different
        // descent and lets TextKit move the entire line baseline whenever the
        // last module is inserted or removed.
        V1EditorLineBoxGeometry.attachmentOriginY(
            lineHeight: lineHeight(for: font),
            attachmentHeight: attachmentHeight,
            fontDescender: font.descender
        )
    }
}

/// One capsule specification is shared by TextKit attachments and the
/// SwiftUI preview fallback, so the two editor surfaces never drift apart.
enum V1EditorCapsuleMetrics {
    static let height: CGFloat = 28
    static let cornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
    static let iconSize: CGFloat = 14
    static let iconLeading: CGFloat = 7
    static let titleLeading: CGFloat = 25
    static let titleAdvance: CGFloat = 34
    static let minimumWidth: CGFloat = 58
    static let maximumWidth: CGFloat = 150
    static let contentSpacing: CGFloat = 4
    /// One inter-item gap is shared by the legacy SwiftUI fallback and the
    /// TextKit attachment's transparent boundary advance.
    static let inlineItemSpacing: CGFloat = 2
    static let attachmentTrailingAdvance: CGFloat = 2

    /// The visible capsule must not be pushed away from preceding text by an
    /// extra glyph-origin offset. The attachment owns only its outgoing
    /// boundary; incoming text keeps its native side bearing.
    static let attachmentLeadingAdvance: CGFloat = 0
}

/// Owns the lifetime of one unified TextKit editor. SwiftUI sends only
/// durable draft snapshots and user commands; it never drives one-shot
/// insertion through a Binding during `updateUIView`.
@MainActor
final class V1TextKitEditorSession: NSObject, UITextViewDelegate {
    private static let trailingPositionAttribute = NSAttributedString.Key(
        rawValue: "com.serydoo.PhotoMemo.textKitTrailingPosition"
    )
    private(set) var draft: V1EditorDraft
    let region: CardRegion
    private(set) var selectedRange = NSRange(location: 0, length: 0)
    private(set) var textStorageRevision = 0
    private(set) var draftRevision = 0
    private var selectionOwner: V1TextKitSelectionOwner = .uikit
    private var shouldRestoreTrailingCaretAfterDelete = false

    private(set) var isApplyingExternalState = false
    private var hasEmittedCurrentEdit = false

    let onDraftChange: (V1EditorDraft) -> Void
    let onFocus: () -> Void
    private weak var attachedTextView: UITextView?

    init(
        draft: V1EditorDraft,
        region: CardRegion,
        onDraftChange: @escaping (V1EditorDraft) -> Void,
        onFocus: @escaping () -> Void = {}
    ) {
        self.draft = draft
        self.region = region
        self.onDraftChange = onDraftChange
        self.onFocus = onFocus
        super.init()
    }

    func attach(to textView: UITextView) {
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .subheadline)
        textView.adjustsFontForContentSizeCategory = true
        // The TextKit view calculates its vertical inset after SwiftUI gives
        // it a real height. This centers the empty caret using the natural
        // font line height while still making room for module attachments.
        textView.textContainerInset = UIEdgeInsets(
            top: 0,
            left: V1EditorInputMetrics.textContainerHorizontalInset,
            bottom: 0,
            right: V1EditorInputMetrics.textContainerHorizontalInset
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineBreakMode = .byClipping
        textView.typingAttributes = editingAttributes()
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isScrollEnabled = true
        textView.accessibilityLabel =
            region.localizedEditorAccessibilityLabel
        textView.accessibilityHint =
            region.localizedEditorAccessibilityHint
        attachedTextView = textView
        V1TextKitTrace.log("attach", extra: stateDescription(for: textView))
        applyDraft(draft, to: textView, selection: selectedRange)
    }

    func setDraftFromOutside(_ nextDraft: V1EditorDraft, in textView: UITextView) {
        guard !hasSameEditingContent(draft, nextDraft),
              textView.markedTextRange == nil else { return }

        // The projection callback can arrive immediately after a TextKit edit.
        // Keep the live UIKit caret while editing. Once the module surface is
        // opened, the text view may resign first responder and UIKit can
        // report a reset range during the following SwiftUI update. The
        // session's last delegate-backed selection is the stable fallback.
        let liveSelection = textView.isFirstResponder
            ? textView.selectedRange
            : selectedRange
        selectionOwner = .swiftUIUpdate
        V1TextKitTrace.log("setDraftFromOutside", extra: stateDescription(for: textView))
        draft = nextDraft
        draftRevision += 1
        applyDraft(nextDraft, to: textView, selection: liveSelection)
    }

    func insert(_ item: V1ContentItem, in textView: UITextView) {
        ensureTrailingSentinel(in: textView)
        // UITextView is the selection source of truth while it is active. After
        // the module surface dismisses the keyboard, UIKit can expose a reset
        // range even though the session still owns the user's last caret.
        // Prefer that stable session range while the view is not first
        // responder, so insertion remains at the intended position.
        let commandSelection = textView.isFirstResponder
            ? textView.selectedRange
            : selectedRange
        selectedRange = commandSelection
        let validRange = NSRange(
            location: 0,
            length: max(textView.textStorage.length - 1, 0)
        )
        let insertionLocation = min(
            max(selectedRange.location, validRange.location),
            validRange.location + validRange.length
        )
        let range = NSRange(location: insertionLocation, length: 0)
        let attachment = attributedAttachment(for: item)

        selectionOwner = .commandBus
        registerUndoSnapshot(
            for: textView,
            actionName: "插入模块"
        )
        V1TextKitTrace.log(
            "insert.begin",
            extra: "range=\(NSStringFromRange(range)) draftRevision=\(draftRevision) " + stateDescription(for: textView)
        )

        isApplyingExternalState = true
        textView.textStorage.replaceCharacters(
            in: range,
            with: attachment
        )
        refreshTextViewLayout(textView)
        selectedRange = NSRange(location: range.location + 1, length: 0)
        textView.selectedRange = selectedRange
        draft = projectedDraft(from: textView)
        draftRevision += 1
        // Rebuild the complete attributed draft immediately so the inserted
        // attachment and all existing runs use the canonical line-box and
        // canvas metrics in the same update, without waiting for SwiftUI's
        // next update cycle.
        applyDraft(draft, to: textView, selection: selectedRange)
        V1TextKitTrace.log(
            "insert.end",
            extra: "draftRevision=\(draftRevision) " + stateDescription(for: textView) + " projected=\(draft.items.map { String(describing: $0.kind) })"
        )
        isApplyingExternalState = false
        emitDraftChangeIfNeeded()
    }

    func copySelection(in textView: UITextView) -> Bool {
        let selection = clampedUserSelection(
            textView.selectedRange,
            in: textView
        )
        guard selection.length > 0 else {
            return false
        }

        let items = projectedItems(
            from: textView,
            in: selection
        )
        guard !items.isEmpty,
              let data = V1EditorClipboardCodec.encode(
                V1EditorClipboardPayload(items: items)
              ) else {
            return false
        }

        let plainText = V1EditorClipboardPayload(items: items).displayText
        UIPasteboard.general.setItems(
            [[
                V1EditorPasteboard.structuredType: data,
                V1EditorPasteboard.legacyStructuredType: data,
                V1EditorPasteboard.plainTextType: plainText
            ]],
            options: [.localOnly: true]
        )
        return true
    }

    func pasteStructuredContent(in textView: UITextView) -> Bool {
        guard let data = structuredPasteboardData(),
        let payload = V1EditorClipboardCodec.decode(data),
        !payload.items.isEmpty else {
            return false
        }

        ensureTrailingSentinel(in: textView)
        let selection = clampedUserSelection(
            textView.selectedRange,
            in: textView
        )
        let pastedItems = payload.items.map(\.copyingForInsertion)
        let attributed = attributedString(for: pastedItems)

        selectionOwner = .commandBus
        registerUndoSnapshot(
            for: textView,
            actionName: "粘贴内容"
        )
        isApplyingExternalState = true
        textView.textStorage.replaceCharacters(
            in: selection,
            with: attributed
        )
        refreshTextViewLayout(textView)

        selectedRange = NSRange(
            location: selection.location + attributed.length,
            length: 0
        )
        textView.selectedRange = selectedRange
        draft = projectedDraft(from: textView)
        draftRevision += 1
        applyDraft(draft, to: textView, selection: selectedRange)
        isApplyingExternalState = false
        emitDraftChangeIfNeeded()
        return true
    }

    func selectTrailingPosition(in textView: UITextView) {
        let documentLength = max(textView.textStorage.length - 1, 0)
        selectedRange = NSRange(location: documentLength, length: 0)
        textView.selectedRange = selectedRange
        selectionOwner = .userTouch
        V1TextKitTrace.log("selectTrailingPosition", extra: stateDescription(for: textView))
    }

    func prepareForDeleteBackward(in textView: UITextView) {
        let documentLength = max(textView.textStorage.length - 1, 0)
        guard textView.selectedRange.length == 0,
              textView.selectedRange.location > documentLength else {
            return
        }
        shouldRestoreTrailingCaretAfterDelete = true
        selectedRange = NSRange(location: documentLength, length: 0)
        textView.selectedRange = selectedRange
        V1TextKitTrace.log("prepareForDeleteBackward", extra: stateDescription(for: textView))
    }

    func deleteBackwardIfTrailingAttachment(in textView: UITextView) -> Bool {
        ensureTrailingSentinel(in: textView)
        let documentLength = max(textView.textStorage.length - 1, 0)
        let selection = textView.selectedRange
        guard selection.length == 0 else {
            return false
        }

        // The live UIKit selection is the only valid deletion anchor while
        // the editor is active. The trailing sentinel is outside the user
        // document, so clamp a transient UIKit position past it before
        // looking for an attachment immediately before the caret. The old
        // implementation always inspected documentLength - 1, which made a
        // backspace after custom text delete the rightmost module instead of
        // the character/module adjacent to the user's caret.
        let caretLocation = min(
            max(selection.location, 0),
            documentLength
        )
        guard caretLocation > 0 else {
            return false
        }
        let precedingLocation = caretLocation - 1
        guard textView.textStorage.attribute(
            .attachment,
            at: precedingLocation,
            effectiveRange: nil
        ) != nil else {
            return false
        }

        if selection.location != caretLocation {
            selectedRange = NSRange(location: caretLocation, length: 0)
            textView.selectedRange = selectedRange
        }

        registerUndoSnapshot(
            for: textView,
            actionName: "删除模块"
        )
        isApplyingExternalState = true
        textView.textStorage.deleteCharacters(
            in: NSRange(location: precedingLocation, length: 1)
        )
        refreshTextViewLayout(textView)
        selectedRange = NSRange(location: precedingLocation, length: 0)
        textView.selectedRange = selectedRange
        draft = projectedDraft(from: textView)
        draftRevision += 1
        // Rebuild the complete attributed draft immediately so surviving runs
        // retain the canonical line-box and canvas metrics after deletion.
        applyDraft(draft, to: textView, selection: selectedRange)
        isApplyingExternalState = false
        emitDraftChangeIfNeeded()
        V1TextKitTrace.log("deleteAttachmentAtCaret", extra: stateDescription(for: textView))
        let restoredCaretLocation = precedingLocation
        DispatchQueue.main.async { [weak self, weak textView] in
            guard let self, let textView, textView.window != nil else { return }
            let currentLength = max(textView.textStorage.length - 1, 0)
            guard currentLength >= restoredCaretLocation else { return }
            self.selectionOwner = .projectionRestore
            self.selectedRange = NSRange(
                location: restoredCaretLocation,
                length: 0
            )
            textView.selectedRange = self.selectedRange
            V1TextKitTrace.log("restoreCaretAfterDelete.layout", extra: self.stateDescription(for: textView))
        }
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        selectedRange = textView.selectedRange
        // UIKit derives typing attributes from the run next to the insertion
        // point. At an attachment boundary that run is the module itself, so
        // text inserted immediately before a module can otherwise lose the
        // editor's font and canonical paragraph line box.
        refreshTypingAttributes(in: textView)
        V1TextKitTrace.log("selectionChanged", extra: stateDescription(for: textView) + " owner=\(selectionOwner.rawValue)")
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        onFocus()
    }

    func textViewDidChange(_ textView: UITextView) {
        guard !isApplyingExternalState,
              textView.markedTextRange == nil else { return }

        ensureTrailingSentinel(in: textView)
        // Normalize committed input before projecting the draft. This repairs
        // any plain-text run UIKit created from attachment-adjacent attributes
        // while leaving module attachments and the trailing sentinel intact.
        normalizeTextRunAttributes(in: textView)
        selectedRange = textView.selectedRange
        if shouldRestoreTrailingCaretAfterDelete {
            let documentLength = max(textView.textStorage.length - 1, 0)
            selectedRange = NSRange(location: documentLength, length: 0)
            textView.selectedRange = selectedRange
            shouldRestoreTrailingCaretAfterDelete = false
            V1TextKitTrace.log("restoreCaretAfterDelete", extra: stateDescription(for: textView))
            let restoredLength = selectedRange.location
            DispatchQueue.main.async { [weak self, weak textView] in
                guard let self, let textView else { return }
                guard textView.window != nil else { return }
                let currentLength = max(textView.textStorage.length - 1, 0)
                guard currentLength == restoredLength else { return }
                self.selectedRange = NSRange(location: currentLength, length: 0)
                textView.selectedRange = self.selectedRange
                V1TextKitTrace.log("restoreCaretAfterDelete.layout", extra: self.stateDescription(for: textView))
            }
        }
        draft = projectedDraft(from: textView)
        draftRevision += 1
        V1TextKitTrace.log("textViewDidChange", extra: "draftRevision=\(draftRevision) " + stateDescription(for: textView))
        emitDraftChangeIfNeeded()
    }

    private func emitDraftChangeIfNeeded() {
        guard !hasEmittedCurrentEdit else { return }
        hasEmittedCurrentEdit = true
        onDraftChange(draft)
        DispatchQueue.main.async { [weak self] in
            self?.hasEmittedCurrentEdit = false
        }
    }

    private func applyDraft(
        _ draft: V1EditorDraft,
        to textView: UITextView,
        selection: NSRange
    ) {
        isApplyingExternalState = true
        let result = NSMutableAttributedString(
            attributedString: attributedString(for: draft.items)
        )

        result.append(
            NSAttributedString(
                string: "\u{200B}",
                attributes: trailingSentinelAttributes()
            )
        )

        textView.textStorage.setAttributedString(result)
        refreshTextViewLayout(textView)
        textStorageRevision += 1
        selectedRange = NSRange(
            location: min(selection.location, result.length),
            length: 0
        )
        textView.selectedRange = selectedRange
        selectionOwner = .projectionRestore
        refreshTypingAttributes(in: textView)
        V1TextKitTrace.log("applyDraft", extra: "textStorageRevision=\(textStorageRevision) " + stateDescription(for: textView))
        isApplyingExternalState = false
    }

    private func normalizeTextRunAttributes(in textView: UITextView) {
        let documentLength = max(textView.textStorage.length - 1, 0)
        guard documentLength > 0 else {
            refreshTypingAttributes(in: textView)
            return
        }

        let documentRange = NSRange(location: 0, length: documentLength)
        let canonicalAttributes = editingAttributes()
        var textRanges: [NSRange] = []
        textView.textStorage.enumerateAttribute(
            .attachment,
            in: documentRange
        ) { value, range, _ in
            if value == nil {
                textRanges.append(range)
            }
        }

        guard !textRanges.isEmpty else {
            refreshTypingAttributes(in: textView)
            return
        }

        let wasApplyingExternalState = isApplyingExternalState
        isApplyingExternalState = true
        textView.textStorage.beginEditing()
        for range in textRanges {
            // Ordinary editor text has one owned attribute schema. Replacing
            // the complete run is intentional: merely merging the canonical
            // values can leave an inherited baselineOffset (or another rich-
            // text geometry attribute) behind after attachment-boundary
            // edits. That stale value disappears only after a full draft
            // rebuild, which is exactly the insert/delete jump this editor
            // must prevent.
            textView.textStorage.setAttributes(
                canonicalAttributes,
                range: range
            )
        }
        textView.textStorage.endEditing()
        isApplyingExternalState = wasApplyingExternalState
        refreshTypingAttributes(in: textView)
        refreshTextViewLayout(textView)
    }

    private func refreshTypingAttributes(in textView: UITextView) {
        guard textView.markedTextRange == nil else { return }
        textView.typingAttributes = editingAttributes()
    }

    private func projectedDraft(from textView: UITextView) -> V1EditorDraft {
        let items = projectedItems(from: textView)
        return V1EditorDraft(items: items.isEmpty ? [.text("")] : items)
    }

    private func projectedItems(
        from textView: UITextView,
        in requestedRange: NSRange? = nil
    ) -> [V1ContentItem] {
        var items: [V1ContentItem] = []
        let range = requestedRange.map {
            clampedUserSelection($0, in: textView)
        } ?? NSRange(
            location: 0,
            length: max(textView.textStorage.length - 1, 0)
        )

        guard range.length > 0 else {
            return items
        }

        textView.textStorage.enumerateAttributes(in: range) { attributes, subrange, _ in
            if let attachment = attributes[.attachment] as? V1TextKitModuleAttachment {
                items.append(attachment.item)
                return
            }

            let value = (textView.textStorage.string as NSString).substring(with: subrange)
            guard !value.isEmpty else { return }
            if let index = items.indices.last, items[index].kind == .text {
                items[index].value += value
                items[index].savedValue += value
            } else {
                items.append(.text(value))
            }
        }

        return items
    }

    private func attributedString(
        for items: [V1ContentItem]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let attributes = editingAttributes()

        for item in items {
            if item.kind == .text {
                result.append(
                    NSAttributedString(
                        string: item.value,
                        attributes: attributes
                    )
                )
            } else {
                result.append(attributedAttachment(for: item))
            }
        }

        return result
    }

    private func attributedAttachment(
        for item: V1ContentItem
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(
            attachment: V1TextKitModuleAttachment(
                item: item,
                leadingAdvance: V1EditorCapsuleMetrics.attachmentLeadingAdvance,
                trailingAdvance: V1EditorCapsuleMetrics.attachmentTrailingAdvance
            )
        )
        // Paragraph style is a paragraph-wide contract. The attachment gets
        // the canonical line box, but deliberately not the ordinary text's
        // positive baselineOffset: its 28pt canvas is already centered by its
        // bounds origin and must not be lifted a second time.
        result.addAttributes(
            attachmentAttributes(),
            range: NSRange(location: 0, length: result.length)
        )
        return result
    }

    private func structuredPasteboardData() -> Data? {
        UIPasteboard.general.data(
            forPasteboardType: V1EditorPasteboard.structuredType
        ) ?? UIPasteboard.general.data(
            forPasteboardType: V1EditorPasteboard.legacyStructuredType
        )
    }

    private func registerUndoSnapshot(
        for textView: UITextView,
        actionName: String
    ) {
        guard let undoManager = textView.undoManager else { return }
        let snapshot = V1TextKitUndoSnapshot(
            attributedString: textView.textStorage.copy() as? NSAttributedString
                ?? NSAttributedString(),
            selectedRange: textView.selectedRange
        )
        undoManager.registerUndo(withTarget: self) { [weak textView] session in
            guard let textView else { return }
            session.restoreUndoSnapshot(snapshot, in: textView)
        }
        undoManager.setActionName(actionName)
    }

    private func restoreUndoSnapshot(
        _ snapshot: V1TextKitUndoSnapshot,
        in textView: UITextView
    ) {
        // Register the inverse before restoring, so the same action supports
        // redo without inventing a second content representation.
        registerUndoSnapshot(
            for: textView,
            actionName: "编辑内容"
        )
        isApplyingExternalState = true
        textView.textStorage.setAttributedString(snapshot.attributedString)
        refreshTextViewLayout(textView)
        let location = min(
            max(snapshot.selectedRange.location, 0),
            textView.textStorage.length
        )
        let length = min(
            max(snapshot.selectedRange.length, 0),
            max(textView.textStorage.length - location, 0)
        )
        selectedRange = NSRange(location: location, length: length)
        textView.selectedRange = selectedRange
        draft = projectedDraft(from: textView)
        draftRevision += 1
        isApplyingExternalState = false
        emitDraftChangeIfNeeded()
    }

    private func clampedUserSelection(
        _ selection: NSRange,
        in textView: UITextView
    ) -> NSRange {
        let documentLength = max(textView.textStorage.length - 1, 0)
        let start = min(
            max(selection.location, 0),
            documentLength
        )
        let end = min(
            max(NSMaxRange(selection), start),
            documentLength
        )
        return NSRange(
            location: start,
            length: max(end - start, 0)
        )
    }

    private func ensureTrailingSentinel(in textView: UITextView) {
        let lastLocation = textView.textStorage.length - 1
        if lastLocation >= 0,
           textView.textStorage.attribute(
               Self.trailingPositionAttribute,
               at: lastLocation,
               effectiveRange: nil
           ) != nil {
            return
        }

        let currentSelection = textView.selectedRange
        isApplyingExternalState = true
        textView.textStorage.append(
            NSAttributedString(
                string: "\u{200B}",
                attributes: trailingSentinelAttributes()
            )
        )
        textView.selectedRange = currentSelection
        isApplyingExternalState = false
        textStorageRevision += 1
        V1TextKitTrace.log(
            "restoreTrailingSentinel",
            extra: stateDescription(for: textView)
        )
    }

    private func editingAttributes() -> [NSAttributedString.Key: Any] {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        var attributes = lineBoxAttributes(for: font)
        attributes[.baselineOffset] =
            V1EditorInputMetrics.textBaselineOffset(for: font)
        return attributes
    }

    private func attachmentAttributes() -> [NSAttributedString.Key: Any] {
        lineBoxAttributes(
            for: UIFont.preferredFont(forTextStyle: .subheadline)
        )
    }

    private func lineBoxAttributes(
        for font: UIFont
    ) -> [NSAttributedString.Key: Any] {
        let lineHeight = V1EditorInputMetrics.lineHeight(for: font)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        return [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
    }

    private func trailingSentinelAttributes() -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [
            Self.trailingPositionAttribute: true
        ]
        attributes.merge(editingAttributes()) { current, _ in current }
        return attributes
    }

    private func refreshTextViewLayout(_ textView: UITextView) {
        guard let textView = textView as? V1TextKitTextView else { return }
        textView.updateVerticalTextAlignment()
    }

    private func stateDescription(for textView: UITextView) -> String {
        let caret = textView.caretRect(for: textView.selectedTextRange?.end ?? textView.endOfDocument)
        return "session=\(ObjectIdentifier(self)) textView=\(ObjectIdentifier(textView)) " +
        "range=\(NSStringFromRange(textView.selectedRange)) storageRevision=\(textStorageRevision) " +
        "storageLength=\(textView.textStorage.length) contentOffset=\(textView.contentOffset) " +
        "caret=\(caret) usedRect=\(textView.layoutManager.usedRect(for: textView.textContainer)) " +
        "storage=\(textView.textStorage.string.debugDescription)"
    }

    private func hasSameEditingContent(
        _ lhs: V1EditorDraft,
        _ rhs: V1EditorDraft
    ) -> Bool {
        guard lhs.items.count == rhs.items.count else { return false }
        return zip(lhs.items, rhs.items).allSatisfy { left, right in
            left.kind == right.kind
                && left.value == right.value
                && left.savedValue == right.savedValue
                && left.title == right.title
                && left.systemImage == right.systemImage
        }
    }
}

struct V1TextKitSessionEditor: View {
    let region: CardRegion
    let title: String?
    let titleColumnWidth: CGFloat
    let draft: V1EditorDraft
    let commandBus: V1TextKitCommandBus
    let isFocused: Bool
    let onFocus: () -> Void
    let onDraftChange: (V1EditorDraft) -> Void

    @State private var session: V1TextKitEditorSession

    init(
        region: CardRegion,
        title: String? = nil,
        titleColumnWidth: CGFloat = V1EditorInputMetrics.titleColumnWidth,
        draft: V1EditorDraft,
        commandBus: V1TextKitCommandBus,
        isFocused: Bool,
        onFocus: @escaping () -> Void,
        onDraftChange: @escaping (V1EditorDraft) -> Void
    ) {
        self.region = region
        self.title = title
        self.titleColumnWidth = titleColumnWidth
        self.draft = draft
        self.commandBus = commandBus
        self.isFocused = isFocused
        self.onFocus = onFocus
        self.onDraftChange = onDraftChange
        _session = State(
            initialValue: V1TextKitEditorSession(
                draft: draft,
                region: region,
                onDraftChange: onDraftChange
                , onFocus: onFocus
            )
        )
    }

    var body: some View {
        HStack(
            alignment: .center,
            spacing: V1EditorInputMetrics.titleInputSpacing
        ) {
            Text(title ?? region.displayTitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(
                    width: titleColumnWidth,
                    alignment: .leading
                )
                .accessibilityAddTraits(.isHeader)

            V1SlotATextKitSessionRepresentable(
                session: session,
                region: region,
                draft: draft,
                commandBus: commandBus,
                onFocus: onFocus
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: V1EditorInputMetrics.controlHeight)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: ConfigurationUI.smallCornerRadius,
                    style: .continuous
                )
                .stroke(
                    isFocused ? Color.accentColor.opacity(0.42) : Color.primary.opacity(0.06),
                    lineWidth: isFocused ? 1.2 : 1
                )
            )
        }
        .padding(.horizontal, 4)
        .padding(.vertical, V1EditorInputMetrics.rowVerticalPadding)
    }
}

typealias V1SlotATextKitSessionEditor = V1TextKitSessionEditor

private struct V1SlotATextKitSessionRepresentable: UIViewRepresentable {
    let session: V1TextKitEditorSession
    let region: CardRegion
    let draft: V1EditorDraft
    let commandBus: V1TextKitCommandBus
    let onFocus: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let view = V1TextKitTextView()
        let bus = commandBus
        view.onTrailingTouch = { [weak session] textView, point in
            let shouldUseTrailing = session?.moveCaretToEndIfNeeded(
                in: textView,
                point: point
            ) ?? false
            if shouldUseTrailing {
                commandBus.prefersTrailingInsertion = true
            }
        }
        view.onDeleteBackward = { [weak session] textView in
            guard let session else { return false }
            if session.deleteBackwardIfTrailingAttachment(in: textView) {
                return true
            }
            session.prepareForDeleteBackward(in: textView)
            return false
        }
        session.attach(to: view)
        view.onCopy = { [weak session] textView in
            session?.copySelection(in: textView) ?? false
        }
        view.onPaste = { [weak session] textView in
            session?.pasteStructuredContent(in: textView) ?? false
        }
        bus.insertHandler = { [weak bus, weak session, weak view] item in
            guard let bus, let session, let view else { return }
            if bus.prefersTrailingInsertion {
                session.selectTrailingPosition(in: view)
                bus.prefersTrailingInsertion = false
            }
            session.insert(item, in: view)
        }
        commandBus.focusHandler = { [weak view] in
            guard let view else { return }
            DispatchQueue.main.async {
                guard view.window != nil else { return }
                _ = view.becomeFirstResponder()
            }
        }
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        V1TextKitTrace.log("updateUIView", extra: "session=\(ObjectIdentifier(session)) textView=\(ObjectIdentifier(view)) range=\(NSStringFromRange(view.selectedRange))")
        let bus = commandBus
        bus.insertHandler = { [weak bus, weak session, weak view] item in
            guard let bus, let session, let view else { return }
            if bus.prefersTrailingInsertion {
                session.selectTrailingPosition(in: view)
                bus.prefersTrailingInsertion = false
            }
            session.insert(item, in: view)
        }
        commandBus.focusHandler = { [weak view] in
            guard let view else { return }
            DispatchQueue.main.async {
                guard view.window != nil else { return }
                _ = view.becomeFirstResponder()
            }
        }
        session.setDraftFromOutside(draft, in: view)
    }
}

private final class V1TextKitTextView: UITextView {
    var onTrailingTouch: ((UITextView, CGPoint) -> Void)?
    var onDeleteBackward: ((UITextView) -> Bool)?
    var onCopy: ((UITextView) -> Bool)?
    var onPaste: ((UITextView) -> Bool)?

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        tintColor = .tintColor
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        tintColor = .tintColor
    }

    override func copy(_ sender: Any?) {
        if onCopy?(self) == true {
            return
        }
        super.copy(sender)
    }

    override func paste(_ sender: Any?) {
        if onPaste?(self) == true {
            return
        }
        super.paste(sender)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateVerticalTextAlignment()
    }

    /// UITextView has no native vertical-alignment mode. Recalculate only the
    /// vertical text-container inset so the empty caret is centered without
    /// changing horizontal text metrics or the user's selection.
    func updateVerticalTextAlignment() {
        guard bounds.height > 0 else { return }

        let fontLineHeight = ceil(
            font?.lineHeight ?? V1EditorInputMetrics.fallbackLineHeight
        )
        // Text and attachment runs share one line box. Recomputing the line
        // height from the current contents made the caret jump vertically as
        // the user moved between plain text and module capsules. The capsule
        // is the lower bound, so keep that same canonical box for every draft;
        // ordinary glyphs are centered inside it by their own baselineOffset.
        let lineHeight = max(
            V1EditorInputMetrics.moduleAttachmentHeight,
            fontLineHeight
        )
        let verticalInset = max(0, floor((bounds.height - lineHeight) / 2))
        let current = textContainerInset
        guard abs(current.top - verticalInset) > 0.5
                || abs(current.bottom - verticalInset) > 0.5 else {
            return
        }
        textContainerInset = UIEdgeInsets(
            top: verticalInset,
            left: current.left,
            bottom: verticalInset,
            right: current.right
        )
    }

    /// UIKit's default caret uses the line fragment supplied by the current
    /// run. Attachment baselines and ordinary text baselines are not
    /// interchangeable, so using that fragment's y-position makes the caret
    /// move when the content changes. This is a deliberately single-line
    /// editor: keep UIKit's x-position and width, but use the stable visual
    /// center of the input surface for every content kind.
    override func caretRect(for position: UITextPosition) -> CGRect {
        let systemRect = super.caretRect(for: position)
        guard bounds.height > 0 else {
            return systemRect
        }

        // The system rect can have different heights for ordinary glyphs and
        // attachments. Use one deliberately shorter caret for every content
        // kind; only the system x-position remains content-dependent.
        let caretWidth = V1EditorInputMetrics.caretWidth
        let caretHeight = V1EditorInputMetrics.caretHeight
        let editorCenterY = bounds.midY
        return CGRect(
            x: systemRect.minX,
            y: editorCenterY - caretHeight / 2,
            width: max(systemRect.width, caretWidth),
            height: caretHeight
        )
    }

    override func deleteBackward() {
        if onDeleteBackward?(self) == true {
            return
        }
        super.deleteBackward()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // An empty draft contains only the private trailing sentinel. UIKit
        // does not consistently promote that otherwise blank surface to the
        // first responder when it is embedded in the editor ScrollView, so
        // make the native input contract explicit before handling the touch.
        _ = becomeFirstResponder()
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onTrailingTouch?(self, point)
        }
    }
}

private extension V1TextKitEditorSession {
    func moveCaretToEndIfNeeded(in textView: UITextView, point: CGPoint) -> Bool {
        let documentLength = max(textView.textStorage.length - 1, 0)
        let endPosition = textView.position(
            from: textView.beginningOfDocument,
            offset: documentLength
        )
        let contentRight = endPosition.map {
            textView.caretRect(for: $0).maxX
        } ?? textView.textContainerInset.left
        // The blank area begins at the measured content boundary. Using an
        // additional pixel buffer can leave a tap immediately after the last
        // glyph mapped by UIKit to the preceding character.
        let isInRightTrailingZone = point.x >= contentRight
        V1TextKitTrace.log(
            "touchEnded",
            extra: "point=\(point) contentRight=\(contentRight) documentLength=\(documentLength) trailing=\(isInRightTrailingZone) " + stateDescription(for: textView)
        )
        guard isInRightTrailingZone else {
            guard let position = textView.closestPosition(to: point) else { return false }
            let offset = textView.offset(from: textView.beginningOfDocument, to: position)
            guard offset >= documentLength else { return false }
            selectedRange = NSRange(location: documentLength, length: 0)
            textView.selectedRange = selectedRange
            return true
        }
        selectedRange = NSRange(location: documentLength, length: 0)
        textView.selectedRange = selectedRange
        return true
    }
}
#endif
