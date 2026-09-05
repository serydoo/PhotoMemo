#if os(iOS) && !MEMOMARK_SHARE_EXTENSION
import SwiftUI

/// The two native modal patterns used by MemoMark.
///
/// This type centralizes the presentation contract only. A sheet's content
/// still owns its navigation title and actions, so persistence and workflow
/// state do not move into a visual helper.
enum MemoMarkSheetPattern {
    case editor
    case browser

    var defaultDetents: Set<PresentationDetent> {
        [.medium, .large]
    }
}

extension View {

    /// Applies MemoMark's shared native-sheet presentation rhythm.
    func memoMarkSheet(
        _ pattern: MemoMarkSheetPattern,
        detents: Set<PresentationDetent>? = nil
    ) -> some View {
        presentationDetents(
            detents ?? pattern.defaultDetents
        )
        .presentationDragIndicator(.visible)
        .presentationBackground(ConfigurationUI.appBackground)
    }

    /// Standard toolbar placement for sheets that edit a draft.
    func memoMarkEditorSheetToolbar(
        cancelTitle: String,
        doneTitle: String,
        doneAccessibilityIdentifier: String? = nil,
        doneDisabled: Bool = false,
        onCancel: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(cancelTitle, action: onCancel)
            }

            ToolbarItem(placement: .confirmationAction) {
                if let doneAccessibilityIdentifier {
                    Button(doneTitle, action: onDone)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier(doneAccessibilityIdentifier)
                        .disabled(doneDisabled)
                } else {
                    Button(doneTitle, action: onDone)
                        .fontWeight(.semibold)
                        .disabled(doneDisabled)
                }
            }
        }
    }

    /// Standard trailing action for read-only or browsing sheets.
    func memoMarkBrowserSheetToolbar(
        doneTitle: String,
        onDone: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(doneTitle, action: onDone)
                    .fontWeight(.semibold)
            }
        }
    }
}
#endif
