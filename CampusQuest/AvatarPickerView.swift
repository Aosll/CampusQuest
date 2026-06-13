//
//  AvatarPickerView.swift
//  CampusQuest
//
//  Created by Ömer Efe DİKİCİ.
//
//  The sheet that lets a signed-in player change their avatar: pick a photo
//  from the library, choose one of the app-themed generated avatars, or
//  remove the current one to fall back to a monogram.
//

import SwiftUI

struct AvatarPickerView: View {
    var name: String

    @Environment(\.dismiss) private var dismiss
    @State private var manager = ProfilePhotoManager()
    @State private var showPhotoPicker = false

    @AppStorage(ProfilePhotoKeys.photoData) private var photoData: Data?
    @AppStorage(ProfilePhotoKeys.avatarID) private var avatarID: String?

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 16)]

    private var hasSelection: Bool { photoData != nil || avatarID != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                CampusBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        AvatarView(size: 110, isGuest: false, name: name)
                            .padding(.top, 8)

                        photoButton

                        VStack(alignment: .leading, spacing: 12) {
                            Text("CampusQuest Avatars")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppColor.inkSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(PresetAvatar.all) { preset in
                                    presetCell(preset)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: AppRadius.card))

                        if hasSelection {
                            Button(role: .destructive) {
                                withAnimation { manager.reset() }
                            } label: {
                                Label("Remove Avatar", systemImage: "trash")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.9),
                                                in: RoundedRectangle(cornerRadius: AppRadius.control))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPicker { image in
                    withAnimation { manager.save(image: image) }
                }
                .ignoresSafeArea()
            }
            .preferredColorScheme(.light)
        }
    }

    private var photoButton: some View {
        Button {
            showPhotoPicker = true
        } label: {
            Label("Choose from Library", systemImage: "photo.on.rectangle")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient.brand, in: RoundedRectangle(cornerRadius: AppRadius.control))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func presetCell(_ preset: PresetAvatar) -> some View {
        let isSelected = avatarID == preset.id && photoData == nil
        return Button {
            withAnimation { manager.select(preset) }
        } label: {
            ZStack {
                Circle().fill(preset.gradient).frame(width: 64, height: 64)
                Image(systemName: preset.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle().strokeBorder(isSelected ? AppColor.primary : .clear, lineWidth: 3)
            )
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(AppColor.primary)
                        .background(Circle().fill(.white))
                        .symbolEffect(.bounce, value: isSelected)
                }
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    AvatarPickerView(name: "Ömer Efe")
}
