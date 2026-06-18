import SwiftUI

struct MainComposerChipStyle {

    let icon: String

    let tint: Color

    let background: Color

    let border: Color
}

struct MainComposerChipView: View {

    let title: String

    let plainLiteralText: String?

    let style: MainComposerChipStyle

    let isSelected: Bool

    let isHovered: Bool

    let isArranging: Bool

    let composerWigglePhase: Bool

    let onRemove: () -> Void

    var body: some View {

        HStack(spacing: 8) {

            if !isPlainLiteral {

                Image(systemName: style.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(style.tint)
            }

            Text(title)
                .font(
                    isPlainLiteral
                    ? .subheadline
                    : .subheadline.weight(.medium)
                )
                .foregroundStyle(
                    isPlainLiteral
                    ? Color.primary.opacity(0.88)
                    : .primary
                )
                .lineLimit(1)

            if isArranging {

                Image(systemName: "line.3.horizontal")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, isPlainLiteral ? 2 : 12)
        .padding(.vertical, 9)
        .background {
            if isPlainLiteral {
                Color.clear
            } else {
                Capsule()
                    .fill(style.background)
            }
        }
        .overlay {
            if isPlainLiteral {
                Rectangle()
                    .fill(
                        isSelected
                            ? MinimalPalette.accent.opacity(0.16)
                            : Color.clear
                    )
                    .frame(height: 2)
                    .offset(y: 15)
            } else {
                Capsule()
                    .stroke(
                        isSelected
                            ? MinimalPalette.accent
                            : style.border,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        }
        .shadow(
            color:
                isPlainLiteral
                ? .clear
                : (
                    isSelected
                    ? MinimalPalette.accent.opacity(0.22)
                    : .black.opacity(
                        isHovered ? 0.06 : 0
                    )
                ),
            radius: isSelected ? 10 : 6,
            y: isSelected ? 4 : 2
        )
        .scaleEffect(
            isPlainLiteral
            ? 1
            : (
                isSelected
                ? 1.015
                : (isHovered ? 1.01 : 1)
            )
        )
        .rotationEffect(
            isArranging
            ? .degrees(
                composerWigglePhase ? 1.2 : -1.2
            )
            : .zero
        )
        .offset(
            y:
                isArranging
                ? (composerWigglePhase ? -0.8 : 0.8)
                : 0
        )
        .overlay(
            alignment: .topTrailing
        ) {

            if isArranging {

                Button(action: onRemove) {
                    Image(
                        systemName: "minus.circle.fill"
                    )
                    .font(.caption)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .white,
                        Color.red.opacity(0.9)
                    )
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
        .animation(
            .spring(
                response: 0.22,
                dampingFraction: 0.9
            ),
            value: isSelected
        )
        .animation(
            .easeInOut(duration: 0.16),
            value: isHovered
        )
        .animation(
            .easeInOut(duration: 0.14),
            value: composerWigglePhase
        )
    }

    private var isPlainLiteral: Bool {

        plainLiteralText != nil
    }
}

struct MainComposerInsertionHandleView: View {

    let isSelected: Bool

    let onSelect: () -> Void

    var body: some View {

        Button(action: onSelect) {
            ZStack {

                Capsule()
                    .fill(
                        Color.black.opacity(
                            isSelected ? 0.08 : 0.04
                        )
                    )
                    .frame(
                        width: isSelected ? 18 : 12,
                        height: isSelected ? 34 : 24
                    )

                RoundedRectangle(
                    cornerRadius: 999,
                    style: .continuous
                )
                .fill(
                    isSelected
                        ? MinimalPalette.accent
                        : Color.black.opacity(0.16)
                )
                .frame(
                    width: isSelected ? 3 : 2,
                    height: isSelected ? 24 : 16
                )

                if isSelected {

                    Image(systemName: "plus.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(
                            MinimalPalette.accent
                        )
                        .offset(y: 18)
                }
            }
            .frame(width: 20, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("插入到这里")
    }
}

struct MainInlineTemplateEditorView: View {

    let slot: MainFieldSlot

    let isFocused: Bool

    @Binding
    var text: String

    @Binding
    var selection: NSRange

    let onFocus: () -> Void

    var body: some View {

        ZStack(
            alignment: .topLeading
        ) {

            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(Color.white.opacity(0.84))
            .overlay(
                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    isFocused
                        ? MinimalPalette
                        .accent.opacity(0.28)
                        : Color.black.opacity(0.04)
                )
            )

            if text.isEmpty {

                Text(slot.placeholder)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .allowsHitTesting(false)
            }

            InlineTemplateTextEditor(
                text: $text,
                selection: $selection,
                onFocus: onFocus
            )
            .padding(.horizontal, 12)
            .frame(
                minHeight: 48,
                maxHeight: 72,
                alignment: .topLeading
            )
        }
        .contentShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .onTapGesture {
            onFocus()
        }
    }
}
