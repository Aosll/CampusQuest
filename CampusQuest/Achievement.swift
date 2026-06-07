//
//  Achievement.swift
//  CampusQuest
//
//  A tiered achievement catalog. Each achievement has a target and a metric
//  computed from PlayerProgress, so the UI can show locked items with a
//  live progress bar (e.g. "73 / 100 Words Solved").
//

import SwiftUI

enum AchievementTier: String {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var color: Color {
        switch self {
        case .bronze:   return Color(red: 0.80, green: 0.52, blue: 0.25)
        case .silver:   return Color(red: 0.62, green: 0.66, blue: 0.72)
        case .gold:     return Color(red: 0.95, green: 0.74, blue: 0.22)
        case .platinum: return Color(red: 0.40, green: 0.78, blue: 0.92)
        }
    }
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let tier: AchievementTier
    let target: Int
    /// Current raw value toward the target, read from saved progress.
    let metric: (PlayerProgress) -> Int

    func current(_ p: PlayerProgress) -> Int { min(metric(p), target) }
    func isUnlocked(_ p: PlayerProgress) -> Bool { metric(p) >= target }
    func fraction(_ p: PlayerProgress) -> Double {
        target > 0 ? min(Double(metric(p)) / Double(target), 1) : 1
    }

    /// All achievements the player has currently unlocked.
    static func unlocked(for p: PlayerProgress) -> [Achievement] {
        all.filter { $0.isUnlocked(p) }
    }

    // Category-level completion targets (match current Computer Engineering content).
    private static func completed(_ p: PlayerProgress, prefix: String) -> Int {
        p.completedLevels.filter { $0.hasPrefix(prefix) }.count
    }

    static let all: [Achievement] = [
        Achievement(id: "xp_100", title: "First 100 XP", detail: "Earn 100 XP.",
                    icon: "star.fill", tier: .bronze, target: 100) { $0.totalXP },
        Achievement(id: "xp_500", title: "First 500 XP", detail: "Earn 500 XP.",
                    icon: "star.circle.fill", tier: .silver, target: 500) { $0.totalXP },
        Achievement(id: "xp_1000", title: "First 1000 XP", detail: "Earn 1000 XP.",
                    icon: "sparkles", tier: .gold, target: 1000) { $0.totalXP },
        Achievement(id: "levels_10", title: "10 Levels Completed", detail: "Complete 10 levels.",
                    icon: "flag.checkered", tier: .silver, target: 10) { $0.completedLevels.count },
        Achievement(id: "words_50", title: "50 Words Solved", detail: "Solve 50 words.",
                    icon: "textformat.abc", tier: .silver, target: 50) { $0.wordsFound },
        Achievement(id: "words_100", title: "100 Words Solved", detail: "Solve 100 words.",
                    icon: "character.book.closed.fill", tier: .gold, target: 100) { $0.wordsFound },
        Achievement(id: "quiz_master", title: "Quiz Master", detail: "Answer 50 quiz questions correctly.",
                    icon: "checkmark.seal.fill", tier: .gold, target: 50) { $0.quizCorrectTotal },
        Achievement(id: "cyber_expert", title: "Cybersecurity Expert", detail: "Complete every Cybersecurity level.",
                    icon: "lock.shield.fill", tier: .platinum, target: 4) { completed($0, prefix: "Cybersecurity") },
        Achievement(id: "db_explorer", title: "Database Explorer", detail: "Complete every Databases level.",
                    icon: "cylinder.split.1x2.fill", tier: .gold, target: 3) { completed($0, prefix: "Databases") },
    ]
}
