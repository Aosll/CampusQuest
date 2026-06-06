//
//  Models.swift
//  CampusQuest
//
//  Data models for the game's static content.
//  These are decoded from the bundled JSON files.
//

import Foundation

/// A single word the player can find, with its meaning and quiz info.
struct WordItem: Codable, Identifiable, Hashable {
    let word: String          // e.g. "stack"
    let definition: String    // short plain-English meaning
    let category: String      // used by the mini quiz ("which subject?")
    let objectToUnlock: String // id of the 2D scene object to reveal

    // Words are unique within a level, so the word itself works as an id.
    var id: String { word }

    /// A nicely capitalized version for display, e.g. "Stack".
    var displayName: String { word.capitalized }
}

/// One level = one course (e.g. "Data Structures"), made of several words.
struct GameLevel: Codable, Identifiable, Hashable {
    let title: String
    let words: [WordItem]

    var id: String { title }
}

/// A university major (e.g. "Computer Engineering") containing its levels.
struct Department: Codable, Identifiable, Hashable {
    let department: String     // matches the JSON key
    let levels: [GameLevel]

    var id: String { department }

    /// Friendlier alias so views can read `department.name`.
    var name: String { department }
}
