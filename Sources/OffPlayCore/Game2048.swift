import Foundation

public enum SlideDirection: String, CaseIterable, Sendable {
    case left, right, up, down
}

public struct Game2048: Codable, Equatable, Sendable {
    private struct Snapshot: Codable, Equatable, Sendable {
        let board: [Int]
        let score: Int
        let moves: Int
        let random: RandomSource
    }

    public private(set) var board: [Int]
    public private(set) var score = 0
    public private(set) var moves = 0
    public private(set) var reached2048 = false
    private var random: RandomSource
    private var previous: Snapshot?

    public init(seed: UInt64, board: [Int]? = nil) {
        self.board = board ?? Array(repeating: 0, count: 16)
        random = RandomSource(seed: seed)
        if board == nil { spawn(); spawn() }
        reached2048 = self.board.contains { $0 >= 2048 }
    }

    public var highestTile: Int { board.max() ?? 0 }
    public var canUndo: Bool { previous != nil && !isGameOver }
    public var isGameOver: Bool {
        if board.contains(0) { return false }
        for r in 0..<4 {
            for c in 0..<4 {
                if c < 3 && board[r * 4 + c] == board[r * 4 + c + 1] { return false }
                if r < 3 && board[r * 4 + c] == board[(r + 1) * 4 + c] { return false }
            }
        }
        return true
    }

    @discardableResult public mutating func slide(_ direction: SlideDirection) -> Bool {
        guard !isGameOver else { return false }
        var nextBoard = board
        var points = 0
        for line in 0..<4 {
            let indices: [Int]
            switch direction {
            case .left: indices = (0..<4).map { line * 4 + $0 }
            case .right: indices = (0..<4).reversed().map { line * 4 + $0 }
            case .up: indices = (0..<4).map { $0 * 4 + line }
            case .down: indices = (0..<4).reversed().map { $0 * 4 + line }
            }
            let compact = indices.map { board[$0] }.filter { $0 != 0 }
            var merged: [Int] = []
            var index = 0
            while index < compact.count {
                if index + 1 < compact.count && compact[index] == compact[index + 1] {
                    let tile = compact[index] * 2
                    merged.append(tile)
                    points += tile
                    index += 2
                } else {
                    merged.append(compact[index])
                    index += 1
                }
            }
            merged += Array(repeating: 0, count: 4 - merged.count)
            for (offset, cell) in indices.enumerated() { nextBoard[cell] = merged[offset] }
        }
        guard nextBoard != board else { return false }
        previous = Snapshot(board: board, score: score, moves: moves, random: random)
        board = nextBoard
        score += points
        moves += 1
        reached2048 = reached2048 || board.contains { $0 >= 2048 }
        spawn()
        return true
    }

    @discardableResult public mutating func undo() -> Bool {
        guard canUndo, let saved = previous else { return false }
        board = saved.board
        score = saved.score
        moves = saved.moves
        random = saved.random
        previous = nil
        return true
    }

    private mutating func spawn() {
        let empty = board.indices.filter { board[$0] == 0 }
        guard !empty.isEmpty else { return }
        let index = empty[random.integer(lessThan: empty.count)]
        board[index] = random.integer(lessThan: 10) == 0 ? 4 : 2
    }

    var validForArchive: Bool {
        func validBoard(_ board: [Int]) -> Bool {
            board.count == 16 && board.allSatisfy { $0 == 0 || ($0 >= 2 && $0 <= 1 << 50 && $0 & ($0 - 1) == 0) }
        }
        return validBoard(board) && score >= 0 && score < 1 << 60 && moves >= 0 &&
            (previous == nil || (validBoard(previous!.board) && previous!.score >= 0 && previous!.moves >= 0)) &&
            (highestTile < 2048 || reached2048)
    }
}
