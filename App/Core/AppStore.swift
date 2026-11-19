import Foundation
import Observation
import SwiftUI
import UIKit
import OffPlayCore

enum AppModal: String, Identifiable {
    case pause, newGame, rules, statistics, settings
    var id: String { rawValue }
}

@MainActor @Observable final class AppStore {
    private(set) var library: GameLibrary
    private(set) var content: GameContent?
    private(set) var loading = true
    private(set) var loadError: String?
    private(set) var saveError: String?
    private(set) var activeID: GameID?
    var path: [GameID] = []
    var modal: AppModal?
    var feedback: String?
    private var sceneActive = true
    private var timeStamp: TimeInterval?
    private var saveTicks = 0
    private let fileStore: LibraryFileStore
    private let testing: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        testing = arguments.contains("-ui-testing")
        library = GameLibrary(seed: testing ? 42 : UInt64.random(in: 0...UInt64.max))
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(testing ? "OffPlay-UI-Tests" : "OffPlay", isDirectory: true)
        fileStore = LibraryFileStore(url: base.appendingPathComponent("library.json"))
        if testing && arguments.contains("-reset-data") { try? FileManager.default.removeItem(at: base) }
    }

    var colorScheme: ColorScheme? {
        switch library.appearance { case .system: nil; case .light: .light; case .dark: .dark }
    }

    func load() {
        loading = true
        loadError = nil
        do {
            content = try GameContent.bundled()
            if let loaded = try fileStore.load() { library = loaded.library }
            if testing, let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-theme"),
               ProcessInfo.processInfo.arguments.indices.contains(index + 1),
               let appearance = AppAppearance(rawValue: ProcessInfo.processInfo.arguments[index + 1]) { library.appearance = appearance }
        } catch { loadError = error.localizedDescription }
        loading = false
    }

    func open(_ id: GameID) {
        guard let content else { return }
        library.ensureSession(id, content: content)
        save()
        feedback = nil
        path = [id]
        navigationChanged()
    }

    func navigationChanged() {
        flushTime()
        activeID = path.last
        resetClock()
        save()
    }

    func leaveGame() {
        flushTime()
        save()
        modal = nil
        path = []
        activeID = nil
        timeStamp = nil
        feedback = nil
    }

    func present(_ screen: AppModal) {
        flushTime()
        save()
        modal = screen
        timeStamp = nil
    }

    func sheetDismissed() { resetClock() }

    func requestNewGame(_ id: GameID) {
        if let session = library.session(id), session.hasStarted && session.outcome == nil || id == .sudoku || id == .minesweeper {
            present(.newGame)
        } else {
            newGame(id, sudoku: library.lastSudokuDifficulty, mines: library.lastMineDifficulty)
        }
    }

    func newGame(_ id: GameID, sudoku: SudokuDifficulty, mines: MineDifficulty) {
        guard let content else { return }
        flushTime()
        library.newGame(id, content: content, sudokuDifficulty: sudoku, mineDifficulty: mines)
        feedback = nil
        modal = nil
        timeStamp = nil
        save()
    }

    @discardableResult func play(_ id: GameID, submittingWord: Bool = false, _ action: (inout GameState) -> Bool) -> Bool {
        guard sceneActive, modal == nil, activeID == id else { return false }
        flushTime()
        guard library.act(on: id, action) else {
            feedback = "Langkah belum dapat dilakukan."
            haptic(.error)
            return false
        }
        feedback = nil
        if let result = library.session(id)?.outcome {
            timeStamp = nil
            haptic(result == .won ? .success : .error)
        } else if submittingWord {
            feedback = "Belum tepat. Susun hurufnya lagi."
            haptic(.error)
        } else if library.hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        resetClock()
        save()
        return true
    }

    func undo(_ id: GameID) {
        guard sceneActive, modal == nil, activeID == id else { return }
        flushTime()
        if library.undo(id) {
            feedback = nil
            if library.hapticsEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
            save()
        }
    }

    func setAppearance(_ appearance: AppAppearance) { library.appearance = appearance; save() }
    func setHaptics(_ enabled: Bool) { library.hapticsEnabled = enabled; save() }

    func setSceneActive(_ active: Bool) {
        flushTime()
        sceneActive = active
        resetClock()
        if !active { save() }
    }

    func tick() {
        flushTime()
        saveTicks += 1
        if saveTicks >= 5 { saveTicks = 0; save() }
    }

    func save() {
        guard !loading, loadError == nil else { return }
        do { try fileStore.save(library); saveError = nil }
        catch { saveError = "Perubahan belum tersimpan: \(error.localizedDescription)" }
    }

    private func resetClock() {
        if sceneActive, modal == nil, let id = activeID, let session = library.session(id), session.hasStarted && session.outcome == nil {
            timeStamp = ProcessInfo.processInfo.systemUptime
        } else { timeStamp = nil }
    }

    private func flushTime() {
        let now = ProcessInfo.processInfo.systemUptime
        if sceneActive, modal == nil, let id = activeID, let stamp = timeStamp {
            library.addActiveTime(max(0, now - stamp), to: id)
            timeStamp = now
        }
    }

    private func haptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        if library.hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(type) }
    }
}
