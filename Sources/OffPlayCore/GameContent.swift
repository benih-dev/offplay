import Foundation

public struct GameContent: Sendable {
    public let puzzles: [SudokuPuzzle]
    public let wordGroups: [WordGroup]

    public init(puzzles: [SudokuPuzzle], wordGroups: [WordGroup]) {
        self.puzzles = puzzles; self.wordGroups = wordGroups
    }

    public static func bundled() throws -> GameContent {
        guard let puzzleURL = Bundle.module.url(forResource: "sudoku", withExtension: "json"),
              let wordsURL = Bundle.module.url(forResource: "words", withExtension: "txt") else { throw ContentError.missing }
        let puzzles = try JSONDecoder().decode([SudokuPuzzle].self, from: Data(contentsOf: puzzleURL))
        let lines = try String(contentsOf: wordsURL, encoding: .utf8).split(whereSeparator: \.isNewline).map(String.init)
        guard lines.allSatisfy({ word in (4...8).contains(word.count) && word.utf8.allSatisfy { (97...122).contains($0) } }) else { throw ContentError.invalid }
        let groups = Dictionary(grouping: Set(lines), by: { String($0.sorted()) }).values
            .map { WordGroup(words: Array($0)) }.filter { Set($0.id).count > 1 }.sorted { $0.id < $1.id }
        guard groups.count >= 300, Set(puzzles.map(\.id)).count == puzzles.count,
              SudokuDifficulty.allCases.allSatisfy({ level in puzzles.filter { $0.difficulty == level }.count >= 50 }),
              puzzles.allSatisfy({ puzzle in
                  puzzle.givens.count == 81 && puzzle.solution.count == 81 &&
                  !puzzle.solution.contains(0) && SudokuAnalysis.isValid(puzzle.solution) &&
                  puzzle.givens.indices.allSatisfy { puzzle.givens[$0] == 0 || puzzle.givens[$0] == puzzle.solution[$0] }
              }) else { throw ContentError.invalid }
        return GameContent(puzzles: puzzles, wordGroups: groups)
    }
}

public enum ContentError: Error, LocalizedError {
    case missing, invalid
    public var errorDescription: String? { "Konten permainan belum dapat dibaca." }
}
