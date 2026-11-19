import Foundation

public struct SudokuPuzzle: Codable, Equatable, Sendable {
    public let id: String
    public let difficulty: SudokuDifficulty
    public let givens: [Int]
    public let solution: [Int]

    public init(id: String, difficulty: SudokuDifficulty, givens: [Int], solution: [Int]) {
        self.id = id; self.difficulty = difficulty; self.givens = givens; self.solution = solution
    }
}

public struct SudokuGame: Codable, Equatable, Sendable {
    private struct Snapshot: Codable, Equatable, Sendable {
        let values: [Int]
        let notes: [Set<Int>]
    }
    public let puzzle: SudokuPuzzle
    public private(set) var values: [Int]
    public private(set) var notes: [Set<Int>] = Array(repeating: [], count: 81)
    private var history: [Snapshot] = []

    public init(puzzle: SudokuPuzzle) { self.puzzle = puzzle; values = puzzle.givens }
    public var canUndo: Bool { !history.isEmpty && !isWon }
    public var isWon: Bool { !values.contains(0) && duplicateCells.isEmpty }

    public var duplicateCells: Set<Int> {
        var conflicts: Set<Int> = []
        for unit in SudokuAnalysis.units {
            for digit in 1...9 {
                let cells = unit.filter { values[$0] == digit }
                if cells.count > 1 { conflicts.formUnion(cells) }
            }
        }
        return conflicts
    }

    @discardableResult public mutating func enter(_ digit: Int, at index: Int, asNote: Bool = false) -> Bool {
        guard values.indices.contains(index), puzzle.givens[index] == 0, (0...9).contains(digit), !isWon else { return false }
        if asNote {
            guard values[index] == 0, digit > 0 else { return false }
            remember()
            if notes[index].contains(digit) { notes[index].remove(digit) } else { notes[index].insert(digit) }
        } else {
            guard values[index] != digit || !notes[index].isEmpty else { return false }
            remember()
            values[index] = digit
            notes[index] = []
        }
        return true
    }

    @discardableResult public mutating func undo() -> Bool {
        guard canUndo, let snapshot = history.popLast() else { return false }
        values = snapshot.values; notes = snapshot.notes
        return true
    }

    private mutating func remember() {
        history.append(Snapshot(values: values, notes: notes))
        if history.count > 100 { history.removeFirst(history.count - 100) }
    }

    var validForArchive: Bool {
        guard puzzle.givens.count == 81, puzzle.solution.count == 81,
              !puzzle.solution.contains(0), SudokuAnalysis.isValid(puzzle.solution),
              puzzle.givens.indices.allSatisfy({ puzzle.givens[$0] == 0 || puzzle.givens[$0] == puzzle.solution[$0] }) else { return false }
        func valid(_ values: [Int], _ notes: [Set<Int>]) -> Bool {
            values.count == 81 && notes.count == 81 && values.allSatisfy { (0...9).contains($0) } &&
            notes.allSatisfy { $0.allSatisfy { (1...9).contains($0) } } && values.indices.allSatisfy {
                (puzzle.givens[$0] == 0 || values[$0] == puzzle.givens[$0]) && (values[$0] == 0 || notes[$0].isEmpty)
            }
        }
        return history.count <= 100 && valid(values, notes) && history.allSatisfy { valid($0.values, $0.notes) }
    }
}
