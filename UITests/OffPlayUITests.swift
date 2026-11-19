import XCTest
import OffPlayCore
import UIKit

final class OffPlayUITests: XCTestCase {
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

    @MainActor private func assertAppearance(in app: XCUIApplication, light: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let matches = NSPredicate { _, _ in
            guard let image = app.screenshot().image.cgImage else { return false }
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

    @MainActor private func launch(reset: Bool = true, theme: String = "light") -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-theme", theme] + (reset ? ["-reset-data"] : [])
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
        let emptyCell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'sudoku.cell.' AND value == 'kosong'")).firstMatch
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
        XCTAssertFalse(app.staticTexts["Langkah belum dapat dilakukan."].exists)
        app.buttons["cards.tableau.0.0"].tap()
        XCTAssertFalse(app.staticTexts["Langkah belum dapat dilakukan."].exists)
        app.buttons["cards.tableau.1.1"].tap()
        app.buttons["cards.tableau.5.5"].tap()
        XCTAssertTrue(app.buttons["cards.tableau.5.6"].exists)
        XCTAssertFalse(app.staticTexts["Langkah belum dapat dilakukan."].exists)
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
        app.launchArguments = ["-ui-testing", "-theme", "light"]
        app.launch()
        XCTAssertTrue(app.buttons["catalog.blockGrid"].waitForExistence(timeout: 10))
        open("blockGrid", in: app)
        XCTAssertEqual(app.descendants(matching: .any)["session.score"].label, score)
        app.buttons["session.new"].tap()
        app.buttons["new.confirm"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["session.score"].label.contains("0"))
        app.buttons["session.back"].tap()
        app.buttons["catalog.statistics"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == 'Ditinggalkan'")).firstMatch.exists)
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

    @MainActor func testWordResultPersistsAndNewGameDoesNotAskToAbandon() throws {
        let app = launch()
        open("wordScramble", in: app)
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
        XCTAssertTrue(app.staticTexts["session.result"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["session.result"].label, "Menang")
        attach(app, name: "Word Scramble Result")
        app.buttons["session.back"].tap()
        app.terminate()
        app.launchArguments = ["-ui-testing", "-theme", "light"]
        app.launch()
        XCTAssertTrue(app.buttons["catalog.blockGrid"].waitForExistence(timeout: 10))
        open("wordScramble", in: app)
        XCTAssertEqual(app.staticTexts["session.result"].label, "Menang")
        app.buttons["session.new"].tap()
        XCTAssertFalse(app.buttons["new.confirm"].exists)
        XCTAssertFalse(app.staticTexts["session.result"].exists)
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
        XCTAssertTrue(app.staticTexts["Menengah"].waitForExistence(timeout: 5))
        attach(app, name: "Minesweeper Intermediate")
        app.buttons["session.pause"].tap()
        app.buttons["pause.catalog"].tap()
        open("sudoku", in: app)
        app.buttons["session.new"].tap()
        app.buttons["new.sudoku.hard"].tap()
        if !app.buttons["new.confirm"].isHittable { app.swipeUp() }
        app.buttons["new.confirm"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sulit ·'")).firstMatch.waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts["Menengah"].waitForExistence(timeout: 5))
        assertBoardFits(app, prefix: "mines", columns: 16)
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
