import XCTest
import OffPlayCore
import UIKit

final class OffPlayUITests: XCTestCase {
    @MainActor func testFeedbackDoesNotMoveBoard() {
        let app = launch()
        open("blockGrid", in: app)
        app.buttons["block.piece.0"].tap()
        let board = app.descendants(matching: .any)["session.board"].firstMatch
        XCTAssertTrue(board.exists)
        let frame = board.frame.integral
        XCTAssertFalse(app.staticTexts["session.feedback"].exists)
        app.buttons["block.cell.63"].tap()
        XCTAssertTrue(app.staticTexts["session.feedback"].waitForExistence(timeout: 5))
        XCTAssertEqual(board.frame.integral, frame)
        app.buttons["block.cell.0"].tap()
        XCTAssertFalse(app.staticTexts["session.feedback"].exists)
        XCTAssertEqual(board.frame.integral, frame)
    }

    @MainActor private func putAceOnFoundation(in app: XCUIApplication) throws -> CardSuit {
        open("klondike", in: app)
        var library = GameLibrary(seed: 42)
        library.ensureSession(.klondike, content: try GameContent.bundled())
        guard case var .klondike(game)? = library.session(.klondike)?.state else {
            throw NSError(domain: "Expected Klondike session", code: 1)
        }
        while !game.stock.isEmpty {
            game.draw()
            app.buttons["cards.stock"].tap()
            if let card = game.waste.last, card.rank == 1 {
                app.buttons["cards.waste"].tap()
                app.buttons["cards.foundation.\(card.suit.rawValue)"].tap()
                return card.suit
            }
        }
        throw NSError(domain: "Expected an ace in the seeded stock", code: 1)
    }

    @MainActor func testKlondikeSelectedPileRetapDeselects() throws {
        let app = launch()
        let suit = try putAceOnFoundation(in: app)
        let foundation = app.buttons["cards.foundation.\(suit.rawValue)"]
        let emptyFoundation = app.buttons["cards.foundation.\((suit.rawValue + 1) % 4)"]
        XCTAssertFalse(emptyFoundation.isEnabled)
        for pile in [app.buttons["cards.tableau.0.0"], app.buttons["cards.waste"], foundation] {
            if pile.identifier == "cards.waste" { app.buttons["cards.stock"].tap() }
            pile.tap()
            XCTAssertTrue(emptyFoundation.isEnabled)
            pile.tap()
            XCTAssertFalse(app.staticTexts["session.feedback"].exists)
            XCTAssertFalse(emptyFoundation.isEnabled, "Re-tapping a selected pile should clear selection")
        }
    }

    @MainActor private func endBlockGrid(in app: XCUIApplication) throws {
        var library = GameLibrary(seed: 42)
        library.ensureSession(.blockGrid, content: try GameContent.bundled())
        guard case var .blockGrid(game)? = library.session(.blockGrid)?.state else {
            return XCTFail("Expected Block Grid session")
        }
        open("blockGrid", in: app)
        XCTAssertFalse(app.staticTexts["session.result"].exists)
        var moves = 0
        while !game.isGameOver && moves < 100 {
            let move = try XCTUnwrap((0..<3).flatMap { slot in
                (0..<64).map { (slot: slot, cell: $0) }
            }.first { game.canPlace(slot: $0.slot, row: $0.cell / 8, column: $0.cell % 8) })
            let piece = app.buttons["block.piece.\(move.slot)"]
            let footer = app.buttons["session.rules"]
            for _ in 0..<4 where piece.frame.maxY > footer.frame.minY - 8 {
                app.swipeUp()
            }
            XCTAssertLessThanOrEqual(piece.frame.maxY, footer.frame.minY - 8)
            piece.tap()
            XCTAssertEqual(piece.value as? String, "selected")
            app.buttons["block.cell.\(move.cell)"].tap()
            XCTAssertTrue(game.place(slot: move.slot, row: move.cell / 8, column: move.cell % 8))
            moves += 1
        }
        XCTAssertTrue(game.isGameOver)
        XCTAssertTrue(app.staticTexts["session.result"].waitForExistence(timeout: 5))
    }

    @MainActor func testBlockGridEndedStatus() throws {
        let app = launch()
        XCTAssertEqual(app.buttons["catalog.blockGrid"].label, "Block Grid, Ready to play")
        try endBlockGrid(in: app)
        XCTAssertEqual(app.staticTexts["session.result"].label, "Session ended")
        app.buttons["session.back"].tap()
        XCTAssertEqual(app.buttons["catalog.blockGrid"].label, "Block Grid, Session ended")
    }

    @MainActor func testIndonesianStatisticsLabels() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-data", "-theme", "light", "-AppleLanguages", "(id)", "-AppleLocale", "id_ID"]
        app.launch()
        XCTAssertTrue(app.buttons["catalog.statistics"].waitForExistence(timeout: 10))
        open("minesweeper", in: app)
        app.buttons["mines.cell.0"].tap()
        app.buttons["session.new"].tap()
        app.buttons["new.confirm"].tap()
        app.buttons["session.back"].tap()
        app.buttons["catalog.statistics"].tap()
        let winRate = app.staticTexts["stats.winRate.label"].firstMatch
        let streak = app.staticTexts["stats.streak.label"].firstMatch
        let longestStreak = app.staticTexts["stats.longestStreak.label"].firstMatch
        for _ in 0..<16 where !streak.isHittable { app.swipeUp(velocity: .slow) }
        XCTAssertTrue(winRate.isHittable)
        XCTAssertTrue(streak.isHittable)
        XCTAssertTrue(longestStreak.isHittable)
        let offset = (app.frame.height * 0.54 - winRate.frame.midY) / app.frame.height
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5 + offset)))
        Thread.sleep(forTimeInterval: 2)
        attach(app, name: "Indonesian Statistics")
        XCTAssertEqual(winRate.label, "Tingkat menang")
        XCTAssertEqual(streak.label, "Beruntun")
        XCTAssertEqual(longestStreak.label, "Beruntun terpanjang")
    }

    @MainActor func test2048RestartKeepsHighScore() throws {
        let app = launch()
        open("game2048", in: app)
        for direction in ["left", "up", "right", "down", "left", "up"] {
            app.buttons["slide.\(direction)"].tap()
        }
        let scoreLabel = app.descendants(matching: .any)["session.score"].label
        let score = try XCTUnwrap(scoreLabel.split(whereSeparator: { !$0.isNumber }).last.flatMap { Int($0) })
        XCTAssertGreaterThan(score, 0)
        Thread.sleep(forTimeInterval: 2)
        attach(app, name: "2048 earned score")
        app.buttons["session.new"].tap()
        app.buttons["new.confirm"].tap()
        app.buttons["session.back"].tap()
        app.buttons["catalog.statistics"].tap()
        let terminalTile = app.staticTexts["stats.game2048.highestTile"]
        for _ in 0..<12 where !terminalTile.isHittable {
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(terminalTile.isHittable)
        let record = app.staticTexts["stats.game2048.highScore"]
        Thread.sleep(forTimeInterval: 2)
        attach(app, name: "2048 high score after restart")
        XCTAssertEqual(record.label, String(score))
    }

    @MainActor func testEnglishFallbackAndIndonesianLocalization() {
        let app = launch(language: "fr")
        XCTAssertTrue(app.staticTexts["Six games for your downtime."].exists)
        open("minesweeper", in: app)
        XCTAssertTrue(app.staticTexts["Beginner"].exists)
        XCTAssertEqual(app.buttons["session.new"].label, "New Game")
        app.buttons["session.back"].tap()
        app.buttons["catalog.settings"].tap()
        XCTAssertTrue(app.buttons["settings.theme.system"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["settings.theme.system"].label, "Follow System")
        app.terminate()

        let indonesian = launch(language: "id")
        XCTAssertTrue(indonesian.staticTexts["Enam permainan untuk waktu luangmu."].exists)
        open("minesweeper", in: indonesian)
        XCTAssertTrue(indonesian.staticTexts["Pemula"].exists)
        XCTAssertTrue(indonesian.staticTexts["Bendera 0/10"].exists)
        XCTAssertEqual(indonesian.buttons["session.new"].label, "Mulai Baru")
        indonesian.buttons["session.back"].tap()
        indonesian.buttons["catalog.settings"].tap()
        XCTAssertTrue(indonesian.buttons["settings.theme.system"].waitForExistence(timeout: 5))
        XCTAssertEqual(indonesian.buttons["settings.theme.system"].label, "Ikuti Sistem")
    }

    @MainActor func testMinesweeperLossMarksExplodedMine() throws {
        let app = launch()
        open("minesweeper", in: app)
        var library = GameLibrary(seed: 42)
        library.ensureSession(.minesweeper, content: try GameContent.bundled())
        guard case var .minesweeper(game)? = library.session(.minesweeper)?.state else {
            return XCTFail("Expected Minesweeper session")
        }
        game.reveal(at: 0)
        let mine = try XCTUnwrap(game.mines.sorted().first { app.buttons["mines.cell.\($0)"].isHittable })
        XCTAssertFalse(app.buttons["mines.cell.\(mine)"].label.contains("exploded"))
        app.buttons["mines.cell.0"].tap()
        app.buttons["mines.cell.\(mine)"].tap()
        XCTAssertEqual(app.staticTexts["session.result"].label, "Lost")
        XCTAssertTrue(app.buttons["mines.cell.\(mine)"].label.contains("exploded mine"))
        let otherMine = try XCTUnwrap(game.mines.sorted().first { $0 != mine && app.buttons["mines.cell.\($0)"].exists })
        XCTAssertTrue(app.buttons["mines.cell.\(otherMine)"].label.hasSuffix("mine"))
    }

    @MainActor func testSettingsFollowSystemUpdatesOpenSheet() {
        let app = launch(theme: "dark")
        app.buttons["catalog.settings"].tap()
        XCTAssertTrue(app.buttons["settings.theme.system"].waitForExistence(timeout: 5))
        assertAppearance(in: app, light: false)
        app.buttons["settings.theme.system"].tap()
        assertAppearance(in: app, light: true)
        app.buttons["settings.theme.dark"].tap()
        assertAppearance(in: app, light: false)
        app.buttons["settings.theme.light"].tap()
        assertAppearance(in: app, light: true)
        app.buttons["settings.done"].tap()
        assertAppearance(in: app, light: true)
    }

    @MainActor func testCatalogUtilityFollowsAppearanceChanges() {
        let app = launch()
        let settings = app.buttons["catalog.settings"]
        assertAppearance(in: settings, light: true, sampleButtonFill: true)
        settings.tap()
        app.buttons["settings.theme.dark"].tap()
        app.buttons["settings.done"].tap()
        assertAppearance(in: settings, light: false, sampleButtonFill: true)
        settings.tap()
        app.buttons["settings.theme.light"].tap()
        app.buttons["settings.done"].tap()
        assertAppearance(in: settings, light: true, sampleButtonFill: true)
    }

    @MainActor private func assertAppearance(
        in element: XCUIElement,
        light: Bool,
        sampleButtonFill: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matches = NSPredicate { _, _ in
            guard element.isHittable, var image = element.screenshot().image.cgImage else { return false }
            if sampleButtonFill {
                // Sample inside the outline but outside the centered symbol.
                let sample = CGRect(x: image.width / 6, y: image.height / 2, width: 1, height: 1)
                guard let fill = image.cropping(to: sample) else { return false }
                image = fill
            }
            var pixel = [UInt8](repeating: 0, count: 4)
            let brightness = pixel.withUnsafeMutableBytes { bytes -> Double in
                guard let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return 0 }
                context.interpolationQuality = .high
                context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
                return Double(bytes[0]) / 255
            }
            return light ? brightness > 0.5 : brightness < 0.5
        }
        let expectation = XCTNSPredicateExpectation(predicate: matches, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, "Expected \(light ? "light" : "dark") appearance", file: file, line: line)
    }

    @MainActor private func launch(reset: Bool = true, theme: String = "light", language: String = "en") -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-theme", theme, "-AppleLanguages", "(\(language))"] + (reset ? ["-reset-data"] : [])
        app.launch()
        XCTAssertTrue(app.buttons["catalog.blockGrid"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func open(_ id: String, in app: XCUIApplication) {
        let button = app.buttons["catalog.\(id)"]
        for _ in 0..<4 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(app.buttons["session.back"].waitForExistence(timeout: 5))
    }

    @MainActor func testAllSixGamesAcceptPlayActions() {
        let app = launch()
        open("blockGrid", in: app)
        app.buttons["block.piece.0"].tap()
        app.buttons["block.cell.0"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["session.score"].exists)
        app.buttons["session.back"].tap()

        open("klondike", in: app)
        app.buttons["cards.stock"].tap()
        XCTAssertTrue(app.buttons["session.undo"].isEnabled)
        app.buttons["session.undo"].tap()
        XCTAssertFalse(app.buttons["session.undo"].isEnabled)
        app.buttons["session.back"].tap()

        open("sudoku", in: app)
        let emptyCell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sudoku.cell.' AND value == 'empty'")).firstMatch
        XCTAssertTrue(emptyCell.exists)
        emptyCell.tap()
        app.buttons["sudoku.digit.1"].tap()
        XCTAssertTrue(app.buttons["session.undo"].isEnabled)
        app.buttons["session.undo"].tap()
        app.buttons["sudoku.notes"].tap()
        app.buttons["sudoku.digit.2"].tap()
        app.buttons["sudoku.erase"].tap()
        app.buttons["session.back"].tap()

        open("game2048", in: app)
        app.buttons["slide.down"].tap()
        if !app.buttons["session.undo"].isEnabled { app.buttons["slide.left"].tap() }
        XCTAssertTrue(app.buttons["session.undo"].isEnabled)
        app.buttons["session.undo"].tap()
        app.buttons["session.back"].tap()

        open("minesweeper", in: app)
        app.buttons["mines.flagMode"].tap()
        app.buttons["mines.cell.0"].tap()
        app.buttons["mines.flagMode"].tap()
        app.buttons["mines.cell.1"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["session.result"].exists)
        app.buttons["session.back"].tap()

        open("wordScramble", in: app)
        app.buttons["word.letter.0"].tap()
        XCTAssertTrue(app.buttons["word.answer.0"].isEnabled)
        app.buttons["word.answer.0"].tap()
        XCTAssertFalse(app.buttons["word.answer.0"].isEnabled)
        attach(app, name: "Word Scramble")
    }

    @MainActor func testKlondikeUndoClearsWasteSelection() {
        let app = launch()
        open("klondike", in: app)
        app.buttons["cards.stock"].tap()
        app.buttons["cards.waste"].tap()
        app.buttons["session.undo"].tap()
        XCTAssertFalse(app.buttons["cards.waste"].isEnabled)
        app.buttons["cards.tableau.0.0"].tap()
        XCTAssertFalse(app.staticTexts["That move isn’t allowed."].exists)
        app.buttons["cards.tableau.0.0"].tap()
        XCTAssertFalse(app.staticTexts["That move isn’t allowed."].exists)
        app.buttons["cards.tableau.1.1"].tap()
        app.buttons["cards.tableau.5.5"].tap()
        XCTAssertTrue(app.buttons["cards.tableau.5.6"].exists)
        XCTAssertFalse(app.staticTexts["That move isn’t allowed."].exists)
    }

    @MainActor func testCancelNewGameAndRelaunchPreserveProgress() {
        let app = launch()
        open("blockGrid", in: app)
        app.buttons["block.piece.0"].tap()
        app.buttons["block.cell.0"].tap()
        let score = app.descendants(matching: .any)["session.score"].label
        app.buttons["session.new"].tap()
        XCTAssertTrue(app.buttons["new.cancel"].waitForExistence(timeout: 5))
        app.buttons["new.cancel"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["session.score"].label, score)
        app.buttons["session.pause"].tap()
        XCTAssertTrue(app.buttons["pause.resume"].waitForExistence(timeout: 5))
        app.buttons["pause.resume"].tap()
        app.buttons["session.back"].tap()
        app.terminate()
        app.launchArguments.removeAll { $0 == "-reset-data" }
        app.launch()
        XCTAssertTrue(app.buttons["catalog.blockGrid"].waitForExistence(timeout: 10))
        open("blockGrid", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["session.score"].label, score)
        app.buttons["session.new"].tap()
        app.buttons["new.confirm"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["session.score"].label.contains("0"))
        app.buttons["session.back"].tap()
        app.buttons["catalog.statistics"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == 'Abandoned'")).firstMatch.exists)
        app.buttons["stats.done"].tap()
    }

    @MainActor func testSettingsAndEmptyStatisticsInDarkTheme() {
        let app = launch(theme: "dark")
        app.buttons["catalog.statistics"].tap()
        XCTAssertTrue(app.staticTexts["stats.empty.blockGrid"].waitForExistence(timeout: 5))
        app.buttons["stats.done"].tap()
        app.buttons["catalog.settings"].tap()
        app.buttons["settings.theme.light"].tap()
        app.buttons["settings.theme.dark"].tap()
        app.switches["settings.haptics"].tap()
        attach(app, name: "Settings Dark")
        app.buttons["settings.done"].tap()
        attach(app, name: "Game Box Dark")
    }

    @MainActor func testStatisticsOnlyShowRowsAfterPlaying() {
        let app = launch()
        let empty = app.staticTexts["stats.empty.blockGrid"]
        let started = app.staticTexts["stats.blockGrid.started"]
        let highScore = app.staticTexts["stats.blockGrid.highScore"]

        app.buttons["catalog.statistics"].tap()
        XCTAssertTrue(empty.waitForExistence(timeout: 5))
        XCTAssertFalse(started.exists)
        XCTAssertFalse(highScore.exists)
        app.buttons["stats.done"].tap()

        open("blockGrid", in: app)
        app.buttons["block.piece.0"].tap()
        app.buttons["block.cell.0"].tap()
        app.buttons["session.back"].tap()

        app.buttons["catalog.statistics"].tap()
        XCTAssertTrue(started.waitForExistence(timeout: 5))
        XCTAssertEqual(started.label, "1")
        XCTAssertTrue(highScore.exists)
        XCTAssertFalse(empty.exists)
        XCTAssertTrue(app.staticTexts["stats.empty.klondike"].exists)
        XCTAssertFalse(app.staticTexts["stats.klondike.started"].exists)
    }

    @MainActor func testWordResultPersistsAndNewGameDoesNotAskToAbandon() throws {
        let app = launch()
        open("wordScramble", in: app)
        try solveWord(in: app)
        XCTAssertTrue(app.staticTexts["session.result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["session.result"].label, "Won")
        attach(app, name: "Word Scramble Result")
        app.buttons["session.back"].tap()
        app.terminate()
        app.launchArguments.removeAll { $0 == "-reset-data" }
        app.launch()
        XCTAssertTrue(app.buttons["catalog.blockGrid"].waitForExistence(timeout: 10))
        open("wordScramble", in: app)
        XCTAssertEqual(app.staticTexts["session.result"].label, "Won")
        app.buttons["session.new"].tap()
        XCTAssertFalse(app.buttons["new.confirm"].exists)
        XCTAssertFalse(app.staticTexts["session.result"].exists)
    }

    @MainActor func testWordScrambleWinShowsCleanSolvedState() throws {
        let app = launch()
        open("wordScramble", in: app)
        let answer = try solveWord(in: app)
        XCTAssertTrue(app.staticTexts["session.result"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["word.submit"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'word.letter.'")).firstMatch.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'word.answer.'")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["word.hint"].exists)
        let solved = app.descendants(matching: .any)["word.solved"]
        XCTAssertTrue(solved.exists)
        XCTAssertEqual(solved.value as? String, answer)
        XCTAssertTrue(app.staticTexts["word.guesses"].exists)
        attach(app, name: "Word Scramble Solved")
        app.buttons["session.new"].tap()
        XCTAssertTrue(app.buttons["word.letter.0"].waitForExistence(timeout: 5))
        XCTAssertFalse(solved.exists)
        XCTAssertTrue(app.buttons["word.submit"].exists)
    }

    @discardableResult @MainActor private func solveWord(in app: XCUIApplication) throws -> String {
        let content = try GameContent.bundled()
        var available: [(index: Int, letter: String)] = []
        for index in 0..<8 {
            let button = app.buttons["word.letter.\(index)"]
            if button.exists {
                let letter = try XCTUnwrap(button.label.split(separator: ",").first?.split(separator: " ").last).lowercased()
                available.append((index, letter))
            }
        }
        let key = available.map(\.letter).sorted().joined()
        let answer = try XCTUnwrap(content.wordGroups.first { $0.id == key }?.words.first)
        for letter in answer.map(String.init) {
            let position = try XCTUnwrap(available.firstIndex { $0.letter == letter })
            app.buttons["word.letter.\(available[position].index)"].tap()
            available.remove(at: position)
        }
        let submit = app.buttons["word.submit"]
        if !submit.isHittable { app.swipeUp() }
        XCTAssertTrue(submit.isEnabled)
        submit.tap()
        return answer
    }

    @MainActor func testSudokuNewGameShowsAllControlsWithoutScrolling() {
        let app = launch()
        open("sudoku", in: app)
        let cell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sudoku.cell.' AND value == 'empty'")).firstMatch
        cell.tap()
        let digit = app.buttons["sudoku.digit.1"]
        for _ in 0..<5 where !digit.isHittable { app.swipeUp() }
        digit.tap()
        XCTAssertTrue(app.buttons["session.undo"].isEnabled)

        assertNewGameControls(in: app, difficultyIDs: ["new.sudoku.easy", "new.sudoku.medium", "new.sudoku.hard"], screenshot: "Sudoku New Game")
        XCTAssertTrue(app.buttons["session.undo"].isEnabled)
    }

    @MainActor func testMinesweeperNewGameShowsAllControlsWithoutScrolling() {
        let app = launch()
        open("minesweeper", in: app)
        app.buttons["mines.flagMode"].tap()
        let cell = app.buttons["mines.cell.0"]
        cell.tap()
        XCTAssertTrue(cell.label.contains("flagged"))

        assertNewGameControls(in: app, difficultyIDs: ["new.mines.beginner", "new.mines.intermediate"], screenshot: "Minesweeper New Game")
        XCTAssertTrue(cell.label.contains("flagged"))
    }

    @MainActor private func assertNewGameControls(in app: XCUIApplication, difficultyIDs: [String], screenshot: String) {
        app.buttons["session.new"].tap()
        let sheet = app.scrollViews.containing(.button, identifier: "new.confirm").firstMatch
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        attach(app, name: screenshot)
        let viewport = sheet.frame.intersection(app.frame)
        for id in difficultyIDs + ["new.confirm", "new.cancel"] {
            let button = app.buttons[id]
            XCTAssertTrue(button.isHittable && viewport.contains(button.frame), "\(id) should be fully visible without scrolling")
        }
        app.buttons["new.cancel"].tap()
        XCTAssertTrue(app.buttons["new.cancel"].waitForNonExistence(timeout: 5))
    }

    @MainActor func testPauseFreezesClockAndNewGameChangesDifficulty() {
        let app = launch()
        open("minesweeper", in: app)
        app.buttons["mines.flagMode"].tap()
        app.buttons["mines.cell.0"].tap()
        app.buttons["session.pause"].tap()
        let time = app.staticTexts["pause.time"]
        XCTAssertTrue(time.waitForExistence(timeout: 5))
        let paused = time.label
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertEqual(time.label, paused)
        app.buttons["pause.resume"].tap()
        app.buttons["session.new"].tap()
        app.buttons["new.mines.intermediate"].tap()
        if !app.buttons["new.confirm"].isHittable { app.swipeUp() }
        app.buttons["new.confirm"].tap()
        XCTAssertTrue(app.staticTexts["Intermediate"].waitForExistence(timeout: 5))
        attach(app, name: "Minesweeper Intermediate")
        app.buttons["session.pause"].tap()
        app.buttons["pause.catalog"].tap()
        open("sudoku", in: app)
        app.buttons["session.new"].tap()
        app.buttons["new.sudoku.hard"].tap()
        if !app.buttons["new.confirm"].isHittable { app.swipeUp() }
        app.buttons["new.confirm"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Hard ·'")).firstMatch.waitForExistence(timeout: 5))
        attach(app, name: "Sudoku Hard")
    }

    @MainActor private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testLayoutAtPreferredTextSize() {
        let app = launch()
        attach(app, name: "Compact Game Box")
        open("blockGrid", in: app)
        app.buttons["block.piece.0"].tap()
        assertBoardFits(app, prefix: "block", columns: 8)
        attach(app, name: "Compact Block Grid")
        app.buttons["session.back"].tap()
        open("klondike", in: app)
        XCTAssertGreaterThanOrEqual(app.buttons["cards.stock"].frame.width, 44)
        attach(app, name: "Compact Klondike")
        app.buttons["session.back"].tap()
        open("sudoku", in: app)
        assertBoardFits(app, prefix: "sudoku", columns: 9)
        let digit = app.buttons["sudoku.digit.1"]
        for _ in 0..<5 where !digit.isHittable { app.swipeUp() }
        XCTAssertTrue(digit.isHittable)
        attach(app, name: "Compact Sudoku")
        app.buttons["session.back"].tap()
        open("minesweeper", in: app)
        assertBoardFits(app, prefix: "mines", columns: 9)
        app.buttons["session.new"].tap()
        app.buttons["new.mines.intermediate"].tap()
        if !app.buttons["new.confirm"].isHittable { app.swipeUp() }
        app.buttons["new.confirm"].tap()
        XCTAssertTrue(app.staticTexts["Intermediate"].waitForExistence(timeout: 5))
        let first = app.buttons["mines.cell.0"]
        let second = app.buttons["mines.cell.1"]
        let last = app.buttons["mines.cell.15"]
        XCTAssertEqual(second.frame.midX - first.frame.midX, 36, accuracy: 0.1)
        XCTAssertFalse(last.isHittable)
        app.buttons["mines.flagMode"].tap()
        first.tap()
        XCTAssertTrue(first.label.contains("flagged"))
        let board = app.scrollViews["board.viewport"]
        board.swipeLeft()
        XCTAssertTrue(last.isHittable)
        last.tap()
        XCTAssertTrue(last.label.contains("flagged"))
        print("BOARD MEASUREMENT mines 16 columns: 36.0pt on \(app.frame.width)pt screen (scrolling)")
    }

    @MainActor func testKlondikeColumnsFitScreen() {
        let app = launch()
        open("klondike", in: app)
        let cards = (0..<7).map { column in
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cards.tableau.\(column).")).firstMatch
        } + [app.buttons["cards.stock"], app.buttons["cards.waste"]]
            + (0..<4).map { app.buttons["cards.foundation.\($0)"] }
        for card in cards {
            XCTAssertTrue(card.exists)
            XCTAssertGreaterThanOrEqual(card.frame.width, 44)
            XCTAssertGreaterThanOrEqual(card.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(card.frame.maxX, app.frame.maxX)
            XCTAssertGreaterThanOrEqual(card.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(card.frame.maxY, app.frame.maxY)
        }
        print("BOARD MEASUREMENT klondike 7 columns: \(cards[6].frame.width)pt cards on \(app.frame.width)pt screen; last column maxX \(cards[6].frame.maxX), last foundation maxX \(cards.last!.frame.maxX)")
        attach(app, name: "Fitted Klondike")
    }

    @MainActor func testGameplayControlsDoNotIntersectFooterInitially() {
        let app = launch()
        for game in ["blockGrid", "klondike", "sudoku", "game2048", "minesweeper", "wordScramble"] {
            open(game, in: app)
            let footer = app.otherElements["session.footer"].frame
            let controls = app.otherElements["session.board"].descendants(matching: .button)
            for control in controls.allElementsBoundByIndex {
                XCTAssertFalse(control.frame.intersects(footer), "\(game): \(control.identifier) intersects footer")
            }
            for _ in 0..<5 where !app.buttons["session.back"].isHittable { app.swipeUp() }
            app.buttons["session.back"].tap()
        }
    }

    @MainActor func testSudokuControlsDoNotIntersectFooterInitially() {
        let app = launch()
        open("sudoku", in: app)
        let footer = app.otherElements["session.footer"].frame
        for id in ["sudoku.notes", "sudoku.erase"] {
            let button = app.buttons[id]
            XCTAssertTrue(button.exists)
            XCTAssertFalse(button.frame.intersects(footer), "\(id) \(button.frame) intersects footer \(footer)")
        }
        let digits = (1...9).map { app.buttons["sudoku.digit.\($0)"].frame }
        for frame in digits {
            XCTAssertGreaterThanOrEqual(frame.width, 36)
            XCTAssertGreaterThanOrEqual(frame.height, 44)
            XCTAssertFalse(frame.intersects(footer))
        }
        if app.frame.width - 24 >= 9 * 36 + 8 * 4 {
            XCTAssertEqual(digits[0].minY, digits[8].minY, accuracy: 1)
        } else {
            XCTAssertEqual(digits[0].minY, digits[4].minY, accuracy: 1)
            XCTAssertEqual(digits[5].minY, digits[8].minY, accuracy: 1)
            XCTAssertGreaterThan(digits[5].minY, digits[4].minY)
        }
    }

    @MainActor func testSudokuSelectionAndNotesPersistThroughConflictsAndFeedback() throws {
        let app = launch()
        open("sudoku", in: app)
        var library = GameLibrary(seed: 42)
        library.ensureSession(.sudoku, content: try GameContent.bundled())
        guard case let .sudoku(game)? = library.session(.sudoku)?.state,
              let index = game.puzzle.givens.firstIndex(of: 0),
              let conflict = (0..<9).map({ game.puzzle.givens[index / 9 * 9 + $0] }).first(where: { $0 > 0 }) else {
            return XCTFail("Expected an empty cell and a given in its row")
        }
        let cell = app.buttons["sudoku.cell.\(index)"]
        let notes = app.buttons["sudoku.notes"]
        cell.tap()
        for _ in 0..<5 where !notes.isHittable { app.swipeUp() }
        notes.tap()
        app.buttons["sudoku.digit.2"].tap()
        app.buttons["sudoku.digit.3"].tap()
        XCTAssertEqual(notes.label, "Notes: On")
        XCTAssertEqual(cell.value as? String, "empty")
        XCTAssertFalse(app.staticTexts["session.feedback"].exists)
        notes.tap()
        app.buttons["sudoku.digit.\(conflict)"].tap()
        XCTAssertEqual(cell.value as? String, String(conflict))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Cells with duplicate numbers:'")).firstMatch.exists)
        XCTAssertEqual(notes.label, "Notes")
        XCTAssertTrue(app.buttons["sudoku.digit.1"].isEnabled)
        for _ in 0..<5 where !notes.isHittable { app.swipeUp() }
        notes.tap()
        app.buttons["sudoku.digit.5"].tap()
        XCTAssertTrue(app.staticTexts["session.feedback"].exists)
        XCTAssertEqual(notes.label, "Notes: On")
        XCTAssertEqual(cell.value as? String, String(conflict))
        XCTAssertTrue(app.buttons["sudoku.digit.1"].isEnabled)
        attach(app, name: "Sudoku Notes and Selection Persist With Feedback")
        app.buttons["sudoku.erase"].tap()
        app.buttons["sudoku.digit.6"].tap()
        XCTAssertEqual(cell.value as? String, "empty")
        XCTAssertEqual(notes.label, "Notes: On")
        XCTAssertFalse(app.staticTexts["session.feedback"].exists)
    }

    @MainActor func testSudokuFullDigitPadIsReachable() {
        let app = launch()
        open("sudoku", in: app)
        let cell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sudoku.cell.'")).firstMatch
        cell.tap()
        app.swipeUp()
        for digit in 7...9 {
            let button = app.buttons["sudoku.digit.\(digit)"]
            XCTAssertTrue(button.isHittable)
            XCTAssertLessThanOrEqual(button.frame.maxY, app.buttons["session.undo"].frame.minY - 8)
            button.tap()
            XCTAssertEqual(cell.value as? String, String(digit))
        }
        attach(app, name: "Sudoku Full Digit Pad")
    }

    @MainActor private func assertBoardFits(_ app: XCUIApplication, prefix: String, columns: Int, file: StaticString = #filePath, line: UInt = #line) {
        let cells = (0..<columns).map { app.descendants(matching: .any)["\(prefix).cell.\($0)"].firstMatch }
        let expectedSize = floor(min(48, (app.frame.width - 24 - 16) / CGFloat(columns)))
        for cell in cells {
            XCTAssertTrue(cell.isHittable, file: file, line: line)
            XCTAssertGreaterThanOrEqual(cell.frame.minX, app.frame.minX, file: file, line: line)
            XCTAssertLessThanOrEqual(cell.frame.maxX, app.frame.maxX, file: file, line: line)
        }
        let cellSpacing = (cells.last!.frame.midX - cells.first!.frame.midX) / CGFloat(columns - 1)
        XCTAssertEqual(cellSpacing, expectedSize, accuracy: 0.1, file: file, line: line)
        XCTAssertEqual(cells.first!.frame.minX - app.frame.minX, app.frame.maxX - cells.last!.frame.maxX, accuracy: 1, file: file, line: line)
        print("BOARD MEASUREMENT \(prefix) \(columns) columns: \(cellSpacing)pt on \(app.frame.width)pt screen")
    }

    @MainActor func test2048BoardSwipesMatchDirectionalButtons() {
        let app = launch()
        open("game2048", in: app)
        let board = app.descendants(matching: .any)["slide.board"]
        func tiles() -> [String] { board.staticTexts.allElementsBoundByIndex.map(\.label) }
        let initial = tiles()
        board.tap()
        XCTAssertEqual(tiles(), initial)
        let center = board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.01, thenDragTo: center.withOffset(CGVector(dx: 0, dy: 12)))
        XCTAssertEqual(tiles(), initial)
        continueAfterFailure = true
        for direction in ["left", "up", "down"] {
            let before = tiles()
            XCTAssertEqual(before.count, 16)
            app.buttons["slide.\(direction)"].tap()
            let expected = tiles()
            XCTAssertNotEqual(expected, before, "Fixture must allow a \(direction) move")
            app.buttons["session.undo"].tap()
            XCTAssertEqual(tiles(), before)
            switch direction {
            case "left": board.swipeLeft()
            case "up": board.swipeUp()
            default: board.swipeDown()
            }
            XCTAssertEqual(tiles(), expected, "Board swipe \(direction) must match its direction button")
        }
    }

    @MainActor func testRulesAndDirectionalControls() {
        let app = launch()
        open("blockGrid", in: app)
        app.buttons["session.rules"].tap()
        XCTAssertTrue(app.buttons["rules.done"].waitForExistence(timeout: 5))
        app.buttons["rules.done"].tap()
        app.buttons["session.pause"].tap()
        app.buttons["pause.rules"].tap()
        XCTAssertTrue(app.buttons["rules.done"].waitForExistence(timeout: 5))
        app.buttons["rules.done"].tap()
        app.buttons["session.back"].tap()
        open("game2048", in: app)
        for direction in ["left", "up", "right", "down"] {
            let button = app.buttons["slide.\(direction)"]
            if !button.isHittable { app.swipeUp() }
            XCTAssertTrue(button.isHittable)
            button.tap()
        }
        let board = app.descendants(matching: .any)["slide.board"]
        if !board.isHittable { app.swipeDown() }
        board.swipeLeft()
        attach(app, name: "2048")
    }
}
