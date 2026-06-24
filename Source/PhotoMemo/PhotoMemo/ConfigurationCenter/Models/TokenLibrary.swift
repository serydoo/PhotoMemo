#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct TokenLibrary: Hashable {

    var memoryBlocks: [MemoryBlock]
    var photoBlocks: [MemoryBlock]
    var systemBlocks: [MemoryBlock]

    var categories: [TokenCategory] {
        TokenCategory.allCases
    }

    init(
        memoryBlocks: [MemoryBlock] = MemoryBlockLibrary.memory,
        photoBlocks: [MemoryBlock] = MemoryBlockLibrary.photo,
        systemBlocks: [MemoryBlock] = MemoryBlockLibrary.system
    ) {
        self.memoryBlocks = memoryBlocks
        self.photoBlocks = photoBlocks
        self.systemBlocks = systemBlocks
    }

    func blocks(
        for category: TokenCategory
    ) -> [MemoryBlock] {
        switch category {
        case .memory:
            return memoryBlocks
        case .photo:
            return photoBlocks
        case .system:
            return systemBlocks
        }
    }
}
#endif
