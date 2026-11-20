import SwiftUI
import UIKit
import OffPlayCore

enum GameMenuTheme {
    static let canvas = adaptive(0xdff3fc, 0x172d36)
    static let text = adaptive(0x173c43, 0xdff3fc)
    static let secondary = adaptive(0x365b63, 0xb9dce9)
    static let brand = adaptive(0x168458, 0x70d99b)
    static let ink = color(0x173c43)
    static let paper = color(0xffffff)
    static let utilitySurface = adaptive(0xffffff, 0x284653)
    static let utilityOutline = adaptive(0x173c43, 0x82adbc)
    static let depth = adaptive(0x173c43, 0x091a21)
    static let brandRim = adaptive(0xffffff, 0x2f675b)
    static let brandDepth = adaptive(0x0d5b3d, 0x091a21)
    static let green = adaptive(0x70d99b, 0x76be91)
    static let greenFill = adaptive(0xc8f2d3, 0xa2cfb1)
    static let greenDeep = color(0x0d5b3d)
    static let greenTile = color(0x168458)
    static let yellow = adaptive(0xffda65, 0xe5c360)
    static let yellowFill = adaptive(0xfff0b4, 0xddcb8c)
    static let coral = adaptive(0xff9486, 0xe88d84)
    static let coralFill = adaptive(0xffddd4, 0xedb9ad)
    static let redInk = color(0xa32e38)
    static let blue = adaptive(0x79c8ee, 0x74b4d7)
    static let blueFill = adaptive(0xb9e5fb, 0x9ecde4)
    static let blueInk = color(0x164f76)
    static let mineCovered = adaptive(0x168458, 0x28533e)
    static let mineSurface = adaptive(0xffffff, 0x202e32)
    static let mineSymbol = adaptive(0xffffff, 0xdff3fc)
    static let mineRed = adaptive(0xa32e38, 0xff9486)
    static let mineExplosion = color(0xa32e38)

    static func mineNumber(_ count: Int) -> Color {
        switch count {
        case 1: adaptive(0x164f76, 0x79c8ee)
        case 2: adaptive(0x0d5b3d, 0x70d99b)
        case 3: mineRed
        case 4: adaptive(0x593f86, 0xc9aff2)
        case 5: adaptive(0x843f25, 0xefb18d)
        case 6: adaptive(0x146269, 0x82d4d3)
        case 7: adaptive(0x46373f, 0xf0b7d7)
        default: text
        }
    }

    static let unit: CGFloat = 4
    static let inset: CGFloat = 16
    static let sectionGap: CGFloat = 24
    static let radius: CGFloat = 20
    static let smallRadius: CGFloat = 12
    static let edge: CGFloat = 2
    static let lift: CGFloat = 6
    static let target: CGFloat = 48
    static let previewSize: CGFloat = 120
    static let previewHeight: CGFloat = 144
    static let pressDuration: TimeInterval = 0.18

    static func face(_ id: GameID) -> Color {
        switch id {
        case .blockGrid, .minesweeper: green
        case .klondike, .wordScramble: coral
        case .sudoku: blue
        case .game2048: yellow
        }
    }

    static func well(_ id: GameID) -> Color {
        switch id {
        case .blockGrid, .minesweeper: greenFill
        case .klondike, .wordScramble: coralFill
        case .sudoku: blueFill
        case .game2048: yellowFill
        }
    }

    static func boardWell(_ id: GameID) -> Color {
        switch id {
        case .blockGrid, .minesweeper: adaptive(0xc8f2d3, 0x274a3a)
        case .klondike, .wordScramble: adaptive(0xffddd4, 0x4d3236)
        case .sudoku: adaptive(0xb9e5fb, 0x22445a)
        case .game2048: adaptive(0xfff0b4, 0x4a4428)
        }
    }

    static func boardEdge(_ id: GameID) -> Color {
        switch id {
        case .blockGrid, .minesweeper: adaptive(0x173c43, 0x76be91)
        case .klondike, .wordScramble: adaptive(0x173c43, 0xe88d84)
        case .sudoku: adaptive(0x173c43, 0x74b4d7)
        case .game2048: adaptive(0x173c43, 0xe5c360)
        }
    }

    nonisolated private static func color(_ hex: UInt32) -> Color {
        Color(uiColor: uiColor(hex))
    }

    nonisolated private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255,
            alpha: 1
        )
    }

    nonisolated private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            uiColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

struct GameMenuButtonStyle: ButtonStyle {
    enum Role {
        case utility, shuffle, game(GameID)
    }

    var role: Role = .utility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    private var palette: (fill: Color, foreground: Color, outline: Color) {
        switch role {
        case .utility: (GameMenuTheme.utilitySurface, GameMenuTheme.text, GameMenuTheme.utilityOutline)
        case .shuffle: (GameMenuTheme.yellow, GameMenuTheme.ink, GameMenuTheme.ink)
        case .game(let id): (GameMenuTheme.face(id), GameMenuTheme.ink, GameMenuTheme.ink)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let radius = if case .game = role { GameMenuTheme.radius } else { GameMenuTheme.smallRadius }
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let pressed = configuration.isPressed
        let palette = self.palette
        configuration.label
            .foregroundStyle(palette.foreground)
            .background {
                shape.fill(palette.fill)
                    .shadow(
                        color: GameMenuTheme.depth,
                        radius: 0,
                        y: pressed && !reduceMotion ? GameMenuTheme.edge : GameMenuTheme.lift
                    )
                    .overlay(shape.strokeBorder(palette.outline, lineWidth: GameMenuTheme.edge))
            }
            .offset(y: pressed && !reduceMotion ? GameMenuTheme.unit : 0)
            .opacity(isEnabled ? (pressed && reduceMotion ? 0.8 : 1) : 0.5)
            .animation(
                reduceMotion ? nil : .easeOut(duration: GameMenuTheme.pressDuration),
                value: pressed
            )
            .contentShape(shape)
    }
}
