//
//  LevelGameModel.swift
//  CampusQuest
//
//  Drives the gameplay for one level: which word is current, the
//  shuffled letters, progress, and completion.
//

import Foundation

/// One letter on the wheel. Each tile is unique even if letters repeat
/// (e.g. the two "o"s in "loop").
struct LetterTile: Identifiable, Equatable {
    let id = UUID()
    let letter: String
}

@Observable
final class LevelGameModel {
    let level: GameLevel
    private(set) var currentIndex = 0
    private(set) var isLevelComplete = false
    /// The word just found correctly (used to show its definition card).
    private(set) var lastFoundWord: WordItem?
    /// The shuffled letters for the current word.
    private(set) var tiles: [LetterTile] = []
    /// Number of wrong guesses this run (0 = a perfect level).
    private(set) var mistakeCount = 0

    /// How many words have been found so far.
    var foundCount: Int { currentIndex }

    init(level: GameLevel) {
        self.level = level
        startCurrentWord()
    }

    /// The word the player is currently trying to spell.
    var currentWord: WordItem? {
        guard currentIndex < level.words.count else { return nil }
        return level.words[currentIndex]
    }

    /// e.g. "3 / 10"
    var progressText: String {
        "\(currentIndex) / \(level.words.count)"
    }

    /// How far through the level we are, from 0 to 1.
    var progressFraction: Double {
        guard !level.words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(level.words.count)
    }

    /// Prepares the shuffled tiles for the current word.
    func startCurrentWord() {
        guard let word = currentWord else {
            tiles = []
            isLevelComplete = true
            return
        }
        tiles = word.word.map { LetterTile(letter: String($0)) }.shuffled()
        // Avoid the rare case where the shuffle already spells the word.
        if word.word.count > 1, tiles.map(\.letter).joined() == word.word {
            tiles.shuffle()
        }
    }

    /// Checks a guessed word against the current target.
    /// Returns true if correct (and remembers it for the definition card).
    func submit(guess: String) -> Bool {
        guard let word = currentWord else { return false }
        if guess.lowercased() == word.word.lowercased() {
            lastFoundWord = word
            return true
        }
        if !guess.isEmpty { mistakeCount += 1 }
        return false
    }

    /// Moves on to the next word (called after the definition card).
    func advance() {
        currentIndex += 1
        lastFoundWord = nil
        startCurrentWord()
    }

    /// Re-shuffles the current tiles (used by the Shuffle button).
    func shuffleTiles() {
        tiles.shuffle()
    }
}
