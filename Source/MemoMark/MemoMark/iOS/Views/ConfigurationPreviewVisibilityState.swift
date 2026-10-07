#if !MEMOMARK_SHARE_EXTENSION
/// A temporary viewing choice, never part of a preset or processing snapshot.
struct ConfigurationPreviewVisibilityState {
    var isCollapsed = false

    func isVisible(
        isEditingCardContent: Bool,
        allowsCollapseDuringEditing: Bool = false
    ) -> Bool {
        (isEditingCardContent && !allowsCollapseDuringEditing) || !isCollapsed
    }
}
#endif
