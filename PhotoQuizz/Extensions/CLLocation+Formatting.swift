import Foundation
import CoreLocation

// MARK: - CLLocationCoordinate2D Formatting Extension (T016)

extension CLLocationCoordinate2D {

    /// Format coordinate as a human-readable string
    /// Example: "48.8566° N, 2.3522° E"
    var formattedString: String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        let latValue = abs(latitude)
        let lonValue = abs(longitude)

        return String(format: "%.4f° %@, %.4f° %@", latValue, latDirection, lonValue, lonDirection)
    }

    /// Format coordinate for compact display
    /// Example: "48.86° N, 2.35° E"
    var compactString: String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        let latValue = abs(latitude)
        let lonValue = abs(longitude)

        return String(format: "%.2f° %@, %.2f° %@", latValue, latDirection, lonValue, lonDirection)
    }

    /// Format as degrees, minutes, seconds
    /// Example: "48° 51' 24" N, 2° 21' 8" E"
    var dmsString: String {
        func toDMS(_ decimal: Double) -> (degrees: Int, minutes: Int, seconds: Int) {
            let absolute = abs(decimal)
            let degrees = Int(absolute)
            let minutesDecimal = (absolute - Double(degrees)) * 60
            let minutes = Int(minutesDecimal)
            let seconds = Int((minutesDecimal - Double(minutes)) * 60)
            return (degrees, minutes, seconds)
        }

        let lat = toDMS(latitude)
        let lon = toDMS(longitude)

        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"

        return "\(lat.degrees)° \(lat.minutes)' \(lat.seconds)\" \(latDirection), \(lon.degrees)° \(lon.minutes)' \(lon.seconds)\" \(lonDirection)"
    }
}

// MARK: - CLLocation Convenience Extension

extension CLLocation {
    /// Create location from coordinate
    convenience init(coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
