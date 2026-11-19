import Foundation
import OffPlayCore

extension GameID {
    var localizedDescription: String {
        switch self {
        case .blockGrid: String(localized: "Place pieces and clear lines.")
        case .klondike: String(localized: "Build foundations from ace to king.")
        case .sudoku: String(localized: "Fill in the digits without repeats.")
        case .game2048: String(localized: "Slide and merge tiles.")
        case .minesweeper: String(localized: "Reveal cells and avoid mines.")
        case .wordScramble: String(localized: "Find Indonesian words.")
        }
    }
}

extension SudokuDifficulty {
    var localizedName: String {
        switch self {
        case .easy: String(localized: "Easy")
        case .medium: String(localized: "Medium")
        case .hard: String(localized: "Hard")
        }
    }
}

extension MineDifficulty {
    var localizedName: String {
        switch self {
        case .beginner: String(localized: "Beginner")
        case .intermediate: String(localized: "Intermediate")
        }
    }
}

extension SessionOutcome {
    var localizedName: String {
        switch self {
        case .won: String(localized: "Won")
        case .lost: String(localized: "Lost")
        case .abandoned: String(localized: "Abandoned")
        }
    }
}

extension AppAppearance {
    var localizedName: String {
        switch self {
        case .system: String(localized: "Follow System")
        case .light: String(localized: "Light")
        case .dark: String(localized: "Dark")
        }
    }
}

extension CardSuit {
    var localizedName: String {
        switch self {
        case .spades: String(localized: "spades")
        case .hearts: String(localized: "hearts")
        case .clubs: String(localized: "clubs")
        case .diamonds: String(localized: "diamonds")
        }
    }
}

extension Error {
    var offPlayDescription: String {
        if self is ContentError { return String(localized: "Couldn’t read the game content.") }
        if let error = self as? SaveFileError {
            switch error {
            case .invalid: return String(localized: "Couldn’t read the save file.")
            case let .unsupportedVersion(version):
                return String(localized: "The save file uses version \(version), which this app doesn’t support.")
            }
        }
        return localizedDescription
    }
}
