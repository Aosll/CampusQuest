//
//  AchievementsView.swift
//  CampusQuest
//
//  Shows all badges: earned ones in color, locked ones dimmed with a
//  lock and a hint on how to unlock them.
//

import SwiftUI
import SwiftData

/// One badge in the catalog. `id` must match the ids awarded in PlayerProgress.
struct Badge: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String

    static let all: [Badge] = [
        Badge(id: "First Steps",
              title: "First Steps",
              detail: "Complete your first level.",
              icon: "figure.walk"),
        Badge(id: "Halfway There",
              title: "Halfway There",
              detail: "Complete 3 levels.",
              icon: "flag.checkered"),
        Badge(id: "CS Graduate",
              title: "CS Graduate",
              detail: "Complete all levels in Computer Engineering.",
              icon: "graduationcap.fill")
    ]
}

struct AchievementsView: View {
    @Query private var progressList: [PlayerProgress]
    private var earned: Set<String> { Set(progressList.first?.earnedBadges ?? []) }

    var body: some View {
        List {
            ForEach(Badge.all) { badge in
                let unlocked = earned.contains(badge.id)
                HStack(spacing: 16) {
                    Image(systemName: unlocked ? badge.icon : "lock.fill")
                        .font(.title2)
                        .foregroundStyle(unlocked ? Color.accentColor : .secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle().fill(unlocked ? Color.accentColor.opacity(0.15)
                                                   : Color(.tertiarySystemBackground))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(badge.title).font(.headline)
                        Text(badge.detail).font(.caption).foregroundStyle(.secondary)
                    }

                    Spacer()

                    if unlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(.vertical, 4)
                .opacity(unlocked ? 1 : 0.6)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
