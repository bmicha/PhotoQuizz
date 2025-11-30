import Foundation
import CoreLocation
import Observation

// MARK: - GeocodingService (T014)

/// Service for reverse geocoding coordinates to place names
@Observable
final class GeocodingService {

    // MARK: - Properties

    private let geocoder = CLGeocoder()
    private var cache: [String: CLPlacemark] = [:]

    // MARK: - Network Status

    /// Simple network check (geocoding will fail gracefully if offline)
    var isNetworkAvailable: Bool {
        // CLGeocoder handles network internally; we rely on graceful fallback
        true
    }

    // MARK: - Reverse Geocoding

    /// Convert coordinates to city/country with graceful offline fallback
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D, dateTaken: Date?) async -> LocationReveal {
        // Check cache first
        let cacheKey = cacheKeyFor(coordinate: coordinate)
        if let cached = cache[cacheKey] {
            return LocationReveal(coordinate: coordinate, placemark: cached, dateTaken: dateTaken)
        }

        // Perform geocoding
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            if let placemark = placemarks.first {
                // Cache the result
                cache[cacheKey] = placemark
                return LocationReveal(coordinate: coordinate, placemark: placemark, dateTaken: dateTaken)
            }
        } catch {
            // Geocoding failed (offline or rate limited) - return fallback
            print("Geocoding failed: \(error.localizedDescription)")
        }

        // Return offline fallback (coordinates only)
        return LocationReveal(coordinate: coordinate, dateTaken: dateTaken)
    }

    // MARK: - Cache Management

    /// Clear the geocoding cache
    func clearCache() {
        cache.removeAll()
    }

    /// Generate cache key from coordinate (rounded to 4 decimal places)
    private func cacheKeyFor(coordinate: CLLocationCoordinate2D) -> String {
        let lat = String(format: "%.4f", coordinate.latitude)
        let lon = String(format: "%.4f", coordinate.longitude)
        return "\(lat),\(lon)"
    }
}
