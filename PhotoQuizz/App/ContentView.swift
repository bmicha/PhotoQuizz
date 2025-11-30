import SwiftUI
import Photos

// MARK: - ContentView (T018)

/// Root navigation view that handles permission state and main navigation
struct ContentView: View {

    // MARK: - Environment

    @Environment(PhotoLibraryService.self) private var photoLibraryService
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    @State private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @State private var isCheckingPermission = true

    // MARK: - Body

    var body: some View {
        Group {
            if isCheckingPermission {
                // Loading state while checking permission
                ProgressView("Loading...")
                    .font(.title2)
            } else {
                switch authorizationStatus {
                case .authorized, .limited:
                    // Permission granted - show home screen
                    HomeView()

                case .denied, .restricted:
                    // Permission denied - show explanation
                    PermissionDeniedView()

                case .notDetermined:
                    // First launch - show permission request
                    PermissionRequestView(onAuthorized: {
                        checkAuthorizationStatus()
                    })

                @unknown default:
                    // Handle future cases
                    PermissionRequestView(onAuthorized: {
                        checkAuthorizationStatus()
                    })
                }
            }
        }
        .task {
            checkAuthorizationStatus()
        }
    }

    // MARK: - Private Methods

    private func checkAuthorizationStatus() {
        authorizationStatus = photoLibraryService.authorizationStatus
        isCheckingPermission = false
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environment(PhotoLibraryService())
        .environment(GeocodingService())
        .environment(SettingsService())
}
