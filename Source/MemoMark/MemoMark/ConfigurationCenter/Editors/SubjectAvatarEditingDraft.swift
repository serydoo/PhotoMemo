#if !MEMOMARK_SHARE_EXTENSION
import Foundation

/// View-local editing state for the three derived avatar assets. This is not
/// durable subject truth: `MemorySubject.Identity` remains the persisted owner
/// and receives these values only through the editor's established save path.
struct SubjectAvatarEditingDraft: Equatable {

    static let emptyStatusMessage =
        "可选择对象头像，用于头像、标识与预览。"

    var displayImagePath: String?
    var badgeImagePath: String?
    var previewImagePath: String?
    var statusMessage: String

    init(
        displayImagePath: String? = nil,
        badgeImagePath: String? = nil,
        previewImagePath: String? = nil,
        statusMessage: String = Self.emptyStatusMessage
    ) {
        self.displayImagePath = displayImagePath
        self.badgeImagePath = badgeImagePath
        self.previewImagePath = previewImagePath
        self.statusMessage = statusMessage
    }

    var hasAvatar: Bool {
        displayImagePath?.isEmpty == false
        || badgeImagePath?.isEmpty == false
        || previewImagePath?.isEmpty == false
    }

    var previewPath: String? {
        previewImagePath ?? displayImagePath
    }

    /// Projects the complete derived-asset set into durable subject identity.
    /// Keeping the three paths together prevents a partially updated avatar
    /// from being observed by preview, badge, or export code.
    func applying(
        to identity: inout MemorySubject.Identity
    ) {
        identity.avatarImagePath = displayImagePath
        identity.avatarBadgeImagePath = badgeImagePath
        identity.avatarPreviewImagePath = previewImagePath
    }

    mutating func restore(
        displayImagePath: String?,
        badgeImagePath: String?,
        previewImagePath: String?
    ) {
        self.displayImagePath = displayImagePath
        self.badgeImagePath = badgeImagePath
        self.previewImagePath = previewImagePath
        statusMessage = hasAvatar
            ? "已准备头像衍生资源，可用于头像、标识与预览。"
            : Self.emptyStatusMessage
    }

    mutating func applyOptimizedPaths(
        displayImagePath: String,
        badgeImagePath: String,
        previewImagePath: String
    ) {
        self.displayImagePath = displayImagePath
        self.badgeImagePath = badgeImagePath
        self.previewImagePath = previewImagePath
        statusMessage = "头像已优化并同步到头像、标识与预览资源。"
    }
}
#endif
