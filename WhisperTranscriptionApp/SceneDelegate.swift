import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let transcriptionListVC = TranscriptionListViewController()
        let navigationController = UINavigationController(rootViewController: transcriptionListVC)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Start background task to keep the app running while minimized
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "RecordingBackgroundTask") {
            // This block is called when time expires
            self.endBackgroundTask()
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // End the background task when the app enters the foreground
        endBackgroundTask()
    }

    // MARK: - Helper Methods
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}