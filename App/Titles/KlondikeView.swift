import SwiftUI
import OffPlayCore

struct KlondikeView: View {
    @Environment(AppStore.self) private var store
    @State private var selected: CardSource?
    @State private var availableWidth: CGFloat = 0
    @ScaledMetric(relativeTo: .headline) private var preferredCardWidth: CGFloat = 48
    @ScaledMetric(relativeTo: .caption) private var countHeight: CGFloat = 20

    var body: some View {
        if case let .klondike(game)? = store.library.session(.klondike)?.state {
            let cardWidth = floor(min(preferredCardWidth, max(44, (availableWidth - 16 - 24) / 7)))
            let cardHeight = cardWidth * 68 / 48
            let hiddenHeight = cardWidth * 18 / 48
            let isOverflowing = cardWidth * 7 + 24 + 16 > availableWidth
            VStack(spacing: 12) {
                Text("Tap a card, then its destination column or foundation.").font(.footnote).foregroundStyle(GameTheme.secondary)
                ScrollView(.horizontal) {
                  HStack(alignment: .top, spacing: 4) {
                    VStack(spacing: 4) {
                        Button {
                            selected = nil
                            store.play(.klondike) { state in
                                guard case var .klondike(current) = state else { return false }
                                let changed = current.draw(); state = .klondike(current); return changed
                            }
                        } label: { CardFace(card: nil, placeholder: game.stock.isEmpty ? "↻" : "▤", selected: false, width: cardWidth, height: cardHeight) }
                            .buttonStyle(BoardButtonStyle()).disabled(game.stock.isEmpty && game.waste.isEmpty).accessibilityLabel(game.stock.isEmpty ? LocalizedStringKey("Recycle the stock") : "Draw from the stock")
                            .accessibilityIdentifier("cards.stock")
                        Text(String(game.stock.count)).font(.caption2).frame(height: countHeight)
                    }
                    Button { selected = selected == .waste ? nil : .waste } label: {
                        CardFace(card: game.waste.last, placeholder: "", selected: selected == .waste, width: cardWidth, height: cardHeight)
                    }.buttonStyle(BoardButtonStyle()).disabled(game.waste.isEmpty).accessibilityLabel("Waste pile").accessibilityIdentifier("cards.waste")
                    Spacer(minLength: cardWidth)
                    ForEach(CardSuit.allCases, id: \.rawValue) { suit in
                        Button {
                            if let source = selected { move(source, to: .foundation(suit)) }
                            else if !game.foundations[suit.rawValue].isEmpty { selected = .foundation(suit) }
                        } label: {
                            CardFace(card: game.foundations[suit.rawValue].last, placeholder: suit.symbol, selected: selected == .foundation(suit), width: cardWidth, height: cardHeight)
                        }.buttonStyle(BoardButtonStyle()).disabled(selected == nil && game.foundations[suit.rawValue].isEmpty).accessibilityLabel("Foundation: \(suit.localizedName)").accessibilityIdentifier("cards.foundation.\(suit.rawValue)")
                    }
                }
                  .frame(minWidth: max(0, availableWidth - 16))
                  .padding(.horizontal, 8)
                }
                .scrollDisabled(!isOverflowing)
                .frame(height: cardHeight + countHeight + 8)
                BoardViewport(height: max(220, (game.tableau.map { column in column.reduce(CGFloat(0)) { $0 + ($1.faceUp ? cardHeight : hiddenHeight) + 3 } }.max() ?? cardHeight) + 16)) {
                    HStack(alignment: .top, spacing: 4) {
                        ForEach(0..<7, id: \.self) { column in
                            VStack(spacing: 3) {
                                if game.tableau[column].isEmpty {
                                    Button {
                                        if let selected { move(selected, to: .tableau(column)) }
                                    } label: { CardFace(card: nil, placeholder: "K", selected: false, width: cardWidth, height: cardHeight) }
                                        .buttonStyle(BoardButtonStyle()).disabled(selected == nil).accessibilityLabel("Column \(column + 1) empty, kings only")
                                        .accessibilityIdentifier("cards.column.\(column)")
                                }
                                ForEach(Array(game.tableau[column].enumerated()), id: \.element.id) { index, card in
                                    if card.faceUp {
                                        Button { choose(column: column, index: index) } label: {
                                            CardFace(card: card, placeholder: "", selected: selected == .tableau(column: column, index: index), width: cardWidth, height: cardHeight)
                                        }.buttonStyle(BoardButtonStyle()).accessibilityLabel("\(card.label) of \(card.suit.localizedName), column \(column + 1)")
                                            .accessibilityIdentifier("cards.tableau.\(column).\(index)")
                                    } else {
                                        RoundedRectangle(cornerRadius: 5).fill(GameTheme.accentFill).frame(width: cardWidth, height: hiddenHeight)
                                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(GameTheme.line, lineWidth: 1))
                                            .accessibilityElement().accessibilityLabel("Face-down card, column \(column + 1)")
                                    }
                                }
                            }.frame(width: cardWidth)
                        }
                    }
                }
                .scrollDisabled(!isOverflowing)
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
            .onChange(of: game) { selected = nil }
        }
    }

    private func choose(column: Int, index: Int) {
        let source = CardSource.tableau(column: column, index: index)
        if let selected {
            if case let .tableau(oldColumn, _) = selected, oldColumn == column { self.selected = selected == source ? nil : source }
            else { move(selected, to: .tableau(column)) }
        } else { selected = source }
    }
    private func move(_ source: CardSource, to destination: CardDestination) {
        if store.play(.klondike, { state in
            guard case var .klondike(game) = state else { return false }
            let changed = game.move(from: source, to: destination); state = .klondike(game); return changed
        }) { selected = nil }
    }
}

private struct CardFace: View {
    let card: PlayingCard?
    let placeholder: String
    let selected: Bool
    var width: CGFloat = 48
    var height: CGFloat = 68
    var body: some View {
        VStack(spacing: 3) {
            if let card {
                Text(card.label).font(.system(.headline, design: .rounded))
                Text(card.suit.symbol).font(.title3)
            } else { Text(placeholder).font(.title3) }
        }
        .frame(width: width, height: height)
        .background(selected ? GameTheme.accentFill : GameTheme.surface)
        .foregroundStyle(card?.suit.isRed == true ? GameTheme.danger : GameTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(selected ? GameTheme.accent : GameTheme.line, lineWidth: selected ? 2 : 1))
    }
}
