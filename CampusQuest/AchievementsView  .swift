//
//  AchievementsView.swift
//  CampusQuest
//
//  A tiered progression system: each achievement shows its tier (Bronze →
//  Platinum) and, while locked, a live progress bar toward its target.
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Query private var progressList: [PlayerProgress]
    private var progress: PlayerProgress? { progressList.first }

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
                    ForEach(Achievement.all) { achievement in
                        AchievementTile(achievement: achievement, progress: progress)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(LinearGradient.pageBackground.ignoresSafeArea())
        .navigationTitle("Awards")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        let total = Achievement.all.count
        let count = progress.map { Achievement.unlocked(for: $0).count } ?? 0
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
                        Text("\(count) / \(total) achievements")
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

private struct AchievementTile: View {
    let achievement: Achievement
    let progress: PlayerProgress?

    private var unlocked: Bool { progress.map { achievement.isUnlocked($0) } ?? false }
    private var current: Int { progress.map { achievement.current($0) } ?? 0 }
    private var fraction: Double { progress.map { achievement.fraction($0) } ?? 0 }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill((unlocked ? achievement.tier.color : AppColor.locked).opacity(0.18))
                    .frame(width: 60, height: 60)
                Image(systemName: unlocked ? achievement.icon : "lock.fill")
                    .font(.title2.bold())
                    .foregroundStyle(unlocked ? achievement.tier.color : AppColor.locked)
            }

            // Tier badge.
            Text(achievement.tier.rawValue.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(achievement.tier.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(achievement.tier.color.opacity(0.16), in: Capsule())

            Text(achievement.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(achievement.detail)
                .font(.caption2)
                .foregroundStyle(AppColor.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Spacer(minLength: 0)

            if unlocked {
                Label("Earned", systemImage: "checkmark.seal.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(AppColor.success)
            } else {
                VStack(spacing: 3) {
                    ProgressView(value: fraction)
                        .tint(achievement.tier.color)
                    Text("\(current) / \(achievement.target)")
                        .font(.caption2.bold())
                        .foregroundStyle(AppColor.inkSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 210)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .fill(unlocked ? AppColor.surface : AppColor.surfaceMuted)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(
                    unlocked ? achievement.tier.color.opacity(0.35) : AppColor.locked.opacity(0.18),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(unlocked ? 0.07 : 0.03), radius: 8, y: 3)
        .opacity(unlocked ? 1 : 0.9)
    }
}

#Preview {
    NavigationStack {
        AchievementsView()
    }
    .modelContainer(for: PlayerProgress.self, inMemory: true)
}
