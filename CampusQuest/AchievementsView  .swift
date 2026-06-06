//
//  AchievementsView.swift
//  CampusQuest
//
//  Shows all badges as a collectible grid: earned ones in color, locked
//  ones dimmed with a lock and a hint on how to unlock them. A header
//  summarizes "x / total badges earned".
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
        Badge(id: "First Word",
              title: "First Word",
              detail: "Find your very first word.",
              icon: "a.circle.fill"),
        Badge(id: "Lab Starter",
              title: "Lab Starter",
              detail: "Complete your first level.",
              icon: "flask.fill"),
        Badge(id: "Halfway There",
              title: "Halfway There",
              detail: "Complete 3 levels.",
              icon: "flag.checkered"),
        Badge(id: "Perfect Lab",
              title: "Perfect Lab",
              detail: "Finish a level with no wrong guesses.",
              icon: "star.circle.fill"),
        Badge(id: "3-Day Streak",
              title: "3-Day Streak",
              detail: "Play 3 days in a row.",
              icon: "flame.fill"),
        Badge(id: "Major Master",
              title: "Major Master",
              detail: "Complete every level in a major.",
              icon: "graduationcap.fill")
    ]
}

struct AchievementsView: View {
    @Query private var progressList: [PlayerProgress]
    private var progress: PlayerProgress? { progressList.first }
    private var earned: Set<String> { Set(progress?.earnedBadges ?? []) }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                    .padding(.horizontal)
                    .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Badge.all) { badge in
                        BadgeTile(badge: badge, unlocked: earned.contains(badge.id))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(LinearGradient.pageBackground.ignoresSafeArea())
        .navigationTitle("Awards")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        let total = Badge.all.count
        let count = earned.count
        let streak = progress?.currentStreak ?? 0

        return GlassCard(cornerRadius: AppRadius.largeCard) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.icon)
                            .fill(LinearGradient.brand)
                            .frame(width: 56, height: 56)
                        Image(systemName: "rosette")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(count) / \(total) badges earned")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppColor.ink)
                        Text(streak > 0 ? "🔥 \(streak)-day streak" : "Play daily to build a streak")
                            .font(.caption)
                            .foregroundStyle(AppColor.inkSecondary)
                    }

                    Spacer()
                }

                ProgressView(value: total > 0 ? Double(count) / Double(total) : 0)
                    .tint(AppColor.primary)
            }
            .padding()
        }
    }
}

private struct BadgeTile: View {
    let badge: Badge
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(unlocked ? AppColor.primary.opacity(0.16) : AppColor.locked.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: unlocked ? badge.icon : "lock.fill")
                    .font(.title2.bold())
                    .foregroundStyle(unlocked ? AppColor.primary : AppColor.locked)
            }

            Text(badge.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)

            Text(badge.detail)
                .font(.caption2)
                .foregroundStyle(AppColor.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if unlocked {
                Label("Earned", systemImage: "checkmark.seal.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColor.success)
            } else {
                Text("Locked")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColor.locked)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 180)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .fill(Color.white.opacity(unlocked ? 0.92 : 0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(
                    unlocked ? AppColor.primary.opacity(0.20) : AppColor.locked.opacity(0.18),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(unlocked ? 0.07 : 0.03), radius: 8, y: 3)
        .opacity(unlocked ? 1 : 0.85)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
