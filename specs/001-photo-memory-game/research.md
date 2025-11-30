# Research: PhotoQuizz - Photo Memory Game

**Date**: 2025-11-30
**Branch**: `001-photo-memory-game`

## Technology Decisions

### 1. UI Framework: SwiftUI

**Decision**: Use SwiftUI as the primary UI framework

**Rationale**:
- Native tvOS support with focus engine built-in
- Declarative syntax simplifies state management for game flow
- Animation APIs well-suited for tile reveal effect
- tvOS 17+ provides mature SwiftUI implementation

**Alternatives Considered**:
- UIKit: More manual focus handling, imperative patterns add complexity
- Hybrid UIKit+SwiftUI: Unnecessary complexity for this app scope

### 2. Photo Access: PhotoKit (Photos Framework)

**Decision**: Use PHPhotoLibrary and PHAsset for photo access

**Rationale**:
- Official Apple framework for photo library access
- Provides metadata including GPS coordinates (CLLocation) and creation date
- Supports album enumeration (PHAssetCollection)
- Handles authorization flow natively

**Key APIs**:
- `PHPhotoLibrary.requestAuthorization(for:)` - Permission request
- `PHAsset.fetchAssets(in:options:)` - Fetch photos from albums
- `PHAsset.location` - GPS coordinates (CLLocation?)
- `PHAsset.creationDate` - Photo date (Date?)
- `PHImageManager.requestImage(for:)` - Load image data

**Alternatives Considered**:
- Direct file system access: Not available on tvOS for user photos

### 3. Map Display: MapKit

**Decision**: Use MKMapView (via SwiftUI Map) for location reveal

**Rationale**:
- Native Apple framework, no API keys required
- Integrates seamlessly with CoreLocation
- Supports satellite/hybrid views for visual appeal
- Annotation support for marking photo location

**Key APIs**:
- `Map` SwiftUI view with camera position
- `MKMapCamera` for programmatic positioning
- `Marker` or `Annotation` for location pin

**Alternatives Considered**:
- Google Maps SDK: Requires API key, additional dependency
- Static map images: Less interactive, requires network for each image

### 4. Reverse Geocoding: CoreLocation CLGeocoder

**Decision**: Use CLGeocoder for coordinates → city/country conversion

**Rationale**:
- Built into CoreLocation, no external API needed
- Returns CLPlacemark with locality, country, etc.
- Rate-limited but sufficient for sequential photo reveals

**Key APIs**:
- `CLGeocoder.reverseGeocodeLocation(_:)` - async/await version
- `CLPlacemark.locality` - City name
- `CLPlacemark.country` - Country name

**Considerations**:
- Rate limiting: ~50 requests/minute (sufficient for game pace)
- Network dependency: Fallback to coordinates if offline

**Alternatives Considered**:
- OpenStreetMap Nominatim: External dependency, API limits
- Cached geocoding database: Complex, storage overhead

### 5. Settings Persistence: UserDefaults

**Decision**: Use UserDefaults for storing user preferences

**Rationale**:
- Simple key-value storage sufficient for settings
- No complex relationships or queries needed
- Native tvOS support with iCloud sync capability
- Minimal code for read/write operations

**Data to Persist**:
- Reveal speed (enum: slow/medium/fast)
- Timer duration (Int: seconds)
- Session length (enum: 5/10/20/endless)
- Selected album IDs (Set<String>)

**Alternatives Considered**:
- Core Data: Overkill for simple settings
- JSON file: Manual serialization needed
- SwiftData: tvOS 17 support unclear, adds complexity

### 6. Tile Reveal Animation Strategy

**Decision**: Grid-based tile flip animation using SwiftUI

**Rationale**:
- SwiftUI provides built-in animation modifiers
- Can use `LazyVGrid` for tile layout
- Opacity/rotation3DEffect for flip animation
- Random order achievable with shuffled indices

**Implementation Approach**:
1. Divide photo into NxN grid (e.g., 6x6 = 36 tiles)
2. Each tile starts hidden (opacity 0 or flipped)
3. Timer triggers random tile reveals
4. Each reveal uses `.animation(.spring())` for smooth flip
5. Complete when all tiles revealed or user skips

**Performance Consideration**:
- Pre-render tile images to avoid per-frame cropping
- Use `drawingGroup()` for GPU-accelerated compositing

### 7. tvOS Focus Navigation

**Decision**: Leverage SwiftUI's built-in focus system

**Rationale**:
- SwiftUI on tvOS handles focus automatically for standard controls
- `@FocusState` for programmatic focus management
- `.focusable()` modifier for custom focusable views

**Key Patterns**:
- Use standard Button/NavigationLink where possible
- Custom game controls use `.focusable(true)` with `.onMoveCommand`
- Menu button handled via `.onExitCommand` modifier

**Alternatives Considered**:
- UIKit focus engine: More control but more boilerplate
- Custom gesture recognizers: Fights against platform conventions

## Best Practices Research

### tvOS App Design Guidelines

1. **10-foot UI**: Design for viewing distance of ~10 feet
   - Large text (minimum 29pt for body)
   - High contrast colors
   - Simple, uncluttered layouts

2. **Focus-based Navigation**:
   - Clear focus indicators (scale, shadow, glow)
   - Predictable focus movement
   - Avoid focus traps

3. **Content-forward Design**:
   - Photos should dominate the screen
   - Minimal chrome/UI during gameplay
   - Ambient, relaxed aesthetic for "chill" experience

### PhotoKit Best Practices

1. **Batch Fetching**: Use fetch options to filter by location
   ```swift
   let options = PHFetchOptions()
   options.predicate = NSPredicate(format: "location != nil")
   ```

2. **Image Loading**: Use target size to avoid loading full resolution
   ```swift
   let options = PHImageRequestOptions()
   options.deliveryMode = .opportunistic
   options.resizeMode = .fast
   ```

3. **Authorization**: Always check status before fetching
   - Handle `.notDetermined`, `.authorized`, `.denied`, `.restricted`

### Game State Management

**Decision**: Use `@Observable` class for game session state

**Rationale**:
- Swift 5.9 Observation framework is cleaner than Combine
- Single source of truth for game state
- Automatic UI updates without manual subscriptions

**State Model**:
```swift
@Observable class GameSession {
    var photos: [PhotoItem]
    var currentIndex: Int
    var revealedTiles: Set<Int>
    var timerRemaining: Int
    var phase: GamePhase // .revealing, .revealed, .complete
}
```

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| User has no geotagged photos | Pre-flight check with friendly message |
| Geocoding rate limits | Cache results during session, fallback to coordinates |
| Large photo libraries slow | Paginate fetches, show loading indicator |
| Network unavailable | Graceful fallback (coordinates only, no map) |
| Photo access denied | Clear permission flow with Settings link |

## Open Questions (Resolved)

All technical unknowns have been resolved through this research phase. No blockers for Phase 1 design.
