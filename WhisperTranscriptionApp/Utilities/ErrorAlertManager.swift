import UIKit

class ErrorAlertManager {
    static let shared = ErrorAlertManager()
    
    private init() {}
    
    func showAlert(title: String, message: String, in viewController: UIViewController? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        DispatchQueue.main.async {
            if let viewController = viewController {
                viewController.present(alert, animated: true)
            } else if let topVC = UIApplication.shared.windows.first?.rootViewController {
                topVC.present(alert, animated: true)
            }
        }
    }
    
    // Specific error handling methods
    func handleMicrophonePermissionError() {
        showAlert(
            title: "Microphone Access Required",
            message: "Please enable microphone access in Settings to use the recording features."
        )
    }
    
    func handleModelLoadingError(_ error: Error) {
        showAlert(
            title: "Model Loading Error",
            message: "Failed to load Whisper model: \(error.localizedDescription)"
        )
    }
    
    func handleStorageError(_ error: Error) {
        showAlert(
            title: "Storage Error",
            message: "Failed to save or retrieve data: \(error.localizedDescription)"
        )
    }
}