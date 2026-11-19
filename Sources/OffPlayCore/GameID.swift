import Foundation

public enum GameID: String, Codable, CaseIterable, Identifiable, Sendable {
    case blockGrid, klondike, sudoku, game2048, minesweeper, wordScramble

    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .blockGrid: "Block Grid"
        case .klondike: "Klondike Solitaire"
        case .sudoku: "Sudoku"
        case .game2048: "2048"
        case .minesweeper: "Minesweeper"
        case .wordScramble: "Word Scramble"
        }
    }
    public var description: String {
        switch self {
        case .blockGrid: "Susun keping, bersihkan garis."
        case .klondike: "Susun kartu dari Ace ke King."
        case .sudoku: "Lengkapi angka tanpa duplikasi."
        case .game2048: "Geser dan gabungkan angka."
        case .minesweeper: "Buka petak, hindari ranjau."
        case .wordScramble: "Temukan kata bahasa Indonesia."
        }
    }
}

public enum SudokuDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy, medium, hard
    public var id: String { rawValue }
    public var name: String {
        switch self { case .easy: "Mudah"; case .medium: "Sedang"; case .hard: "Sulit" }
    }
}

public enum MineDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case beginner, intermediate
    public var id: String { rawValue }
    public var name: String { self == .beginner ? "Pemula" : "Menengah" }
    public var side: Int { self == .beginner ? 9 : 16 }
    public var mineCount: Int { self == .beginner ? 10 : 40 }
}

public enum SessionOutcome: String, Codable, Sendable {
    case won, lost, abandoned
    public var name: String {
        switch self { case .won: "Menang"; case .lost: "Kalah"; case .abandoned: "Ditinggalkan" }
    }
}
