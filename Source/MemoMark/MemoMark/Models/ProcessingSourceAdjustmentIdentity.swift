import Foundation

/// Normalize only the observed Photos resource envelope. Unknown formats are
/// hashed intact so future edit semantics are never accidentally discarded.
nonisolated enum ProcessingSourceAdjustmentIdentity {
    private struct Recipe: Encodable {
        let formatIdentifier: String
        let formatVersion: String
        let data: Data
        let baseVersion: Int?
        let renderTypes: Int?
        let editorBundleID: String?
    }

    static func digest(_ resourceData: Data) -> String {
        let knownKeys: Set<String> = ["adjustmentData", "adjustmentFormatIdentifier",
            "adjustmentFormatVersion", "adjustmentBaseVersion", "adjustmentRenderTypes",
            "adjustmentEditorBundleID", "adjustmentTimestamp"]
        guard let fields = (try? PropertyListSerialization.propertyList(from: resourceData, options: [], format: nil)) as? [String: Any],
              Set(fields.keys).isSubset(of: knownKeys),
              let data = fields["adjustmentData"] as? Data,
              let identifier = fields["adjustmentFormatIdentifier"] as? String,
              let version = fields["adjustmentFormatVersion"] as? String else {
            return "opaque-v1:" + ProcessingIdentity.digest(resourceData)
        }
        let recipe = Recipe(formatIdentifier: identifier, formatVersion: version, data: data,
            baseVersion: fields["adjustmentBaseVersion"] as? Int,
            renderTypes: fields["adjustmentRenderTypes"] as? Int,
            editorBundleID: fields["adjustmentEditorBundleID"] as? String)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let encoded = try? encoder.encode(recipe) else {
            return "opaque-v1:" + ProcessingIdentity.digest(resourceData)
        }
        return "photos-recipe-v1:" + ProcessingIdentity.digest(encoded)
    }
}
