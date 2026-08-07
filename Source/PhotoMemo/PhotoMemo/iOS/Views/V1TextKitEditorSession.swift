#if os(iOS) && !PHOTOMEMO_SHARE_EXTENSION
import Foundation
import SwiftUI
import UIKit

@MainActor
final class V1TextKitCommandBus {
    var insertHandler: ((V1ContentItem) -> Void)?
    var prefersTrailingInsertion = false
    private(set) var commandRevision = 0

    func insert(_ item: V1ContentItem) {
        commandRevision += 1
        V1TextKitTrace.log("commandBus.insert", extra: "revision=\(commandRevision) item=\(item.kind)")
        insertHandler?(item)
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
        // Keep the fixed editor row and attachment line fragment in the same
        // vertical measure; larger insets make the row re-layout when focus
        // or an attachment changes.
        textView.textContainerInset = UIEdgeInsets(top: 6, left: 4, bottom: 6, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 28
        paragraphStyle.maximumLineHeight = 28
        textView.typingAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraphStyle
        ]
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.accessibilityLabel = "\(region.displayTitle)内容"
        attachedTextView = textView
        V1TextKitTrace.log("attach", extra: stateDescription(for: textView))
        applyDraft(draft, to: textView, selection: selectedRange)
    }

    func setDraftFromOutside(_ nextDraft: V1EditorDraft, in textView: UITextView) {
        guard !hasSameEditingContent(draft, nextDraft),
              textView.markedTextRange == nil else { return }

        // The projection callback can arrive immediately after a TextKit edit.
        // Keep the live UIKit caret when rebuilding the attributed storage; the
        // session snapshot may still contain the pre-edit range and would
        // otherwise restore the caret to the beginning of the document.
        let liveSelection = textView.selectedRange
        selectionOwner = .swiftUIUpdate
        V1TextKitTrace.log("setDraftFromOutside", extra: stateDescription(for: textView))
        draft = nextDraft
        draftRevision += 1
        applyDraft(nextDraft, to: textView, selection: liveSelection)
    }

    func insert(_ item: V1ContentItem, in textView: UITextView) {
        ensureTrailingSentinel(in: textView)
        // UITextView is the selection source of truth at the command boundary.
        // SwiftUI may redraw between the user's caret movement and module tap,
        // while the delegate-backed snapshot can still contain an older range.
        selectedRange = textView.selectedRange
        let validRange = NSRange(
            location: 0,
            length: max(textView.textStorage.length - 1, 0)
        )
        let insertionLocation = min(
            max(selectedRange.location, validRange.location),
            validRange.location + validRange.length
        )
        let range = NSRange(location: insertionLocation, length: 0)
        let attachment = V1TextKitModuleAttachment(item: item)

        selectionOwner = .commandBus
        V1TextKitTrace.log(
            "insert.begin",
            extra: "range=\(NSStringFromRange(range)) draftRevision=\(draftRevision) " + stateDescription(for: textView)
        )

        isApplyingExternalState = true
        textView.textStorage.replaceCharacters(
            in: range,
            with: NSAttributedString(attachment: attachment)
        )
        selectedRange = NSRange(location: range.location + 1, length: 0)
        textView.selectedRange = selectedRange
        draft = projectedDraft(from: textView)
        draftRevision += 1
        V1TextKitTrace.log(
            "insert.end",
            extra: "draftRevision=\(draftRevision) " + stateDescription(for: textView) + " projected=\(draft.items.map { String(describing: $0.kind) })"
        )
        isApplyingExternalState = false
        emitDraftChangeIfNeeded()
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
        guard documentLength > 0,
              textView.textStorage.attribute(.attachment, at: documentLength - 1, effectiveRange: nil) != nil else {
            return false
        }

        isApplyingExternalState = true
        textView.textStorage.deleteCharacters(in: NSRange(location: documentLength - 1, length: 1))
        let newLength = max(textView.textStorage.length - 1, 0)
        selectedRange = NSRange(location: newLength, length: 0)
        textView.selectedRange = selectedRange
        draft = projectedDraft(from: textView)
        draftRevision += 1
        isApplyingExternalState = false
        emitDraftChangeIfNeeded()
        V1TextKitTrace.log("deleteTrailingAttachment", extra: stateDescription(for: textView))
        let restoredLength = newLength
        DispatchQueue.main.async { [weak self, weak textView] in
            guard let self, let textView, textView.window != nil else { return }
            let currentLength = max(textView.textStorage.length - 1, 0)
            guard currentLength == restoredLength else { return }
            self.selectionOwner = .projectionRestore
            self.selectedRange = NSRange(location: currentLength, length: 0)
            textView.selectedRange = self.selectedRange
            V1TextKitTrace.log("restoreCaretAfterDelete.layout", extra: self.stateDescription(for: textView))
        }
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        selectedRange = textView.selectedRange
        V1TextKitTrace.log("selectionChanged", extra: stateDescription(for: textView) + " owner=\(selectionOwner.rawValue)")
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        onFocus()
    }

    func textViewDidChange(_ textView: UITextView) {
        guard !isApplyingExternalState,
              textView.markedTextRange == nil else { return }

        ensureTrailingSentinel(in: textView)
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
        let result = NSMutableAttributedString()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline),
            .foregroundColor: UIColor.label,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.minimumLineHeight = 28
                style.maximumLineHeight = 28
                return style
            }()
        ]

        for item in draft.items {
            if item.kind == .text {
                result.append(NSAttributedString(string: item.value, attributes: attributes))
            } else {
                result.append(
                    NSAttributedString(
                        attachment: V1TextKitModuleAttachment(item: item)
                    )
                )
            }
        }

        result.append(
            NSAttributedString(
                string: "\u{200B}",
                attributes: [Self.trailingPositionAttribute: true]
            )
        )

        textView.textStorage.setAttributedString(result)
        textStorageRevision += 1
        selectedRange = NSRange(
            location: min(selection.location, result.length),
            length: 0
        )
        textView.selectedRange = selectedRange
        selectionOwner = .projectionRestore
        V1TextKitTrace.log("applyDraft", extra: "textStorageRevision=\(textStorageRevision) " + stateDescription(for: textView))
        isApplyingExternalState = false
    }

    private func projectedDraft(from textView: UITextView) -> V1EditorDraft {
        var items: [V1ContentItem] = []
        let range = NSRange(location: 0, length: textView.textStorage.length)

        textView.textStorage.enumerateAttributes(in: range) { attributes, subrange, _ in
            if attributes[Self.trailingPositionAttribute] != nil {
                return
            }
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

        return V1EditorDraft(items: items.isEmpty ? [.text("")] : items)
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
                attributes: [Self.trailingPositionAttribute: true]
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
    let draft: V1EditorDraft
    let commandBus: V1TextKitCommandBus
    let onFocus: () -> Void
    let onDraftChange: (V1EditorDraft) -> Void

    @State private var session: V1TextKitEditorSession

    init(
        region: CardRegion,
        draft: V1EditorDraft,
        commandBus: V1TextKitCommandBus,
        onFocus: @escaping () -> Void,
        onDraftChange: @escaping (V1EditorDraft) -> Void
    ) {
        self.region = region
        self.draft = draft
        self.commandBus = commandBus
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
        VStack(alignment: .leading, spacing: 6) {
            Text(region.editorTitle)
                .font(.headline.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            if let subtitle = region.editorSubtitle {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }

            V1SlotATextKitSessionRepresentable(
                session: session,
                region: region,
                draft: draft,
                commandBus: commandBus,
                onFocus: onFocus
            )
            .frame(minHeight: 42, maxHeight: 42)
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
                .stroke(Color.primary.opacity(0.06))
            )
        }
        // Match the single-field editor's inner visual measure while keeping
        // the TextKit row's full-width hit target inside this inset.
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding + 4)
        .padding(.vertical, 8)
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
        commandBus.insertHandler = { [weak session, weak view] item in
            guard let session, let view else { return }
            if commandBus.prefersTrailingInsertion {
                session.selectTrailingPosition(in: view)
                commandBus.prefersTrailingInsertion = false
            }
            session.insert(item, in: view)
        }
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        V1TextKitTrace.log("updateUIView", extra: "session=\(ObjectIdentifier(session)) textView=\(ObjectIdentifier(view)) range=\(NSStringFromRange(view.selectedRange))")
        commandBus.insertHandler = { [weak session, weak view] item in
            guard let session, let view else { return }
            if commandBus.prefersTrailingInsertion {
                session.selectTrailingPosition(in: view)
                commandBus.prefersTrailingInsertion = false
            }
            session.insert(item, in: view)
        }
        session.setDraftFromOutside(draft, in: view)
    }
}

private final class V1TextKitTextView: UITextView {
    var onTrailingTouch: ((UITextView, CGPoint) -> Void)?
    var onDeleteBackward: ((UITextView) -> Bool)?

    override func deleteBackward() {
        if onDeleteBackward?(self) == true {
            return
        }
        super.deleteBackward()
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
