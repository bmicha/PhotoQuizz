import Foundation
import Photos
import CoreLocation

// MARK: - PhotoItem Struct (T009)

/// A photo selected for gameplay with required metadata
struct PhotoItem: Identifiable, Equatable {
    let id: String
    let asset: PHAsset
    let location: CLLocationCoordinate2D
    let dateTaken: Date?
    let albumId: String?

    // MARK: - Initialization

    /// Initialize from a PHAsset, returns nil if no valid location
    init?(asset: PHAsset, albumId: String? = nil) {
        guard let assetLocation = asset.location?.coordinate,
              Self.isValidCoordinate(assetLocation) else {
            return nil
        }

        self.id = asset.localIdentifier
        self.asset = asset
        self.location = assetLocation
        self.dateTaken = asset.creationDate
        self.albumId = albumId
    }

    // MARK: - Validation

    /// Check if coordinate is within valid range
    private static func isValidCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
        coordinate.longitude >= -180 && coordinate.longitude <= 180 &&
        // Exclude (0, 0) as it's often a placeholder for missing data
        !(coordinate.latitude == 0 && coordinate.longitude == 0)
    }

    // MARK: - Equatable

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Date Formatting Extension

extension PhotoItem {
    /// Formatted date string for display
    var formattedDate: String {
        guard let date = dateTaken else {
            return "Date unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
