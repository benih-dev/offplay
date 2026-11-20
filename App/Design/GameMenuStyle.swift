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
    static let green = color(0x70d99b)
    static let greenFill = color(0xc8f2d3)
    static let greenDeep = color(0x0d5b3d)
    static let greenTile = color(0x168458)
    static let yellow = color(0xffda65)
    static let yellowFill = color(0xfff0b4)
    static let coral = color(0xff9486)
    static let coralFill = color(0xffddd4)
    static let redInk = color(0xa32e38)
    static let blue = color(0x79c8ee)
    static let blueFill = color(0xb9e5fb)
    static let blueInk = color(0x164f76)

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
    var fill: Color = GameMenuTheme.paper
    var radius: CGFloat = GameMenuTheme.smallRadius
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(GameMenuTheme.ink)
            .background(fill, in: shape)
            .overlay(shape.strokeBorder(GameMenuTheme.ink, lineWidth: GameMenuTheme.edge))
            .shadow(
                color: GameMenuTheme.ink,
                radius: 0,
                y: pressed && !reduceMotion ? GameMenuTheme.edge : GameMenuTheme.lift
            )
            .offset(y: pressed && !reduceMotion ? GameMenuTheme.unit : 0)
            .opacity(isEnabled ? (pressed && reduceMotion ? 0.8 : 1) : 0.5)
            .animation(
                reduceMotion ? nil : .easeOut(duration: GameMenuTheme.pressDuration),
                value: pressed
            )
            .contentShape(shape)
    }
}
