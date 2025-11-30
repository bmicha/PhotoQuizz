import Foundation
import Observation

// MARK: - GamePhase Enum (T007)

/// Current phase of the game session
enum GamePhase: Equatable {
    case revealing  // Tiles are progressively revealing, timer running
    case revealed   // Answer shown (map, city, country, date)
    case complete   // Session finished, show summary
}

// MARK: - GameSession Class (T012)

/// Active game state managing photo sequence and progress
@Observable
final class GameSession {
    // MARK: - Properties

    let id: UUID
    let photos: [PhotoItem]
    let settings: UserSettings

    private(set) var currentIndex: Int
    private(set) var phase: GamePhase
    private(set) var revealedTiles: Set<Int>
    private(set) var timerRemaining: Int

    // MARK: - Constants

    static let gridSize = 6
    static let totalTiles = 36 // 6x6 grid

    // MARK: - Computed Properties

    var currentPhoto: PhotoItem? {
        guard currentIndex >= 0 && currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var progress: (current: Int, total: Int) {
        let total = settings.sessionLength.count ?? photos.count
        return (currentIndex + 1, min(total, photos.count))
    }

    var isComplete: Bool {
        phase == .complete
    }

    var hasMorePhotos: Bool {
        let nextIndex = currentIndex + 1
        if let sessionCount = settings.sessionLength.count {
            return nextIndex < sessionCount && nextIndex < photos.count
        }
        return nextIndex < photos.count
    }

    // MARK: - Initialization

    init(photos: [PhotoItem], settings: UserSettings) {
        self.id = UUID()
        self.photos = photos.shuffled()
        self.settings = settings
        self.currentIndex = 0
        self.phase = .revealing
        self.revealedTiles = []
        self.timerRemaining = settings.timerDuration
    }

    // MARK: - Game Actions

    /// Reveal the next tile in the grid
    func revealNextTile() {
        guard phase == .revealing else { return }

        // Find unrevealed tiles
        let allTiles = Set(0..<Self.totalTiles)
        let unrevealed = allTiles.subtracting(revealedTiles)

        if let nextTile = unrevealed.randomElement() {
            revealedTiles.insert(nextTile)
        }

        // Auto-reveal all if time is up
        if revealedTiles.count >= Self.totalTiles {
            showAnswer()
        }
    }

    /// Skip timer and show the answer
    func showAnswer() {
        guard phase == .revealing else { return }
        phase = .revealed
        revealedTiles = Set(0..<Self.totalTiles) // Reveal all tiles
    }

    /// Move to the next photo
    func nextPhoto() {
        guard phase == .revealed else { return }

        if hasMorePhotos {
            currentIndex += 1
            phase = .revealing
            revealedTiles = []
            timerRemaining = settings.timerDuration
        } else {
            phase = .complete
        }
    }

    /// Decrement timer by one second
    func tick() {
        guard phase == .revealing && timerRemaining > 0 else { return }
        timerRemaining -= 1
        if timerRemaining <= 0 {
            showAnswer()
        }
    }

    /// End the session early
    func endSession() {
        phase = .complete
    }
}

// MARK: - GameSession Errors

enum GameSessionError: Error, LocalizedError {
    case noPhotosAvailable
    case sessionAlreadyActive

    var errorDescription: String? {
        switch self {
        case .noPhotosAvailable:
            return "No geotagged photos available to play with."
        case .sessionAlreadyActive:
            return "A game session is already in progress."
        }
    }
}
