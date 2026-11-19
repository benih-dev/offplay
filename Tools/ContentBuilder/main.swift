import Foundation
import OffPlayCore

enum BuilderError: Error { case missingOutput, couldNotFindDifficulty, existingFile }

func transformed(_ grid: [Int], using random: inout RandomSource) -> [Int] {
    let digits = [0] + random.shuffled(Array(1...9))
    let bands = random.shuffled(Array(0..<3))
    let stacks = random.shuffled(Array(0..<3))
    let rows = bands.flatMap { band in random.shuffled(Array(0..<3)).map { band * 3 + $0 } }
    let columns = stacks.flatMap { stack in random.shuffled(Array(0..<3)).map { stack * 3 + $0 } }
    let transpose = random.integer(lessThan: 2) == 0
    return (0..<81).map { index in
        let r = rows[index / 9], c = columns[index % 9]
        return digits[grid[transpose ? c * 9 + r : r * 9 + c]]
    }
}

func build() throws {
    guard CommandLine.arguments.count == 2 else { throw BuilderError.missingOutput }
    if CommandLine.arguments[1] == "--validate" {
        let content = try GameContent.bundled()
        guard content.puzzles.allSatisfy({ SudokuAnalysis.solutionCount($0.givens) == 1 && SudokuAnalysis.difficulty(of: $0.givens) == $0.difficulty }) else { throw BuilderError.couldNotFindDifficulty }
        print("Validated \(content.puzzles.count) Sudoku puzzles and \(content.wordGroups.count) Indonesian letter groups")
        return
    }
    let output = URL(fileURLWithPath: CommandLine.arguments[1])
    guard !FileManager.default.fileExists(atPath: output.path) else { throw BuilderError.existingFile }
    var random = RandomSource(seed: 0x4f6666506c6179)
    var bases: [SudokuDifficulty: (givens: [Int], solution: [Int])] = [:]
    for attempt in 1...5000 {
        let solution = SudokuAnalysis.makeSolution(using: &random)
        var givens = solution
        for cell in random.shuffled(Array(0..<81)) {
            let digit = givens[cell]
            givens[cell] = 0
            if SudokuAnalysis.solutionCount(givens) != 1 { givens[cell] = digit }
        }
        if let level = SudokuAnalysis.difficulty(of: givens), bases[level] == nil {
            bases[level] = (givens, solution)
            print("Found \(level.rawValue) base at attempt \(attempt), \(givens.filter { $0 != 0 }.count) clues")
        }
        if bases.count == 3 { break }
    }
    guard bases.count == 3 else { throw BuilderError.couldNotFindDifficulty }
    var puzzles: [SudokuPuzzle] = []
    var seen: Set<[Int]> = []
    for level in SudokuDifficulty.allCases {
        guard let base = bases[level] else { throw BuilderError.couldNotFindDifficulty }
        var count = 0
        for _ in 0..<5000 {
            // Transform givens and solution with the exact same permutation/RNG state.
            let state = random
            let givens = transformed(base.givens, using: &random)
            var same = state
            let solution = transformed(base.solution, using: &same)
            guard !seen.contains(givens), SudokuAnalysis.difficulty(of: givens) == level,
                  SudokuAnalysis.solutionCount(givens) == 1 else { continue }
            seen.insert(givens)
            count += 1
            puzzles.append(SudokuPuzzle(id: "\(level.rawValue)-\(count)", difficulty: level, givens: givens, solution: solution))
            if count == 50 { break }
        }
        guard count == 50 else { throw BuilderError.couldNotFindDifficulty }
        print("Validated \(count) distinct \(level.rawValue) puzzles")
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    try encoder.encode(puzzles).write(to: output, options: .atomic)
    print("Wrote \(puzzles.count) offline puzzles to \(output.path)")
}

do { try build() }
catch { print("Content build failed: \(error)"); exit(1) }
