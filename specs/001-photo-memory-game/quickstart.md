# Quickstart Guide: PhotoQuizz

**Date**: 2025-11-30
**Branch**: `001-photo-memory-game`

## Prerequisites

- macOS 14.0+ (Sonoma) or later
- Xcode 15.0+ with tvOS 17 SDK
- Apple TV (4th generation or later) or tvOS Simulator
- Apple Developer account (for device testing)

## Project Setup

### 1. Create Xcode Project

```bash
# Open Xcode and create new project
# Select: tvOS > App
# Product Name: PhotoQuizz
# Organization Identifier: com.yourname
# Interface: SwiftUI
# Language: Swift
# Include Tests: Yes
```

### 2. Configure Info.plist

Add required privacy descriptions:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>PhotoQuizz needs access to your photos to create memory guessing games from your travel photos.</string>
```

### 3. Project Structure

Create the following folder structure in Xcode:

```
PhotoQuizz/
├── App/
├── Features/
│   ├── Onboarding/
│   ├── Home/
│   ├── AlbumSelection/
│   ├── Game/
│   └── Settings/
├── Services/
├── Models/
├── Extensions/
└── Resources/
```

## Quick Implementation Guide

### Step 1: Models (30 min)

Create data models in `Models/`:

```swift
// UserSettings.swift
import Foundation

enum RevealSpeed: String, Codable, CaseIterable {
    case slow, medium, fast

    var duration: TimeInterval {
        switch self {
        case .slow: return 15
        case .medium: return 10
        case .fast: return 5
        }
    }
}

enum SessionLength: String, Codable, CaseIterable {
    case five = "5"
    case ten = "10"
    case twenty = "20"
    case endless

    var count: Int? {
        switch self {
        case .five: return 5
        case .ten: return 10
        case .twenty: return 20
        case .endless: return nil
        }
    }
}

struct UserSettings: Codable {
    var revealSpeed: RevealSpeed = .medium
    var timerDuration: Int = 30
    var sessionLength: SessionLength = .ten
    var selectedAlbumIds: Set<String> = []
}
```

```swift
// PhotoItem.swift
import Photos
import CoreLocation

struct PhotoItem: Identifiable {
    let id: String
    let asset: PHAsset
    let location: CLLocationCoordinate2D
    let dateTaken: Date?

    init?(asset: PHAsset) {
        guard let location = asset.location?.coordinate else { return nil }
        self.id = asset.localIdentifier
        self.asset = asset
        self.location = location
        self.dateTaken = asset.creationDate
    }
}
```

### Step 2: Services (1 hour)

Create service layer in `Services/`:

```swift
// PhotoLibraryService.swift
import Photos

@Observable
class PhotoLibraryService {
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func fetchGeotaggedPhotos(limit: Int? = nil) async -> [PhotoItem] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "location != nil")
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(with: .image, options: options)
        var photos: [PhotoItem] = []

        assets.enumerateObjects { asset, index, stop in
            if let photo = PhotoItem(asset: asset) {
                photos.append(photo)
                if let limit, photos.count >= limit {
                    stop.pointee = true
                }
            }
        }

        return photos.shuffled()
    }
}
```

```swift
// SettingsService.swift
import Foundation

@Observable
class SettingsService {
    private let defaults = UserDefaults.standard
    private let key = "com.photoquizz.settings"

    var settings: UserSettings {
        didSet { save() }
    }

    init() {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            settings = decoded
        } else {
            settings = UserSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
```

### Step 3: Permission Flow (30 min)

```swift
// PermissionRequestView.swift
import SwiftUI

struct PermissionRequestView: View {
    let onAuthorized: () -> Void
    @State private var showDenied = false

    var body: some View {
        VStack(spacing: 40) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 120))
                .foregroundStyle(.blue)

            Text("Access Your Memories")
                .font(.title)

            Text("PhotoQuizz needs access to your photo library to create personalized memory games.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Allow Access") {
                Task {
                    let status = await PhotoLibraryService().requestAuthorization()
                    if status == .authorized || status == .limited {
                        onAuthorized()
                    } else {
                        showDenied = true
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(60)
        .fullScreenCover(isPresented: $showDenied) {
            PermissionDeniedView()
        }
    }
}
```

### Step 4: Core Game View (2 hours)

```swift
// TileRevealView.swift
import SwiftUI

struct TileRevealView: View {
    let image: UIImage
    let revealedTiles: Set<Int>
    let gridSize = 6

    var body: some View {
        GeometryReader { geometry in
            let tileSize = geometry.size.width / CGFloat(gridSize)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(tileSize), spacing: 0), count: gridSize), spacing: 0) {
                ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                    TileView(
                        image: image,
                        index: index,
                        gridSize: gridSize,
                        tileSize: tileSize,
                        isRevealed: revealedTiles.contains(index)
                    )
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct TileView: View {
    let image: UIImage
    let index: Int
    let gridSize: Int
    let tileSize: CGFloat
    let isRevealed: Bool

    var body: some View {
        ZStack {
            // Photo tile
            Image(uiImage: image)
                .resizable()
                .frame(width: tileSize * CGFloat(gridSize), height: tileSize * CGFloat(gridSize))
                .offset(
                    x: -CGFloat(index % gridSize) * tileSize,
                    y: -CGFloat(index / gridSize) * tileSize
                )
                .frame(width: tileSize, height: tileSize)
                .clipped()
                .opacity(isRevealed ? 1 : 0)

            // Hidden state
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(isRevealed ? 0 : 1)
        }
        .animation(.spring(duration: 0.5), value: isRevealed)
    }
}
```

### Step 5: Run on Simulator

1. Select "Apple TV" simulator in Xcode
2. Press Cmd+R to build and run
3. Use arrow keys to navigate (simulates Siri Remote)
4. Press Enter to select (simulates click)

## Testing Checklist

- [ ] Permission request appears on first launch
- [ ] Photos load after granting permission
- [ ] Tiles reveal progressively
- [ ] Timer counts down
- [ ] Map appears on reveal
- [ ] Settings persist after restart
- [ ] Focus navigation works with remote

## Common Issues

### No Photos in Simulator

The tvOS simulator may not have photos. Options:
1. Test on physical Apple TV with iCloud Photos
2. Use preview providers with mock data

### Focus Not Working

Ensure views use:
```swift
.focusable(true)
.focused($focusedField, equals: .someValue)
```

### Map Not Loading

Check network connectivity. The app should fall back to coordinates display.

## Next Steps

After quickstart setup:
1. Run `/speckit.tasks` to generate implementation tasks
2. Follow task order for incremental development
3. Test each feature independently per user stories
