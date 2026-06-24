#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryBlockLibrary {

    static let memory: [MemoryBlock] = [
        MemoryBlock(
            type: .memory,
            title: "昵称",
            value: "昵称"
        ),
        MemoryBlock(
            type: .memory,
            title: "年龄",
            value: "年龄"
        ),
        MemoryBlock(
            type: .memory,
            title: "生命时间",
            value: "生命时间"
        )
    ]

    static let photo: [MemoryBlock] = [
        MemoryBlock(
            type: .photo,
            title: "拍摄日期",
            value: "拍摄日期"
        ),
        MemoryBlock(
            type: .photo,
            title: "拍摄时间",
            value: "拍摄时间"
        ),
        MemoryBlock(
            type: .photo,
            title: "相机",
            value: "相机"
        )
    ]

    static let system: [MemoryBlock] = [
        MemoryBlock(
            type: .system,
            title: "预留",
            value: "预留",
            isReserved: true
        )
    ]
}
#endif
