import Foundation
import CoreLocation

// MARK: - LocationReveal Struct (T011)

/// Computed data for displaying the answer (location reveal)
struct LocationReveal: Equatable {
    let coordinate: CLLocationCoordinate2D
    let city: String?
    let country: String?
    let displayDate: String
    let isOffline: Bool

    // MARK: - Initialization

    /// Create from geocoded placemark
    init(coordinate: CLLocationCoordinate2D, placemark: CLPlacemark?, dateTaken: Date?) {
        self.coordinate = coordinate
        self.city = placemark?.locality
        self.country = placemark?.country
        self.displayDate = Self.formatDate(dateTaken)
        self.isOffline = placemark == nil
    }

    /// Create offline fallback (coordinates only)
    init(coordinate: CLLocationCoordinate2D, dateTaken: Date?) {
        self.coordinate = coordinate
        self.city = nil
        self.country = nil
        self.displayDate = Self.formatDate(dateTaken)
        self.isOffline = true
    }

    // MARK: - Display Helpers

    /// Location text for display (city, country or coordinates)
    var locationText: String {
        if let city = city, let country = country {
            return "\(city), \(country)"
        } else if let city = city {
            return city
        } else if let country = country {
            return country
        } else {
            return coordinateText
        }
    }

    /// Coordinate text for fallback display
    var coordinateText: String {
        let lat = String(format: "%.4f", coordinate.latitude)
        let lon = String(format: "%.4f", coordinate.longitude)
        let latDir = coordinate.latitude >= 0 ? "N" : "S"
        let lonDir = coordinate.longitude >= 0 ? "E" : "W"
        return "\(abs(coordinate.latitude).formatted(.number.precision(.fractionLength(4))))° \(latDir), \(abs(coordinate.longitude).formatted(.number.precision(.fractionLength(4))))° \(lonDir)"
    }

    // MARK: - Private Helpers

    private static func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return "Date unknown"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    // MARK: - Equatable

    static func == (lhs: LocationReveal, rhs: LocationReveal) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.displayDate == rhs.displayDate
    }
}
