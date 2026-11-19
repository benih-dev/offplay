import Foundation

public enum SudokuAnalysis {
    public static let units: [[Int]] = {
        let rows = (0..<9).map { r in (0..<9).map { r * 9 + $0 } }
        let columns = (0..<9).map { c in (0..<9).map { $0 * 9 + c } }
        let boxes = (0..<9).map { box in
            (0..<9).map { (box / 3 * 3 + $0 / 3) * 9 + box % 3 * 3 + $0 % 3 }
        }
        return rows + columns + boxes
    }()
    static let peers: [[Int]] = (0..<81).map { cell in
        Array(Set(units.filter { $0.contains(cell) }.flatMap { $0 })).filter { $0 != cell }.sorted()
    }

    public static func isValid(_ grid: [Int]) -> Bool {
        guard grid.count == 81, grid.allSatisfy({ (0...9).contains($0) }) else { return false }
        return units.allSatisfy { unit in
            let values = unit.map { grid[$0] }.filter { $0 != 0 }
            return values.count == Set(values).count
        }
    }

    public static func solutionCount(_ grid: [Int], limit: Int = 2) -> Int {
        guard isValid(grid), limit > 0 else { return 0 }
        var board = grid
        var count = 0
        func search() {
            if count >= limit { return }
            var selected = -1, options = 0, best = 10
            for index in board.indices where board[index] == 0 {
                var used = 0
                for peer in peers[index] where board[peer] > 0 { used |= 1 << (board[peer] - 1) }
                let mask = 511 & ~used
                let size = mask.nonzeroBitCount
                if size == 0 { return }
                if size < best { selected = index; options = mask; best = size }
                if best == 1 { break }
            }
            if selected < 0 { count += 1; return }
            for digit in 1...9 where options & (1 << (digit - 1)) != 0 {
                board[selected] = digit
                search()
                if count >= limit { break }
            }
            board[selected] = 0
        }
        search()
        return count
    }

    public static func makeSolution(using random: inout RandomSource) -> [Int] {
        var board = Array(repeating: 0, count: 81)
        func fill() -> Bool {
            var selected = -1, choices: [Int] = [], best = 10
            for index in board.indices where board[index] == 0 {
                let used = Set(peers[index].map { board[$0] })
                let options = (1...9).filter { !used.contains($0) }
                if options.isEmpty { return false }
                if options.count < best { selected = index; choices = options; best = options.count }
                if best == 1 { break }
            }
            if selected < 0 { return true }
            for digit in random.shuffled(choices) {
                board[selected] = digit
                if fill() { return true }
            }
            board[selected] = 0
            return false
        }
        precondition(fill())
        return board
    }

    public static func difficulty(of givens: [Int]) -> SudokuDifficulty? {
        guard isValid(givens) else { return nil }
        var solver = LogicalSolver(grid: givens)
        return solver.solve()
    }

    private struct LogicalSolver {
        var grid: [Int]
        var candidates: [Int]

        init(grid: [Int]) {
            self.grid = grid
            candidates = grid.indices.map { index in
                guard grid[index] == 0 else { return 0 }
                var used = 0
                for peer in peers[index] where grid[peer] > 0 { used |= 1 << (grid[peer] - 1) }
                return 511 & ~used
            }
        }

        mutating func solve() -> SudokuDifficulty? {
            var level = 0
            for _ in 0..<2000 {
                if !grid.contains(0) { return [SudokuDifficulty.easy, .medium, .hard][level] }
                if grid.indices.contains(where: { grid[$0] == 0 && candidates[$0] == 0 }) { return nil }
                if singles() { continue }
                if lockedCandidates() || nakedPairs() { level = max(level, 1); continue }
                if hiddenPairs() || nakedTriples() { level = 2; continue }
                return nil
            }
            return nil
        }

        mutating func assign(_ digit: Int, to cell: Int) {
            grid[cell] = digit
            candidates[cell] = 0
            let bit = 1 << (digit - 1)
            for peer in peers[cell] { candidates[peer] &= ~bit }
        }

        mutating func singles() -> Bool {
            for cell in grid.indices where grid[cell] == 0 && candidates[cell].nonzeroBitCount == 1 {
                assign(candidates[cell].trailingZeroBitCount + 1, to: cell)
                return true
            }
            for unit in units {
                for digit in 1...9 where !unit.contains(where: { grid[$0] == digit }) {
                    let cells = unit.filter { grid[$0] == 0 && candidates[$0] & (1 << (digit - 1)) != 0 }
                    if cells.count == 1 { assign(digit, to: cells[0]); return true }
                }
            }
            return false
        }

        mutating func remove(_ mask: Int, from cells: [Int]) -> Bool {
            var changed = false
            for cell in cells where grid[cell] == 0 && candidates[cell] & mask != 0 {
                candidates[cell] &= ~mask
                changed = true
            }
            return changed
        }

        mutating func lockedCandidates() -> Bool {
            for box in units.suffix(9) {
                for digit in 1...9 {
                    let bit = 1 << (digit - 1)
                    let cells = box.filter { grid[$0] == 0 && candidates[$0] & bit != 0 }
                    guard cells.count > 1 else { continue }
                    if Set(cells.map { $0 / 9 }).count == 1 {
                        if remove(bit, from: units[cells[0] / 9].filter { !box.contains($0) }) { return true }
                    }
                    if Set(cells.map { $0 % 9 }).count == 1 {
                        if remove(bit, from: units[9 + cells[0] % 9].filter { !box.contains($0) }) { return true }
                    }
                }
            }
            for unit in units.prefix(18) {
                for digit in 1...9 {
                    let bit = 1 << (digit - 1)
                    let cells = unit.filter { grid[$0] == 0 && candidates[$0] & bit != 0 }
                    guard cells.count > 1 else { continue }
                    let boxes = Set(cells.map { ($0 / 9 / 3) * 3 + $0 % 9 / 3 })
                    if boxes.count == 1, let box = boxes.first,
                       remove(bit, from: units[18 + box].filter({ !unit.contains($0) })) { return true }
                }
            }
            return false
        }

        mutating func nakedPairs() -> Bool {
            for unit in units {
                let pairs = Dictionary(grouping: unit.filter { grid[$0] == 0 && candidates[$0].nonzeroBitCount == 2 }, by: { candidates[$0] })
                for mask in pairs.keys.sorted() {
                    guard let cells = pairs[mask], cells.count == 2 else { continue }
                    if remove(mask, from: unit.filter { !cells.contains($0) }) { return true }
                }
            }
            return false
        }

        mutating func hiddenPairs() -> Bool {
            for unit in units {
                for first in 1..<9 {
                    let firstCells = unit.filter { grid[$0] == 0 && candidates[$0] & (1 << (first - 1)) != 0 }
                    guard firstCells.count == 2 else { continue }
                    for second in (first + 1)...9 {
                        let secondCells = unit.filter { grid[$0] == 0 && candidates[$0] & (1 << (second - 1)) != 0 }
                        guard firstCells == secondCells else { continue }
                        let mask = (1 << (first - 1)) | (1 << (second - 1))
                        if remove(511 & ~mask, from: firstCells) { return true }
                    }
                }
            }
            return false
        }

        mutating func nakedTriples() -> Bool {
            for unit in units {
                let cells = unit.filter { grid[$0] == 0 && (2...3).contains(candidates[$0].nonzeroBitCount) }
                guard cells.count >= 3 else { continue }
                for a in 0..<(cells.count - 2) {
                    for b in (a + 1)..<(cells.count - 1) {
                        for c in (b + 1)..<cells.count {
                            let selected = [cells[a], cells[b], cells[c]]
                            let mask = selected.reduce(0) { $0 | candidates[$1] }
                            if mask.nonzeroBitCount == 3 && remove(mask, from: unit.filter({ !selected.contains($0) })) { return true }
                        }
                    }
                }
            }
            return false
        }
    }
}
