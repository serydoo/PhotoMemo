import Foundation

protocol MemoMarkIntent {

    associatedtype Output

    func execute() async -> MemoMarkResult<Output>
}
