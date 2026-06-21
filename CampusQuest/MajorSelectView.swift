//
//  MajorSelectView.swift
//  CampusQuest
//
//  Lets the player choose a major. For the MVP, only Computer
//  Engineering is playable; other majors are shown as locked with a
//  themed "coming soon" message and a faint subject pattern.
//

import SwiftUI
import UIKit

struct MajorSelectView: View {
    @Environment(ContentStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Every playable major loaded from JSON. Tapping one makes it
                // the active major and opens its levels.
                ForEach(store.departments) { department in
                    let style = MajorStyle.style(for: department.name)
                    NavigationLink {
                        LevelSelectView(department: department)
                    } label: {
                        MajorCard(
                            title: department.name,
                            subtitle: "\(department.levels.count) levels · Open now",
                            systemImage: style.symbol,
                            accent: style.accent,
                            pattern: style.pattern,
                            isLocked: false
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded {
                        store.select(department)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    })
                }

                // Placeholder for a future major.
                MajorCard(title: "Architecture",
                          subtitle: "New faculty opening soon",
                          systemImage: "building.columns",
                          accent: AppColor.secondary,
                          pattern: .blueprint,
                          isLocked: true)
            }
            .padding()
        }
        .background(LinearGradient.pageBackground.ignoresSafeArea())
        .navigationTitle("Choose a Major")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }
}

/// Faint decorative pattern themed to each major.
enum MajorPattern {
    case code, blueprint, health
}

/// Visual styling (icon, accent, pattern) for a playable major, chosen by name
/// with a sensible fallback so a newly added major still looks intentional.
struct MajorStyle {
    let symbol: String
    let accent: Color
    let pattern: MajorPattern

    static func style(for name: String) -> MajorStyle {
        switch name {
        case "Medicine":
            return MajorStyle(symbol: "cross.case", accent: AppColor.success, pattern: .health)
        case "Computer Engineering":
            return MajorStyle(symbol: "desktopcomputer", accent: AppColor.primary, pattern: .code)
        default:
            return MajorStyle(symbol: "graduationcap", accent: AppColor.primary, pattern: .code)
        }
    }
}

/// A reusable card showing one major.
struct MajorCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var accent: Color = AppColor.primary
    var pattern: MajorPattern = .code
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.icon)
                    .fill(accent.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: systemImage)
                    .font(.title2.bold())
                    .foregroundStyle(isLocked ? AppColor.locked : accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFont.cardTitle)
                    .foregroundStyle(AppColor.ink)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isLocked ? AppColor.warning : AppColor.inkSecondary)
            }

            Spacer()

            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .font(.headline)
                .foregroundStyle(isLocked ? AppColor.locked : accent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .fill(Color.white.opacity(isLocked ? 0.6 : 0.92))
                patternOverlay
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(accent.opacity(isLocked ? 0.12 : 0.22), lineWidth: 1)
        )
        .shadow(color: .black.opacity(isLocked ? 0.03 : 0.07), radius: 8, y: 3)
        .opacity(isLocked ? 0.78 : 1)
    }

    @ViewBuilder
    private var patternOverlay: some View {
        let symbol: String = {
            switch pattern {
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .blueprint: return "ruler"
            case .health: return "waveform.path.ecg"
            }
        }()

        Image(systemName: symbol)
            .font(.system(size: 120))
            .foregroundStyle(accent.opacity(0.06))
            .rotationEffect(.degrees(-12))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .offset(x: 30)
    }
}

#Preview {
    NavigationStack {
        MajorSelectView()
            .environment(ContentStore())
    }
}
