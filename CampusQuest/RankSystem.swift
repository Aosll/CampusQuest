//
//  RankSystem.swift
//  CampusQuest
//
//  Turns total XP into an academic rank/level and the progress toward
//  the next rank. Pure logic, computed from XP we already store.
//

import Foundation

struct Rank {
    let level: Int
    let title: String
    let minXP: Int
}

struct RankProgress {
    let level: Int
    let title: String
    let xp: Int
    let nextTitle: String?
    let xpIntoRank: Int
    let xpForNext: Int
    let fraction: Double

    var percent: Int { Int((fraction * 100).rounded()) }
}

enum RankSystem {
    static let ranks: [Rank] = [
        Rank(level: 1, title: "Freshman",  minXP: 0),
        Rank(level: 2, title: "Sophomore", minXP: 150),
        Rank(level: 3, title: "Junior",    minXP: 350),
        Rank(level: 4, title: "Senior",    minXP: 600),
        Rank(level: 5, title: "Graduate",  minXP: 1000),
        Rank(level: 6, title: "Master",    minXP: 1500),
        Rank(level: 7, title: "Doctor",    minXP: 2200),
        Rank(level: 8, title: "Professor", minXP: 3000)
    ]

    /// Computes the current rank and progress toward the next one.
    static func progress(forXP xp: Int) -> RankProgress {
        // Current rank = the highest rank whose minXP the player has reached.
        var current = ranks[0]
        for rank in ranks where xp >= rank.minXP {
            current = rank
        }

        let nextRank = ranks.first { $0.level == current.level + 1 }

        guard let next = nextRank else {
            // Already at the top rank.
            return RankProgress(level: current.level, title: current.title, xp: xp,
                                nextTitle: nil, xpIntoRank: 0, xpForNext: 0, fraction: 1)
        }

        let span = next.minXP - current.minXP
        let into = xp - current.minXP
        let fraction = span > 0 ? Double(into) / Double(span) : 0

        return RankProgress(level: current.level, title: current.title, xp: xp,
                            nextTitle: next.title, xpIntoRank: into, xpForNext: span,
                            fraction: min(max(fraction, 0), 1))
    }
}
