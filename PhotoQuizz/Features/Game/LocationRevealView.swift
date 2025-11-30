import SwiftUI
import MapKit
import Photos

// MARK: - LocationRevealView (T028, T029)

/// View displaying the answer: map with location, city/country, and date
struct LocationRevealView: View {

    // MARK: - Properties

    let locationReveal: LocationReveal
    let photo: PhotoItem

    // MARK: - State

    @State private var cameraPosition: MapCameraPosition

    // MARK: - Initialization

    init(locationReveal: LocationReveal, photo: PhotoItem) {
        self.locationReveal = locationReveal
        self.photo = photo

        // Initialize camera position centered on the photo location
        let coordinate = locationReveal.coordinate
        self._cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        ))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 40) {
            // Map view
            mapSection

            // Location info
            locationInfoSection
        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            // Location marker
            Marker(
                locationReveal.locationText,
                coordinate: locationReveal.coordinate
            )
            .tint(.red)
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .frame(height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.3), radius: 15)
        .overlay(alignment: .topTrailing) {
            // Offline indicator (T029)
            if locationReveal.isOffline {
                offlineIndicator
            }
        }
    }

    // MARK: - Location Info Section

    private var locationInfoSection: some View {
        VStack(spacing: 20) {
            // Location text (city, country or coordinates)
            HStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.red)

                Text(locationReveal.locationText)
                    .font(.system(size: 48, weight: .semibold))
            }

            // Coordinates (always shown if online, primary if offline)
            if !locationReveal.isOffline {
                Text(locationReveal.coordinateText)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }

            // Date
            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)

                Text(locationReveal.displayDate)
                    .font(.system(size: 36))
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Offline Indicator (T029)

    private var offlineIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline Mode")
        }
        .font(.system(size: 24))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.orange)
        )
        .padding(20)
    }
}

// MARK: - Preview

#Preview {
    let coordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
    let reveal = LocationReveal(
        coordinate: coordinate,
        placemark: nil,
        dateTaken: Date()
    )

    // Create a mock PhotoItem for preview
    return LocationRevealView(
        locationReveal: reveal,
        photo: PhotoItem(asset: PHAsset())! // Note: Won't work in preview without mock
    )
}
