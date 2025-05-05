import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        print("✅ SceneDelegate lancé")
        let window = UIWindow(windowScene: windowScene)
        let homeVC = HomeViewController()
        let navController = UINavigationController(rootViewController: homeVC)
        navController.navigationBar.isHidden = true

        window.rootViewController = navController
        self.window = window
        window.makeKeyAndVisible()
    }
}
