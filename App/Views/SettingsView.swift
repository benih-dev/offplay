import SwiftUI
import OffPlayCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Button { store.setAppearance(appearance) } label: {
                            HStack {
                                Text(appearance.localizedName)
                                Spacer()
                                if store.library.appearance == appearance { Image(systemName: "checkmark").foregroundStyle(GameTheme.accent) }
                            }.frame(minHeight: 48).foregroundStyle(GameTheme.ink)
                        }.accessibilityIdentifier("settings.theme.\(appearance.rawValue)")
                    }
                }
                Section("Feedback") {
                    Toggle("Game Haptics", isOn: Binding(get: { store.library.hapticsEnabled }, set: store.setHaptics))
                        .frame(minHeight: 48).accessibilityIdentifier("settings.haptics")
                }
                Section("About OffPlay") {
                    Text("Six offline games. Tap a game to pick up where you left off.")
                    Text("Stats and play time are stored on this device.").foregroundStyle(GameTheme.secondary)
                    if let content = store.content {
                        Text("Sudoku boards: \(content.puzzles.count) · Letter groups: \(content.wordGroups.count)")
                            .font(.footnote).foregroundStyle(GameTheme.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(GameTheme.canvas).tint(GameTheme.accent)
            .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { store.modal = nil }.frame(minHeight: 48).keyboardShortcut(.cancelAction).accessibilityIdentifier("settings.done") }
        }
    }
}
