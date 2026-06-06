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
@Observable
final class ContentStore {
    /// The currently loaded department (Computer Engineering for the MVP).
    var department: Department?
    /// Human-readable error to show if loading fails.
    var errorMessage: String?

    init() {
        loadComputerEngineering()
    }

    /// Loads the Computer Engineering content.
    func loadComputerEngineering() {
        do {
            department = try Self.load("ComputerEngineering")
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

    /// Reads a JSON file from the app bundle and decodes it into a Department.
    static func load(_ filename: String) throws -> Department {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ContentError.fileNotFound(filename)
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Department.self, from: data)
        } catch {
            throw ContentError.decodingFailed(error.localizedDescription)
        }
    }
}
