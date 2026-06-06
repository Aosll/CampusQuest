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

    /// Records a level completion. Returns the reward the FIRST time only;
    /// returns nil if the level was already completed before (no double XP).
    func recordCompletion(levelTitle: String,
                          wordCount: Int,
                          totalLevels: Int) -> LevelReward? {
        guard !completedLevels.contains(levelTitle) else { return nil }
        completedLevels.append(levelTitle)

        let xpGained = wordCount * 10 + 50
        totalXP += xpGained

        let newBadges = awardBadges(totalLevels: totalLevels)
        return LevelReward(xpGained: xpGained, newBadges: newBadges)
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
        if done >= 1 { give("First Steps") }
        if done >= 3 { give("Halfway There") }
        if done >= totalLevels { give("CS Graduate") }
        return awarded
    }
}
