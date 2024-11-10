import UIKit
import AVFoundation
import ActivityKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure audio session for recording
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .defaultToSpeaker])
            try audioSession.setActive(true)
            
            // Request microphone permission
            audioSession.requestRecordPermission { allowed in
                if !allowed {
                    // Handle permission denial through ErrorAlertManager
                    DispatchQueue.main.async {
                        ErrorAlertManager.shared.handleMicrophonePermissionError()
                    }
                }
            }
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
        
        // Prevent device from sleeping during recording
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Request authorization for Live Activities
        ActivityAuthorizationInfo().requestAuthorization { granted, error in
            if let error = error {
                print("Error requesting Live Activities authorization: \(error.localizedDescription)")
            } else if !granted {
                print("Live Activities authorization not granted.")
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Handle discarded scenes if needed
    }
}