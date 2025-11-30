import SwiftUI

// MARK: - AlbumSelectionView (T043, T044, T046, T047)

/// View for selecting albums to use in game sessions
struct AlbumSelectionView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(PhotoLibraryService.self) private var photoLibraryService
    @Environment(SettingsService.self) private var settingsService

    // MARK: - State

    @State private var albums: [PhotoAlbum] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    // MARK: - Grid Layout

    private let columns = [
        GridItem(.adaptive(minimum: 340), spacing: 30)
    ]

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.02)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                headerView

                // Content
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if albums.isEmpty {
                    emptyView
                } else {
                    albumGrid
                }
            }
            .padding(60)
        }
        .navigationTitle("Select Albums")
        .task {
            await loadAlbums()
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose Albums")
                    .font(.system(size: 48, weight: .bold))

                Text(selectedCountText)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Clear selection button
            if !settingsService.settings.selectedAlbumIds.isEmpty {
                Button("Clear All") {
                    settingsService.setSelectedAlbums([])
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    // MARK: - Album Grid

    private var albumGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 30) {
                ForEach(albums) { album in
                    AlbumGridItem(
                        album: album,
                        isSelected: settingsService.settings.selectedAlbumIds.contains(album.id)
                    ) {
                        settingsService.toggleAlbum(album.id)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)

            Text("Loading albums...")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text(message)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await loadAlbums()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("No Albums with Geotagged Photos")
                .font(.system(size: 36, weight: .semibold))

            Text("Add photos with location data to your albums to see them here.")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    private var selectedCountText: String {
        let count = settingsService.settings.selectedAlbumIds.count
        if count == 0 {
            return "No albums selected (using all photos)"
        } else {
            return "\(count) album\(count == 1 ? "" : "s") selected"
        }
    }

    // MARK: - Load Albums

    private func loadAlbums() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedAlbums = try await photoLibraryService.fetchAlbums()

            await MainActor.run {
                albums = fetchedAlbums
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

// MARK: - Button Styles

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 28, weight: .semibold))
            .padding(.horizontal, 40)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.blue : Color.blue.opacity(0.8))
            )
            .foregroundColor(.white)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3), value: isFocused)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 28))
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFocused ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
            )
            .foregroundColor(isFocused ? .white : .primary)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .animation(.spring(duration: 0.3), value: isFocused)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AlbumSelectionView()
    }
    .environment(PhotoLibraryService())
    .environment(SettingsService())
}
