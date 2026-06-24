#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct MemoryBlockLibrary {

    static let memory: [MemoryBlock] = [
        MemoryBlock(
            type: .memory,
            title: "Nickname",
            value: "昵称"
        ),
        MemoryBlock(
            type: .memory,
            title: "Age",
            value: "年龄"
        ),
        MemoryBlock(
            type: .memory,
            title: "Life Anchor",
            value: "Life Anchor"
        )
    ]

    static let photo: [MemoryBlock] = [
        MemoryBlock(
            type: .photo,
            title: "Capture Date",
            value: "拍摄日期"
        ),
        MemoryBlock(
            type: .photo,
            title: "Capture Time",
            value: "拍摄时间"
        ),
        MemoryBlock(
            type: .photo,
            title: "Camera",
            value: "相机"
        )
    ]

    static let system: [MemoryBlock] = [
        MemoryBlock(
            type: .system,
            title: "Reserved",
            value: "Reserved",
            isReserved: true
        )
    ]
}
#endif
