//
//  DailyChallenge.swift
//  CampusQuest
//
//  A small daily goal shown on the home screen. The challenge is chosen
//  deterministically from the date and tracked against PlayerProgress's
//  per-day counters, so it resets every calendar day.
//

import Foundation

/// One of the rotating daily goals.
enum DailyChallengeKind {
    case solveWords(Int)
    case earnXP(Int)
    case completeLevels(Int)
}

struct DailyChallenge {
    let kind: DailyChallengeKind
    let rewardXP: Int

    /// Today's challenge, rotating through the three kinds by day of year.
    static func today(date: Date = Date()) -> DailyChallenge {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        switch day % 3 {
        case 0:  return DailyChallenge(kind: .solveWords(5), rewardXP: 50)
        case 1:  return DailyChallenge(kind: .earnXP(50), rewardXP: 30)
        default: return DailyChallenge(kind: .completeLevels(3), rewardXP: 60)
        }
    }

    var title: String {
        switch kind {
        case .solveWords(let n):     return "Solve \(n) words"
        case .earnXP(let n):         return "Earn \(n) XP"
        case .completeLevels(let n): return "Complete \(n) levels"
        }
    }

    var iconName: String {
        switch kind {
        case .solveWords:     return "textformat.abc"
        case .earnXP:         return "star.fill"
        case .completeLevels: return "checkmark.seal.fill"
        }
    }

    var target: Int {
        switch kind {
        case .solveWords(let n), .earnXP(let n), .completeLevels(let n): return n
        }
    }

    /// Today's progress toward the goal, from the player's daily counters.
    func progress(for player: PlayerProgress) -> Int {
        // Counters only reflect today once a recording method has rolled the
        // day over; guard against showing stale values from a previous day.
        guard player.dailyDay == PlayerProgress.dayString() else { return 0 }
        switch kind {
        case .solveWords:     return player.dailyWords
        case .earnXP:         return player.dailyXP
        case .completeLevels: return player.dailyLevels
        }
    }
}
