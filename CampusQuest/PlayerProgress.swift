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

    // MARK: Daily challenge counters (reset each calendar day)
    /// The day the daily counters below belong to ("yyyy-MM-dd").
    var dailyDay: String = ""
    /// Words found today.
    var dailyWords: Int = 0
    /// XP earned today.
    var dailyXP: Int = 0
    /// Levels completed today.
    var dailyLevels: Int = 0
    /// Day on which today's daily-challenge reward was claimed.
    var dailyChallengeClaimedDay: String = ""

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
        touchToday()
        wordsFound += 1
        dailyWords += 1
        return wordsFound
    }

    /// Records a finished quiz: awards 10 XP per correct answer, updates the
    /// day streak, and re-evaluates streak badges. Returns the XP gained.
    @discardableResult
    func recordQuizFinished(correctCount: Int) -> Int {
        touchToday()
        let xp = correctCount * 10
        totalXP += xp
        dailyXP += xp
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
        touchToday()
        if perfect { bestPerfectLab = true }

        guard !completedLevels.contains(levelTitle) else {
            // No duplicate XP, but a first-ever perfect run can still unlock a badge.
            let extra = awardBadges(totalLevels: totalLevels)
            return extra.isEmpty ? nil : LevelReward(xpGained: 0, newBadges: extra)
        }
        completedLevels.append(levelTitle)

        let xpGained = wordCount * 10 + 50
        totalXP += xpGained
        dailyXP += xpGained
        dailyLevels += 1

        let newBadges = awardBadges(totalLevels: totalLevels)
        return LevelReward(xpGained: xpGained, newBadges: newBadges)
    }

    /// "yyyy-MM-dd" string for a date (default today), in a stable locale.
    static func dayString(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// Rolls daily counters over at the start of a new day and updates the
    /// day-based play streak. Called by every progress-recording method.
    private func touchToday() {
        let today = Self.dayString()

        // Reset daily-challenge counters when the calendar day changes.
        if dailyDay != today {
            dailyDay = today
            dailyWords = 0
            dailyXP = 0
            dailyLevels = 0
        }

        // Update the play streak once per day.
        if today != lastPlayedDay {
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
               Self.dayString(yesterday) == lastPlayedDay {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            lastPlayedDay = today
        }
    }

    /// Spends XP if the player can afford it. Returns true on success.
    @discardableResult
    func spendXP(_ amount: Int) -> Bool {
        guard totalXP >= amount else { return false }
        totalXP -= amount
        return true
    }

    /// The most recently earned badge id, if any (for the home widget).
    var recentBadgeID: String? { earnedBadges.last }

    /// True if today's daily-challenge reward has already been claimed.
    var dailyChallengeClaimedToday: Bool { dailyChallengeClaimedDay == Self.dayString() }

    /// Grants the daily-challenge reward once per day when the target is met.
    /// Returns the XP granted (0 if already claimed or not yet complete).
    @discardableResult
    func claimDailyChallenge(reward: Int, progress: Int, target: Int) -> Int {
        let today = Self.dayString()
        guard progress >= target, dailyChallengeClaimedDay != today else { return 0 }
        dailyChallengeClaimedDay = today
        totalXP += reward
        return reward
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
