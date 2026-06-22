//
//  CampusIDDetailView.swift
//  CampusQuest
//
//  A full-screen detail for the Campus ID card. Tapping the card on the
//  home screen opens this. It reuses the existing design language
//  (GlassCard, AppColor, LinearGradient.brand) and pulls everything from
//  PlayerProgress + RankSystem + Achievement.
//

import SwiftUI
import SwiftData

struct CampusIDDetailView: View {
    @Environment(ContentStore.self) private var store
    @Environment(AuthManager.self) private var auth
    @Query private var progressList: [PlayerProgress]

    private var progress: PlayerProgress? { progressList.first }
    private var totalXP: Int { progress?.totalXP ?? 0 }
    private var streak: Int { progress?.currentStreak ?? 0 }
    private var completedCount: Int { progress?.completedLevels.count ?? 0 }
    private var earnedAchievements: [Achievement] {
        progress.map { Achievement.unlocked(for: $0) } ?? []
    }

    @State private var showAvatarPicker = false

    var body: some View {
        let rank = RankSystem.progress(forXP: totalXP)
        let major = store.department?.name ?? "Computer Engineering"

        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header(rank: rank)
                identityCard(major: major)
                rankCard(rank: rank)
                statsGrid(rank: rank)
                achievementsCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(LinearGradient.pageBackground.ignoresSafeArea())
        .navigationTitle("Campus ID")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerView(name: auth.studentName)
        }
    }

    // MARK: - Header

    private func header(rank: RankProgress) -> some View {
        VStack(spacing: 10) {
            AvatarView(size: 96, isGuest: auth.isGuest, name: auth.studentName)
                .overlay(alignment: .bottomTrailing) {
                    // Only signed-in (Apple) players can change their photo.
                    if !auth.isGuest {
                        Button {
                            showAvatarPicker = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(AppColor.primary, in: Circle())
                                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        }
                        .buttonStyle(PressableButtonStyle())
                        .offset(x: 4, y: 4)
                    }
                }
            Text(auth.studentName)
                .font(AppFont.screenTitle)
                .foregroundStyle(AppColor.ink)
            Text(rank.title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(LinearGradient.brand, in: Capsule())
        }
        .padding(.top, 8)
    }

    // MARK: - Identity

    private func identityCard(major: String) -> some View {
        GlassCard {
            VStack(spacing: 0) {
                detailRow(label: "STUDENT", value: auth.studentName, icon: "person.text.rectangle")
                Divider().padding(.leading, 52)
                detailRow(label: "MAJOR", value: major, icon: "building.columns")
                Divider().padding(.leading, 52)
                detailRow(label: "RANK", value: "\(rankLevelText)", icon: "graduationcap")
            }
            .padding(.vertical, 4)
        }
    }

    private var rankLevelText: String {
        let rank = RankSystem.progress(forXP: totalXP)
        return "Level \(rank.level) · \(rank.title)"
    }

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(AppColor.primary)
                .frame(width: 38, height: 38)
                .background(AppColor.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppColor.inkSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Rank progress

    private func rankCard(rank: RankProgress) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(rank.xp) XP")
                        .font(.headline)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Text(rank.nextTitle != nil
                         ? "\(rank.percent)% to \(rank.nextTitle!)"
                         : "Max rank reached")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.inkSecondary)
                }
                ProgressView(value: rank.fraction)
                    .tint(AppColor.primary)
                if let next = rank.nextTitle {
                    Text("\(rank.xpIntoRank) / \(rank.xpForNext) XP toward \(next)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppColor.inkSecondary)
                }
            }
            .padding(16)
        }
    }

    // MARK: - Stats

    private func statsGrid(rank: RankProgress) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            statTile(value: "\(totalXP)", label: "Total XP", icon: "star.fill", color: AppColor.secondary)
            statTile(value: "\(streak)", label: "Day Streak", icon: "flame.fill", color: AppColor.warning)
            statTile(value: "\(completedCount)", label: "Levels Done", icon: "flag.checkered", color: AppColor.success)
            statTile(value: "\(earnedAchievements.count)/\(Achievement.all.count)",
                     label: "Badges", icon: "rosette", color: AppColor.primary)
        }
    }

    private func statTile(value: String, label: String, icon: String, color: Color) -> some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(AppColor.ink)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppColor.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Achievements

    private var achievementsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Badges Earned")
                        .font(.headline)
                        .foregroundStyle(AppColor.ink)
                    Spacer()
                    Text("\(earnedAchievements.count)")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColor.secondary)
                }

                if earnedAchievements.isEmpty {
                    Text("No badges yet — complete levels and quizzes to earn your first one.")
                        .font(.caption)
                        .foregroundStyle(AppColor.inkSecondary)
                } else {
                    ForEach(earnedAchievements) { badge in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(badge.tier.color.opacity(0.16)).frame(width: 38, height: 38)
                                Image(systemName: badge.icon)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(badge.tier.color)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(badge.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppColor.ink)
                                Text(badge.tier.rawValue)
                                    .font(.caption2.bold())
                                    .foregroundStyle(badge.tier.color)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}
