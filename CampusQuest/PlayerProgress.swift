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
    /// Total correct quiz answers across all sessions (drives Quiz Master).
    var quizCorrectTotal: Int = 0
    /// Day-based play streak.
    var currentStreak: Int = 0
    /// Highest day-based streak the player has ever reached.
    var longestStreak: Int = 0
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

    // MARK: Playable Daily Challenge (the deterministic mini-game)
    /// When the player last finished the playable Daily Challenge. nil = never.
    /// Tracked separately from normal levels so the mini-game never affects
    /// `completedLevels` or the regular level progression.
    var lastDailyCompletedDate: Date? = nil

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
        quizCorrectTotal += correctCount
        _ = awardAchievements()
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
            // No duplicate XP, but newly met achievements can still unlock.
            let extra = awardAchievements()
            return extra.isEmpty ? nil : LevelReward(xpGained: 0, newBadges: extra)
        }
        completedLevels.append(levelTitle)

        let xpGained = wordCount * 10 + 50
        totalXP += xpGained
        dailyXP += xpGained
        dailyLevels += 1

        let newBadges = awardAchievements()
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
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
            lastPlayedDay = today
        }
    }

    /// Marks today as an active day and updates the play streak using the same
    /// rules as any other activity. Safe to call on app launch; the caller is
    /// responsible for saving the context (see `StreakManager`).
    func updateStreakForToday() {
        touchToday()
    }

    /// Spends XP if the player can afford it. Returns true on success.
    @discardableResult
    func spendXP(_ amount: Int) -> Bool {
        guard totalXP >= amount else { return false }
        totalXP -= amount
        return true
    }

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

    /// True if the playable Daily Challenge mini-game was already finished today.
    var didCompleteDailyChallengeToday: Bool {
        guard let last = lastDailyCompletedDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    /// Records a finished playable Daily Challenge. Grants a one-time daily
    /// bonus (added to total + today's XP counter), updates the streak, and
    /// re-evaluates achievements. Does NOT touch `completedLevels`, so the
    /// mini-game stays separate from normal level progression. Returns the
    /// reward the first time only; nil if it was already completed today.
    @discardableResult
    func recordDailyChallengeGame(bonusXP: Int) -> LevelReward? {
        touchToday()
        guard !didCompleteDailyChallengeToday else { return nil }
        lastDailyCompletedDate = Date()
        totalXP += bonusXP
        dailyXP += bonusXP
        let newBadges = awardAchievements()
        return LevelReward(xpGained: bonusXP, newBadges: newBadges)
    }

    /// Records any achievements whose targets are now met. Persists their ids
    /// in `earnedBadges` and returns the titles of the newly unlocked ones.
    @discardableResult
    private func awardAchievements() -> [String] {
        var newlyUnlocked: [String] = []
        for achievement in Achievement.all where achievement.isUnlocked(self) {
            if !earnedBadges.contains(achievement.id) {
                earnedBadges.append(achievement.id)
                newlyUnlocked.append(achievement.title)
            }
        }
        return newlyUnlocked
    }
}
