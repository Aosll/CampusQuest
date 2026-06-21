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
    /// The base names of the playable majors, in display order. Each one ships
    /// a "<name>.json" in the bundle. Add a major by adding its file here.
    static let majorFileNames = ["ComputerEngineering", "Medicine"]

    /// UserDefaults key remembering the player's last chosen major (by name).
    private static let selectedMajorKey = "selectedMajorName"

    /// Every major that loaded successfully, in `majorFileNames` order.
    var departments: [Department] = []
    /// The currently active major — drives the Campus ID, quizzes, daily
    /// challenge and dictionary. Stays `nil` until the player picks a major,
    /// so the app can force a first-run choice instead of guessing one.
    var department: Department?
    /// Human-readable error to show if loading fails.
    var errorMessage: String?
    /// True while a department's JSON is being read/decoded.
    var isLoading = false

    /// The player's saved major name, or nil if they haven't chosen one yet.
    private var savedMajorName: String? {
        UserDefaults.standard.string(forKey: Self.selectedMajorKey)
    }

    init() {
        // Load every playable major at startup, then restore the player's last
        // choice (or none on first run — RootView forces a choice in that case).
        Task { await loadAllMajors() }
    }

    /// Makes `department` the active major and remembers it across launches.
    /// Must already be one of the loaded `departments`. Switching it refreshes
    /// everything keyed off the active major (Campus ID, quiz categories, etc.).
    func select(_ department: Department) {
        self.department = department
        UserDefaults.standard.set(department.name, forKey: Self.selectedMajorKey)
    }

    /// Loads every major in `majorFileNames`, keeping the ones that decode,
    /// then restores the saved active major (or leaves it nil on first run).
    func loadAllMajors() async {
        isLoading = true
        defer { isLoading = false }
        var loaded: [Department] = []
        for name in Self.majorFileNames {
            do {
                loaded.append(try await Self.load(name))
            } catch {
                errorMessage = error.localizedDescription
                print("Content load error (\(name)): \(error.localizedDescription)")
            }
        }
        departments = loaded
        // Restore the player's saved major if it still exists. Otherwise leave
        // `department` nil: first run shows the major-choice screen, and a
        // removed major also falls back to choosing again.
        if let savedName = savedMajorName,
           let saved = loaded.first(where: { $0.name == savedName }) {
            department = saved
        } else if let current = department,
                  loaded.contains(where: { $0.id == current.id }) {
            department = loaded.first(where: { $0.id == current.id })
        } else {
            department = nil
        }
        if !loaded.isEmpty { errorMessage = nil }
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
