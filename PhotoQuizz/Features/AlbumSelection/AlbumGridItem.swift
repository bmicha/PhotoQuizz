import SwiftUI
import Photos

// MARK: - AlbumGridItem (T042, T048)

/// Grid item displaying an album with thumbnail and selection state
struct AlbumGridItem: View {

    // MARK: - Properties

    let album: PhotoAlbum
    let isSelected: Bool
    let action: () -> Void

    // MARK: - Environment

    @Environment(\.isFocused) private var isFocused
    @Environment(PhotoLibraryService.self) private var photoLibraryService

    // MARK: - State

    @State private var thumbnailImage: UIImage?

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Thumbnail
                thumbnailView
                    .frame(width: 300, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(selectionOverlay)

                // Title and count
                VStack(spacing: 8) {
                    Text(album.title)
                        .font(.system(size: 28, weight: .semibold))
                        .lineLimit(1)

                    Text(album.subtitle)
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isFocused ? Color.blue.opacity(0.2) : Color.clear)
            )
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? .blue.opacity(0.3) : .clear, radius: 10)
            .animation(.spring(duration: 0.3), value: isFocused)
        }
        .buttonStyle(.plain)
        .task {
            await loadThumbnail()
        }
    }

    // MARK: - Thumbnail View

    @ViewBuilder
    private var thumbnailView: some View {
        if let image = thumbnailImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                )
        }
    }

    // MARK: - Selection Overlay

    @ViewBuilder
    private var selectionOverlay: some View {
        if isSelected {
            ZStack {
                Color.blue.opacity(0.3)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .shadow(radius: 5)
            }
        }
    }

    // MARK: - Load Thumbnail

    private func loadThumbnail() async {
        guard let asset = album.thumbnailAsset else { return }

        do {
            let image = try await photoLibraryService.loadImage(
                for: asset,
                targetSize: CGSize(width: 400, height: 300)
            )
            await MainActor.run {
                thumbnailImage = image
            }
        } catch {
            print("Failed to load album thumbnail: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    AlbumGridItem(
        album: PhotoAlbum(
            collection: PHAssetCollection(),
            geotaggedCount: 42,
            thumbnailAsset: nil
        ),
        isSelected: true,
        action: {}
    )
    .environment(PhotoLibraryService())
}
