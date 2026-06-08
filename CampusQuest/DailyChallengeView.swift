//
//  DailyChallengeView.swift
//  CampusQuest
//
//  The playable Daily Challenge screen. It builds today's deterministic word
//  set (see `DailyChallengeGame`) and runs it through the normal gameplay by
//  reusing `LevelView` in `.daily` mode, so finishing it grants a one-time
//  bonus without affecting normal level progression.
//

import SwiftUI
import SwiftData

struct DailyChallengeView: View {
    @Environment(ContentStore.self) private var store

    var body: some View {
        Group {
            if let level = DailyChallengeGame.dailyLevel(from: store.department) {
                LevelView(level: level, totalLevels: 1, mode: .daily)
            } else {
                ContentUnavailableView(
                    "Daily Challenge Unavailable",
                    systemImage: "calendar.badge.exclamationmark",
                    description: Text("Today's words could not be loaded. Please try again later.")
                )
            }
        }
        .navigationTitle("Daily Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }
}
