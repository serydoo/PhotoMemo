import Foundation

/// Research transport only; not a durable metadata schema or preservation policy.
/// The caller must exclusively own mutable input while this initializer runs.
nonisolated struct GlassCardSDRResearchMetadataSnapshot: Sendable {
    enum Failure: Error, Equatable { case unsupportedProperties, invalidRoot }
    private let encoded: Data

    init(_ properties: [CFString: Any]) throws {
        let root=properties as NSDictionary
        guard PropertyListSerialization.propertyList(root,isValidFor:.binary) else {
            throw Failure.unsupportedProperties
        }
        encoded=try PropertyListSerialization.data(fromPropertyList:root,format:.binary,options:0)
    }

    /// Each call decodes an independent object graph at the consumer boundary.
    func properties() throws -> [CFString: Any] {
        let root=try PropertyListSerialization.propertyList(from:encoded,options:[],format:nil)
        guard let properties=root as? [CFString: Any] else { throw Failure.invalidRoot }
        return properties
    }
}
