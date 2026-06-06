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
    @Query private var progressList: [PlayerProgress]
    private var totalXP: Int { progressList.first?.totalXP ?? 0 }
    private var badgeCount: Int { progressList.first?.earnedBadges.count ?? 0 }

    // Deep indigo used for readable text on the light background.
    private let ink = Color(red: 0.18, green: 0.20, blue: 0.42)

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackground()

                VStack(spacing: 22) {
                    Spacer(minLength: 8)
                    logo
                    rankCard
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
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(ink)
            Text("Find the words. Build your major.")
                .font(.footnote)
                .foregroundStyle(ink.opacity(0.6))
        }
    }

    // MARK: - Rank card

    private var rankCard: some View {
        let rank = RankSystem.progress(forXP: totalXP)
        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.accentColor)
                    Text("\(rank.level)")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Level \(rank.level) · \(rank.title)")
                        .font(.headline)
                        .foregroundStyle(ink)
                    Text("\(rank.xp) XP")
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.6))
                }

                Spacer()

                Label("\(badgeCount)", systemImage: "rosette")
                    .font(.subheadline.bold())
                    .foregroundStyle(ink)
            }

            VStack(spacing: 4) {
                ProgressView(value: rank.fraction)
                    .tint(Color.accentColor)
                Text(rank.nextTitle != nil
                     ? "\(rank.percent)% to \(rank.nextTitle!)"
                     : "Max rank reached")
                    .font(.caption2)
                    .foregroundStyle(ink.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 14) {
            NavigationLink {
                MajorSelectView()
            } label: {
                Text("Play")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                    .shadow(color: Color.accentColor.opacity(0.35), radius: 10, y: 5)
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
