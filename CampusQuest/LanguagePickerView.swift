//
//  LanguagePickerView.swift
//  CampusQuest
//
//  A modern, Apple-style language picker that matches the CampusQuest look:
//  soft blue/lavender background, rounded white cards, flag icons, a checkmark
//  on the selected language, and a smooth selection animation.
//

import SwiftUI

struct LanguagePickerView: View {
    @Environment(LanguageManager.self) private var language

    var body: some View {
        ZStack {
            CampusBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                language.select(lang)
                            }
                        } label: {
                            row(for: lang)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(for lang: AppLanguage) -> some View {
        let isSelected = lang == language.selection

        return HStack(spacing: 14) {
            Text(lang.flag)
                .font(.system(size: 30))
                .frame(width: 44, height: 44)
                .background(AppColor.primary.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))

            Text(lang.displayName)
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
        LanguagePickerView()
    }
    .environment(LanguageManager())
}
