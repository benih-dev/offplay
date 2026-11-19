import Foundation

public struct BlockGridGame: Codable, Equatable, Sendable {
    public static let side = 8
    public static let pieces: [[GridCell]] = {
        var shapes = [[GridCell(0, 0)]]
        for length in 2...5 {
            shapes.append((0..<length).map { GridCell(0, $0) })
            shapes.append((0..<length).map { GridCell($0, 0) })
        }
        shapes.append((0..<4).map { GridCell($0 / 2, $0 % 2) })
        shapes.append((0..<9).map { GridCell($0 / 3, $0 % 3) })
        shapes += [
            [GridCell(0, 0), GridCell(1, 0), GridCell(1, 1)],
            [GridCell(0, 0), GridCell(0, 1), GridCell(1, 0)],
            [GridCell(0, 0), GridCell(0, 1), GridCell(1, 1)],
            [GridCell(0, 1), GridCell(1, 0), GridCell(1, 1)],
            [GridCell(0, 0), GridCell(0, 1), GridCell(0, 2), GridCell(1, 1)],
            [GridCell(0, 1), GridCell(1, 0), GridCell(1, 1), GridCell(2, 1)],
            [GridCell(0, 1), GridCell(1, 0), GridCell(1, 1), GridCell(1, 2)],
            [GridCell(0, 0), GridCell(1, 0), GridCell(1, 1), GridCell(2, 0)]
        ]
        return shapes
    }()

    public private(set) var board: [Int]
    public private(set) var tray: [Int?]
    public private(set) var score = 0
    public private(set) var clearedLines = 0
    private var random: RandomSource

    public init(seed: UInt64) {
        board = Array(repeating: 0, count: 64)
        tray = []
        random = RandomSource(seed: seed)
        refill()
    }

    init(board: [Int], tray: [Int?], seed: UInt64 = 1) {
        self.board = board
        self.tray = tray
        random = RandomSource(seed: seed)
    }

    public func canPlace(slot: Int, row: Int, column: Int) -> Bool {
        guard tray.indices.contains(slot), let piece = tray[slot] else { return false }
        return Self.pieces[piece].allSatisfy {
            let r = row + $0.row, c = column + $0.column
            return (0..<8).contains(r) && (0..<8).contains(c) && board[r * 8 + c] == 0
        }
    }

    @discardableResult public mutating func place(slot: Int, row: Int, column: Int) -> Bool {
        guard canPlace(slot: slot, row: row, column: column), let piece = tray[slot] else { return false }
        for cell in Self.pieces[piece] { board[(row + cell.row) * 8 + column + cell.column] = piece + 1 }
        tray[slot] = nil
        let rows = (0..<8).filter { r in (0..<8).allSatisfy { board[r * 8 + $0] > 0 } }
        let columns = (0..<8).filter { c in (0..<8).allSatisfy { board[$0 * 8 + c] > 0 } }
        for row in rows { for c in 0..<8 { board[row * 8 + c] = 0 } }
        for column in columns { for r in 0..<8 { board[r * 8 + column] = 0 } }
        clearedLines = rows.count + columns.count
        score += Self.pieces[piece].count + 10 * clearedLines
        if tray.allSatisfy({ $0 == nil }) { refill() }
        return true
    }

    public var isGameOver: Bool {
        !tray.indices.contains { slot in
            (0..<64).contains { canPlace(slot: slot, row: $0 / 8, column: $0 % 8) }
        }
    }

    private mutating func refill() {
        tray = (0..<3).map { _ in random.integer(lessThan: Self.pieces.count) }
    }

    var validForArchive: Bool {
        board.count == 64 && board.allSatisfy { (0...19).contains($0) } &&
        tray.count == 3 && tray.contains { $0 != nil } && tray.allSatisfy { $0 == nil || (0..<19).contains($0!) } &&
        score >= 0 && (0...16).contains(clearedLines)
    }
}
