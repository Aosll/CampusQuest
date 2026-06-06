//
//  MajorSelectView.swift
//  CampusQuest
//
//  Lets the player choose a major. For the MVP, only Computer
//  Engineering is playable; other majors are shown as locked.
//

import SwiftUI

struct MajorSelectView: View {
    @Environment(ContentStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // The one playable major (loaded from JSON).
                if let department = store.department {
                    NavigationLink {
                        LevelSelectView(department: department)
                    } label: {
                        MajorCard(
                            title: department.name,
                            subtitle: "\(department.levels.count) levels",
                            systemImage: "desktopcomputer",
                            isLocked: false
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Placeholders for future majors.
                MajorCard(title: "Architecture", subtitle: "Coming soon",
                          systemImage: "building.columns", isLocked: true)
                MajorCard(title: "Medicine", subtitle: "Coming soon",
                          systemImage: "cross.case", isLocked: true)
            }
            .padding()
        }
        .navigationTitle("Choose a Major")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// A reusable card showing one major.
struct MajorCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title)
                .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isLocked ? "lock.fill" : "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 16))
        .opacity(isLocked ? 0.5 : 1)
    }
}

#Preview {
    NavigationStack {
        MajorSelectView()
            .environment(ContentStore())
    }
}
