import UIKit

class HomeViewController: UIViewController {

    let titleLabel = UILabel()
    let startButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        setupUI()
    }

    func setupUI() {
        // Label titre
        titleLabel.text = "Photo Quizz"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 64, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Bouton démarrer
        startButton.setTitle("Démarrer une partie", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: .medium)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .primaryActionTriggered) // ✅ Siri Remote OK

        // Ajout à la vue
        view.addSubview(titleLabel)
        view.addSubview(startButton)

        // Contraintes
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 150),

            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 80)
        ])
    }

    @objc func startButtonTapped() {
        let gameVC = ZoomPhotoViewController()
        navigationController?.pushViewController(gameVC, animated: true)
    }
}
