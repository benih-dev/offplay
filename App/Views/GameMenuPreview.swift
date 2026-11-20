import SwiftUI
import OffPlayCore

/// Static board illustrations; opening a tile uses the saved game in AppStore.
struct GameMenuPreview: View {
    let id: GameID

    private static let blocks: Set<Int> = [
        0, 1, 8, 9, 14, 15, 22, 23, 30, 32, 33, 40, 41, 42,
        47, 48, 49, 50, 55, 56, 57, 58, 61, 62, 63
    ]
    private static let sudoku = Array(
        "530070000600195000098000060800060003400803001700020006060000280000419005000080079"
    )
    private static let tiles = [2, 0, 0, 0, 4, 2, 0, 0, 8, 16, 4, 0, 32, 64, 8, 2]
    private static let revealedMines: Set<Int> = [6, 7, 8, 11, 12, 13, 16, 17, 18]

    var body: some View {
        illustration
            .frame(width: GameMenuTheme.previewSize, height: GameMenuTheme.previewSize)
            .frame(maxWidth: .infinity, minHeight: GameMenuTheme.previewHeight)
            .background(
                GameMenuTheme.well(id),
                in: RoundedRectangle(cornerRadius: GameMenuTheme.smallRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: GameMenuTheme.smallRadius)
                    .strokeBorder(GameMenuTheme.ink, lineWidth: GameMenuTheme.edge)
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    @ViewBuilder private var illustration: some View {
        switch id {
        case .blockGrid: blockGrid
        case .klondike: playingCards
        case .sudoku: sudoku
        case .game2048: numberTiles
        case .minesweeper: mines
        case .wordScramble: words
        }
    }

    private func grid<Cell: View>(
        columns: Int,
        spacing: CGFloat = GameMenuTheme.unit,
        @ViewBuilder cell: @escaping (Int) -> Cell
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            ForEach(0..<(columns * columns), id: \.self) { index in
                cell(index).aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private var blockGrid: some View {
        grid(columns: 8, spacing: GameMenuTheme.edge) { index in
            RoundedRectangle(cornerRadius: GameMenuTheme.edge)
                .fill(Self.blocks.contains(index)
                      ? (index > 46 ? GameMenuTheme.yellow : GameMenuTheme.greenTile)
                      : GameMenuTheme.greenFill)
        }
        .padding(GameMenuTheme.unit)
        .background(GameMenuTheme.greenDeep, in: RoundedRectangle(cornerRadius: GameMenuTheme.unit))
    }

    private var playingCards: some View {
        HStack(spacing: GameMenuTheme.unit) {
            playingCard(rank: "A", suit: "suit.spade.fill", red: false)
            playingCard(rank: "2", suit: "suit.heart.fill", red: true)
            playingCard(rank: "3", suit: "suit.club.fill", red: false)
        }
    }

    private func playingCard(rank: String, suit: String, red: Bool) -> some View {
        VStack(alignment: .leading, spacing: GameMenuTheme.inset) {
            Text(rank).font(.system(size: 20, weight: .bold, design: .serif))
            Image(systemName: suit).font(.system(size: 20))
        }
        .foregroundStyle(red ? GameMenuTheme.redInk : GameMenuTheme.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, GameMenuTheme.inset)
        .background(GameMenuTheme.paper, in: RoundedRectangle(cornerRadius: GameMenuTheme.unit))
        .overlay {
            RoundedRectangle(cornerRadius: GameMenuTheme.unit)
                .strokeBorder(GameMenuTheme.ink, lineWidth: GameMenuTheme.edge)
        }
        .shadow(color: GameMenuTheme.redInk, radius: 0, y: GameMenuTheme.unit)
    }

    private var sudoku: some View {
        grid(columns: 9, spacing: 0) { index in
            Text(Self.sudoku[index] == "0" ? "" : String(Self.sudoku[index]))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(GameMenuTheme.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(GameMenuTheme.paper)
                .border(GameMenuTheme.blue, width: 0.5)
        }
        .overlay {
            GeometryReader { geometry in
                Path { path in
                    for boundary in 1...2 {
                        let fraction = CGFloat(boundary) / 3
                        let x = geometry.size.width * fraction
                        let y = geometry.size.height * fraction
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(GameMenuTheme.blueInk, lineWidth: GameMenuTheme.edge)
            }
        }
        .border(GameMenuTheme.blueInk, width: GameMenuTheme.edge)
        .shadow(color: GameMenuTheme.blueInk, radius: 0, y: GameMenuTheme.unit)
    }

    private var numberTiles: some View {
        grid(columns: 4) { index in
            let number = Self.tiles[index]
            Text(number == 0 ? "" : String(number))
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(GameMenuTheme.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    number >= 16 ? GameMenuTheme.yellow
                        : (number == 0 ? GameMenuTheme.yellowFill : GameMenuTheme.paper),
                    in: RoundedRectangle(cornerRadius: GameMenuTheme.unit)
                )
        }
        .padding(GameMenuTheme.unit)
        .background(GameMenuTheme.ink, in: RoundedRectangle(cornerRadius: GameMenuTheme.unit * 2))
    }

    private var mines: some View {
        grid(columns: 5) { index in
            ZStack {
                RoundedRectangle(cornerRadius: GameMenuTheme.unit)
                    .fill(Self.revealedMines.contains(index) ? GameMenuTheme.paper : GameMenuTheme.greenTile)
                if index == 2 {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(GameMenuTheme.paper)
                } else if Self.revealedMines.contains(index) && index != 12 {
                    Text(index == 8 ? "2" : "1")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(GameMenuTheme.blueInk)
                }
            }
        }
    }

    private var words: some View {
        VStack(spacing: GameMenuTheme.inset) {
            letterRow("TAKA", fill: GameMenuTheme.paper)
            letterRow("KATA", fill: GameMenuTheme.yellow)
        }
    }

    private func letterRow(_ word: String, fill: Color) -> some View {
        HStack(spacing: GameMenuTheme.unit) {
            ForEach(Array(word.enumerated()), id: \.offset) { _, letter in
                Text(String(letter))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(GameMenuTheme.ink)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .background(fill, in: RoundedRectangle(cornerRadius: GameMenuTheme.unit))
                    .overlay {
                        RoundedRectangle(cornerRadius: GameMenuTheme.unit)
                            .strokeBorder(GameMenuTheme.ink, lineWidth: 1)
                    }
                    .shadow(color: GameMenuTheme.ink, radius: 0, y: GameMenuTheme.unit)
            }
        }
    }
}
