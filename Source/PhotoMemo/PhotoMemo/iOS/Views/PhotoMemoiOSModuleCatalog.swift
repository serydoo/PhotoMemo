#if !PHOTOMEMO_SHARE_EXTENSION
import Foundation

struct IOSInsertedModule:
    Identifiable,
    Hashable {

    let id: UUID
    let moduleID: MemoryCardModuleID?
    let title: String
    let value: String
    let systemImage: String
    let expressionConfiguration: ExpressionModuleConfiguration?

    init(
        id: UUID = UUID(),
        moduleID: MemoryCardModuleID? = nil,
        title: String,
        value: String,
        systemImage: String,
        expressionConfiguration: ExpressionModuleConfiguration? = nil
    ) {
        self.id = id
        self.moduleID = moduleID
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.expressionConfiguration = expressionConfiguration
    }
}

typealias IOSInsertableModule = MemoryCardModuleID
#endif
