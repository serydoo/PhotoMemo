#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI
import UIKit

struct MemoryCardRegionEditorCard: View {

    let region: CardRegion
    let showsDivider: Bool
    let draft: MemoryCardEditorDraft
    let onFocus: () -> Void
    let onFocusTextItem: (MemoryCardContentItem) -> Void
    let onFocusTrailingText: () -> Void
    let onUpdateTextItem: (MemoryCardContentItem, String) -> Void
    let onPrependText: (String) -> Void
    let onAppendText: (String) -> Void
    let onRemoveItem: (MemoryCardContentItem) -> Void
    let onRemovePreviousComposedItem: (UUID) -> Bool
    let insertionMarkerID: UUID?
    let showsInsertionMarkerAtEnd: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(region.editorTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle = region.editorSubtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }

            compositionField
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
        .padding(.vertical, 5)
        .overlay(alignment: .bottom) {
            if showsDivider {
                HorizontalDivider()
                    .padding(.horizontal, ConfigurationUI.sheetPanelPadding)
            }
        }
    }

    private var compositionField: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MemoryCardEditorCapsuleMetrics.inlineItemSpacing) {
                ForEach(draft.items) { item in
                    if item.id == insertionMarkerID,
                       insertionAnchorBelongsBefore(item) {
                        insertionAnchor
                    }

                    switch item.kind {
                    case .text:
                        editableTextField(item)

                    case .token,
                         .separator,
                         .lineBreak:
                        moduleChip(item)
                    }

                    if item.id == insertionMarkerID,
                       !insertionAnchorBelongsBefore(item) {
                        insertionAnchor
                    }
                }

                if draft.items.last?.kind != .text {
                    if showsInsertionMarkerAtEnd {
                        insertionAnchor
                    }
                    transientTextField(
                        placeholder: "",
                        minWidth: 58,
                        onChange: onAppendText,
                        onFocus: onFocusTrailingText
                    )
                }
            }
            .padding(.horizontal, MemoryCardEditorInputMetrics.textContainerHorizontalInset)
            .padding(.vertical, 4)
        }
        .frame(minHeight: 42)
        .contentShape(Rectangle())
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                onFocus()
            }
        )
        .background(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .fill(Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: ConfigurationUI.smallCornerRadius,
                style: .continuous
            )
            .stroke(Color.primary.opacity(0.08))
        )
    }

    private func moduleChip(
        _ item: MemoryCardContentItem
    ) -> some View {
        HStack(spacing: MemoryCardEditorCapsuleMetrics.contentSpacing) {
            Image(systemName: item.editorModuleSystemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            Text(item.editorModuleTitle)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .font(.footnote.weight(.semibold))
        .padding(.horizontal, 6)
        .frame(height: MemoryCardEditorCapsuleMetrics.height)
        .background(
            RoundedRectangle(
                cornerRadius: MemoryCardEditorCapsuleMetrics.cornerRadius,
                style: .continuous
            )
            .fill(
                Color(
                    uiColor: item.isUnresolvedModule
                        ? .systemOrange
                        : .systemBlue
                )
                .opacity(0.12)
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: MemoryCardEditorCapsuleMetrics.cornerRadius,
                style: .continuous
            )
            .stroke(
                (item.isUnresolvedModule
                    ? Color.orange
                    : Color.accentColor
                )
                .opacity(0.22),
                lineWidth: MemoryCardEditorCapsuleMetrics.borderWidth
            )
        )
    }

    private var insertionAnchor: some View {
        Capsule(style: .continuous)
            .fill(Color.primary.opacity(0.42))
            .frame(width: 2, height: 20)
            .padding(.horizontal, 2)
            .accessibilityLabel("模块插入位置")
    }

    private func insertionAnchorBelongsBefore(
        _ item: MemoryCardContentItem
    ) -> Bool {
        item.kind == .text
            && item.value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }

    private func editableTextField(
        _ item: MemoryCardContentItem
    ) -> some View {
        MemoryCardInlineTextField(
            text: Binding(
                get: { item.value },
                set: {
                    onUpdateTextItem(item, $0)
                }
            ),
            placeholder: "",
            minWidth: textFieldWidth(for: item.value),
            onFocus: {
                onFocusTextItem(item)
            },
            onBackspaceAtBeginning: {
                onRemovePreviousComposedItem(item.id)
            }
        )
        .frame(minWidth: textFieldWidth(for: item.value))
    }

    private func transientTextField(
        placeholder: String,
        minWidth: CGFloat,
        onChange: @escaping (String) -> Void,
        onFocus: @escaping () -> Void
    ) -> some View {
        MemoryCardInlineTextField(
            text: Binding(
                get: { "" },
                set: onChange
            ),
            placeholder: placeholder,
            minWidth: minWidth,
            onFocus: onFocus,
            onBackspaceAtBeginning: { false }
        )
        .frame(minWidth: minWidth)
    }

    private func textFieldWidth(
        for value: String
    ) -> CGFloat {
        let trimmed =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            return 52
        }

        return min(
            max(CGFloat(trimmed.count) * 18, 42),
            180
        )
    }
}

final class MemoryCardTextKitModuleAttachment: NSTextAttachment {
    let item: MemoryCardContentItem

    init(
        item: MemoryCardContentItem,
        leadingAdvance: CGFloat = 0,
        trailingAdvance: CGFloat = MemoryCardEditorCapsuleMetrics.attachmentTrailingAdvance
    ) {
        self.item = item
        super.init(data: nil, ofType: nil)
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        let title = item.editorModuleTitle as NSString
        let titleWidth = ceil(title.size(withAttributes: [.font: font]).width)
        let size = CGSize(
            width: min(
                max(
                    titleWidth + MemoryCardEditorCapsuleMetrics.titleAdvance,
                    MemoryCardEditorCapsuleMetrics.minimumWidth
                ),
                MemoryCardEditorCapsuleMetrics.maximumWidth
            ),
            height: MemoryCardEditorCapsuleMetrics.height
        )
        let canvasSize = CGSize(
            width: size.width + leadingAdvance + trailingAdvance,
            height: size.height
        )
        let tintColor = item.isUnresolvedModule
            ? UIColor.systemOrange
            : UIColor.systemBlue
        image = UIGraphicsImageRenderer(size: canvasSize).image { context in
            let capsuleRect = CGRect(
                x: leadingAdvance,
                y: 0,
                width: size.width,
                height: size.height
            )
            tintColor.withAlphaComponent(0.12).setFill()
            UIBezierPath(
                roundedRect: capsuleRect,
                cornerRadius: MemoryCardEditorCapsuleMetrics.cornerRadius
            ).fill()
            tintColor.withAlphaComponent(0.22).setStroke()
            let border = UIBezierPath(
                roundedRect: CGRect(
                    x: capsuleRect.minX + MemoryCardEditorCapsuleMetrics.borderWidth / 2,
                    y: MemoryCardEditorCapsuleMetrics.borderWidth / 2,
                    width: capsuleRect.width - MemoryCardEditorCapsuleMetrics.borderWidth,
                    height: capsuleRect.height - MemoryCardEditorCapsuleMetrics.borderWidth
                ),
                cornerRadius: MemoryCardEditorCapsuleMetrics.cornerRadius
                    - MemoryCardEditorCapsuleMetrics.borderWidth / 2
            )
            border.lineWidth = MemoryCardEditorCapsuleMetrics.borderWidth
            border.stroke()
            let contentY = floor(
                (size.height - MemoryCardEditorCapsuleMetrics.iconSize) / 2
            )
            UIImage(systemName: item.editorModuleSystemImage)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal)
                .draw(
                    in: CGRect(
                        x: capsuleRect.minX + MemoryCardEditorCapsuleMetrics.iconLeading,
                        y: contentY,
                        width: MemoryCardEditorCapsuleMetrics.iconSize,
                        height: MemoryCardEditorCapsuleMetrics.iconSize
                    )
                )
            let titleY = floor((size.height - font.lineHeight) / 2)
            title.draw(
                at: CGPoint(
                    x: capsuleRect.minX + MemoryCardEditorCapsuleMetrics.titleLeading,
                    y: titleY
                ),
                withAttributes: [
                    .font: font,
                    .foregroundColor: UIColor.label
                ]
            )
            _ = context
        }
        // Align the capsule's visual center with the subheadline line rather
        // than using a fixed offset that drifts as Dynamic Type changes.
        let editorFont = UIFont.preferredFont(forTextStyle: .subheadline)
        let baselineOffset = MemoryCardEditorInputMetrics.attachmentBaselineOffset(
            for: editorFont,
            attachmentHeight: size.height
        )
        // Render the transparent boundary inside the attachment image itself.
        // TextKit then advances by one deterministic canvas width instead of
        // combining a bounds-origin offset with the font's side bearings.
        bounds = CGRect(
            x: 0,
            y: baselineOffset,
            width: canvasSize.width,
            height: canvasSize.height
        )
        accessibilityLabel = item.editorModuleAccessibilityLabel
    }

    required init?(coder: NSCoder) { nil }
}

private struct MemoryCardInlineTextField: UIViewRepresentable {

    @Binding var text: String
    let placeholder: String
    let minWidth: CGFloat
    let onFocus: () -> Void
    let onBackspaceAtBeginning: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MemoryCardInlineTextFieldView {
        let textField = MemoryCardInlineTextFieldView()
        textField.onBackspaceAtBeginning = {
            context.coordinator.parent.onBackspaceAtBeginning()
        }
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingDidBegin(_:)),
            for: .editingDidBegin
        )
        configure(textField)
        return textField
    }

    func updateUIView(
        _ textField: MemoryCardInlineTextFieldView,
        context: Context
    ) {
        context.coordinator.parent = self
        textField.onBackspaceAtBeginning = {
            context.coordinator.parent.onBackspaceAtBeginning()
        }
        configure(textField)
        if textField.text != text {
            textField.text = text
        }
    }

    private func configure(
        _ textField: MemoryCardInlineTextFieldView
    ) {
        textField.placeholder = placeholder
        textField.font = UIFont.preferredFont(
            forTextStyle: .subheadline
        )
        textField.adjustsFontForContentSizeCategory = true
        textField.textColor = .label
        textField.tintColor = .tintColor
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.clearButtonMode = .never
        textField.returnKeyType = .default
        textField.setContentHuggingPriority(
            .defaultLow,
            for: .horizontal
        )
        textField.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
    }

    final class Coordinator: NSObject {
        var parent: MemoryCardInlineTextField

        init(_ parent: MemoryCardInlineTextField) {
            self.parent = parent
        }

        @objc func textDidChange(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        @objc func editingDidBegin(_ sender: UITextField) {
            parent.onFocus()
        }
    }
}

private final class MemoryCardInlineTextFieldView: UITextField {
    var onBackspaceAtBeginning: (() -> Bool)?

    override func deleteBackward() {
        guard let selectedTextRange,
              selectedTextRange.isEmpty,
              offset(
                  from: beginningOfDocument,
                  to: selectedTextRange.start
              ) == 0,
              onBackspaceAtBeginning?() == true
        else {
            super.deleteBackward()
            return
        }
    }
}

#endif
