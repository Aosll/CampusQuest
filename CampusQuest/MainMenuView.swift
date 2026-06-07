//
//  MainMenuView.swift
//  CampusQuest
//
//  A bright, cheerful home screen: soft pastel background, logo, a
//  gamified rank card (level, XP bar, progress to next rank), and the
//  menu buttons.
//

import SwiftUI
import SwiftData
import UIKit

struct MainMenuView: View {
    @Environment(ContentStore.self) private var store
    @Environment(AuthManager.self) private var auth
    @Query private var progressList: [PlayerProgress]
    private var progress: PlayerProgress? { progressList.first }
    private var totalXP: Int { progress?.totalXP ?? 0 }
    private var unlockedAchievements: [Achievement] { progress.map { Achievement.unlocked(for: $0) } ?? [] }
    private var badgeCount: Int { unlockedAchievements.count }
    private var hasProgress: Bool { (progress?.completedLevels.isEmpty == false) }
    private var streak: Int { progress?.currentStreak ?? 0 }

    @State private var claimPulse = false
    @State private var showDailyChallengeDetail = false
    @State private var showAchievementDetail = false
    @State private var showSettings = false

    // Deep indigo used for readable text on the light background.
    private let ink = AppColor.ink

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        streakRow
                        logo
                        NavigationLink {
                            CampusIDDetailView()
                        } label: {
                            campusIDCard
                        }
                        .buttonStyle(PressableButtonStyle(scale: 0.98))
                        dailyChallengeCard
                        recentAchievementCard
                        buttons
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .preferredColorScheme(.light)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Streak

    private var streakRow: some View {
        HStack {
            if streak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("\(streak) Day Streak")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [AppColor.warning, .orange],
                                   startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
                .shadow(color: AppColor.warning.opacity(0.35), radius: 8, y: 3)
            }

            Spacer()

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(AppColor.inkSecondary)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.85), in: Circle())
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    // MARK: - Logo

    private var logo: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.36, green: 0.52, blue: 0.96),
                                     Color(red: 0.55, green: 0.40, blue: 0.92)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.white)
            }
            Text("Campus Quest")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
            Text("Find words. Build your future.")
                .font(.subheadline)
                .foregroundStyle(AppColor.inkSecondary)
        }
    }

    // MARK: - Campus ID card

    private var campusIDCard: some View {
        let rank = RankSystem.progress(forXP: totalXP)
        let major = store.department?.name ?? "Computer Engineering"

        return VStack(spacing: 0) {
            // Card header strip: title + decorative dot pattern.
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "graduationcap.fill")
                        .font(.subheadline.bold())
                    Text("CAMPUS ID CARD")
                        .font(.caption.bold())
                        .tracking(1.5)
                }
                .foregroundStyle(.white)

                Spacer()

                DotPattern(columns: 6, rows: 3)
                    .frame(height: 24)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(LinearGradient.brand)

            // Card body: identity + XP bar.
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.icon)
                            .fill(AppColor.primary.opacity(0.14))
                            .frame(width: 56, height: 56)
                        Image(systemName: "person.fill")
                            .font(.title2.bold())
                            .foregroundStyle(AppColor.primary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        idRow(label: "STUDENT", value: auth.studentName)
                        idRow(label: "MAJOR", value: major)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("LEVEL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppColor.inkSecondary)
                        Text(rank.title)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColor.ink)
                        Label("\(badgeCount)/\(Achievement.all.count)", systemImage: "rosette")
                            .font(.caption2.bold())
                            .foregroundStyle(AppColor.secondary)
                    }
                }

                VStack(spacing: 5) {
                    HStack {
                        Text("\(rank.xp) XP")
                            .font(.caption.bold())
                            .foregroundStyle(AppColor.ink)
                        Spacer()
                        Text(rank.nextTitle != nil
                             ? "\(rank.percent)% to \(rank.nextTitle!) Rank"
                             : "Max rank reached")
                            .font(.caption2.bold())
                            .foregroundStyle(AppColor.inkSecondary)
                    }
                    ProgressView(value: rank.fraction)
                        .tint(AppColor.primary)
                }
            }
            .padding(18)
            .background(Color.white.opacity(0.92))
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.largeCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.largeCard)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 7)
    }

    private func idRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(AppColor.inkSecondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Daily challenge

    private var dailyChallengeCard: some View {
        let challenge = DailyChallenge.today()
        let current = progress.map { challenge.progress(for: $0) } ?? 0
        let target = challenge.target
        let done = current >= target
        let claimed = progress?.dailyChallengeClaimedToday ?? false
        let fraction = target > 0 ? min(Double(current) / Double(target), 1) : 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: challenge.iconName)
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.inkSecondary)
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundStyle(AppColor.ink)
                }

                Spacer()

                // Reward preview.
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                    Text("+\(challenge.rewardXP)")
                }
                .font(.caption.bold())
                .foregroundStyle(AppColor.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColor.secondary.opacity(0.14), in: Capsule())
            }

            ProgressView(value: fraction)
                .tint(AppColor.primary)

            HStack {
                Text("\(min(current, target)) / \(target)")
                    .font(.caption.bold())
                    .foregroundStyle(AppColor.inkSecondary)
                Spacer()
                if claimed {
                    Label("Reward claimed", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.success)
                } else if done {
                    Button {
                        claimDailyReward(challenge)
                    } label: {
                        Text("Claim +\(challenge.rewardXP) XP")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppColor.success, in: Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .scaleEffect(claimPulse ? 1.06 : 1)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(AppColor.primary.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.card))
        .onTapGesture { showDailyChallengeDetail = true }
        .sheet(isPresented: $showDailyChallengeDetail) {
            DailyChallengeDetailView(challenge: challenge, current: current, target: target)
        }
    }

    private func claimDailyReward(_ challenge: DailyChallenge) {
        guard let progress else { return }
        let current = challenge.progress(for: progress)
        let granted = progress.claimDailyChallenge(reward: challenge.rewardXP,
                                                   progress: current,
                                                   target: challenge.target)
        if granted > 0 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { claimPulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { claimPulse = false }
            }
        }
    }

    // MARK: - Recent achievement

    @ViewBuilder
    private var recentAchievementCard: some View {
        if let badge = unlockedAchievements.last {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(badge.tier.color.opacity(0.16)).frame(width: 44, height: 44)
                    Image(systemName: badge.icon)
                        .font(.headline.bold())
                        .foregroundStyle(badge.tier.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Recent Achievement · \(badge.tier.rawValue)")
                        .font(.caption2.bold())
                        .foregroundStyle(AppColor.inkSecondary)
                    Text(badge.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppColor.ink)
                }

                Spacer()

                NavigationLink { AchievementsView() } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.inkSecondary)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card))
            .onTapGesture { showAchievementDetail = true }
            .sheet(isPresented: $showAchievementDetail) {
                AchievementDetailView(badge: badge)
            }
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 14) {
            NavigationLink {
                MajorSelectView()
            } label: {
                Label(hasProgress ? "Continue Quest" : "Start Quest",
                      systemImage: hasProgress ? "arrow.right.circle.fill" : "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.control)
                            .fill(LinearGradient.brand)
                            .overlay(
                                // Subtle top highlight for a more premium finish.
                                LinearGradient(colors: [.white.opacity(0.25), .clear],
                                               startPoint: .top, endPoint: .center)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
                            )
                    )
                    .foregroundStyle(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.control)
                            .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: AppColor.primary.opacity(0.45), radius: 16, y: 8)
                    .shadow(color: AppColor.secondary.opacity(0.25), radius: 6, y: 2)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.97))

            HStack(spacing: 12) {
                NavigationLink { QuizView() } label: {
                    MenuTileLabel(title: "Quiz", icon: "questionmark.circle")
                }
                .buttonStyle(PressableButtonStyle())
                NavigationLink { DictionaryView() } label: {
                    MenuTileLabel(title: "Dictionary", icon: "book")
                }
                .buttonStyle(PressableButtonStyle())
                NavigationLink { AchievementsView() } label: {
                    MenuTileLabel(title: "Awards", icon: "rosette")
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
    }
}

/// A minimal settings sheet. For now it shows the current account and a
/// Sign Out action that returns the user to the login screen.
struct SettingsView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    private var accountLabel: String {
        switch auth.state {
        case .signedInApple(_, let name): return "Signed in with Apple · \(name)"
        case .guest:                      return "Guest mode · this device only"
        case .signedOut:                  return "Signed out"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackground()

                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: auth.isGuest ? "person.crop.circle.dashed" : "person.crop.circle.fill")
                            .font(.title)
                            .foregroundStyle(AppColor.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Account")
                                .font(.caption.bold())
                                .foregroundStyle(AppColor.inkSecondary)
                            Text(accountLabel)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppColor.ink)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))

                    Button(role: .destructive) {
                        auth.signOut()
                        dismiss()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.9),
                                        in: RoundedRectangle(cornerRadius: AppRadius.control))
                    }
                    .buttonStyle(PressableButtonStyle())

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(.light)
        }
    }
}

/// Detail popup for the daily challenge shown on the home screen.
struct DailyChallengeDetailView: View {
    let challenge: DailyChallenge
    let current: Int
    let target: Int
    @Environment(\.dismiss) private var dismiss

    private var fraction: Double {
        target > 0 ? min(Double(current) / Double(target), 1) : 0
    }

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: challenge.iconName)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 20))
                .padding(.top, 8)

            VStack(spacing: 6) {
                Text("Daily Challenge")
                    .font(.caption.bold())
                    .foregroundStyle(AppColor.inkSecondary)
                Text(challenge.title)
                    .font(.title2.bold())
                    .foregroundStyle(AppColor.ink)
                Text(challenge.detail)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.inkSecondary)
            }

            VStack(spacing: 8) {
                ProgressView(value: fraction)
                    .tint(AppColor.primary)
                HStack {
                    Text("\(min(current, target)) / \(target)")
                        .font(.caption.bold())
                        .foregroundStyle(AppColor.inkSecondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("+\(challenge.rewardXP) XP")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(AppColor.secondary)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(24)
        .background(CampusBackground())
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.light)
    }
}

/// Detail popup for a single earned badge shown on the home screen.
struct AchievementDetailView: View {
    let badge: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle().fill(badge.tier.color.opacity(0.16)).frame(width: 96, height: 96)
                Image(systemName: badge.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(badge.tier.color)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(badge.title)
                    .font(.title2.bold())
                    .foregroundStyle(AppColor.ink)
                Text(badge.tier.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(badge.tier.color, in: Capsule())
                Text(badge.detail)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColor.inkSecondary)
                    .padding(.top, 2)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .padding(24)
        .background(CampusBackground())
        .presentationDetents([.medium])
        .preferredColorScheme(.light)
    }
}

/// A soft white secondary menu tile (icon over label).
struct MenuTileLabel: View {
    let title: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .foregroundStyle(Color.accentColor)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

/// A bright, cheerful background: soft pastel gradient, gentle color
/// glows, and faint letter blocks. Swap in a generated image later if
/// you want.
struct CampusBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.82, green: 0.91, blue: 1.00),
                         Color(red: 0.93, green: 0.89, blue: 0.99)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft, cheerful color glows.
            Circle()
                .fill(Color(red: 0.45, green: 0.62, blue: 1.0).opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 130, y: -200)
            Circle()
                .fill(Color(red: 1.0, green: 0.72, blue: 0.83).opacity(0.35))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: -130, y: 320)

            decoBlock("C", x: -120, y: -250, rotation: -12, size: 70)
            decoBlock("Q", x: 130,  y: -180, rotation: 10,  size: 60)
            decoBlock("A", x: -140, y: 280,  rotation: 8,   size: 56)
            decoBlock("Z", x: 120,  y: 330,  rotation: -8,  size: 64)
        }
        .ignoresSafeArea()
    }

    private func decoBlock(_ letter: String,
                           x: CGFloat, y: CGFloat,
                           rotation: Double, size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.22)
            .fill(.white.opacity(0.45))
            .overlay(
                Text(letter)
                    .font(.system(size: size * 0.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(red: 0.30, green: 0.34, blue: 0.60).opacity(0.25))
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
    }
}

#Preview {
    MainMenuView()
        .environment(ContentStore())
        .modelContainer(for: PlayerProgress.self, inMemory: true)
}
