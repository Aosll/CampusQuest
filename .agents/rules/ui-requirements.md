---
trigger: always_on
---

# Campus Quest — UI / UX Requirements

These are required UI/UX standards for the gameplay screens. Apply them
whenever building or revising the level screen, the definition card, or
the 2D department scene.

## Letter-finding screen (LevelView)

1. **Answer slots must be clearly visible.** The letter slots that show the
   word length / current guess should NOT be faint gray. Give them a clearly
   readable background, a subtle border, and good contrast so the player
   notices them at first glance.

2. **Clear visual hierarchy at the bottom.** Keep the letter wheel compact and
   positioned in the lower area, with clear separation from the Shuffle
   button. The wheel, the slots, and the Shuffle control should read as three
   distinct zones, not a cramped cluster.

3. **The definition card must feel like a distinct "hint/reward" surface.**
   Not plain text. Use a card background, soft shadow, and/or a thin border,
   rounded corners, and clear padding. Include a clear action button labeled
   "Got it" (or "Continue").

## 2D department scene (the unique core feature)

4. **Finding a correct word must visibly develop the 2D department scene.**
   This is what makes the game unique versus a plain word puzzle. When a word
   is found, a small 2D area in the upper/middle region should grow or unlock:
   e.g. for Computer Engineering, pieces of a Programming Lab / Code Screen /
   Function Block / server rack light up or appear as more words are found.
   The scene should reflect overall level progress.

## Visual language

- 2D flat design, clean and minimal, soft pastel palette.
- Computer Engineering color identity: blue, dark gray, neon-green accents.
- Simple, satisfying micro-animations (found = glow/unlock; wrong = gentle
  shake; level complete = a small celebration).
- Use SF Symbols as placeholders until custom 2D art is provided.

## Technical note

- The letter-wheel mechanic is built in SwiftUI (not SpriteKit) for simplicity
  and maintainability. SpriteKit may be used later for richer 2D scene
  animations if needed, but do not rewrite the existing SwiftUI wheel into
  SpriteKit without being asked.
