//
//  PlayerProgress.swift
//  CampusQuest
//
//  The saved player progress: total XP, completed levels, and badges.
//  Stored on the device with SwiftData so it survives app restarts.
//

import Foundation
import SwiftData

@Model
final class PlayerProgress {
    var totalXP: Int
    var completedLevels: [String]
    var earnedBadges: [String]
    /// Number of distinct words the player has ever found (drives word badges).
    var wordsFound: Int = 0
    /// Best single-level streak of correct guesses without a mistake.
    var bestPerfectLab: Bool = false
    /// Day-based play streak.
    var currentStreak: Int = 0
    /// Last day the player was active, as "yyyy-MM-dd". Empty = never.
    var lastPlayedDay: String = ""

    init(totalXP: Int = 0,
         completedLevels: [String] = [],
         earnedBadges: [String] = []) {
        self.totalXP = totalXP
        self.completedLevels = completedLevels
        self.earnedBadges = earnedBadges
    }
}

/// What the player earned by finishing a level (shown on the results screen).
struct LevelReward {
    let xpGained: Int
    let newBadges: [String]
}

extension PlayerProgress {
    /// Fetches the single progress record, creating it the first time.
    static func current(in context: ModelContext) -> PlayerProgress {
        let descriptor = FetchDescriptor<PlayerProgress>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let new = PlayerProgress()
        context.insert(new)
        return new
    }

    func isCompleted(_ levelTitle: String) -> Bool {
        completedLevels.contains(levelTitle)
    }

    /// Counts one found word and updates the day streak. Safe to call on
    /// every correct guess. Returns the new running total of words found.
    @discardableResult
    func registerWordFound() -> Int {
        wordsFound += 1
        registerActivityToday()
        return wordsFound
    }

    /// Records a finished quiz: awards 10 XP per correct answer, updates the
    /// day streak, and re-evaluates streak badges. Returns the XP gained.
    @discardableResult
    func recordQuizFinished(correctCount: Int) -> Int {
        registerActivityToday()
        let xp = correctCount * 10
        totalXP += xp
        // Re-evaluate badges; Int.max guards against awarding "Major Master".
        _ = awardBadges(totalLevels: Int.max)
        return xp
    }

    /// Records a level completion. `perfect` means no wrong guesses.
    /// Returns the reward the FIRST time only; returns nil if the level was
    /// already completed before (no double XP), though badges may still be
    /// re-evaluated for things like a first perfect run.
    func recordCompletion(levelTitle: String,
                          wordCount: Int,
                          totalLevels: Int,
                          perfect: Bool = false) -> LevelReward? {
        registerActivityToday()
        if perfect { bestPerfectLab = true }

        guard !completedLevels.contains(levelTitle) else {
            // No duplicate XP, but a first-ever perfect run can still unlock a badge.
            let extra = awardBadges(totalLevels: totalLevels)
            return extra.isEmpty ? nil : LevelReward(xpGained: 0, newBadges: extra)
        }
        completedLevels.append(levelTitle)

        let xpGained = wordCount * 10 + 50
        totalXP += xpGained

        let newBadges = awardBadges(totalLevels: totalLevels)
        return LevelReward(xpGained: xpGained, newBadges: newBadges)
    }

    /// Updates the day-based streak: +1 for consecutive days, reset to 1
    /// after a gap, no-op if already counted today.
    private func registerActivityToday() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let today = formatter.string(from: Date())
        guard today != lastPlayedDay else { return }

        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
           formatter.string(from: yesterday) == lastPlayedDay {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        lastPlayedDay = today
    }

    /// Gives any badges whose thresholds are now met. Returns the new ones.
    private func awardBadges(totalLevels: Int) -> [String] {
        var awarded: [String] = []
        func give(_ id: String) {
            if !earnedBadges.contains(id) {
                earnedBadges.append(id)
                awarded.append(id)
            }
        }
        let done = completedLevels.count
        if wordsFound >= 1 { give("First Word") }
        if done >= 1 { give("Lab Starter") }
        if done >= 3 { give("Halfway There") }
        if bestPerfectLab { give("Perfect Lab") }
        if currentStreak >= 3 { give("3-Day Streak") }
        if done >= totalLevels { give("Major Master") }
        return awarded
    }
}
