//
//  AppearancePickerView.swift
//  CampusQuest
//
//  Lets the player force Light or Dark mode, or follow the system setting.
//  Matches the Language picker look: soft background, rounded cards, an icon
//  per option, and a checkmark on the selected appearance.
//

import SwiftUI

struct AppearancePickerView: View {
    @AppStorage(AppAppearance.storageKey) private var appearanceRaw = AppAppearance.system.rawValue

    private var selection: AppAppearance {
        AppAppearance(rawValue: appearanceRaw) ?? .system
    }

    var body: some View {
        ZStack {
            CampusBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(AppAppearance.allCases) { option in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                appearanceRaw = option.rawValue
                            }
                        } label: {
                            row(for: option)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for option: AppAppearance) -> some View {
        let isSelected = option == selection

        return HStack(spacing: 14) {
            Image(systemName: option.icon)
                .font(.title3)
                .foregroundStyle(AppColor.primary)
                .frame(width: 44, height: 44)
                .background(AppColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))

            Text(option.displayName)
                .font(.headline)
                .foregroundStyle(AppColor.ink)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? AppColor.primary : AppColor.inkSecondary.opacity(0.4))
                .symbolEffect(.bounce, value: isSelected)
        }
        .padding(16)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .strokeBorder(isSelected ? AppColor.primary.opacity(0.55) : Color.primary.opacity(0.12),
                              lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: .black.opacity(isSelected ? 0.10 : 0.05), radius: isSelected ? 12 : 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        AppearancePickerView()
    }
}
