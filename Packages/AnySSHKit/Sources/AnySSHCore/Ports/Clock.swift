import Foundation

public protocol Clock: Sendable {
    var now: Date { get }
}

public protocol IDProvider: Sendable {
    func next() -> String
}
