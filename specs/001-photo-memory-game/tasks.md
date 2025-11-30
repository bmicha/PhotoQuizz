# Tasks: PhotoQuizz - Photo Memory Game

**Input**: Design documents from `/specs/001-photo-memory-game/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/services.md, research.md, quickstart.md

**Tests**: No explicit test-first requirement in spec. Test tasks are NOT included per default. Unit tests can be added in Polish phase if desired.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- **App**: `PhotoQuizz/App/`
- **Features**: `PhotoQuizz/Features/{Onboarding,Home,AlbumSelection,Game,Settings}/`
- **Services**: `PhotoQuizz/Services/`
- **Models**: `PhotoQuizz/Models/`
- **Extensions**: `PhotoQuizz/Extensions/`
- **Resources**: `PhotoQuizz/Resources/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create new tvOS project "PhotoQuizz" in Xcode with SwiftUI, targeting tvOS 17.0+
- [x] T002 Configure Info.plist with NSPhotoLibraryUsageDescription for photo access permission
- [x] T003 [P] Create folder structure: App/, Features/, Services/, Models/, Extensions/, Resources/ in PhotoQuizz/
- [x] T004 [P] Configure Assets.xcassets with app icon placeholder in PhotoQuizz/Resources/Assets.xcassets

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models and services that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

### Core Models

- [x] T005 [P] Create RevealSpeed enum (slow/medium/fast with durations) in PhotoQuizz/Models/UserSettings.swift
- [x] T006 [P] Create SessionLength enum (five/ten/twenty/endless) in PhotoQuizz/Models/UserSettings.swift
- [x] T007 [P] Create GamePhase enum (revealing/revealed/complete) in PhotoQuizz/Models/GameSession.swift
- [x] T008 Create UserSettings struct with Codable conformance in PhotoQuizz/Models/UserSettings.swift
- [x] T009 [P] Create PhotoItem struct with PHAsset, location, dateTaken in PhotoQuizz/Models/PhotoItem.swift
- [x] T010 [P] Create PhotoAlbum struct with id, title, geotaggedCount in PhotoQuizz/Models/PhotoAlbum.swift
- [x] T011 [P] Create LocationReveal struct with coordinate, city, country, displayDate, isOffline in PhotoQuizz/Models/LocationReveal.swift
- [x] T012 Create GameSession class with @Observable, photos array, currentIndex, phase, revealedTiles, timerRemaining in PhotoQuizz/Models/GameSession.swift

### Core Services

- [x] T013 Implement PhotoLibraryService with authorization and fetchGeotaggedPhotos in PhotoQuizz/Services/PhotoLibraryService.swift
- [x] T014 [P] Implement GeocodingService with reverseGeocode and offline fallback in PhotoQuizz/Services/GeocodingService.swift
- [x] T015 [P] Implement SettingsService with UserDefaults persistence in PhotoQuizz/Services/SettingsService.swift

### Extensions

- [x] T016 [P] Create CLLocation+Formatting extension for coordinate string formatting in PhotoQuizz/Extensions/CLLocation+Formatting.swift

### App Entry Point

- [x] T017 Create PhotoQuizzApp.swift with @main entry point and environment objects in PhotoQuizz/App/PhotoQuizzApp.swift
- [x] T018 Create ContentView.swift with root navigation state (permission check → home) in PhotoQuizz/App/ContentView.swift

**Checkpoint**: Foundation ready - all models, services, and app structure in place

---

## Phase 3: User Story 5 - Grant Photo Library Access (Priority: P1) 🎯 MVP

**Goal**: First-time users can grant photo library access through a clear permission flow

**Independent Test**: Launch app fresh, see permission explanation, grant/deny access, verify navigation to appropriate screen

### Implementation for User Story 5

- [x] T019 [P] [US5] Create PermissionRequestView with explanation text and "Allow Access" button in PhotoQuizz/Features/Onboarding/PermissionRequestView.swift
- [x] T020 [P] [US5] Create PermissionDeniedView with instructions to enable in Settings in PhotoQuizz/Features/Onboarding/PermissionDeniedView.swift
- [x] T021 [US5] Update ContentView to check authorization status and show appropriate view in PhotoQuizz/App/ContentView.swift
- [x] T022 [US5] Add focus styling to permission buttons with scale and shadow effects in PhotoQuizz/Features/Onboarding/PermissionRequestView.swift

**Checkpoint**: Permission flow complete - app can request and handle photo library access

---

## Phase 4: User Story 1 - Play Discovery Mode Solo (Priority: P1) 🎯 MVP

**Goal**: Users can play the core game: photo reveals progressively, then shows location on map with city/country/date

**Independent Test**: Start game session, watch tiles reveal randomly, timer counts down, press reveal or wait for timer, see map with location info, continue to next photo

### Implementation for User Story 1

- [x] T023 [P] [US1] Create HomeView with "Start Game" button and basic layout in PhotoQuizz/Features/Home/HomeView.swift
- [x] T024 [P] [US1] Create TileView component for individual tile with flip animation in PhotoQuizz/Features/Game/TileRevealView.swift
- [x] T025 [US1] Create TileRevealView with 6x6 grid layout using LazyVGrid in PhotoQuizz/Features/Game/TileRevealView.swift
- [x] T026 [US1] Implement tile reveal animation with random order and spring effect in PhotoQuizz/Features/Game/TileRevealView.swift
- [x] T027 [P] [US1] Create TimerView with circular countdown display in PhotoQuizz/Features/Game/TimerView.swift
- [x] T028 [US1] Create LocationRevealView with Map, pin annotation, city/country/date labels in PhotoQuizz/Features/Game/LocationRevealView.swift
- [x] T029 [US1] Handle offline fallback in LocationRevealView showing coordinates instead of city/country in PhotoQuizz/Features/Game/LocationRevealView.swift
- [x] T030 [US1] Create GameSessionView orchestrating reveal → timer → answer flow in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T031 [US1] Implement timer logic with pause on background (scenePhase) in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T032 [US1] Add "Reveal" button to skip timer and show answer in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T033 [US1] Add "Continue" button to advance to next photo in GameSessionView in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T034 [US1] Handle session completion (show summary or return to home) in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T035 [US1] Wire HomeView "Start Game" to fetch photos and launch GameSessionView in PhotoQuizz/Features/Home/HomeView.swift

**Checkpoint**: Core game loop complete - users can play a full photo guessing session

---

## Phase 5: User Story 4 - Navigate with Siri Remote (Priority: P1)

**Goal**: All screens navigate smoothly with Siri Remote touchpad, click, and Menu button

**Independent Test**: Navigate through all screens using only Siri Remote, verify focus moves predictably, click performs actions, Menu goes back

### Implementation for User Story 4

- [x] T036 [US4] Add .focusable() and focus state styling to HomeView buttons in PhotoQuizz/Features/Home/HomeView.swift
- [x] T037 [US4] Add .focusable() and focus state styling to GameSessionView controls in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T038 [US4] Add .onExitCommand for Menu button navigation throughout app in PhotoQuizz/App/ContentView.swift
- [x] T039 [US4] Ensure focus indicator (scale + shadow) is consistent across all interactive elements in all Feature views
- [x] T040 [US4] Test and fix any focus traps or unexpected focus movement patterns in game flow

**Checkpoint**: Remote navigation complete - entire app is usable with Siri Remote only

---

## Phase 6: User Story 2 - Browse and Select Photo Albums (Priority: P2)

**Goal**: Users can select specific albums to play with photos from trips or time periods

**Independent Test**: Navigate to album selection, see list of albums with geotagged photo counts, select albums, start game and verify only selected album photos appear

### Implementation for User Story 2

- [x] T041 [P] [US2] Add fetchAlbums() method to PhotoLibraryService returning [PhotoAlbum] in PhotoQuizz/Services/PhotoLibraryService.swift
- [x] T042 [P] [US2] Create AlbumGridItem view for album thumbnail with title and photo count in PhotoQuizz/Features/AlbumSelection/AlbumGridItem.swift
- [x] T043 [US2] Create AlbumSelectionView with grid of selectable albums in PhotoQuizz/Features/AlbumSelection/AlbumSelectionView.swift
- [x] T044 [US2] Add multi-select functionality with checkmarks to AlbumSelectionView in PhotoQuizz/Features/AlbumSelection/AlbumSelectionView.swift
- [x] T045 [US2] Add selectedAlbumIds binding to SettingsService in PhotoQuizz/Services/SettingsService.swift
- [x] T046 [US2] Add "Select Albums" navigation from HomeView to AlbumSelectionView in PhotoQuizz/Features/Home/HomeView.swift
- [x] T047 [US2] Update photo fetching in HomeView to filter by selected albums in PhotoQuizz/Features/Home/HomeView.swift
- [x] T048 [US2] Add focus styling to album grid items with scale effect in PhotoQuizz/Features/AlbumSelection/AlbumGridItem.swift

**Checkpoint**: Album selection complete - users can customize which photos appear in games

---

## Phase 7: User Story 3 - Customize Game Settings (Priority: P3)

**Goal**: Users can adjust reveal speed, timer duration, and session length

**Independent Test**: Open settings, change each option, start game and verify new settings are applied

### Implementation for User Story 3

- [x] T049 [US3] Create SettingsView with sections for reveal speed, timer, session length in PhotoQuizz/Features/Settings/SettingsView.swift
- [x] T050 [US3] Implement reveal speed picker (slow/medium/fast) with current value display in PhotoQuizz/Features/Settings/SettingsView.swift
- [x] T051 [US3] Implement timer duration picker (10-120 seconds range) in PhotoQuizz/Features/Settings/SettingsView.swift
- [x] T052 [US3] Implement session length picker (5/10/20/endless options) in PhotoQuizz/Features/Settings/SettingsView.swift
- [x] T053 [US3] Add "Settings" navigation from HomeView to SettingsView in PhotoQuizz/Features/Home/HomeView.swift
- [x] T054 [US3] Wire GameSessionView to use settings from SettingsService in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T055 [US3] Wire TileRevealView reveal timing to use revealSpeed setting in PhotoQuizz/Features/Game/TileRevealView.swift
- [x] T056 [US3] Add focus styling to all settings controls in PhotoQuizz/Features/Settings/SettingsView.swift

**Checkpoint**: Settings complete - users can customize game difficulty and duration

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, error handling, and quality improvements

- [x] T057 Handle edge case: fewer than 5 geotagged photos with friendly message in PhotoQuizz/Features/Home/HomeView.swift
- [x] T058 Handle edge case: photo access revoked mid-session return to home in PhotoQuizz/Features/Game/GameSessionView.swift
- [x] T059 Handle edge case: "Date unknown" display when photo has no date in PhotoQuizz/Features/Game/LocationRevealView.swift
- [x] T060 [P] Add loading indicator during photo fetching in PhotoQuizz/Features/Home/HomeView.swift
- [x] T061 [P] Add loading indicator during image loading in TileRevealView in PhotoQuizz/Features/Game/TileRevealView.swift
- [x] T062 [P] Add app icon and launch screen assets in PhotoQuizz/Resources/Assets.xcassets
- [x] T063 Review and ensure 10-foot UI compliance (large text, high contrast) across all views
- [x] T064 Run quickstart.md validation - verify app matches documented behavior

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-7)**: All depend on Foundational phase completion
  - US5 (Permissions) should complete first (gates photo access)
  - US1 (Core Game) depends on US5
  - US4 (Navigation) can proceed in parallel with US1
  - US2, US3 can proceed after US1 or in parallel with US1
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

```
US5 (Permissions) ─┬─► US1 (Core Game) ──► US2 (Albums)
                   │                    └─► US3 (Settings)
                   └─► US4 (Navigation) ◄── (cross-cutting, applies to all)
```

- **US5 (P1)**: MUST complete first - gates all photo functionality
- **US1 (P1)**: Core game - can start after US5
- **US4 (P1)**: Navigation polish - can proceed in parallel, applies across all views
- **US2 (P2)**: Album selection - enhances US1, can start after Foundational
- **US3 (P3)**: Settings - enhances US1, can start after Foundational

### Within Each User Story

- Views can be created in parallel when they don't share state
- Service integration tasks depend on service implementation (Phase 2)
- Focus styling tasks depend on view implementation

### Parallel Opportunities

**Phase 2 (Foundational):**
```
T005, T006, T007 in parallel (all enums)
T009, T010, T011 in parallel (all structs)
T013, T014, T015 in parallel (all services, different files)
```

**Phase 4 (US1 Core Game):**
```
T023, T024, T027 in parallel (HomeView, TileView, TimerView)
```

**Phase 6 (US2 Albums):**
```
T041, T042 in parallel (service method, grid item view)
```

---

## Parallel Example: Phase 2 Foundational

```bash
# Launch enum tasks together:
Task: "Create RevealSpeed enum in PhotoQuizz/Models/UserSettings.swift"
Task: "Create SessionLength enum in PhotoQuizz/Models/UserSettings.swift"
Task: "Create GamePhase enum in PhotoQuizz/Models/GameSession.swift"

# Launch model struct tasks together:
Task: "Create PhotoItem struct in PhotoQuizz/Models/PhotoItem.swift"
Task: "Create PhotoAlbum struct in PhotoQuizz/Models/PhotoAlbum.swift"
Task: "Create LocationReveal struct in PhotoQuizz/Models/LocationReveal.swift"

# Launch service tasks together:
Task: "Implement PhotoLibraryService in PhotoQuizz/Services/PhotoLibraryService.swift"
Task: "Implement GeocodingService in PhotoQuizz/Services/GeocodingService.swift"
Task: "Implement SettingsService in PhotoQuizz/Services/SettingsService.swift"
```

---

## Implementation Strategy

### MVP First (US5 + US1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: US5 (Permissions)
4. Complete Phase 4: US1 (Core Game)
5. **STOP and VALIDATE**: Test permission flow + full game loop
6. Complete Phase 5: US4 (Navigation polish)
7. Deploy/demo if ready - this is a functional MVP!

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US5 (Permissions) → Test → App can request access
3. Add US1 (Core Game) → Test → Full game playable (MVP!)
4. Add US4 (Navigation) → Test → Polished remote experience
5. Add US2 (Albums) → Test → Album filtering works
6. Add US3 (Settings) → Test → Customizable difficulty
7. Polish → Production ready

### Task Count Summary

| Phase | Story | Task Count |
|-------|-------|------------|
| Phase 1 | Setup | 4 |
| Phase 2 | Foundational | 14 |
| Phase 3 | US5 (Permissions) | 4 |
| Phase 4 | US1 (Core Game) | 13 |
| Phase 5 | US4 (Navigation) | 5 |
| Phase 6 | US2 (Albums) | 8 |
| Phase 7 | US3 (Settings) | 8 |
| Phase 8 | Polish | 8 |
| **Total** | | **64** |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after its phase completes
- tvOS focus management is critical - test with Siri Remote throughout
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
