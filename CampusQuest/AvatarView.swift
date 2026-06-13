//
//  AvatarView.swift
//  CampusQuest
//
//  Created by Ömer Efe DİKİCİ.
//
//  The player's avatar, rendered consistently everywhere it appears (96pt
//  on the Campus ID detail, 56pt on the home card). It reads the avatar
//  choice straight from AppStorage so it updates instantly when changed.
//
//  Rendering priority:
//    • Guest          → brand gradient + "G" monogram (always; ignores any
//                        stored photo/preset, per the guest privacy rule).
//    • Library photo   → the picked image, circular-cropped.
//    • Built-in avatar → an app-themed SF Symbol on a brand gradient.
//    • Otherwise       → brand gradient + the name's initial.
//

import SwiftUI

struct AvatarView: View {
    var size: CGFloat = 80
    var isGuest: Bool
    var name: String

    @AppStorage(ProfilePhotoKeys.photoData) private var photoData: Data?
    @AppStorage(ProfilePhotoKeys.avatarID) private var avatarID: String?

    private var monogram: String {
        if isGuest { return "G" }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return String(trimmed.first ?? "S").uppercased()
    }

    var body: some View {
        Group {
            if isGuest {
                monogramAvatar(LinearGradient.brand)
            } else if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let preset = PresetAvatar.preset(id: avatarID) {
                symbolAvatar(preset.symbol, gradient: preset.gradient)
            } else {
                monogramAvatar(LinearGradient.brand)
            }
        }
        .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: size > 70 ? 3 : 2))
        .shadow(color: AppColor.primary.opacity(0.25), radius: size > 70 ? 10 : 5, y: 4)
    }

    private func monogramAvatar(_ gradient: LinearGradient) -> some View {
        ZStack {
            Circle().fill(gradient).frame(width: size, height: size)
            Text(monogram)
                .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func symbolAvatar(_ symbol: String, gradient: LinearGradient) -> some View {
        ZStack {
            Circle().fill(gradient).frame(width: size, height: size)
            Image(systemName: symbol)
                .font(.system(size: size * 0.46, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        AvatarView(size: 96, isGuest: false, name: "Ömer Efe")
        AvatarView(size: 56, isGuest: true, name: "Guest")
    }
    .padding()
}
