import Foundation

public struct WordGroup: Codable, Equatable, Sendable {
    public let id: String
    public let words: [String]
    public var length: Int { id.count }
    public init(words: [String]) {
        precondition(!words.isEmpty)
        self.words = words.sorted()
        id = String(words[0].sorted())
    }
}

public struct WordScrambleGame: Codable, Equatable, Sendable {
    public let group: WordGroup
    public let letters: [String]
    public private(set) var chosen: [Int] = []
    public private(set) var guesses = 0
    public private(set) var isWon = false

    public init(group: WordGroup, seed: UInt64) {
        self.group = group
        var random = RandomSource(seed: seed)
        let original = group.id.map(String.init)
        var candidate = random.shuffled(original)
        // A deterministic permutation fallback also handles unlucky repeated shuffles.
        for _ in 0..<100 where group.words.contains(candidate.joined()) { candidate = random.shuffled(original) }
        if group.words.contains(candidate.joined()) {
            var permutation = original.sorted()
            while group.words.contains(permutation.joined()) && Self.nextPermutation(&permutation) {}
            precondition(!group.words.contains(permutation.joined()))
            candidate = permutation
        }
        letters = candidate
    }

    public var answer: String { chosen.map { letters[$0] }.joined() }
    public var canSubmit: Bool { chosen.count == letters.count && !isWon }

    @discardableResult public mutating func addLetter(at index: Int) -> Bool {
        guard !isWon, letters.indices.contains(index), !chosen.contains(index), chosen.count < letters.count else { return false }
        chosen.append(index)
        return true
    }

    @discardableResult public mutating func removeLetter(at slot: Int) -> Bool {
        guard !isWon, chosen.indices.contains(slot) else { return false }
        chosen.remove(at: slot)
        return true
    }

    @discardableResult public mutating func submit() -> Bool {
        guard canSubmit else { return false }
        guesses += 1
        isWon = group.words.contains(answer.lowercased())
        return true
    }

    private static func nextPermutation(_ values: inout [String]) -> Bool {
        guard values.count > 1 else { return false }
        var pivot = values.count - 2
        while pivot >= 0 && values[pivot] >= values[pivot + 1] { pivot -= 1 }
        guard pivot >= 0 else { return false }
        var next = values.count - 1
        while values[next] <= values[pivot] { next -= 1 }
        values.swapAt(pivot, next)
        values.replaceSubrange((pivot + 1)..., with: values[(pivot + 1)...].reversed())
        return true
    }

    var validForArchive: Bool {
        (4...8).contains(group.length) && !group.words.isEmpty && group.words.allSatisfy { String($0.sorted()) == group.id } &&
        letters.allSatisfy { $0.utf8.count == 1 && (97...122).contains($0.utf8.first!) } &&
        letters.sorted().joined() == group.id && Set(chosen).count == chosen.count &&
        chosen.allSatisfy { letters.indices.contains($0) } && guesses >= 0 &&
        (!isWon || (chosen.count == letters.count && group.words.contains(answer)))
    }
}
