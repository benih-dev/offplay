import Foundation

public struct MinesweeperGame: Codable, Equatable, Sendable {
    public let difficulty: MineDifficulty
    public private(set) var mines: Set<Int> = []
    public private(set) var revealed: Set<Int> = []
    public private(set) var flags: Set<Int> = []
    public private(set) var exploded: Int?
    public private(set) var moves = 0
    private var random: RandomSource

    public init(difficulty: MineDifficulty = .beginner, seed: UInt64) {
        self.difficulty = difficulty
        random = RandomSource(seed: seed)
    }

    init(difficulty: MineDifficulty, mines: Set<Int>, revealed: Set<Int>, flags: Set<Int>) {
        self.difficulty = difficulty
        self.mines = mines
        self.revealed = revealed
        self.flags = flags
        random = RandomSource(seed: 1)
    }

    public var side: Int { difficulty.side }
    public var mineCount: Int { difficulty.mineCount }
    public var isLost: Bool { exploded != nil }
    public var isWon: Bool { !mines.isEmpty && !isLost && revealed.count == side * side - mineCount }
    public var isFinished: Bool { isLost || isWon }

    public func neighbors(of index: Int) -> [Int] {
        let row = index / side, column = index % side
        return (-1...1).flatMap { dr in
            (-1...1).compactMap { dc -> Int? in
                let r = row + dr, c = column + dc
                guard (dr != 0 || dc != 0), (0..<side).contains(r), (0..<side).contains(c) else { return nil }
                return r * side + c
            }
        }
    }

    public func adjacentMines(at index: Int) -> Int { neighbors(of: index).filter { mines.contains($0) }.count }

    @discardableResult public mutating func toggleFlag(at index: Int) -> Bool {
        guard valid(index), !isFinished, !revealed.contains(index) else { return false }
        if flags.contains(index) { flags.remove(index) }
        else {
            guard flags.count < mineCount else { return false }
            flags.insert(index)
        }
        moves += 1
        return true
    }

    @discardableResult public mutating func reveal(at index: Int) -> Bool {
        guard valid(index), !isFinished, !revealed.contains(index), !flags.contains(index) else { return false }
        if mines.isEmpty {
            let safe = Set(neighbors(of: index) + [index])
            let candidates = (0..<(side * side)).filter { !safe.contains($0) }
            mines = Set(random.shuffled(candidates).prefix(mineCount))
        }
        open([index])
        moves += 1
        return true
    }

    @discardableResult public mutating func chord(at index: Int) -> Bool {
        guard valid(index), !isFinished, revealed.contains(index),
              neighbors(of: index).filter({ flags.contains($0) }).count == adjacentMines(at: index) else { return false }
        let targets = neighbors(of: index).filter { !revealed.contains($0) && !flags.contains($0) }
        guard !targets.isEmpty else { return false }
        open(targets)
        moves += 1
        return true
    }

    private func valid(_ index: Int) -> Bool { (0..<(side * side)).contains(index) }

    private mutating func open(_ targets: [Int]) {
        var pending = targets
        while let index = pending.popLast() {
            if revealed.contains(index) || flags.contains(index) { continue }
            if mines.contains(index) { exploded = index; return }
            revealed.insert(index)
            if adjacentMines(at: index) == 0 {
                pending += neighbors(of: index).filter { !revealed.contains($0) && !flags.contains($0) }
            }
        }
    }

    var validForArchive: Bool {
        (mines.isEmpty || mines.count == mineCount) && flags.count <= mineCount &&
        [mines, flags, revealed].allSatisfy { $0.allSatisfy { valid($0) } } &&
        flags.isDisjoint(with: revealed) && moves >= 0 &&
        (exploded == nil || mines.contains(exploded!)) && (!mines.isEmpty || revealed.isEmpty)
    }
}
