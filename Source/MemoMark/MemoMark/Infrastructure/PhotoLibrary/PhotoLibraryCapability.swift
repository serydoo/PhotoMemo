import Photos

/// A live capability snapshot. Limited visibility must never be treated as
/// proof that an inaccessible asset does not exist.
nonisolated enum PhotoLibraryCapability: Equatable, Sendable {
    case fullReadWrite
    case limited
    case addOnly
    case none

    init(readWrite: PHAuthorizationStatus, addOnly: PHAuthorizationStatus) {
        switch readWrite {
        case .authorized: self = .fullReadWrite
        case .limited: self = .limited
        default: self = addOnly == .authorized ? .addOnly : .none
        }
    }

    static var current: Self {
        Self(
            readWrite: PHPhotoLibrary.authorizationStatus(for: .readWrite),
            addOnly: PHPhotoLibrary.authorizationStatus(for: .addOnly)
        )
    }

    var canAddAssets: Bool { self != .none }
    var canReadVisibleAssets: Bool { self == .fullReadWrite || self == .limited }
    var canManageAlbums: Bool { self == .fullReadWrite }

    enum AlbumDisposition: Equatable {
        case resolveAlbum
        case systemLibrary
        case requiresFullAccess
    }

    func albumDisposition(preferredIdentifier: String?) -> AlbumDisposition {
        let identifier = MemoMarkAlbumSelection.normalizedIdentifier(preferredIdentifier ?? "")
        if identifier == MemoMarkAlbumSelection.systemLibraryIdentifier {
            return .systemLibrary
        }
        if canManageAlbums { return .resolveAlbum }
        return identifier.isEmpty ? .systemLibrary : .requiresFullAccess
    }
}
