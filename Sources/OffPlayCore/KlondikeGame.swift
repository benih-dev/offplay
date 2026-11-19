import Foundation

public enum CardSuit: Int, Codable, CaseIterable, Sendable {
    case spades, hearts, clubs, diamonds
    public var symbol: String {
        switch self { case .spades: "♠"; case .hearts: "♥"; case .clubs: "♣"; case .diamonds: "♦" }
    }
    public var name: String {
        switch self { case .spades: "sekop"; case .hearts: "hati"; case .clubs: "keriting"; case .diamonds: "wajik" }
    }
    public var isRed: Bool { self == .hearts || self == .diamonds }
}

public struct PlayingCard: Codable, Equatable, Identifiable, Sendable {
    public let suit: CardSuit
    public let rank: Int
    public var faceUp: Bool
    public var id: Int { suit.rawValue * 13 + rank - 1 }
    public var label: String {
        switch rank { case 1: "A"; case 11: "J"; case 12: "Q"; case 13: "K"; default: String(rank) }
    }
    public init(suit: CardSuit, rank: Int, faceUp: Bool = false) {
        self.suit = suit; self.rank = rank; self.faceUp = faceUp
    }
}

public enum CardSource: Equatable, Sendable {
    case tableau(column: Int, index: Int), waste, foundation(CardSuit)
}

public enum CardDestination: Equatable, Sendable {
    case tableau(Int), foundation(CardSuit)
}

public struct KlondikeGame: Codable, Equatable, Sendable {
    private struct Snapshot: Codable, Equatable, Sendable {
        let tableau: [[PlayingCard]]
        let stock: [PlayingCard]
        let waste: [PlayingCard]
        let foundations: [[PlayingCard]]
        let moves: Int
    }
    public private(set) var tableau: [[PlayingCard]]
    public private(set) var stock: [PlayingCard]
    public private(set) var waste: [PlayingCard] = []
    public private(set) var foundations: [[PlayingCard]] = Array(repeating: [], count: 4)
    public private(set) var moves = 0
    private var history: [Snapshot] = []

    public init(seed: UInt64) {
        var random = RandomSource(seed: seed)
        var deck = random.shuffled(CardSuit.allCases.flatMap { suit in (1...13).map { PlayingCard(suit: suit, rank: $0) } })
        var columns: [[PlayingCard]] = []
        for column in 0..<7 {
            var cards: [PlayingCard] = []
            for index in 0...column {
                var card = deck.removeLast()
                card.faceUp = index == column
                cards.append(card)
            }
            columns.append(cards)
        }
        tableau = columns
        stock = deck
    }

    init(tableau: [[PlayingCard]], stock: [PlayingCard] = [], waste: [PlayingCard] = [], foundations: [[PlayingCard]] = Array(repeating: [], count: 4)) {
        self.tableau = tableau; self.stock = stock; self.waste = waste; self.foundations = foundations
    }

    public var isWon: Bool { foundations.reduce(0) { $0 + $1.count } == 52 }
    public var canUndo: Bool { !history.isEmpty && !isWon }

    @discardableResult public mutating func draw() -> Bool {
        guard !isWon, !stock.isEmpty || !waste.isEmpty else { return false }
        remember()
        if !stock.isEmpty {
            var card = stock.removeLast()
            card.faceUp = true
            waste.append(card)
        } else {
            stock = waste.reversed().map { card in
                var hidden = card; hidden.faceUp = false; return hidden
            }
            waste = []
        }
        moves += 1
        return true
    }

    public func cards(at source: CardSource) -> [PlayingCard] {
        switch source {
        case let .tableau(column, index):
            guard tableau.indices.contains(column), tableau[column].indices.contains(index) else { return [] }
            let cards = Array(tableau[column][index...])
            guard cards.allSatisfy(\.faceUp) else { return [] }
            for offset in 1..<cards.count {
                guard cards[offset - 1].rank == cards[offset].rank + 1,
                      cards[offset - 1].suit.isRed != cards[offset].suit.isRed else { return [] }
            }
            return cards
        case .waste: return waste.last.map { [$0] } ?? []
        case let .foundation(suit): return foundations[suit.rawValue].last.map { [$0] } ?? []
        }
    }

    @discardableResult public mutating func move(from source: CardSource, to destination: CardDestination) -> Bool {
        guard !isWon else { return false }
        let moving = cards(at: source)
        guard let first = moving.first else { return false }
        switch destination {
        case let .tableau(column):
            guard tableau.indices.contains(column) else { return false }
            if case let .tableau(old, _) = source, old == column { return false }
            if let top = tableau[column].last {
                guard top.faceUp, top.rank == first.rank + 1, top.suit.isRed != first.suit.isRed else { return false }
            } else if first.rank != 13 { return false }
        case let .foundation(suit):
            guard moving.count == 1, first.suit == suit, first.rank == foundations[suit.rawValue].count + 1 else { return false }
            if case let .foundation(old) = source, old == suit { return false }
        }
        remember()
        switch source {
        case let .tableau(column, index):
            tableau[column].removeSubrange(index...)
            if !tableau[column].isEmpty { tableau[column][tableau[column].count - 1].faceUp = true }
        case .waste: waste.removeLast()
        case let .foundation(suit): foundations[suit.rawValue].removeLast()
        }
        switch destination {
        case let .tableau(column): tableau[column] += moving
        case let .foundation(suit): foundations[suit.rawValue] += moving
        }
        moves += 1
        return true
    }

    @discardableResult public mutating func undo() -> Bool {
        guard canUndo, let snapshot = history.popLast() else { return false }
        tableau = snapshot.tableau; stock = snapshot.stock; waste = snapshot.waste
        foundations = snapshot.foundations; moves = snapshot.moves
        return true
    }

    private mutating func remember() {
        history.append(Snapshot(tableau: tableau, stock: stock, waste: waste, foundations: foundations, moves: moves))
        if history.count > 100 { history.removeFirst(history.count - 100) }
    }

    var validForArchive: Bool {
        func valid(_ tableau: [[PlayingCard]], _ stock: [PlayingCard], _ waste: [PlayingCard], _ foundations: [[PlayingCard]]) -> Bool {
            let cards = tableau.flatMap { $0 } + stock + waste + foundations.flatMap { $0 }
            guard tableau.count == 7, foundations.count == 4, cards.count == 52,
                  cards.allSatisfy({ (1...13).contains($0.rank) }), Set(cards.map(\.id)).count == 52,
                  stock.allSatisfy({ !$0.faceUp }), waste.allSatisfy(\.faceUp) else { return false }
            for suit in CardSuit.allCases {
                if !foundations[suit.rawValue].enumerated().allSatisfy({ $0.element.suit == suit && $0.element.rank == $0.offset + 1 && $0.element.faceUp }) { return false }
            }
            for column in tableau {
                if let first = column.firstIndex(where: \.faceUp), !column[first...].allSatisfy(\.faceUp) { return false }
            }
            return true
        }
        return moves >= 0 && history.count <= 100 && valid(tableau, stock, waste, foundations) &&
            history.allSatisfy { $0.moves >= 0 && valid($0.tableau, $0.stock, $0.waste, $0.foundations) }
    }
}
