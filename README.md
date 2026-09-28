# Cambodian Rek (ល្បែងរែក) - Mobile Board Game & Editor

A complete Flutter mobile implementation of the traditional Cambodian board game **Rek (ល្បែងរែក)**, featuring a full board setup editor, AI opponent, pass-and-play local multiplayer, save/load features, and authentic Rek capture rules.

---

## Interface Layout & Features

### Top Menu
- **Green Wi-Fi Connection Icon**: Located in the top-left corner, displaying peer/network status.
- **Erase all**: Clears pieces or provides an option to reset back to the standard setup.
- **Erase**: Toggles eraser mode to tap-and-remove individual pieces on the board.
- **Rotate Baord**: Smoothly rotates the board 180° with animated orientation flipping to view from either player's side.

### Piece Selectors
- **Above the Board (Teal Player)**:
  - Plain Teal Token
  - Crowned Teal Token (King)
- **Below the Board (Lime Green Player)**:
  - Plain Lime Green Token (*highlighted with a square selection box by default*)
  - Crowned Lime Green Token (King)
- **Selection Box**: Selecting any token directs your tap on the 8×8 board to place that exact piece.

### 8×8 Light Wood Board & Initial Setup
Custom painted light-wood grain texture with checkered tints and 180° rotational symmetry:
- **Teal Pieces (Top)**:
  - Row 1: 7 plain pieces (columns `a` to `g`, column `h` empty).
  - Row 2: 1 crowned piece at the far right (column `h`).
  - Row 3: Full row of 8 plain pieces.
- **Battlefield (Center)**:
  - Rows 4 and 5: Open neutral ground.
- **Lime Green Pieces (Bottom)**:
  - Row 6: Full row of 8 plain pieces.
  - Row 7: 1 crowned piece at the far left (column `a`).
  - Row 8: 7 plain pieces (columns `b` to `h`, column `a` empty).

### Bottom Menu
- **Yellow Back Arrow**: Located in the bottom-left corner; switches back to editor mode or opens the game options drawer.
- **Save**: Saves the current board setup and game state to local storage (`SharedPreferences`).
- **Load Game**: Opens the saved games dialog to resume previous matches or setups.
- **Play / Edit Board**: Toggles between interactive Sandbox Board Setup mode and live playable match mode.
- **White Chat Bubble Icon**: Located in the bottom-right corner; opens the Rek rules guide and full move history log.

---

## Authentic Cambodian Rek Rules

1. **Rook Orthogonal Movement**:
   - Every piece (King and Men) moves like a Chess Rook—in any of the 4 cardinal directions (up, down, left, right) across any number of unobstructed empty squares.
2. **"Rek" (Shoulder Pole) Capture**:
   - When a piece lands between two adjacent opposing enemy pieces along a straight line (`Enemy - Friendly - Enemy`), it performs a **Rek** and captures both flanking enemy pieces!
   - Simultaneous horizontal and vertical Rek can capture up to 4 pieces at once.
3. **Surrounding Capture (Khat / Hup)**:
   - Any enemy piece or group completely immobilized with zero legal orthogonal moves is trapped and captured.
4. **Victory Condition**:
   - Capturing the opposing King or eliminating all opposing pieces wins the game.

---

## Running the Application

### macOS Desktop:
```bash
flutter run -d macos
```

### Mobile (Android/iOS):
```bash
flutter run
```

### Web:
```bash
flutter run -d chrome
```

### Running Tests:
```bash
flutter test
flutter analyze
```
