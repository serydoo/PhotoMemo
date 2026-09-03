#if !MEMOMARK_SHARE_EXTENSION
import Foundation
import Testing

@Suite("Task local thumbnail responsibility contract")
struct TaskLocalThumbnailContractTests {

    @Test("task page delegates local decode state to its thumbnail surface")
    func taskPageDelegatesLocalDecodeState() throws {
        let page = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/TaskPageSurface.swift"
            ),
            encoding: .utf8
        )
        let thumbnail = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/TaskLocalThumbnail.swift"
            ),
            encoding: .utf8
        )
        let history = try String(
            contentsOfFile: MemoMarkTestPaths.path(
                "Source/MemoMark/MemoMark/iOS/Views/TaskRecentHistorySurface.swift"
            ),
            encoding: .utf8
        )

        #expect(page.contains("TaskLocalThumbnail("))
        #expect(!page.contains("CGImageSourceCreateWithURL("))
        #expect(!page.contains("private struct TaskLocalThumbnail"))
        #expect(thumbnail.contains("struct TaskLocalThumbnail: View"))
        #expect(thumbnail.contains(".task(id: sourceURL)"))
        #expect(thumbnail.contains("Task.detached(priority: .utility)"))
        #expect(thumbnail.contains("CGImageSourceCreateThumbnailAtIndex("))
        #expect(!thumbnail.contains("BatchQueueStore"))
        #expect(!thumbnail.contains("PhotoLibraryExportService"))
        #expect(page.contains("TaskRecentHistorySurface("))
        #expect(!page.contains("private var groupedHistoryRows"))
        #expect(history.contains("struct TaskRecentHistorySurface: View"))
        #expect(history.contains("@Binding\n    var isSheetPresented"))
        #expect(history.contains("onOpenPhotoLibrary(link)"))
        #expect(!history.contains("BatchQueueStore"))
    }
}
#endif
