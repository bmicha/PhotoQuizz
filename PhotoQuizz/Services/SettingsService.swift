import Foundation
import Observation

// MARK: - SettingsService (T015)

/// Service for managing user preferences persistence
@Observable
final class SettingsService {

    // MARK: - Constants

    private enum Keys {
        static let settings = "com.photoquizz.settings"
    }

    // MARK: - Properties

    private let defaults: UserDefaults

    /// Current user settings
    private(set) var settings: UserSettings

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load saved settings or use defaults
        if let data = defaults.data(forKey: Keys.settings),
           let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .defaults
        }
    }

    // MARK: - Save

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: Keys.settings)
        }
    }

    // MARK: - Update Methods

    /// Update reveal speed
    func setRevealSpeed(_ speed: RevealSpeed) {
        settings.revealSpeed = speed
        save()
    }

    /// Update timer duration (clamped to valid range)
    func setTimerDuration(_ seconds: Int) {
        settings.timerDuration = max(10, min(120, seconds))
        save()
    }

    /// Update session length
    func setSessionLength(_ length: SessionLength) {
        settings.sessionLength = length
        save()
    }

    /// Update selected albums
    func setSelectedAlbums(_ albumIds: Set<String>) {
        settings.selectedAlbumIds = albumIds
        save()
    }

    /// Add an album to selection
    func addAlbum(_ albumId: String) {
        settings.selectedAlbumIds.insert(albumId)
        save()
    }

    /// Remove an album from selection
    func removeAlbum(_ albumId: String) {
        settings.selectedAlbumIds.remove(albumId)
        save()
    }

    /// Toggle album selection
    func toggleAlbum(_ albumId: String) {
        if settings.selectedAlbumIds.contains(albumId) {
            removeAlbum(albumId)
        } else {
            addAlbum(albumId)
        }
    }

    /// Reset all settings to defaults
    func resetToDefaults() {
        settings = .defaults
        defaults.removeObject(forKey: Keys.settings)
    }
}
