import SwiftUI

// MARK: - PhotoQuizzApp (T017)

/// Main entry point for the PhotoQuizz tvOS app
@main
struct PhotoQuizzApp: App {

    // MARK: - Services (Shared State)

    @State private var photoLibraryService = PhotoLibraryService()
    @State private var geocodingService = GeocodingService()
    @State private var settingsService = SettingsService()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(photoLibraryService)
                .environment(geocodingService)
                .environment(settingsService)
        }
    }
}
