//
//  LetterWheelView.swift
//  CampusQuest
//
//  A circular wheel of letters. The player drags across letters to
//  connect them; a line follows the finger. On release, the spelled
//  word is reported back.
//

import SwiftUI

struct LetterWheelView: View {
    let tiles: [LetterTile]
    /// Called continuously with the in-progress guess as the finger moves.
    var onPreview: (String) -> Void = { _ in }
    /// Called when the finger lifts, with the final guessed word.
    var onSubmit: (String) -> Void

    @State private var selectedIDs: [UUID] = []
    @State private var dragPoint: CGPoint?

    /// Smaller tiles when there are many letters, so they don't overlap.
    private var tileSize: CGFloat { tiles.count > 9 ? 40 : 50 }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = max(40, min(geo.size.width, geo.size.height) / 2 - tileSize / 2 - 6)
            let positions = positions(center: center, radius: radius)

            ZStack {
                // Line connecting the selected letters, then to the finger.
                // A gradient route reads more clearly than a flat stroke.
                Path { path in
                    let points = selectedIDs.compactMap { positions[$0] }
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() { path.addLine(to: point) }
                    if let dragPoint { path.addLine(to: dragPoint) }
                }
                .stroke(LinearGradient.brand,
                        style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))

                // The letter tiles.
                ForEach(tiles) { tile in
                    let selected = selectedIDs.contains(tile.id)
                    Text(tile.letter.uppercased())
                        .font(.title2.bold())
                        .foregroundStyle(selected ? .white : .primary)
                        .frame(width: tileSize, height: tileSize)
                        .background(
                            Circle().fill(selected
                                          ? Color.accentColor
                                          : Color(.secondarySystemBackground))
                        )
                        // Selected tiles pop and glow for clearer feedback.
                        .scaleEffect(selected ? 1.18 : 1)
                        .shadow(color: selected ? Color.accentColor.opacity(0.5) : .clear,
                                radius: selected ? 8 : 0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.55), value: selected)
                        .position(positions[tile.id] ?? center)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragPoint = value.location
                        if let id = tile(at: value.location, in: positions),
                           !selectedIDs.contains(id) {
                            selectedIDs.append(id)
                            onPreview(currentGuess)
                        }
                    }
                    .onEnded { _ in
                        onSubmit(currentGuess)
                        selectedIDs = []
                        dragPoint = nil
                        onPreview("")
                    }
            )
        }
    }

    /// The word spelled by the currently selected tiles.
    private var currentGuess: String {
        selectedIDs
            .compactMap { id in tiles.first { $0.id == id }?.letter }
            .joined()
    }

    /// Places each tile evenly around a circle.
    private func positions(center: CGPoint, radius: CGFloat) -> [UUID: CGPoint] {
        var result: [UUID: CGPoint] = [:]
        let count = max(tiles.count, 1)
        for (index, tile) in tiles.enumerated() {
            let angle = Double(index) / Double(count) * 2 * .pi - .pi / 2
            result[tile.id] = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
        }
        return result
    }

    /// Returns the tile whose center is near the given point, if any.
    private func tile(at point: CGPoint, in positions: [UUID: CGPoint]) -> UUID? {
        for (id, pos) in positions where hypot(pos.x - point.x, pos.y - point.y) < tileSize / 2 + 6 {
            return id
        }
        return nil
    }
}
