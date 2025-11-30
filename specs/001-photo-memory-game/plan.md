# Implementation Plan: PhotoQuizz - Photo Memory Game

**Branch**: `001-photo-memory-game` | **Date**: 2025-11-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-photo-memory-game/spec.md`

## Summary

A tvOS photo memory game that lets users rediscover their memories by guessing where their geotagged photos were taken. Photos reveal progressively using a tile-based animation, then display the location on a map with city/country and date. Built as a native tvOS app using SwiftUI with PhotoKit for photo access and MapKit for location display.

## Technical Context

**Language/Version**: Swift 5.9+ with iOS 17 / tvOS 17 SDK
**Primary Dependencies**: SwiftUI, PhotoKit (PHPhotoLibrary), MapKit, CoreLocation (CLGeocoder)
**Storage**: UserDefaults for settings persistence (no complex data storage needed)
**Testing**: XCTest with Swift Testing framework
**Target Platform**: tvOS 17.0+
**Project Type**: Single tvOS application
**Performance Goals**: 60 fps animations, <3s app launch, <2s geocoding response
**Constraints**: Siri Remote navigation only, network required for maps/geocoding (graceful fallback to coordinates)
**Scale/Scope**: Single-user local app, typical photo library (1,000-50,000 photos)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: Project constitution contains template placeholders. Applying sensible defaults for tvOS development:

| Gate | Status | Notes |
|------|--------|-------|
| Single App Structure | ✅ PASS | One tvOS app target, no unnecessary complexity |
| Native Frameworks | ✅ PASS | Using Apple-provided frameworks (SwiftUI, PhotoKit, MapKit) |
| Test Coverage | ✅ PASS | XCTest for unit/UI tests planned |
| Simplicity | ✅ PASS | Minimal dependencies, standard tvOS patterns |

No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/001-photo-memory-game/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (internal app contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
PhotoQuizz/
├── App/
│   ├── PhotoQuizzApp.swift          # App entry point
│   └── ContentView.swift            # Root navigation
├── Features/
│   ├── Onboarding/
│   │   ├── PermissionRequestView.swift
│   │   └── PermissionDeniedView.swift
│   ├── Home/
│   │   └── HomeView.swift
│   ├── AlbumSelection/
│   │   ├── AlbumSelectionView.swift
│   │   └── AlbumGridItem.swift
│   ├── Game/
│   │   ├── GameSessionView.swift
│   │   ├── TileRevealView.swift
│   │   ├── TimerView.swift
│   │   └── LocationRevealView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   ├── PhotoLibraryService.swift    # PhotoKit wrapper
│   ├── GeocodingService.swift       # CLGeocoder wrapper
│   └── SettingsService.swift        # UserDefaults wrapper
├── Models/
│   ├── GameSession.swift
│   ├── PhotoItem.swift
│   ├── LocationReveal.swift
│   └── UserSettings.swift
├── Extensions/
│   └── CLLocation+Formatting.swift
└── Resources/
    └── Assets.xcassets

PhotoQuizzTests/
├── Services/
│   ├── PhotoLibraryServiceTests.swift
│   ├── GeocodingServiceTests.swift
│   └── SettingsServiceTests.swift
├── Models/
│   └── GameSessionTests.swift
└── Features/
    └── Game/
        └── TileRevealTests.swift

PhotoQuizzUITests/
└── GameFlowUITests.swift
```

**Structure Decision**: Single tvOS app with feature-based organization. Features are grouped by screen/flow (Onboarding, Home, AlbumSelection, Game, Settings). Services provide reusable business logic. Models are plain Swift types. This structure supports the focused scope of a single-platform entertainment app.

## Complexity Tracking

> No violations - structure is minimal for requirements.

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| No MVVM/Coordinator | Direct SwiftUI views | App is simple enough; MVVM adds unnecessary indirection |
| No Core Data | UserDefaults only | Only persisting simple settings; no complex data relationships |
| No third-party deps | Native frameworks | PhotoKit, MapKit, SwiftUI cover all requirements |
