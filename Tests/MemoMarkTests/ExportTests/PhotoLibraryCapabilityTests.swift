import Photos
import Testing
@testable import MemoMark

@Suite("Photo Library capability boundaries")
struct PhotoLibraryCapabilityTests {
    @Test("read/write status and add-only status are independent")
    func permissionMatrix() {
        #expect(PhotoLibraryCapability(readWrite: .authorized, addOnly: .authorized) == .fullReadWrite)
        #expect(PhotoLibraryCapability(readWrite: .limited, addOnly: .authorized) == .limited)
        #expect(PhotoLibraryCapability(readWrite: .denied, addOnly: .authorized) == .addOnly)
        #expect(PhotoLibraryCapability(readWrite: .notDetermined, addOnly: .notDetermined) == .none)
        #expect(PhotoLibraryCapability(readWrite: .restricted, addOnly: .denied) == .none)
    }

    @Test("restricted scopes never acquire album authority")
    func operationBoundaries() {
        #expect(PhotoLibraryCapability.fullReadWrite.canManageAlbums)
        for capability in [PhotoLibraryCapability.limited, .addOnly, .none] {
            #expect(!capability.canManageAlbums)
        }
        #expect(PhotoLibraryCapability.limited.canReadVisibleAssets)
        #expect(!PhotoLibraryCapability.addOnly.canReadVisibleAssets)
        #expect(PhotoLibraryCapability.addOnly.canAddAssets)
        #expect(!PhotoLibraryCapability.none.canAddAssets)
    }

    @Test("default destination degrades but explicit intent cannot be discarded")
    func destinationBoundaries() {
        #expect(PhotoLibraryCapability.limited.albumDisposition(preferredIdentifier: nil) == .systemLibrary)
        #expect(PhotoLibraryCapability.addOnly.albumDisposition(preferredIdentifier: "album") == .requiresFullAccess)
        #expect(PhotoLibraryCapability.fullReadWrite.albumDisposition(preferredIdentifier: nil) == .resolveAlbum)
    }
}
