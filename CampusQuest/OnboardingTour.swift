//
//  OnboardingTour.swift
//  CampusQuest
//
//  A first-launch coachmark tour. It dims the real home screen, cuts a
//  spotlight around one real control at a time, and shows a tooltip that
//  explains what it does ("tap here to start", "change the theme here").
//  Shown once, then remembered via @AppStorage so it never repeats.
//

import SwiftUI

/// The real controls on the home screen the tour can point at. Steps with
/// no target (intro / outro) show a centered card instead of a spotlight.
enum TourStep: String {
    case settings
    case startQuest
    case dailyChallenge
    case features
}

/// One stop in the tour: an optional spotlight target plus its copy.
struct TourStop: Identifiable {
    let id = UUID()
    let target: TourStep?
    let icon: String
    let titleKey: LocalizedStringKey
    let messageKey: LocalizedStringKey

    /// The ordered script the tour plays through.
    static let stops: [TourStop] = [
        TourStop(target: nil,
                 icon: "graduationcap.fill",
                 titleKey: "Welcome to CampusQuest!",
                 messageKey: "Here's a quick tour of the basics. You can skip it anytime."),
        TourStop(target: .settings,
                 icon: "gearshape.fill",
                 titleKey: "Settings & Theme",
                 messageKey: "Tap the gear to change the language or switch between Light and Dark mode."),
        TourStop(target: .startQuest,
                 icon: "play.fill",
                 titleKey: "Start Playing",
                 messageKey: "This is your main quest. Tap here to begin solving word levels."),
        TourStop(target: .dailyChallenge,
                 icon: "calendar.badge.clock",
                 titleKey: "Daily Challenge",
                 messageKey: "A fresh set of words every day for bonus XP. Keep your streak alive!"),
        TourStop(target: .features,
                 icon: "square.grid.2x2.fill",
                 titleKey: "Quiz, Dictionary & Awards",
                 messageKey: "Test yourself, review the words you've learned, and collect achievement badges here."),
        TourStop(target: nil,
                 icon: "sparkles",
                 titleKey: "You're all set!",
                 messageKey: "Have fun and build your future, one word at a time.")
    ]
}

// MARK: - Anchor plumbing

/// Collects the on-screen frame of each tagged control so the overlay can
/// position its spotlight over the real button.
struct TourAnchorKey: PreferenceKey {
    static let defaultValue: [TourStep: Anchor<CGRect>] = [:]
    static func reduce(value: inout [TourStep: Anchor<CGRect>],
                       nextValue: () -> [TourStep: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    /// Marks this control as a tour target so the spotlight can find it.
    func tourTarget(_ step: TourStep) -> some View {
        anchorPreference(key: TourAnchorKey.self, value: .bounds) { [step: $0] }
    }

    /// Masks out (cuts a hole in) the given shape from this view.
    fileprivate func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask().blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

// MARK: - Overlay

/// The dim-and-spotlight overlay. Driven by `index` into `TourStop.stops`;
/// calls `onFinish` when the player skips or reaches the end.
struct OnboardingTourOverlay: View {
    @Binding var index: Int
    let anchors: [TourStep: Anchor<CGRect>]
    let proxy: GeometryProxy
    let onFinish: () -> Void

    private var stop: TourStop { TourStop.stops[index] }
    private var isLast: Bool { index == TourStop.stops.count - 1 }

    /// The on-screen frame of the current target, if any.
    private var targetRect: CGRect? {
        guard let target = stop.target, let anchor = anchors[target] else { return nil }
        return proxy[anchor]
    }

    var body: some View {
        ZStack {
            dimmedBackground
            if let rect = targetRect {
                spotlightRing(around: rect)
            }
            tooltip
        }
        .transition(.opacity)
    }

    // Full-screen scrim with an optional hole cut around the target.
    private var dimmedBackground: some View {
        Rectangle()
            .fill(Color.black.opacity(0.72))
            .reverseMask {
                if let rect = targetRect {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .frame(width: rect.width + 18, height: rect.height + 18)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
            // Block taps to the real UI while the tour is up.
            .contentShape(Rectangle())
    }

    private func spotlightRing(around rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(LinearGradient.brand, lineWidth: 3)
            .frame(width: rect.width + 18, height: rect.height + 18)
            .position(x: rect.midX, y: rect.midY)
            .shadow(color: AppColor.primary.opacity(0.6), radius: 12)
            .allowsHitTesting(false)
    }

    private var tooltip: some View {
        VStack(spacing: 14) {
            Image(systemName: stop.icon)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: 16))

            Text(stop.titleKey)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.ink)

            Text(stop.messageKey)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.inkSecondary)

            // Progress dots.
            HStack(spacing: 6) {
                ForEach(0..<TourStop.stops.count, id: \.self) { i in
                    Circle()
                        .fill(i == index ? AppColor.primary : AppColor.inkSecondary.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .padding(.top, 2)

            HStack(spacing: 12) {
                if !isLast {
                    Button {
                        onFinish()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColor.inkSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppColor.surfaceMuted, in: RoundedRectangle(cornerRadius: AppRadius.control))
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                Button {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            index += 1
                        }
                    }
                } label: {
                    Text(isLast ? "Got it" : "Next")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(22)
        .frame(maxWidth: 340)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.largeCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.largeCard)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .padding(.horizontal, 24)
        .position(x: proxy.size.width / 2, y: tooltipCenterY)
    }

    /// Keep the tooltip clear of the highlighted control: below it when the
    /// target sits in the top half, above it otherwise. Centered when there's
    /// no target (intro / outro).
    private var tooltipCenterY: CGFloat {
        let height = proxy.size.height
        guard let rect = targetRect else { return height / 2 }
        if rect.midY < height / 2 {
            return min(rect.maxY + 170, height - 170)
        } else {
            return max(rect.minY - 170, 200)
        }
    }
}
