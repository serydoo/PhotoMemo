import Foundation
import Testing
@testable import MemoMark

@Suite("Photos adjustment version identity")
struct ProcessingSourceAdjustmentIdentityTests {
    private func recipe(timestamp: Date, data: Data = Data([1, 2]), extra: Int? = nil) throws -> Data {
        var fields: [String: Any] = ["adjustmentData": data,
            "adjustmentFormatIdentifier": "com.apple.photo", "adjustmentFormatVersion": "1.4",
            "adjustmentBaseVersion": 0, "adjustmentRenderTypes": 3,
            "adjustmentEditorBundleID": "com.apple.mobileslideshow", "adjustmentTimestamp": timestamp]
        if let extra { fields["futureRenderingMode"] = extra }
        return try PropertyListSerialization.data(fromPropertyList: fields, format: .xml, options: 0)
    }
    @Test("resource materialization timestamp does not create a new visual intent")
    func timestamp() throws {
        #expect(try ProcessingSourceAdjustmentIdentity.digest(recipe(timestamp: .distantPast)) == ProcessingSourceAdjustmentIdentity.digest(recipe(timestamp: .distantFuture)))
    }
    @Test("actual edit data produces a distinct source version")
    func edits() throws {
        #expect(try ProcessingSourceAdjustmentIdentity.digest(recipe(timestamp: .distantPast)) != ProcessingSourceAdjustmentIdentity.digest(recipe(timestamp: .distantPast, data: Data([1, 3]))))
    }
    @Test("unknown source fields are preserved conservatively")
    func unknown() throws {
        #expect(try ProcessingSourceAdjustmentIdentity.digest(recipe(timestamp: .distantPast, extra: 1)) != ProcessingSourceAdjustmentIdentity.digest(recipe(timestamp: .distantPast, extra: 2)))
    }
}
