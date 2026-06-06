---
trigger: always_on
---

# Campus Quest: Word Majors — Project Context & Rules

This file is the persistent context for the AI agent working on this project.
Always follow these rules unless the developer explicitly overrides them in chat.

---

## 1. What We Are Building

Campus Quest is an educational, casual 2D word game for iOS about university
majors. The player picks a major, enters its 2D world, finds words by connecting
letters (Wordscapes-style letter wheel), learns a short definition for each
found word, answers a small "which subject does this belong to?" quiz, and
gradually upgrades the major's visual scene.

This is a hobby project. Keep everything simple, readable, and beginner-friendly.

### MVP scope (build ONLY this first)
- ONE major: **Computer Engineering**.
- **5 levels** for that major (one level = one course).
- Each level has 8–12 words.
- Letter-wheel word-finding screen.
- Short free definition card when a word is found.
- A simple "match the meaning" mini quiz.
- Simple 2D progress feedback when words/quizzes are completed.
- Level-end results screen (words found, XP, badges).
- Save user progress locally.

Other majors (Architecture, Medicine, etc.), Turkish language support, and
monetization come LATER. Do not build them now.

---

## 2. Tech Stack (do not change without asking)

- Language: **Swift 6**
- UI / menus / navigation: **SwiftUI**
- Word-finding game scene + 2D animations: **SpriteKit**
- Local persistence: **SwiftData**
- Minimum deployment target: **iOS 17.0**
- Build, run, simulator, signing: **Xcode** (the agent edits code; Xcode builds it)
- Package manager: Swift Package Manager (only if a dependency is truly needed)

Do NOT add third-party libraries/dependencies unless explicitly approved by the
developer. Prefer Apple's native frameworks.

---

## 3. Architecture & File Organization

- Use a clear, feature-based folder structure, for example:
  - `Models/` — data models (Word, Level, Department, Progress)
  - `Data/` — JSON content files + loaders
  - `Views/` — SwiftUI screens (MainMenu, MajorSelect, LevelSelect, etc.)
  - `Game/` — SpriteKit scenes and game logic (letter wheel, word matching)
  - `Services/` — progress saving, scoring, content loading
  - `Resources/` — JSON, assets references
- Follow a simple MVVM-style separation: SwiftUI Views stay thin; logic lives in
  `@Observable` model/view-model types.
- Game content (departments, levels, words, definitions, quiz options) is stored
  as **JSON** and decoded into Swift models, so new content can be added easily.

### Content data shape (target schema)
```json
{
  "department": "Computer Engineering",
  "levels": [
    {
      "title": "Data Structures",
      "words": [
        {
          "word": "stack",
          "definition": "A data structure that follows the Last In, First Out principle.",
          "category": "Data Structures",
          "objectToUnlock": "stack_visual"
        }
      ]
    }
  ]
}
```

---

## 4. Coding Standards — DO

- Write modern Swift 6: use `async/await`, NOT Combine.
- Use the `@Observable` macro for state, NOT the old `ObservableObject`.
- Use `guard let` for early returns; avoid deep nesting.
- Keep files small and focused (one main type per file when reasonable).
- Use clear, descriptive names (`LetterWheelView`, not `LWV`).
- Add short comments explaining WHY for any non-obvious logic.
- Handle errors gracefully; never crash on missing/invalid data.
- Make the smallest change that satisfies the request.
- Keep UI in English for now (app content language is English).

---

## 5. Coding Standards — DON'T

- Do NOT force-unwrap optionals (`!`) except where it is provably safe.
- Do NOT add networking, online multiplayer, accounts, or social features.
- Do NOT add ads, in-app purchases, or any monetization yet.
- Do NOT build extra majors beyond Computer Engineering yet.
- Do NOT add Turkish localization yet (plan for it, don't implement it).
- Do NOT modify the `CampusQuestTests` or `CampusQuestUITests` targets.
- Do NOT over-engineer: no complex patterns, no premature abstractions.
- Do NOT add dependencies without asking.
- Do NOT delete or rewrite large chunks of working code to "clean up" unless asked.
- Do NOT run destructive terminal/git commands (force push, reset --hard, rm -rf)
  without explicit approval.

---

## 6. How To Work With This Developer (IMPORTANT)

The developer is a **complete beginner with no prior coding experience** and is
building this in a "vibe coding" style. Adjust your behavior accordingly:

- **Explain in Turkish**, in simple, non-technical language. Code, code comments,
  identifiers, and file names stay in English; explanations to the developer are
  in Turkish.
- Work in **small steps**. Do one feature/screen at a time. Do not dump huge
  amounts of code at once.
- **Before making significant changes, show a short plan first** and wait for
  approval. Explain what each file does and why.
- After changes, tell the developer exactly **what to do in Xcode** to see the
  result (which file changed, press Run, select an iPhone simulator).
- When a build error appears, ask the developer to paste the full error text,
  then fix it and explain the cause simply.
- Never assume the developer knows Xcode/Swift conventions — spell out menu
  clicks and steps.
- Prefer clarity over cleverness. If two solutions exist, choose the one that is
  easier for a beginner to read and maintain.

---

## 7. Computer Engineering MVP Content (reference)

The 5 MVP levels and their words for Computer Engineering:

1. **Programming Fundamentals**: variable, function, loop, array, condition,
   input, output, string, integer, boolean
2. **Data Structures**: stack, queue, tree, graph, linkedlist, node, heap, hash,
   array, map
3. **Computer Networks**: router, packet, protocol, firewall, server, client,
   socket, domain, switch, latency
4. **Databases**: table, query, schema, index, relation, primarykey, foreignkey,
   transaction, database, record
5. **Cybersecurity**: encryption, malware, phishing, firewall, vulnerability,
   exploit, password, authentication, threat, attack

Each word needs: a short plain-English definition, a category (for the quiz),
and an object-to-unlock id (for the 2D scene). Definitions should be one short,
clear sentence understandable by a high-school student.

---

## 8. Visual Style

- 2D flat design, clean and minimal, soft pastel palette.
- Computer Engineering color identity: blue, dark gray, neon-green accents.
- Simple, satisfying animations (word found = object glows/unlocks; level
  complete = scene upgrades; wrong answer = gentle shake).
- Use SF Symbols for UI icons until custom art is provided.

---

## 9. Definition of Done (per feature)

A feature is done when:
- It builds with no errors and runs in the iPhone simulator.
- It follows the standards above.
- The developer has been told, in Turkish, what changed and how to test it.