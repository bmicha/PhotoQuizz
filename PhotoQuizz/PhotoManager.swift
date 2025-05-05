import Photos
import CoreLocation
import UIKit
import ImageIO

protocol PhotoLoadingDelegate: AnyObject {
    func photoLoadingDidStart()
    func photoLoadingDidFinish()
}

struct PhotoItem {
    let image: UIImage
    let location: CLLocation?
    let creationDate: Date?
}

class PhotoManager: NSObject {
    
    static let shared = PhotoManager()
    private var photoLibrary: PHPhotoLibrary?
    private var authorizationStatus: PHAuthorizationStatus = .notDetermined
    weak var loadingDelegate: PhotoLoadingDelegate?
    
    private override init() {
        super.init()
        setupPhotoLibrary()
    }
    
    private func setupPhotoLibrary() {
        photoLibrary = PHPhotoLibrary.shared()
        photoLibrary?.register(self)
        
        // Vérifier le statut d'autorisation
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if authorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                self?.authorizationStatus = status
                print("📸 Statut d'autorisation Photos : \(status.rawValue)")
            }
        }
    }
    
    func loadLocalPhotos() -> [PhotoItem] {
        var photos: [PhotoItem] = []
        
        for i in 1...20 {
            let imageName = "LocalPhoto\(i)"
            if let image = UIImage(named: imageName) {
                let fakeLocation = CLLocation(latitude: 48.85 + Double(i) * 0.01, longitude: 2.35 + Double(i) * 0.01)
                let fakeDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())
                let item = PhotoItem(image: image, location: fakeLocation, creationDate: fakeDate)
                photos.append(item)
            }
        }
        
        return photos
    }
    
    func loadRandomPhotoWithLocationOrFallback(completion: @escaping (PhotoItem?) -> Void) {
        // Notifier le début du chargement
        DispatchQueue.main.async {
            self.loadingDelegate?.photoLoadingDidStart()
        }
        
        // Vérifier l'autorisation avant de continuer
        if authorizationStatus != .authorized {
            print("❌ Accès aux photos non autorisé")
            DispatchQueue.main.async {
                self.loadingDelegate?.photoLoadingDidFinish()
                completion(nil)
            }
            return
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Utiliser une approche asynchrone pour éviter les problèmes d'accessibilité
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // Filtrer les assets pour ne garder que ceux avec une localisation
            var assetsWithLocation: [PHAsset] = []
            assets.enumerateObjects { asset, _, _ in
                if asset.location != nil {
                    assetsWithLocation.append(asset)
                }
            }
            
            guard !assetsWithLocation.isEmpty else {
                print("❌ Aucune photo avec localisation trouvée dans la photothèque")
                DispatchQueue.main.async {
                    self.loadingDelegate?.photoLoadingDidFinish()
                    completion(nil)
                }
                return
            }
            
            print("📸 Photos avec localisation trouvées : \(assetsWithLocation.count)")
            
            // Sélectionner une photo aléatoire parmi celles avec localisation
            let randomIndex = Int(arc4random_uniform(UInt32(assetsWithLocation.count)))
            let asset = assetsWithLocation[randomIndex]
            
            // Configurer les options de requête d'image
            let imageManager = PHImageManager.default()
            let targetSize = CGSize(width: 3840, height: 2160) // Résolution 4K
            let requestOptions = PHImageRequestOptions()
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isNetworkAccessAllowed = true
            requestOptions.isSynchronous = false
            requestOptions.resizeMode = .exact // Assure une meilleure qualité
            requestOptions.version = .current // Utilise la version la plus récente de l'image
            
            // Récupérer l'image
            imageManager.requestImage(for: asset,
                                    targetSize: targetSize,
                                    contentMode: .aspectFit,
                                    options: requestOptions) { [weak self] image, info in
                guard let self = self,
                      let image = image else {
                    print("❌ Échec du chargement de l'image")
                    DispatchQueue.main.async {
                        self?.loadingDelegate?.photoLoadingDidFinish()
                        completion(nil)
                    }
                    return
                }
                
                // Vérifier si l'image est en haute résolution
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    print("⚠️ Image chargée en qualité dégradée")
                } else {
                    print("✅ Image chargée en haute résolution")
                }
                
                let item = PhotoItem(
                    image: image,
                    location: asset.location,
                    creationDate: asset.creationDate
                )
                
                DispatchQueue.main.async {
                    self.loadingDelegate?.photoLoadingDidFinish()
                    completion(item)
                }
            }
        }
    }
    
    func loadLocalPhotosWithMetadata() -> [PhotoItem] {
        var items: [PhotoItem] = []
        
        // Chercher les fichiers .jpg et .jpeg
        let jpgUrls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "LocalPhotos") ?? []
        let jpegUrls = Bundle.main.urls(forResourcesWithExtension: "jpeg", subdirectory: "LocalPhotos") ?? []
        let urls = jpgUrls + jpegUrls
        
        print("📸 URLs trouvées : \(urls.count)")
        urls.forEach { url in
            print("   - \(url.lastPathComponent)")
        }
        
        if urls.isEmpty {
            print("❌ Aucune image trouvée dans LocalPhotos/")
            return items
        }
        
        for url in urls {
            do {
                let data = try Data(contentsOf: url)
                guard let image = UIImage(data: data) else {
                    print("❌ Impossible de créer l'image depuis les données pour \(url.lastPathComponent)")
                    continue
                }
                
                let (location, date) = extractMetadata(from: url)
                let item = PhotoItem(image: image, location: location, creationDate: date)
                items.append(item)
                print("✅ Image chargée avec succès : \(url.lastPathComponent)")
            } catch {
                print("❌ Erreur lors du chargement de \(url.lastPathComponent) : \(error)")
            }
        }
        
        print("📸 Total des images chargées : \(items.count)")
        return items
    }
    
    func extractMetadata(from url: URL) -> (location: CLLocation?, date: Date?) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return (nil, nil)
        }
        
        // Récupérer la date
        var dateTaken: Date? = nil
        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
           let dateStr = tiff[kCGImagePropertyTIFFDateTime] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
            dateTaken = formatter.date(from: dateStr)
        }
        
        // Récupérer la géolocalisation
        if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
           let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
           let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
           let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
           let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String {
            
            let latitude = latRef == "S" ? -lat : lat
            let longitude = lonRef == "W" ? -lon : lon
            let location = CLLocation(latitude: latitude, longitude: longitude)
            return (location, dateTaken)
        }
        
        return (nil, dateTaken)
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension PhotoManager: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Gérer les changements dans la photothèque si nécessaire
        print("📸 Changements détectés dans la photothèque")
    }
}
