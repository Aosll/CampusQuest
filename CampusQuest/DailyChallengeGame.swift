//
//  DailyChallengeGame.swift
//  CampusQuest
//
//  Builds the playable Daily Challenge: a fixed-size word set chosen
//  DETERMINISTICALLY from today's date, so everyone (and every session) on
//  the same calendar day gets exactly the same words. It reuses the normal
//  gameplay by producing a synthetic `GameLevel` that `LevelView` can run.
//

import Foundation

/// A tiny, deterministic random number generator (SplitMix64). Seeding it with
/// the same value always produces the same sequence, which is what lets the
/// daily word set be identical for everyone on a given day.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum DailyChallengeGame {
    /// How many words make up one Daily Challenge.
    static let wordCount = 5
    /// One-time bonus XP for finishing today's Daily Challenge.
    static let bonusXP = 75
    /// Title used for the synthetic level (also shown in the nav bar).
    static let levelTitle = "Daily Challenge"

    /// Today's deterministic word set as a synthetic `GameLevel`, or nil if no
    /// content is loaded. Same date -> same words for everyone.
    static func dailyLevel(from department: Department?, date: Date = Date()) -> GameLevel? {
        guard let department else { return nil }

        // Flatten every word in the department, de-duplicated by the word text
        // and sorted so the starting pool order is stable before shuffling.
        var seen = Set<String>()
        let pool = department.levels
            .flatMap(\.words)
            .filter { seen.insert($0.word.lowercased()).inserted }
            .sorted { $0.word < $1.word }

        guard !pool.isEmpty else { return nil }

        var generator = SeededGenerator(seed: seed(for: date))
        let chosen = Array(pool.shuffled(using: &generator).prefix(wordCount))
        return GameLevel(title: levelTitle, words: chosen)
    }

    /// A stable per-calendar-day seed derived from "yyyy-MM-dd" (digits only).
    private static func seed(for date: Date) -> UInt64 {
        let day = PlayerProgress.dayString(date).filter(\.isNumber)
        return UInt64(day) ?? 0
    }
}
