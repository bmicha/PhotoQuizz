import Foundation
import Photos
import UIKit
import Observation

// MARK: - PhotoLibraryError

enum PhotoLibraryError: Error, LocalizedError {
    case notAuthorized
    case accessDenied
    case noGeotaggedPhotos
    case loadFailed(PHAsset)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Photo library access has not been granted."
        case .accessDenied:
            return "Photo library access was denied. Please enable it in Settings."
        case .noGeotaggedPhotos:
            return "No photos with location data were found."
        case .loadFailed(let asset):
            return "Failed to load photo: \(asset.localIdentifier)"
        }
    }
}

// MARK: - PhotoLibraryService (T013)

/// Service for accessing the user's photo library via PhotoKit
@Observable
final class PhotoLibraryService {

    // MARK: - Properties

    private let imageManager = PHCachingImageManager()

    // MARK: - Authorization

    /// Current authorization status
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Check if authorized to access photos
    var isAuthorized: Bool {
        let status = authorizationStatus
        return status == .authorized || status == .limited
    }

    /// Request photo library access
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    // MARK: - Fetch Photos

    /// Fetch geotagged photos from specified albums (or all if empty)
    func fetchGeotaggedPhotos(from albumIds: Set<String> = [], limit: Int? = nil) async throws -> [PhotoItem] {
        guard isAuthorized else {
            throw PhotoLibraryError.notAuthorized
        }

        return await withCheckedContinuation { continuation in
            var photos: [PhotoItem] = []

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "location != nil")
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let assets: PHFetchResult<PHAsset>

            if albumIds.isEmpty {
                // Fetch from all photos
                assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            } else {
                // Fetch from specific albums
                let albumOptions = PHFetchOptions()
                let albumAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

                // Filter by album membership
                var filteredAssets: [PHAsset] = []
                albumAssets.enumerateObjects { asset, _, _ in
                    // Check if asset belongs to any selected album
                    let collections = PHAssetCollection.fetchAssetCollectionsContaining(
                        asset,
                        with: .album,
                        options: nil
                    )
                    var belongsToSelected = false
                    collections.enumerateObjects { collection, _, stop in
                        if albumIds.contains(collection.localIdentifier) {
                            belongsToSelected = true
                            stop.pointee = true
                        }
                    }
                    if belongsToSelected {
                        filteredAssets.append(asset)
                    }
                }

                // Convert to PhotoItems
                for asset in filteredAssets {
                    if let photo = PhotoItem(asset: asset) {
                        photos.append(photo)
                        if let limit = limit, photos.count >= limit {
                            break
                        }
                    }
                }

                continuation.resume(returning: photos.shuffled())
                return
            }

            // Process all assets
            assets.enumerateObjects { asset, index, stop in
                if let photo = PhotoItem(asset: asset) {
                    photos.append(photo)
                    if let limit = limit, photos.count >= limit {
                        stop.pointee = true
                    }
                }
            }

            continuation.resume(returning: photos.shuffled())
        }
    }

    // MARK: - Fetch Albums

    /// Fetch all albums containing geotagged photos
    func fetchAlbums() async throws -> [PhotoAlbum] {
        guard isAuthorized else {
            throw PhotoLibraryError.notAuthorized
        }

        return await withCheckedContinuation { continuation in
            var albums: [PhotoAlbum] = []

            // Fetch user albums
            let userAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )

            // Fetch smart albums
            let smartAlbums = PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: .any,
                options: nil
            )

            // Process user albums
            userAlbums.enumerateObjects { collection, _, _ in
                if let album = self.createAlbum(from: collection) {
                    albums.append(album)
                }
            }

            // Process smart albums
            smartAlbums.enumerateObjects { collection, _, _ in
                if let album = self.createAlbum(from: collection) {
                    albums.append(album)
                }
            }

            // Sort by title and filter only albums with geotagged photos
            let sortedAlbums = albums
                .filter { $0.geotaggedCount > 0 }
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

            continuation.resume(returning: sortedAlbums)
        }
    }

    private func createAlbum(from collection: PHAssetCollection) -> PhotoAlbum? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "location != nil")

        let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        let geotaggedCount = assets.count

        guard geotaggedCount > 0 else { return nil }

        let thumbnailAsset = assets.firstObject

        return PhotoAlbum(
            collection: collection,
            geotaggedCount: geotaggedCount,
            thumbnailAsset: thumbnailAsset
        )
    }

    // MARK: - Load Image

    /// Load image for display
    func loadImage(for asset: PHAsset, targetSize: CGSize) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                } else if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: PhotoLibraryError.loadFailed(asset))
                }
            }
        }
    }
}
