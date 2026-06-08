//
//  StreakManager.swift
//  CampusQuest
//
//  Centralizes the day-based play streak. Call `updateStreak(in:)` when the
//  app launches and after a level is completed. The actual day-comparison
//  logic lives on `PlayerProgress` (see `updateStreakForToday()`), so the
//  rules stay in one place and existing activity tracking keeps working.
//

import Foundation
import SwiftData

@MainActor
enum StreakManager {
    /// Updates the play streak for today and saves it.
    ///
    /// Rules (implemented in `PlayerProgress.touchToday`):
    /// - Same calendar day as last play: no change.
    /// - Yesterday: `currentStreak += 1`.
    /// - Older (a day was skipped) or never played: `currentStreak = 1`.
    /// - `longestStreak` is raised whenever `currentStreak` exceeds it.
    static func updateStreak(in context: ModelContext) {
        let progress = PlayerProgress.current(in: context)
        progress.updateStreakForToday()
        try? context.save()
    }
}
