import Foundation
import Photos

// MARK: - PhotoAlbum Struct (T010)

/// Represents a selectable album from the user's photo library
struct PhotoAlbum: Identifiable, Equatable {
    let id: String
    let title: String
    let thumbnailAsset: PHAsset?
    let geotaggedCount: Int

    // MARK: - Initialization

    init(collection: PHAssetCollection, geotaggedCount: Int, thumbnailAsset: PHAsset? = nil) {
        self.id = collection.localIdentifier
        self.title = collection.localizedTitle ?? "Untitled Album"
        self.thumbnailAsset = thumbnailAsset
        self.geotaggedCount = geotaggedCount
    }

    // MARK: - Display

    var subtitle: String {
        "\(geotaggedCount) geotagged photo\(geotaggedCount == 1 ? "" : "s")"
    }

    // MARK: - Validation

    /// Only albums with geotagged photos are selectable
    var isSelectable: Bool {
        geotaggedCount > 0
    }

    // MARK: - Equatable

    static func == (lhs: PhotoAlbum, rhs: PhotoAlbum) -> Bool {
        lhs.id == rhs.id
    }
}
