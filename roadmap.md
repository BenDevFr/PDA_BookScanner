# BookScanner - Roadmap & Testing Guide

## Project
**Mod**: HephasStalkerPDA_BookScanner  
**PZ Version**: 41.78.7  
**Goal**: Scan books with PDA to read them later without carrying them

---

## ✅ Phase 1 - Basic Scanning (COMPLETED)
- PDA detection in inventory
- Smart book filtering (recipes/skills only)
- Context menu "Scan with PDA"
- Scan feedback (message + sound)
- Auto-debug logging (3 levels)
- FR/EN translations
- Development tests

---

## ✅ Phase 2 - ModData Storage (COMPLETED)
- Minimal storage (fullType, category, timestamp)
- Duplicate detection
- Grayed option if already scanned
- Save/load persistence

---

## ✅ Phase 2.5 - Ownership System (COMPLETED)
- Multi-context ownership system (solo/multi)
- "Connect to this PDA" menu
- Auto-merge multiple libraries
- Player-bound PDA detection
- Protection against scanning foreign PDA

**Tests passed**:
- ✅ PDA connection in solo
- ✅ Scan with bound PDA
- ✅ Scan impossible without bound PDA
- ✅ Auto-merge (2-3 PDAs)

**Fixed bugs**:
- ✅ BSCore.lua line 118 (modData scope)
- ✅ PDA menu displaying technical ID instead of visible name

---

## 🚧 Phase 2.75 - Polish (IN PROGRESS)

### Immediate implementation
1. **Clear library (debug)**
   - Add to BSTests.lua
   - Context menu "🗑️ Clear PDA Library"
   - Uses `BSStorage.clearAllBooks()`

2. **Scan All**
   - New option "Scan all books"
   - Loop through scannable books, skip duplicates
   - Feedback: "X scanned, Y skipped"

3. **Library Menu (preview)**
   - On PDA: "Library (X books)"
   - Display simple list of scanned books
   - No reading yet (Phase 3)

---

## 📋 Phase 3 - Library Interface (PLANNED)

### Complete UI
- Dedicated book list window
- Sort by category (skill/recipe)
- Alphabetical / scan date sort
- Search/filter
- Display pages read (bonus via `getAlreadyReadPages()`)

### Reading scans
- Click book → display content
- Recipes: tooltip + icons
- Skills: description + XP multiplier
- No XP gain (virtual reading only)

---

## 🔮 Phase 4+ - Advanced Features (FUTURE)

### Data transfer
- **Memory cards**: Export/import library
- **PDA-to-PDA**: Direct sharing between players
- Physical "Memory Card" item to create

### Advanced gameplay
- **Scan time**: Timed action (ISTimedAction)
  - 220-page book: 8-10 seconds
  - Magazine: 3-5 seconds
  - Electronics skill multiplier?
- **Equipped PDA required**: Secondary hand or belt mandatory
- **Sandbox options**:
  - Destroy book on scan (true/false)
  - Storage capacity limit (unlimited/20/50/100)

### Optimization
- Cache PDA detection system (multi performance)
- Refactor `detectPDA()` / `hasPDA()` aliases

---

## 🐛 Known Bugs / To Fix

### Minor (non-blocking)
- **PDA name**: Displays "ShadZimmer" instead of "Shad Zimmer"
  - Cause: `getUsername()` returns without space
  - Possible solution: Parse and reformat, or use character name?
  - Priority: Low

### Log warnings
- `RecipeManager -> Cannot create recipe for movable item: Base.Hephas_StalkerPDA`
  - Non-blocking, vanilla PZ warning
  - Priority: Ignorable

---

## 🧪 Tests to Perform

### Unit tests (dev)
- [x] Connect virgin PDA
- [x] Scan with bound PDA
- [x] Scan without PDA (menu absent)
- [x] Auto-merge multi-PDAs
- [ ] Clear library (debug)
- [ ] Scan All
- [ ] Persistence after death/respawn

### Multiplayer tests
- [ ] Each player their own PDA
- [ ] PDAs renamed with Steam username
- [ ] Unable to scan foreign PDA
- [ ] Death + loot recovery
- [ ] Merge identical PDAs

### Edge case tests
- [ ] 10+ PDAs in inventory
- [ ] Scan 100+ books (limit?)
- [ ] Mod disabled then re-enabled
- [ ] Compatibility with other book mods

---

## 💡 Ideas / Notes

### Feature brainstorming
- **Read-only sharing**: View foreign PDA library without scanning
- **Library stats**: Books by category, progression
- **Achievements**: Scan all books in game
- **Lore/Immersion**: PDA displays "Connection established" on bind
- **Custom sound**: Different sound per book type (skill/recipe)

### Open questions
- Should there be a cost (battery, electricity) to scan?
- Allow scanning maps/blueprints?
- Integration with talent mods (Tree Tech, etc.)?

### Architectural decisions
- ModData stored on PDA (not player) → library follows object ✅
- Ownership based on `getUsername()` (multi) or save ID (solo) ✅
- Auto-merge rather than manual menu ✅
- No mod sorting (technically impossible) ✅

---

## 📦 Release Checklist

### Before Steam Workshop publication
- [ ] Comment/remove BSTests.lua
- [ ] Verify complete translations (FR/EN)
- [ ] Screenshots/demo video
- [ ] End-user README.md
- [ ] CHANGELOG.md
- [ ] Test in clean game (without debug)
- [ ] Verify dedicated server compatibility

### Workshop metadata
- Clear mod description
- Tags: UI, Multiplayer, Quality of Life
- Attractive preview images
- Credits: Hephas (original PDA)

---

## 🔄 Version History

### v1.0.0-phase2.5 (09/30/2025)
- Multi-context ownership system
- Auto-merge multiple PDAs
- PDA connection menu
- Solo vs multi detection

### v1.0.0-phase2 (09/30/2025)
- ModData storage
- Duplicate detection
- Persistence

### v1.0.0-phase1 (09/29/2025)
- Basic functional scanning
- PDA/book detection
- Auto-debug logs

---

*Last updated: 09/30/2025 21:30*