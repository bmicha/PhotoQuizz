# Data Model: PhotoQuizz - Photo Memory Game

**Date**: 2025-11-30
**Branch**: `001-photo-memory-game`

## Entity Overview

```
┌─────────────────┐     ┌─────────────────┐
│   UserSettings  │     │   GameSession   │
│                 │     │                 │
│ - revealSpeed   │     │ - photos[]      │
│ - timerDuration │     │ - currentIndex  │
│ - sessionLength │     │ - phase         │
│ - selectedAlbums│     │ - settings      │
└─────────────────┘     └────────┬────────┘
                                 │ contains
                                 ▼
┌─────────────────┐     ┌─────────────────┐
│   PhotoAlbum    │     │   PhotoItem     │
│                 │     │                 │
│ - id            │◄────│ - asset         │
│ - title         │     │ - location      │
│ - thumbnailAsset│     │ - dateTaken     │
│ - photoCount    │     │ - albumId       │
└─────────────────┘     └────────┬────────┘
                                 │ reveals to
                                 ▼
                        ┌─────────────────┐
                        │ LocationReveal  │
                        │                 │
                        │ - coordinate    │
                        │ - city          │
                        │ - country       │
                        │ - displayDate   │
                        └─────────────────┘
```

## Entities

### UserSettings

Persisted user preferences for game configuration.

| Field | Type | Description | Default |
|-------|------|-------------|---------|
| revealSpeed | RevealSpeed | How fast tiles reveal | .medium |
| timerDuration | Int | Seconds for guessing phase | 30 |
| sessionLength | SessionLength | Photos per game | .ten |
| selectedAlbumIds | Set<String> | Album IDs to use (empty = all) | [] |

**Persistence**: UserDefaults with Codable encoding

**Validation Rules**:
- timerDuration: 10...120 seconds
- selectedAlbumIds: Valid PHAssetCollection identifiers

### RevealSpeed (Enum)

| Case | Value | Reveal Duration |
|------|-------|-----------------|
| slow | "slow" | 15 seconds |
| medium | "medium" | 10 seconds |
| fast | "fast" | 5 seconds |

### SessionLength (Enum)

| Case | Value | Photo Count |
|------|-------|-------------|
| five | "5" | 5 photos |
| ten | "10" | 10 photos |
| twenty | "20" | 20 photos |
| endless | "endless" | Until user quits |

---

### PhotoAlbum

Represents a selectable album from the user's photo library.

| Field | Type | Description |
|-------|------|-------------|
| id | String | PHAssetCollection.localIdentifier |
| title | String | Album display name |
| thumbnailAsset | PHAsset? | First photo for thumbnail |
| geotaggedCount | Int | Photos with location data |

**Source**: PHAssetCollection (smart albums + user albums)

**Validation Rules**:
- Only albums with geotaggedCount > 0 are selectable

---

### PhotoItem

A photo selected for gameplay with required metadata.

| Field | Type | Description |
|-------|------|-------------|
| id | String | PHAsset.localIdentifier |
| asset | PHAsset | Reference to photo asset |
| location | CLLocationCoordinate2D | GPS coordinates (required) |
| dateTaken | Date? | Photo creation date |
| albumId | String? | Source album identifier |

**Source**: PHAsset with non-nil location

**Validation Rules**:
- location must be valid (latitude: -90...90, longitude: -180...180)
- Photos without location are filtered out during fetch

**State**: Immutable once created

---

### GameSession

Active game state managing photo sequence and progress.

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique session identifier |
| photos | [PhotoItem] | Shuffled photos for this session |
| currentIndex | Int | Current photo being played |
| phase | GamePhase | Current game phase |
| revealedTiles | Set<Int> | Indices of revealed tiles (0-35) |
| timerRemaining | Int | Seconds left in timer |
| settings | UserSettings | Snapshot of settings at session start |

**Lifecycle States**:

```
            ┌─────────┐
            │ created │
            └────┬────┘
                 │ startGame()
                 ▼
            ┌─────────┐
   ┌───────►│revealing│◄──────┐
   │        └────┬────┘       │
   │             │ timerExpires() or reveal()
   │             ▼            │
   │        ┌─────────┐       │
   │        │revealed │       │
   │        └────┬────┘       │
   │             │ next()     │
   │             ▼            │
   │        ┌─────────┐       │
   │        │ hasMore?│───Yes─┘
   │        └────┬────┘
   │             │ No
   │             ▼
   │        ┌─────────┐
   └────────│complete │
   quit()   └─────────┘
```

**Validation Rules**:
- currentIndex: 0..<photos.count
- revealedTiles: 0..<36 (6x6 grid)
- timerRemaining: 0...settings.timerDuration

---

### GamePhase (Enum)

| Case | Description |
|------|-------------|
| revealing | Tiles are progressively revealing, timer running |
| revealed | Answer shown (map, city, country, date) |
| complete | Session finished, show summary |

---

### LocationReveal

Computed data for displaying the answer.

| Field | Type | Description |
|-------|------|-------------|
| coordinate | CLLocationCoordinate2D | Map center point |
| city | String? | Locality from geocoding |
| country | String? | Country from geocoding |
| displayDate | String | Formatted date or "Date unknown" |
| isOffline | Bool | True if geocoding failed |

**Computation**:
- city/country: From CLGeocoder.reverseGeocodeLocation()
- displayDate: DateFormatter with .medium style
- isOffline: Set when network unavailable (show coordinates only)

**Validation Rules**:
- If geocoding fails, city and country are nil
- displayDate is never nil (falls back to "Date unknown")

---

## Relationships

| From | To | Relationship | Cardinality |
|------|----|--------------|-------------|
| GameSession | PhotoItem | contains | 1:N (5-20 or unlimited) |
| GameSession | UserSettings | uses snapshot | 1:1 |
| PhotoItem | LocationReveal | reveals to | 1:1 (computed) |
| UserSettings | PhotoAlbum | references | 0:N (by ID) |

## Data Flow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ PhotoLibrary │───►│ PhotoItem[]  │───►│ GameSession  │
│  (PHAsset)   │    │  (filtered)  │    │  (shuffled)  │
└──────────────┘    └──────────────┘    └──────────────┘
                                               │
                                               ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  CLGeocoder  │◄───│  PhotoItem   │◄───│ currentPhoto │
│              │    │  .location   │    │              │
└──────┬───────┘    └──────────────┘    └──────────────┘
       │
       ▼
┌──────────────┐
│LocationReveal│
│ city/country │
└──────────────┘
```

## Storage Summary

| Entity | Storage | Lifetime |
|--------|---------|----------|
| UserSettings | UserDefaults | Persistent |
| PhotoAlbum | In-memory (from PhotoKit) | App session |
| PhotoItem | In-memory (from PhotoKit) | Game session |
| GameSession | In-memory | Game session |
| LocationReveal | In-memory (cached) | Game session |

No database required. All persistent data fits in UserDefaults.
