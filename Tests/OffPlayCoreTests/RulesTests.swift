import Foundation
import XCTest
@testable import OffPlayCore

final class GameRulesTests: XCTestCase {
    func testCrossingBlockLinesClearTogether() {
        var board = Array(repeating: 0, count: 64)
        for i in 1..<8 { board[i] = 1; board[i * 8] = 1 }
        var game = BlockGridGame(board: board, tray: [0, 0, 0])
        XCTAssertTrue(game.place(slot: 0, row: 0, column: 0))
        XCTAssertEqual(game.score, 21)
        XCTAssertEqual(game.clearedLines, 2)
        XCTAssertTrue(game.board.allSatisfy { $0 == 0 })
        XCTAssertEqual(game.tray, [nil, 0, 0])
    }

    func testTrayRefillsOnlyAfterAllThreePieces() {
        var game = BlockGridGame(board: Array(repeating: 0, count: 64), tray: [0, 0, 0])
        XCTAssertEqual(BlockGridGame.pieces.count, 19)
        XCTAssertTrue(game.place(slot: 0, row: 0, column: 0))
        let once = game
        XCTAssertFalse(game.place(slot: 1, row: 0, column: 0))
        XCTAssertEqual(game, once)
        XCTAssertTrue(game.place(slot: 1, row: 1, column: 0))
        XCTAssertEqual(game.tray[2], 0)
        XCTAssertTrue(game.place(slot: 2, row: 2, column: 0))
        XCTAssertTrue(game.tray.allSatisfy { $0 != nil })
    }

    func testMergeOccursOnceAndUndoRestoresRandomDraw() {
        var game = Game2048(seed: 12, board: [2, 2, 4, 0] + Array(repeating: 0, count: 12))
        XCTAssertTrue(game.slide(.left))
        XCTAssertEqual(Array(game.board.prefix(2)), [4, 4])
        XCTAssertEqual(game.score, 4)
        let firstDraw = game
        XCTAssertTrue(game.undo())
        XCTAssertTrue(game.slide(.left))
        XCTAssertEqual(game, firstDraw)
    }

    func testUnchangedSlideDoesNotConsumeRandomState() {
        var game = Game2048(seed: 12, board: [2] + Array(repeating: 0, count: 15))
        let before = game
        XCTAssertFalse(game.slide(.left))
        XCTAssertEqual(game, before)
    }

    func test2048AchievementSurvivesUndoWithoutEndingSession() {
        var game = Game2048(seed: 12, board: [1024, 1024, 0, 0] + Array(repeating: 0, count: 12))
        XCTAssertTrue(game.slide(.left))
        XCTAssertTrue(game.reached2048 && !game.isGameOver)
        XCTAssertTrue(game.undo())
        XCTAssertTrue(game.reached2048 && game.highestTile == 1024)
    }

    func testKlondikeDealAndUndo() {
        var game = KlondikeGame(seed: 52)
        XCTAssertEqual(game.tableau.map(\.count), [1, 2, 3, 4, 5, 6, 7])
        XCTAssertEqual(game.stock.count, 24)
        XCTAssertEqual(Set((game.tableau.flatMap { $0 } + game.stock).map(\.id)).count, 52)
        XCTAssertTrue(game.tableau.allSatisfy { $0.filter(\.faceUp).count == 1 })
        let before = game
        XCTAssertTrue(game.draw())
        XCTAssertEqual(game.moves, 1)
        XCTAssertTrue(game.undo())
        XCTAssertEqual(game.tableau, before.tableau)
        XCTAssertEqual(game.stock, before.stock)
        XCTAssertEqual(game.moves, 0)
    }

    func testStockRecyclePreservesOrder() {
        let cards = (1...3).map { PlayingCard(suit: .clubs, rank: $0) }
        var game = KlondikeGame(tableau: Array(repeating: [], count: 7), stock: cards)
        for _ in 0..<3 { XCTAssertTrue(game.draw()) }
        let firstDrawn = game.waste.first
        XCTAssertTrue(game.draw())
        XCTAssertTrue(game.waste.isEmpty)
        XCTAssertTrue(game.draw())
        XCTAssertEqual(game.waste.last?.id, firstDrawn?.id)
    }

    func testMoveUndoIncludesAutomaticCardFlip() {
        let hidden = PlayingCard(suit: .spades, rank: 8)
        let moving = PlayingCard(suit: .hearts, rank: 6, faceUp: true)
        let target = PlayingCard(suit: .clubs, rank: 7, faceUp: true)
        var columns: [[PlayingCard]] = Array(repeating: [], count: 7)
        columns[0] = [hidden, moving]; columns[1] = [target]
        var game = KlondikeGame(tableau: columns)
        XCTAssertFalse(game.move(from: .tableau(column: 0, index: 1), to: .tableau(2)))
        XCTAssertTrue(game.move(from: .tableau(column: 0, index: 1), to: .tableau(1)))
        XCTAssertTrue(game.tableau[0][0].faceUp)
        XCTAssertTrue(game.undo())
        XCTAssertEqual(game.tableau, columns)
        XCTAssertEqual(game.moves, 0)
    }

    func testSudokuNotesAndLocalDuplicateMarkers() {
        let solution = (0..<81).map { ($0 / 9 * 3 + $0 / 9 / 3 + $0 % 9) % 9 + 1 }
        var givens = solution; givens[0] = 0; givens[1] = 0
        var game = SudokuGame(puzzle: SudokuPuzzle(id: "fixture", difficulty: .easy, givens: givens, solution: solution))
        XCTAssertFalse(game.enter(5, at: 2))
        XCTAssertTrue(game.enter(2, at: 0, asNote: true))
        XCTAssertTrue(game.enter(1, at: 0))
        XCTAssertTrue(game.notes[0].isEmpty)
        XCTAssertTrue(game.undo())
        XCTAssertEqual(game.values[0], 0)
        XCTAssertEqual(game.notes[0], [2])
        XCTAssertTrue(game.enter(3, at: 0))
        XCTAssertTrue(game.duplicateCells.contains(0) && game.duplicateCells.contains(2))
        XCTAssertFalse(game.isWon)
    }

    func testFirstMineOpeningAndNeighborsStaySafeWithEarlierFlags() {
        var flagged = MinesweeperGame(seed: 10)
        var plain = MinesweeperGame(seed: 10)
        XCTAssertTrue(flagged.toggleFlag(at: 0))
        XCTAssertTrue(flagged.mines.isEmpty)
        XCTAssertFalse(flagged.reveal(at: 0))
        XCTAssertTrue(flagged.reveal(at: 40))
        XCTAssertTrue(plain.reveal(at: 40))
        XCTAssertEqual(flagged.mines, plain.mines)
        XCTAssertEqual(flagged.mines.count, 10)
        XCTAssertTrue(flagged.flags.contains(0))
        XCTAssertTrue(flagged.mines.isDisjoint(with: Set(flagged.neighbors(of: 40) + [40])))
    }

    func testWrongFlagCanLoseThroughChord() {
        let mines: Set<Int> = [9, 40, 41, 42, 50, 51, 52, 60, 61, 62]
        var game = MinesweeperGame(difficulty: .beginner, mines: mines, revealed: [10], flags: [11])
        XCTAssertEqual(game.adjacentMines(at: 10), 1)
        XCTAssertTrue(game.chord(at: 10))
        XCTAssertTrue(game.isLost)
    }

    func testScrambleAcceptsCuratedAnagrams() {
        var game = WordScrambleGame(group: WordGroup(words: ["saku", "suka", "kuas"]), seed: 1)
        XCTAssertFalse(game.group.words.contains(game.letters.joined()))
        XCTAssertFalse(game.submit())
        XCTAssertEqual(game.guesses, 0)
        for letter in "kuas".map(String.init) {
            let index = game.letters.indices.first { game.letters[$0] == letter && !game.chosen.contains($0) }!
            XCTAssertTrue(game.addLetter(at: index))
        }
        XCTAssertTrue(game.submit())
        XCTAssertTrue(game.isWon)
        XCTAssertEqual(game.guesses, 1)
    }
}

final class SessionTests: XCTestCase {
    private var smallContent: GameContent { GameContent(puzzles: [], wordGroups: [WordGroup(words: ["saku", "suka", "kuas"])]) }

    func testFirstActionStartsSessionAndTerminalCountsOnce() {
        var library = GameLibrary(seed: 1)
        library.ensureSession(.wordScramble, content: smallContent)
        library.addActiveTime(10, to: .wordScramble)
        XCTAssertEqual(library.stats(.wordScramble).total.started, 0)
        XCTAssertEqual(library.session(.wordScramble)?.elapsed, 0)
        for letter in "saku".map(String.init) {
            XCTAssertTrue(library.act(on: .wordScramble) { state in
                guard case var .wordScramble(game) = state else { return false }
                let index = game.letters.indices.first { game.letters[$0] == letter && !game.chosen.contains($0) }!
                let changed = game.addLetter(at: index); state = .wordScramble(game); return changed
            })
            library.addActiveTime(1, to: .wordScramble)
        }
        XCTAssertTrue(library.act(on: .wordScramble) { state in
            guard case var .wordScramble(game) = state else { return false }
            let changed = game.submit(); state = .wordScramble(game); return changed
        })
        XCTAssertFalse(library.act(on: .wordScramble) { _ in true })
        let stats = library.stats(.wordScramble).total
        XCTAssertEqual(stats.started, 1)
        XCTAssertEqual(stats.completed, 1)
        XCTAssertEqual(stats.won, 1)
        XCTAssertEqual(stats.bestTime, 4)
        library.newGame(.wordScramble, content: smallContent)
        XCTAssertEqual(library.stats(.wordScramble).total.abandoned, 0)
    }

    func testReplacingUnplayedBoardDoesNotCountAbandonment() {
        var library = GameLibrary(seed: 1)
        library.newGame(.blockGrid, content: smallContent)
        library.newGame(.blockGrid, content: smallContent)
        XCTAssertEqual(library.stats(.blockGrid).total.started, 0)
        XCTAssertTrue(library.act(on: .blockGrid) { state in
            guard case var .blockGrid(game) = state else { return false }
            let changed = game.place(slot: 0, row: 0, column: 0); state = .blockGrid(game); return changed
        })
        library.newGame(.blockGrid, content: smallContent)
        XCTAssertEqual(library.stats(.blockGrid).total.started, 1)
        XCTAssertEqual(library.stats(.blockGrid).total.abandoned, 1)
        XCTAssertEqual(library.stats(.blockGrid).total.completed, 0)
    }

    func testSaveRoundTripPreservesUndoRandomAndSettings() throws {
        var library = GameLibrary(seed: 12)
        library.ensureSession(.game2048, content: smallContent)
        _ = library.act(on: .game2048) { state in
            guard case var .game2048(game) = state else { return false }
            let changed = game.slide(.down); state = .game2048(game); return changed
        }
        library.addActiveTime(7, to: .game2048)
        library.appearance = .dark; library.hapticsEnabled = false
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LibraryFileStore(url: directory.appendingPathComponent("save.json"))
        try store.save(library)
        let loaded = try XCTUnwrap(try store.load())
        XCTAssertEqual(loaded.library, library)
        XCTAssertFalse(loaded.usedBackup)
    }

    func testCorruptPrimaryRestoresBackupAndNewerVersionIsRejected() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LibraryFileStore(url: directory.appendingPathComponent("save.json"))
        var first = GameLibrary(seed: 1)
        first.ensureSession(.blockGrid, content: smallContent)
        try store.save(first)
        var second = first; second.appearance = .dark
        try store.save(second)
        try Data("truncated".utf8).write(to: store.url)
        let recovered = try XCTUnwrap(try store.load())
        XCTAssertTrue(recovered.usedBackup)
        XCTAssertEqual(recovered.library, first)
        try Data("{\"version\":999}".utf8).write(to: store.url)
        XCTAssertThrowsError(try store.load())
    }

    func testBundledContentMeetsSupplyAndSolvabilityTargets() throws {
        let content = try GameContent.bundled()
        XCTAssertGreaterThanOrEqual(content.wordGroups.count, 300)
        XCTAssertEqual(Set(content.puzzles.map(\.givens)).count, content.puzzles.count)
        for level in SudokuDifficulty.allCases { XCTAssertGreaterThanOrEqual(content.puzzles.filter { $0.difficulty == level }.count, 50) }
        for puzzle in content.puzzles {
            XCTAssertEqual(SudokuAnalysis.solutionCount(puzzle.givens), 1)
            XCTAssertEqual(SudokuAnalysis.difficulty(of: puzzle.givens), puzzle.difficulty)
        }
    }

    func testChallengeBagSurvivesSaveWithoutPrematureRepeats() throws {
        let content = try GameContent.bundled()
        var library = GameLibrary(seed: 5)
        var seen: Set<String> = []
        for index in 0..<50 {
            library.newGame(.sudoku, content: content)
            guard case let .sudoku(game) = library.session(.sudoku)!.state else { return XCTFail("Wrong state") }
            XCTAssertFalse(seen.contains(game.puzzle.id))
            seen.insert(game.puzzle.id)
            if index == 25 { library = try JSONDecoder().decode(GameLibrary.self, from: JSONEncoder().encode(library)) }
        }
        guard case let .sudoku(previous) = library.session(.sudoku)!.state else { return }
        library.newGame(.sudoku, content: content)
        guard case let .sudoku(next) = library.session(.sudoku)!.state else { return }
        XCTAssertNotEqual(next.puzzle.id, previous.puzzle.id)
        XCTAssertEqual(library.stats(.sudoku).total.started, 0)
    }
}
