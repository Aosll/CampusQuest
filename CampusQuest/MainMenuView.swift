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

struct MainMenuView: View {
    @Environment(ContentStore.self) private var store
    @Query private var progressList: [PlayerProgress]
    private var totalXP: Int { progressList.first?.totalXP ?? 0 }
    private var badgeCount: Int { progressList.first?.earnedBadges.count ?? 0 }
    private var hasProgress: Bool { (progressList.first?.completedLevels.isEmpty == false) }

    // Deep indigo used for readable text on the light background.
    private let ink = AppColor.ink

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackground()

                VStack(spacing: 22) {
                    Spacer(minLength: 8)
                    logo
                    campusIDCard
                    Spacer()
                    buttons
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
            }
            .preferredColorScheme(.light)
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
                        idRow(label: "STUDENT", value: "Player")
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
                        Label("\(badgeCount)/\(Badge.all.count)", systemImage: "rosette")
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
                    .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
                    .foregroundStyle(.white)
                    .shadow(color: AppColor.primary.opacity(0.35), radius: 10, y: 5)
            }

            HStack(spacing: 12) {
                NavigationLink { QuizView() } label: {
                    MenuTileLabel(title: "Quiz", icon: "questionmark.circle")
                }
                NavigationLink { DictionaryView() } label: {
                    MenuTileLabel(title: "Dictionary", icon: "book")
                }
                NavigationLink { AchievementsView() } label: {
                    MenuTileLabel(title: "Awards", icon: "rosette")
                }
            }
        }
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
