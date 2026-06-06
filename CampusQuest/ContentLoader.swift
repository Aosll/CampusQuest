//
//  ContentLoader.swift
//  CampusQuest
//
//  Loads the game's static content from bundled JSON and prepares
//  the quiz questions for the loaded department.
//

import Foundation

/// Errors that can happen while loading game content.
enum ContentError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Could not find \(name).json in the app bundle."
        case .decodingFailed(let message):
            return "Could not read the content: \(message)"
        }
    }
}

/// Holds the loaded game content and generated quiz questions.
/// `@Observable` means SwiftUI automatically refreshes when this changes.
/// Isolated to the main actor so its observable state is always read/written
/// on the main thread; the heavy JSON work runs off-main (see `load`).
@MainActor
@Observable
final class ContentStore {
    /// The currently loaded department (Computer Engineering for the MVP).
    var department: Department?
    /// Human-readable error to show if loading fails.
    var errorMessage: String?
    /// True while a department's JSON is being read/decoded.
    var isLoading = false

    init() {
        // MVP: load Computer Engineering at startup. Adding another major is
        // just a matter of shipping a new "<Name>.json" and loading it here
        // (or when the major is selected).
        Task { await loadDepartment(named: "ComputerEngineering") }
    }

    /// Loads a single department's content from "<name>.json" on demand.
    /// Reading/decoding happens off the main thread; the result is published
    /// on the main actor. `name` is the JSON file's base name.
    func loadDepartment(named name: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            department = try await Self.load(name)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            print("Content load error: \(error.localizedDescription)")
        }
    }

    /// Builds quiz questions for a single level on demand, using the whole
    /// department's categories as possible answer choices.
    func questions(for level: GameLevel) -> [QuizQuestion] {
        let categories = department?.allCategories ?? []
        return level.words.map { QuizBuilder.makeQuestion(for: $0, allCategories: categories) }
    }

    /// Reads and decodes a department JSON off the main thread. `Department`
    /// is a value type (Sendable), so the result can safely cross back to the
    /// main actor.
    nonisolated static func load(_ filename: String) async throws -> Department {
        try await Task.detached(priority: .userInitiated) {
            guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
                throw ContentError.fileNotFound(filename)
            }
            do {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(Department.self, from: data)
            } catch let error as ContentError {
                throw error
            } catch {
                throw ContentError.decodingFailed(error.localizedDescription)
            }
        }.value
    }
}
