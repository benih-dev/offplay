import Foundation

public struct RandomSource: Codable, Equatable, Sendable {
    public private(set) var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }

    public mutating func integer(lessThan bound: Int) -> Int {
        precondition(bound > 0)
        let range = UInt64(bound)
        let threshold = (0 &- range) % range
        var value = next()
        while value < threshold { value = next() }
        return Int(value % range)
    }

    public mutating func shuffled<T>(_ values: [T]) -> [T] {
        var result = values
        guard result.count > 1 else { return result }
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            result.swapAt(index, integer(lessThan: index + 1))
        }
        return result
    }
}

public struct GridCell: Codable, Hashable, Sendable {
    public let row: Int
    public let column: Int

    public init(_ row: Int, _ column: Int) {
        self.row = row
        self.column = column
    }
}
