import SwiftUI
import OffPlayCore

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    var body: some View {
        NavigationStack {
            Form {
                Section("Tampilan") {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { appearance in
                        Button { store.setAppearance(appearance) } label: {
                            HStack {
                                Text(appearance.name)
                                Spacer()
                                if store.library.appearance == appearance { Image(systemName: "checkmark").foregroundStyle(GameTheme.accent) }
                            }.frame(minHeight: 48).foregroundStyle(GameTheme.ink)
                        }.accessibilityIdentifier("settings.theme.\(appearance.rawValue)")
                    }
                }
                Section("Umpan balik") {
                    Toggle("Getaran permainan", isOn: Binding(get: { store.library.hapticsEnabled }, set: store.setHaptics))
                        .frame(minHeight: 48).accessibilityIdentifier("settings.haptics")
                }
                Section("Tentang OffPlay") {
                    Text("Enam permainan offline. Tap Judul untuk langsung melanjutkan Sesi.")
                    Text("Angka dan waktu bermain disimpan di perangkat ini.").foregroundStyle(GameTheme.secondary)
                    if let content = store.content {
                        Text("\(content.puzzles.count) papan Sudoku · \(content.wordGroups.count) kelompok huruf")
                            .font(.footnote).foregroundStyle(GameTheme.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(GameTheme.canvas).tint(GameTheme.accent)
            .navigationTitle("Pengaturan").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Selesai") { store.modal = nil }.frame(minHeight: 48).keyboardShortcut(.cancelAction).accessibilityIdentifier("settings.done") }
        }
    }
}
