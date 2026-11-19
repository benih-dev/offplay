import Foundation

public enum GameState: Codable, Equatable, Sendable {
    case blockGrid(BlockGridGame), klondike(KlondikeGame), sudoku(SudokuGame)
    case game2048(Game2048), minesweeper(MinesweeperGame), wordScramble(WordScrambleGame)

    public var id: GameID {
        switch self {
        case .blockGrid: .blockGrid; case .klondike: .klondike; case .sudoku: .sudoku
        case .game2048: .game2048; case .minesweeper: .minesweeper; case .wordScramble: .wordScramble
        }
    }
    public var outcome: SessionOutcome? {
        switch self {
        case let .blockGrid(game): game.isGameOver ? .lost : nil
        case let .klondike(game): game.isWon ? .won : nil
        case let .sudoku(game): game.isWon ? .won : nil
        case let .game2048(game): game.isGameOver ? .lost : nil
        case let .minesweeper(game): game.isLost ? .lost : (game.isWon ? .won : nil)
        case let .wordScramble(game): game.isWon ? .won : nil
        }
    }
    public var score: Int? {
        switch self { case let .blockGrid(game): game.score; case let .game2048(game): game.score; default: nil }
    }
    public var groupKey: String? {
        switch self {
        case let .sudoku(game): game.puzzle.difficulty.rawValue
        case let .minesweeper(game): game.difficulty.rawValue
        case let .wordScramble(game): String(game.group.length)
        default: nil
        }
    }
    public var canUndo: Bool {
        switch self {
        case let .klondike(game): game.canUndo
        case let .sudoku(game): game.canUndo
        case let .game2048(game): game.canUndo
        default: false
        }
    }
    public mutating func undo() -> Bool {
        switch self {
        case var .klondike(game): let changed = game.undo(); self = .klondike(game); return changed
        case var .sudoku(game): let changed = game.undo(); self = .sudoku(game); return changed
        case var .game2048(game): let changed = game.undo(); self = .game2048(game); return changed
        default: return false
        }
    }
    var validForArchive: Bool {
        switch self {
        case let .blockGrid(game): game.validForArchive
        case let .klondike(game): game.validForArchive
        case let .sudoku(game): game.validForArchive
        case let .game2048(game): game.validForArchive
        case let .minesweeper(game): game.validForArchive
        case let .wordScramble(game): game.validForArchive
        }
    }
}

public struct GameSession: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var state: GameState
    public var hasStarted = false
    public var elapsed: TimeInterval = 0
    public var outcome: SessionOutcome?

    public init(state: GameState) { id = UUID(); self.state = state }
}

public struct GameStatistics: Codable, Equatable, Sendable {
    public var started = 0
    public var completed = 0
    public var won = 0
    public var lost = 0
    public var abandoned = 0
    public var activeTime: TimeInterval = 0
    public var highScore: Int?
    public var highestTile: Int?
    public var target2048Count = 0
    public var bestTime: TimeInterval?
    public var fewestMoves: Int?
    public var streak = 0
    public var longestStreak = 0
    public var winRate: Double? { won + lost > 0 ? Double(won) / Double(won + lost) : nil }
    public init() {}

    var validForArchive: Bool {
        [started, completed, won, lost, abandoned, target2048Count, streak, longestStreak].allSatisfy { $0 >= 0 } &&
        GameLibrary.isValidActiveTime(activeTime) && (bestTime.map(GameLibrary.isValidActiveTime) ?? true)
    }

    mutating func finish(_ session: GameSession, outcome: SessionOutcome, trackStreak: Bool) {
        switch outcome {
        case .abandoned: abandoned += 1
        case .won: completed += 1; won += 1
        case .lost: completed += 1; lost += 1
        }
        if trackStreak {
            streak = outcome == .won ? streak + 1 : 0
            longestStreak = max(longestStreak, streak)
        }
        if let score = session.state.score { highScore = max(highScore ?? score, score) }
        guard outcome != .abandoned else { return }
        if case let .game2048(game) = session.state {
            highestTile = max(highestTile ?? game.highestTile, game.highestTile)
            if game.reached2048 { target2048Count += 1 }
        }
        if outcome == .won {
            bestTime = min(bestTime ?? session.elapsed, session.elapsed)
            if case let .klondike(game) = session.state { fewestMoves = min(fewestMoves ?? game.moves, game.moves) }
        }
    }
}

public struct TitleStatistics: Codable, Equatable, Sendable {
    public var total = GameStatistics()
    public var groups: [String: GameStatistics] = [:]
    public init() {}
}

public enum AppAppearance: String, Codable, CaseIterable, Sendable {
    case system, light, dark
    public var name: String {
        switch self { case .system: "Ikuti Sistem"; case .light: "Terang"; case .dark: "Gelap" }
    }
}

private struct ChallengeBag: Codable, Equatable, Sendable {
    var remaining: [String] = []
    var last: String?
    mutating func draw(from all: [String], using random: inout RandomSource) -> String {
        precondition(!all.isEmpty)
        let available = Set(all)
        remaining.removeAll { !available.contains($0) }
        if remaining.isEmpty {
            remaining = random.shuffled(all)
            if remaining.count > 1 && remaining.last == last { remaining.swapAt(0, remaining.count - 1) }
        }
        let selected = remaining.removeLast()
        last = selected
        return selected
    }
}

public struct GameLibrary: Codable, Equatable, Sendable {
    public static let currentVersion = 1
    /// Upper bound for tracked play time, so every stored duration converts to whole `Int` seconds.
    public static let maxActiveTime = TimeInterval(Int32.max)
    public let version: Int
    public private(set) var sessions: [String: GameSession] = [:]
    public private(set) var statistics: [String: TitleStatistics] = [:]
    public private(set) var lastSudokuDifficulty: SudokuDifficulty = .easy
    public private(set) var lastMineDifficulty: MineDifficulty = .beginner
    public var appearance: AppAppearance = .system
    public var hapticsEnabled = true
    private var random: RandomSource
    private var bags: [String: ChallengeBag] = [:]

    public init(seed: UInt64) { version = Self.currentVersion; random = RandomSource(seed: seed) }
    public func session(_ id: GameID) -> GameSession? { sessions[id.rawValue] }
    public func stats(_ id: GameID) -> TitleStatistics { statistics[id.rawValue] ?? TitleStatistics() }

    public mutating func ensureSession(_ id: GameID, content: GameContent) {
        if session(id) == nil { newGame(id, content: content) }
    }

    public mutating func newGame(_ id: GameID, content: GameContent, sudokuDifficulty: SudokuDifficulty? = nil, mineDifficulty: MineDifficulty? = nil) {
        let seed = random.next()
        let state: GameState
        switch id {
        case .blockGrid: state = .blockGrid(BlockGridGame(seed: seed))
        case .klondike: state = .klondike(KlondikeGame(seed: seed))
        case .game2048: state = .game2048(Game2048(seed: seed))
        case .minesweeper:
            let level = mineDifficulty ?? lastMineDifficulty
            state = .minesweeper(MinesweeperGame(difficulty: level, seed: seed))
            lastMineDifficulty = level
        case .sudoku:
            let level = sudokuDifficulty ?? lastSudokuDifficulty
            let available = content.puzzles.filter { $0.difficulty == level }
            var bag = bags["sudoku-\(level.rawValue)"] ?? ChallengeBag()
            let selected = bag.draw(from: available.map(\.id), using: &random)
            bags["sudoku-\(level.rawValue)"] = bag
            state = .sudoku(SudokuGame(puzzle: available.first { $0.id == selected }!))
            lastSudokuDifficulty = level
        case .wordScramble:
            var bag = bags["words"] ?? ChallengeBag()
            let selected = bag.draw(from: content.wordGroups.map(\.id), using: &random)
            bags["words"] = bag
            state = .wordScramble(WordScrambleGame(group: content.wordGroups.first { $0.id == selected }!, seed: seed))
        }
        if let old = session(id), old.hasStarted && old.outcome == nil { finish(old, outcome: .abandoned) }
        sessions[id.rawValue] = GameSession(state: state)
    }

    @discardableResult public mutating func act(on id: GameID, _ action: (inout GameState) -> Bool) -> Bool {
        guard var session = session(id), session.outcome == nil, action(&session.state) else { return false }
        if !session.hasStarted {
            session.hasStarted = true
            var stats = stats(id)
            stats.total.started += 1
            if let group = session.state.groupKey {
                var bucket = stats.groups[group] ?? GameStatistics()
                bucket.started += 1
                stats.groups[group] = bucket
            }
            statistics[id.rawValue] = stats
        }
        if let outcome = session.state.outcome {
            session.outcome = outcome
            finish(session, outcome: outcome)
        }
        sessions[id.rawValue] = session
        return true
    }

    @discardableResult public mutating func undo(_ id: GameID) -> Bool {
        guard var session = session(id), session.hasStarted, session.outcome == nil, session.state.undo() else { return false }
        sessions[id.rawValue] = session
        return true
    }

    public mutating func addActiveTime(_ seconds: TimeInterval, to id: GameID) {
        guard seconds > 0, seconds.isFinite, var session = session(id), session.hasStarted, session.outcome == nil else { return }
        session.elapsed = min(session.elapsed + seconds, Self.maxActiveTime)
        sessions[id.rawValue] = session
        var stats = stats(id)
        stats.total.activeTime = min(stats.total.activeTime + seconds, Self.maxActiveTime)
        if let group = session.state.groupKey {
            var bucket = stats.groups[group] ?? GameStatistics()
            bucket.activeTime = min(bucket.activeTime + seconds, Self.maxActiveTime)
            stats.groups[group] = bucket
        }
        statistics[id.rawValue] = stats
    }

    public func validate() throws {
        guard version == Self.currentVersion else { throw SaveFileError.unsupportedVersion(version) }
        guard sessions.allSatisfy({ key, session in
            GameID(rawValue: key) == session.state.id && session.state.validForArchive &&
            Self.isValidActiveTime(session.elapsed) &&
            session.outcome == session.state.outcome && (session.outcome == nil || session.hasStarted)
        }), statistics.values.allSatisfy({ $0.total.validForArchive && $0.groups.values.allSatisfy(\.validForArchive) }) else { throw SaveFileError.invalid }
    }

    static func isValidActiveTime(_ seconds: TimeInterval) -> Bool {
        seconds.isFinite && seconds >= 0 && seconds <= maxActiveTime
    }

    private mutating func finish(_ session: GameSession, outcome: SessionOutcome) {
        let id = session.state.id
        var stats = stats(id)
        stats.total.finish(session, outcome: outcome, trackStreak: false)
        if let group = session.state.groupKey {
            var bucket = stats.groups[group] ?? GameStatistics()
            bucket.finish(session, outcome: outcome, trackStreak: id == .minesweeper)
            stats.groups[group] = bucket
        }
        statistics[id.rawValue] = stats
    }
}
