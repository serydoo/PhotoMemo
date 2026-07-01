import Foundation

protocol PhotoMemoIntent {

    associatedtype Output

    func execute() async -> PhotoMemoResult<Output>
}
