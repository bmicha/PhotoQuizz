# Service Contracts: PhotoQuizz

**Date**: 2025-11-30
**Branch**: `001-photo-memory-game`

This document defines the internal service contracts for PhotoQuizz. Since this is a native tvOS app with no external API, contracts describe Swift protocols and their expected behaviors.

---

## PhotoLibraryService

Abstracts PhotoKit operations for fetching photos and albums.

### Protocol Definition

```swift
protocol PhotoLibraryServiceProtocol {
    /// Current authorization status
    var authorizationStatus: PHAuthorizationStatus { get }

    /// Request photo library access
    /// - Returns: Granted status after request
    func requestAuthorization() async -> PHAuthorizationStatus

    /// Fetch all albums containing geotagged photos
    /// - Returns: Array of PhotoAlbum sorted by title
    func fetchAlbums() async throws -> [PhotoAlbum]

    /// Fetch geotagged photos from specified albums (or all if empty)
    /// - Parameter albumIds: Album identifiers to filter by (empty = all)
    /// - Parameter limit: Maximum photos to return (nil = unlimited)
    /// - Returns: Array of PhotoItem with valid locations
    func fetchGeotaggedPhotos(from albumIds: Set<String>, limit: Int?) async throws -> [PhotoItem]

    /// Load image for display
    /// - Parameter asset: Photo asset to load
    /// - Parameter targetSize: Desired image size
    /// - Returns: Loaded image
    func loadImage(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage
}
```

### Behaviors

| Method | Success | Failure |
|--------|---------|---------|
| requestAuthorization() | Returns .authorized or .limited | Returns .denied or .restricted |
| fetchAlbums() | Returns [PhotoAlbum] (may be empty) | Throws if not authorized |
| fetchGeotaggedPhotos() | Returns shuffled [PhotoItem] | Throws if not authorized |
| loadImage() | Returns UIImage at target size | Throws on load failure |

### Errors

```swift
enum PhotoLibraryError: Error {
    case notAuthorized
    case accessDenied
    case noGeotaggedPhotos
    case loadFailed(PHAsset)
}
```

---

## GeocodingService

Handles reverse geocoding of coordinates to place names.

### Protocol Definition

```swift
protocol GeocodingServiceProtocol {
    /// Convert coordinates to city/country
    /// - Parameter coordinate: GPS location
    /// - Returns: LocationReveal with place names (nil if offline)
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> LocationReveal

    /// Check if network is available for geocoding
    var isNetworkAvailable: Bool { get }
}
```

### Behaviors

| Method | Success | Failure/Offline |
|--------|---------|-----------------|
| reverseGeocode() | Returns LocationReveal with city/country | Returns LocationReveal with isOffline=true, city/country=nil |

### Caching Strategy

- Cache results by coordinate (rounded to 4 decimal places)
- Cache lifetime: Duration of game session
- Cache size: Unbounded (session length limits it naturally)

### Rate Limiting

- CLGeocoder allows ~50 requests/minute
- Sequential reveals naturally stay under limit
- No explicit throttling needed

---

## SettingsService

Manages user preferences persistence.

### Protocol Definition

```swift
protocol SettingsServiceProtocol {
    /// Current user settings
    var settings: UserSettings { get }

    /// Update reveal speed
    func setRevealSpeed(_ speed: RevealSpeed)

    /// Update timer duration
    func setTimerDuration(_ seconds: Int)

    /// Update session length
    func setSessionLength(_ length: SessionLength)

    /// Update selected albums
    func setSelectedAlbums(_ albumIds: Set<String>)

    /// Reset all settings to defaults
    func resetToDefaults()
}
```

### Behaviors

| Method | Behavior |
|--------|----------|
| settings (get) | Returns current settings, defaults if none saved |
| set*() methods | Immediately persists to UserDefaults |
| resetToDefaults() | Clears all saved settings |

### UserDefaults Keys

```swift
enum SettingsKey: String {
    case revealSpeed = "com.photoquizz.revealSpeed"
    case timerDuration = "com.photoquizz.timerDuration"
    case sessionLength = "com.photoquizz.sessionLength"
    case selectedAlbumIds = "com.photoquizz.selectedAlbumIds"
}
```

---

## GameSessionManager

Orchestrates game flow and state transitions.

### Protocol Definition

```swift
protocol GameSessionManagerProtocol {
    /// Current game session (nil if no active game)
    var currentSession: GameSession? { get }

    /// Observable game state for UI binding
    var gameState: GameState { get }

    /// Start a new game session
    /// - Parameter settings: Settings snapshot for this session
    /// - Parameter photos: Pre-fetched photos to use
    func startSession(settings: UserSettings, photos: [PhotoItem]) throws

    /// Called when a tile should be revealed
    func revealNextTile()

    /// Called when user skips to answer or timer expires
    func showAnswer()

    /// Advance to next photo
    func nextPhoto()

    /// End current session
    func endSession()
}
```

### Game State

```swift
struct GameState {
    let phase: GamePhase
    let currentPhoto: PhotoItem?
    let revealedTiles: Set<Int>
    let timerRemaining: Int
    let progress: (current: Int, total: Int)
    let locationReveal: LocationReveal?
}
```

### State Transitions

```
startSession() → phase = .revealing, timer starts
revealNextTile() → adds tile to revealedTiles (if revealing)
showAnswer() → phase = .revealed, stops timer, triggers geocoding
nextPhoto() → increments currentIndex, phase = .revealing (or .complete)
endSession() → currentSession = nil
```

### Errors

```swift
enum GameSessionError: Error {
    case noPhotosAvailable
    case sessionAlreadyActive
}
```

---

## Timer Contract

Timer behavior during gameplay.

### Requirements

| Requirement | Behavior |
|-------------|----------|
| Start | Begins when photo reveal starts |
| Tick | Decrements every second |
| Pause | When app enters background |
| Resume | When app returns to foreground |
| Stop | When user reveals answer or timer reaches 0 |
| Expiry | Automatically triggers showAnswer() |

### Implementation Note

Use `Timer.publish()` with `.autoconnect()` and handle `scenePhase` changes for pause/resume.

---

## View Contracts

### TileRevealView

**Input**:
- image: UIImage (full photo)
- revealedTiles: Set<Int> (0-35)
- gridSize: Int (default 6)

**Output**:
- Renders 6x6 grid of tiles
- Revealed tiles show photo portion
- Hidden tiles show placeholder (dark)
- Flip animation on reveal

### LocationRevealView

**Input**:
- locationReveal: LocationReveal

**Output**:
- Map centered on coordinate
- Pin/marker at location
- City, Country text (or coordinates if offline)
- Date text

### Focus Requirements

All interactive views must:
- Support `.focusable()` modifier
- Show clear focus indicator (scale + shadow)
- Handle `.onMoveCommand` for directional input
- Handle click/select action
