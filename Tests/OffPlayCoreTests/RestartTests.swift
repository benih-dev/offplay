import XCTest
@testable import OffPlayCore

final class RestartTests: XCTestCase {
    func testRestartPreservesHighScoreForBothScoredGames() throws {
        let content = try GameContent.bundled()
        for id in [GameID.game2048, .blockGrid] {
            var library = GameLibrary(seed: 42)
            library.ensureSession(id, content: content)
            library.newGame(id, content: content)
            XCTAssertNil(library.stats(id).total.highScore)
            XCTAssertEqual(library.stats(id).total.abandoned, 0)

            var best = 0
            for round in 0..<3 {
                XCTAssertTrue(library.act(on: id) { state in
                    if id == .game2048 {
                        let tile = round == 1 ? 8 : 2
                        var game = Game2048(seed: 1, board: [tile, tile] + Array(repeating: 0, count: 14))
                        let changed = game.slide(.left)
                        state = .game2048(game)
                        return changed
                    } else {
                        var game = BlockGridGame(board: Array(repeating: 0, count: 64), tray: [round == 1 ? 7 : 0, 0, 0])
                        let changed = game.place(slot: 0, row: 0, column: 0)
                        state = .blockGrid(game)
                        return changed
                    }
                })
                let old = try XCTUnwrap(library.session(id))
                XCTAssertNil(old.outcome)
                best = max(best, try XCTUnwrap(old.state.score))
                library.newGame(id, content: content)
                XCTAssertEqual(library.stats(id).total.highScore, best, "\(id) round \(round)")
                XCTAssertEqual(library.stats(id).total.abandoned, round + 1)
                XCTAssertEqual(library.stats(id).total.completed, 0)
                XCTAssertNotEqual(library.session(id)?.id, old.id)
                XCTAssertEqual(library.session(id)?.state.score, 0)
                let restored = try JSONDecoder().decode(GameLibrary.self, from: JSONEncoder().encode(library))
                XCTAssertEqual(restored.stats(id).total.highScore, best)
            }
        }
    }
}
