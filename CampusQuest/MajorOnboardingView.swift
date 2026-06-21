//
//  MajorOnboardingView.swift
//  CampusQuest
//
//  Shown once, on first launch, before the player reaches the home screen.
//  It forces the player to pick a major up front so the rest of the app
//  always has a clear active major (no silent default). The choice is saved,
//  so later launches skip straight to the home screen.
//

import SwiftUI

struct MajorOnboardingView: View {
    @Environment(ContentStore.self) private var store

    var body: some View {
        ZStack {
            CampusBackground()

            if store.departments.isEmpty {
                // Content is still loading from the bundle.
                ProgressView()
                    .controlSize(.large)
                    .tint(AppColor.primary)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        header

                        VStack(spacing: 16) {
                            ForEach(store.departments) { department in
                                let style = MajorStyle.style(for: department.name)
                                Button {
                                    store.select(department)
                                } label: {
                                    MajorCard(
                                        title: department.name,
                                        subtitle: "\(department.levels.count) levels",
                                        systemImage: style.symbol,
                                        accent: style.accent,
                                        pattern: style.pattern,
                                        isLocked: false
                                    )
                                }
                                .buttonStyle(PressableButtonStyle())
                            }
                        }
                    }
                    .padding(24)
                    .padding(.top, 24)
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient.brand)
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
            }
            Text("Choose Your Major")
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(AppColor.ink)
            Text("Pick a faculty to begin. You can switch any time later.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppColor.inkSecondary)
        }
    }
}

#Preview {
    MajorOnboardingView()
        .environment(ContentStore())
}
