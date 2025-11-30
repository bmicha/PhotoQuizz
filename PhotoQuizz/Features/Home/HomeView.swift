import SwiftUI

// MARK: - HomeView (T023, T035)

/// Main home screen with game start options
struct HomeView: View {

    // MARK: - Environment

    @Environment(PhotoLibraryService.self) private var photoLibraryService
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    @State private var isLoading = false
    @State private var photos: [PhotoItem] = []
    @State private var errorMessage: String?
    @State private var showGame = false
    @State private var showAlbumSelection = false
    @State private var showSettings = false

    @FocusState private var focusedButton: HomeButton?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 60) {
                    // Title
                    VStack(spacing: 16) {
                        Text("PhotoQuizz")
                            .font(.system(size: 96, weight: .bold))

                        Text("Rediscover Your Memories")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 80)

                    Spacer()

                    // Main buttons
                    VStack(spacing: 30) {
                        // Start Game button
                        HomeMenuButton(
                            title: "Start Game",
                            subtitle: selectedAlbumsSubtitle,
                            icon: "play.fill",
                            isLoading: isLoading
                        ) {
                            startGame()
                        }
                        .focused($focusedButton, equals: .startGame)

                        // Select Albums button
                        HomeMenuButton(
                            title: "Select Albums",
                            subtitle: "\(settingsService.settings.selectedAlbumIds.count) selected",
                            icon: "photo.on.rectangle"
                        ) {
                            showAlbumSelection = true
                        }
                        .focused($focusedButton, equals: .selectAlbums)

                        // Settings button
                        HomeMenuButton(
                            title: "Settings",
                            subtitle: settingsSubtitle,
                            icon: "gear"
                        ) {
                            showSettings = true
                        }
                        .focused($focusedButton, equals: .settings)
                    }

                    Spacer()

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 28))
                            .foregroundStyle(.red)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.1))
                            )
                    }
                }
                .padding(60)
            }
            .navigationDestination(isPresented: $showGame) {
                GameSessionView(photos: photos)
            }
            .navigationDestination(isPresented: $showAlbumSelection) {
                AlbumSelectionView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onAppear {
            focusedButton = .startGame
        }
    }

    // MARK: - Computed Properties

    private var selectedAlbumsSubtitle: String {
        let count = settingsService.settings.selectedAlbumIds.count
        return count == 0 ? "All photos" : "\(count) album\(count == 1 ? "" : "s") selected"
    }

    private var settingsSubtitle: String {
        let settings = settingsService.settings
        return "\(settings.sessionLength.displayName) • \(settings.revealSpeed.displayName)"
    }

    // MARK: - Actions

    private func startGame() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let albumIds = settingsService.settings.selectedAlbumIds
                let limit = settingsService.settings.sessionLength.count

                let fetchedPhotos = try await photoLibraryService.fetchGeotaggedPhotos(
                    from: albumIds,
                    limit: limit
                )

                await MainActor.run {
                    if fetchedPhotos.isEmpty {
                        errorMessage = "No geotagged photos found. Add photos with location data to play."
                    } else if fetchedPhotos.count < 5 {
                        // T057: Edge case - fewer than 5 geotagged photos
                        errorMessage = "Only \(fetchedPhotos.count) geotagged photo\(fetchedPhotos.count == 1 ? "" : "s") found. Add more photos with location data for a better experience."
                        photos = fetchedPhotos
                        showGame = true
                    } else {
                        photos = fetchedPhotos
                        showGame = true
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - HomeButton Enum

private enum HomeButton: Hashable {
    case startGame
    case selectAlbums
    case settings
}

// MARK: - HomeMenuButton

/// A styled menu button for the home screen
private struct HomeMenuButton: View {
    let title: String
    let subtitle: String
    let icon: String
    var isLoading: Bool = false
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            HStack(spacing: 30) {
                // Icon
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 40))
                    }
                }
                .frame(width: 60)

                // Text
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 42, weight: .semibold))

                    Text(subtitle)
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 30)
            .frame(maxWidth: 800)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFocused ? Color.blue : Color.secondary.opacity(0.15))
            )
            .foregroundColor(isFocused ? .white : .primary)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .shadow(color: isFocused ? .blue.opacity(0.4) : .clear, radius: 15)
            .animation(.spring(duration: 0.3), value: isFocused)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(PhotoLibraryService())
        .environment(GeocodingService())
        .environment(SettingsService())
}
