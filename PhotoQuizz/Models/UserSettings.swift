import Foundation

// MARK: - RevealSpeed Enum (T005)

/// Controls how fast tiles reveal during the guessing phase
enum RevealSpeed: String, Codable, CaseIterable {
    case slow
    case medium
    case fast

    /// Duration in seconds for the full reveal animation
    var duration: TimeInterval {
        switch self {
        case .slow: return 15
        case .medium: return 10
        case .fast: return 5
        }
    }

    var displayName: String {
        switch self {
        case .slow: return "Slow (15s)"
        case .medium: return "Medium (10s)"
        case .fast: return "Fast (5s)"
        }
    }
}

// MARK: - SessionLength Enum (T006)

/// Number of photos in a game session
enum SessionLength: String, Codable, CaseIterable {
    case five = "5"
    case ten = "10"
    case twenty = "20"
    case endless

    /// Number of photos, nil means endless
    var count: Int? {
        switch self {
        case .five: return 5
        case .ten: return 10
        case .twenty: return 20
        case .endless: return nil
        }
    }

    var displayName: String {
        switch self {
        case .five: return "5 Photos"
        case .ten: return "10 Photos"
        case .twenty: return "20 Photos"
        case .endless: return "Endless"
        }
    }
}

// MARK: - UserSettings Struct (T008)

/// Persisted user preferences for game configuration
struct UserSettings: Codable, Equatable {
    var revealSpeed: RevealSpeed
    var timerDuration: Int
    var sessionLength: SessionLength
    var selectedAlbumIds: Set<String>

    /// Default settings for new users
    static let defaults = UserSettings(
        revealSpeed: .medium,
        timerDuration: 30,
        sessionLength: .ten,
        selectedAlbumIds: []
    )

    /// Validate timer duration is within acceptable range
    var isTimerDurationValid: Bool {
        timerDuration >= 10 && timerDuration <= 120
    }
}
