import Foundation

public enum SaveFileError: Error, LocalizedError {
    case invalid, unsupportedVersion(Int)
    public var errorDescription: String? {
        switch self {
        case .invalid: "Simpanan tidak dapat dibaca."
        case let .unsupportedVersion(version): "Simpanan memakai versi \(version) yang belum didukung app ini."
        }
    }
}

public struct LoadedLibrary: Sendable {
    public let library: GameLibrary
    public let usedBackup: Bool
}

public struct LibraryFileStore: Sendable {
    public let url: URL
    public var backupURL: URL { url.appendingPathExtension("bak") }
    public init(url: URL) { self.url = url }

    public func load() throws -> LoadedLibrary? {
        let manager = FileManager.default
        if manager.fileExists(atPath: url.path) {
            do { return LoadedLibrary(library: try decode(Data(contentsOf: url)), usedBackup: false) }
            catch SaveFileError.unsupportedVersion(let version) { throw SaveFileError.unsupportedVersion(version) }
            catch {
                if manager.fileExists(atPath: backupURL.path) {
                    return LoadedLibrary(library: try decode(Data(contentsOf: backupURL)), usedBackup: true)
                }
                throw error
            }
        }
        if manager.fileExists(atPath: backupURL.path) {
            return LoadedLibrary(library: try decode(Data(contentsOf: backupURL)), usedBackup: true)
        }
        return nil
    }

    public func save(_ library: GameLibrary) throws {
        try library.validate()
        let manager = FileManager.default
        try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let bytes = try encoder.encode(library)
        if manager.fileExists(atPath: url.path) {
            let existing = try Data(contentsOf: url)
            let readable: Bool
            do {
                _ = try decode(existing)
                readable = true
            } catch SaveFileError.unsupportedVersion(let version) {
                throw SaveFileError.unsupportedVersion(version)
            } catch {
                readable = false
            }
            if readable {
                try existing.write(to: backupURL, options: .atomic)
            } else {
                let preserved = url.appendingPathExtension("unreadable-\(UUID().uuidString)")
                try existing.write(to: preserved, options: .atomic)
            }
        }
        try bytes.write(to: url, options: .atomic)
    }

    private func decode(_ bytes: Data) throws -> GameLibrary {
        struct Header: Decodable { let version: Int }
        let header = try JSONDecoder().decode(Header.self, from: bytes)
        guard header.version == GameLibrary.currentVersion else { throw SaveFileError.unsupportedVersion(header.version) }
        let library = try JSONDecoder().decode(GameLibrary.self, from: bytes)
        try library.validate()
        return library
    }
}
