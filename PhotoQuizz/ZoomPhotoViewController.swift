import UIKit
import MapKit
import TVUIKit

class ZoomPhotoViewController: UIViewController, PhotoLoadingDelegate {
    private var imageView: UIImageView!
    private var imageContainerView: UIView!
    private var timerLabel: UILabel!
    private var timerBackgroundView: UIVisualEffectView!
    private var answerButton: UIButton!
    private var timer: Timer?
    private var secondsElapsed = 0 // Compteur de secondes écoulées
    private var currentPhotoItem: PhotoItem?
    private var mapView: MKMapView!
    private var infoView: UIView!
    private var locationLabel: UILabel!
    private var dateLabel: UILabel!
    private var nextPhotoButton: UIButton!
    private let infoContainerView = UIView()
    private let nextButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var loadingBackgroundView: UIView!
    
    // Niveaux de zoom prédéfinis
    private let zoomLevels: [CGFloat] = [500, 400, 320, 256, 205, 164, 131, 105]
    private var currentZoomIndex = 0
    private var finalZoomLevel: CGFloat = 100 // Sera ajusté en fonction de l'orientation
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        print("✅ ZoomPhotoViewController chargé")
        
        setupImageContainer()
        setupImageView()
        setupTimerBackground()
        setupTimerLabel()
        setupAnswerButton()
        setupMapAndInfoView()
        setupUI()
        PhotoManager.shared.loadingDelegate = self
        loadPhoto()
    }
    
    private func setupImageContainer() {
        imageContainerView = UIView()
        imageContainerView.clipsToBounds = true
        imageContainerView.backgroundColor = .black
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageContainerView)
        
        NSLayoutConstraint.activate([
            imageContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupImageView() {
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.addSubview(imageView)
        
        // L'imageView doit être plus grande que son conteneur pour permettre le zoom
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: imageContainerView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageContainerView.heightAnchor)
        ])
    }
    
    private func setupTimerBackground() {
        let blurEffect = UIBlurEffect(style: .dark)
        timerBackgroundView = UIVisualEffectView(effect: blurEffect)
        timerBackgroundView.layer.cornerRadius = 15
        timerBackgroundView.clipsToBounds = true
        timerBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timerBackgroundView)
        
        NSLayoutConstraint.activate([
            timerBackgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            timerBackgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            timerBackgroundView.widthAnchor.constraint(equalToConstant: 120),
            timerBackgroundView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupTimerLabel() {
        timerLabel = UILabel()
        timerLabel.textColor = .white
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 36, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerBackgroundView.contentView.addSubview(timerLabel)
        
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: timerBackgroundView.contentView.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerBackgroundView.contentView.centerYAnchor)
        ])
        
        updateTimerLabel()
    }
    
    private func setupAnswerButton() {
        answerButton = UIButton(type: .system)
        answerButton.setTitle("Réponse", for: .normal)
        answerButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        answerButton.backgroundColor = .systemBlue
        answerButton.setTitleColor(.white, for: .normal)
        answerButton.layer.cornerRadius = 10
        answerButton.translatesAutoresizingMaskIntoConstraints = false
        answerButton.addTarget(self, action: #selector(answerButtonTapped), for: .primaryActionTriggered)
        view.addSubview(answerButton)
        
        NSLayoutConstraint.activate([
            answerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            answerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            answerButton.widthAnchor.constraint(equalToConstant: 200),
            answerButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupNextPhotoButton() {
        nextPhotoButton = UIButton(type: .system)
        nextPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        nextPhotoButton.setTitle("Suivante", for: .normal)
        nextPhotoButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        nextPhotoButton.backgroundColor = .systemBlue
        nextPhotoButton.setTitleColor(.white, for: .normal)
        nextPhotoButton.layer.cornerRadius = 10
        nextPhotoButton.addTarget(self, action: #selector(nextPhotoButtonTapped), for: .primaryActionTriggered)
        infoView.addSubview(nextPhotoButton)
    }
    
    private func setupMapAndInfoView() {
        // Configuration de la vue d'information
        infoView = UIView()
        infoView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.isHidden = true
        view.addSubview(infoView)
        
        // Configuration de la carte
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 10
        mapView.clipsToBounds = true
        infoView.addSubview(mapView)
        
        // Configuration des labels
        locationLabel = UILabel()
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        locationLabel.textColor = .white
        locationLabel.font = .systemFont(ofSize: 24, weight: .bold)
        locationLabel.textAlignment = .left
        locationLabel.numberOfLines = 0
        infoView.addSubview(locationLabel)
        
        dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.textColor = .white
        dateLabel.font = .systemFont(ofSize: 20)
        dateLabel.textAlignment = .left
        infoView.addSubview(dateLabel)
        
        // Configuration du bouton suivant
        setupNextPhotoButton()
        
        // Créer une vue conteneur pour les informations
        let infoContainerView = UIView()
        infoContainerView.translatesAutoresizingMaskIntoConstraints = false
        infoView.addSubview(infoContainerView)
        
        // Ajouter les labels dans le conteneur d'informations
        infoContainerView.addSubview(locationLabel)
        infoContainerView.addSubview(dateLabel)
        infoContainerView.addSubview(nextPhotoButton)
        
        NSLayoutConstraint.activate([
            infoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            infoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            infoView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            infoView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            
            // Carte à gauche
            mapView.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 20),
            mapView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 20),
            mapView.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -20),
            mapView.widthAnchor.constraint(equalTo: infoView.widthAnchor, multiplier: 0.4),
            
            // Conteneur d'informations à droite
            infoContainerView.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 20),
            infoContainerView.leadingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 20),
            infoContainerView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -20),
            infoContainerView.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -20),
            
            // Labels dans le conteneur d'informations
            locationLabel.topAnchor.constraint(equalTo: infoContainerView.topAnchor),
            locationLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor),
            locationLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor),
            
            dateLabel.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: 20),
            dateLabel.leadingAnchor.constraint(equalTo: infoContainerView.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: infoContainerView.trailingAnchor),
            
            // Bouton en bas du conteneur d'informations
            nextPhotoButton.centerXAnchor.constraint(equalTo: infoContainerView.centerXAnchor),
            nextPhotoButton.bottomAnchor.constraint(equalTo: infoContainerView.bottomAnchor),
            nextPhotoButton.heightAnchor.constraint(equalToConstant: 40),
            nextPhotoButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
    
    private func setupUI() {
        // Configuration de l'indicateur de chargement
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .large
        loadingIndicator.transform = CGAffineTransform(scaleX: 2.0, y: 2.0) // Agrandir l'indicateur
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Ajouter un fond semi-transparent pour l'indicateur
        let loadingBackgroundView = UIView()
        loadingBackgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        loadingBackgroundView.isHidden = true
        loadingBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingBackgroundView)
        NSLayoutConstraint.activate([
            loadingBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Stocker la référence à la vue de fond
        self.loadingBackgroundView = loadingBackgroundView
    }
    
    private func loadPhoto() {
        PhotoManager.shared.loadRandomPhotoWithLocationOrFallback { [weak self] item in
            DispatchQueue.main.async {
                guard let self = self, let item = item else {
                    self?.showError("Aucune photo à afficher")
                    return
                }
                self.currentPhotoItem = item
                self.displayPhoto(item)
                print("✅ Image chargée avec EXIF : \(String(describing: item.location))")
                self.startTimer()
            }
        }
    }
    
    private func displayPhoto(_ item: PhotoItem) {
        // Redimensionner l'image pour optimiser la mémoire tout en préservant le ratio
        let targetSize = CGSize(width: 1920, height: 1080) // Résolution 1080p
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { context in
            // Calculer le ratio pour préserver les proportions
            let imageSize = item.image.size
            let widthRatio = targetSize.width / imageSize.width
            let heightRatio = targetSize.height / imageSize.height
            let ratio = min(widthRatio, heightRatio)
            
            let newSize = CGSize(
                width: imageSize.width * ratio,
                height: imageSize.height * ratio
            )
            
            // Centrer l'image
            let rect = CGRect(
                x: (targetSize.width - newSize.width) / 2,
                y: (targetSize.height - newSize.height) / 2,
                width: newSize.width,
                height: newSize.height
            )
            
            item.image.draw(in: rect)
        }
        
        imageView.image = resizedImage
        
        // Calculer le niveau de zoom final en fonction de l'orientation
        let imageSize = resizedImage.size
        let containerSize = imageContainerView.bounds.size
        
        // Calculer les ratios pour la largeur et la hauteur
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        
        // Pour le dernier niveau, on veut que l'image soit entièrement visible
        // On utilise le plus petit ratio pour s'assurer que l'image rentre entièrement
        finalZoomLevel = min(widthRatio, heightRatio) * 100
        
        // Réinitialiser l'index de zoom et appliquer le zoom initial
        currentZoomIndex = 0
        applyZoom(animated: false)
    }
    
    private func applyZoom(animated: Bool) {
        let zoomLevel: CGFloat
        if currentZoomIndex < zoomLevels.count {
            zoomLevel = zoomLevels[currentZoomIndex] / 100
        } else {
            zoomLevel = finalZoomLevel / 100
        }
        
        let transform = CGAffineTransform(scaleX: zoomLevel, y: zoomLevel)
        
        if animated {
            UIView.animate(withDuration: 1.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                self.imageView.transform = transform
            }
        } else {
            imageView.transform = transform
        }
    }
    
    private func startTimer() {
        secondsElapsed = 0
        updateTimerLabel()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.secondsElapsed += 1
            self.updateTimerLabel()
            
            // Toutes les 3 secondes, on dézoome
            if self.secondsElapsed % 3 == 0 {
                if self.currentZoomIndex < self.zoomLevels.count {
                    self.currentZoomIndex += 1
                    self.applyZoom(animated: true)
                }
            }
        }
    }
    
    private func updateTimerLabel() {
        let minutes = secondsElapsed / 60
        let seconds = secondsElapsed % 60
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    @objc private func answerButtonTapped() {
        // Arrêter le timer
        timer?.invalidate()
        timer = nil
        
        // Zoomer à 100% si ce n'est pas déjà le cas
        if currentZoomIndex < zoomLevels.count {
            currentZoomIndex = zoomLevels.count
            applyZoom(animated: true)
        }
        
        // Cacher le bouton réponse
        answerButton.isHidden = true
        
        // Afficher les informations
        if let photoItem = currentPhotoItem {
            // Mettre à jour la carte
            if let location = photoItem.location {
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                mapView.setRegion(region, animated: true)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = location.coordinate
                mapView.addAnnotation(annotation)
            }
            
            // Mettre à jour les labels
            let geocoder = CLGeocoder()
            if let location = photoItem.location {
                geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                    if let placemark = placemarks?.first {
                        let country = placemark.country ?? "Pays inconnu"
                        let locality = placemark.locality ?? placemark.administrativeArea ?? "Lieu inconnu"
                        self?.locationLabel.text = "\(locality), \(country)"
                    }
                }
            } else {
                locationLabel.text = "Lieu inconnu"
            }
            
            // Formater la date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            dateFormatter.locale = Locale(identifier: "fr_FR")
            if let date = photoItem.creationDate {
                dateLabel.text = dateFormatter.string(from: date)
            } else {
                dateLabel.text = "Date inconnue"
            }
        }
        
        // Afficher la vue d'information avec animation
        UIView.animate(withDuration: 0.5) {
            self.infoView.isHidden = false
            self.infoView.alpha = 1
        } completion: { _ in
            // Mettre le focus sur le bouton photo suivante
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
        }
    }
    
    @objc private func nextPhotoButtonTapped() {
        // Cacher la vue d'information avec animation
        UIView.animate(withDuration: 0.5, animations: {
            self.infoView.alpha = 0
        }) { _ in
            self.infoView.isHidden = true
            self.infoView.alpha = 1
            // Réafficher le bouton réponse
            self.answerButton.isHidden = false
            self.loadPhoto()
        }
    }
    
    func showError(_ message: String) {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    deinit {
        timer?.invalidate()
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if !infoView.isHidden {
            return [nextPhotoButton]
        }
        return [answerButton]
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let nextFocusedView = context.nextFocusedView {
            if nextFocusedView == nextPhotoButton {
                nextPhotoButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } else if nextFocusedView == answerButton {
                answerButton.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }
        }
        
        if let previouslyFocusedView = context.previouslyFocusedView {
            if previouslyFocusedView == nextPhotoButton {
                nextPhotoButton.transform = .identity
            } else if previouslyFocusedView == answerButton {
                answerButton.transform = .identity
            }
        }
    }
    
    // MARK: - PhotoLoadingDelegate
    
    func photoLoadingDidStart() {
        DispatchQueue.main.async {
            self.loadingBackgroundView.isHidden = false
            self.loadingIndicator.startAnimating()
            self.imageView.alpha = 0.3 // Réduire l'opacité pendant le chargement
        }
    }
    
    func photoLoadingDidFinish() {
        DispatchQueue.main.async {
            self.loadingBackgroundView.isHidden = true
            self.loadingIndicator.stopAnimating()
            UIView.animate(withDuration: 0.3) {
                self.imageView.alpha = 1.0 // Restaurer l'opacité
            }
        }
    }
}
